# ${{ values.name }}

${{ values.description }}

Owned by `${{ values.owner }}` · runs on `${{ values.cloud }}` · first deployed to
`${{ values.environment }}`.

## Runbook

| Signal | Where |
|---|---|
| Liveness | `GET /healthz` |
| Readiness | `GET /readyz` |
| Metrics | `GET /metrics` (Prometheus, scraped via pod annotations) |
| Logs | structured JSON via `log/slog`, `LOG_LEVEL` env var |

## Common operations

**Roll back a bad deploy** — `helm rollback <release> -n ${{ values.name }}-${{ values.environment }}`.

**Slow shutdown / connection drops on deploy** — check
`terminationGracePeriodSeconds` is at least the 10s the server allows for
draining in-flight requests (see `main.go`).

**Open network access** — the chart ships a deny-all NetworkPolicy. Add the
calling namespace to `networkPolicy.allowedIngressNamespaces` and any outbound
destinations to `networkPolicy.allowedEgressCidrs`.

## Ownership

Changes to build, test, scan, or deploy behaviour belong in the platform repo
(`novaferrydianto/platform-engineering`), not in this service's `ci.yml`.
