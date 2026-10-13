# VerifAI Backend API

Base URL locally: `http://localhost:3000`

## Authentication

Protected endpoints require:

```text
Authorization: Bearer <Firebase ID token>
```

## Endpoints

### GET /api/health
Public database/application health check.

### GET /api/tracks
Public list of industry tracks.

### POST /api/auth/sync
Protected. Creates or updates the authenticated user from Firebase claims.

### GET /api/users/me
Protected. Returns the current user's profile and selected industry track.

### PUT /api/users/profile
Protected. Updates `display_name` and/or `industry_track_id`.

### GET /api/tasks/next
Protected. Returns the next task for the authenticated user's selected industry track. The reference answer is never returned.

Query parameters:

- `feature` — restrict to a feature: `verification`, `judgement`, `risk_governance`, `prompt_design`. Default `verification`.
- `dimension` — display-name alias, e.g. `Verification`, `AI Judgement`, `Risk & Governance`, `Prompt Design`. Must agree with `feature` when both are given; otherwise `400`.

Every task payload carries `feature` and `dimension` (e.g. `"feature": "judgement", "dimension": "AI Judgement"`).

### POST /api/tasks/:id/attempt
Protected. Submits an answer and atomically updates attempt history, skill score, XP, level, streak, readiness and achievements.

The request body depends on the task feature:

```json
{
  "decision_option_id": 11,
  "reason_option_id": 14,
  "rationale": "optional free-text rationale"
}
```

- Verification `choice` tasks: `{ "answer_option_id": 31, "rationale": "..." }`.
- Verification `line_text` tasks (legacy): `{ "answer": "...", "reason": "...", "selected_lines": [8, 9] }`.
- To record a practice run (no XP, does not affect skill score): `{ ..., "practice": true }`.

The response includes the score, whether it passed, XP earned, the correct option ids, and the updated `skill_score`, `progress` and `newly_earned_achievements`, plus `request_id`.

### GET /api/tasks/history
Protected. The authenticated user's scored attempts, newest first (practice attempts are excluded).

Query parameters:

- `?limit=<1..50>` — page size (default 20); `?offset=<n>` — pagination offset (default 0).
- `?feature=<key>` — restrict to one feature (`verification`, `judgement`, `risk_governance`, `prompt_design`); `400` if unknown.
- `?passed=true|false` — restrict to passed or failed attempts; `400` if malformed.

Response: `{ attempts: [{ id, task_id, feature, title, score, passed, xp_earned, submitted_at, feedback, answer, rationale, selected_lines }], total, limit, offset }`.

### GET /api/interview/questions
Protected. Returns the interview question bank for the authenticated user's selected track, each with a boolean `practiced` flag.

### POST /api/interview/questions/:id/practice
Protected. Marks a question as practised. Idempotent: practising the same question again returns 200 with the same count. Recomputes the readiness score. Returns the question's `practised_count` and `total`.

### GET /api/progress/me
Protected. Returns XP, level, streak, completed task count, readiness score and per-dimension scores.

### GET /api/progress/me/activity
Protected. Daily activity history plus current streak info. Optional `?days=<1..90>` (default 30) window; values outside the range are clamped.

Response: `{ days, streak: { current, last_activity_date }, activity: [{ activity_date, attempts, xp_earned, passed }] }`. One row per day with at least one attempt, ordered oldest first (practice attempts included but earn no XP).

### GET /api/leaderboard
Protected. Deterministic top-N board ordered by XP (ties broken by readiness score, then user id).

Query parameters:
- `?track=<industry_track_id>` — limit the board to one industry track (default: global)
- `?limit=<1..50>` — board size (default 20)

Response: `{ track_id, leaderboard: [{ rank, user_id, display_name, level, xp, streak, readiness_score, tier }], me: { ...same fields, rank } }`. `me` is always included, with the requesting user's computed rank even when they sit outside the top N.

