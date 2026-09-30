# Railway Deployment Checklist

## Before deployment

- [ ] Work is on `feature/backend-d4-completion`.
- [ ] No `.env` or Firebase service-account file is committed.
- [ ] `npm install` completes.
- [ ] `npm run check` passes.
- [ ] `npm test` passes.
- [ ] Database schema/migration has been reviewed.
- [ ] Seed data provides 4 tracks and 16 tasks.

## Railway variables

Set these in the Railway service Variables panel:

- `DATABASE_URL` — use the team's PostgreSQL connection string.
- `FIREBASE_SERVICE_ACCOUNT_JSON` — complete Firebase service-account JSON as one environment-variable value.
- `NODE_ENV=production`
- `ALLOWED_ORIGINS` — client origins if applicable.

Do not paste secrets into GitHub files, README files, commits, screenshots, or chat.

## Deploy

The repository contains `railway.json` with `npm start` and `/api/health` as the healthcheck.

After deployment, open:

```text
GET https://<railway-domain>/api/health
```

Expected successful response:

```json
{
  "status": "ok",
  "db": "connected"
}
```

## Production verification

Test in this order:

1. `/api/health`
2. `/api/tracks`
3. Firebase-authenticated `/api/auth/sync`
4. `/api/users/me`
5. `/api/users/profile`
6. `/api/tasks/next`
7. `/api/tasks/:id/attempt`
8. `/api/progress/me`
9. `/api/achievements/me`

Verify a full user journey:

`Firebase login → sync → choose track → next task → submit answer → feedback → XP/level/streak → progress → achievement`.
