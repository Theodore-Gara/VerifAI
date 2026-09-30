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

### POST /api/tasks/:id/attempt
Protected. Submits an answer and atomically updates attempt history, skill score, XP, level, streak and achievements.

Request:

```json
{
  "answer": "I would verify the original source before relying on the generated summary."
}
```

### GET /api/progress/me
Protected. Returns XP, level, streak, completed task count, readiness score and per-dimension scores.

### GET /api/achievements/me
Protected. Returns achievements earned by the current user.

## Scoring

Reference answers use `Keywords:` concepts. The scoring service normalizes text and checks exact token/phrase presence. The score is the percentage of required concepts matched, from 0 to 100. A score of 60+ is a pass.

XP:

- minimum: 10
- maximum: 70
- formula: `20 + round(score * 0.5)` bounded to 10–70

Level:

- level 1 starts at 0 XP
- each additional 250 XP increases the level by 1

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
