# Infra drop-in — argon2-demo.newtalaria.com

**DNS:** already live (CF proxied → 120.138.19.144).  
**VPS path:** `/opt/talaria/demos/argon2/`  
**Internal ports:** API `8180`, web `8182` (bound to 127.0.0.1 only).  
**Box source:** `/workspace/talaria/demos/argon2demo/` (symlink `demos/argon2` → same tree).

## Copy

Sync the whole `argon2demo/` tree (or at least `argon2demo_server/` + `deploy/` + root `pubspec.lock`) to `/opt/talaria/demos/argon2/`.

```bash
# From the synced tree:
cd /opt/talaria/demos/argon2
cp deploy/.env.example deploy/.env   # first time only
# edit deploy/.env → real tal_sk_… secret key + dashboard deep link
# Leave TALARIA_URL unset unless overriding the key's cell ingest host.
set -a && source deploy/.env && set +a
docker compose -f deploy/docker-compose.yml up -d --build
```

Wire / refresh `deploy/nginx-argon2-demo.conf.snippet` (`server_name argon2-demo.newtalaria.com` → `127.0.0.1:8182`), then `nginx -t && systemctl reload nginx` (or your edge reload).

## Rate limits (do both)

1. **App:** max **1** in-flight OWASP hash → HTTP **429** JSON (`error`/`message`).
2. **nginx:** `limit_req_zone … rate=6r/m` + `burst=2` on `/` (see snippet).
   - Snippet sets `limit_req_status 429` and `error_page 429|503 → JSON` so the UI never sees HTML.
3. **UI:** all three buttons disabled while in-flight; parses JSON only when Content-Type / body looks like JSON; shows “Rate limited — try again…” for 429 / non-JSON error bodies.

Each compare ≈ 19 MiB RAM + hundreds of ms CPU (PointyCastle side). Without these caps the slow button is a self-DoS.

## Recreate after two-button UI (2026-10-27)

UI now has **PointyCastle (slow)** / **Native** / **Run both**. API: `POST /demo/hash?impl=pointycastle|native|both` (default both).

Changed files (sync these at minimum):

- `argon2demo_server/web/templates/demo.html` — three-button UI
- `argon2demo_server/lib/src/demo/hash_compare.dart` — per-impl runs
- `argon2demo_server/lib/src/web/routes/demo_hash_route.dart` — `?impl=` + captureException
- `argon2demo_server/lib/src/web/widgets/demo_page.dart` / `lib/server.dart` — dashboard default `one.newtalaria.com`
- `deploy/.env.example` — dashboard default (do **not** overwrite existing `.env`)

```bash
# On VPS — sync box tree → /opt/talaria/demos/argon2/ then:
cd /opt/talaria/demos/argon2
# Preserve deploy/.env (TALARIA_API_KEY + TALARIA_DASHBOARD_URL)
set -a && source deploy/.env && set +a
docker compose -f deploy/docker-compose.yml up -d --build --force-recreate
```

Smoke:

```bash
curl -sS -X POST 'https://argon2-demo.newtalaria.com/demo/hash?impl=native'
curl -sS -X POST 'https://argon2-demo.newtalaria.com/demo/hash?impl=pointycastle'
curl -sS -X POST 'https://argon2-demo.newtalaria.com/demo/hash?impl=both'
```

## Recreate after UI / rate-limit fix (2026-10-27)

Changed files (sync these at minimum):

- `argon2demo_server/web/templates/demo.html` — client Content-Type/429 handling + in-flight debounce
- `deploy/nginx-argon2-demo.conf.snippet` — JSON body for nginx `limit_req` 429/503
- `deploy/INFRA.md` / root `README.md` — this runbook

```bash
# On VPS — sync box tree → /opt/talaria/demos/argon2/ then:
cd /opt/talaria/demos/argon2
set -a && source deploy/.env && set +a
docker compose -f deploy/docker-compose.yml up -d --build --force-recreate
# Re-apply nginx snippet (JSON error_page) then:
nginx -t && systemctl reload nginx
```

Smoke:

```bash
# Happy path
curl -sS -X POST https://argon2-demo.newtalaria.com/demo/hash
# expect JSON: pointycastleMs, nativeMs, ratio

# Rapid fire — expect 429 JSON (app and/or nginx), never HTML
for i in 1 2 3 4 5; do
  curl -sS -o /tmp/a2-$i.out -w "%{http_code} %{content_type}\n" \
    -X POST https://argon2-demo.newtalaria.com/demo/hash &
done
wait
head -c 120 /tmp/a2-*.out; echo
```

UI check: mash “Run compare” — button stays disabled while hashing; pink banner (if any) says rate-limited, never `Unexpected token '<'`.

## Health check

```bash
curl -sS https://argon2-demo.newtalaria.com/demo/hash
# expect: pointycastleMs, nativeMs, ratio
```

Enable **tracing** on the Talaria project for the key’s environment.

Build note: image uses `dart build cli` so `serverpod_argon2` native `.so` is bundled.