### GET /api/achievements/me
Protected. Returns achievements earned by the current user.

### GET /api/achievements
Protected. Full achievements catalog — every achievement with an `earned` flag and, when earned, its `earned_at` timestamp, so locked and unlocked states render from one call.

### GET /api/achievements/milestones
Protected. Code-defined track milestones with live progress. Optional `?track=<id>` overrides the user's selected track (400 if neither is set).

Response: `{ track_id, milestones: [{ code, name, description, target, current, achieved }] }`. Milestones cover task completion (first task, all tasks in the track), XP (250, 1000), streak (7 days) and level (5). `achieved` flips as soon as `current >= target`.

### POST /api/assistant/chat
Protected. Sends up to eight conversation messages to the AI assistant. `task_id` is **optional**: with it the assistant is scoped to a task belonging to the authenticated user's selected track; without it this is a general, track-aware assistant. Requests are limited to 8 per user per minute; each message is limited to 1,200 characters.

Request:

```json
{
  "task_id": 123,
  "messages": [{ "role": "user", "content": "Can you give me a hint?" }]
}
```

Pass `?stream=1` (or `"stream": true`) to receive a Server-Sent Events stream: each `data:` frame is `{"delta":"..."}`, terminated by `data: [DONE]`, or `{"error":"..."}` on failure.

Requires `NVIDIA_API_KEY` in the backend environment. Model routing is per use case: `NVIDIA_MODEL_CHAT` (default `nvidia/nemotron-3.5-lightning-30b-a3b`) for the assistant, coach and general surfaces, with a retryable failure falling back to `NVIDIA_MODEL_FALLBACK`.

### POST /api/verification/analyze
Protected. Assesses a `document`, `claim`, `ai_response` or `source` and returns a structured report. **The submitted content is never stored** — only metadata and the report are persisted, so confidential material does not persist.

Request: `{ "kind": "document", "content": "...", "document_name": "q3.pdf" }` (`content` ≤ 60,000 characters).

Response: `{ "analysis": { id, kind, document_name, overall_status, items_requiring_review, sources_confirmed, summary, report, created_at } }`, where `overall_status` is one of `appears_sound`, `human_review_required`, `insufficient_evidence`. Uses the analysis model (`NVIDIA_MODEL_ANALYSIS`, default `nvidia/nemotron-3-super-120b-a12b`) with reasoning enabled, and is rate-limited.

### GET /api/verification/analyses
Protected. The user's recent analyses (metadata + report), newest first. Optional `?limit=<1..50>` (default 20).

### GET /api/lab/lessons
Protected. The AI Lab lesson catalog available to the user's track (plus global lessons), each with section/activity/question counts and the user's progress.

### GET /api/lab/lessons/:code
Protected. One lesson with its textbook `sections`, graded recall `activities` (each with `type`, `prompt`, `payload`, `xp_reward` and whether the user has `passed`) and assessment `questions`, plus the user's progress. Opening a lesson records recency (not completion). The response also includes `sources`, `attributions` (ready-made credit lines) and a `share_alike` flag. **Answer keys are withheld** — activities never return `correct`, and questions never return `correct_index`/`explanation`.

### GET /api/lab/lessons/next
Protected. Content rotation. Prefers a lesson the learner has not opened yet; when none remain and `include_seen` is true (the default), it serves the lesson gone longest without a revisit, so seen content is never locked away. Optional `?include_seen=true|false` (default true). Response: `{ lesson, revisited }`; `lesson` is `null` when all content is seen and `include_seen=false`.

### GET /api/lab/sources
Protected. The content-source catalogue ("where our material comes from"): title, author, publisher, edition, URL, licence, licence URL, industry, the date the licence was checked, and notes.

### GET /api/lab/sources/:id
Protected. One source plus the lessons that draw on it (`use_type` and `changes_made` per link). `400` for a malformed id, `404` if unknown.

