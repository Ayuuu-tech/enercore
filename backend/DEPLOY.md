# Enercore Backend — Deployment

The backend is a NestJS API (Node 22+) backed by Supabase Postgres via Prisma.
It must run **continuously** — a 2‑minute cron polls Trackso and IO.Next and
snapshots each IO.Next plant's daily energy into the DB, which is what powers
Hella's week/month/year history. If the server is down, those days are lost.

## Required environment variables

Set these on the host (never commit real values — see `.env.example`):

| Variable | Purpose |
|---|---|
| `DATABASE_URL` | Supabase Postgres (Session pooler, port 5432) |
| `JWT_SECRET`, `JWT_EXPIRES_IN` | Auth token signing |
| `PORT` | Listen port (default 3000; most hosts inject their own) |
| `SUPABASE_URL`, `SUPABASE_KEY` | Supabase project |
| `TRACKSO_BASE_URL`, `TRACKSO_AUTH_HEADER`, `TRACKSO_EMAIL`, `TRACKSO_PASSWORD`, `TRACKSO_SITE_KEYS` | Trackso telemetry (Hollister, Caparo) |
| `IONEXT_BASE_URL`, `IONEXT_USERNAME`, `IONEXT_PASSWORD` | IO.Next telemetry (Hella) |

## Option A — Docker (works on any VPS / Render / Railway / Fly)

```bash
docker build -t enercore-backend .
docker run -d --restart=always -p 3000:3000 --env-file .env enercore-backend
```

The included `Dockerfile` is multi-stage: it runs `prisma generate` + `nest build`,
then ships only production deps + `dist`.

## Option B — Render / Railway (no Docker)

- **Build command:** `npm ci && npx prisma generate && npm run build`
- **Start command:** `npm run start:prod`  (= `node dist/main`)
- Add every variable from the table above in the dashboard's Environment section.
- Keep the instance "always on" (disable auto-sleep) so the 2‑min sync runs.

## Database schema

Schema is already pushed to Supabase. After any schema change, run once against
production:

```bash
npx prisma db push        # or `prisma migrate deploy` if you adopt migrations
```

## After deploy — point the app at it

Build the release app with the hosted URL baked in:

```bash
flutter build apk --release --dart-define=API_URL=https://YOUR-BACKEND-HOST/api
```

Verify: open `https://YOUR-BACKEND-HOST/api` — it should respond (not connection‑refused).
