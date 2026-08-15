# syntax=docker/dockerfile:1
FROM ghcr.io/astral-sh/uv:python3.13-alpine AS build
WORKDIR /app
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

COPY pyproject.toml ./
RUN uv venv /opt/venv && VIRTUAL_ENV=/opt/venv uv pip install --no-cache .

COPY src ./src
RUN VIRTUAL_ENV=/opt/venv uv pip install --no-cache --no-deps .

FROM python:3.14-alpine AS runtime
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    APP_PORT=8080

RUN adduser -D -u 1000 appuser
COPY --from=build --chown=appuser:appuser /opt/venv /opt/venv

USER appuser
WORKDIR /app
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request,os,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:'+os.environ['APP_PORT']+'/healthz').status==200 else 1)"

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
