from fastapi.testclient import TestClient

import app as nova


def setup_function():
    nova.DB = __import__("pathlib").Path(__import__("tempfile").mktemp(suffix=".sqlite3"))
    nova.ADMIN_PASSWORD = "test-password"
    nova.JWT_SECRET = "t" * 48


def admin_headers(client):
    response = client.post("/admin/login", json={"password": "test-password"})
    assert response.status_code == 200
    return {"Authorization": "Bearer " + response.json()["access_token"]}


def profile():
    return json_config


json_config = '{"outbounds":[{"protocol":"freedom"}]}'


def test_admin_can_replace_config_without_reinstall():
    client = TestClient(nova.app)
    headers = admin_headers(client)
    body = {"id": "eu-1", "name": "Frankfurt", "country_code": "DE", "protocol": "VLESS", "config": json_config, "enabled": True}
    assert client.post("/admin/servers", headers=headers, json=body).status_code == 201
    replacement = {**body, "config": '{"outbounds":[{"protocol":"vless","tag":"changed"}]}' }
    assert client.put("/admin/servers/eu-1", headers=headers, json=replacement).status_code == 200
    assert client.get("/servers/eu-1/config").json()["config"] == replacement["config"]


def test_bulk_import_and_invalid_config():
    client = TestClient(nova.app)
    headers = admin_headers(client)
    item = {"id": "jp-1", "name": "Tokyo", "country_code": "JP", "protocol": "VLESS", "config": json_config, "enabled": True}
    assert client.post("/admin/servers/bulk", headers=headers, json={"servers": [item]}).json()["updated"] == 1
    bad = {**item, "id": "bad", "config": "vless://not-json"}
    assert client.post("/admin/servers", headers=headers, json=bad).status_code == 422
