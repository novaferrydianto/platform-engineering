# Platform Engineering

Internal Developer Platform (IDP) for self-service, paved-road software delivery.
Developers request a service or environment through the portal; the platform
generates the code, wires CI/CD, and provisions infrastructure — with security
and compliance guardrails baked in, not bolted on.

## Pillars

| Pillar | Where | What it does |
|---|---|---|
| Self-service portal | [`idp-portal/`](idp-portal/) | Backstage — software catalog, scaffolder UI, TechDocs |
| Golden paths | [`golden-paths/`](golden-paths/) | Backstage Software Templates — the guided, paved-road workflow |
| Reusable service templates | [`golden-paths/*/skeleton/`](golden-paths/) | Starter code (app + Dockerfile + Helm chart + CI) each golden path scaffolds from |
| CI/CD templates | [`.github/workflows/`](.github/workflows/), [`.github/actions/`](.github/actions/) | Reusable GitHub Actions workflows: build, test, security scan, container publish, Helm deploy, OpenTofu plan/apply |
| Infrastructure modules | [`infrastructure-modules/`](infrastructure-modules/) | OpenTofu modules for AWS, GCP, Azure, and cloud-agnostic Kubernetes (incl. Kyverno, Argo CD) |
| Automated provisioning | [`provisioning/`](provisioning/) | Terragrunt environment stacks, Crossplane compositions, GitOps apps, and admission policies |
| Policy as code | [`provisioning/policies/`](provisioning/policies/) | Kyverno `ClusterPolicy` — signature verification, registry allowlist, resource limits |
| GitOps | [`provisioning/gitops/`](provisioning/gitops/) | Argo CD app-of-apps reconciling platform components from git |
| Cost visibility | [`reusable-cost-estimate.yml`](.github/workflows/reusable-cost-estimate.yml) | Infracost delta posted on infrastructure PRs before apply |

## How a request flows

1. A developer opens the portal (`idp-portal/`) and picks a **golden path**
   (`golden-paths/go-service` — the default for new backends — plus
   `nodejs-service`, `python-fastapi-service`, `static-site`).
2. The scaffolder renders the path's `skeleton/` — a **reusable service
   template** — into a new repo, including a `ci.yml` that calls the shared
   **CI/CD templates** in `.github/workflows/`.
3. On first push, CI/CD builds, tests, security-scans, signs and publishes the
   container, then deploys it. Infrastructure requests become a PR against
   `provisioning/live/<cloud>/<env>/`, which composes the **infrastructure
   modules** for the target cloud.
4. Merge triggers `reusable-tofu-plan-apply.yml`, which provisions the
   environment via Terragrunt. Day-2 application resources can instead go
   through `provisioning/crossplane/` claims, with no PR required.

See [`docs/architecture.md`](docs/architecture.md) for the full diagram and
[`docs/getting-started.md`](docs/getting-started.md) to run the portal locally.

## Repository layout

```
platform-engineering/
├── idp-portal/              # Backstage app
├── golden-paths/            # Software Templates + reusable skeletons
├── .github/                 # reusable CI/CD workflows + composite actions
├── infrastructure-modules/  # OpenTofu modules (aws/gcp/azure/kubernetes)
├── provisioning/            # Terragrunt stacks, Crossplane, GitOps apps, Kyverno policies
├── docs/                    # architecture, getting started, golden-path authoring guide
└── scripts/                 # bootstrap + CI validation helpers
```

## Toolchain

| Tool | Version | Why pinned here |
|---|---|---|
| Node.js | 24 (LTS) | Backstage supports `22 \|\| 24`; 26.x Current would fail its `engines` check |
| OpenTofu | 1.12.5 | `.github/actions/setup-opentofu` |
| Terragrunt | 1.1.3 | same |
| Go | 1.26 | Go service golden path — default choice for new backends |
| Python | 3.13 | FastAPI golden path |

## Engineering defaults

- **Security-first**: least privilege IAM, private networking by default, no
  hardcoded secrets (OIDC for CI→cloud auth, secret managers for runtime).
  See [`SECURITY.md`](SECURITY.md) for the full control set.
- **Idempotent IaC**: every module is safe to re-`apply`; state is remote,
  encrypted, and locked.
- **Deny-all by default**: network policies, security groups, and IAM start
  closed and are opened explicitly per module input.
- **Pinned supply chain**: every third-party GitHub Action is pinned to a
  commit SHA, enforced by `scripts/check-action-pins.sh` in pre-commit and CI.

## Getting started

```bash
scripts/bootstrap.sh          # verify tooling, install pre-commit gates, validate
cd idp-portal && yarn install && yarn dev
```

See [`docs/getting-started.md`](docs/getting-started.md).
