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
| Logs | structured JSON via structlog, `APP_LOG_LEVEL` env var |

## Common operations

**Roll back a bad deploy** — `helm rollback <release> -n ${{ values.name }}-${{ values.environment }}`.

**Enable OpenAPI docs temporarily** — set `APP_EXPOSE_DOCS=true`. Leave it off
in shared environments; the schema is an information-disclosure surface.

**Open network access** — the chart ships a deny-all NetworkPolicy. Add the
calling namespace to `networkPolicy.allowedIngressNamespaces` and outbound
destinations to `networkPolicy.allowedEgressCidrs`.

## Ownership

Changes to build, test, scan, or deploy behaviour belong in the platform repo
(`novaferrydianto/platform-engineering`), not in this service's `ci.yml`.
