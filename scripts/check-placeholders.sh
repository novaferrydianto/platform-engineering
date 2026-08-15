#!/usr/bin/env bash
# Fails if any REPLACE_WITH_* placeholder survives in configuration that gets
# applied to real infrastructure.
#
# These are deliberately loud rather than plausible-looking. A placeholder like
# "acme-platform-tofu-state" reaches `terragrunt apply` and fails with a
# confusing "bucket does not exist"; REPLACE_WITH_STATE_BUCKET fails here, with
# the reason attached.
#
# Documentation is excluded: READMEs describe the placeholders on purpose.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# Directories whose contents are applied to infrastructure, not read by humans.
SCAN_PATHS=(
  provisioning/live
  provisioning/policies
  provisioning/gitops
  provisioning/bootstrap
)

status=0
found=""

for path in "${SCAN_PATHS[@]}"; do
  [ -d "$path" ] || continue

  while IFS= read -r match; do
    [ -n "$match" ] || continue
    found+="  ${match}"$'\n'
    status=1
  done < <(
    grep -rn --include='*.hcl' --include='*.yaml' --include='*.yml' --include='*.tf' \
      'REPLACE_WITH_[A-Z_]*' "$path" 2>/dev/null || true
  )
done

if [ "$status" -ne 0 ]; then
  echo "Unset placeholders remain in applied configuration:" >&2
  printf '%s' "$found" >&2
  cat >&2 <<'EOF'

Set them before applying:
  - state buckets      → create with provisioning/bootstrap/<cloud>, then set
                         state_bucket in provisioning/live/<cloud>/account.hcl
  - GCP project        → provisioning/live/gcp/account.hcl
  - backend.tf.example → copy to backend.tf and fill in after the first apply

See provisioning/bootstrap/README.md.
EOF
  exit 1
fi

echo "No unset placeholders in applied configuration."
