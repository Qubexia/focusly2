# Focaly Backend

NestJS modular-monolith backend for the Focaly Study Management Mobile App. See `../specs/001-focaly-backend/` for the spec, plan, data model, and OpenAPI contract, and `../docs/architecture.md` for the reference architecture.

## Quick start

```bash
npm ci
npm run start:dev        # API on http://localhost:3000 (Swagger at /docs once Phase 2 lands)
npm run start:worker:dev # BullMQ consumers + cron
```

See `../specs/001-focaly-backend/quickstart.md` for the full setup walkthrough, env reference, and per-user-story verification steps.

## Layout

`src/` holds 16 feature modules under `modules/`, cross-cutting concerns under `common/`, infrastructure adapters under `infrastructure/`, and shared event types under `shared/`. Both runtime entries (`main.ts` for the API web service, `worker.ts` for the background worker) live at the top of `src/`.

## Deployment

Render (MVP) — web + worker services declared in `render.yaml`. CI tags `v*` trigger the `deploy.yml` workflow which POSTs Render deploy hooks. No Docker at any tier (see `../docs/architecture.md` §12).
