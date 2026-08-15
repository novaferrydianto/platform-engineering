# Security Policy

This repository defines the guardrails every service on the platform inherits.
A weakness here propagates to every scaffolded repo, so treat changes to
`.github/workflows/`, `.github/actions/`, `infrastructure-modules/`, and
`provisioning/` as security-sensitive.

## Reporting a vulnerability

Report privately through **GitHub Security Advisories** on this repository
(Security → Advisories → Report a vulnerability). Do not open a public issue.

Include the affected path, the impact, and reproduction steps. Expect an
acknowledgement within two business days.

## Controls in this repository

### Supply chain

- Every third-party GitHub Action is pinned to a **full commit SHA**, with the
  human-readable version in a trailing comment. Tags are mutable; SHAs are not.
- Dependabot tracks actions, npm, OpenTofu providers, and base images weekly.
- Published images are **signed with cosign** (keyless, via OIDC) and carry
  **SBOM and max-mode provenance** attestations.
- Images are addressed by digest for deployment; no `latest` tag is published.
- Those signatures are **verified at admission** by the Kyverno
  `verify-image-signatures` policy. Signing without verifying proves nothing —
  the check closes the loop between what CI publishes and what the cluster runs.

### CI/CD

- Workflows declare `permissions: contents: read` at the top level and widen
  only per-job, per-need.
- `actions/checkout` runs with `persist-credentials: false`, so the job token is
  not left in `.git/config` for later steps to reuse.
- Cloud authentication is **OIDC only** — no long-lived access keys are stored
  in any repository. Plan and apply use separate roles
  (`AWS_PLAN_ROLE_ARN` vs `AWS_APPLY_ROLE_ARN`).
- `apply` runs only on the default branch, through a GitHub Environment, and
  applies the **reviewed plan file**, so what was approved is what runs.
- **Every environment requires manual approval — dev, staging, and prod.**
  Both `reusable-tofu-plan-apply.yml` and `reusable-helm-deploy.yml` route
  through a GitHub Environment, so no apply or deploy reaches any cluster
  without a human approving it. Dev is not exempt: it holds real cloud
  resources and real credentials.
- Four scanning gates run on every PR: secrets (Gitleaks, full history),
  dependencies and misconfiguration (Trivy), static analysis (CodeQL
  `security-extended`), and IaC/manifests (Checkov). Results go to the Security
  tab as SARIF.

### Infrastructure

- Networks are **deny-all by default**. AWS empties the default security group;
  GCP adds an explicit deny-all ingress rule; Azure adds a deny-all inbound NSG
  rule. Access is opened per-module, explicitly.
- Kubernetes API servers are **private by default**, and variable validation
  rejects `0.0.0.0/0` in any control plane allowlist.
- Encryption at rest is on everywhere, with dedicated auto-rotating KMS/CMK keys
  per resource.
- **No credential is ever written to state or a tfvars file.** RDS uses
  `manage_master_user_password`; Cloud SQL generates into Secret Manager.
- Nodes require **IMDSv2 with hop limit 1**, closing the SSRF-to-node-credentials
  path.
- Workload identity (IRSA / GKE Workload Identity / Entra workload identity) is
  configured everywhere, so pods never inherit node credentials.
- Kubernetes namespaces enforce the **restricted Pod Security Standard**, a
  default-deny NetworkPolicy, and a non-automounting default ServiceAccount.
  `NetworkPolicy` is only as real as the CNI enforcing it: EKS enables the
  VPC CNI's native policy agent, GKE enables Calico, and AKS enables Cilium —
  every cluster module actually enforces what it renders, not just applies it.

### Generated services

Every golden path skeleton ships with a non-root container, read-only root
filesystem, dropped capabilities, no privilege escalation, explicit resource
limits, and a deny-all NetworkPolicy.

## Required repository settings

These are not expressible in code and must be configured once on the repository
and account:

1. **Branch protection** on `main`: required PR review (CODEOWNERS enforced),
   required status checks, no force pushes, no deletions, linear history.
2. **GitHub Environments** `dev`, `staging`, `prod` — **each with required
   reviewers**, and `prod` additionally with a wait timer. The workflows already
   reference these environments; without reviewers configured, the gate exists
   but approves automatically:

   ```bash
   OWNER=novaferrydianto
   REPO=platform-engineering
   REVIEWER_ID=22340157   # gh api users/$OWNER --jq .id

   for env in dev staging prod; do
     gh api -X PUT "repos/$OWNER/$REPO/environments/$env" \
       -F "reviewers[][type]=User" \
       -F "reviewers[][id]=$REVIEWER_ID" \
       -F "deployment_branch_policy[protected_branches]=true" \
       -F "deployment_branch_policy[custom_branch_policies]=false"
   done

   gh api -X PUT "repos/$OWNER/$REPO/environments/prod" -F "wait_timer=10"
   ```

   Two caveats on a personal account: **required reviewers on a private repo
   need GitHub Pro** (they are free on public repos), and GitHub will not let
   the person who triggered a run approve their own deployment — with a single
   reviewer configured, self-triggered deployments cannot be approved. Add a
   second reviewer, or make the repository public, before relying on this gate.
3. **Actions permissions**: allow only actions from this account plus the
   SHA-pinned allowlist; disable "Allow all actions".
4. **Default `GITHUB_TOKEN` permissions**: read-only.
5. **Secret scanning and push protection**: enabled.
6. **Dependabot secrets** for any value CI needs on Dependabot PRs
   (`GITLEAKS_LICENSE`, `INFRACOST_API_KEY`, …). Dependabot PRs cannot read
   ordinary Actions secrets — duplicate each required secret under
   Settings → Secrets and variables → Dependabot, or gate the job so
   `github.actor != 'dependabot[bot]'` skips it.
7. **Repository variables** for the OIDC role identifiers
   (`AWS_PLAN_ROLE_ARN`, `AWS_APPLY_ROLE_ARN`, `AWS_DEPLOY_ROLE_ARN`,
   `GCP_WORKLOAD_IDENTITY_PROVIDER`, `AZURE_CLIENT_ID`, …). These are
   identifiers, not secrets — the trust policy is what grants access, and it
   must be scoped to this repository and the specific environment.

## Non-goals

This repository does not manage runtime secrets. Applications read secrets from
their cloud's secret manager via workload identity at run time; nothing is
injected through CI.
