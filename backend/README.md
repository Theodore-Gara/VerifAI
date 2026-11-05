# VerifAI Backend — Deliverable 4

Node.js/Express REST API for the VerifAI workplace-readiness mobile application.

## Stack

- Node.js 22+
- Express
- PostgreSQL
- Firebase Admin Authentication
- Node.js test runner + Supertest
- Railway deployment

## Core Deliverable 4 flow

`GET /api/tasks/next` → user answers → `POST /api/tasks/:id/attempt` → deterministic scoring → task attempt saved → skill score updated → XP/level/streak updated → achievements evaluated.

## Quick start

```bash
npm install
npm run check
npm test
npm start
```

Copy `.env.example` to `.env` and configure the database and Firebase credentials first.

## Database

Fresh database (first time only; refuses a database that already has users):

```bash
npm run db:setup
```

Existing database (the normal deploy path; applies pending migrations only):

```bash
npm run db:migrate
```

Re-apply content seeds without touching learner data:

```bash
npm run db:setup seed
```

The seed path now upserts task options, lab activities and capstone questions by
stable keys, and retires old lessons instead of deleting them. Re-running it no
longer cascades attempts or progress away. If a database has learner data but
its `schema_migrations` ledger was lost, `db:migrate` refuses to replay from
001 (002 truncates progression); restore the ledger, or run `npm run db:baseline`
if the schema is known to be current.

Back up an existing database before migration.

## Documentation

- `API.md` — endpoint reference
- `docs/openapi.yaml` — OpenAPI specification
- `USER_MANUAL.md` — beginner setup, GitHub and Railway instructions
- `DEPLOYMENT_CHECKLIST.md` — deployment verification
- `TEST_MATRIX.md` — test coverage plan
- `PROJECT_HANDOFF.md` — inherited work, Deliverable 4 additions and verification status
- `AUDIT_AND_FIXES.md` — implementation audit

## Security

Never commit `.env`, Firebase service-account credentials, passwords or API keys.

## Git workflow

Use the team's feature branch `feature/backend-d4-completion`, test locally, then open a Pull Request to `main` for review.
