# VerifAI — Sprint 2 Frontend

Response to the first QA round. This file covers **mobile/Flutter work only** and
pairs with `SPRINT2_BACKEND.md`. It assumes the frozen contract in that file
(verification report v2, error envelope, industry switch response, support
content, tour manifest, roadmap and achievements catalog). Build against fixtures
first; do not wait for the endpoints.

**Priority key** — **P0** = QA "High" / blocks a core workflow, **P1** = QA
"Medium" / a shipped surface is confusing, **P2** = polish. **Effort key** —
S = 1, M = 2, L = 3, XL = 5 points (roughly half a day per point for one
developer, including widget tests).

---

## Workload — this file is two workstreams

| Workstream | Section | Owner | Tasks | Points |
|---|---|---|---|---|
| **C — Frontend Fix** | Part C | Frontend dev 1 | 11 | 23 |
| **D — Frontend Build** | Part D | Frontend dev 2 | 9 | 23 |

With A = B = C = D = 23 points, the four buckets are exactly even. Every task
below names the files it touches and the test
that proves it, so the two frontend developers can work in parallel without
colliding: **C owns navigation, industry switching, verification UX, logout and
the achievements shelf; D owns the new content screens, walkthroughs, imagery
and the stage tracker.** The roadmap work is deliberately split that way: the old
list leaves `/track` (D rebuilds the screen) and lands on Profile (C replaces the
hardcoded grid with the live catalog). The two shared files
are `lib/core/router/app_router.dart` (C adds the navigation helpers, D adds the
new content routes) and `lib/features/navigation/main_nav_shell.dart` (C adds the
logout footer, D adds the "Get help" group). Agree on route names and section
order on day 1 (listed below).

### New routes (day-1 agreement)

| Route | Screen | Owner |
|---|---|---|
| `/help` | Help & Support hub | D |
| `/help/faq` | FAQ | D |
| `/help/article/:slug` | Single help article | D |
| `/industry/:slug` | Industry guide (Learn More target) | D |
| `/about` | About Us | D |
| `/contact` | Contact Us | D |
| `/walkthrough/:key` | Full-screen walkthrough player | D |

Existing routes C may touch: `/welcome-tour`, `/change-industry`, `/dashboard`,
`/profile`, `/verification-studio`, all hub routes.

No new routes for the roadmap: `/track` keeps its path and entry points, but
FB-9 rebuilds the screen behind it. FF-11 changes the achievements section of
`/profile` in place. Both are behind the same route names the QA tester uses.

---

# Part C — Fix (current build)

The QA report's first cluster (navigation, industry switching, logout) is a
**restructuring** problem, not a styling one: the app currently has two
navigation systems (a five-tab dock and a drawer that only exists inside the
shell) and no unambiguous "back to Home" rule. The fix is to make the rules
explicit and shared, not to add a third system.

## FF-1 — Navigation is inconsistent and some screens have no back · P0 · L (3)

**QA ref:** 2 (clear back button on secondary screens; consistent navigation).

**Issue.** The app bar is written by hand in more than 40 places across
`mobile/lib/features/**`. Screens pushed from a hub inherit Flutter's default
arrow, but:
- `/welcome-tour` is opened with `context.go`
  (`industry_select_screen.dart:141`) and has **no app bar at all**, so there is
  no back stack and system back exits the app.
- `/change-industry` hardcodes `context.go('/profile')`
  (`industry_select_screen.dart:40`) instead of popping.
- `LabHomeScreen` hand-rolls its own back logic instead of using a shared
  pattern (`lab_home_screen.dart:42-45`).
- `TaskRunScreen` is entered with `pushReplacement` in the retry/continue paths,
  so where Back lands depends on which path launched it.
- The automatic arrow uses the framework default rather than the app's icon
  treatment and tooltip.

**Fix**
- Add `mobile/lib/shared/widgets/verifai_app_bar.dart`: one AppBar builder with
  `showBack`, `fallbackRoute` (default `/dashboard`), optional `title`, `actions`
  and a consistent 48dp leading target, `Semantics(label: 'Back')`, and the app's
  typography/colour. Back uses `context.pop()` when `canPop()`, otherwise
  `context.go(fallbackRoute)`.
- Replace the feature app bars screen by screen (mechanical, no redesign).
- Make the tour a **pushed** route when it is entered from onboarding and from
  Help; when onboarding is incomplete, its back returns to industry selection.
- Replace `go` with `pop` in change-industry, and the custom back in
  `LabHomeScreen` with the shared widget.
- Audit the route table: every non-root route must either have a back target or
  be a deliberate root (`/dashboard`, `/login`, `/splash`).

**Acceptance**
- Every secondary screen has a visible, labelled back control.
- System back from a secondary screen never exits the app.
- Back from a hub-returning flow lands on that hub, not on a different tab.
- Task run → feedback → back returns to the task's hub, not out of the flow.

**Tests.** `test/features/navigation/back_navigation_test.dart` (one case per
entry point); update `main_nav_shell_test.dart` and `shell_tab_reentry_test.dart`.

## FF-2 — There is no direct way back to Home · P0 · M (2)

**QA ref:** 2 ("return to Home without closing or restarting the app").

**Issue.** The bottom dock exists only on the five tab routes. On every pushed
screen the dock is gone, so the only way Home is repeated back taps; a deep link
into `/ai-lab/lessons/...` or `/verification-studio` has no Home at all.

**Fix**
- `goHome(context)` helper in `lib/features/navigation/`: `context.go('/dashboard')`
  (never `push`, to avoid a second shell — see the global-key note in
  `nav_drawer_controller.dart`), then clear any modal route.
- Add a Home action to the shared app bar on pushed screens (icon + tooltip,
  or in the overflow on narrow layouts).
- Keep the dock's Home tab as is, and add "Dashboard" as the first drawer entry.
- Ensure returning Home does not lose in-progress input silently: if a task run
  has unsaved selections, confirm before leaving (small dialog, reuse the
  existing confirm pattern).

