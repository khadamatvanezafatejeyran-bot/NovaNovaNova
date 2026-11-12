# NOVA VPN — Flutter Android client

Flutter Android client for NOVA VPN by JEYRAN GROUP. The client uses `flutter_v2ray_client` for the actual Android VPN tunnel. No sample servers, fake speed, fake ping, or simulated connection status are included: until a real API URL and working server records are configured, the app clearly reports that no servers are available.

## Run

1. Install Flutter (Dart SDK >= 3.3) and Android SDK.
2. Configure a real HTTPS backend URL at build time:

   ```sh
   flutter pub get
   flutter run --dart-define=NOVA_API_BASE_URL=https://vpn-api.example.com
   ```

3. Use a valid admin-managed server config on the backend. Country codes should be populated only from verified server IP geolocation by the operator; the client does not infer geography from a link remark.

The VPN status is driven by the plugin status callback; pressing Start is not treated as proof of connection. Server protocol support depends on the selected plugin/Xray core version. Hysteria2 must not be enabled unless the deployed core actually supports it.

## Backend

`backend/` contains a small FastAPI + SQLite management API and a minimal admin page. It is a starter deployment, not a hosted service. Set a long random `NOVA_ADMIN_PASSWORD` and `NOVA_JWT_SECRET`, use HTTPS at a reverse proxy, restrict admin access, and back up the database. Do not commit credentials. App-facing config delivery is necessarily visible to a device running the client; hiding configuration strings in an APK or API response is not a security boundary. Production deployments should add user authentication, rate limiting, audit controls, and a secure delivery policy appropriate to the service.

Run backend locally:

```sh
cd backend
python -m venv .venv
. .venv/bin/activate  # Windows: .venv\\Scripts\\activate
pip install -r requirements.txt
export NOVA_ADMIN_PASSWORD='replace-with-a-long-random-password'
export NOVA_JWT_SECRET='replace-with-at-least-32-random-bytes'
uvicorn app:app --host 127.0.0.1 --port 8000
```

Open `/admin` for the manager. API docs are available at `/docs` in development. Server records are disabled by default and must be explicitly enabled by an administrator. The backend does not claim that a server works just because a profile parses; test it independently.

## Current scope

This commit provides the real Android client flow, server API contract/backend, server management UI, basic bilingual UI, and persistent settings. Production hosting, verified IP geolocation, account/subscription system, privacy/legal review, ad SDK integration, and signed APK release require operator credentials, infrastructure, and testing. Ads are intentionally omitted until the VPN core is stable.
