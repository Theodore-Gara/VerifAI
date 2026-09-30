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

- `DATABASE_URL` — the private Railway connection string
  (`postgres.railway.internal`, not the public proxy URL). On the `VerifAI`
  service this is currently a **literal value, not a live reference**; see
  [Migrating off `railway.json`](#migrating-off-railwayjson-to-infrastructure-as-code).
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

---

# Migrating off `railway.json` to Infrastructure as Code

`railway.json` is **Config as Code** and is deprecated. It is replaced by
`.railway/railway.ts` (**Infrastructure as Code**, or IaC).

**Hard cutoff: 2026-12-01.** After that date existing `railway.json` /
`railway.toml` files stop being read during deploys, and the service falls back
to whatever the dashboard holds. This file was written on 2026-09-30, while the
current setup still works.

## Current state

Recorded 2026-09-30, before migrating:

| Thing | Value |
|---|---|
| Project | `VerifAI` (`5ca1f96f-2ac9-4716-bf21-f7d28323af47`) |
| Environment | `production` (`81ed5ee5-a8ed-4ed0-990b-19a1e11d6ef5`) |
| Backend service | `VerifAI` (`b6a62fd7-6fd4-4d22-9317-61f60c11c83d`) |
| Database service | `Postgres` (`78a5b556-43fd-40de-950d-fd5257fee08b`) |
| Config file | `backend/railway.json` |
| Domain | `https://verifai-production-29ae.up.railway.app` |

Three things to know before starting:

1. **The backend has no `package.json` at the repo root.** Railway builds from
   the root unless a root directory is supplied, so a git-driven build fails.
   The current deployment works only because it was uploaded with `railway up`
   from inside `backend/`. The IaC file must declare the root directory (below).
2. **`DATABASE_URL` on the service is a literal**, not a live reference. It
   holds the private URL `postgres.railway.internal`, which is correct, but a
   Postgres password rotation will not propagate. See "Optional" at the end.
3. **The CI deploy job never deploys.** `.github/workflows/ci-cd.yml` gates on
   `secrets.RAILWAY_API_TOKEN` and `secrets.RAILWAY_SERVICE_ID`, and neither
   secret exists, so the job exits 0 with "skipping deploy". Merging to `main`
   does not deploy. Fix this independently of the migration — a Railway project
   token is scoped to one environment, see
   <https://docs.railway.com/infrastructure-as-code>.

## Steps

Run from the **repository root** unless noted. The authoring file is written to
the repo root; the CLI finds it by walking up from the current directory, so
`backend/` also works for `plan` and `apply`.

```bash
# 1. The CLI needs the TypeScript SDK to evaluate a .ts authoring file.
npm install railway

# 2. Generate the file. Dry-run without --apply.
railway config migrate --service VerifAI

# 3. Write it, and clear the Config as Code setting on the service.
railway config migrate --service VerifAI --apply

# 4. Hand-edit .railway/railway.ts -- see "What migrate gets wrong" below.

# 5. Review before touching anything. `plan` is read-only.
railway config plan

# 6. Apply.
railway config apply

# 7. Commit the result, including the .railway/ directory.
```

`--apply` also clears Railway's Config as Code setting for the service. Add
`--delete-files` to remove the old `backend/railway.json` in the same step;
otherwise delete it manually, because a service cannot be managed by both
systems at once and `config plan` will refuse while `railway.json` is still
present.

## What `migrate` gets wrong

All four of these were observed on a dry run of this repository. Review the
generated file against them.

1. **Service name is wrong without `--service`.** `migrate` derives the name
   from the containing directory, so it emits `service("backend", ...)` for
   `backend/railway.json`. Applying that would create a *second* service rather
   than configure the existing `VerifAI` one. `--service VerifAI` fixes it.

2. **The root directory is not generated.** Without it the build context
   problem above remains. Add it by hand:

   ```ts
   const VerifAI = service("VerifAI", {
     source: github("Theodore-Gara/VerifAI", { rootDirectory: "backend" }),
     start: "npm start",
     healthcheck: "/api/health",
     healthcheckTimeout: 30,
   });
   ```

3. **The restart policy is dropped.** `restartPolicyType: "ON_FAILURE"` and
   `restartPolicyMaxRetries: 10` from `railway.json` do not survive, and
   `restartPolicy` is not in the documented TypeScript DSL. These match Railway's
   defaults, so nothing should change in practice — verify rather than assume.

4. **No database wiring is generated.** `migrate` only translates what
   `railway.json` contained, and `railway.json` had no environment variables.

## Footguns

- **Do not let IaC claim the database casually.** The idiomatic way to get a
  live reference is `postgres("postgres")` plus
  `env: { DATABASE_URL: db.env.DATABASE_URL }`. Be aware that declaring the
  database makes this repository **own that resource**, and the first
  `config apply` records the ownership. The `Postgres` service here has a volume
  with live data on it, and volume lifecycle is only "intentionally
  conservative". Manual re-running of one command on password rotation is
  cheaper than transferring ownership of a live database. If you do adopt it,
  `railway config partials` shows what each partial owns.
- **Never apply a plan that removes a `tracing` block you did not remove
  yourself.** The SDKs silently drop `tracing`, so `config plan` against a
  traced service proposes turning tracing *off*. Not currently an issue here,
  but it is a live footgun.
- **IaC is not read during deploys.** Railway evaluates `.railway/railway.ts`
  through the CLI, locally or in CI. The file governs configuration ownership;
  it does not by itself make builds work. That still needs `source` with
  `rootDirectory`, and a deploy trigger (Railway's GitHub integration, or
  `railwayapp/config` in CI).
- **`railway config plan` is safe** — it only reads Railway state. Use it
  liberally. `apply` always runs a fresh plan first and rejects a stale one.

## Optional: a real `DATABASE_URL` reference

Only worth doing alongside the database-ownership decision above.

```ts
const db = postgres("postgres");

const VerifAI = service("VerifAI", {
  source: github("Theodore-Gara/VerifAI", { rootDirectory: "backend" }),
  start: "npm start",
  healthcheck: "/api/health",
  env: {
    NODE_ENV: "production",
    DATABASE_URL: db.env.DATABASE_URL,
  },
});

return project("VerifAI", { resources: [VerifAI, db] });
```

Use `preserve()` for any value the CLI cannot read back, so secrets stay in
Railway instead of being written into source.

## Reference

- <https://docs.railway.com/infrastructure-as-code>
- <https://docs.railway.com/infrastructure-as-code/reference>
- <https://docs.railway.com/config-as-code>
