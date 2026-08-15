#!/usr/bin/env bash
# Fails if any third-party GitHub Action is referenced by tag or branch instead
# of a full 40-character commit SHA. Tags are mutable: whoever controls the
# upstream repo can repoint v4 at new code that runs with our job's token.
#
# References to this account's own reusable workflows and composite actions
# are exempt — they live in this repository and are reviewed here.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

OWN_ORG="${PLATFORM_OWNER:-novaferrydianto}"
status=0

while IFS= read -r file; do
  while IFS= read -r line; do
    ref="${line#*uses:}"
    ref="${ref%%#*}" # drop the trailing "# v4" version comment
    ref="$(printf '%s' "$ref" | tr -d ' \r')"

    case "$ref" in
      ./*|docker://*) continue ;;                 # local path or docker ref
      "$OWN_ORG"/*) continue ;;                   # our own repo, reviewed here
    esac

    version="${ref##*@}"
    if ! printf '%s' "$version" | grep -qE '^[0-9a-f]{40}$'; then
      printf '%s: not pinned to a commit SHA: %s\n' "$file" "$ref" >&2
      status=1
    fi
  done < <(grep -nE '^\s*-?\s*uses:' "$file" || true)
done < <(git ls-files '.github/workflows/*.yml' '.github/actions/**/*.yml' 'golden-paths/*/skeleton/.github/workflows/*.yml')

if [ "$status" -ne 0 ]; then
  echo >&2
  echo "Pin actions to a commit SHA with the version in a trailing comment:" >&2
  echo "  uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4" >&2
fi

exit "$status"