### GET /api/lab/library
Protected. The catalogue grouped by industry: `{ groups: [{ industry, sources: [...] }] }`.

### POST /api/lab/lessons/:code/progress
Protected. Body `{ "sections_completed": 3, "activities_completed": 1 }`. Counts are monotonic (never decrease) and completion is recomputed.

### POST /api/lab/lessons/:code/assessment
Protected. Body `{ "answers": [1, 0, 2] }` (one index per question). Graded **server-side** against the stored answer key. Returns `{ result: { score, passed, correct_count, total }, questions: [{ question_id, answered, correct, correct_index, explanation }] }`. Passing threshold is 60.

### POST /api/lab/activities/:id/attempt
Protected. Body `{ "response": <answer>, "practice": false }`. Grades a recall activity **server-side** and returns `{ result: { correct, passed, xp_earned, practice }, explanation, answer }`. A **first non-practice pass** awards the activity's XP (default 10); repeat attempts are practice and earn nothing. The `response` shape depends on `type`:

- `multiple_choice` — the option index (`0`-based).
- `true_false` — a boolean.
- `fill_blank` — a string (matched case-insensitively against accepted answers).
- `matching` — an object `{ "<left>": "<right>", ... }`.
- `ordering` — an array of the items in the chosen order.

### GET /api/lab/assessments
Protected. Capstone assessments (module-level, scenario-based) available to the user's track plus cross-industry ones. Each carries `total_marks`, `time_limit_seconds` (default 40 min), `pass_score` (60), `max_attempts` (3), `question_count`, `attempts_used`, `attempts_remaining`, `best_score`, `passed` and `view_only`.

### GET /api/lab/assessments/:code
Protected. The full paper read-only (scenario, instructions, questions with `marks`/`marking` and answers withheld). `view_only` is true once the attempts are exhausted, at which point the learner can still revisit the paper but cannot start again.

### POST /api/lab/assessments/:code/start
Protected. Opens a timed attempt. Questions (and multiple-choice / multi-select options) are **shuffled**; answer keys and rubrics are withheld. Returns `{ attempt_id, started_at, expires_at, time_limit_seconds, pass_score, total_marks, scenario, instructions, attempts_remaining, questions }`. `404` if not available, `409` when no attempts remain, `400` if it has no questions.

### POST /api/lab/assessments/:code/submit
Protected. Body `{ attempt_id, answers: { "<question_id>": <response> } }`. Grades the **auto-marked** questions server-side (remapping shuffled options). If the paper contains a **rubric** question (e.g. an extended response), the attempt is held and returns `202` with `{ result: { pending_marking: true, score, auto_marks, total_marks, ... }, results }`. Otherwise it finalises immediately: `{ result: { pending_marking: false, score, passed, timed_out, marks_awarded, total_marks, attempts_remaining }, results, xp_earned, tokens_earned, achievement }`. A **first pass** — even on the third attempt after two failures — awards XP + tokens + a badge and feeds the readiness score. Answers submitted more than 30 s past `expires_at` are marked `timed_out` and fail. Response shapes by type: `multiple_choice` index, `true_false` boolean, `fill_blank` string, `matching` `{left:right}` map, `ordering` array, `numeric` a number (or array for multi-part), `multi_select` an array of selected indices, `extended_response` free text.

### POST /api/lab/assessments/:code/attempts/:id/mark
Reviewer/AI-marker endpoint. Body `{ marks: { "<question_id>": <total> | [<per-criterion>] }, marked_by }`. Finalises a `pending_marking` attempt: rubric marks are capped at the question marks, added to the auto marks, and the score, pass, rewards and readiness are applied (a human should spot-check any AI marking). `409` if the attempt is not awaiting marking.

### POST /api/lab/assessments/:code/attempts/:id/ai-mark
Protected. AI-assisted marking. Vera's marker model scores each rubric question against the rubric and stores a **suggestion** (`ai_suggestion`, plus `suggested_marks` and a `projected_score`) without finalising — the attempt stays `pending_marking` until a human confirms via the mark endpoint. `409` if not awaiting marking, `400` if there are no rubric questions.

