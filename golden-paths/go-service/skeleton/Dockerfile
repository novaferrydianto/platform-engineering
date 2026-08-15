# syntax=docker/dockerfile:1

# checkov:skip=CKV_DOCKER_2:Runtime is distroless/static with no shell, so a HEALTHCHECK command cannot execute. Liveness and readiness are defined in helm/values.yaml, where Kubernetes acts on them.
FROM golang:1.26-alpine AS build
WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY cmd ./cmd
COPY internal ./internal

# CGO off + static link: the binary has no libc dependency, so it runs unmodified
# on the distroless base below. Build info stripped (-s -w) to shrink the image;
# trimpath drops the build machine's filesystem paths from the binary.
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/server ./cmd/server

FROM gcr.io/distroless/static-debian12:nonroot AS runtime
ENV PORT=8080

COPY --from=build /out/server /server

# distroless/static:nonroot already runs as uid 65532; no shell, no package
# manager, no libc — there is nothing in this image for an attacker to reuse.
USER nonroot:nonroot
EXPOSE 8080

ENTRYPOINT ["/server"]
