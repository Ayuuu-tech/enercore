# Health

`GET /api` returns a liveness string. Deploys are driven by GitHub Actions
(`.github/workflows/deploy.yml`) and gated on the API coming back healthy.

_Deploys run from GitHub Actions on push to main._
