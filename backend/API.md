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

### GET /api/interview/questions
Protected. Returns the interview question bank for the authenticated user's selected track, each with a boolean `practiced` flag.

### POST /api/interview/questions/:id/practice
Protected. Marks a question as practised. Idempotent: practising the same question again returns 200 with the same count. Recomputes the readiness score. Returns the question's `practised_count` and `total`.

### GET /api/progress/me
Protected. Returns XP, level, streak, completed task count, readiness score and per-dimension scores.

### GET /api/leaderboard
Protected. Deterministic top-N board ordered by XP (ties broken by readiness score, then user id).

Query parameters:
- `?track=<industry_track_id>` — limit the board to one industry track (default: global)
- `?limit=<1..50>` — board size (default 20)

Response: `{ track_id, leaderboard: [{ rank, user_id, display_name, level, xp, streak, readiness_score, tier }], me: { ...same fields, rank } }`. `me` is always included, with the requesting user's computed rank even when they sit outside the top N.

### GET /api/achievements/me
Protected. Returns achievements earned by the current user.

### POST /api/assistant/chat
Protected. Sends up to eight conversation messages to the NVIDIA-hosted Learning Assistant, scoped to a task belonging to the authenticated user's selected track. The assistant receives task title/scenario only, not the answer key. Requests are limited to 8 per user per minute; each message is limited to 1,200 characters.

Request:

```json
{
  "task_id": 123,
  "messages": [{ "role": "user", "content": "Can you give me a hint?" }]
}
```

Requires `NVIDIA_API_KEY` in the backend environment. `NVIDIA_MODEL` optionally overrides the default model.

## Scoring

Scores are always 0–100 and stored per dimension; the highest of any dimension named `best_dimension` drives the `dimension-80` achievement.

- **AI Judgement** and **Risk & Governance**: the decision option and reason option each carry a weight (decision 50 + reason 50). The selected decision scores its full weight when best, half when the neighbouring option, zero otherwise; the reason scores its full weight when correct, zero otherwise.
- **Verification (choice)**: select the single correct answer — 100 or 0.
- **Verification (line_text, legacy)**: reference answers use `Keywords:` concepts. The scoring service normalizes text and checks exact token/phrase presence. The score is the percentage of required concepts matched; flaw-line matches and reasoning keywords add points.

XP:

- practice runs earn 0 XP
- otherwise scaled by score and difficulty: `round(score/100 * difficulty_max)`, with difficulty maxima easy 50 / medium 70 / hard 100
- a pass is `score >= 50` for judgement and risk & governance, `>= 60` for verification

Level:

- level 1 starts at 0 XP
- each 250 XP increases the level by 1

Readiness:

- weighted mean of the dimension skill scores plus interview coverage (each question practised counts `100 / total`); stored monotonically via `GREATEST` so readiness never drops

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

1. `db/schema.sql`
2. `db/seed.sql`

For the original prototype database, back it up and review `db/migrate_d4.sql` before running it once.

See `USER_MANUAL.md` for beginner setup and GitHub/Railway instructions.
