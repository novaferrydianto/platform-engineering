from fastapi.testclient import TestClient

from app.main import create_app

client = TestClient(create_app())


def test_healthz() -> None:
    res = client.get("/healthz")
    assert res.status_code == 200
    assert res.json() == {"status": "ok"}


def test_readyz() -> None:
    assert client.get("/readyz").status_code == 200


def test_metrics_exposed() -> None:
    res = client.get("/metrics")
    assert res.status_code == 200
    assert "python_info" in res.text


def test_docs_disabled_by_default() -> None:
    assert client.get("/docs").status_code == 404