### POST /api/lab/coach
Protected. Body `{ "lesson_code": "ai-ethics-and-bias", "messages": [...] }` → a Socratic tutor reply. `?stream=1` streams SSE as above. Rate-limited.

### GET /api/workshop/posts
Protected. Track-scoped community threads, newest first. Optional `?lesson=<code>`, `?limit=<1..50>`, `?offset=<n>`. Each post carries `author_name`, `reply_count`, `reaction_count`, `reacted` and `is_mine`.

### GET /api/workshop/posts/:id/replies
Protected. Replies to a thread, oldest first.

### POST /api/workshop/posts
Protected. Body `{ "body": "...", "lesson_code": "optional", "parent_id": "optional reply target" }`. `body` ≤ 2,000 characters. The post is scoped to the user's industry track.

### POST /api/workshop/posts/:id/react
Protected. Toggles the caller's upvote; returns `{ reacted, reaction_count }`.

### POST /api/workshop/posts/:id/report
Protected. Body `{ "reason": "spam" | "abuse" | "off_topic" | "other" }`. Idempotent per user. A post is auto-hidden once 3 distinct users report it. You cannot report your own post.

### DELETE /api/workshop/posts/:id
Protected. Deletes the caller's own post (and its replies). `403` for another user's post.

### GET /api/rewards
Protected. The active rewards catalog, each with `can_afford`, plus the wallet `{ xp, level, tokens, next_level_xp }`.

### GET /api/rewards/tokens
Protected. Ledger of token grants and spends, newest first. Optional `?limit=<1..100>` (default 20). Also returns the wallet.

### POST /api/rewards/:code/redeem
Protected. Redeems a reward by spending **tokens** (XP and level are never touched). `409` with `{ tokens, cost_tokens }` when the balance is short; `404` for an unknown reward. The balance row is locked so concurrent redemptions cannot both pass.

### POST /api/users/avatar
Protected. Body `{ "image_base64": "...", "mime": "image/png" }` (`image/png`, `image/jpeg` or `image/webp`; ≤ 2 MB). A `data:` URI prefix is tolerated. Stored inline as `bytea`.

### GET /api/users/avatar
Protected. Returns the caller's avatar image, or `404` when none is set.


## Vera — AI assistant with memory

Vera is the app-wide, friendly professional assistant. She keeps track of the learner's progress (skill scores, task outcomes, lab and capstone results), remembers durable observations, and personalises coaching. Sessions and messages are stored per user.

### POST /api/vera/chat
Protected. Body `{ session_id?, messages, context? }` where `messages` is the running history (1–20 messages, each ≤ 2,000 chars, last from the user) and `context` is one of `assistant`, `coach`, `lab`, `verification`, `general`. Creates a session when `session_id` is omitted. Vera's system prompt is built from the learner profile, stored memories, **app-wide knowledge** (task types, lessons, capstones and the rewards catalogue with the learner's token balance) and the learner's own recent attempts **including the correct answers**, so she can recommend what to do or which reward to save for, and is **not gated** — she will state the correct answer to a task or assessment the learner attempted if asked. The turn is stored and durable memories are extracted from the exchange. Returns `{ session_id, reply }`. `?stream=1` streams SSE. Rate-limited (8/min).

### GET /api/vera/sessions
Protected. The user's recent chat sessions.

### GET /api/vera/sessions/:id
Protected. One session with its messages.

### GET /api/vera/memory
Protected. The learner's stored memories (kind + content).

### POST /api/vera/memory
Protected. Body `{ kind, content }`, `kind` ∈ `preference|struggle|strength|goal|fact`, `content` ≤ 300 chars. Idempotent per (user, kind, content).

### DELETE /api/vera/memory/:id
Protected. Removes one of the user's memories.

