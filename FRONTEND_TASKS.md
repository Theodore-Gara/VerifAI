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

---

# Feature Build — AI Judgement (next sprint)

> This section is a **build plan**, not a fix for the current state — the numbered
> items above address what exists today; this is net-new work. It pairs with the
> matching section in `BACKEND_TASKS.md`. Build against `MockApiClient` first so
> this is not blocked on the backend endpoints.

## What we're building
A dedicated **AI Judgement** mode plus a **Tasks category hub**. The user picks a
category, then gets a scenario with a **Decision** (3 choices) and a **Reason**
(3 choices), plus an optional rationale. Structure per
`VerifAI_Finance_AI_Judgement_Tasks.pdf`.

## Decisions locked
- Tasks tab becomes a **category hub**: Verification (live), AI Judgement (new),
  Prompt Design & Risk & Governance (coming soon).
- AI Judgement interaction: scenario → Decision (3) + Reason (3) → optional
  rationale → submit.
- Scoring is backend-side and deterministic (decision 50/25/0 + reason 50/0);
  the app renders options and shows the returned score/feedback.
- The task modal + feedback screen become **category-driven** (this also fixes
  the hardcoded Verification framing).
- The general loop shows **Verification only** once this ships.

## API contract
See `BACKEND_TASKS.md` → "API contract". `GET /api/tasks/next?dimension=AI Judgement`
returns `options` (`id`, `kind`, `label`); `POST /api/tasks/:id/attempt` accepts
`{ decision_option_id, reason_option_id, rationale? }`.

## Work items

### AJ-F1 — Models
`TaskOption { id, kind, label }`; add `List<TaskOption> options` to `DailyTask`
(`shared/models/daily_task.dart`) with a `const []` default (regen freezed).
Split by `kind` in the UI (`decision` vs `reason`).

### AJ-F2 — API client
Add `getJudgementTask()` and
`submitJudgement(taskId, decisionOptionId, reasonOptionId, rationale?)` to
`ApiClient` (`core/services/api_client.dart`) and implement in **both**
`DioApiClient` and `MockApiClient` (mock fixture = one judgement task).

### AJ-F3 — Provider
`features/judgement/providers.dart` with `judgementTaskProvider`; on submit
invalidate `dashboardProvider` + `achievementsProvider`.

### AJ-F4 — Judgement screen
`features/judgement/presentation/judgement_screen.dart`, route `/judgement`
(`core/router/app_router.dart`). Scenario card → **two required sections**:
*What should you do?* (3 decision choices) and *Pick the best reason* (3 reason
choices), from `task.options` by `kind` → optional rationale field → Submit. On
success push `/feedback`. Match the layout in
`VerifAI_Finance_AI_Judgement_Tasks.pdf`.

### AJ-F5 — Tasks category hub
Turn `features/task/presentation/task_screen.dart` into a category list:
Verification (live → current task flow), AI Judgement (→ `/judgement`), and
Prompt Design / Risk & Governance as "coming soon". Keep the category list in
one place so more categories are a one-line addition.

### AJ-F6 — Category-driven task modal + feedback
Parameterise `TaskChallengeModal` and `FeedbackScreen` by category: replace the
hardcoded "VERIFICATION" badge/labels/question and "VERIFICATION PASSED" /
"You found the issue" copy with per-category values. The same change fixes the
Verification framing for AI Judgement tasks currently served in the general loop.

### AJ-F7 — Tests
Widget test: renders decision + reason options → select both → submit →
feedback. Update any existing tests that construct `DailyTask`.

### AJ-F8 — Mock-first
Ship AJ-F1–F6 against the `MockApiClient` fixture; switch to live endpoints when
`BACKEND_TASKS.md` AJ-B3/AJ-B4 land.

### Noted for later (do not build now)
- **Interview Practice** (FR12) as a hub category for the Legal track.
- Human-AI Collaboration / Human vs AI Comparison categories from the Legal task bank.
