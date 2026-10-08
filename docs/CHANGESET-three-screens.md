# Change Set: Task, Feedback & Progress Screens

**Branch:** `vusani-changes` (carried from `feature/task-feedback-progress-screens`)
**Scope:** Three new screens wired into the VerifAI mobile app, plus integration changes connecting them to the existing flow.
**Verification:** `flutter analyze` on the whole `lib/` passes with zero issues (verified Oct 1).

---

## New screens (three files, all under `mobile/lib/features/`)

### 1. `task/presentation/task_screen.dart` — "Tasks" mission list
- Shows all available challenge missions as cards, with an "N ACTIVE" counter pill in the AppBar.
- Each mission opens the existing `TaskChallengeModal` (from the dashboard feature) for the spot-the-flaw challenge flow.
- Shows an `EmptyState` fallback ("All caught up!") when no missions exist.
- Currently renders 3 inline mock `DailyTask` objects (ids 101–103, spanning Finance / Business Consulting / IT-Software tracks).

### 2. `feedback/presentation/feedback_screen.dart` — post-attempt results
- Constructor params: `score`, `feedback`, `xpEarned`, optional `dimensionScores` map.
- Layout: pass/fail pill ("PASSED" if score ≥ 60, else "ALMOST THERE"), `ScoreRing` (132px, shared widget), a humanized headline ("Nice catch — that's exactly the instinct employers look for." on pass / "Close one. Here's where it slipped, and how to nail it next time." on fail), the API feedback text, an XP reward chip, and a "Dimension Breakdown" section using the shared `DimensionBar` widget.
- A green `VerifAIButton` ("Continue") in the bottom bar pops back.
- Also contains the small value class **`FeedbackResult`** (score, feedback, xpEarned) used as the go_router `extra` payload, and a `FeedbackEmptyScreen` variant for standalone viewing.

### 3. `progress/presentation/progress_screen.dart` — long-term progress
- Level/XP card (uses shared `XPBar`).
- Duo-metric row: `StreakBadge` for days-streak + a completed-tasks counter.
- "Weekly XP Activity" bar chart built from plain Containers (7 bars, XP-labeled).
- "Readiness Dimensions" section using `DimensionBar`.
- All data is inline mock constants for now (streak 7 days, level 3, 340/500 XP, 23 tasks).

---

## Integration changes

### `core/router/app_router.dart`
- Registered three new routes: `/tasks` → `TaskScreen`, `/progress` → `ProgressScreen`, `/feedback` → `FeedbackScreen`.
- The feedback route reads a `FeedbackResult` from `state.extra` (with a safe zero-default fallback) and passes `context.pop()` as its Continue handler.
- All three are protected by the existing auth redirect like other post-login routes.
- They are push destinations, NOT bottom tabs — `MainNavShell` and its 4 tabs (HQ, Track, Scores, Profile) are untouched.

### `dashboard/presentation/task_challenge_modal.dart`
- The submit handler no longer shows the old hardcoded "QUEST COMPLETE!" celebration dialog (that dialog code was fully removed).
- It now: pops the modal, pushes `/feedback` with a `FeedbackResult` (currently a mocked score of 85, +40 XP, and humanized feedback text — marked with a `TODO` to wire the real `TaskSubmissionResponse` from the API), then calls `widget.onTaskCompleted()`.

### `dashboard/presentation/dashboard_screen.dart`
Two new entry points:
- (a) The streak bento card is now a `GestureDetector` that pushes `/progress` on tap.
- (b) The "Active Mission" section header now has a green "See all missions" link (with chevron) on the same row that pushes `/tasks`.

---

## Conventions to preserve when continuing

- Style follows `mobile/README.md` design system: Manrope via `AppTypography.textTheme`, 8pt `AppSpacing`, `AppRadius` tokens, `AppColors` palette (navy `#0E1B2A`, green, cyan, xp-purple, gold), transparent AppBars over `AppColors.background` with ambient circle glows in a `Stack`, 100px bottom scroll padding to clear the floating dock.
- Reuse shared widgets instead of hand-rolling: `DailyTaskCard`, `VerifAIButton`, `XPBar`, `StreakBadge`, `DimensionBar`, `ScoreRing`, `EmptyState`.
- Riverpod `ConsumerStatefulWidget`/`StatefulWidget` pattern, `go_router` for navigation.

---

## Known remaining work

Real data plumbing:
- Repositories/providers for tasks + progress.
- Extending the `ApiClient` abstract class with `getTasks()` / `getProgress()`.
- Having `TaskChallengeModal` consume the real `submitTask()` response instead of the mocked 85-score.

The backend already exposes `GET /api/tasks/next`, `POST /api/tasks/:id/attempt`, and `GET /api/progress/me` — the mock shapes should mirror those responses for a drop-in swap.
