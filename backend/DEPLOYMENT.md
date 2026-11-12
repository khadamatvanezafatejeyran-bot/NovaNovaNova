# Deploying the NOVA management API

This API is the source of truth for the active server catalogue and profiles. Updating an existing server record here does not require publishing a new Android APK: installed clients fetch the selected profile from the API when a connection is started. To apply a changed profile to an active session, disconnect and reconnect.

## Configure a deployment

1. Deploy this `backend/` directory to a Python 3.11+ host with persistent storage. Mount persistent storage for `NOVA_DB_PATH`; the SQLite database contains server profile secrets and must not be publicly downloadable.
2. Put the API behind HTTPS. Do not expose the development server directly to the internet. Configure the reverse proxy to limit request sizes, rate-limit `/admin/login`, and restrict `/admin` to trusted operators if possible.
3. Set `NOVA_ADMIN_PASSWORD` to a unique long random password and `NOVA_JWT_SECRET` to at least 32 random characters using the hosting provider's secret manager. Never commit these values or put them in the Flutter APK.
4. Set `NOVA_ENV=production` to disable the interactive API docs endpoint. Start with `uvicorn app:app --host 127.0.0.1 --port 8000` behind the HTTPS reverse proxy. Configure database backup, monitoring, and restore procedures on the host.
5. Build the client with the public HTTPS API base URL: `flutter build apk --dart-define=NOVA_API_BASE_URL=https://your-api-host.example`. The URL is not a credential.

## Replace or add profiles

1. Open `https://your-api-host.example/admin` and sign in with `NOVA_ADMIN_PASSWORD`.
2. Use **افزودن سرور** for a new ID, or select **ویرایش / تعویض کانفیگ** for an existing server.
3. Enter a complete JSON profile compatible with the exact deployed `flutter_v2ray_client`/Xray core version. The API validates JSON shape, but that does not prove a profile is valid, reachable, or secure.
4. Verify the server address geolocation independently before setting its country code. Leave it blank if unknown.
5. Keep new or untested profiles disabled. Test them on a real Android device and enable them only after verification.
6. Save. The API catalogue changes immediately; users need not reinstall the APK. They must reconnect to use a profile that was changed while their VPN tunnel was active.

The API necessarily delivers a profile to a client that connects to it. Do not treat an APK or public client API as a way to keep a profile secret from its device owner. This starter does not include user accounts, subscription limits, multi-admin roles, audit logging, or automated health checks; add and review those before offering a public service.
