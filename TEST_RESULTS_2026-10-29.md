# VerifAI — Deliverable 5: Test Results

**Run date:** 29 October 2026 (UTC)  
**Application:** [https://verif-ai-5a435.web.app/](https://verif-ai-5a435.web.app/)  
**API:** `https://verifai-2wnm.onrender.com`  
**Run by:** Buffy (Freebuff coding assistant), using a remote browser session and terminal. This is not a claim that the student team performed these tests.

## 1. Run conditions and limitations

- **Client/platform:** Flutter web deployment at the supplied URL. The embedded browser reported Windows (`Win32`) and Chromium `130.0.6723.191`; viewport reported as 1536 × 864. Exact Windows version and Flutter build/version were not available.
- **Observed app state:** The first visit was at `#/login`. After the user signed in, the same browser session showed `#/dashboard` with the signed-in learner’s IT / Software track, readiness 22 (Novice), one-day streak, nine completed tasks, and a recommended verification task. API requests for Firebase sign-in, account lookup, `/api/auth/sync`, `/api/users/me`, and `/api/dashboard` returned 200. I also directly opened the Progress route and visually inspected it; authenticated activity and leaderboard requests returned 200. I attempted to activate the dashboard’s “Start task” control using screenshot-derived coordinates and a canvas click target, but the route did not change and no task request was sent. The Flutter canvas remains inaccessible to browser automation input, so hub-button navigation and task execution could not be exercised.
- **API/database:** The deployed `/api/health` returned HTTP 200, `status: ok`, `db: connected`. The API identifies Firebase Authentication in the supplied test plan and repository documentation.
- **Local automated tests:** Backend command `npm test` ran from `backend/` under Node `v26.7.0`: **186 passed, 0 failed**. The test process logged that `DATABASE_URL` was unset and database-backed routes would not work; the suite uses mocks for relevant database/API behavior and is not a live-data persistence test. The installed runtime was Node 26, not the Node 22 version specified by the plan.
- **Flutter automated tests:** Not run: `flutter` is not installed in this environment (`command not found`).
- **Visual evidence:** Captured the signed-in Home dashboard at [test-evidence/dashboard-signed-in.png](test-evidence/dashboard-signed-in.png) and Progress at [test-evidence/progress-signed-in.png](test-evidence/progress-signed-in.png). The dashboard image has the display-name area blurred. These show real data for the current signed-in account; other test-case evidence has not been captured.
- **Status meanings:** Pass means the specific check was actually performed and met its expected result. Pending means not run or only partially observed; it is not a pass or a failure.

## 2. Test case results

### Authentication

| ID | Test | Actual result | Status | Evidence / notes |
|---|---|---|---|---|
| AUTH-01 | Sign in with valid learner credentials | User signed in successfully; after Firebase sign-in/account lookup, `/api/auth/sync` and `/api/users/me` returned HTTP 200 and the app opened `#/dashboard`. | Pass | Signed-in session and dashboard screenshot: [test-evidence/dashboard-signed-in.png](test-evidence/dashboard-signed-in.png). No credentials recorded. |
| AUTH-02 | Correct email, wrong password | Not run. | Pending | — |
| AUTH-03 | Unregistered email | Not run. | Pending | — |
| AUTH-04 | Both sign-in fields blank | Not run. | Pending | — |
| AUTH-05 | Malformed sign-in email | Not run. | Pending | — |
| AUTH-06 | Register a new account | Not run; registration flow was not operable in this session. | Pending | — |
| AUTH-07 | Existing email, short password, or mismatched confirmation | Not run. | Pending | — |
| AUTH-08 | Request password reset | Not run. | Pending | — |
| AUTH-09 | Sign out from Profile and check back navigation | Not run; requires an authenticated account. | Pending | — |
| AUTH-10 | Session persistence after closing/reopening | Not run; requires an authenticated account and app restart. | Pending | — |

### Onboarding and navigation

| ID | Test | Actual result | Status | Evidence / notes |
|---|---|---|---|---|
| ONB-01 | Step through or skip the welcome tour | Not run; app controls were not operable. | Pending | — |
| ONB-02 | Select and save an industry track | Not run; requires onboarding/account. | Pending | — |
| ONB-03 | Continue without selecting a track | Not run. | Pending | — |
| NAV-01 | Visit Home, Learn, Practice, Progress, and Profile | Not run; no hub controls available through the browser snapshot. | Pending | — |
| NAV-02 | Back navigation from a nested screen | Not run. | Pending | — |
| NAV-03 | Open a protected route while signed out | Not run in the client. | Pending | API authorization checks are recorded under API-02/03. |
| NAV-04 | Home dashboard for a lived-in account | Signed-in dashboard displayed IT / Software, readiness 22 (Novice), a one-day streak, nine completed tasks, and “The Working Query That’s Insecure” as the next task. Dashboard requests returned HTTP 200. | Pass | [test-evidence/dashboard-signed-in.png](test-evidence/dashboard-signed-in.png). |

### Learning and practice

| ID | Test | Actual result | Status | Evidence / notes |
|---|---|---|---|---|
| LRN-01 | Open Learn/AI Lab lesson and activity | Not run. | Pending | — |
| LRN-02 | Open Prompt Design limitation state | Not run in the UI. | Pending | The plan identifies authored Prompt Design content as a known limitation. |
| PRC-01 | View Practice skill areas | Not run. | Pending | — |
| PRC-02 | Open a scenario and inspect its full content | Not run. | Pending | — |
| PRC-03 | Submit a scenario and observe real score/feedback | Not run. An attempted “Start task” click did not reach the Flutter canvas; the app remained on the dashboard and no submission was made. | Pending | No attempt or score was invented. |
| PRC-04 | Review score, explanation, and next action | Not run. | Pending | — |
| PRC-05 | Complete an AI Judgement task | Not run. | Pending | — |
| PRC-06 | Complete a Risk and Governance task | Not run. | Pending | — |
| PRC-07 | Open tasks from each industry track | Not run. | Pending | — |

### Progress, history, and profile

| ID | Test | Actual result | Status | Evidence / notes |
|---|---|---|---|---|
| PRG-01 | Read progress after several attempts | Progress displayed level 6, 99 / 550 XP, one-day streak, nine completed tasks, seven-day practice activity, leaderboard rank 1, and readiness skill scores. Authenticated progress activity and leaderboard requests returned HTTP 200. | Pass | [test-evidence/progress-signed-in.png](test-evidence/progress-signed-in.png). |
| PRG-02 | Read progress for a new learner | Not run. | Pending | — |
| PRG-03 | Open a saved attempt from history | Not run. | Pending | — |
| PRG-04 | Confirm progress updates after a new task | Not run; no task was submitted. | Pending | — |
| PRO-01 | View profile and preferences | Not run. | Pending | — |
| PRO-02 | Update profile/preferences and verify persistence | Not run. | Pending | — |
| PRO-03 | Change industry track and verify it across the app | Not run. | Pending | — |

### Staff/admin access

| ID | Test | Actual result | Status | Evidence / notes |
|---|---|---|---|---|
| ADM-01 | Access portal as staff/admin | Not run; no staff account supplied. | Pending | — |
| ADM-02 | Attempt portal access as a learner and verify server denial | Not run; requires role-specific authenticated accounts. | Pending | — |
| ADM-03 | Perform an admin content action | Not run; no staff account supplied. | Pending | — |

### Backend and database integration

| ID | Test | Actual result | Status | Evidence / notes |
|---|---|---|---|---|
| API-01 | Call deployed API health endpoint | `GET /api/health` returned HTTP 200 JSON: `status: ok`, `db: connected`. | Pass | Live API request on 29 Oct 2026. |
| API-02 | Call protected endpoint without a token | `GET /api/users/me` returned HTTP 401 with a missing/malformed Authorization message. | Pass | Live API request; no account data returned. |
| API-03 | Call protected endpoint with an invalid token | `GET /api/users/me` with `Bearer invalid.test.token` returned HTTP 401, `Invalid or expired token.` | Pass | Live API request. |
| API-04 | Load tracks and dashboard data in the app | `GET /api/tracks` returned HTTP 200 with four tracks (Finance, Legal, IT / Software, Business Consulting). In the signed-in app, `/api/dashboard` returned HTTP 200 and its data appeared on the Home dashboard. A separate unauthenticated `GET /api/dashboard` returned HTTP 401. | Pass | Live API responses and [test-evidence/dashboard-signed-in.png](test-evidence/dashboard-signed-in.png). |
| API-05 | Submit a task and inspect its Supabase attempt row | Not run; no authenticated submission or database console access. | Pending | Automated backend suite uses mocks and does not prove deployed persistence. |
| API-06 | Compare attempt history for two accounts | Not run; no test accounts/history supplied. | Pending | — |

### Usability and UI feedback

| ID | Test | Actual result | Status | Evidence / notes |
|---|---|---|---|---|
| USE-01 | First-time tester completes a task unaided | Not run; no participant completed a task. | Pending | — |
| USE-02 | Tap primary buttons on each hub | Not run; controls were not available through the browser accessibility snapshot. | Pending | — |
| USE-03 | Observe success, validation, and network-error messages | Not run. | Pending | — |
| USE-04 | Observe loading state and double-submit prevention | Not run. | Pending | — |
| USE-05 | Check small, large, and web layouts | Web layouts were visually inspected at the captured 1600 × 1125 dashboard and progress viewport; small-phone and comparative large-screen checks were not run. | Pending | [Dashboard screenshot](test-evidence/dashboard-signed-in.png), [Progress screenshot](test-evidence/progress-signed-in.png). Multi-size requirement incomplete. |
| USE-06 | Rotate device during a task | Not run; no device/emulator. | Pending | — |
| USE-07 | Check text size, contrast, and key-screen wording | No formal readability, contrast, or wording assessment performed. | Pending | Rendered screens captured: [dashboard](test-evidence/dashboard-signed-in.png), [progress](test-evidence/progress-signed-in.png). |

### Edge cases and automated tests

| ID | Test | Actual result | Status | Evidence / notes |
|---|---|---|---|---|
| EDG-01 | Submit a task without an answer | Not run; no task submitted. | Pending | — |
| EDG-02 | Enter symbols and emoji | Not run. | Pending | — |
| EDG-03 | Enter SQL-style text | Not run against the running app. | Pending | Backend source suite is not a substitute for this manual case. |
| EDG-04 | Paste several thousand characters | Not run. | Pending | — |
| EDG-05 | Disable internet and submit/open app | Not run; airplane-mode/device network controls unavailable. | Pending | — |
| EDG-06 | Lose connection mid-submit | Not run. | Pending | — |
| EDG-07 | Double-submit a task | Not run. | Pending | — |
| EDG-08 | Interrupt a task by backing out/backgrounding | Not run. | Pending | — |
| EDG-09 | Act after session expiry | Not run; requires an authenticated session and expiry wait. | Pending | — |
| EDG-10 | Re-run backend and Flutter automated suites | Backend: `npm test` completed with 186 passed, 0 failed. Flutter: not run because Flutter is unavailable. | Pending | The requested combined result is incomplete. Backend run used Node v26.7.0; local `DATABASE_URL` was unset. |

### Additional features and security checks

| ID | Test | Actual result | Status | Evidence / notes |
|---|---|---|---|---|
| EXT-01 | Registration validation cases | Not run. | Pending | — |
| EXT-02 | Google sign-in and cancellation | Not run; no Google account/session interaction. | Pending | — |
| EXT-03 | Delete a throwaway account | Not run; no throwaway account supplied. | Pending | No account/data was deleted. |
| EXT-04 | Verification Studio text analysis | Not run through the app. | Pending | — |
| EXT-05 | Verification Studio PDF/DOCX upload size limits | Not run. | Pending | — |
| EXT-06 | AI Lab capstone timer, marking, and attempt limit | Not run. | Pending | — |
| EXT-07 | Mark an interview question practised twice | Not run. | Pending | — |
| EXT-08 | Open an industry case and verify read state | Not run. | Pending | — |
| EXT-09 | Redeem a reward with insufficient/sufficient tokens | Not run. | Pending | — |
| EXT-10 | Open global and per-track leaderboard | Not run in the app. | Pending | — |
| EXT-11 | Switch themes and test maximum OS text size | Not run; no UI interaction/device accessibility settings. | Pending | — |
| EXT-12 | Ask Vera a question and observe reply/error | Not run in the app. | Pending | — |
| EXT-13 | Save and reopen a wellness entry | Not run. | Pending | — |
| EXT-14 | Observe API cold-start behavior | The live `/api/health` responded successfully; no timing baseline or first user action was measured. | Pending | No performance conclusion drawn. |
| EXT-15 | Check task response for answer-key leakage | Not run with an authenticated task request. | Pending | — |
| EXT-16 | Unknown API route and invalid profile track | Unknown route check: `GET /api/this-route-does-not-exist` returned HTTP 404 JSON `Route not found`. Invalid profile-track update was not run. | Pending | Partial check only. |
| EXT-17 | Exercise rate limiting | Not run; no burst/load request was sent. | Pending | — |

## 3. Automated test run details

Command: `npm test` (from `backend/`)  
Result: **186 tests, 186 passed, 0 failed, 0 skipped**.  
Duration reported by Node test runner: approximately 23.8 seconds.  
Environment note: `DATABASE_URL is not set` appeared during the run; tests provide mocked database behavior. This is evidence for the backend automated suite only, not proof of live Supabase persistence or the deployed app’s complete behavior.

The app was also checked via live HTTP requests to the deployed API. Observed checks and response codes are recorded in API-01 through API-04 and EXT-16 above. API health was also requested by the web app during startup and returned HTTP 200.

## 4. Bug log

No reproducible application defect was confirmed during the checks that could be completed. This does **not** establish that the app has no defects: 69 of 76 plan cases remain pending or partially checked, including most authenticated UI flows, task submission, and device-specific cases. No production data was changed and no account was created or deleted.

## 5. Summary

| Measure | Result |
|---|---:|
| Total test cases in the supplied plan | 76 |
| Pass | 7 |
| Fail (fixed and retested) | 0 |
| Fail (open) | 0 |
| Pending / partially checked | 69 |
| Not implemented / not applicable | Not determined by this run |
| Crashes observed during completed checks | 0 observed; full app crash-free run not completed |

**Findings.** The deployed API health endpoint reported a healthy service and connected database. Valid sign-in reached the dashboard, authenticated profile/dashboard/progress activity/leaderboard calls succeeded, missing and invalid tokens were rejected, and the Home and Progress screens displayed the learner’s current data. The local backend automated suite passed 186/186, but it uses database mocks; task submission/persistence, most authenticated feature flows, and the Flutter test suite remain unverified.

**Known limitations and next steps.** The signed-in dashboard and Progress screens are captured. Browser automation could not reliably interact with the Flutter canvas, so task flows, hub button navigation, profile editing, and sign-out were not tested; loading routes directly does not establish button navigation. Complete the pending cases using interactive controls on a usable web/mobile client; run `flutter test` in a Flutter-enabled environment; inspect persistence in Supabase; and capture evidence for the remaining cases. The plan’s known Prompt Design content limitation and lack of offline mode were not independently confirmed in this run.

## 6. AI disclosure

**Tool used:** Buffy (Freebuff coding assistant).  
**Purpose:** Extract the supplied test requirements, run available live API checks and the repository’s backend test command, and organize observed results into this report.  
**Verification/adaptation:** Actual results above come only from observed HTTP responses, the reported backend test-run output, or are explicitly marked Pending. Expected outcomes were not copied into the Actual result column. No unavailable UI result, score, account action, screenshot, or persistence observation has been represented as completed.
