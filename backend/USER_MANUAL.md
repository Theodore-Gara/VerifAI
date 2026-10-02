# VerifAI Backend — Beginner User Manual

This guide is for a team member who is still learning GitHub, Node.js, PostgreSQL and Railway.

## 1. What this backend does

The backend is the server used by the VerifAI Flutter application. It handles Firebase-authenticated users, industry tracks, workplace tasks, answer submissions, rule-based scoring, XP, levels, streaks, skill scores and achievements.

## 2. Important project rule

This is a group project. Work on the feature branch `feature/backend-d4-completion`. Do not directly push to `main`. Open a Pull Request when the work has been tested.

## 3. Prerequisites

Install:
- Node.js 18+ (20+ recommended)
- Git
- PostgreSQL, or a PostgreSQL database supplied by the team/Railway
- Firebase project credentials

## 4. Install dependencies

Open a terminal inside the `backend` folder:

```bash
npm install
```

## 5. Configure environment variables

Copy `.env.example` to `.env`.

Set values for:
- `PORT`
- `DATABASE_URL`
- `FIREBASE_SERVICE_ACCOUNT_JSON` OR `FIREBASE_SERVICE_ACCOUNT_PATH`
- `NODE_ENV`
- `ALLOWED_ORIGINS`
- optional rate-limit settings

Never commit `.env` or a Firebase private key.

## 6. Database setup

For a new database:

1. Run `db/schema.sql`.
2. Run `db/seed.sql`.

For the team's existing prototype database:

1. Back up the database first.
2. Review `db/migrate_d4.sql`.
3. Run the migration once.
4. Run `db/seed.sql` to add the Deliverable 4 tracks, tasks and achievements.

Do not run a migration against a production database without a backup and team approval.

## 7. Start locally

```bash
npm start
```

The server uses `PORT` from the environment, or port 3000 by default.

Check:

```text
GET /api/health
```

A healthy response should report `status: ok` and `db: connected`.

## 8. Run tests

```bash
npm test
```

For a syntax check:

```bash
npm run check
```

## 9. Main API routes

Public:
- `GET /api/health`
- `GET /api/tracks`

Firebase-authenticated:
- `POST /api/auth/sync`
- `GET /api/users/me`
- `PUT /api/users/profile`
- `GET /api/tasks/next`
- `POST /api/tasks/:id/attempt`
- `GET /api/progress/me`
- `GET /api/achievements/me`

Authentication header:

```text
Authorization: Bearer <Firebase ID token>
```

## 10. How the attempt flow works

1. The mobile app requests a task.
2. The backend does not expose the reference answer.
3. The user submits an answer.
4. The backend normalizes and scores the answer using deterministic keyword/concept matching.
5. The attempt is saved.
6. The relevant skill score is updated.
7. XP and level are updated.
8. The streak is updated based on activity date.
9. Eligible achievements are awarded once.
10. The response returns the result needed by the frontend.

## 11. GitHub — safest beginner workflow

### First make a backup branch

In the GitHub repository, create:

```text
backup-before-d4-backend
```

Then return to:

```text
feature/backend-d4-completion
```

### Upload the backend

Do not create another repository.

Do not upload a ZIP as the final project file.

The repository should contain the actual backend folders and files inside the existing `backend/` folder.

Before committing, check that you are on:

```text
feature/backend-d4-completion
```

Use small commits such as:

```text
feat: complete deliverable 4 backend
```

After testing, open a Pull Request from:

```text
feature/backend-d4-completion
```

to:

```text
main
```

Do not merge it yourself unless the team's agreed review process allows it.

## 12. Railway deployment

1. Open the team's Railway project.
2. Deploy the backend service from the GitHub repository.
3. Set the environment variables in Railway.
4. Use `npm start` as the start command unless Railway detects it automatically from `package.json`.
5. Confirm the service is running.
6. Open `/api/health`.
7. Confirm the database reports `connected`.

Required production variables:

```text
DATABASE_URL
FIREBASE_SERVICE_ACCOUNT_JSON
NODE_ENV=production
ALLOWED_ORIGINS=<Flutter/web origin if applicable>
```

Never paste secrets into GitHub files.

## 13. Common problems

### `DATABASE_URL is not set`
Create `.env` locally or configure the variable in Railway.

### Firebase token errors
Confirm the Firebase service account belongs to the same Firebase project used by the mobile app.

### `User not found. Call /api/auth/sync first.`
The Firebase-authenticated user has not yet been synchronized into the PostgreSQL `users` table.

### Task submission says the task is unavailable
The user's selected industry track must match the task's track.

### CORS errors
Add the frontend origin to `ALLOWED_ORIGINS`.

### Database migration errors
Stop, back up the database, inspect the exact error, and do not repeatedly rerun a migration blindly.

## 14. What must never be committed

Never commit:
- `.env`
- Firebase service-account JSON
- database passwords
- API keys
- private keys
- `node_modules/`

## 15. Final pre-submission checklist

- [ ] `npm install` succeeds
- [ ] `npm run check` succeeds
- [ ] `npm test` succeeds
- [ ] database schema is applied
- [ ] seed data is applied
- [ ] Firebase authentication works
- [ ] `/api/health` works
- [ ] all required routes are documented
- [ ] no secrets are committed
- [ ] branch is `feature/backend-d4-completion`
- [ ] Pull Request created
- [ ] Railway deployment verified
- [ ] Flutter team has the correct API base URL
