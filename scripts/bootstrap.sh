#!/usr/bin/env bash
# Local development setup: verifies required tooling and installs the same
# gates CI enforces, so failures surface before the push rather than after.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

TOFU_VERSION="1.12.5"
TERRAGRUNT_VERSION="1.1.3"
NODE_MAJOR="24"

missing=0

have() { command -v "$1" >/dev/null 2>&1; }

require() {
  local tool="$1" hint="$2"
  if have "$tool"; then
    printf '  ok      %-12s %s\n' "$tool" "$($tool --version 2>&1 | head -1)"
  else
    printf '  MISSING %-12s %s\n' "$tool" "$hint"
    missing=1
  fi
}

echo "Checking tooling:"
require node "install Node ${NODE_MAJOR} (LTS) — Backstage supports 22 || 24"
require tofu "install OpenTofu ${TOFU_VERSION} — https://opentofu.org/docs/intro/install/"
require terragrunt "install Terragrunt ${TERRAGRUNT_VERSION} — https://terragrunt.gruntwork.io/docs/getting-started/install/"
require helm "install Helm — https://helm.sh/docs/intro/install/"
require kubectl "install kubectl"

if have podman; then
  printf '  ok      %-12s %s\n' podman "$(podman --version 2>&1)"
elif have docker; then
  printf '  ok      %-12s %s\n' docker "$(docker --version 2>&1)"
else
  printf '  MISSING %-12s %s\n' "container engine" "install Podman (preferred, daemonless — see docs/getting-started.md) or Docker"
  missing=1
fi

if have node; then
  actual="$(node -p 'process.versions.node.split(".")[0]')"
  if [ "$actual" != "$NODE_MAJOR" ] && [ "$actual" != "22" ]; then
    echo "  WARN    node ${actual} is outside Backstage's supported range (22 || 24)"
  fi
fi

echo
echo "Installing pre-commit gates:"
if have pre-commit; then
  pre-commit install
  pre-commit install --hook-type pre-push
  echo "  ok      hooks installed"
else
  echo "  MISSING pre-commit — pip install pre-commit, then re-run this script"
  missing=1
fi

echo
echo "Validating infrastructure modules:"
if have tofu; then
  for dir in infrastructure-modules/*/*/; do
    (cd "$dir" && tofu init -backend=false -input=false >/dev/null && tofu validate >/dev/null) \
      && printf '  ok      %s\n' "$dir" \
      || printf '  FAILED  %s\n' "$dir"
  done
else
  echo "  skipped — tofu not installed"
fi

echo
echo "Validating golden paths:"
python3 scripts/validate-golden-paths.py || true

echo
echo "Checking for unset placeholders:"
# A warning, not a failure: a fresh clone is expected to have these unset. They
# become an error only when something is actually applied.
bash scripts/check-placeholders.sh || echo "  (expected on a fresh clone — set before any apply)"

echo
if [ "$missing" -ne 0 ]; then
  echo "Some tooling is missing. Install it and re-run: scripts/bootstrap.sh"
  exit 1
fi

cat <<'EOF'
Ready.

  Portal:   cd idp-portal && yarn install && yarn dev
  Modules:  cd infrastructure-modules/aws/vpc && tofu validate
  Env:      cd provisioning/live/aws/dev && terragrunt run --all -- plan

The portal is generated with --skip-install, so `yarn install` is required
before its TypeScript resolves.
EOF
