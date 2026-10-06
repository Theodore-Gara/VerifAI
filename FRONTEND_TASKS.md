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

## Task history (linked from Progress)

Team feedback: users need to see what they completed and which they got
right/wrong. Reached from the **Progress screen** (not a top-level tab), with a
**dedicated** detail widget.

- **TH-F1 — API:** `getTaskHistory()` on `ApiClient` (both `DioApiClient` and
  `MockApiClient`), returning scored attempts with title, skill, score, passed,
  date, answers.
- **TH-F2 — Provider:** `taskHistoryProvider`.
- **TH-F3 — List:** reached from Progress — attempts (task title, skill badge,
  score, pass/fail, date), newest first, with **filters** (skill, passed/failed)
  and **pagination** ("Load more"). Loading / empty ("No attempts yet") / error
  states.
- **TH-F4 — Detail widget:** a **dedicated** `TaskHistoryDetail` widget (not the
  feedback screen) — scenario, your answer, correct answer, feedback, score, XP,
  date. Includes a **"Try again"** action.
- **TH-F5 — Practice retake:** "Try again" re-attempts for practice — **no XP, no
  tier credit, no readiness change**.
- **TH-F6 — Interview excluded:** Interview Practice does not appear in history;
  its progress shows only as "practised / completed".
- **TH-F7 — Tests:** renders attempts, filters, opens detail, practice retake.

Relates to Medium #4 (practice / review past tasks).

---

## Missing screen states (audit)

Data screens handle loading/empty/error well, but several states are missing.
The **Feedback screen** is the worst offender: it has a pass/fail branch but no
error state and a thin failure path.

### Feedback screen
- `_didPass = passed || score >= 60` drives a green "VERIFICATION PASSED" vs
  gold "REVIEW REQUIRED" badge (`feedback_screen.dart:38-42,138`).
- **Missing failure detail:** no retry (the only button is *Continue*, which
  just pops), no "correct answer / what you missed" reveal, no per-dimension
  copy — and the copy is hardcoded to Verification.
- **Missing error state:** dimensions silently fall back to `const {}` (`:49`);
  opening `/feedback` without `extra` renders a degenerate 0-score/empty-feedback
  failure (`app_router.dart:146-148`).
- **Missing submit-failure state:** a failed attempt only shows a SnackBar in the
  modal (`task_challenge_modal.dart:90`).

**Do:** add distinct incorrect + error states, de-Verification the copy, offer
retry, and reveal the correct answer / missed concepts.

### State matrix

| Screen | Loading | Empty | Error | Gap |
|---|---|---|---|---|
| Splash | ✓ | – | ✗ | auth error silently redirects to /login (`splash_screen.dart:57`) |
| Login / Register | ✓ | – | ✓ | – |
| Industry Select | ✓ | ✗ | ✓ | empty tracks → blank grid; submit has no try/catch → spinner can hang (`industry_select_screen.dart:83-92`) |
| Dashboard | ✓ | ✓ | ✓ | – |
| Tasks | ✓ | ✓ | ✓ | – |
| Task modal | ✓ | – | ~ | submit error = SnackBar only |
| Feedback | – | ✗ | ✗ | see above |
| Progress | ✓ | ✓ | ✓ | – |
| Profile | ✗ | – | ✗ | silent `valueOrNull` → XP 0 / all badges locked while loading; failures invisible (`profile_screen.dart:17-24`) |
| Scoreboard | ✗ | ✗ | ✗ | hardcoded fake data |
| Track Roadmap | ✗ | ✗ | ✗ | hardcoded |

### Cross-cutting
- **401 / token expiry — everywhere.** No `statusCode` handling in `mobile/lib`;
  a mid-session 401 shows a generic error and the user is stuck (auth state never
  flips, so no redirect).
- **Offline — everywhere.** `NoConnectionState` (`empty_state.dart:103`) is
  defined but never used; no connectivity check (NFR3 / D3 offline design).
- **Timeout / slow network.** All failures collapse into one generic `ErrorState`.
- **Silent fallbacks.** `.valueOrNull` hides loading and errors on Splash,
  Profile, Track, Scoreboard, Feedback, Dashboard(user).

## Suggested sequencing
1. (1) Label fake screens + (3) 401 interceptor — do now.
2. Feedback incorrect/error states + Profile loading/error + Industry Select
   empty/submit error — high value, do early.
3. (2) Wire task options + flaw when the backend P0 lands.
4. (4)–(7) as endpoints and time allow.
5. Offline (`NoConnectionState`) + timeout states.
6. (8)–(9) polish.

---

# Feature Build — AI Judgement, Risk & Governance & Interview Practice (next sprint)

> This section is a **build plan**, not a fix for the current state — the numbered
> items above address what exists today; this is net-new work. It pairs with the
> matching section in `BACKEND_TASKS.md`. Build against `MockApiClient` first so
> this is not blocked on the backend endpoints. Three features: **AI Judgement**,
> **Risk & Governance** (reuses the judgement screen) and **Interview Practice**
> (read-only).

