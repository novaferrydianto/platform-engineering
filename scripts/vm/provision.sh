#!/usr/bin/env bash
# Guest OS provisioning for the platform-engineering dev VM (Ubuntu 24.04).
# Installs the same toolchain scripts/bootstrap.sh checks for, so a fresh VM
# is ready with a single `scripts/bootstrap.sh` run. Idempotent — safe to
# re-run after a `vagrant provision` or manual invocation.
#
# Podman is installed as the container engine (not Docker): the `podman-docker`
# package makes `docker build`/`docker run` resolve to Podman transparently, and
# because this guest OS is Linux, Podman runs natively — no `podman machine`
# VM-in-a-VM is needed here (that's only required when the *host* is Windows/macOS).
set -euo pipefail

NODE_MAJOR="24"
TOFU_VERSION="1.12.5"
TERRAGRUNT_VERSION="1.1.3"
GO_VERSION="1.26.6"

log() { printf '\n==> %s\n' "$1"; }

export DEBIAN_FRONTEND=noninteractive

log "apt update + base packages"
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends \
  git curl ca-certificates gnupg unzip jq build-essential apt-transport-https pipx

log "Podman (container engine) + podman-docker compatibility shim"
sudo apt-get install -y --no-install-recommends podman podman-docker uidmap slirp4netns
# podman-docker symlinks /usr/bin/docker -> podman, so `docker build`/`docker run`
# work unmodified — this is what makes "run docker using podman" transparent.

log "Node.js ${NODE_MAJOR} (NodeSource) + corepack (for the vendored Yarn Berry in idp-portal/)"
if ! command -v node >/dev/null 2>&1 || [ "$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null)" != "$NODE_MAJOR" ]; then
  curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | sudo -E bash -
  sudo apt-get install -y nodejs
fi
sudo npm install -g corepack >/dev/null 2>&1 || true
corepack enable >/dev/null 2>&1 || sudo corepack enable

log "OpenTofu ${TOFU_VERSION}"
if ! command -v tofu >/dev/null 2>&1 || [ "$(tofu version -json 2>/dev/null | jq -r .terraform_version)" != "$TOFU_VERSION" ]; then
  curl -fsSL https://get.opentofu.org/install-opentofu.sh -o /tmp/install-opentofu.sh
  chmod +x /tmp/install-opentofu.sh
  sudo /tmp/install-opentofu.sh --install-method standalone --opentofu-version "$TOFU_VERSION"
  rm -f /tmp/install-opentofu.sh
fi

log "Terragrunt ${TERRAGRUNT_VERSION}"
if ! command -v terragrunt >/dev/null 2>&1 || [ "$(terragrunt --version 2>/dev/null | awk '{print $3}')" != "v${TERRAGRUNT_VERSION}" ]; then
  curl -fsSL -o /tmp/terragrunt \
    "https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64"
  sudo install -m 0755 /tmp/terragrunt /usr/local/bin/terragrunt
  rm -f /tmp/terragrunt
fi

log "Go ${GO_VERSION} (go-service golden path)"
if ! command -v go >/dev/null 2>&1 || [ "$(go version | awk '{print $3}')" != "go${GO_VERSION}" ]; then
  curl -fsSL -o /tmp/go.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf /tmp/go.tar.gz
  rm -f /tmp/go.tar.gz
  echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' | sudo tee /etc/profile.d/go.sh >/dev/null
fi

log "Python 3.13 via uv (python-fastapi-service golden path)"
if ! command -v uv >/dev/null 2>&1; then
  curl -fsSL https://astral.sh/uv/install.sh | sh
  echo 'export PATH=$PATH:$HOME/.local/bin' | sudo tee /etc/profile.d/uv.sh >/dev/null
fi
"$HOME/.local/bin/uv" python install 3.13 || true

log "kubectl"
if ! command -v kubectl >/dev/null 2>&1; then
  KUBECTL_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
  curl -fsSL -o /tmp/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
  sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
  rm -f /tmp/kubectl
fi

log "Helm"
if ! command -v helm >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

log "kind (local Kubernetes for testing Helm charts / Crossplane against Podman)"
if ! command -v kind >/dev/null 2>&1; then
  curl -fsSL -o /tmp/kind "https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-amd64"
  sudo install -m 0755 /tmp/kind /usr/local/bin/kind
  rm -f /tmp/kind
fi

log "Cilium CLI (only CNI here that actually enforces NetworkPolicy — kind's default kindnet doesn't)"
if ! command -v cilium >/dev/null 2>&1; then
  CILIUM_CLI_VERSION="$(curl -fsSL https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)"
  curl -fsSL -o /tmp/cilium.tar.gz \
    "https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-amd64.tar.gz"
  sudo tar -C /usr/local/bin -xzf /tmp/cilium.tar.gz cilium
  rm -f /tmp/cilium.tar.gz
fi

log "pre-commit (via pipx)"
if ! command -v pre-commit >/dev/null 2>&1; then
  pipx ensurepath
  pipx install pre-commit
  sudo ln -sf "$HOME/.local/bin/pre-commit" /usr/local/bin/pre-commit
fi

log "Provisioning complete"
cat <<'EOF'

Installed: podman (+ docker shim), node, corepack/yarn, tofu, terragrunt,
go, python 3.13 (uv), kubectl, helm, kind, cilium CLI, pre-commit.

Next: cd into the synced repo and run the platform's own checks:

  cd platform-engineering   # or wherever the repo is mounted/cloned
  scripts/bootstrap.sh

To test NetworkPolicy-enforcing manifests locally (golden path charts,
infrastructure-modules/kubernetes/namespace) against a real policy engine:

  scripts/vm/setup-kind-cilium.sh

Log out and back in (or `newgrp`) if this is the first Podman install, so
rootless container UID/GID mappings from podman-docker take effect.
EOF
