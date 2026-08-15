# ${{ values.name }}

${{ values.description }}

Scaffolded from the **Node.js Service** golden path. Owner: `${{ values.owner }}`.
Target cloud: `${{ values.cloud }}` · initial environment: `${{ values.environment }}`.

## Local development

```bash
npm install
npm run dev      # http://localhost:8080
npm test
```

## Endpoints

| Path | Purpose |
|---|---|
| `/` | Service identity |
| `/healthz` | Liveness probe |
| `/readyz` | Readiness probe |
| `/metrics` | Prometheus metrics |

## Container

```bash
# docker or podman — both accept identical flags
docker build -t ${{ values.name }} .
docker run -p 8080:8080 ${{ values.name }}
```

Runs as non-root with a read-only root filesystem — see `Dockerfile` and
`helm/values.yaml` (`securityContext`).

## CI/CD

`.github/workflows/ci.yml` is a thin caller into the platform's reusable
workflows. Build, test, security scan, container publish, and Helm deploy
logic all live in `novaferrydianto/platform-engineering/.github/workflows/`. To change
how this service is built or scanned, change it there — not here.

## Deployment

The Helm chart in `helm/` defaults to deny-all NetworkPolicy, no privilege
escalation, and explicit resource limits. Open ingress/egress by setting
`networkPolicy.allowedIngressNamespaces` / `allowedEgressCidrs`.
