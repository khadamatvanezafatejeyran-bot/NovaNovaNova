# NOVA VPN — Flutter Android client

Flutter Android client for NOVA VPN by JEYRAN GROUP. The client uses `flutter_v2ray_client` for the actual Android VPN tunnel. There are no bundled/demo servers or fabricated ping/speed values. If the backend is not configured or has no active servers, the app says so.

## Run the Android app

1. Install Flutter (Dart SDK >= 3.3) and Android SDK.
2. Set the deployed backend HTTPS URL at build/run time (this is a public service URL, not a secret):

   ```sh
   flutter pub get
   flutter run --dart-define=NOVA_API_BASE_URL=https://vpn-api.example.com
   ```

The app reads active server metadata from `GET /servers`; config is fetched only when the user connects from `GET /servers/{id}/config`. Admin changes therefore reach already-installed apps without publishing a new APK. A config cached by no-store HTTP directives is not persisted by the client.

The VPN status is driven by the plugin status callback; tapping Start is not treated as proof of connection. Protocol support depends on the selected plugin/Xray core version. Do not enable a protocol until it has been tested on the actual Android build and device.

## Admin-managed configs

`backend/` contains a FastAPI + SQLite management API and a browser admin page. It supports add, edit/replace, enable/disable, order, delete, and bulk upsert. For a replacement, open `/admin`, sign in, click **ویرایش / تعویض کانفیگ**, replace the full JSON profile, then save. The app gets the replacement at its next connection attempt; an already-running tunnel continues using the config it started with, so disconnect/reconnect to apply a changed config. The panel also supports bulk JSON import.

The API expects a complete V2Ray/Xray JSON profile accepted by `flutter_v2ray_client` (valid JSON object with nonempty `outbounds`). Raw `vless://`, `vmess://`, or other share URLs are not accepted as complete JSON in this version. Never expose config contents in a public issue or log. Country code must be verified by the operator against the endpoint IP's geolocation; the app does not infer a country from the profile remark.

### Run backend

```sh
cd backend
python -m venv .venv
. .venv/bin/activate  # Windows: .venv\\Scripts\\activate
pip install -r requirements.txt
export NOVA_ADMIN_PASSWORD='use-a-unique-long-password'
export NOVA_JWT_SECRET="$(python -c 'import secrets; print(secrets.token_urlsafe(48))')"
uvicorn app:app --host 127.0.0.1 --port 8000
```

Open `http://127.0.0.1:8000/admin` for local testing. For real use, deploy behind HTTPS, configure secrets in the hosting provider (never in source control/APK), restrict admin access, use persistent storage/backups for SQLite, and use rate limiting at the reverse proxy. The in-memory admin bearer token expires in one hour. Public endpoints intentionally deliver the selected server profile to the client: a determined user can inspect data delivered to their device, so the APK/API cannot make a profile secret from its owner.

## Not yet production-complete

This source does not provision hosting, confirm the correctness or location of any server, build/sign an APK, provide account/subscription enforcement, establish a privacy/legal policy, or integrate ads. Ads remain intentionally omitted until tunnel behavior is tested. Before production, run Flutter analysis/tests and backend tests, validate all profiles on real Android devices, configure backups/monitoring/rate limits, review privacy and local legal requirements, and perform security review. 
