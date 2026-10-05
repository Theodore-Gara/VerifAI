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

## P0 — Restructure the task schema (per-feature tables)

The live `tasks` table forces four different features into one shape — a generic
`dimension` + `embedded_flaw` (NOT NULL for *every* row) + a single-sentence
`correct_answer`. It has nowhere to store Judgement/R&G options or Prompt Design
criteria, and the columns don't fit the new per-feature designs.

**Do:** split the task content into per-feature tables behind a thin anchor.

**Anchor (no seed content — exists only so `task_attempts`/`skill_scores` have one FK):**
```sql
CREATE TABLE tasks (
  id SERIAL PRIMARY KEY,
  feature VARCHAR NOT NULL CHECK (feature IN ('verification','judgement','risk_governance','prompt_design')),
  track_id INTEGER NOT NULL REFERENCES industry_tracks(id) ON DELETE CASCADE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

**Per-feature content tables:**
```sql
verification_tasks     (task_id PK->tasks, title, scenario, embedded_flaw,
                        expected_answer, feedback, difficulty CHECK easy|medium|hard)
judgement_tasks        (task_id PK->tasks, title, scenario, feedback)     -- no difficulty
risk_governance_tasks  (task_id PK->tasks, title, scenario, feedback)     -- no difficulty
interview_questions    (id PK, track_id->industry_tracks, question,
                        sample_answer, what_employers_test, sort_order)  -- ungraded, standalone
