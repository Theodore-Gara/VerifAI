# VerifAI — Code Audit Review

**Date:** 20 October 2026
**Scope:** `backend/` (Node/Express/PostgreSQL, ~8,400 LOC of controllers+services) and `mobile/` (Flutter, ~22,800 LOC), plus schema, migrations and seeds.
**Method:** full read of the request pipeline, every controller and service, the schema/index set, the Flutter API layer, router, shell and the main feature screens; ran the backend suite (`npm test` → **182 passed, 0 failed**). `flutter analyze` / `flutter test` could not be run in the first pass (Flutter SDK not on PATH); both fix rounds below were verified with them.

---

## 0. Fix rounds — what changed

Verified after the third round: **backend `npm test` → 186 passed, 0 failed**; **`flutter analyze` → no issues**; **`flutter test` → 50 passed, 0 failed**.

### Round 2 — layout restructure, scalability, theming

| Finding | Fix |
|---|---|
| **7.2** navigation tripled | The dock is now **Home · Learn · Practice · Progress · Profile** with a hub inside each: `LearnHubScreen` (lessons, recall practice, capstones, skill roadmap, Vera) and `PracticeHubScreen` (next task, the three skill flows, interview, Verification Studio, industry cases, history). The old `TaskScreen` and the `Track` tab are gone; `/tasks` redirects to `/practice` and `/track` now opens the roadmap from the Learn hub. The drawer is kept as the **secondary** index (grouped by area, opened from Home's low-emphasis action). Widget tests pin the five tabs, hub switching and the drawer. |
| **7.1** Home had no next action | Home still leads with the recommended task (start/practise, difficulty, dimension), the XP bar, streak/completed tiles, readiness and the dimension index; its quick-launch grid now points at the Learn and Practice hubs instead of scattering routes, and shell links use `go` so they switch the dock instead of stacking a second shell. |
| **5.1** single-instance rate limiting | `utils/pgRateStore.js` is an `express-rate-limit` store backed by a new `rate_limit_hits` table (migration 027), used by the global limiter and by the AI/write per-account limiters (each with its own key prefix). It falls back to an in-process counter if a query fails, so a database blip cannot 500 every request. |
| **5.2** two extra queries per request | `verifyFirebaseToken` caches moderation status for 60 s (`AUTH_STATUS_CACHE_MS`); `invalidateStatusCache` is called from the admin status change, the admin hard delete and self-delete, so a suspension is visible on the user's next request. |
| **5.4** non-sargable analytics | `task_attempts`, `answer_logs`, `lab_activity_attempts` and `lab_capstone_attempts` carry a plain `submitted_date` written by the API (`utils/dates.js`, using `STREAK_TIMEZONE`) with indexes; the timezone conversion is gone from the 30-day chart queries. (A STORED generated column is impossible here: `AT TIME ZONE` is STABLE, not IMMUTABLE.) `/api/admin/analytics` and `/track-progress` are cached for 60 s (`ANALYTICS_CACHE_MS`). |
| **5.5** leaderboard scans every user | The board is cached per `(track, limit)` for 60 s (`LEADERBOARD_CACHE_MS`) and `user_progress` gets a covering `(xp DESC, readiness_score DESC, user_id)` index; the caller's own rank stays live. |
| **5.7** static content queried every render | Tracks, lab sources, the library and the rewards catalogue are cached for 60 s and served with a strong `ETag` + `private, max-age=60`, answering `If-None-Match` with 304 (`utils/httpCache.js`). |
| **5.8** stream kept writing after disconnect | `openStream` now returns an `AbortSignal` tied to a premature socket close; the signal is threaded through Vera, the learning assistant and the Lab coach into the LLM transport, which aborts upstream, skips the fallback retry and reports 499 instead of an error frame nobody can receive. |
| **6.4 / 7.10** no pagination or search | `/api/history` takes `limit`/`offset`/`type`/`q` and returns `has_more`; the history screen has search, type chips and infinite scroll, and task rows open `/feedback/:attemptId`. The admin task list and answer log take `q` plus `limit`/`offset` with a real total. The lesson catalogue filters by title, summary and competency. |
| **6.7** fonts downloaded at runtime | Inter and Manrope are bundled: static weights are instanced from the official variable sources into `assets/fonts/` (OFL 1.1, licences included) and declared in `pubspec.yaml`; `google_fonts` is removed, so typography no longer depends on the network and first paint does not reflow. |
| **7.5** no dark mode, colours hardcoded | `AppColors` now resolves through an `AppPalette` (light + dark) and `AppTheme.themeFor(palette)` builds one theme from those tokens. Profile has a Light/System/Dark control persisted with `shared_preferences`. Existing `AppColors.x` call sites follow the active palette, so no screen is left light-on-dark. |
| **7.6** feedback was route-local | New `GET /api/history/attempts/:id` (owner-scoped) and `/feedback/:attemptId`, which re-fetches score/pass/feedback — a restart or deep link now lands on real feedback instead of the empty state. |
| **Seeds** | `69_approve_seeded_tasks.sql` and `70_demo_activity.sql` (demo users/attempts) removed; `71_admin_seed.sql` renumbered to `69_admin_seed.sql` so the pipeline no longer writes demo activity or approvals to a production database. |

### Round 1 — integrity, correctness, first load

Verified after that round: **backend `npm test` → 186 passed, 0 failed**; **`flutter analyze` → no issues**; **`flutter test` → 46 passed, 0 failed**.

### Integrity & correctness

| Finding | Fix |
|---|---|
| **2.1** any learner could finalise a capstone | `.../attempts/:id/mark` is now `requireAdminAuth` + `requireRole('moderator')`; the marker identity is taken from the admin token, never the body; the assessment lookup no longer requires the marker to share the learner's track. A regression test asserts a learner gets **403**. `ai-mark` stays learner-accessible (it is a suggestion) but is now scoped to the caller's own attempt. |
| **2.2** first attempt lost its readiness | `refreshReadiness` is an `INSERT … ON CONFLICT (user_id) DO UPDATE`, and `auth/sync` (+ `auth/me`) create the progress row on first sign-in. |
| **2.3** admin XP grant never recomputed level | `grantAdjust` calls `awardXp(…, { advanceStreak: false })`, so level and level-tokens follow the balance and the grant does not fake a streak. |
| **2.4** two deletion paths | New `services/accountPurge.js`: delete the row (cascade), then the Firebase identity, logging a survived identity instead of failing after the PII is gone. Used by self-delete and the admin hard delete. |
| **2.5** capstone submit race | `SELECT … FOR UPDATE` + re-check inside the transaction, for both submit and mark. |
| **2.6** assistant session race | `INSERT … ON CONFLICT (user_id, task_id) DO UPDATE … RETURNING id`. |
| **3.1** verification passable without a fix | `line_text` needs ≥ 70 **and** a non-zero flaw score **and** a non-zero fix score; choice tasks keep the flat threshold. Unit-tested. |
| **3.2** readiness renormalised over present data | Denominator is the weight of the components the **track offers**, so an untouched module counts as zero coverage, an empty module is excluded, and readiness can only rise as evidence arrives. Tested. |
| **3.3** duplicate XP/streak logic | `tasksController.updateProgress` deleted; `awardXp` is the only path and now also accepts a zero-XP graded attempt (streak only). |
| **3.4** client level curve | `/api/dashboard` returns `xp_into_level` / `xp_for_next_level`; the `_xpForLevel` copy in `progress_screen` is gone. |
| **3.5** achievements counted practice | Correction: the query already filtered `practice = FALSE` — the defect was the misleading `attempts` alias. Renamed to `passed_tasks`. |
| **3.7** future-dated wellness entries | Writes are clamped to `today ≥ date ≥ today − 365d`, with "today" resolved in `STREAK_TIMEZONE`. |
| **3.8** journal purge on every read | Moved to `scripts/purge-wellness-trash.js` (`npm run wellness:purge`); `GET /wellness/journal` is read-only again. |
| **3.9** hardcoded analytics timezone | Admin analytics interpolate `STREAK_TIMEZONE` (validated) instead of `'Africa/Johannesburg'` ×11. |
| **3.10** import capped at 32 kB | `/api/admin/tasks` gets a 2 MB body parser. |
| **3.11** duplicate history endpoints | `GET /api/tasks/history` and its controller removed; `/api/history` is the single timeline. |
| **5.8** SSE had no keep-alive | `openStream` sends a `: ping` comment every 15 s, unrefs the timer, and `sendEvent`/`endStream` no-op on a closed socket. |
| **6.3** route logging in release | `debugLogDiagnostics: kDebugMode`. |

### Performance & experience

| Finding | Fix |
|---|---|
| **6.1** dashboard made 5 requests and used 2 | New `GET /api/dashboard` composes profile + progress + dimension scores + one recommended task (reusing the existing selection logic) in one request, 3 queries + task selection. Home now renders all of it. |
| **6.2** all five tabs built eagerly | `MainNavShell` builds a tab on first visit; a test asserts the unvisited tabs are not in the tree. |
| **6.8** `mock_api_client.dart` "dead" | Correction: seven test files use it. Moved to `test/support/` instead of deleted. |
| **6.9** unused design-system widgets | Deleted `StreakBadge`, `PrefRow`, `DimensionBar`, `SampleDataBanner`, `VerifAICard`. Adopted `XPBar`, `DimensionIndexCard`, `DailyTaskCard`, `VerifAIButton` on Home. |
| **7.1** Home had no next action | Home now leads with the recommended task (or an empty-state CTA), the XP bar, streak/completed tiles and the dimension index. |
| **7.2** navigation tripled | The hamburger is no longer in the leading slot of any tab; the bottom dock is the primary navigation and the drawer opens from a low-emphasis action on Home only. |
| **7.3** touch targets | Bottom-nav items are `InkWell`s with a 48 dp minimum, a ripple and `Semantics(button, selected)`. Home's stat tiles and cards announce one combined label each; there are widget tests for the semantics label. |
| **7.4** fixed-height grid overflow | Home's explore grid uses `mainAxisExtent` with wrapping/ellipsised labels instead of `childAspectRatio`; captions moved from 9.5–11 px to 11–12.5 px. |
| **7.9** inconsistent error handling | All 12 direct `showSnackBar` call sites (6 files) now use the shared `showFeedback` banner; `FeedbackOverlay` is mounted once in `MaterialApp.builder`, so nothing renders a raw Material snackbar anymore. |

### Round 3 — remaining audit items

| Finding | Fix |
|---|---|
| **2.7** document parsing on the request thread | `services/documentParser.js` is a small pool of forked children (pdf.js cannot initialise inside a worker thread) with a queue limit, a 20 s timeout and a hard kill on timeout; `extract.js` caps decoded bytes at 5 MB **before** parsing, stops after 40 PDF pages, and the route body limit dropped from 14 MB to 8 MB. `extractDocument` now reports `pages`/`truncated`. |
| **5.3** ~12 round trips on a submission | The attempt and its `answer_logs` row are written in one CTE; the progress row and streak day-gap come back from one statement; readiness inputs are one JSON-aggregate statement plus a cached per-track interview total, and the recompute is skipped when coverage did not move; achievements are checked and inserted in one statement; token grants are batched into one `UNNEST` insert. |
| **6.5** providers had no lifetime | `core/services/resume_refresh.dart` invalidates the learner's data providers when the app returns to the foreground, throttled to once every 30 s. |
| **6.6** duplicated auth headers | `AuthInterceptor` now attaches the ID token in `onRequest` (with a `skip_auth` opt-out); every manual `_authHeaders`/`_idToken` use is gone and the helpers deleted, so each call behaves the same on a 401. |
| **7.3** touch targets and semantics | Remaining `GestureDetector` actions (daily task card, profile photo, profile stat tiles) became `InkWell` + `Semantics`; mood tiles carry a 64 dp minimum; the widget suite pins the five dock tabs. |
| **7.4** text scale | The micro-label floor is now 11.5 px across the app, the wellness mood grid is a `Wrap` with content-height tiles (the fixed `childAspectRatio` clipped at scale), and shell pages pad their bottom from the real dock height + safe-area inset. A widget test pumps Home/Learn/Practice at **200% text scale** and asserts no overflow. |
| **7.7** action looked frozen | Starting a capstone shows a spinner and "Starting…" while the attempt is created; scenario submit has a haptic and a busy button. |
| **7.8** wellness dates from the device clock | The server files an omitted date against `STREAK_TIMEZONE`'s day (not UTC `CURRENT_DATE`), returns `today` on both reads, and the client derives `isToday`/`_today` from that value; saves omit the date entirely. Backend test asserts the configured day is used. |
| **7.11** polish | Dashboard shows a "Updated just now / N minutes ago" hint; the app bar already leads with a greeting + track; dock clearance is computed (`shared/widgets/dock_clearance.dart`) instead of a hardcoded 100; option selection and submit have haptics. |
| **§4** duplication | `middleware/requireUser.js` resolves the user once per request for seven routers (49 controller-level copies deleted); `findUserByFirebaseUid` is the single lookup (now also used by tasks, interview, assistant and admin self-checks); `createTask` is a 10-line wrapper over `validateTaskBody` + `insertTask`; `/api/history` and `/api/progress/me/activity` read one `user_activity` view (migration 028 + `schema.sql`). |

### Still open

- **3.6** the streak rule is documented in `awardXp` but still counts any graded attempt rather than only passes; the product decision is yours.
- **5.9** admin CSV exports still build the whole file in memory.
- **§8** no Postgres integration suite; `mobile/android/app/google-services.json` is still tracked; `/api/docs` is still a hand-maintained list (the README is now accurate).
- **Reward images** remain unimplemented (`image_asset` is ignored by the catalogue), as agreed for this round.

---

## 1. Executive summary

The codebase is in far better shape than most student projects of this size: modular controllers, real migrations, defensive validation, rate limiting, an audit log, GDPR tooling, and a genuinely good test count. The problems below are mostly **not "it's broken"** — they are **"it's right at the edge of what it can carry"**, plus a handful of real correctness/security holes.

**The five things I would fix before anything else:**

| # | Finding | Impact |
|---|---|---|
| 1 | Any signed-in learner can finalise *any* capstone attempt and award themselves XP/tokens/readiness | Integrity + security hole |
| 2 | A brand-new learner's first scored attempt silently loses its readiness/tier update | Every new user's score is wrong until their 2nd task |
| 3 | Admin XP grants never recompute `level` | XP and level permanently desync |
| 4 | Account deletion removes the Firebase identity *before* the DB row | Half-deleted accounts, orphaned PII, GDPR gap |
| 5 | The app makes ~10 API calls on open; 3 are for task data the dashboard never renders | Slow cold start, wasted DB work, and the daily-task CTA is missing from Home |

---

## 2. Critical — correctness & security

### 2.1 Any learner can mark (and self-award) a capstone attempt
[routes/lab.js:38](backend/routes/lab.js#L38) · [controllers/labController.js:802](backend/controllers/labController.js#L802)

```js
router.post('/assessments/:code/attempts/:id/mark', verifyFirebaseToken, writeLimit, markCapstone);
```

`markCapstone` is the **reviewer** endpoint, but it only checks that the caller is *a* user. It does not check:
- that the caller is an admin/moderator, and
- that the attempt belongs to the caller.

Worse, the marker identity is taken from the request:
`const markedBy = req.body.marked_by ... || 'reviewer'`.

So a learner can open their own `pending_marking` attempt and POST `{ marks: { "<qid>": <full marks> } }`, which runs `applyCapstoneRewards` → XP, reward tokens, achievement, and a `refreshReadiness` bump. That is a directly exploitable path to "Advanced" tier.

**Fix:** move the route behind `requireAdminAuth` + `requireRole('moderator')` (or a separate `/api/admin/lab/...` router), and derive `marked_by` from the authenticated admin, not the body. `aiMarkCapstone` should get the same gate (it is only a suggestion, but it costs an LLM call per anonymous request).

### 2.2 First scored attempt drops the readiness/tier write
[tasksController.js:364](backend/controllers/tasksController.js#L364) vs [:568](backend/controllers/tasksController.js#L568) · [readinessService.js:70](backend/services/readinessService.js#L70)

```js
await refreshReadiness(client, user.id, user.industry_track_id);   // UPDATE user_progress ...
if (!practice || xpEarned > 0) progress = await updateProgress(...); // INSERT user_progress
```

`refreshReadiness` issues a plain `UPDATE user_progress SET readiness_score, tier WHERE user_id = $3`. Nothing creates the `user_progress` row except `updateProgress` / `awardXp` / the admin grant tool — `POST /api/auth/sync` does **not**. For a user's very first attempt the UPDATE matches 0 rows, the readiness is discarded, and `updateProgress` then inserts the row with `readiness_score = 0, tier = 'Novice'`.

Observed consequence: after completing your first task with 100% on that skill, the dashboard still shows **0 readiness / Novice** until the second attempt.

The same hole affects `interviewController.markPracticed` (interview-only users can never move readiness) and any capstone whose `xp_reward` is 0.

**Fix (smallest):** make `refreshReadiness` an upsert:

```sql
INSERT INTO user_progress (user_id, readiness_score, tier)
VALUES ($1, $2, $3)
ON CONFLICT (user_id) DO UPDATE
SET readiness_score = EXCLUDED.readiness_score, tier = EXCLUDED.tier;
```

and create the progress row in `syncUser` so every learner has one from day one.

### 2.3 Admin XP grants don't recompute level
[adminController.js:1278](backend/controllers/adminController.js#L1278)

```sql
UPDATE user_progress SET xp = xp + $1, updated_at = CURRENT_TIMESTAMP
WHERE user_id = $2 RETURNING xp, level
```

`level` is returned but never recalculated (`calculateLevel` is not called), and `grantTokens`/`levelGrants` are skipped. An admin granting +5,000 XP leaves the learner at level 1 with 5,000 XP. The progress screen then renders a full XP bar at level 1 forever.

**Fix:** reuse `awardXp()` ([services/xpService.js](backend/services/xpService.js)) — it already does insert-or-update, level recompute, level tokens and streak. Only the token path needs the separate `adjustment` ledger entry.

### 2.4 Two inconsistent account-deletion paths
[usersController.js:147](backend/controllers/usersController.js#L147) (self-delete) vs [adminController.js:1369](backend/controllers/adminController.js#L1369) (admin hard delete)

- Self-delete calls `getFirebaseAuth().deleteUser(uid)` **first**, then deletes the DB row. If the DB delete fails, the identity is gone but the PII remains — and the user can no longer sign in to trigger a retry.
- Admin hard-delete deletes the DB row **only**; the Firebase identity survives, so the person can sign in again and silently get a fresh empty account.

**Fix:** delete the DB row first (in a transaction, after recording the moderation event), then attempt the Firebase delete and log/inspect failures; make both paths call one shared `purgeAccount()` helper.

### 2.5 Capstone submit is not idempotent under concurrency
[labController.js:643](backend/controllers/labController.js#L643)

`submitted_at` is read with `pool` (no lock), then rewards are applied inside a later transaction. Two concurrent submits of the same attempt can both pass the `if (attempt.submitted_at)` guard and both call `applyCapstoneRewards`. The `reward_token_events` ledger is idempotent, but `awardXp` (XP balance + streak) is not.

**Fix:** `SELECT ... FOR UPDATE` inside the transaction and re-check `submitted_at` there, or `UPDATE ... WHERE submitted_at IS NULL RETURNING id` and bail when 0 rows are returned.

### 2.6 Assistant session creation has a first-message race
[assistantController.js:16](backend/controllers/assistantController.js#L16)

`getOrCreateSession` does SELECT → INSERT with `UNIQUE (user_id, task_id)`. Two simultaneous first messages (double tap, retry) raise `23505` and surface as a 500. The codebase elsewhere handles exactly this (`authController.syncUser`). Use `INSERT ... ON CONFLICT (user_id, task_id) DO UPDATE SET last_active_at = now() RETURNING id`.

### 2.7 `verification/analyze` parses 10 MB documents on the request thread
[app.js:81](backend/app.js#L81) · [services/extract.js](backend/services/extract.js)

A 14 MB JSON body is accepted so a 10 MB PDF/DOCX can be base64-decoded. `pdf-parse`/`mammoth` are CPU-bound and run in-process, blocking the event loop for the whole duration — with one Render instance that is a denial-of-service vector (and a memory spike). The body limit is also the only defence: there is no page/char cap on what the parser reads before `MAX_TOTAL_CHARS` truncation.

**Fix:** cap the decoded byte size *before* parsing, stream/parse in a worker thread or child process (or a queue), and lower the ceiling to something a phone camera/PDF realistically needs.

---

## 3. High-severity logic flaws

### 3.1 Verification can be passed without fixing anything
[tasksController.js:24](backend/controllers/tasksController.js#L24) · [scoringService.js](backend/services/scoringService.js)

`line_text` scoring is flaw 30 + fix 40 + reason 30. `PASS_THRESHOLD.verification = 60`. Selecting the flawed lines correctly (30) and writing a plausible reason (30) passes the task with **no fix at all** — the fix is the actual skill being tested. The same threshold is used for `choice` tasks where one option is worth 100, so the numeric meaning is inconsistent across formats.

**Fix:** per-format thresholds (`line_text` ≥ 70 *and* `fixScore > 0`), or make the fix gate pass/fail.

### 3.2 Readiness renormalises over whatever exists → 100% from one module
[readinessService.js](backend/services/readinessService.js)

```js
const sumWeight = parts.reduce((s, p) => s + p.weight, 0);
value = Σ(weight × score) / sumWeight;
```

The intent ("never penalise an unreached component") is reasonable, but the effect is that a learner who completes only the 4 Verification tasks in their track gets `Verification = 100`, weight 0.3 → renormalised readiness **100 / Advanced**. It also means `Prompt Design` (0.1 weight, not implemented on the backend) can never contribute, and readiness *drops* when a second dimension starts at a low score — which is demoralising and looks like a bug to users.

**Fix:** divide by the *total* weight (0.9 with Prompt Design removed) rather than the present weight, so coverage genuinely matters; or show readiness as "of assessed skills" with the denominator surfaced in the UI.

### 3.3 XP/streak logic exists twice, with different behaviour
[tasksController.js:568 `updateProgress`](backend/controllers/tasksController.js#L568) vs [services/xpService.js:8 `awardXp`](backend/services/xpService.js#L8), and the streak maths is **inlined** in `updateProgress` while a `services/streak.js` implementation of the same thing sits unused by it (it is used only by `awardXp`).

They already differ: `awardXp` returns early for `amount === 0`, always advances the streak and recomputes the level from the granted amount; `updateProgress` takes a precomputed XP delta and re-derives the streak inline with a second query. Any future change to levelling or streak rules must be made in three places.

**Fix:** delete `updateProgress`; call `awardXp` with the earned delta and layer the readiness/tier read on top.

### 3.4 Client re-implements the server's level curve
[progress_screen.dart:368](mobile/lib/features/progress/presentation/progress_screen.dart#L368)

```dart
int _xpForLevel(int level) {
  final k = level - 1;
  return 250 * k + 30 * k * (k - 1);
}
```

Identical to `scoringService.xpForLevel`. The API already returns `next_level_xp` on the rewards wallet — expose the same on `/progress/me` and delete the client copy. Otherwise a tuning change silently makes the progress bar wrong.

### 3.5 Achievements count practice passes; "attempts" means "passed tasks"
[tasksController.js:626](backend/controllers/tasksController.js#L616)

```sql
COUNT(DISTINCT task_id) FILTER (WHERE passed) AS attempts
```

`practice` is not filtered, so repeatedly practising a task you failed can unlock `five-tasks`/`ten-tasks` without ever passing a real attempt. The field name (`attempts`) also misdescribes the value. Decide the rule explicitly and encode it in one place.

### 3.6 Streaks advance on practice and on failures
`updateProgress` sets `last_activity_date = today` for any attempt that produced XP (including practice passes), while a *failed* non-practice attempt earns 0 XP but still runs `updateProgress` (because `!practice`), so it also advances the streak. Meanwhile a practice *failure* doesn't. That's an arbitrary line. Pick one definition ("any graded attempt" or "any pass") and document it; the UI copy "Streak Active" implies the latter.

### 3.7 Future-dated wellness entries
[wellnessController.js](backend/controllers/wellnessController.js) accepts a client-supplied `date` for mood and journal with only a `YYYY-MM-DD` shape check. A learner can backfill arbitrary future dates, producing impossible streaks/"days journalled". Clamp to `date <= CURRENT_DATE` (and to a sensible lookback, e.g. 365 days).

### 3.8 The journal purge runs on every read
[wellnessController.js:94](backend/controllers/wellnessController.js#L94) — `listJournal` issues a `DELETE ... WHERE deleted_at < now() - 30 days` before every SELECT. It's a write on a GET path, it runs on every journal open, and the only index is partial on `deleted_at IS NULL`, so the purge itself is a scan. Use a scheduled job (or a lightweight `pg_cron`) instead.

### 3.9 Analytics timezone is hardcoded in one place
`adminController` uses `'Africa/Johannesburg'` literally in **11** predicates while the rest of the app reads `STREAK_TIMEZONE`. If the deployment ever changes timezone, admin stats and learner stats disagree. Import `STREAK_TIMEZONE` from `services/streak.js`.

### 3.10 Import and task creation will 413 before they get big
[app.js:82](backend/app.js#L82) — the global JSON parser is `32kb`; only avatar and verification have larger path-scoped parsers. `POST /api/admin/tasks/import` explicitly allows **200 tasks** in one body ([adminController.js:876](backend/controllers/adminController.js#L877)), but two or three realistic tasks (scenario + 5 options + feedback) already exceed 32 kb. The import feature is effectively capped at 1–2 tasks and fails with an opaque 413.

**Fix:** add `express.json({ limit: '2mb' })` for `/api/admin/tasks` (and document the real limit), or make the importer accept NDJSON/one task per request.

### 3.11 `getHistory` exists twice with different contracts
[tasksController.js:704](backend/controllers/tasksController.js#L672) (`GET /api/tasks/history` → `{ attempts, total, limit, offset }`) and [historyController.js](backend/controllers/historyController.js) (`GET /api/history` → `{ entries }`). The mobile client only calls the second. The first is dead code that still has to be maintained and tested, and its aggregation is duplicated a **third** time in `progressController.getActivityHistory`. Consolidate on one timeline endpoint with `?type=`.

---

## 4. Duplicated logic inventory

| Duplication | Where | Suggested consolidation |
|---|---|---|
| Full task creation + insert (~110 lines, twice) | [`createTask` adminController.js:199](backend/controllers/adminController.js#L199), [`insertTask` :964](backend/controllers/adminController.js#L964), plus [`validateTaskBody` :929](backend/controllers/adminController.js#L929) | Keep `validateTaskBody` + `insertTask`; make `createTask` a 10-line wrapper. Today three paths validate the same body slightly differently. |
| `requireUser(res, req)` | 6 controllers: lab, rewards, workshop, vera, wellness, industryPractice | One `middleware/requireUser.js` that attaches `req.user`. Also removes one user query per request. |
| User lookup by uid (21 inline `WHERE firebase_uid = $1`) | nearly every controller | `findUserByFirebaseUid` already exists in [db/users.js](backend/db/users.js) — use it (or the middleware above). |
| Streak maths | `tasksController.updateProgress`, `services/streak.js`, `xpService` | `services/streak.js` only. |
| XP → level → tokens | `updateProgress`, `awardXp`, `adminController.grantAdjust` | `awardXp` only. |
| Insights aggregation over the 3 activity tables | `/api/history`, `/api/tasks/history`, `/api/progress/me/activity` | One SQL view (`user_activity`) the three endpoints select from. |
| Level curve | backend `xpForLevel`, Flutter `_xpForLevel`, `next_level_xp` | Return it from the API. |
| Level/tier constant tables | `services/tiers.js`, `user_progress` CHECK constraint, Flutter labels | Keep `tiers.js` as the source; generate the CHECK from it. |

---

## 5. Scalability & performance — backend

**5.1 The service is single-instance by design.** `express-rate-limit` uses the default in-memory store ([app.js:126](backend/app.js#L125)), `adminRoles.configCache` is a module-level variable, and `veraController.compactionInFlight` is a module-level `Set`. With two Render instances a user gets 2× the AI budget, maintenance mode flips per-instance for up to 5 s, and the same Vera session can be compacted twice concurrently. Use a shared store (Postgres or Redis) for the limiter and an advisory lock (`pg_try_advisory_lock`) for compaction, or accept and document the single-instance constraint.

**5.2 Every authenticated request costs 2–3 extra queries.** `verifyFirebaseToken` runs `SELECT status FROM users WHERE firebase_uid = $1` ([middleware/auth.js:37](backend/middleware/auth.js#L37)); `requireRole` runs another for admin routes; the token is then verified against Firebase (a network call, though the SDK caches keys). Health checks are correctly exempt, but the moderation lookup could be cached for 30–60 s (bounded staleness for suspensions is fine) — or folded into the same query that controllers run anyway.

**5.3 The scored-attempt hot path is ~12 round trips.**
`submitAttempt` → user lookup, task select, task content, options, attempt insert, answer_log insert, `updateSkillScore` (4 correlated subqueries), `refreshReadiness` (up to 4 sequential queries — the interview `total` and `practised` round-trips are **serial**, not parallel), `updateProgress` (insert + date query + update), `grantTokens` (N inserts), `awardAchievements` (3 queries + N inserts). It's all inside one transaction, so it holds a pooled connection for the duration; with `DB_POOL_MAX=10` that caps throughput at ~10 concurrent submissions.

Quick wins: run the readiness sub-queries in one statement (or `Promise.all` within the same client — safe), compute `interview total` once per track (cache), and only recompute readiness when a skill or capstone actually changed. Longer term, move the readiness/achievement recompute to an outbox/queue and return the optimistic result immediately.

**5.4 Analytics queries are not sargable.** [adminController.js](backend/controllers/adminController.js) has 11 predicates of the form

```sql
(ta.submitted_at AT TIME ZONE 'Africa/Johannesburg')::date = CURRENT_DATE - d.day
```

computed per row, joined against a `generate_series` of 30 days → 30 sequential scans of `task_attempts` per dashboard load. Likewise `date_trunc('week', u.created_at)` for signups and five separate `COUNT(*)` subqueries for the funnel. At 10k users each analytics page is seconds, and the admin UI loads several such endpoints (`/overview`, `/analytics`, `/track-progress`).

**Fix:** add a `submitted_date DATE GENERATED ALWAYS AS ((submitted_at AT TIME ZONE 'Africa/Johannesburg')::date) STORED` column (or a plain column written by the app) with an index, then group on it. Cache the analytics payload for 60 s — nobody needs second-level freshness on a weekly-signups chart.

**5.5 Leaderboard is O(users) on every view.** `ROW_NUMBER() OVER (ORDER BY xp ...)` over a full `users LEFT JOIN user_progress` scan, every request, with no cache. At 50k users that is a sort of 50k rows per app open. Materialise a `leaderboard_cache` table refreshed every N minutes (or a `RANK()`-friendly keyset page query with a covering index on `(xp DESC, readiness_score DESC, user_id)`).

**5.6 Missing/weak indexes.**
- `task_attempts`: `(user_id, submitted_at DESC)` exists — good. But history/activity aggregations filter `practice = FALSE` and sort by `submitted_at` across a `UNION`; a partial index `(user_id, submitted_at DESC) WHERE practice = FALSE` helps.
- `lab_activity_attempts`: index is `(user_id, activity_id)`; the history and wellness queries order by `submitted_at`, which is unindexed.
- `user_progress`: no index on `(xp DESC, readiness_score DESC)` for the leaderboard.
- `answer_logs`: fine.
- `users.status`: not indexed, but the auth lookup uses the unique `firebase_uid`, so this is fine.

**5.7 Static content is queried on every render.** `GET /api/tracks`, `/api/lab/lessons`, `/api/lab/sources`, `/api/rewards` hit Postgres every time and change rarely. Add `ETag`/`Cache-Control` or a 60 s in-process TTL cache (the `getConfig` pattern already exists to copy).

**5.8 Streaming has no keep-alive and no disconnect handling.** [middleware/sse.js](backend/middleware/sse.js) writes only when the model produces a chunk. With `firstTokenTimeoutMs` of 30 s and reasoning models, there can be long silent gaps — Render/proxies close idle connections. Send a `: ping\n\n` comment every ~15 s, and stop writing (and abort the upstream request) on `req.on('close')`; currently `sendEvent` keeps writing to a dead socket.

**5.9 Pagination is missing on admin lists.** `listTasks` is hard-capped at 500, `listAnswers` at 500/offset, exports build the entire CSV in memory (`LIMIT 50000`). Add keyset pagination and stream CSV exports (`res.write` per row) before content grows.

**5.10 Body-size ceilings are inconsistent.** 32 kb global, 3 MB avatar, 14 MB verification. A workshop post is capped at 2,000 chars but a capstone answer (essay) is bounded only by the 32 kb body — worth making these deliberate per route rather than inherited.

---

## 6. Scalability & performance — mobile

**6.1 The dashboard makes 5 requests and uses 2.**
[dio_api_client.dart:80](mobile/lib/core/services/dio_api_client.dart#L80)

```dart
Future.wait([
  users/me, progress/me,
  tasks/next?feature=verification&difficulty=easy,
  tasks/next?...medium,
  tasks/next?...hard,
]);
```

The three `tasks/next` calls each run the "unseen task" query plus an option query (6+ queries server-side), and [dashboard_screen.dart](mobile/lib/features/dashboard/presentation/dashboard_screen.dart) never reads `data.dailyTask`/`data.tasks`/`data.currentXp`/`data.dimensionScores`. So the app pays for the most expensive part of the dashboard and throws it away — **and** the Home screen has no "next task" card at all.

**Fix:** one `GET /api/dashboard` endpoint returning profile + progress + a single recommended task; or at minimum drop the three calls and add the task card back.

**6.2 All five tabs build eagerly.** [main_nav_shell.dart:35](mobile/lib/features/navigation/main_nav_shell.dart#L35) creates `const [DashboardScreen(), TrackRoadmapScreen(), TaskScreen(), ProgressScreen(), ProfileScreen()]` and puts them in an `IndexedStack` (line 130). Every screen's providers resolve immediately: dashboard (5), achievements, leaderboard, adminIdentity, milestones, activity → **~10 requests before the user taps anything**, all competing for bandwidth on a cold start.

**Fix:** lazy-instantiate tabs (`IndexedStack` with `null` placeholders created on first visit) — a 10-line change with a large first-load win.

**6.3 `debugLogDiagnostics: true` ships in release.** [app_router.dart:89](mobile/lib/core/router/app_router.dart#L89) — route logs on every navigation. Gate on `kDebugMode`.

**6.4 No pagination anywhere.** History requests 30 and stops, leaderboard 20, lab lessons returns everything. There's no `ScrollController`/`loadMore` outside the two chat screens. Add keyset pagination (`offset` already exists on `/tasks/history` and `/workshop/posts`).

**6.5 Provider cache has no lifetime.** All providers are non-`autoDispose` globals, so progress/achievements/leaderboard stay stale until an explicit `invalidate`. There is no pull-to-refresh on 6 of the tab screens and no periodic refresh. Either move to `FutureProvider.autoDispose` with a keep-alive TTL, or add a global "refresh on resume" hook.

**6.6 Auth headers are applied twice or not at all.** `AuthInterceptor` already injects and refreshes the token, yet ~20 methods call `_idToken()` and pass `Authorization` manually (`getMe`/`getTracks` don't). The interceptor's retry only rewrites the header if one was present, so behaviour differs per endpoint. Standardise: always use the interceptor, delete `_authHeaders`.

**6.7 Fonts are downloaded at runtime.** [app_typography.dart](mobile/lib/core/theme/app_typography.dart) uses `GoogleFonts.interTextTheme()`/`manrope` with runtime fetching on. First paint uses a fallback font and then swaps (visible reflow), and typography depends on a network call. Bundle the two families in `pubspec.yaml` and set `GoogleFonts.config.allowRuntimeFetching = false`. *(Partially mitigated: the theme is now built once and cached instead of rebuilt on every style lookup. The network dependency remains — see §0.)*

**6.8 `mock_api_client.dart` (673 lines) is dead code in `lib/`.** Not referenced anywhere. Move to `test/` or delete.

**6.9 Unused design-system widgets.** `XpBar`, `StreakBadge`, `PrefRow`, `VerifaiButton`, `VerifaiInput`, `AppFeedbackBanner` have **zero** call sites outside `shared/widgets`. Screens hand-roll the same buttons/rows instead → visual drift and duplicated code. Either adopt them or delete them.

---

## 7. UI/UX — opportunities

These are the ones with the best effort/impact ratio.

**7.1 Home doesn't offer the next action.** The hero card is a passive score ring; streak and completed-task tiles are passive too. The core loop ("do a scenario") lives one tab away, and the daily-task data is already fetched and discarded. Add:
- a primary "Continue: Verification · Medium" card with a start button (and `is_repeat` surfaced as "Practice again"),
- XP-to-next-level progress (`XpBar` exists),
- the four dimension scores (`DimensionIndexCard` exists, used only on Progress),
- empty-state CTAs: "0 Tasks" → "Start your first task".

**7.2 Navigation is tripled.** A 13-link drawer + a 5-item floating pill + in-page buttons + several full-screen routes. `/scoreboard`, `/rewards`, `/task-history`, `/wellness` are routes while `Progress`/`Track` are tabs, so Back behaviour is inconsistent, and choosing a drawer link with `context.go()` (shell routes) rebuilds the shell and resets the current tab. Consider 5 tabs (Home · Learn · Practice · Progress · Profile), hubs inside each, and drop the drawer or make it secondary.

**7.3 Touch targets and semantics.** Bottom-nav items are `Icon(20) + vertical padding 8` ≈ **36 dp** tall (Material minimum is 48), and they are `GestureDetector`s (no ripple, no focus, no `InkWell`). Across the entire app there is **one** `Semantics(` call. Custom-drawn elements (score ring, bento cards, streak badge) need semantic labels; stat tiles should read "3 day streak" not "3 Days / Streak Active" as two nodes.

**7.4 Typography is too small in places and won't scale.** Labels at 9.5–11 px (dashboard chips, stat captions) are below comfortable mobile sizes. There are 38 hard-coded `height: 100–300` boxes and a `GridView` with `childAspectRatio: 1.45` around text — all of these overflow at the OS's largest text scale. Test at 200 % scale and prefer `IntrinsicHeight`/`Wrap`/`Flexible` over fixed heights.

**7.5 No dark mode, and 83 `Color(0x...)` literals outside the theme.** `AppTheme` only defines `lightTheme`; `wellness_center_screen.dart` hardcodes `0xFF18392F`. Move tokens into `ColorScheme`/`ThemeExtension` and add a `darkTheme` — it's mostly a mechanical change now and very expensive later.

**7.6 The feedback result is route-local.** `/feedback` receives the whole result via `state.extra`; a restart, deep link, or process death falls back to `FeedbackEmptyScreen` and the attempt's feedback is lost (it *is* on `/history`, but the user has no path to it). Persist the last attempt id and re-fetch, or route `/feedback/:attemptId`.

**7.7 The "Continue" action can feel frozen.** `_continueToNextTask` awaits `getNextTask` with no visual feedback, then `pushReplacement`. Show a busy state on the button (and use the same for Retry).

**7.8 Wellness dates come from the device clock.** `_today` is `DateTime.now()` local; the server stores `CURRENT_DATE` in UTC for mood/journal. Near midnight, or in a different timezone, "today's check-in" can fail to appear or overwrite yesterday. Send the ISO date (already done for save) and use it for reads too; display using the returned `date` field rather than `isToday`.

**7.9 Error handling is inconsistent.** 19 of 43 screens use `AsyncErrorView`/`classifyError`; the rest collapse failures into a `SnackBar` (12 call sites), sometimes with no retry. Pick one pattern: inline retry card for screen-level fetches, snackbar only for transient actions.

**7.10 Content discovery.** No search or filter in AI Lab (books → chapters → topics), Industry Practice, Workshop, or task history. `TextField` appears only inside assessment answering. A simple search over lessons/cases plus feature/difficulty filters on history would remove a lot of scrolling.

**7.11 Small polish with outsized perceived quality.**
- Dashboard refresh button *and* pull-to-refresh *and* tab re-entry all invalidate: show a "last updated" hint instead of a bare icon.
- "Home" + avatar + track name in the AppBar is three pieces of chrome for one line of content; consider a greeting ("Good evening, Thabo") with the track as a subtitle.
- The floating dock overlaps scrolling content — `padding: 100` is hardcoded in several screens; derive it from `MediaQuery.padding.bottom + dock height`.
- Haptics exist on tab changes; add them on option select/submit (cheap, high perceived quality).

---

## 8. Testing, observability & repo hygiene

- **182 backend tests pass** — a genuinely strong suite for this stage.
- But **all of them mock `pg`** (no test uses the real schema). The `embedded-postgres` dev dependency exists and is only used by `scripts/local-db.js`. Because of that, SQL-level defects (2.2 readiness upsert, 2.5 submit race, 3.1 thresholds vs real seed data, 5.4 non-sargable analytics) are invisible. Add one integration suite that runs `schema.sql` + migrations and exercises: sync → next task → submit → progress → readiness, capstone start/submit/mark, and wellness upsert.
- **15 Flutter test files** exist (auth interceptor, judgement screen, lab navigation, login flow…) — now plus a Home/shell test that pins the next-task card, the server-supplied XP numbers and lazy tab construction. *(Added in the fix round.)*
- **No auth/authorization tests at all.** A single test asserting "non-admin cannot POST /api/lab/assessments/:code/attempts/:id/mark" would have caught 2.1. *(That test now exists and passes.)*
- **Observability:** `request_id` is generated and returned — good — but it isn't logged alongside responses, there is no structured logger, no `/metrics`, and `console.error` is the only signal. `getMe` is one of several responses that omit `request_id`.
- **Repo hygiene:** `mobile/android/app/google-services.json` is **tracked** while README states Firebase config files are not committed (`git ls-files` confirms). It's not a secret, but it contradicts the docs and will trip the gitleaks job. `backend/.env` and `backend/firebase-service-account.json` are correctly ignored.
- **Docs drift:** `README.md` documents `backend/src/routes/...` but the code lives at `backend/routes/...`; `app.js` still serves a hardcoded endpoint list at `/api/docs` that has drifted from the real routes (it lists `/api/tasks/history` which the client doesn't use, and omits admin routes that exist). Consider generating `openapi.yaml` from the routers.

---

## 9. Suggested order of work

**Phase 1 — integrity (days)**
1. Gate `markCapstone` (and `aiMarkCapstone`) behind admin role + ownership. *(2.1)*
2. Make `refreshReadiness` an upsert; create `user_progress` on sync. *(2.2)*
3. Route admin XP grants through `awardXp`. *(2.3)*
4. Unify account deletion. *(2.4)*
5. Raise the admin body limit. *(3.10)*

**Phase 2 — correctness & consistency (1–2 weeks)**
6. Per-format pass thresholds. *(3.1)*
7. Readiness weighting decision + copy. *(3.2)*
8. Collapse `updateProgress` into `awardXp`; delete dead `/api/tasks/history`. *(3.3, 3.11, §4)*
9. Row-lock the capstone submit; `ON CONFLICT` the assistant session. *(2.5, 2.6)*
10. Clamp wellness dates; move the purge to a job. *(3.7, 3.8)*
11. Add an authorization test suite + one Postgres integration suite. *(§8)*

**Phase 3 — performance (2–3 weeks)**
12. Lazy tabs + single `/api/dashboard`. *(6.1, 6.2)*
13. Generation-column activity dates + analytics caching. *(5.4)*
14. Leaderboard materialisation. *(5.5)*
15. Shared rate-limit store, auth status cache, readiness off the request path. *(5.1–5.3)*
16. SSE heartbeat + client-disconnect abort. *(5.8)*
17. Bundle fonts; remove dead client code. *(6.7, 6.8, 6.9)*

**Phase 4 — experience (ongoing)**
18. Home "next action" card + XP bar + dimension summary. *(7.1)*
19. Navigation consolidation. *(7.2)*
20. Touch targets, semantics, text-scale audit. *(7.3, 7.4)*
21. Theme tokens + dark mode. *(7.5)*
22. Pagination + search. *(6.4, 7.10)*

---

## 10. What is already good (don't refactor these away)

- Consistent `{ data, request_id }` response envelopes and a real 404/error handler.
- `answer_logs` denormalisation so analytics never joins through attempts at query time.
- Idempotent token ledger with `UNIQUE (user_id, reason, ref)` — a genuinely correct design.
- Reward redemption locks the balance row (`FOR UPDATE`) before spending — correct.
- Path-scoped body limits, per-account rate limits with IPv6 masking, helmet + a scoped CSP for the admin SPA.
- Streaming LLM transport with first-token/idle timeouts, retry-on-fallback, and mid-stream error-frame handling — this is more robust than most production code.
- The `assembleContext` token-budget trimmer means a Vera chat can never overflow the model window.
- Session-scoped cache invalidation on sign-out ([app_router.dart](mobile/lib/core/router/app_router.dart)) — a shared-device data leak that most apps miss.
- Existing schema indexes for the hot read paths (attempts by user/date, lab content, workshop replies) are the right ones.
