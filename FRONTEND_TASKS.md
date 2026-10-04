# VerifAI — Frontend Tasks

Work items for the frontend team. Priority key: **High**, **Medium**,
**Low / polish**.

> The app is wired to the backend for auth, onboarding, dashboard, tasks,
> progress, profile and achievements. Several screens still render **hardcoded
> placeholder data**; those are called out first.

---

## High value

### 1. Stop shipping fake data on real-looking screens
`ScoreboardScreen` (fake leaderboard), `TrackRoadmapScreen` (fake milestones)
and the Progress weekly chart are hardcoded.

**Do:** until their endpoints exist, label them "Preview / Coming soon" or gate
them, so no one demos fake data as if it were real.

### 2. Task UI must consume the backend options (and the flaw)
The task modal's four options are hardcoded placeholders, and the task content
shown does not include the deliberate flaw.

**Do (once the backend P0 restructure lands):**
- Render options from `GET /api/tasks/next` and send `option_id` on submit.
- Display `embedded_flaw` — currently there is nothing for the user to "find".

### 3. 401 / token-expiry handling
`DioApiClient` fetches a fresh Firebase ID token per request (good), but there is
no retry/redirect on a `401` mid-session.

**Do:** add an interceptor that refreshes the token once and, if still `401`,
routes back to login.

---

## Medium value

### 4. Task-exhaustion UX
The app already shows "All caught up" when the backend returns no unseen task.
Once the backend policy exists, add a "practice / review past tasks" affordance.

### 5. Test coverage
Only 5 widget tests exist. Add coverage for:
- task submit → feedback (score, passed, matched/missed concepts, new badge),
- achievements rendering (locked vs unlocked, count).

So CI catches regressions.

### 6. Keep the web build deployed
The Firebase Hosting build is the current iOS-testing path. Re-run
`flutter build web --release` and `firebase deploy --only hosting` after notable
changes so testers stay current.

### 7. Git hygiene
`.flutter-plugins-dependencies` is tracked (shows as deleted after
`flutter clean`) and the macOS/Windows generated plugin registrants churn on
every dependency change.

**Do:** add them to `.gitignore` and `git rm --cached` them.

---

## Low / polish

### 8. Accessibility pass
Verify contrast, semantics and tap targets. Brand colours are mostly compliant
but worth a deliberate check.

### 9. Rank placeholder
Profile/Dashboard show `Rank: —`. Wire it once the leaderboard endpoint exists.

---

## Suggested sequencing
1. (1) Label fake screens + (3) 401 interceptor — do now.
2. (2) Wire task options + flaw when the backend P0 lands.
3. (4)–(7) as endpoints and time allow.
4. (8)–(9) polish.
