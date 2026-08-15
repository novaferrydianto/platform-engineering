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
| Logs | structured JSON via pino, `LOG_LEVEL` env var |

## Common operations

**Roll back a bad deploy** — `helm rollback <release> -n ${{ values.name }}-${{ values.environment }}`.

**Scale** — set `autoscaling.enabled=true` in `helm/values.yaml`, or bump
`replicaCount` for a fixed size.

**Open network access** — the chart ships a deny-all NetworkPolicy. Add the
calling namespace to `networkPolicy.allowedIngressNamespaces` and any outbound
destinations to `networkPolicy.allowedEgressCidrs`.

## Ownership

Changes to build, test, scan, or deploy behaviour belong in the platform repo
(`novaferrydianto/platform-engineering`), not in this service's `ci.yml`.
