# VerifAI — Backend Tasks

Work items for the backend team, grounded in the current code and the live
Railway database. Priority key: **P0 = blocks the core product**,
**P1 = a shipped feature is currently fake**, **P2 = quality / maintainability**.

> Verified against the live Railway Postgres on 2026-10. See the "Live data
> findings" section — the deployed database does **not** match the repo's
> `db/schema.sql` / `db/seed.sql`.

---

## P0 — Reconcile the task data model and fix scoring

### The live data does not match the repo
The live `tasks` table has **10 columns**:

```
id, track_id, scenario, embedded_flaw, correct_answer, feedback,
dimension, difficulty, created_at, title
```

But `backend/db/schema.sql` defines `tasks` **without `embedded_flaw`**, and
`backend/db/seed.sql` inserts short titles and `correct_answer` values prefixed
with `Keywords: …`. The live rows instead have:

- `embedded_flaw` populated (the deliberate flaw), **NOT NULL**,
- `title` **identical to `scenario`** (the same sentence),
- `correct_answer` as a **plain full sentence** (no `Keywords:` prefix).

**Why it matters:** a fresh database built from the repo would be missing
`embedded_flaw` and would carry a different answer format, so the app only
works against the migrated prototype data. The repo must be the reproducible
source of truth.

**Do:**
- Add `embedded_flaw` to `schema.sql`.
- Align `seed.sql` with the live curated content (16 tasks, 4 per track), and
  decide the canonical `title` (short headline) vs `scenario` (the AI output).

### `embedded_flaw` is never returned to the app
`getNextTask` selects only `id, track_id, title, scenario, dimension,
difficulty`. The product spec says users *identify the issue*, but the app can
never see the flaw.

**Do:** return `embedded_flaw` from `GET /api/tasks/next` (and keep
`correct_answer`/`feedback` hidden until after the attempt).

### Scoring is mismatched with the data
`services/scoringService.js#extractKeywords()` looks for a `Keywords:` prefix.
The live `correct_answer` has none, so it tokenizes the **entire sentence** into
noisy keywords. A multiple-choice option cannot match those tokens, so scores
collapse toward **0** even for correct answers — the core loop is broken.

**Do — pick one and make data + code agree:**
- **(a)** keep free-text + keyword scoring, and store `correct_answer` in
  `Keywords: …` form; **or**
- **(b)** move to multiple-choice (see below) and score the selected option.

### Move to the multiple-choice model (pending restructure)
The app UI is multiple-choice, but the options are hardcoded placeholders and
the attempt sends the selected option's text as a free-text answer.

**Do:**
- Add `task_options (id, task_id, label, is_correct, sort_order)`.
- Return options from `GET /api/tasks/next` (never the correct flag).
- Accept `option_id` (+ optional `explanation`) in
  `POST /api/tasks/:id/attempt` and score accordingly.

**Effort:** Medium (schema + seed + controller + scoring path).

---

## P0 — Task volume and "run out" behaviour

`getNextTask` excludes already-attempted tasks, and the seed has only **4 tasks
per track**. After four submissions the user gets `task: null` ("All caught
up") **permanently**.

**Do:** decide and implement one of:
- (a) add more tasks per track,
- (b) allow repeats / rotation,
- (c) a daily-task reset.

**Why:** the dashboard markets a "next/daily" task; the loop dead-ends after ~4
tasks per user, which kills demos and real usage.

**Effort:** content (seed) + small logic change.

---

## P1 — Leaderboard / scoreboard endpoint

**Do:** `GET /api/leaderboard?scope=global|track&limit=…` returning
`{ rank, display_name, xp, streak, track }`.

**Why:** the Scoreboard screen is 100% hardcoded (10 fake users) and the
dashboard/profile show **"Rank: —"** because there is no endpoint.
`user_progress` already stores `xp/level/streak`, so the aggregation is
straightforward.

**Effort:** Small–medium (one aggregate query).

---

## P1 — Activity / streak history endpoint

**Do:** `GET /api/progress/activity?range=7d` → per-day
`{ date, xp, attempts }`.

**Why:** the Progress screen's weekly chart is hardcoded. The data exists in
`task_attempts.submitted_at` / `xp_earned`; it just is not exposed.

**Effort:** Small.

---

## P2 — Achievements catalog endpoint

**Do:** `GET /api/achievements` (full catalog: `code, name, description`).

**Why:** only `/achievements/me` (earned rows) exists, so the app hardcodes the
5-item catalog to render locked badges. A catalog endpoint makes the backend the
single source of truth — adding an achievement would not require an app release.

**Effort:** Small.

---

## P2 — Track roadmap / milestones endpoint

**Do:** milestones per track (`title, description, order, xp_reward, unlock
criteria`) plus per-user status.

**Why:** the Track screen's milestone skill-tree is hardcoded. If the roadmap is
a real surface it needs backend data; if it is decorative, say so and the
frontend will label it as such.

**Effort:** Medium (new table + progress derivation).

---

## P2 — Streak timezone correctness

**Do:** compute the streak against the user's local day, not the server's
`CURRENT_DATE` (UTC).

**Why:** `submitAttempt` uses `CURRENT_DATE` and `last_activity_date`. A SAST
user submitting after 22:00 would have the attempt counted on the wrong calendar
day, so streaks can break incorrectly.

**Effort:** Small (accept a client timezone/offset or a `local_date`).

---

## Already fine (no changes required)
- `/auth/sync`, `/users/me`, `/users/profile`, `/tracks`, `/progress/me`,
  `/tasks/:id/attempt` return everything the app needs.
- Health check, rate limiting, and the error format are good.

## Suggested order
1. P0 task model + scoring + `embedded_flaw`
2. P0 content volume / run-out policy
3. P1 leaderboard
4. P1 activity / streak history
5. P2 achievements catalog
6. P2 milestones
7. P2 streak timezone