**Acceptance**
- From any screen, Home is at most two taps away.
- Home after a deep link works and shows the dashboard (not a blank stack).
- Leaving a half-answered task asks before discarding.
- No duplicate `MainNavShell` / global-key crash.

**Tests.** `test/features/navigation/home_navigation_test.dart` (deep link,
pushed screen, unsaved task confirmation).

## FF-3 — The hamburger menu is only available on five screens · P0 · M (2)

**QA ref:** 2 ("hamburger menu available where expected and does not create
confusion").

**Issue.** The drawer is defined inside `MainNavShell`
(`main_nav_shell.dart:120`) and opened through a global scaffold key
(`nav_drawer_controller.dart`). Pushed screens cannot open it, so the menu
appears and disappears depending on where you are. The drawer also mixes two
behaviours: tab destinations switch the dock
(`_onItemTapped`), everything else `push`es, so "back" after a drawer choice
depends on where you started.

**Fix**
- Keep **one** full index in the drawer for the five tabs, and add the same index
  as an "All sections" bottom sheet on pushed screens (opened from the shared app
  bar). Do not mount a second `Drawer` on pushed routes: the app already
  documents why two shells break the global key.
- Make every entry's navigation rule explicit: tab routes switch, leaf routes
  push. After choosing a leaf route, back returns to the screen you were on; the
  sheet is closed first.
- Add the new content destinations (Help, FAQ, About, Contact) to the shared
  index, in a "Get help" group above the footer.
- Remove duplicate routes from the drawer where a hub already owns them (e.g.
  keep "Verification Studio" under Practice, not in two groups).

**Acceptance**
- The full destination index is reachable from every signed-in screen.
- Every entry either switches a tab or pushes exactly one screen.
- No destination is listed twice under different labels.
- `shell_tab_reentry_test.dart` still passes.

**Tests.** `test/features/navigation/menu_parity_test.dart` comparing the drawer
and the sheet entry lists.

## FF-4 — Industry switching is buried and invisible · P0 · M (2)

**QA ref:** 3 (industry switching is confusing; make it discoverable).

**Issue.** Changing industry requires Profile → the top-right account icon
(`manage_accounts`) → bottom sheet → "Explore another industry"
(`profile_screen.dart:164,886`). The dashboard does show the track name
(`dashboard_screen.dart:54`) but it is static text; nothing invites a tap. A
user who picked the wrong industry after skipping the tour will not find it.

**Fix**
- Drawer header: current industry as a chip with a "Change" affordance, opening
  the change flow directly.
- Dashboard app bar: make the track label tappable (edit icon, tooltip "Change
  industry").
- Profile: add a visible "Your industry" tile above account actions.
- `/change-industry`: keep the existing selection screen but add a short
  explanation card at the top — what changes (tasks, lessons, readiness, tour),
  what is kept (XP, level, streak, tokens) — using the frozen backend contract
  (`kept`). Show the current industry as "Selected".
- If the user has progress, confirm before switching with a single sentence:
  "Your Finance progress is saved. Legal starts at Novice."

**Acceptance**
- Industry change is reachable in one tap from the drawer and the dashboard.
- The explanation matches the backend response exactly (no invented promises).
- The current industry is visible on the selection screen, the drawer and the
  dashboard.
- Cancel returns to where the user came from.

**Tests.** `test/features/onboarding/industry_switch_entry_test.dart` (all three
entry points, cancel, confirm).

## FF-5 — Switching industries leaves stale content on screen · P0 · M (2)

**QA ref:** 3 ("ensure the correct learning content and features are displayed"
after switching).

**Issue.** `_handleContinue` invalidates only `dashboardProvider`
(`industry_select_screen.dart:135`). `interviewQuestionsProvider`,
`roadmapProvider` (replacing `milestonesProvider`, see FF-11), lab
lesson/paper/analysis families, `verificationTasksProvider`,
judgement/risk-goal task providers, `leaderboardProvider`, `historyProvider`,
`progressProvider`, achievements and the Vera context can all still hold the
previous industry's data. Some are `autoDispose` and refetch, but the ones held
by mounted tabs do not.

**Fix**
- `invalidateTrackScopedProviders(ref)` in `lib/core/providers/track_scope.dart`,
  covering every provider whose content depends on the track (list them in one
  place with a comment).
- Add a `trackRevisionProvider` (`StateProvider<int>`) bumped on every successful
  switch; track-scoped providers `watch` it so future providers opt in with one
  line instead of being forgotten.
- Reset the shell tab cache (`_tabs`) so a mounted Profile/Progress tab rebuilds
  with the new track. If a full reset is too heavy, force-refresh each tab's
  provider on next build.
- After switching, `go('/dashboard')` and let the dashboard refetch; do not rely
  on the user pulling to refresh.

**Acceptance**
- Finance → Legal → Practice/Progress/Interview/Leaderboard all show Legal
  content without an app restart.
- Finance → Legal → Finance restores Finance values.
- No screen shows another industry's task titles after a switch.
- The list of invalidated providers is covered by a test that fails when a new
  track-scoped provider is added without being registered.

**Tests.** `test/features/onboarding/track_refresh_test.dart` with a fake API
that returns track-tagged data and counts calls.

## FF-6 — Skipping the tutorial removes all guidance permanently · P1 · M (2)

**QA ref:** 3 (tutorial accessible when entering a new industry), 7 (skipping
must never leave a user without guidance), 5 (Help after a skip).

**Issue.** `welcome_tutorial_screen.dart:18` writes
`verifai_welcome_tutorial_completed_v1`, but no code reads it. The tour is only
reachable from the first industry selection; changing industry goes straight to
`/dashboard` (`industry_select_screen.dart:141`). There is no "replay tutorial"
anywhere.

**Fix**
- Read the flag at startup (and the backend `tutorial` summary once BF-7 lands).
  The server is the source of truth; SharedPreferences is an offline cache keyed
  per track (`verifai_tutorial_<trackId>_v1`).
- Dashboard: a dismissible "Getting started" card for users who skipped or have
  not completed the tour. Actions: "Take the 60-second tour" and "Not now".
- Help and Profile: "Replay welcome tour" and "Industry introduction".
- On entering a new industry, if `tour.should_offer`, show a one-time sheet:
  "New to Legal? Take the 60-second introduction." Never block the dashboard.
- Make `WelcomeTutorialScreen` take an optional `trackId` and `onDone` so it can
  be pushed from anywhere and return to the caller, instead of always `go`ing to
  `/dashboard`.

**Acceptance**
- Skip is reversible from Help and Profile.
- A new industry offers its introduction once; dismissing does not offer it
  again until the user asks.
- The tutorial can be opened from Help with a working back arrow.
- Existing onboarding tests still pass; add a replay test.

**Tests.** `test/onboarding_tutorial_test.dart` extended (skip → card → replay).

## FF-7 — Verification Studio's failure and result states are misleading · P0 · L (3)

**QA ref:** 9 (verification fails; useful errors; never claim checks that did not
happen).

**Issue.** The catch block shows `'Verification failed. $e'`
(`verification_studio_screen.dart:137`), which leaks the Dio exception and tells
the user nothing. The client accepts 10 MB while the server rejects above 5 MB
(`:59` vs `services/extract.js`). The picker accepts any file type and the app
sends unknown types as `text/plain`. On failure the user's text and sources stay
in the form but there is no Retry. The result screen
(`verification_result_screen.dart`) never shows `sources_confirmed` or
`web_searched`, says "Nothing flagged." when the list is empty, and renders
"Appears sound" in green even when no source was checked — the false-positive
risk the QA report explicitly calls out.

**Fix**
- Read limits and accepted formats from `GET /api/meta` (backend BB-8); fall back
  to 5 MB / `pdf, docx, txt, md` until it exists.
- Restrict the picker (`FileType.custom`, allowed extensions) and reject oversize
  files locally with the real limit before reading base64.
- Map the backend `code` to an inline, actionable error state:
  - `document_too_large` → "That file is 6.2 MB. The limit is 5 MB."
  - `document_no_text` → "We could not read any text. This looks like a scanned
    PDF — try a text-based file or paste the text."
  - `document_unsupported` → list the supported formats.
  - `ai_timeout` / `ai_unavailable` → "Verification is temporarily unavailable"
    with **Retry** (same input).
  - offline → reconnect hint, keep input.
- Keep the user's text, context and source chips on every failure; never clear
  the form until a report succeeds.
- Result screen: add a "What was checked" strip (web search on/off, sources
  found, claims checked, citations checked). Render `insufficient_evidence` as a
  neutral "Not enough evidence" — never green. Only show "Appears sound" when
  `checks.sources_found > 0` and at least one claim was checked.
- Read `inputs[].pages`, `pages_read`, `truncated` and `quality` from the
  contract. If `truncated`, show a warning above the claims: "We read pages 1–40
  of 62; later pages were not checked." If `quality` is `low`, say the text was
  hard to read and suggest pasting the text or uploading a clearer file.
- Add "Try again" (re-open the studio with the same input where possible) and
  "Edit input" actions; show the report's `summary` before the claims.
- Use the same error component for the history-load failure instead of a bare
  "History unavailable."

**Acceptance**
- No raw exception text is ever rendered.
- Every `code` has a specific message and an action.
- A 6 MB file is blocked before upload and names the real limit.
- A report with zero sources cannot display green or the word "verified".
- A truncated or low-quality document is visibly disclosed before the claims.
- A failed run is recoverable without retyping, including a scanned-PDF
  rejection.

**Tests.** `test/features/verification/verification_studio_error_test.dart` and
`verification_result_state_test.dart` (one case per code; no-overclaim case).

## FF-8 — Log out is not in the menu · P0 · S (1)

**QA ref:** 10.

**Issue.** Log out is a red `TextButton` in the Profile app bar
(`profile_screen.dart:176-184`) plus a dialog (`:916-950`). The drawer has no
account actions at all.

**Fix**
- Drawer footer: divider, then a single "Log out" row in the error colour, below
  navigation and above the version line. Same action on the secondary-screen
  overflow.
- One shared confirm dialog ("Log out of VerifAI? You can sign back in any
  time."). On confirm: close the menu/sheet, `await authNotifier.logout()`, and
  let the router redirect to `/login`.
- Remove the duplicate app-bar button (or keep it behind the overflow) so the
  action has one home.
- Ensure the back stack cannot re-enter the app after logout (the router
  redirect covers this; add a test).

**Acceptance**
- Log out is reachable from every signed-in screen and visually separated from
  navigation.
- Cancel changes nothing; confirm lands on `/login`.
- System back after logout does not return to a signed-in screen.
- No previous user's data flashes after the next sign-in (existing provider
  invalidation in `app_router.dart` remains in force).

**Tests.** `test/features/navigation/logout_test.dart`.

## FF-9 — Hub copy reads unfinished · P2 · S (1)

**QA ref:** 1 ("a little plain and confusing for a first-time user"), 8.

**Issue.** Several strings are missing punctuation or words:
- Learn hub: "Lessons scenarios and capstones read it practise it prove it"
  (`learn_hub_screen.dart:73`).
- Practice hub: "Decide when AI should or shouldnt be used" and "Spot privacy
  bias and compliance risks" (`practice_hub_screen.dart:24,32`).
- Practice hub also says "One scenario at a time, then check what changed." for
  a screen that is mostly a menu.

**Fix.** Copy pass over the hub headings, subtitles, empty states and permission
prompts. Sentence case, one idea per line, no missing apostrophes. Move reusable
marketing copy into the Help/About content (backend BB-1/BB-2) so it can be
corrected without a release. Do not rewrite the brand voice.

**Acceptance**
- No typos or sentence fragments on the audited screens.
- Copy is consistent with the Help article wording (one name per feature:
  "Verification Studio", "Vera", "AI Lab", "Practice").
- Team review sign-off in the PR.

## FF-10 — No regression tests for the new navigation rules · P1 · M (2)

**QA ref:** 12 (retest and prove nothing else broke).

**Issue.** `main_nav_shell_test.dart` covers the five tabs and that the drawer
opens; `shell_tab_reentry_test.dart` covers tab re-entry. Nothing covers back
behaviour, Home, the menu sheet, logout, industry switching or tutorial replay,
so this sprint's changes would be unguarded.

**Fix.** Add widget tests using the existing `test/support/mock_api_client.dart`:
- back from each hub destination returns to that hub,
- Home from a pushed screen and from a deep link,
- drawer/sheet parity,
- industry switch invalidates the right providers (FF-5),
- logout from the drawer,
- tutorial skip → Getting started card → replay,
- verification error codes and no-overclaim result.

Update `main_nav_shell_test.dart` only where the drawer gained entries (assert the
new "Get help" group).

**Acceptance**
- All new tests pass in CI alongside the existing suite.
- No test depends on a real network call or Firebase.
- The four workstreams each add at least one test; none is deleted to make a
  build green.

## FF-11 — Roadmap milestones live on the wrong screen, and achievements are hardcoded · P1 · L (3)

**Source:** product feedback on the Skill Roadmap (after QA round 1).

**Issue.** `TrackRoadmapScreen` renders the six generic items from
`milestonesProvider` as a timeline (`track_roadmap_screen.dart`), so the roadmap
looks like a badge list. At the same time, Profile renders achievements from
`GET /api/achievements/me` (earned only) against `_badgeCatalog`, a hardcoded
five-item list (`profile_screen.dart:969-1015`). That means the achievements
being moved off the roadmap (BF-9) would not appear on the achievements screen
without an app release. `milestonesProvider` is also invalidated from
`app_router.dart`, `app_reconnect.dart` and `resume_refresh.dart`, so every
reference has to move with it.

**Fix**
- Remove the milestone timeline and `Milestone` model usage from `/track`;
  FB-9 replaces the screen.
- Add `getAchievementCatalog()` to `ApiClient`, `DioApiClient` and
  `MockApiClient`, calling `GET /api/achievements` (full catalog with `earned`).
  Extend `Achievement` with `earned` (default false) and keep `earnedAt`.
- Profile: render the catalog, not `_badgeCatalog`. Keep a code → icon/colour
  map for the known achievements and a neutral medal fallback for new codes, so
  future achievements still appear. Keep the "X / N Unlocked" count driven by
  the catalog. Show earned and locked in the same grid (current behaviour) and
  keep the `newly_earned_achievements` chips on feedback.
- Replace `milestonesProvider` invalidations with `roadmapProvider`, delete
  `getMilestones()` from both clients and the mock, and delete
  `shared/models/milestone.dart` once nothing imports it.
- Update copy that still says "XP & milestones" (dashboard quick tile) to
  "XP & achievements".
- Tests: catalog renders new achievements (including `track-master`, `xp-250`,
  `streak-7`, `level-5`), locked vs earned counts, no `getMilestones` calls.

**Acceptance**
- Achievements show all 14 catalog entries, including the five moved from the
  roadmap, without an app release.
- A newly seeded achievement appears with a neutral icon if the app does not know
  its code yet.
- `/track` no longer references `Milestone` or `getMilestones`.
- No screen says "milestones" when it means achievements.

---

# Part D — Build (net-new)

These are new surfaces. They exist to answer QA items 4–8: a first-time user must
be able to understand an industry before choosing it, find help after skipping
onboarding, read answers to common questions, contact the team, and see a product
that does not look plain. Content comes from the backend (`SPRINT2_BACKEND.md`
Part B); the app must render it and remain usable offline/with a fixture.

## FB-1 — "Learn more" on every industry card · P0 · L (3)

**QA ref:** 4 (Learn More on all four cards), 5 (industry information pages).

**Issue.** `_TrackCard` (`industry_select_screen.dart:252-355`) shows icon, name,
description and a perk; tapping selects. There is no way to read about a pathway
before committing to it.

**Fix**
- Add a `Learn more` text button in the card footer with its own 44dp tap target.
  It must **not** select the industry; use a nested `TextButton`/`InkWell` with
  its own handler and a test that asserts selection is unchanged.
- The grid's fixed `mainAxisExtent: 240` (`:194`) must grow or become responsive;
  verify at 320 px width and 200% text scale.
- New `features/industry/presentation/industry_guide_screen.dart` at
  `/industry/:slug`, content from `GET /api/support/industry-guides/:slug`
  (BB-2), bundled fallback for offline. Sections:
  1. Hero image + tagline.
  2. What this pathway is about.
  3. What you will learn and be able to do.
  4. The skills and what they mean in this industry.
  5. How to use Learn, Practice, Verification Studio, Vera, tasks and Progress.
  6. First-session checklist.
  7. Related FAQs.
- Header: industry name, "Back to industries", and a "Choose this industry"
  primary action. From onboarding it selects and continues exactly like tapping
  the card. From Help it opens the change flow (FF-4) with the usual
  confirmation, never a silent switch.
- Loading, error/retry and an offline notice; markdown rendered with the existing
  widget.

**Acceptance**
- All four cards show "Learn more"; tapping it opens the guide without selecting.
- The page has every section above and a clear way back to industry selection.
- Deep link to `/industry/legal` works (and redirects to login when signed out).
- No truncation at 320 px / 200% text.

**Tests.** `test/features/onboarding/industry_learn_more_test.dart` (selection
unchanged, navigation, back) and `industry_guide_screen_test.dart` (sections,
error, fallback).

## FB-2 — Help & Support hub · P0 · L (3)

**QA ref:** 5 (central Help & Support), 3 (guidance after skipping), 1 (first-time
understanding).

**Issue.** There is no help surface in the app at all (grep for `Help`, `FAQ`,
`Support` in `lib` returns nothing).

**Fix.** New `features/help/presentation/help_home_screen.dart` at `/help`:
- **Search** across the loaded articles and FAQs (local and instant; the help
  payload is small enough to filter in memory, so no backend search is needed
  this sprint).
- **Start here:** what VerifAI is, the 60-second walkthrough (FB-4), and "take
  the tour" (FF-6).
- **How the app works:** the five areas, hubs, how to go back/Home, where to
  change industry (deep links to FF-4's flow).
- **Feature guides:** dashboard cards, Learn, Practice, Verification Studio,
  Vera, Progress & rewards, Wellness — each a short article plus "open feature".
- **Industry guides:** four cards linking to `/industry/:slug` (FB-1).
- **Verification help:** how to read a report, what the verdicts mean, what to do
  when a check fails — linked from the verification error state.
- **Troubleshooting:** can't log in, content won't load, verification failed,
  offline, how to change industry.
- **Still need help?** Contact (FB-6) and FAQ (FB-3).
- Article view at `/help/article/:slug` with back, reading width, and related
  links. Content from BB-2 with bundled fallback.
- Reachable from the drawer/overflow "Get help", the verification error, and the
  dashboard "Need help?" link.

**Acceptance**
- Every section above exists and is reachable without a network call (fallback).
- Search returns a result for at least the ten QA FAQ questions and the words
  "change industry", "back", "verification", "Vera".
- Opening an article from search/back returns to the search with the query
  preserved.
- Works at 320 px / 200% text and in dark mode.

**Tests.** `test/features/help/help_home_test.dart` (sections, search, article
open/back, offline fallback).

## FB-3 — FAQ · P0 · M (2)

**QA ref:** 6 (FAQ section).

**Issue.** No FAQ content or screen exists.

**Fix.** `/help/faq`, grouped by topic (Getting started, Industries, Learning,
Verification, Progress & rewards, Account), with:
- accordions (one open at a time per group; `Semantics(expanded:)`),
- search across question and answer,
- the ten QA questions from BB-1 verbatim, each answer short (≤120 words) with
  "Read more" links into Help articles,
- "Still not answered?" → Contact (FB-6),
- `faq_expand` analytics event (BB-6) fired once per open, best-effort.

**Acceptance**
- All ten questions are present and answerable without leaving the screen.
- Search matches answer text as well as questions.
- Expanding does not navigate or lose scroll position.
- Deep link to a question (anchor) opens it expanded.

**Tests.** `test/features/help/faq_test.dart`.

## FB-4 — Walkthroughs (video or voice-over) · P1 · L (3)

**QA ref:** 7 (short video/voice-over explaining the app and each industry).

**Issue.** `mobile/assets/audio/` contains only a chime plus
`ADD_YOUR_WELCOME_RECORDING.txt`, which claims the splash plays a recording — no
audio/video plugin is in `pubspec.yaml` and no playback code exists. The tutorial
is text and icons only.

**Fix**
- Add `video_player` (official Flutter plugin; supports Android, iOS and the web
  build the team uses for iOS testing). `webview_flutter` is not a safe choice
  here: it has no first-class web support, so a WebView player would break the
  hosted build.
- Host the walkthroughs as H.264/AAC MP4 with a poster frame; play them with
  `VideoPlayerController.networkUrl` inside a `WalkthroughPlayer` widget. Show a
  transcript (markdown from BB-3) below every video and use the player's progress
  for the watched state; add `.vtt` captions if the player package in use
  supports them, otherwise the transcript is the accessible equivalent.
- `/walkthrough/:key` full-screen player plus an inline card on Help and on the
  tour screen. Show duration, poster and transcript.
- Never autoplay; remember watched state locally; if the video fails to load,
  show the transcript and the relevant screenshots instead of an error.
- One global walkthrough (dashboard → start a task → Vera → menu → Progress) and
  four short industry walkthroughs.
- Remove or correct `ADD_YOUR_WELCOME_RECORDING.txt`; the app does not have an
  audio player, so it must not promise one.
- **Voice-over option:** if the team records narration instead of video, the same
  route hosts an audio player; that needs `just_audio` (or `audioplayers`) as a
  separate, deliberate dependency. Default to hosted video.

**Acceptance**
- Global + four industry walkthroughs listed and playable on Android, iOS and
  web.
- Transcript is always available; muted/no-video fallback is usable.
- No autoplay, no background audio, no data use before a tap.
- The misleading audio note is gone.
- The new dependency is recorded in `pubspec.yaml` and the README, and the web
  build is re-verified after adding it.

**Tests.** `test/features/help/walkthrough_test.dart` (manifest rendering,
fallback when the player fails, no autoplay).

## FB-5 — About Us · P1 · M (2)

**QA ref:** 5 (mission, vision, what the app helps with in South Africa).

**Issue.** No About surface exists.

**Fix.** `/about`, content from `GET /api/support/about` (BB-2) with a bundled
fallback:
- Mission and vision, in one short paragraph each.
- The problem in South Africa: AI adoption outpacing verification skills, the
  employability gap, and POPIA-aware practice — factual, no invented statistics.
- What VerifAI helps you do (learn, practise, verify, prove readiness).
- Who it is for (students, graduates, early-career professionals, teams).
- How it works in four steps (choose industry → learn → practise with feedback →
  build evidence of readiness).
- Team/credits and a Contact CTA (FB-6).
- Version/build number from the existing app constants (no new dependency).
- Link from the drawer footer and the login screen (public, so it must not
  require a session).

**Acceptance**
- Reachable signed out and signed in.
- No placeholder or lorem text; mission/vision approved by the team.
- Every claim is either qualitative or sourced; no fake numbers.
- Back returns to the entry point.

**Tests.** `test/features/help/about_test.dart`.

## FB-6 — Contact Us · P1 · M (2)

**QA ref:** 6 (contact us for more info).

**Issue.** No contact surface or endpoint exists.

**Fix.** `/contact` with:
- name, email (prefilled from the account when signed in), topic dropdown
  (`bug`, `account`, `content`, `verification`, `feedback`, `other`), message,
  optional app version.
- Inline validation, character count, keyboard types, no request until valid.
- Submit to BB-4; success shows the ticket id and expected reply time; failure
  keeps the draft, offers Retry and a `mailto:` fallback.
- Privacy note: what is stored, why, and how long; link to the privacy article.
- "Report a problem" entry from Help and the verification error state, pre-filling
  the topic and, where useful, the report `request_id` (never the document text).
- Signed-out users can contact (name/email fields required).

**Acceptance**
- Invalid email/message is blocked inline.
- Double submit is prevented; success and failure states are distinct.
- Draft survives a failed submit and a keyboard dismissal.
- No document content or credentials are ever attached.

**Tests.** `test/features/help/contact_test.dart`.

## FB-7 — Explain the dashboard in context · P1 · M (2)

**QA ref:** 1 (a first-time user cannot tell what each feature means), 8.

**Issue.** The dashboard shows streak, tasks completed, next task, the readiness
ring and six quick-access tiles (`dashboard_screen.dart:181-586`) with no
explanation of what any of them measure or do.

**Fix**
- Add an info affordance to each card/tile → a bottom sheet with 2–3 sentences
  and a "Learn more" link to the matching Help article (FB-2).
- Add a one-time "How this works" coach-mark pass over the dashboard (3 steps:
  readiness ring, next task, quick access), replayable from Help, dismissible,
  never blocking, `Semantics` labels.
- Add the "Getting started" card for users who skipped onboarding (shares state
  with FF-6).
- Keep the dashboard's existing data and layout; this is annotation, not
  redesign.

**Acceptance**
- Every dashboard card/tile has an explanation and a working deep link.
- Coach marks can be skipped and replayed; dismissing is persisted.
- No overlay blocks scrolling or the dock after dismissal.
- Existing dashboard tests and text-scale tests still pass.

**Tests.** `test/features/dashboard/dashboard_help_test.dart`.

## FB-8 — Visual system: people, work and AI imagery · P2 · L (3)

**QA ref:** 8 (relevant photographs and AI illustrations; not decoration).

**Issue.** `mobile/assets/images/` contains 11 files: logos, the Google sign-in
mark and nine reward product photos. There is no imagery of people learning,
working with AI, or explaining a feature, so the app reads plain exactly as QA
described. `assets/audio/` has one chime.

**Fix**
- Commission or license a small, coherent set (8–12 images): a learner at a
  laptop, a small team reviewing AI output, a close-up of checking a document, a
  South African workplace, and 3 flat illustrations for empty/error states.
- Use them where they explain: industry guide heroes (FB-1), Help header (FB-2),
  dashboard welcome card, verification empty state, About hero (FB-5), walking
  tour posters (FB-4). No image that is purely decorative.
- Pipeline: crop to 16:9 and 1:1, compress to progressive JPEG/WebP at ≤120 KB,
  same approach as the reward photos; add a dark-mode treatment and a scrim
  where text sits on the image.
- `semanticsLabel` for informative images, `excludeFromSemantics` for decorative
  ones; never put essential text inside an image.
- Record provenance/licence in `mobile/assets/images/CREDITS.md` (the file exists
  for rewards).
- Budget: total new assets ≤1.5 MB.

**Acceptance**
- Every new image has a credit and a licence note.
- Total asset budget respected; app size check recorded in the PR.
- Layouts verified at 320 px, 200% text, light and dark.
- No placeholder/generated faces; no brand logos without permission.

**Tests.** Asset-load smoke test for each new image plus the existing widget
suite; no golden images required.

---

## FB-9 — Stage-based milestone tracker UI · P1 · L (3)

**Source:** product feedback on the Skill Roadmap.

**Issue.** `/track` renders a flat list of XP/streak/level counters as a
timeline. It has no stages, no gating, no evidence from the learner's work and
no "what next" action, so it reads as achievements rather than a journey. There
is no roadmap model or provider, and the backend endpoint does not exist yet.

**Build**
- Models `RoadmapData`, `RoadmapStage`, `RoadmapMilestone`, `RoadmapAction`,
  `RoadmapCredential` in `shared/models/roadmap.dart` (plain classes, same style
  as `Milestone`).
- `getRoadmap({int? trackId})` on `ApiClient`, `DioApiClient` and
  `MockApiClient`, plus `roadmapProvider` (`FutureProvider.autoDispose`) in
  `features/track/providers.dart`.
- Replace `TrackRoadmapScreen` with the stage tracker described below, keeping
  the `/track` route and the "Skill roadmap" entry points.
- CTA deep links: use the milestone's `action.route`; fall back by requirement
  type if a route is missing, so bad content can never produce a dead button.
- Loading, empty, error/retry, pull-to-refresh, and a "How this works" link to
  the roadmap Help article.
- Tests: stage statuses, milestone progress, next action, locked preview, empty
  and error states, CTA route mapping.

**Acceptance**
- The screen shows five stages, the current stage expanded, completed stages
  collapsed with a check, and future stages locked with a one-line preview.
- Every milestone shows evidence progress (`2 of 3 tasks`) and the next action
  is one tap from the relevant feature.
- No XP, streak or badge appears on this screen; those live on Profile.
- Works at 320 px and 200% text scale, light and dark.

---

# Milestone tracker — screen design

This is the UI half of the shared design in `SPRINT2_BACKEND.md` → "Roadmap
design". The backend is the source of truth for status and gating; the app only
renders it.

## Screen structure (`/track`, title "Your readiness path")

1. **Hero card**
   - Eyebrow: `STAGE 2 OF 5`.
   - Stage title and one-sentence outcome (`Verify — Catch confident mistakes in
     AI output.`).
   - Overall progress bar over milestones (`3 of 10 milestones`), not stage
     count alone.
   - Readiness chip (`34 / 100 · Novice`) linking to `/progress`.
   - Credential chip: `Passport locked` / `Passport ready`.
2. **Next up card** (sticky under the hero while scrolling)
   - Milestone title, one-line reason, evidence progress.
   - Primary CTA from `next_action.label` / `route` (e.g. "Pass your next
     verification task" → `/verification`).
   - If the next action is readiness, CTA goes to `/progress`; if it is a
     capstone, to `/ai-lab/assessments`.
3. **Stage list**
   - **Completed:** green check, stage title, outcome, `2/2`; collapsed by
     default, expandable to see what was done.
   - **Active:** outlined card, expanded. Milestone rows show a small progress
     bar, `current / target unit`, and a state label (`Done`, `Next`, `Up next`).
     Only the first incomplete milestone carries a filled CTA; the others show a
     quiet "Up next" chip so the user is not sent in five directions.
   - **Locked:** lock icon, title, `Unlocks after <previous stage>`, and the
     milestone titles as a preview (no CTAs).
4. **Credential card**
   - "AI Readiness Passport": locked/unlocked, the requirement in one sentence,
     and a CTA to `/progress` when readiness is the blocker. No share sheet this
     sprint.
5. **Footer link**
   - "How the roadmap works" → Help article, explaining stages vs achievements
     and that XP/streaks live on Profile.

## Interaction rules

- Tapping a completed or locked stage expands/collapses it; it never navigates.
- A milestone CTA navigates with `context.push` so Back returns to the roadmap.
- On return, the screen refreshes (provider is `autoDispose`; also invalidate on
  resume).
- Pull-to-refresh re-fetches; a failed refresh keeps the last good data with an
  inline error, rather than replacing the screen.
- Score milestones use the milestone's own best-ever `current` ("Reached 70
  readiness"), while the hero chip shows the live readiness score. Slight
  disagreement is correct; never recompute or reconcile it on the client.
- No confetti, badges or XP on this screen. The only numbers are evidence
  progress and readiness.

## Deep-link mapping (fallback when `action.route` is absent)

| Requirement | Route |
|---|---|
| `tutorial_completed` | `/welcome-tour` |
| `tasks_passed` (verification) | `/verification` |
| `tasks_passed` (judgement) | `/judgement` |
| `tasks_passed` (risk_governance) | `/risk-governance` |
| `capstone_score` | `/ai-lab/assessments` |
| `industry_cases_read` | `/industry-practice` |
| `activities_passed` | `/ai-lab/practice` |
| `readiness_score` | `/progress` |

## States and accessibility

- **Loading:** a hero shimmer plus three stage-card shimmers, matching the final
  layout.
- **Empty:** "Your path is being prepared for this industry" + Contact/Help
  links; no fake stages.
- **Error:** inline error card with Retry, keeping the app bar and pull-to-
  refresh available.
- **Semantics:** stage cards announce "Stage 2 of 5, Verify, active"; milestone
  progress announces "2 of 3 tasks complete"; every CTA has a label that names
  the destination feature.
- **Contrast/tap targets:** 48dp minimum, existing palette, no colour-only
  status (icon + text for complete/locked).

## What this replaces

The old `TrackRoadmapScreen` timeline, `MilestoneStatus` enum,
`milestonesProvider` and `getMilestones()` are removed. The six former items are
now achievements on Profile (FF-11), so nothing is lost: the roadmap becomes the
journey, and the achievement shelf keeps the badges.

## Suggested sequence

Both workstreams start after the route/contract agreement on day 1.

| Day | Frontend Fix (C) | Frontend Build (D) |
|---|---|---|
| 1 | Route + contract agreement; FF-1 shared app bar | Route agreement; FB-1 screen skeleton on fixture |
| 2–3 | FF-1 audit + FF-2 Home + FF-8 logout | FB-1 guide screen + FB-2 Help shell |
| 4 | FF-3 menu parity + FF-9 copy | FB-2 content sections; FB-3 FAQ |
| 5 | FF-4 industry entry points | FB-5 About; FB-6 Contact |
| 6–7 | FF-7 verification UX (needs BF-8 + BB-8) | FB-4 walkthrough player on fixture |
| 8 | FF-11 achievements catalog + remove old timeline | FB-7 dashboard explanations; FB-9 fixture |
| 9–10 | FF-5 track refresh + FF-6 tutorial | FB-9 roadmap screen (needs BB-10) |
| 11 | FF-10 regression tests | FB-8 imagery + credits; asset budget |
| 12 | Retest support; fix QA2 rows | Retest support; fix QA2 rows |

Dependencies to watch:
- FF-7's final copy depends on BF-8's codes and BB-8's limits. Build the state
  machine on the documented codes; do not wait.
- FF-5 and FF-4's confirmation copy depend on BF-6/BF-5. The UI can be built with
  a fixture response.
- FB-1/FB-2/FB-5/FB-6 need BB-2/BB-4. Ship with bundled fallback content first;
  switch to the API when it lands, and keep the fallback for offline.
- FB-4 needs BB-3. Ship transcript-only until media hosting exists.
- FB-9 needs BB-10 for real data; build against a fixture from the API contract
  in `SPRINT2_BACKEND.md`. FF-11 needs BF-9's seed so the moved achievements
  appear in the catalog.

## QA record — frontend rows

The shared template (test ID, steps, expected, actual, severity, owner, status)
is in `SPRINT2_BACKEND.md`. Frontend-specific rows to close:

| Test ID | Area | Steps | Expected | Actual | Severity | Owner | Status |
|---|---|---|---|---|---|---|---|
| QA2-F01 | Tutorial | Skip onboarding, open drawer → Help | Tour can be replayed | | S2 | FE 1 | Open |
| QA2-F02 | Contact | Submit with a bad email | Inline error, no request | | S3 | FE 2 | Open |
| QA2-F03 | Logout | Drawer → Log out → confirm | Login screen, back cannot re-enter | | S1 | FE 1 | Open |
| QA2-F04 | Navigation | Open each hub, then back | Returns to the hub | | S1 | FE 1 | Open |
| QA2-F05 | Navigation | Open a deep link, tap Home | Dashboard, no blank stack | | S1 | FE 1 | Open |
| QA2-F06 | Industry | Dashboard → industry label → Change | Change flow in one tap | | S1 | FE 1 | Open |
| QA2-F07 | Industry | Switch Finance → Legal, open Progress | Legal-only content | | S1 | FE 1 | Open |
| QA2-F08 | Learn more | Tap Learn more on Legal card | Guide opens, selection unchanged | | S2 | FE 2 | Open |
| QA2-F09 | Help | Search "change industry" | Answer found and opens | | S2 | FE 2 | Open |
| QA2-F10 | Help | Open Help with no network | Bundled content still readable | | S2 | FE 2 | Open |
| QA2-F11 | Verification | Open studio with a 6 MB file | Blocked before upload, real limit shown | | S2 | FE 1 | Open |
| QA2-F12 | Verification | Open a report with zero sources | Not green, no "verified" claim | | S1 | FE 1 | Open |
| QA2-F13 | Verification | Upload an image-only PDF | Scanned-PDF message, draft kept | | S2 | FE 1 | Open |
| QA2-F14 | Verification | Open a 50-page report | Truncation warning with pages read | | S2 | FE 1 | Open |
| QA2-F15 | Visual | Review industry guide + Help | Real imagery, credited, not decorative | | S3 | FE 2 | Open |
| QA2-F16 | Roadmap | Open `/track` on a fresh account | Five stages, Stage 1 active, next action is the tour | | S1 | FE 1 | Open |
| QA2-F17 | Roadmap | Scroll the roadmap | Completed stage collapsed, active expanded, later stages locked | | S2 | FE 1 | Open |
| QA2-F18 | Roadmap | Tap the next-action CTA | Opens the right feature, Back returns to the roadmap | | S1 | FE 1 | Open |
| QA2-F19 | Roadmap | Look for XP, streak or badges on `/track` | None present; only evidence progress and readiness | | S2 | FE 1 | Open |
| QA2-F20 | Achievements | Open Profile after the migration | All 14 badges, including the moved ones; count matches | | S1 | FE 2 | Open |
| QA2-F21 | Achievements | Trigger an unknown achievement code | Neutral medal renders, no crash, count still correct | | S3 | FE 2 | Open |

## QA traceability (frontend-owned)

The full matrix is in `SPRINT2_BACKEND.md`; this is the client-side view.

| QA section | Client-side answer |
|---|---|
| Overall feedback | FB-2 (help), FB-5 (about), FB-7 (in-context explanations), FB-8 (imagery), FF-9 (copy) |
| Navigation & back buttons | FF-1 (shared back), FF-2 (Home), FF-3 (menu parity), FF-10 (tests) |
| Industry switching | FF-4 (entry points), FF-5 (fresh content), FF-6 (replayable tour), FB-1 (guides) |
| Industry "Learn More" | FB-1 (link + guide), FB-8 (guide imagery) |
| About Us | FB-5 |
| Contact Us | FB-6 |
| Help & Support | FB-2, FB-4 |
| FAQ | FB-3 |
| Tutorial videos | FB-4, FF-6 |
| Visual appearance | FB-8, FB-1, FB-2 |
| Verification | FF-7 (honest states, actionable errors) |
| Logout | FF-8 |
| Skill Roadmap (product feedback) | FB-9 (stage tracker), FF-11 (achievements catalog on Profile) |
| Suggested priorities | P0 items scheduled first in the sequence table |
| QA approach | QA record rows + one test per task |

## Definition of done (both frontend workstreams)

- `flutter analyze` reports no issues; all widget tests pass, including the new
  navigation/help/verification tests.
- No raw exception text is shown to a user anywhere; every network failure has a
  human message and an action.
- New screens have loading, empty and error states, and work at 320 px and 200%
  text scale.
- Accessibility: 48dp targets, labelled icons, `Semantics` for accordions and
  progress, colour contrast checked in light and dark.
- Docs updated: `README.md` (help content, imagery credits, verification
  behaviour) and `SPRINT2_FRONTEND.md` marked for the items this sprint closes.
- The QA row is `Closed` only after a retest, not after a merge.

## Out of scope for this sprint

- Redesigning the dashboard, hubs or rewards catalogue.
- Admin support screens (backend API only).
- Voice cloning or synthetic narration; any recording uses a real team voice with
  consent.
- Interview Practice for non-Legal tracks, Prompt Design, and new gamification.
- A shareable or downloadable passport, and any certification claim. The
  roadmap's credential card is a locked/unlocked display state, nothing more.
- Reordering stages per industry. Wording changes per track; the five stages and
  the route order do not.
- Offline caching of videos (transcript fallback is enough for now).

## Risks

- **Route-file collisions** between C and D. Mitigation: D adds routes in one
  block with a comment; C owns the helper file and imports it.
- **Content not ready** blocks Help/About/guides. Mitigation: bundled fallback
  content written from the QA answers, replaced by API content when seeded.
- **Video hosting** may slip. Mitigation: transcript + screenshots first; the
  player is additive. If `video_player` is rejected, the fallback is a
  transcript-only walkthrough, not a broken WebView.
- **Imagery licensing** can delay FB-8. Mitigation: use only supplied or
  commissioned assets; credit everything; never scrape stock images.
- **Scope creep** from "make it less plain" into a redesign. Mitigation: imagery
  and explanations only where they clarify; no new visual language.
- **Roadmap fixture drift.** FB-9 is built against a hand-written fixture; if
  BB-10 changes the contract mid-sprint the screen silently disagrees with the
  server. Mitigation: one fixture file generated from the frozen contract,
  shared by the widget tests, plus a contract test that fails on unknown keys.
- **Achievements grid regressions.** Moving the six items and switching Profile
  to the live catalog changes what the tester sees. Mitigation: keep the code →
  icon map, add a neutral fallback, and keep the unlocked count derived from the
  catalog so a seed change cannot make it wrong.
