# VerifAI Deliverable 4 Backend Handoff

## Purpose

This document explains the completed backend scope, what was inherited from the existing team backend, what was added for Deliverable 4, and what still requires the team's real environment.

## Existing teammate/backend foundation

The original backend already provided:
- Express server setup
- PostgreSQL pool
- Firebase Admin authentication
- authentication middleware
- health endpoint
- Firebase user synchronization
- current-user endpoint
- profile update functionality
- industry-track endpoint
- environment examples and basic deployment structure

## Deliverable 4 additions

The completed backend adds:
- `GET /api/tasks/next`
- `POST /api/tasks/:id/attempt`
- deterministic rule-based scoring
- skill score aggregation
- XP calculation
- level calculation
- daily streak handling
- achievement awarding
- `GET /api/progress/me`
- `GET /api/achievements/me`
- API tests
- scoring tests
- validation middleware
- consistent request IDs and errors
- production security middleware
- OpenAPI documentation
- Railway deployment documentation

## Database

The Deliverable 4 model uses:
- `users`
- `industry_tracks`
- `tasks`
- `task_attempts`
- `skill_scores`
- `user_progress`
- `achievements`
- `user_achievements`

The repository also includes a migration for the original prototype's `scores` and `task_submissions` tables.

## Scoring

Scoring is deterministic and does not call an external AI service. Reference answers contain required concepts/keywords. The submitted answer is normalized and checked for those concepts. Score is the percentage of required concepts matched, bounded to 0–100. A score of 60 or more passes.

XP is bounded from 10 to 70 per completed attempt and increases with score. Levels increase every 250 cumulative XP.

Streaks count consecutive calendar days with at least one submission. Multiple submissions on the same day do not increase the streak more than once.

## Security

The backend uses:
- Firebase token verification
- parameterized PostgreSQL queries
- Helmet
- CORS allow-list configuration
- request-size limits
- API rate limiting
- production-safe error messages
- request IDs

## Testing status

The repository contains Jest/Supertest tests and scoring unit tests.

Because this package was prepared without access to the team's Firebase credentials or live PostgreSQL/Railway environment, production authentication, live database integration and Railway deployment cannot be honestly marked as verified here.

Run locally:

```bash
npm install
npm run check
npm test
```

## Railway status

Deployment is prepared but not performed by this package. The team must configure the real Railway project and secrets.

## GitHub status

This package is intended to be added to the existing group repository on:

```text
feature/backend-d4-completion
```

It must be reviewed before merging to `main`.
