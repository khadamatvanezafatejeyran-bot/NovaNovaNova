import hashlib
import hmac
import json
import os
import sqlite3
import time
from contextlib import contextmanager
from pathlib import Path
from typing import Optional

from fastapi import Depends, FastAPI, Header, HTTPException, Response
from fastapi.responses import HTMLResponse
from pydantic import BaseModel, Field, field_validator

BASE = Path(__file__).parent
DB = Path(os.environ.get("NOVA_DB_PATH", str(BASE / "nova.sqlite3")))
ADMIN_PASSWORD = os.environ.get("NOVA_ADMIN_PASSWORD", "")
JWT_SECRET = os.environ.get("NOVA_JWT_SECRET", "")

app = FastAPI(title="NOVA VPN management API", docs_url="/docs" if os.environ.get("NOVA_ENV") != "production" else None)

@contextmanager
def db():
    conn = sqlite3.connect(DB)
    conn.row_factory = sqlite3.Row
    try:
        conn.execute("""CREATE TABLE IF NOT EXISTS servers (
            id TEXT PRIMARY KEY, name TEXT NOT NULL, country_code TEXT NOT NULL DEFAULT '',
            protocol TEXT NOT NULL, config TEXT NOT NULL, enabled INTEGER NOT NULL DEFAULT 0,
            sort_order INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL)""")
        yield conn
        conn.commit()
    finally:
        conn.close()


def b64(data: bytes) -> str:
    import base64
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def token_for(subject: str) -> str:
    header = b64(b'{"alg":"HS256","typ":"JWT"}')
    payload = b64(json.dumps({"sub": subject, "exp": int(time.time()) + 3600}, separators=(",", ":")).encode())
    unsigned = f"{header}.{payload}"
    sig = b64(hmac.new(JWT_SECRET.encode(), unsigned.encode(), hashlib.sha256).digest())
    return f"{unsigned}.{sig}"


def admin(authorization: Optional[str] = Header(default=None)) -> str:
    if not authorization or not authorization.startswith("Bearer ") or not JWT_SECRET:
        raise HTTPException(401, "Admin authentication required")
    import base64
    try:
        raw = authorization[7:]
        head, payload, signature = raw.split(".")
        expected = b64(hmac.new(JWT_SECRET.encode(), f"{head}.{payload}".encode(), hashlib.sha256).digest())
        if not hmac.compare_digest(expected, signature):
            raise ValueError("bad signature")
        claims = json.loads(base64.urlsafe_b64decode(payload + "=" * (-len(payload) % 4)))
        if claims.get("exp", 0) < time.time() or claims.get("sub") != "admin":
            raise ValueError("expired")
    except Exception:
        raise HTTPException(401, "Invalid or expired token")
    return "admin"


class Login(BaseModel):
    password: str = Field(min_length=1, max_length=256)

class ServerIn(BaseModel):
    id: str = Field(min_length=1, max_length=80, pattern=r"^[a-zA-Z0-9_-]+$")
    name: str = Field(min_length=1, max_length=100)
    country_code: str = Field(default="", max_length=2, pattern=r"^([A-Za-z]{2})?$")
    protocol: str = Field(min_length=2, max_length=20)
    # Store a full JSON configuration accepted by flutter_v2ray_client.
    # Configs are returned only to an authorized administrator or the assigned client.
    config: str = Field(min_length=1, max_length=100000)
    enabled: bool = False
    sort_order: int = 0

    @field_validator("config")
    @classmethod
    def valid_json_config(cls, value: str) -> str:
        try:
            parsed = json.loads(value)
        except json.JSONDecodeError as exc:
            raise ValueError("Config must be a complete V2Ray/Xray JSON configuration") from exc
        if not isinstance(parsed, dict) or not isinstance(parsed.get("outbounds"), list) or not parsed["outbounds"]:
            raise ValueError("Config JSON must contain a non-empty outbounds array")
        return value

class BulkServers(BaseModel):
    servers: list[ServerIn] = Field(min_length=1, max_length=200)