### GET /api/vera/tips
Protected. Deterministic, cost-free coaching tips derived from the learner profile (weak areas, recent misses, strengths, unfinished lessons, capstones awaiting marking), plus a `summary` of the profile.

## Industry Practice

Informational real-world case studies (scenario → cause → solution), like Interview Practice. Cases are sourced from real reporting.

### GET /api/industry-practice/cases
Protected. Cases for the user's track plus cross-industry ones, each with a `read` flag.

### GET /api/industry-practice/cases/:id
Protected. The full case (`scenario`, `cause`, `solution`, `source_title`, `source_url`). Reading it marks it as read. `404` if not available for the track.

### POST /api/industry-practice/cases/:id/read
Protected. Marks a case as read (idempotent).

## Scoring

Scores are always 0–100 and stored per dimension; the highest of any dimension named `best_dimension` drives the `dimension-80` achievement.

- **AI Judgement** and **Risk & Governance**: the decision option and reason option each carry a weight (decision 50 + reason 50). The selected decision scores its full weight when best, half when the neighbouring option, zero otherwise; the reason scores its full weight when correct, zero otherwise.
- **Verification (choice)**: select the single correct answer — 100 or 0.
- **Verification (line_text, legacy)**: reference answers use `Keywords:` concepts. The scoring service normalizes text and checks exact token/phrase presence. The score is the percentage of required concepts matched; flaw-line matches and reasoning keywords add points.

XP:

- practice runs earn 0 XP
- otherwise scaled by score and difficulty: `round(score/100 * difficulty_max)`, with difficulty maxima easy 50 / medium 70 / hard 100
- a pass is `score >= 50` for judgement and risk & governance, `>= 60` for verification
- AI Lab practice activities award their `xp_reward` (default 10) on the **first non-practice pass**; repeat attempts earn none, and a pass still advances the level/token economy

Level:

- level 1 starts at 0 XP
- cumulative XP to reach a level: `250·k + 30·k·(k−1)` where `k = level − 1` (250, 560, 930, …)

Reward tokens:

- XP is a permanent progression metric and is **never spent**. Reward tokens are a separate, spendable currency earned from milestones.
- Each level gained grants `TOKENS_PER_LEVEL` tokens (default 10); each achievement earned grants `TOKENS_PER_ACHIEVEMENT` tokens (default 5).
- A first capstone pass may also grant a token bonus (ledger reason `capstone`).
- Grants are recorded in an append-only ledger (`reward_token_events`) whose `UNIQUE(user_id, reason, ref)` constraint makes them idempotent, so a retried submission cannot double-credit.
- Redemptions (`POST /api/rewards/:code/redeem`) deduct tokens only; XP, level and readiness are untouched.

Readiness:

- weighted mean of the dimension skill scores plus interview coverage (each question practised counts `100 / total`) and lab capstone results (a `Learning` component, the average of the learner's best passed capstone scores); weights are renormalised over whichever components have data and stored monotonically via `GREATEST` so readiness never drops

Streak:

- first activity day starts at 1
- another submission on the same calendar day does not increase the streak
- activity on the next calendar day increments the streak
- a gap of two or more days resets it to 1

## Error format

Errors use:

```json
{
  "error": "Human-readable message",
  "request_id": "correlation-id"
}
```

## Database setup

For a new database run:

1. `npm run db:setup` — applies `db/schema.sql`, then `db/seed.sql` and every `db/seed/*.sql` content file (AI Lab lessons, rewards catalog), then baselines migrations.

For an existing database:

- `npm run db:migrate` — applies any pending `db/migrations/NNN_*.sql` (e.g. `007_product_hub.sql`).
- `npm run db:seed` — re-applies seed data only.

For the original prototype database, back it up and review `db/migrations/001_prototype_to_d4.sql` before running it once.

See `USER_MANUAL.md` for beginner setup and GitHub/Railway instructions.