```
`prompt_design_tasks` + `prompt_design_criteria` are **deferred** (the anchor CHECK
already allows `prompt_design`).

**Controlled-choice options (shared by Judgement + R&G — identical shape):**
```sql
task_options (id PK, task_id->tasks, kind CHECK decision|reason, label, score 0..100, sort_order)
```

**Attempts:** make `task_attempts.answer` NULLABLE; add `rationale TEXT`,
`decision_option_id -> task_options(id)`, `reason_option_id -> task_options(id)`.

**Migration `002_restructure_tasks.sql`:**
1. Wipe `task_attempts`; reset the derived tables (`skill_scores`, `user_progress`,
   `user_achievements`) — **keep `users`**.
2. Drop/recreate `tasks` as the anchor; create the feature tables + `task_options`;
   recreate `task_attempts`.
3. Reseed per feature: Verification 6/track, Judgement 5/track, R&G 6/track,
   Interview (Legal).
4. Rewrite `db/schema.sql` + `db/seed.sql` to this shape (source of truth) and
   record `002` in `schema_migrations`.

**Feature key naming:** snake_case internally (`risk_governance`), mapped to the
display dimension (`Risk & Governance`).

**Downstream:** `getNextTask` filters by `feature` (default `verification`) and
joins the anchor to the feature table; `submitAttempt` routes scoring by
`tasks.feature` (Verification = rule/keyword + difficulty XP; Judgement/R&G =
option weights).

**Effort:** Medium–large (schema + seed + controller routing + migration).

> Supersedes the single-table approach in "Reconcile the task data model" above.

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

## P1 — Difficulty-scaled XP reward (verification scoring)

`calculateXp(score)` (`services/scoringService.js`) depends only on correctness,
so an easy task and a hard task answered equally award the same XP. Complexity
should be worth more.

**Do:**
- Pass `task.difficulty` into `calculateXp` (it is already selected in
  `submitAttempt` but currently unused) and scale the reward per tier — e.g.
  factors `{ easy: 0.7, medium: 1.0, hard: 1.4 }` on the existing curve, with
  `medium` left unchanged.
- **Keep the clamped scoring** so rewards stay bounded, but scope the clamp to
  each difficulty instead of one global 10–70 range — a hard task's floor and
  ceiling should both sit above an easy task's.
- Do **not** scale the dimension/readiness score (`skill_scores`) by difficulty;
  that is a 0–100 competency measure and stays difficulty-independent.

**Why:** the product intends "more complexity, more points"; today it is flat.

**Effort:** Small (one function signature, one call site, tests).

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
1. P0 schema restructure (per-feature tables) + reseed
2. P0 reconcile/`embedded_flaw` + scoring (now per-feature)
3. P0 content volume / run-out policy
4. P1 leaderboard
5. P1 activity / streak history
6. P2 achievements catalog
7. P2 milestones
8. P2 streak timezone

---

# Feature Build — AI Judgement, Risk & Governance & Interview Practice (next sprint)

> This section is a **build plan**, not a fix for the current state — the P0–P2
> items above address what exists today; this is net-new work. It pairs with the
> matching "Feature Build" section in `FRONTEND_TASKS.md`. Freeze the **API
> contract** below first so both teams can build in parallel. Three features:
> **AI Judgement**, **Risk & Governance** (shares the judgement engine) and
> **Interview Practice** (read-only).

## What AI Judgement is
A dedicated task mode for the **AI Judgement** dimension. Each task is a
workplace scenario with **two answered parts**: a **Decision** (one of three
fixed choices — *Use AI* / *Use AI with human review* / *Don't use AI*) and a
**Reason** (best of three task-specific reasons). Per Deliverable 3 §8.2,
Judgement is verified by "controlled-choice or predefined classification match";
per FR4, scoring is deterministic and must never be done by the AI that authored
the task. Structure follows `VerifAI_Finance_AI_Judgement_Tasks.pdf`.

## AI Judgement — decisions locked
- Interaction: scenario → Decision (3 fixed choices) + Reason (3 choices) +
  optional rationale.
- Scoring (0–100, no keyword matching): **Decision 50** correct / **25**
  neighbouring choice / **0** opposite end; **Reason 50** correct / **0** wrong.
- Rationale: optional, stored, **unscored** (future rubric/LLM pass).
- Difficulty: **not used** for AI Judgement (scenario-based only).
- Data model: **minimal extension** of the current D4 schema.
- Volume: **5 AI Judgement tasks per track** (20 total). Per-track mix: one
  clear *Use AI*, two *Use AI with human review*, two *Don't use AI*.
- The general task loop becomes **Verification-only** once this ships.

## API contract (freeze first)

**`GET /api/tasks/next?dimension=AI Judgement`** — optional param; absent = today's behaviour.
```json
{ "task": {
    "id": 2, "track_id": 1, "title": "The Month-End Agenda", "scenario": "...",
    "dimension": "AI Judgement",
    "options": [
      { "id": 11, "kind": "decision", "label": "Use AI" },
      { "id": 12, "kind": "decision", "label": "Use AI with human review" },
      { "id": 13, "kind": "decision", "label": "Don't use AI" },
      { "id": 14, "kind": "reason",   "label": "A. It is a routine, low-risk..." },
      { "id": 15, "kind": "reason",   "label": "B. ..." },
      { "id": 16, "kind": "reason",   "label": "C. ..." }
    ]
}, "request_id": "..." }
```
- `options` grouped by `kind` then `sort_order`; **`score` is never returned**.
- `task: null` when exhausted (unchanged).

**`POST /api/tasks/:id/attempt`** — extended, backward-compatible.
```json
// AI Judgement
{ "decision_option_id": 11, "reason_option_id": 14, "rationale": "optional text" }
// Verification (unchanged)
{ "answer": "free text" }
```
`result.score` = decision option's score + reason option's score (0–100). Response
shape otherwise unchanged.

## AI Judgement — work items

### AJ-B1 — Schema: options table
`task_options (id, task_id FK → tasks, kind VARCHAR CHECK (kind IN ('decision','reason')), label TEXT, score INT CHECK (score BETWEEN 0 AND 100), sort_order INT)`.
For each AI Judgement task: **3 decision rows** (scores 50 / 25 / 0) and **3
reason rows** (50 / 0 / 0). Add `task_attempts.decision_option_id`,
`task_attempts.reason_option_id` (both FK → task_options) and
`task_attempts.rationale TEXT`. Keep `tasks.correct_answer` for Verification.

### AJ-B2 — Migration
`backend/db/migrations/002_task_options.sql` (repo must stay the reproducible source of truth — see the live-drift note in P0).

### AJ-B3 — `getNextTask`: dimension filter + options
Accept optional `dimension`; when present add `AND t.dimension = $n`, **drop the
difficulty ordering** (order by `t.id`), and join/return `options` (label + id
only). Leave the default path unchanged.

### AJ-B4 — `submitAttempt`: two-part scoring path
When `decision_option_id` + `reason_option_id` are present: validate both belong
to the task with the right `kind`, set `score` = decision option's `score` +
reason option's `score`, store both ids + `rationale`, and skip `scoreAnswer`.
Otherwise keep the existing keyword path. The XP/streak/skill-score/achievement
flow is unchanged, so the `AI Judgement` dimension updates automatically.

### AJ-B5 — Content: 5 tasks per track
Author **5 AI Judgement scenarios per track** (20 total) using the exact layout
in `VerifAI_Finance_AI_Judgement_Tasks.pdf`: scenario, 3 fixed decision choices,
3 reasons (one best), and post-answer feedback. Per-track mix: one *Use AI*, two
*Use AI with human review*, two *Don't use AI*. This also relieves the P0
"run-out after 4 tasks" dead-end for the Judgement mode.

### AJ-B6 — Tests
Extend `tests/api.test.js` (dimension filter; options returned without `score`;
option submission scores correctly) and `tests/scoring.test.js` (option weight →
score).

## Risk & Governance (shares the AI Judgement engine)

Same controlled-choice engine as AI Judgement (AJ-B1–B4); only the content and
the decision option count differ. No new schema/controller work.

### Decisions locked
- Interaction: scenario → **Decision** (2 options: *Proceed* / *Don't proceed*) +
  **Reason** (best of 3) + optional rationale.
- Scoring: decision **50/0** + reason **50/0**. Right instinct + wrong reason = 50
  (the partial credit the rubric calls for).
- Difficulty: **not used** (scenario-based).
- Volume: **6 tasks per track** (reuse the existing scenarios).
- Uses the same `dimension` filter; the general loop stays Verification-only.

### API
Same as AI Judgement, only the dimension and the 2-option decision differ:
`GET /api/tasks/next?dimension=Risk & Governance`,
`POST /api/tasks/:id/attempt` → `{ decision_option_id, reason_option_id, rationale? }`.

### Work items
- **RG-B1 — Content:** convert the existing Risk & Governance scenarios per track
  (Legal task bank + Business Consulting/IT/Finance docx) into the decision+reason
  layout — scenario, 2 decisions (50/0), 3 reasons (50/0/0), feedback. 6 per track.
- **RG-B2 — Tests:** extend `api.test.js` for a 2-option decision + reason scoring.

## Interview Practice (Legal only for now)

Read-only and ungraded (FR12): a bank of interview questions with sample answers,
outside the scored loop. No scoring, no XP, no attempt endpoint.

### API
`GET /api/interview/questions` → questions for the user's track.
```json
{ "questions": [
  { "id": 1, "track_id": 2, "question": "...", "sample_answer": "...",
    "what_employers_test": "...", "sort_order": 1 }
] }
```

### Work items
- **IP-B1 — Schema:** `interview_questions (id, track_id FK, question TEXT,
  sample_answer TEXT, what_employers_test TEXT, sort_order INT)`.
- **IP-B2 — Migration:** `backend/db/migrations/003_interview_questions.sql`.
- **IP-B3 — Route:** `GET /api/interview/questions` scoped to the user's track.
- **IP-B4 — Content:** seed the Legal Interview Practice panels from the Legal
  task bank docx.
- **IP-B5 — Tests:** returns only the user's track; empty when none.

### Noted for later (do not build now)
- Adopt Deliverable 3's full `ScoringCriterion` / `VerificationResult` model with
  per-criterion configurable weights.
- Interview Practice for the other three tracks.
- Human-AI Collaboration / Human vs AI Comparison categories.