@app.on_event("startup")
def startup():
    with db():
        pass

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/admin/login")
def login(body: Login, response: Response):
    if not ADMIN_PASSWORD or len(JWT_SECRET) < 32:
        raise HTTPException(503, "Set NOVA_ADMIN_PASSWORD and a NOVA_JWT_SECRET of at least 32 characters")
    if not hmac.compare_digest(body.password, ADMIN_PASSWORD):
        raise HTTPException(401, "Invalid credentials")
    response.headers["Cache-Control"] = "no-store"
    return {"access_token": token_for("admin"), "token_type": "bearer", "expires_in": 3600}

@app.get("/servers")
def public_servers(response: Response):
    with db() as conn:
        rows = conn.execute("SELECT id,name,country_code,protocol FROM servers WHERE enabled=1 ORDER BY sort_order,name").fetchall()
    response.headers["Cache-Control"] = "no-store"
    return [dict(row) for row in rows]

@app.get("/servers/{server_id}/config")
def public_config(server_id: str, response: Response):
    with db() as conn:
        row = conn.execute("SELECT config FROM servers WHERE id=? AND enabled=1", (server_id,)).fetchone()
    if row is None:
        raise HTTPException(404, "Server not found")
    response.headers["Cache-Control"] = "no-store"
    return {"config": row["config"]}

@app.get("/admin/servers")
def list_servers(_: str = Depends(admin)):
    with db() as conn:
        rows = conn.execute("SELECT id,name,country_code,protocol,enabled,sort_order,created_at FROM servers ORDER BY sort_order,name").fetchall()
    return [dict(row) for row in rows]

@app.get("/admin/servers/{server_id}")
def get_admin_server(server_id: str, _: str = Depends(admin)):
    with db() as conn:
        row = conn.execute("SELECT id,name,country_code,protocol,config,enabled,sort_order,created_at FROM servers WHERE id=?", (server_id,)).fetchone()
    if row is None:
        raise HTTPException(404, "Server not found")
    return dict(row)

@app.post("/admin/servers", status_code=201)
def create_server(server: ServerIn, _: str = Depends(admin)):
    with db() as conn:
        try:
            conn.execute("INSERT INTO servers(id,name,country_code,protocol,config,enabled,sort_order,created_at) VALUES(?,?,?,?,?,?,?,?)", (server.id, server.name, server.country_code.upper(), server.protocol.upper(), server.config, int(server.enabled), server.sort_order, int(time.time())))
        except sqlite3.IntegrityError:
            raise HTTPException(409, "Server id already exists")
    return {"id": server.id}

@app.put("/admin/servers/{server_id}")
def update_server(server_id: str, server: ServerIn, _: str = Depends(admin)):
    if server.id != server_id:
        raise HTTPException(400, "Path id and body id must match")
    with db() as conn:
        cur = conn.execute("UPDATE servers SET name=?,country_code=?,protocol=?,config=?,enabled=?,sort_order=? WHERE id=?", (server.name, server.country_code.upper(), server.protocol.upper(), server.config, int(server.enabled), server.sort_order, server_id))
        if cur.rowcount == 0:
            raise HTTPException(404, "Server not found")
    return {"id": server_id}

@app.post("/admin/servers/bulk", status_code=200)
def bulk_upsert(body: BulkServers, _: str = Depends(admin)):
    now = int(time.time())
    with db() as conn:
        for server in body.servers:
            conn.execute("""INSERT INTO servers(id,name,country_code,protocol,config,enabled,sort_order,created_at)
                VALUES(?,?,?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET
                name=excluded.name,country_code=excluded.country_code,protocol=excluded.protocol,
                config=excluded.config,enabled=excluded.enabled,sort_order=excluded.sort_order""",
                (server.id, server.name, server.country_code.upper(), server.protocol.upper(), server.config, int(server.enabled), server.sort_order, now))
    return {"updated": len(body.servers)}

@app.delete("/admin/servers/{server_id}", status_code=204)
def delete_server(server_id: str, _: str = Depends(admin)):
    with db() as conn:
        cur = conn.execute("DELETE FROM servers WHERE id=?", (server_id,))
        if cur.rowcount == 0:
            raise HTTPException(404, "Server not found")
    return Response(status_code=204)

@app.get("/admin", response_class=HTMLResponse)
def admin_page():
    return HTMLResponse((BASE / "admin.html").read_text(encoding="utf-8"), headers={"Cache-Control": "no-store"})
