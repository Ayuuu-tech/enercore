# Enercore Backend — Deployment

The backend is a NestJS API (Node 22+) backed by Supabase Postgres via Prisma.
It must run **continuously** — a 2-minute job polls Trackso and IO.Next, records
telemetry, and snapshots each plant's daily energy. Bills are computed from the
plants' cumulative counters, so an outage no longer loses billed units, but any
downtime is still a hole in the charts and history.

## Live deployment (Azure App Service)

| | |
|---|---|
| **API** | `https://enercore-api-11148.azurewebsites.net/api` |
| Resource group | `enercore-rg` (Central India) |
| Service | App Service, Linux, Node 22, plan `enercore-plan` (B1) |
| Always On | enabled — required, or the 2-minute sync would be suspended |
| Database | Supabase Postgres (unchanged) |

### Why not Docker / Container Apps

The repo has a working `Dockerfile`, but the Azure **for Students** subscription
blocks ACR Tasks (cloud image builds) and Container App environments in most
regions. App Service with a prebuilt artifact sidesteps both. If you move to a
pay-as-you-go subscription, `Dockerfile` + Container Apps is the better home.

## Redeploying

Oryx (Azure's build step) is too slow on B1 — it times out compiling Nest. So we
**build locally and ship the artifact**, with Azure-side build disabled:

```bash
cd backend
npx prisma generate && npm run build          # -> dist/

# stage: prod deps + generated Prisma client + dist
STAGE=$(mktemp -d)
cp package.json package-lock.json "$STAGE/"
(cd "$STAGE" && npm ci --omit=dev --ignore-scripts)
cp -r dist prisma prisma.config.ts "$STAGE/"
cp -r node_modules/.prisma node_modules/@prisma "$STAGE/node_modules/"
# the client is already generated; don't let Azure re-run it
(cd "$STAGE" && npm pkg delete scripts.postinstall)

(cd "$STAGE" && zip -qr /tmp/prebuilt.zip .)
az webapp deploy -n enercore-api-11148 -g enercore-rg \
  --src-path /tmp/prebuilt.zip --type zip --async true
```

Startup command is `npm run start:prod` (= `node dist/src/main`).

## Environment variables

Set as App Service application settings — **never** commit real values
(see `.env.example`). To change one:

```bash
az webapp config appsettings set -n enercore-api-11148 -g enercore-rg \
  --settings KEY="value"
```

| Variable | Purpose |
|---|---|
| `DATABASE_URL` | Supabase Postgres (Session pooler, port 5432) |
| `JWT_SECRET`, `JWT_EXPIRES_IN` | Auth token signing |
| `SUPABASE_URL`, `SUPABASE_KEY` | Supabase project |
| `TRACKSO_BASE_URL`, `TRACKSO_AUTH_HEADER`, `TRACKSO_EMAIL`, `TRACKSO_PASSWORD`, `TRACKSO_SITE_KEYS` | Trackso telemetry (Hollister, Caparo) |
| `IONEXT_BASE_URL`, `IONEXT_USERNAME`, `IONEXT_PASSWORD` | IO.Next telemetry (Hella) |
| `CORS_ORIGINS` | Comma-separated browser origins. Unset = no cross-origin browser access. The mobile app sends no `Origin`, so it is unaffected. |
| `SCM_DO_BUILD_DURING_DEPLOYMENT`, `ENABLE_ORYX_BUILD` | Both `false` — we ship a prebuilt artifact. |

## Building the app against it

```bash
flutter build apk --release \
  --dart-define=API_URL=https://enercore-api-11148.azurewebsites.net/api
```

Without `API_URL`, the app falls back to the local dev URLs (LAN IP / localhost).

## Database schema

Schema is already applied. After a schema change, run once against production:

```bash
npx prisma db push        # or `prisma migrate deploy` once you adopt migrations
```

## Logs

```bash
az webapp log tail -n enercore-api-11148 -g enercore-rg
```
