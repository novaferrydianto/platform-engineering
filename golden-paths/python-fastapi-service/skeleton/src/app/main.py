from fastapi import FastAPI, Response
from prometheus_client import CONTENT_TYPE_LATEST, generate_latest

from app.settings import settings


def create_app() -> FastAPI:
    app = FastAPI(
        title="${{ values.name }}",
        description="${{ values.description }}",
        version="0.1.0",
        docs_url="/docs" if settings.expose_docs else None,
    )

    @app.get("/healthz")
    async def healthz() -> dict[str, str]:
        return {"status": "ok"}

    # Readiness is separate from liveness so a warming instance is pulled from the
    # load balancer rather than restarted.
    @app.get("/readyz")
    async def readyz() -> dict[str, str]:
        return {"status": "ready"}

    @app.get("/metrics")
    async def metrics() -> Response:
        return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)

    @app.get("/")
    async def root() -> dict[str, str]:
        return {"service": "${{ values.name }}", "description": "${{ values.description }}"}

    return app


app = create_app()
