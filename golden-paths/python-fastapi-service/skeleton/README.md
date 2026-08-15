# ${{ values.name }}

${{ values.description }}

Scaffolded from the **Python FastAPI Service** golden path. Owner: `${{ values.owner }}`.
Target cloud: `${{ values.cloud }}` · initial environment: `${{ values.environment }}`.

## Local development

```bash
uv sync
uv run uvicorn app.main:app --reload --port 8080
uv run pytest
```

## Endpoints

| Path | Purpose |
|---|---|
| `/` | Service identity |
| `/healthz` | Liveness probe |
| `/readyz` | Readiness probe |
| `/metrics` | Prometheus metrics |
| `/docs` | OpenAPI UI — **off unless `APP_EXPOSE_DOCS=true`** |

## Container

```bash
# docker or podman — both accept identical flags
docker build -t ${{ values.name }} .
docker run -p 8080:8080 ${{ values.name }}
```

Runs as non-root (uid 1000) with a read-only root filesystem in Kubernetes.

## CI/CD

`.github/workflows/ci.yml` is a thin caller into the platform's reusable
workflows. Build, test, security scan, container publish, and Helm deploy logic
all live in `novaferrydianto/platform-engineering/.github/workflows/`.

## Configuration

All settings are env vars prefixed `APP_` (`APP_LOG_LEVEL`, `APP_PORT`,
`APP_EXPOSE_DOCS`) — see `src/app/settings.py`. Secrets come from the cluster's
secret store, never from committed files.
