# Architecture

## Flow

```
                    ┌──────────────────────┐
                    │   idp-portal/         │   Backstage: catalog, scaffolder UI,
                    │   (Backstage)         │   TechDocs, org/ownership model
                    └──────────┬────────────┘
                               │ developer picks a golden path
                               ▼
                    ┌──────────────────────┐
                    │   golden-paths/*      │   template.yaml (wizard: name, owner,
                    │   template.yaml       │   cloud target, environment)
                    └──────────┬────────────┘
                               │ scaffolder renders skeleton/, publishes new repo,
                               │ registers it in the catalog
                               ▼
                    ┌──────────────────────┐
                    │  new service repo     │   app code + Dockerfile + Helm chart +
                    │  (from skeleton/)     │   catalog-info.yaml + ci.yml
                    └──────────┬────────────┘
                               │ ci.yml calls reusable workflows
                               ▼
        ┌──────────────────────────────────────────────┐
        │  .github/workflows/  (reusable, workflow_call) │
        │  build → test → security-scan → docker build/  │
        │  push (OIDC) → open PR to provisioning/         │
        └──────────────────────┬───────────────────────┘
                               │ PR against environment stack
                               ▼
                    ┌──────────────────────┐
                    │  provisioning/live/    │   <cloud>/{dev,staging,prod}
                    │  (Terragrunt units)    │   composes infrastructure-modules/*
                    └──────────┬────────────┘
                               │ merge → reusable-tofu-plan-apply.yml
                               ▼
                    ┌──────────────────────┐
                    │ infrastructure-modules│   aws/ gcp/ azure/ kubernetes/
                    │ (OpenTofu, per cloud) │   VPC, cluster, database, storage
                    └──────────────────────┘

  Alternative for K8s-native, in-cluster self-service:
                    ┌──────────────────────┐
                    │ provisioning/         │   XRD + Composition — a developer
                    │ crossplane/           │   applies a claim (e.g. XDatabaseInstance)
                    └──────────────────────┘   directly from the cluster.

  Continuously reconciled, and enforced at admission:
                    ┌──────────────────────┐
                    │ provisioning/gitops/  │   Argo CD app-of-apps pulls platform
                    │ (Argo CD)             │   components from git; prune + selfHeal
                    └──────────┬────────────┘   make git the only way in.
                               │ delivers
                               ▼
                    ┌──────────────────────┐
                    │ provisioning/policies/│   Kyverno ClusterPolicies — cosign
                    │ (Kyverno)             │   signature verification, registry
                    └──────────────────────┘   allowlist, resource limits.
```

## Design decisions

- **Backstage over a custom portal** — mature scaffolder + catalog model,
  avoids reinventing ownership/discovery, large plugin ecosystem for the
  security/observability integrations this platform will need next
  (cost insights, TechDocs, SonarQube, PagerDuty, etc).
- **Golden path = template.yaml + skeleton** — the wizard (`template.yaml`)
  and the reusable code it renders (`skeleton/`) live together so a path is
  self-contained and versioned as one unit. Shared building blocks (base
  Dockerfiles, Helm chart conventions) are duplicated minimally per skeleton
  today; promote to a shared `skeleton/_shared/` fetch source once a third
  near-identical path appears (rule of three).
- **Reusable workflows, not copy-pasted YAML** — every golden path's `ci.yml`
  is a thin caller into `.github/workflows/reusable-*.yml`. Fixing a security
  scan step or adding a new gate happens once, centrally, and every generated
  repo picks it up on its next run (workflows are referenced by ref, e.g.
  `@main` or a pinned tag).
- **OpenTofu + Terragrunt, not plain Terraform** — OpenTofu is the
  MPL-licensed, community-governed fork, so the IaC layer carries no BUSL
  licensing risk. Terragrunt sits on top to keep backend configuration and
  provider blocks out of every unit: `root.hcl` generates them, so no unit can
  accidentally run with local state.
- **Modules vs. environment stacks** — `infrastructure-modules/` holds pure,
  reusable building blocks (no state, no environment specifics).
  `provisioning/live/<cloud>/<env>/` is where state lives and where modules get
  composed with environment-specific variables. This keeps modules testable and
  reusable across dev/staging/prod without copy-pasting resource blocks.
- **OpenTofu + Crossplane, not either/or** — OpenTofu is the system of
  record for account/network-level infra (VPC, cluster, IAM). Crossplane
  compositions are for in-cluster, self-service claims application teams make
  directly (e.g. "give me a Postgres instance") without opening a PR — faster
  loop for day-2 requests that don't need human review.
- **Argo CD for platform components, CI push for application workloads** —
  both deploy paths exist deliberately. Argo CD's `prune` + `selfHeal` make git
  the only way to change what it manages, which is what you want for policies
  and platform addons where drift is a security problem. Golden path apps keep
  deploying through `reusable-helm-deploy.yml`, where the whole rollout stays
  visible in one pipeline run behind an environment approval gate. The
  comparison table lives in the
  [Argo CD module README](../infrastructure-modules/kubernetes/argocd/README.md).
- **Kyverno covers what Pod Security Standards cannot** — PSS handles non-root,
  capabilities, and privilege escalation at the namespace. Kyverno exists for
  the orthogonal rules: verifying the cosign signatures this platform already
  produces, restricting registries, rejecting mutable tags, and requiring
  explicit resource declarations. Policies ship as `Audit` and are promoted to
  `Enforce` per policy once their reports are clean.
- **Cost estimated before apply, not after** — `reusable-cost-estimate.yml`
  prices `provisioning/live` on the PR and posts the monthly delta, so the
  number is visible while the change is still reviewable. It never
  authenticates to a cloud account and never runs `apply`.

## Security posture

Summarised here; [`SECURITY.md`](../SECURITY.md) is the authoritative list.

- CI/CD → cloud auth is OIDC (short-lived tokens), never long-lived access
  keys, via the `cloud-login` composite action. Plan and apply assume
  **separate roles**, so a plan job cannot mutate infrastructure.
- Every third-party action is pinned to a **commit SHA**, enforced by
  `scripts/check-action-pins.sh` in both pre-commit and `platform-ci.yml`.
  Tags are mutable; a compromised upstream tag would otherwise execute with our
  job token.
- `reusable-security-scan.yml` runs four gates on every PR — secrets,
  dependencies, static analysis, and IaC — with results as SARIF in the
  Security tab.
- Every OpenTofu module defaults to private networking and encryption at rest;
  public exposure is an explicit, reviewed opt-in, and variable validation
  rejects `0.0.0.0/0` in control plane allowlists.
- Published images are signed with cosign and carry SBOM + provenance
  attestations; deployments reference digests, and no `latest` tag exists.
- **Every environment gates on manual approval — dev, staging and prod.**
  `plan` runs automatically on PR; `apply` and `helm upgrade` both run through a
  GitHub Environment with required reviewers, and `apply` replays the
  **reviewed plan file**, so what was approved is what runs. Dev is included
  deliberately: it holds real cloud resources and real credentials.
