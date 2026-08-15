# ${{ values.name }}

${{ values.description }}

Owned by `${{ values.owner }}` · hosted on `${{ values.cloud }}` · first deployed to
`${{ values.environment }}`.

## Runbook

**Deploy** — merge to `main`. CI builds `dist/`, syncs it to object storage, and
invalidates the CDN.

**Roll back** — re-run the deploy workflow from the last good commit; object
storage versioning retains prior objects.

**Cache not updating** — the CDN invalidation step runs after sync. If content
is stale, confirm the invalidation completed; `index.html` is short-cached
while hashed assets are immutable.

## Ownership

Build and deploy behaviour lives in `novaferrydianto/platform-engineering`, not in this
repo's `ci.yml`.