## What we're building
A dedicated **AI Judgement** mode plus a **Tasks category hub**. The user picks a
category, then gets a scenario with a **Decision** (3 choices) and a **Reason**
(3 choices), plus an optional rationale. Structure per
`VerifAI_Finance_AI_Judgement_Tasks.pdf`.

## Decisions locked
- Tasks tab becomes a **category hub**: Verification (live), AI Judgement (new),
  Risk & Governance (new), Interview Practice (new, Legal), Prompt Design
  (coming soon).
- AI Judgement interaction: scenario → Decision (3) + Reason (3) → optional
  rationale → submit.
- Scoring is backend-side and deterministic (decision 50/25/0 + reason 50/0);
  the app renders options and shows the returned score/feedback.
- The task modal + feedback screen become **category-driven** (this also fixes
  the hardcoded Verification framing).
- The general loop shows **Verification only** once this ships.
- User-facing wording uses **skill** ("Verification skill", "AI Judgement skill",
  "Risk & Governance skill", …) rather than "dimension"; the backend keeps its
  `dimension` / `skill_scores` naming.

## API contract
See `BACKEND_TASKS.md` → "API contract". `GET /api/tasks/next?dimension=AI Judgement`
returns `options` (`id`, `kind`, `label`); `POST /api/tasks/:id/attempt` accepts
`{ decision_option_id, reason_option_id, rationale? }`.

## AI Judgement — work items

### AJ-F1 — Models
`TaskOption { id, kind, label }`; add `List<TaskOption> options` to `DailyTask`
(`shared/models/daily_task.dart`) with a `const []` default (regen freezed).
Split by `kind` in the UI (`decision` vs `reason`). `DailyTask` also gains
`feature` (`verification` / `judgement` / `risk_governance`) — the backend is
being restructured into per-feature tables, so `feature` replaces reliance on
`dimension`.

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
Verification (live → current task flow), AI Judgement (→ `/judgement`),
Risk & Governance (→ reused judgement screen), Interview Practice (Legal only),
and Prompt Design as "coming soon". Keep the category list in one place so more
categories are a one-line addition.

### AJ-F6 — Category-driven task modal + feedback
Parameterise `TaskChallengeModal` and `FeedbackScreen` by category: replace the
hardcoded "VERIFICATION" badge/labels/question and "VERIFICATION PASSED" /
"You found the issue" copy with per-category values. The same change fixes the
Verification framing for AI Judgement tasks currently served in the general loop.
After an attempt, the feedback reveals the **correct option** (from the backend's
`correct_option_id`).

### AJ-F7 — Tests
Widget test: renders decision + reason options → select both → submit →
feedback. Update any existing tests that construct `DailyTask`.

### AJ-F8 — Mock-first
Ship AJ-F1–F6 against the `MockApiClient` fixture; switch to live endpoints when
`BACKEND_TASKS.md` AJ-B3/AJ-B4 land.

## Risk & Governance (reuses the judgement screen)

- **RG-F1 — Hub entry + screen reuse:** add Risk & Governance to the Tasks hub;
  reuse `JudgementScreen` (decision section has 2 options, reason section 3).
  Parameterise by category — no new screen.
- **RG-F2 — Feedback copy:** add the Risk & Governance variant to the
  category-driven feedback screen.
- **RG-F3 — Tests:** reuse the judgement widget test with a 2-option decision.

## Interview Practice (Legal only for now)

- **IP-F1 — Models:** `InterviewQuestion { id, question, sampleAnswer,
  whatEmployersTest, trackId, sortOrder, practiced }`.
- **IP-F2 — API client:** `getInterviewQuestions()` + `markInterviewPracticed(id)`
  on `ApiClient`; implement in `DioApiClient` + `MockApiClient`.
- **IP-F3 — Provider:** `interviewQuestionsProvider`.
- **IP-F4 — Screen:** `features/interview/presentation/interview_practice_screen.dart`
  — list of questions, tap to reveal the sample answer + "what employers are
  testing". **Revealing marks the question practised** (calls the practice route)
  and shows a covered count (e.g. "3 / 12 practised"). Route `/interview`. No
  scoring/XP, but it feeds readiness via coverage.
- **IP-F5 — Hub entry:** add Interview Practice to the Tasks category hub, shown
  **only for Legal-track users** (hidden for the other three tracks).
- **IP-F6 — Tests:** renders questions, expands to show the answer, records
  practice, updates the covered count.

### Noted for later (do not build now)
- Interview Practice for the other three tracks.
- Human-AI Collaboration / Human vs AI Comparison categories.

---

# Feature Build — Promotion & status (readiness tiers)

- **PS-F1 — Tier display:** show the user's tier (Novice → Developing →
  Proficient → Advanced) and progress within it (`passed / required × 100`) on the
  Dashboard / Progress screens.
- **PS-F2 — Sticky readiness:** display the sticky readiness score; it never shows
  a fall.
- **PS-F3 — XP curve:** the level/XP bar reflects the +60-per-level curve
  (L1→L2 250, L2→L3 310, L3→L4 370, …).
- **PS-F4 — Passport unlock:** show a locked/unlocked passport state — unlocked
  when the user is at **Proficient** tier or higher **and** readiness ≥ 60.
