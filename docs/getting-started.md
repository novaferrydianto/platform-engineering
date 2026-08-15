# Getting Started

## Prerequisites

- Node.js 24 (latest LTS "Krypton"; Backstage supports `22 || 24`, so 26.x Current is
  deliberately not used — it would fail the portal's `engines` check)
- OpenTofu 1.12.5 and Terragrunt 1.1.3
- A container engine — **Docker or Podman** — for building/testing service
  templates locally. Every Dockerfile in this repo is plain OCI-buildable, so
  `podman build`/`podman run` work as direct substitutes wherever this guide
  shows `docker build`/`docker run`.
- `kubectl` + a cluster context if working with Crossplane (`provisioning/crossplane/`)

### Using Podman instead of Docker

Podman needs no background daemon and doesn't require Docker Desktop
licensing, which is why it's a common choice inside a VM (e.g. the VMware
Workstation guest from the earlier setup discussion).

```bash
# Windows/macOS: Podman needs a Linux VM to run containers in
podman machine init
podman machine start

# optional: make `docker` resolve to podman for tools/scripts that hardcode it
alias docker=podman        # bash/zsh
# or install the `podman-docker` package, which symlinks /usr/bin/docker
```

`podman build`, `podman run`, and `podman push` accept the same flags as
their Docker equivalents used throughout this repo — no command changes are
needed beyond swapping the binary name.

## Run the portal locally

```bash
cd idp-portal
yarn install
yarn dev
```

This starts the Backstage frontend (`:3000`) and backend (`:7007`). The
catalog auto-discovers entities from `idp-portal/catalog/*.yaml` and every
`golden-paths/*/template.yaml`, as configured in `idp-portal/app-config.yaml`.

If `idp-portal/` only contains config files (no `packages/` yet), the app
hasn't been generated on this machine — run:

```bash
npx @backstage/create-app@latest --path idp-portal
```

then copy `app-config.yaml` and `catalog-info.yaml` from this repo's
`idp-portal/` into the generated app, overwriting the defaults.

## Scaffold a new service (via the portal UI)

1. Open the portal, go to **Create** → pick a golden path.
2. Fill in the wizard (name, owner, cloud target, environment).
3. The scaffolder renders `golden-paths/<path>/skeleton/` into a new repo,
   pushes it, and registers it in the catalog.
4. First CI run (`.github/workflows/` reusable workflows) builds, tests,
   security-scans, and publishes the image, then opens a PR into
   `provisioning/terraform-live/<env>/`.

## Scaffold a new service (CLI, no portal)

Each golden path's `skeleton/` is a standalone starter — you can copy it by
hand for local experimentation without going through Backstage:

```bash
cp -r golden-paths/nodejs-service/skeleton my-new-service
cd my-new-service
# replace \${{ values.* }} scaffolder placeholders manually, then:
podman build -t my-new-service .   # or: docker build -t my-new-service .
```

## Add a new golden path

See [`golden-paths.md`](golden-paths.md).

## Work on infrastructure modules

```bash
cd infrastructure-modules/aws/vpc
terraform init -backend=false
terraform validate
terraform fmt -check
```

## Provision an environment

```bash
cd provisioning/terraform-live/dev
terraform init   # configure backend.tf with your remote state first
terraform plan
```

Or, for a K8s-native claim via Crossplane:

```bash
kubectl apply -f provisioning/crossplane/xrds/
kubectl apply -f provisioning/crossplane/compositions/
kubectl apply -f provisioning/crossplane/examples/database-claim.yaml
```
