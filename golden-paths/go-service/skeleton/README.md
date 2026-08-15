# ${{ values.name }}

${{ values.description }}

Scaffolded from the **Go Service** golden path. Owner: `${{ values.owner }}`.
Target cloud: `${{ values.cloud }}` · initial environment: `${{ values.environment }}`.

## Local development

```bash
go mod download
go run ./cmd/server      # http://localhost:8080
go test ./...
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

The image is built `FROM scratch`-equivalent (`distroless/static:nonroot`) — a
static binary with no shell, no package manager, and no libc. There is nothing
in the runtime image for an attacker to reuse, and no `RUN apt/apk` layer to
keep patched. Because the image has no shell, Docker `HEALTHCHECK` isn't used
here; liveness/readiness are Kubernetes HTTP probes instead (see `helm/`).

## Shutdown

`main.go` traps `SIGTERM` and drains in-flight requests for up to 10s before
exiting — set `terminationGracePeriodSeconds` in the Helm chart at least that
high if you change the timeout.

## CI/CD

`.github/workflows/ci.yml` is a thin caller into the platform's reusable
workflows (`golangci-lint`, `go test -race`, CodeQL, container scan, cosign
signing). To change how this service is built or scanned, change it in
`novaferrydianto/platform-engineering/.github/workflows/`, not here.

## Deployment

The Helm chart in `helm/` defaults to deny-all NetworkPolicy, no privilege
escalation, and explicit resource limits. Open ingress/egress by setting
`networkPolicy.allowedIngressNamespaces` / `allowedEgressCidrs`.
