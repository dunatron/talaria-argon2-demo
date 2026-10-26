# Talaria · Serverpod Argon2 live demo

Thin **Serverpod 4.0.4** app that hashes a **fixed fake password** twice under
OWASP Argon2id params (`m=19456`, `t=2`, `p=1`):

| Path | Span name | Impl |
|---|---|---|
| Pre (slow) | `auth.passwordHash.pointycastle` | PointyCastle `Argon2BytesGenerator` (Serverpod auth ≤4.0.2) |
| Post (native) | `auth.passwordHash.native` | `serverpod_argon2` **0.1.0** (Serverpod ≥4.0.3) |

Returns **milliseconds only** — never hash bytes, never real user data.

| | |
|---|---|
| Subdomain | `argon2-demo.newtalaria.com` (CF DNS already live → VPS) |
| VPS path | `/opt/talaria/demos/argon2/` |
| Internal ports | API **8180**, web **8182** |
| Pins | `/workspace/talaria/research/serverpod-argon2-demo-pins-2026-10-27.md` |

Local smoke (this box, AOT bundle): **PointyCastle ~147–172 ms**, **native ~31–34 ms**, **~4.3–5.5×**.

---

## Local run (native Argon2)

`dart bin/main.dart` / JIT **does not** load `serverpod_argon2` native assets.
Always use **`dart build cli`**:

```bash
cd /workspace/talaria/demos/argon2demo
cd argon2demo_server && dart pub get && serverpod generate && cd ..

export TALARIA_API_KEY=tal_live_YOUR_DEV_KEY   # optional for timings-only; required for waterfalls
export TALARIA_RELEASE=argon2-demo-local
export TALARIA_DASHBOARD_URL=https://one.newtalaria.com   # UI deep link

cd argon2demo_server
dart build cli --target bin/main.dart --output build
./build/bundle/bin/main --mode development
```

- UI: http://localhost:8082/
- Compare: `curl -sX POST 'http://localhost:8082/demo/hash?impl=both' | jq`
- Single path: `?impl=pointycastle` or `?impl=native`
- RPC: `client.demo.hash()` on API port **8080** (dev) / **8180** (production)

Without `TALARIA_API_KEY` the server still returns timings (NoOp spans). With a
`tal_live_…` key, enable **tracing** on that project environment for waterfalls.

---

## Talaria wiring

```dart
Serverpod(..., databaseInterceptor: TalariaServerpod.interceptDatabase, …);
await TalariaServerpod.init(TalariaOptions(
  dsn: 'https://ingest.newtalaria.com',
  apiKey: Platform.environment['TALARIA_API_KEY']!,
  release: Platform.environment['TALARIA_RELEASE'] ?? 'argon2-demo',
  tags: {'service': 'argon2-demo'},
));
TalariaServerpod.attach(pod);
```

| Env | Required | Notes |
|---|---|---|
| `TALARIA_API_KEY` | for ingest | `tal_live_…` from Project settings → Client keys |
| `TALARIA_DSN` | no | default `https://ingest.newtalaria.com` |
| `TALARIA_RELEASE` | no | default `argon2-demo` |
| `TALARIA_DASHBOARD_URL` | no | shown under “Run compare” |

---

## Rate limits / DoS

Each compare ≈ **19 MiB** RAM + hundreds of ms CPU (PointyCastle side).

1. **App:** max **1** in-flight compare → HTTP **429** JSON (`too_many_requests`).
2. **nginx:** `limit_req` ~6 req/min/IP — see `deploy/nginx-argon2-demo.conf.snippet`
   (`limit_req_status 429` + JSON `error_page`, not HTML).
3. **UI:** All buttons disabled while in-flight; never `response.json()` on HTML;
   429 / non-JSON → “Rate limited — try again…”.
4. Fixed password only — no accounts, no `/login`.

Verified: parallel POSTs → one `200` + one `429` (app). nginx overload also JSON.

---

## Docker / Infra

See **`deploy/INFRA.md`** (short runbook for the VPS).

```bash
# On VPS under /opt/talaria/demos/argon2/ after syncing this tree:
cp deploy/.env.example deploy/.env   # set TALARIA_API_KEY + dashboard URL
set -a && source deploy/.env && set +a
docker compose -f deploy/docker-compose.yml up -d --build
```

- Compose binds `127.0.0.1:8180` (API) and `127.0.0.1:8182` (web).
- nginx `server_name argon2-demo.newtalaria.com` → `127.0.0.1:8182`.
- Dockerfile uses **`dart build cli`** so `libserverpod_argon2.so` is in the image.
- DNS already live (Cloudflare proxied). TLS + nginx live wire: Infra.

---

## Layout

```
argon2demo/
  README.md
  pubspec.yaml                 # workspace root
  argon2demo_server/           # Serverpod server + Relic web
    Dockerfile
    lib/server.dart            # Talaria init/attach
    lib/src/demo/              # HashCompare + DemoEndpoint
    lib/src/web/routes/        # / and /demo/hash
    web/templates/demo.html    # PointyCastle / Native / Run both UI
  argon2demo_client/           # generated client
  deploy/
    INFRA.md
    docker-compose.yml
    nginx-argon2-demo.conf.snippet
    .env.example
```

Do **not** contact Serverpod from this demo workstream.
