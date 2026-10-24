# VerifAI — Sprint 2 Backend

Response to the first QA round. This file covers **backend work only** and pairs
with `SPRINT2_FRONTEND.md`. Together they answer every finding in the QA report,
including the items that are really navigation/UX (the backend half is the data,
contract and correctness work those screens depend on).

**Priority key** — **P0** = QA "High" / blocks a core workflow, **P1** = QA
"Medium" / a shipped surface is confusing or uncompensated, **P2** = polish.
**Effort key** — S = 1, M = 2, L = 3, XL = 5 points (roughly half a day per
point for one developer, including tests).

**QA traceability** — every numbered finding in the report is mapped to a task in
the table at the end of this file. QA item 9 (verification) is the largest single
piece of work and the only finding that is a genuine functional defect rather
than a usability gap.

---

## Workload — this file is one workstream

| Workstream | Section | Owner | Tasks | Points |
|---|---|---|---|---|
| **A — Backend Fix** | Part A | Backend dev 1 | 9 | 23 |
| **B — Backend Build** | Part B | Backend dev 2 | 10 | 23 |

The frontend file carries the other two workstreams (C = 23, D = 23). All four
buckets are exactly 23 points, so the group split is even and each person owns a
complete vertical slice of the response, including the roadmap redesign.

A and B are deliberately independent after **day 1**: B's support-content API
is read-only and seeded, A never edits support content. The only shared surface
is the contract in the next section, which is frozen before either side starts.

---

## Contract freeze — do this on day 1

The frontend builds against these shapes with fixtures while the endpoints are
in progress. Changing them later costs both teams a day.

### 1. Verification report v2 (`POST /api/verification/analyze`)

```json
{
  "analysis": {
    "id": 42,
    "kind": "document",
    "document_name": "essay.pdf",
    "overall_status": "human_review_required",
    "summary": "Two of five checkable claims could not be corroborated.",
    "checks": {
      "web_search": true,
      "sources_found": 4,
      "claims_checked": 5,
      "citations_checked": 1
    },
    "claims": [
      {
        "claim": "Load shedding cost the economy R300bn in 2023",
        "page": 3,
        "verdict": "contradicted",
        "concern": "The cited figure is roughly ten times the estimate published by the source found.",
        "evidence": ["https://example.org/report"]
      }
    ]
  },
  "sources": [{ "title": "…", "url": "…" }],
  "inputs": [
    {
      "type": "document",
      "label": "essay.pdf",
      "chars": 58240,
      "pages": 26,
      "pages_read": 26,
      "truncated": false,
      "quality": "good"
    }
  ],
  "web_searched": true,
  "request_id": "…"
}
```

- `verdict` is one of `supported`, `contradicted`, `unverified`; `page` is the
  source page for a document (null for pasted text).
- `overall_status` is **derived by the server**, never chosen by the model.
- `sources_confirmed` stays at the top level for compatibility and is now
  computed as `claims.filter(v => v.verdict === 'supported').length`.
- `inputs[].truncated` is true when the page or character cap cut the document;
  `quality` is `good` or `low` (low means extraction produced mostly symbols,
  single letters or replacement characters). The app must show both.
- Version-1 rows already in `verification_analyses` must still render: the app
  treats a report without `claims` as a legacy report.

### 2. Error envelope

Every 4xx/5xx from the routes below returns:

```json
{
  "error": "This looks like a scanned PDF. We could not read any text.",
  "code": "document_no_text",
  "hint": "Upload a text-based PDF or paste the text instead.",
  "retryable": false,
  "request_id": "…"
}
```

`error` stays human-readable and keeps working for existing clients. `code`,
`hint` and `retryable` are new. The app maps `code` to an action, never the raw
exception text.

### 3. Industry switch

```json
{
  "user": { "id": 12, "industry_track_id": 3, "industry_track_name": "IT / Software" },
  "track": { "id": 3, "name": "IT / Software", "description": "…" },
  "progress": { "readiness_score": 0, "tier": "Novice", "skill_scores": [] },
  "tour": { "should_offer": true, "status": "not_started" },
  "kept": ["xp", "level", "streak", "tokens"],
  "request_id": "…"
}
```

### 4. Support content

`GET /api/support/help`, `/api/support/faqs`, `/api/support/industry-guides`,
`/api/support/about`, `/api/support/tour` all return `{ "<collection>": [...],
"version": "2026-10-22", "request_id": "…" }` with ETag support. Markdown lives
in `body_md` / `answer_md`; the app already has a markdown renderer.

### 5. Roadmap and achievements

Two separate concepts, two separate endpoints — do not merge them back.

- `GET /api/roadmap` → staged journey. Full shape in "Roadmap design — the
  milestone tracker" below. Freeze `stage.status`, `milestone.status`, the
  `unit` values and `next_action` on day 1; the app builds against a fixture.
- `GET /api/achievements` → `{ "achievements": [{ "id", "code", "name",
  "description", "earned", "earned_at" }], "request_id": "…" }`, 14 entries
  after BF-9, ordered by `id`. `earned` is the only new field; it is a boolean.
- `GET /api/achievements/milestones` → `410` with `code: "roadmap_moved"` for
  one release, then removed.

---

# Part A — Fix (current build)

Things that are wrong today. Two of these (BF-5, BF-6) are the "restructuring of
a workflow" the QA report implies: switching industry currently changes the
label but not the learner's actual progress state.

## BF-1 — Verification searches the web with the wrong query · P0 · L (3)

**QA ref:** 9 (verification does not work as expected).

**Issue.** `buildEvidence` sets `primaryQuery` to the first input's full text
(`backend/controllers/verificationController.js:67-124`), and
`analyzeVerification` passes it straight to `webSearch(evidence.primaryQuery)`
(`:150`). `services/tavily.js` truncates whatever it receives to 380 characters.
For a pasted ChatGPT essay the "search query" is literally the opening paragraph;
for a PDF it is the first page. Tavily has no claim to match, so it returns
loosely-related pages or nothing, `sources_confirmed` stays at 0 and the report
lands on `insufficient_evidence` — the exact "verification failed" result the QA
tester saw. Citation lookups are searched correctly, but their results are merged
into the same evidence blob and then applied to the whole document. The material
is also cut at 60,000 characters by `extract.js` and at 120,000 characters for
the combined evidence (`MAX_TOTAL_CHARS`), so pages beyond that point are never
considered and the cut is not reported.

**Fix — separate *finding claims* from *checking claims*.**

1. `services/verification/claims.js`: extract up to 8 discrete factual claims
   from the material using the `light` profile (`temperature 0`, JSON out:
   `{ "claims": [{ "text": "…", "page": 3, "kind": "statistic|date|name|quote|causal" }] }`).
   Chunk long material by page in ~6,000-character windows (the extractor
   supplies page markers, see BF-4), so a 40-page document is represented by
   claims from across the whole file rather than its first 60,000 characters.
   Deterministic fallback if the model fails: sentences containing a number,
   date, percentage, proper noun or quotation mark, capped at 6.
2. For each claim call `webSearch(claim.text, { maxResults: 3 })`. Cap the fan-out
   at 8 searches and ~20 s total; run them sequentially or with a small pool, not
   `Promise.all` over 8 (Tavily and the model provider enforce their own limits).
3. De-duplicate results by URL across claims while keeping the per-claim
   association, so one source can support two claims but is cited once.
4. Send `{ material: <trimmed>, claims: [{ text, evidence: [...] }] }` to the
   analysis model and ask **only** for a verdict, concern and evidence ids per
   claim. Do not ask it to decide the overall status (BF-3).
5. Keep user-supplied citations as a distinct evidence set and record which
   claims they support (`citations_checked`).

**Acceptance**
- No request ever sends more than 380 characters of raw document as a search
  query; the query is a claim.
- A fabricated statistic in a test fixture produces a `contradicted` verdict with
  the contradicting URL attached to that claim.
- Searches are capped, de-duplicated and attributed.
- A document with no checkable claims returns `insufficient_evidence` with a
  clear summary, not a 500 and not `appears_sound`.
- A 30-page fixture produces claims from pages beyond the first 60,000
  characters, and every document claim carries a page number.

**Tests.** New `backend/tests/verificationPipeline.test.js` with a mocked Tavily
and model: assert the query is claim text, the cap is honoured, duplicate URLs
collapse, evidence is attached to the right claim, long-document chunking, and
the no-claims path.

## BF-2 — A model hiccup turns into "Verification failed" · P0 · L (3)

**QA ref:** 9 (useful error messages; do not fake a result).

**Issue.** The `analysis` profile runs with `thinking: true`, `maxTokens: 4000`
and `reasoningBudget: 2000` (`backend/services/llm/profiles.js:19-27`). A
reasoning model that spends the budget on its trace returns empty `content`;
`analyzeContent` then throws 502 "The AI service returned an empty response."
`chatWithFallback` retries on the fallback model with the **same** thinking
parameters, so the retry can fail the same way. Separately, `parseReport`
throws 502 when the text is not JSON. Both surface as the same generic failure
in the app.

**Fix**
- Give verification its own profile: `thinking: false`, `temperature: 0.1`,
  `maxTokens: 2500`, `timeoutMs: 45000`, explicit fallback. Reasoning is not
  needed to classify claims against supplied evidence, and disabling it removes
  the empty-content class of failure.
- If the provider supports a JSON response format, use it; otherwise keep the
  strict prompt and validate with a small schema checker rather than accepting
  any JSON.
- One repair attempt on invalid JSON ("Your previous answer was not valid JSON.
  Return only the object described."). After that return
  `502 report_unreadable` with `retryable: true`.
- Log `finish_reason`, token usage, `request_id` and the failure stage. Never log
  document text or the model's content.
- Add a metric counter per failure stage so the next QA round can see whether
  failures are transport, parsing or evidence.

**Acceptance**
- No verification request can end in "empty response".
- A fenced JSON reply, a reply with prose around the object, and a malformed
  reply each have a defined outcome covered by a test.
- The repair path is attempted at most once.

**Tests.** Extend `verificationWeb.test.js`; new cases for empty content,
fenced JSON, malformed JSON + repair, and fallback profile parameters.

## BF-3 — The report can claim more certainty than the checks support · P0 · M (2)

**QA ref:** 9 ("ensure the application does not claim that content is verified
when the necessary checks have not actually been performed").

**Issue.** `parseReport` takes `overall_status` and `sources_confirmed` directly
from the model (`verificationController.js:18-63`). A model can return
`appears_sound` with zero search results, and the result screen renders a green
"Appears sound" with no indication that nothing was checked. `web_searched` is
`webResults.length > 0`, which conflates "we searched" with "we found
something". This is the honesty requirement in the QA report, not just a wording
issue.

**Fix**
- Move to the v2 report in the contract: per-claim verdicts plus a `checks`
  block, and derive the status server-side with a pure function:
  - any `contradicted` → `human_review_required`
  - `claims_checked > 0` and `sources_found === 0` → `insufficient_evidence`
  - every checked claim `supported` (and at least one) → `appears_sound`
  - otherwise → `human_review_required`
- Compute `sources_confirmed` from the verdicts instead of trusting the model.
- `web_searched` becomes `checks.web_search`; add `sources_found` so the app can
  distinguish "search ran, nothing found" from "search was off".
- Store the report version inside the JSONB payload (`"version": 2`) so history
  stays readable after the next schema change. No table migration needed.

**Acceptance**
- Unit tests cover the full derivation matrix, including the rule that
  `appears_sound` is unreachable with zero sources.
- A report with zero checkable claims cannot be `appears_sound`.
- Legacy rows (no `claims`) still return and render.

**Tests.** New `backend/tests/verificationReport.test.js`.

## BF-4 — Document intake loses text and hides extraction problems · P0 · M (2)

**QA ref:** 9 (uploading a supported document, useful errors).

**Issue.** The model never receives a file: `services/documentParseChild.js`
extracts text with `pdf-parse` (pdf.js) for PDFs and `mammoth.extractRawText` for
DOCX, then only that text is sent. That is why text-based PDFs work today and
your earlier uploads were read. The extraction layer still has six problems:

1. **No OCR.** A scanned or image-only PDF yields an empty string. That empty
text is still sent to the model as `(no readable text)`, which can return
`appears_sound` — a report about nothing.
2. **Silent truncation.** `extractDocument` computes `truncated` when the
40-page or 60,000-character cap is hit (`services/extract.js`), but
`buildEvidence` drops the flag. A 50-page document is analysed up to page 40 and
the user is never told.
3. **Lost structure.** `mammoth.extractRawText` flattens DOCX headings, lists and
tables. `pdf-parse` joins items by vertical position, so multi-column PDFs can
interleave and tables lose their rows.
4. **No page markers.** Claims cannot say where in the document they came from,
and BF-1 has no safe way to chunk long material.
5. **No quality check.** Broken font mappings can produce gibberish rather than
empty text, and nothing detects it.
6. **Input contract drift.** The app accepts 10 MB
(`verification_studio_screen.dart:59`) while the server rejects above 5 MB; the
picker accepts any file type; `.doc`, `.pptx`, `.xlsx` and images are decoded as
UTF-8 and become binary garbage.

**Decision (Sprint 2): text extraction only.** No OCR, no vision fallback. An
image-only PDF is rejected honestly with a remedy. OCR is a deliberate follow-up
(see "Out of scope"), not a silent gap.

**Fix**
- Allowlist `pdf`, `docx`, `txt`, `md`; verify magic bytes for PDF (`%PDF-`) and
  DOCX (`PK\x03\x04`). Reject `.doc` with "Save as .docx and try again"; reject
  other formats with the supported list.
- Page-aware extraction: a custom `pagerender` in `documentParseChild.js` prefixes
  each page with `[page N]`, and the child returns `pages` and `pages_read`.
  `extractDocument` returns `{ text, pages, pagesRead, truncated, quality }`
  instead of dropping the metadata.
- DOCX: use `mammoth.convertToHtml` and convert headings, lists and tables to
  lightweight markdown; fall back to `extractRawText` if conversion fails.
  No new dependency.
- Quality gate: if the extracted text is empty or under ~40 characters →
  `422 document_no_text` (scanned-PDF hint + “paste the text” alternative). If it
  is mostly symbols, single letters or replacement characters → `quality: "low"`
  and a warning in the response, still analysed if there is usable text.
- Truncation: keep the 40-page / 60,000-character caps for now, but return
  `pages`, `pages_read` and `truncated` in `inputs` (see the contract). The app
  must warn when `truncated` is true.
- Export limits and accepted formats from one module and serve them on
  `GET /api/meta` (BB-8). The app stops hardcoding 10 MB.
- Return `413 document_too_large` with the real limit in `hint`.
- **Scope guard:** if the DOCX structure conversion takes more than half a day,
  keep raw text for DOCX and open a follow-up; do not let formatting work delay
  the verification fixes.

**Acceptance**
- A text PDF extracts with `[page N]` markers; a real 3-page and 22-page PDF both
  work (verified against the current parser).
- An image-only/scanned PDF is a 422 `document_no_text`; the model is never
  called with an empty document.
- `.doc`, `.pptx`, `.xlsx`, images, wrong magic bytes and oversize files each
  produce a distinct, actionable code.
- A >40-page or >60,000-character document reports `truncated: true` and
  `pages_read`; nothing is cut silently.
- DOCX headings, lists and table rows survive in the extracted text.
- Low-quality extraction is flagged and does not silently become a clean report.
- No OCR code path exists in this sprint; no tesseract/vision call is made.

**Tests.** New `backend/tests/verificationInput.test.js` with fixtures: text PDF,
no-text PDF, 50-page PDF (truncation), DOCX with headings and a table, corrupt
file, `.doc`, oversize. Assert codes, page metadata and the quality flag. Extend
`extract` coverage for empty and corrupt files.

## BF-5 — Changing industry is a bare column update · P1 · M (2)

**QA ref:** 3 (industry switching must show the right content and features).

**Issue.** `PUT /api/users/profile` writes `users.industry_track_id` and returns
the row (`backend/controllers/usersController.js:36-61`). It does not reject a
no-op change, does not record the change, and does not recompute anything. The
app then only invalidates the dashboard
(`industry_select_screen.dart:135`). Nothing marks the moment the learner's
context changed, so every derived value stays stale until the next attempt.

**Fix**
- New `PUT /api/users/industry` (the existing profile route keeps accepting
  `industry_track_id` and delegates to the same service, for compatibility).
- One transaction: lock the user row, validate the target track exists, reject
  the current track with `409 same_track` (so a double tap cannot reset
  anything), update, insert an audit row in `user_track_changes`
  (`user_id, from_track_id, to_track_id, changed_at`, migration
  `034_user_track_changes.sql`), recompute readiness for the new track, commit.
- Return the contract in "Industry switch", including the tour offer (BF-7) and
  the list of values that carry across (XP, level, streak, tokens).
- Invalidate any `contentCache` key that is track-dependent (today the caches are
  global curriculum data, so this is a guard for future keys).

**Acceptance**
- Same-track change is a 409 and writes nothing.
- A successful change writes exactly one audit row and recomputes readiness for
  the new track inside the same transaction.
- The response matches the frozen contract; `kept` is accurate.

**Tests.** New `backend/tests/industrySwitch.test.js` (unknown track, same track,
happy path, concurrent double switch).

## BF-6 — Progress and history are not scoped to the industry · P0 · XL (5)

**QA ref:** 3 (correct learning content after switching).

**Issue.** `skill_scores` is keyed on `(user_id, dimension)` with no track
(`backend/db/schema.sql`); `task_attempts` are user-scoped; `getProgress` returns
every skill row (`progressController.js:8-40`); `dashboardController` returns
every row; `refreshReadiness` mixes scores from all industries while dividing by
the *current* track's offered modules (`services/readinessService.js:38-118`).
So a learner who switches from Finance to Legal keeps Finance's readiness, skill
bars and completed-module counts; the new industry looks partly complete. This
is the underlying reason the QA tester could not tell whether switching had
worked.

**Fix — scope competency to the track, keep progression global.**

- `skill_scores` gains `track_id` and the unique key becomes
  `(user_id, track_id, dimension)`. Backfill from the attempted task's track
  (`task_attempts → tasks.track_id`); rows with no attempt fall back to the
  user's current track.
- New `user_track_progress (user_id, track_id, readiness_score, readiness_best,
  tier, tasks_completed, last_activity_date, PRIMARY KEY (user_id, track_id))`.
  Backfill from `user_progress`. `refreshReadiness(client, userId, trackId)`
  writes this row instead of `user_progress.readiness_score`, and keeps
  `readiness_best = GREATEST(readiness_best, readiness_score)`. The high-water
  mark exists for the roadmap: a weak retake can lower readiness without ever
  taking back a completed stage (see "Milestone semantics" below).
- Keep `user_progress` for the global signals: `xp`, `level`, `streak`, `tokens`.
  Switching industries must not cost the learner their XP or streak. Its
  `readiness_score` / `tier` columns stay as a mirror of the active track for
  older code paths; every read path must move to `user_track_progress` in the
  same PR, and a comment marks the old columns as deprecated.
- Read paths use `users.industry_track_id`:
  `/dashboard` (readiness + dimensions), `/progress` (skill scores +
  completed count), `/leaderboard` (join `user_track_progress` for the active
  track instead of `user_progress.readiness_score`), and the Vera context.
- `/history` gains `?track=current|all` (default `current`) and joins
  `tasks.track_id`; the `user_activity` view gains `track_id` for task rows so a
  capstone/activity row can be filtered by its own track where available.
- Migration `031_track_scoped_progress.sql`, idempotent, recorded in
  `schema_migrations`.

**Acceptance**
- Switching Finance → Legal shows readiness 0 / no skill bars for Legal, then
  restores the Finance values when switching back.
- XP, level, streak and tokens survive a switch.
- Old-industry attempts never count toward the new industry's readiness.
- Leaderboard `me` and board rows use the active track's readiness.
- Dashboard and Progress agree for the same user in the same request window.

**Tests.** Extend `tiers.test.js`, `scoring.test.js` and add
`backend/tests/trackScopedProgress.test.js` (switch, isolation, restore,
leaderboard join).

## BF-7 — Tutorial completion only exists inside one device · P1 · M (2)

**QA ref:** 3 (tutorial accessible when entering a new industry), 7 (skipping
must not remove guidance), 5 (Help must work after a skip).

**Issue.** `WelcomeTutorialScreen` writes
`verifai_welcome_tutorial_completed_v1`
(`welcome_tutorial_screen.dart:18`) but nothing reads it. The tour is only
reachable from the industry → Continue path; changing industry goes straight to
`/dashboard`, and a reinstall or second device forgets everything. The backend
knows only "has an industry / has none" (`industry_track_id != null` in
`dio_api_client.dart:695`).

**Fix**
- `user_tutorials (user_id, track_id, tour_key, status completed|skipped,
  updated_at, PRIMARY KEY (user_id, track_id, tour_key))`, migration
  `030_tour_state.sql`.
- `GET /api/onboarding/tour?track_id=` → `{ tour_key, status, should_offer,
  updated_at }`; `PUT /api/onboarding/tour` with `{ track_id, status }` (upsert,
  idempotent).
- Include a `tutorial` summary for the active track in `GET /api/auth/me` so the
  app can decide first-run state without SharedPreferences.
- `should_offer` is true when there is no row for that track (new industry) or
  the row is `skipped` and the app explicitly asked to be re-offered.

**Acceptance**
- Skipping records `skipped` server-side; completing records `completed`.
- A newly selected industry returns `should_offer: true`.
- Repeat PUT is idempotent and does not move `updated_at` unnecessarily.
- The app can replay the tour from Help with the same endpoints.

**Tests.** New `backend/tests/tour.test.js`.

## BF-8 — API failures are opaque to the client · P1 · M (2)

**QA ref:** 9 (useful error messages), 12 (QA needs reproducible failures).

**Issue.** Verification failures are mapped to status codes in
`middleware/aiError.js`, but the body carries only a human sentence. The app
prints the raw Dio exception on top of it
(`verification_studio_screen.dart:137`). There is no machine-readable code, so
the app cannot distinguish "your file is too big" from "the AI is down" and
cannot decide whether to offer Retry or Edit. Provider text can leak into the
message (e.g. `result.error.message` from the LLM).

**Fix**
- Add `sendApiError(res, { status, code, error, hint, retryable, requestId })`
  and use it for `/api/verification/*`, `/api/onboarding/*` and
  `/api/support/contact`.
- Codes: `no_input`, `document_too_large`, `document_unsupported`,
  `document_no_text`, `document_parse_failed`, `ai_unavailable`, `ai_timeout`,
  `report_unreadable`, `rate_limited`, `same_track`.
- Replace provider messages with stable copy; keep the provider detail in the
  server log only.
- Keep the existing `error` field first so older builds keep working.
- Rate limiting happens before these controllers. Add a `handler` to
  `uidRateLimit`/`aiLimit` that emits the same envelope with `code:
  "rate_limited"` and `retryable: true`, or document 429 as the one deliberate
  exception for this sprint.

**Acceptance**
- Every failure the app can render has a code and a hint.
- No provider or stack text is reachable from a response body.
- `request_id` is present on every error.

**Tests.** New `backend/tests/errorEnvelope.test.js` covering each code.

## BF-9 — The "milestones" endpoint is a second achievements list · P1 · M (2)

**Source:** product feedback on the Skill Roadmap (after QA round 1). The current
roadmap is a checklist of XP, level, streak and task-count badges, not a journey.

**Issue.** `GET /api/achievements/milestones`
(`backend/controllers/achievementsController.js:46-160`) builds six rows from
`xp`, `level`, `streak` and task counts: First Steps, Track Master, Committed
(250 XP), Dedicated (1000 XP), On Fire (7-day streak) and Seasoned (level 5).
Each has an `achieved` flag but no order, no prerequisite and no evidence beyond
a number. Several already duplicate achievements (`first-task`, `xp-500`,
`ten-tasks`), and the endpoint lives under `/achievements`, which is exactly what
it is: a second, unordered achievement list. The only consumer is the roadmap
screen (`milestonesProvider`), so this can be moved without breaking a public
contract.

**Fix — move these six into the achievements catalog, then delete the endpoint.**

| Former roadmap item | Achievement code | Action |
|---|---|---|
| First Steps | `first-task` (exists) | Upsert copy to "First Steps" |
| Track Master | `track-master` (new) | All published tasks in the active track passed |
| Committed (250 XP) | `xp-250` (new) | `xp >= 250` |
| Dedicated (1000 XP) | `xp-1000` (new) | `xp >= 1000` |
| On Fire (7-day streak) | `streak-7` (new) | `streak >= 7` |
| Seasoned (level 5) | `level-5` (new) | `level >= 5` |

- Seed the new rows in `db/seed/78_achievements.sql` (idempotent upsert by
  `code`). Keep the existing five base achievements and the four capstones; the
  catalog becomes 14.
- Extend `awardAchievements` (`backend/controllers/tasksController.js:616-646`)
  so `stats` also reads `xp`, `level`, `streak` from `user_progress` and
  `track_total` / `track_passed` for the user's active track. Add the four new
  conditions to the `eligible` CTE. The existing `NOT EXISTS` + `ON CONFLICT`
  already makes awarding idempotent; keep token grants keyed on the code.
- Two details that decide whether the badges look correct:
  - **XP must mean the number the app shows.** Today `stats.xp` is
    `SUM(task_attempts.xp_earned)`, which excludes capstone, activity and reward
    XP. Move every XP condition (`xp-250`, `xp-500`, `xp-1000`) to
    `user_progress.xp`, otherwise a learner sitting at 260 XP has no 250 badge.
  - **Awarding only runs on task submission** (`tasksController.js:393`). A
    level, streak, capstone-score or track-completion badge would then wait for
    the next task. Call `awardAchievements` from the capstone submit, activity
    grading and the daily streak rollover too, so a badge never arrives a day
    late. Do not fake it with a read-time `UPDATE` in `GET /api/achievements`.
- Delete `buildMilestones` and `getMilestones`; replace the route with a `410
  Gone` shim for one release:
  `{ error: 'The track roadmap moved to /api/roadmap.', code: 'roadmap_moved', request_id }`.
  The new app never calls it.
- Update `backend/tests/api.test.js`: remove the two `/milestones` tests and add
  award tests for the new achievements (thresholds, current-track completion,
  no double award, no double tokens).

**Acceptance**
- `/api/achievements` returns all 14 achievements with `earned` / `earned_at`.
- `track-master`, `xp-250`, `xp-1000`, `streak-7` and `level-5` are awarded at
  the right thresholds and only once.
- Completing a task in Finance cannot award `track-master` for Legal.
- An XP badge appears at the same moment the dashboard shows the qualifying XP,
  including XP earned from a capstone or activity rather than a task.
- `/api/achievements/milestones` returns the 410 shim, not a list.
- The roadmap endpoint (BB-10) does not read achievements at all; the two
  concepts are independent.

## What is already healthy

No changes needed: Firebase auth verification and `findUserByFirebaseUid`,
`/auth/sync` and `/auth/me`, rate limiting, the global error handler, rewards and
token ledger, wellness, the per-feature task tables and scoring engine, the
`user_activity` view idea, and content caching/ETag on `/tracks`. The QA report's
praise for the login/negative-testing behaviour matches what the backend does.

---

# Part B — Build (net-new)

Everything here is missing today. The support surface is intentionally
**content-driven**: articles, FAQs, guides and tour steps live in the database so
the team can fix wording or add an answer without shipping an app build. That is
the difference between a one-off help screen and a help system the QA tester can
retest after changes.

## BB-1 — Support content schema and seed · P0 · L (3)

**QA ref:** 5 (Help), 6 (FAQ), 4/5 (industry pages), 8 (visual explanations).

**Issue.** There is no help, FAQ, industry-guide or about content anywhere in the
backend (grep for `help`, `faq`, `about`, `contact` returns nothing outside
unrelated comments).

**Build**

```sql
help_articles (
  id, slug UNIQUE, title, summary, body_md, category, audience,
  sort_order, published, updated_at
)
faqs (
  id, slug UNIQUE, question, answer_md, topic, sort_order, published, updated_at
)
industry_guides (
  id, track_id UNIQUE REFERENCES industry_tracks, slug UNIQUE, tagline,
  overview_md, outcomes JSONB, feature_tour JSONB, how_to JSONB,
  hero_image, updated_at
)
```

Migration `032_support_content.sql`, seeds `70_support_help.sql`,
`71_support_faqs.sql`, `72_industry_guides.sql`.

Seed at minimum:

- **Help articles (10):** what VerifAI is; getting around the app; choosing and
  changing your industry; dashboard cards explained; Learn; Practice & skill
  scenarios; Verification Studio; Vera the assistant; progress, XP, streaks,
  achievements and tokens; troubleshooting (login, loading, verification, offline).
- **FAQ (exactly the QA list, 10):** what VerifAI is and how it works; how to
  change industry; what happens if you skip the tutorial; what Learn and Practice
  are for; what Verification Studio is; how to use Vera; what the readiness score
  means; how XP/streaks/achievements/tokens work; why verification can fail; how
  to log out and manage the account.
- **Industry guides (4):** Finance, Legal, IT / Software, Business Consulting.

**Acceptance**
- A fresh database built from the repo has all content (seeds keyed on `slug`,
  idempotent upserts).
- Every article/FAQ has a real answer, no lorem, no placeholder.
- Markdown renders in the app without custom HTML.

**Tests.** `backend/tests/supportContent.test.js` (seed idempotency, published
filtering, slug uniqueness).

## BB-2 — Support read API · P0 · M (2)

**QA ref:** 4, 5, 6.

**Build**
- `GET /api/support/help?category=` and `/help/:slug`
- `GET /api/support/faqs?topic=&q=` (case-insensitive question and answer match)
- `GET /api/support/industry-guides` and `/industry-guides/:slug`
- `GET /api/support/about` (mission, vision, South Africa impact, how it helps,
  contact details, app version)
- Public reads (no auth) so About can be linked from the login screen; cached
  content plus ETag, the same pattern as `tracksController`
- `404` for unknown slugs with the standard envelope

**Acceptance**
- ETag revalidation returns 304.
- Content changes are visible without a deploy.
- Response includes `version` so the app can cache and detect updates.
- Unknown slug is a clean 404, not an empty array.

**Tests.** `backend/tests/support.test.js` (list, filter, search, ETag, 404).

## BB-3 — Tour and media manifest · P1 · M (2)

**QA ref:** 7 (video/voice-over walkthroughs), 3 (industry intro after a switch).

**Build**
- `GET /api/support/tour?track=finance` → global tour + that industry's tour:

```json
{
  "tour_key": "finance-v1",
  "version": "2026-10-22",
  "autoplay": false,
  "steps": [
    {
      "id": "dashboard",
      "title": "Your home screen",
      "body_md": "…",
      "media": {
        "kind": "video",
        "url": "https://…/dashboard.mp4",
        "captions_url": "https://…/dashboard.vtt",
        "poster": "https://…/dashboard.jpg",
        "duration_seconds": 42
      }
    }
  ]
}
```

- Global tour covers the dashboard cards, starting a task, Vera, the menu, and
  Progress. Each industry tour covers what the four skills mean in that domain
  and which content to start with.
- `autoplay: false` is the only supported behaviour; the client decides.
- Media is hosted, not bundled, so replacing a recording is a content change. If
  hosting is not ready, ship the same manifest with `media: null` and the
  transcript in `body_md`; the app already handles a missing player.

**Acceptance**
- Five manifests (global + four industries), all with captions or transcripts.
- No media URL is hardcoded in the app.
- A missing/failed media URL still leaves a usable text tour.

**Tests.** `backend/tests/tourManifest.test.js` (track filter, shape, version).

## BB-4 — Contact intake · P1 · M (2)

**QA ref:** 6 (contact us), 5 (Help & Support).

**Build**
- `POST /api/support/contact` with `{ name, email, subject, message, category,
  app_version }`.
- Validate lengths and email format; require `category` from a fixed list
  (`bug`, `account`, `content`, `verification`, `feedback`, `other`).
- Rate limit per user/IP (reuse the limiter pattern; 5 per hour), and a honeypot
  field that silently accepts and discards bots.
- Store in `support_messages (id, user_id NULL, name, email, subject, message,
  category, app_version, status 'new', request_id, created_at)`, migration
  `033_support_messages.sql`.
- Optional notification email behind `SUPPORT_NOTIFY_EMAIL` (provider key in the
  environment). If it fails, the ticket is still stored and the response is
  still a success.
- Return `{ ticket_id, expected_reply: "1–2 working days", request_id }`.
- Never echo the message back; never log the body.

**Acceptance**
- 201 with a ticket id; stored row matches the request.
- Invalid email/message is a 400 with a code.
- Honeypot and rate limit behave without revealing which check failed.
- Missing notification provider does not fail the request.

**Tests.** `backend/tests/supportContact.test.js`.

## BB-5 — Admin support console API · P2 · L (3)

**QA ref:** 5/6 (content must be correctable quickly), 12 (retest cycle).

**Build**
- `GET/PUT /api/admin/support/help` and `/faqs` (list, update, publish/unpublish).
- `GET /api/admin/support/messages?status=&category=` and
  `PUT /api/admin/support/messages/:id` (status `new|in_progress|resolved`,
  internal note).
- Role gates consistent with the rest of the panel: moderator read, admin write.
- Audit every content edit and status change through the existing moderation
  audit path.

**Acceptance**
- Only admins can edit content; moderators can read.
- Every write is audited with actor, target and diff summary.
- Publishing an article makes it visible on the public read API immediately
  (content cache invalidated).

**Tests.** `backend/tests/supportAdmin.test.js`.

**Note.** The admin *screens* are out of scope for this sprint; this is the API
the existing admin panel can adopt next. Do not block Help delivery on it.

## BB-6 — Support analytics · P2 · M (2)

**QA ref:** 1 (first-time confusion), 12 (measure whether fixes work).

**Build**
- `support_events (id, user_id, event, target, metadata JSONB, created_at)`,
  migration `033` alongside messages.
- `POST /api/support/events` accepting one event at a time:
  `help_open`, `article_view`, `faq_expand`, `faq_search`, `tour_start`,
  `tour_complete`, `tour_skip`, `contact_open`, `contact_submit`.
- `GET /api/admin/support/insights?days=30` → top articles, top FAQ topics,
  searches with no result, skip rate per tour, contact volume by category.
- Best-effort write: a failed analytics insert must never affect the UI. Cap
  metadata keys; store slugs and ids only, never free text or message content.

**Acceptance**
- A failed event insert never returns an error to the app.
- No PII in `metadata`; a test asserts the allowlist.
- Insights query runs for a 30-day window without a full table scan (index on
  `(created_at)`, `(event)`).

**Tests.** `backend/tests/supportAnalytics.test.js`.

## BB-7 — Author the four industry guides · P1 · L (3)

**QA ref:** 4 (Learn More on all four cards), 8 (visual explanations).

**Build.** This is content, not code, but it is on the backend workstream
because it ships through the support-content seed. For each of Finance, Legal,
IT / Software and Business Consulting, write the same nine sections:

1. What this pathway is about (2 short paragraphs, plain language).
2. Who it is for and what you will be able to do at the end.
3. The four skills in this industry, each with one concrete workplace example
   (what bad AI output looks like and what to check).
4. What the dashboard cards mean for this pathway.
5. How to use Learn, Practice, Verification Studio, Vera, tasks and Progress.
6. A first-session checklist (5 steps, 15 minutes).
7. Common mistakes and how the app helps you avoid them.
8. Image keys for the hero and one in-body illustration (assets supplied by FB-8).
9. Links to the three most relevant FAQs.

**Acceptance**
- Four complete guides, consistent structure and tone.
- Every feature named in the guide exists in the app under that name.
- Reviewed by someone from that domain before merge (a comment on the PR is
  enough); no invented statistics or citations.
- Content fits the Learn More screen without truncation.

## BB-8 — Meta/config endpoint · P1 · S (1)

**QA ref:** 9 (limits and formats must agree with the app).

**Build**
- `GET /api/meta` → `{ api_version, verification: { max_document_bytes,
  max_pages, max_total_chars, accepted_formats }, support: { tour_version },
  limits: { contact_rate_per_hour } }`, cached with ETag.
- Values come from the same exported constants the validators use, so they cannot
  drift.

**Acceptance**
- Test asserts the response equals the constants from `extract.js` and the
  contact limiter.
- The app can drop its hardcoded 10 MB after this lands.

**Tests.** Extend `backendWiring.test.js`.

## BB-9 — Support data lifecycle · P2 · M (2)

**QA ref:** privacy obligations implied by storing contact details; also 12
(account deletion must remain correct).

**Build**
- Extend `services/accountPurge.js` so deleting an account also deletes
  `support_messages` rows for that user (or nulls `user_id` and redacts email if
  a ticket must be retained for audit — pick one and document it).
- `support_events` are deleted with the account.
- Add a retention script (`scripts/prune-support.js`): messages resolved for
  more than 24 months, events older than 12 months. Dry-run by default, same
  style as `recompute-readiness.js`.
- Document the policy in `README.md`.

**Acceptance**
- Deleting an account removes or redacts its support rows in the same
  transaction.
- The prune script reports counts and only deletes with `--apply`.
- No support table is left out of the purge path.

**Tests.** Extend the account purge test; add a prune dry-run test.

---

## BB-10 — Milestone tracker engine and content · P1 · L (3)

**Source:** product feedback on the Skill Roadmap.

**Issue.** There is no roadmap data model. The only "track" data is the
industry label (`industry_tracks`), and progress is spread across attempts,
capstones, case reads, activities and readiness. A proper tracker needs ordered
stages, evidence-based milestones, gating and a next action.

**Build**
- `roadmap_stages` and `roadmap_milestones` (migration `035_roadmap.sql`), with a
  `requirement_type` validated by a CHECK and an optional JSONB filter.
- `GET /api/roadmap` (new `routes/roadmap.js`) returning the contract in the
  design section below: stages, milestone evidence, statuses, next action and
  the credential state.
- A requirement evaluator that reads existing data only — `task_attempts`,
  `lab_capstone_attempts`, `industry_case_reads`, `lab_activity_attempts`,
  `user_track_progress` (BF-6) and `user_tutorials` (BF-7). No new event table.
- Seed five stages and ten milestones per track (40 rows of content) with a
  shared `seed_roadmap(track_name, stages jsonb)` helper in
  `db/seed/73_roadmap_helpers.sql`, then one file per track (`74`–`77`).
- Tests for gating, counters, track switching, empty states and the next action.

**Acceptance**
- A new user sees Stage 1 active, 0/10 milestones, and "Take the tour" as the
  next action.
- Completing Stage 1 unlocks Stage 2; locked stages cannot become active out of
  order.
- Evidence counts come from real rows, never from a client-supplied number.
- Switching industry returns the other track's roadmap (BF-5/BF-6).
- The response is one call; no N+1 queries per milestone.

**Tests.** New `backend/tests/roadmap.test.js` with seeded fixtures.

---

# Roadmap design — the milestone tracker

This is the shared design for BB-10 and FB-9. It replaces the current
"Track Roadmap" checklist. Read it with the UI design in
`SPRINT2_FRONTEND.md`.

## What a milestone tracker is (and is not)

- **Roadmap:** an ordered journey. Stages unlock in sequence, every milestone is
  backed by evidence from the learner's work, and the screen always answers
  "what do I do next?". No XP, streaks or badges on this screen.
- **Achievements:** the reward shelf. Optional badges for firsts, counts, XP,
  streaks, levels, capstones and skill thresholds. They live on Profile and can
  be earned in any order. The six former roadmap items move here (BF-9).

The two must not share a list. A learner can earn an achievement without moving
forward on the roadmap, and can complete a roadmap stage without unlocking a
badge (though some overlap is natural).

## The five stages (same for every track)

| # | Stage | Outcome | Milestones |
|---|---|---|---|
| 1 | **Orientation** | Know how VerifAI works and check your first AI output. | Take the industry tour · Pass 1 verification task |
| 2 | **Verify** | Catch confident mistakes in AI output. | Pass 3 verification tasks · Pass 1 medium-or-hard verification task |
| 3 | **Judge & govern** | Decide when AI should and should not be used. | Pass 2 AI Judgement tasks · Pass 2 Risk & Governance tasks |
| 4 | **Apply** | Use verification in your industry context. | Read 3 industry cases · Pass the track capstone at 70+ |
| 5 | **Prove readiness** | Show a level of readiness you can take to an employer. | Reach 70 readiness · Pass 5 AI Lab recall activities |

Gating rule: a stage is complete when **all** its milestones are complete. The
first incomplete stage is **active**; every later stage is **locked**. Inside the
active stage the first incomplete milestone is the **next action**; the other
incomplete milestones are **up next** (visible, not blocked).

## Milestone semantics — no progress can be taken back

A journey that un-completes itself is worse than no journey. So every milestone
is evaluated against evidence that only grows:

| Kind | Evidence | Rule |
|---|---|---|
| **Counter** | `tasks_passed`, `industry_cases_read`, `activities_passed`, `tutorial_completed` | Distinct passed/read rows. Never decremented — a failed retake does not remove an earlier pass. |
| **Best score** | `capstone_score`, `readiness_score` | Best-ever, not current: `MAX(lab_capstone_attempts.score)` per assessment, and `user_track_progress.readiness_best` (BF-6). |

Consequences to implement and test:
- A learner who reaches 70 readiness keeps the Stage 5 milestone even if a later
  capstone retake drops the live score to 64. The hero chip still shows the live
  score; only the milestone uses the high-water mark, and the copy says "Reached
  70 readiness" rather than "Readiness is 70".
- `target` for readiness stays 70 (Proficient, `services/tiers.js`). Readiness is
  achievable because the denominator only counts modules the track offers, so
  covering every module plus a 70 capstone clears it without an interview bank.
- Stage status is derived on each read but is monotonic: once `complete`, a stage
  stays complete. Do not add a per-user roadmap table to "remember" this — the
  evidence is already monotonic, which is why the derived read is safe.
- Retakes and practice attempts do not inflate counters: only `passed` rows count,
  and only distinct task/case/activity ids.

## Requirement types

| Type | Evidence | Example filter |
|---|---|---|
| `tutorial_completed` | `user_tutorials` (BF-7) | `{ "tour_key": "industry" }` |
| `tasks_passed` | distinct passed `task_attempts` | `{ "feature": "verification", "difficulty": ["medium", "hard"] }` |
| `capstone_score` | best `lab_capstone_attempts.score` for the track capstone | `{}` (target 70) |
| `industry_cases_read` | `industry_case_reads` for the track | `{}` |
| `activities_passed` | distinct passed `lab_activity_attempts` | `{ "scope": "track_or_global" }` |
| `readiness_score` | `user_track_progress.readiness_best` (BF-6) | `{}` (target 70) |

`interview_practised` is deliberately **not** a requirement this sprint: the
question bank is Legal-only, so it would make the roadmap impossible on the
other three tracks. Add it when all tracks have a bank.

### Where each requirement reads from

The schema does not put every field where it looks like it belongs, so the
evaluator joins explicitly. One query per requirement type with all of the
track's milestones batched in, not one query per milestone.

| Type | Source and join | Filter handling |
|---|---|---|
| `tutorial_completed` | `user_tutorials u` where `u.user_id` and `u.tour_key = filter->>'tour_key'` | Presence of the row is the count (max 1). |
| `tasks_passed` | `task_attempts ta JOIN tasks t ON t.id = ta.task_id` where `t.track_id = :track` and `ta.passed` | `filter->>'feature'` → `t.feature`; `filter->'difficulty'` needs `LEFT JOIN verification_tasks vt ON vt.task_id = t.id` and `vt.difficulty = ANY(...)` — difficulty is **not** on `tasks`. |
| `capstone_score` | `lab_capstone_attempts a JOIN lab_capstone_assessments c ON c.id = a.assessment_id` where `c.track_id = :track` | `MAX(a.score)`; target is the pass mark, so a failed attempt alone never completes it. |
| `industry_cases_read` | `industry_case_reads r JOIN industry_cases c ON c.id = r.case_id` | `c.track_id = :track`; rows are one per case, so `COUNT(*)` cannot double-count. |
| `activities_passed` | `lab_activity_attempts aa JOIN lab_activities a ON a.id = aa.activity_id JOIN lab_lessons l ON l.id = a.lesson_id` | `aa.passed` and `(l.track_id = :track OR l.track_id IS NULL)` — practice lessons are track-scoped, the AI-literacy lessons are global. Count `DISTINCT aa.activity_id`. |
| `readiness_score` | `user_track_progress` row for `(:user, :track)` | `COALESCE(readiness_best, 0)`. |

Historical data note: `task_attempts` rows already exist for attempts made before
the sprint. They count, which is why a returning learner may open the roadmap
with Stage 1 already complete. That is intended — the tracker records work
already done, it does not restart the journey.

## Per-track flavour

Requirements are identical; the wording and examples are domain-specific so the
journey feels like the learner's industry, not a generic checklist.

| Track | First check | Judgement milestone | Governance milestone |
|---|---|---|---|
| Finance | Audit an AI-generated figure before it reaches a client. | Decide when a forecast can use AI and when a person must own it. | Spot privacy and compliance risk in a finance workflow. |
| Legal | Check whether an AI summary cites the clause it claims to. | Decide when a draft can be AI-assisted and when it needs a lawyer. | Spot confidentiality, privilege and POPIA risk. |
| IT / Software | Review generated code for a bug the model is confident about. | Decide when AI can ship code and when a human must review it. | Spot security, licensing and data risk in an engineering workflow. |
| Business Consulting | Check an AI recommendation against the evidence behind it. | Decide when a strategy or client answer can be AI-assisted. | Spot bias, privacy and compliance risk in an engagement. |

## Milestone copy template (Finance filled in)

Ten rows per track, same codes everywhere. The Finance column is the copy to
write; the other three follow the flavour table above. This is the content
contract for `74_finance_roadmap.sql` — keep the codes identical across files so
the evaluator and the app never special-case a track.

| # | Code | Requirement (target) | Generic title | Finance title | CTA route |
|---|---|---|---|---|---|
| 1.1 | `tour` | `tutorial_completed` (1) | Take the {track} tour | Take the Finance tour | `/welcome-tour` |
| 1.2 | `first-check` | `tasks_passed` verification (1) | Check your first AI output | Audit your first AI-generated figure | `/verification` |
| 2.1 | `verify-three` | `tasks_passed` verification (3) | Pass three verification tasks | Catch three confident mistakes | `/verification` |
| 2.2 | `verify-hard` | `tasks_passed` verification, `difficulty: [medium, hard]` (1) | Catch a harder mistake | Catch a subtle error in a forecast | `/verification` |
| 3.1 | `judge-two` | `tasks_passed` judgement (2) | Decide when AI may be used | Decide when a forecast can use AI | `/judgement` |
| 3.2 | `govern-two` | `tasks_passed` risk_governance (2) | Manage the risk of using AI | Spot privacy and compliance risk | `/risk-governance` |
| 4.1 | `cases-three` | `industry_cases_read` (3) | Read three {track} cases | Read three finance cases | `/industry-practice` |
| 4.2 | `capstone-pass` | `capstone_score` (70) | Pass the {track} capstone | Pass the Finance capstone | `/ai-lab/assessments` |
| 5.1 | `readiness-70` | `readiness_score` (70) | Reach Proficient readiness | Reach Proficient readiness | `/progress` |
| 5.2 | `activities-five` | `activities_passed` (5) | Complete five recall drills | Complete five finance recall drills | `/ai-lab/practice` |

Writing rules: one sentence, second person, no XP or streak wording, no
"milestone 3 of 10" (the UI numbers them), and never promise a job or a
certificate. Stage `outcome` lines are in the five-stages table above and are
identical across tracks except for the domain noun.

## Data model

```sql
CREATE TABLE roadmap_stages (
  id SERIAL PRIMARY KEY,
  track_id INTEGER NOT NULL REFERENCES industry_tracks(id) ON DELETE CASCADE,
  code VARCHAR(40) NOT NULL,
  title VARCHAR(120) NOT NULL,
  outcome TEXT NOT NULL,
  description TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  credential_title VARCHAR(120),
  credential_description TEXT,
  UNIQUE (track_id, code)
);

CREATE TABLE roadmap_milestones (
  id SERIAL PRIMARY KEY,
  stage_id INTEGER NOT NULL REFERENCES roadmap_stages(id) ON DELETE CASCADE,
  code VARCHAR(60) NOT NULL,
  title VARCHAR(160) NOT NULL,
  description TEXT NOT NULL,
  requirement_type VARCHAR(40) NOT NULL CHECK (requirement_type IN (
    'tutorial_completed','tasks_passed','capstone_score',
    'industry_cases_read','activities_passed','readiness_score'
  )),
  requirement_target INTEGER NOT NULL CHECK (requirement_target > 0),
  requirement_filter JSONB,
  action_label VARCHAR(80),
  action_route VARCHAR(200),
  sort_order INTEGER NOT NULL DEFAULT 0,
  UNIQUE (stage_id, code)
);
```

No per-user roadmap table: status is derived from evidence on every read, so
nothing can drift and a learner who does the work before opening the screen sees
it as complete.

## API contract — `GET /api/roadmap`

Optional `?track=<id>` for previewing another track; defaults to the active one.

```json
{
  "track": { "id": 1, "name": "Finance" },
  "summary": {
    "current_stage": 2,
    "stages_completed": 1,
    "milestones_completed": 3,
    "milestones_total": 10,
    "percent": 30,
    "readiness_score": 34,
    "tier": "Novice"
  },
  "stages": [
    {
      "code": "orient",
      "title": "Orientation",
      "outcome": "Know how VerifAI works and check your first AI output.",
      "order": 1,
      "status": "complete",
      "milestones": [
        {
          "code": "tour",
          "title": "Take the Finance tour",
          "description": "See where everything lives and what the four skills mean in Finance.",
          "status": "complete",
          "current": 1,
          "target": 1,
          "unit": "tour",
          "action": { "label": "Replay tour", "route": "/welcome-tour" }
        }
      ]
    }
  ],
  "next_action": {
    "stage": "verify",
    "milestone": "verify-three",
    "label": "Pass your next verification task",
    "route": "/verification"
  },
  "credential": {
    "title": "AI Readiness Passport",
    "description": "Complete all five stages and reach Proficient readiness.",
    "unlocked": false
  },
  "request_id": "…"
}
```

- `stage.status`: `complete` | `active` | `locked`.
- `milestone.status`: `complete` | `current` | `up_next` | `locked`.
- `unit` is a short noun for the UI (`task`, `case`, `activity`, `score`).
- `milestone.current` for a score requirement is the best-ever value, so it can
  exceed the live score shown in `summary.readiness_score`; both are correct.
- `next_action` is the first incomplete milestone in the active stage; it is
  null only when every stage is complete.
- `credential.unlocked` is true when Stage 5 is complete (which includes the
  readiness milestone). This is a display state; a shareable passport is out of
  scope.

## Content and seeds

- 20 stage rows (5 × 4 tracks) and 40 milestone rows (10 × 4).
- One helper (`73_roadmap_helpers.sql`) and four data files (`74`–`77`), all
  idempotent by `(track_id, code)` and `(stage_id, code)`.
- Descriptions are concise (one sentence each); no XP or streak wording. Copy
  reviewed by the domain owner, same as BB-7.

## Suggested sequence

Both workstreams run in parallel after the contract freeze.

| Day | Backend Fix (A) | Backend Build (B) |
|---|---|---|
| 1 | Freeze contract; BF-8 error envelope (unblocks FF-7) | Freeze contract; BB-1 schema |
| 2–3 | BF-1 claim pipeline; BF-2 profile/repair | BB-8 meta; BB-2 read API |
| 4 | BF-3 derived status + tests | BB-3 tour manifest |
| 5–6 | BF-4 extraction, intake and truncation metadata | BB-4 contact intake |
| 7–8 | BF-6 track-scoped progress (migration + read paths) | BB-10 roadmap tables + endpoint + seeds |
| 9 | BF-5 industry switch endpoint | BB-10 content + tests |
| 10 | BF-7 tutorial state + BF-9 achievement migration | BB-7 industry guide content |
| 11 | Regression pass; achievement award tests | BB-5 admin API; BB-6 analytics |
| 12 | QA retest support for verification + switching | BB-9 lifecycle; QA retest support |

Two critical paths: BF-6 (track-scoped progress) and BB-10 (roadmap data). The
frontend cannot finish FF-4/FF-5 copy without BF-6, or FB-9 without BB-10. Run
the BF-6 migration against a copy of staging **before** the sprint starts, and
freeze the roadmap contract on day 1 so D can build against a fixture.

## QA record — fill during the sprint

Use one row per retest. Severity follows the report: **S1** blocks a workflow,
**S2** degrades it, **S3** cosmetic.

| Test ID | Area | Steps | Expected | Actual | Severity | Owner | Status |
|---|---|---|---|---|---|---|---|
| QA2-B01 | Verification | Upload a 6 MB PDF | Rejected before upload with the real limit | | S2 | FE 2 | Open |
| QA2-B02 | Verification | Paste a ChatGPT essay | Report lists checked claims, no false "sound" | | S1 | BE 1 | Open |
| QA2-B03 | Verification | Citation lookup for "POPIA section 22" | Sources returned and linked to the claim | | S1 | BE 1 | Open |
| QA2-B04 | Verification | Upload an image-only PDF | 422 with scanned-PDF hint; no model call | | S3 | BE 1 | Open |
| QA2-B05 | Verification | Upload a 50-page PDF | `truncated: true` and pages read shown | | S2 | BE 1 | Open |
| QA2-B06 | Industry switch | Finance → Legal, open Progress | Legal readiness 0, no Finance skills | | S1 | BE 1 / FE 1 | Open |
| QA2-B07 | Industry switch | Switch back to Finance | Previous Finance readiness restored | | S1 | BE 1 | Open |
| QA2-B08 | Tutorial | Skip, reopen Help | Tour replay offered | | S2 | FE 1 | Open |
| QA2-B09 | Support | Open Help, search "change industry" | Answer found and linked | | S2 | FE 2 | Open |
| QA2-B10 | Contact | Submit with a bad email | Inline validation, no request | | S3 | FE 2 | Open |
| QA2-B11 | Logout | Log out from the drawer | Lands on login, back cannot re-enter | | S1 | FE 1 | Open |
| QA2-B12 | Navigation | Back from every hub | Returns to the hub, never exits | | S1 | FE 1 | Open |
| QA2-B13 | Roadmap | Open `/track` on a fresh Finance account | Stage 1 active, 0/10, next action is the tour | | S1 | BE 2 | Open |
| QA2-B14 | Roadmap | Complete the tour, reopen the roadmap | Stage 1 complete, Stage 2 active, next action is a verification task | | S1 | BE 2 | Open |
| QA2-B15 | Roadmap | Switch Finance → Legal, open the roadmap | Legal stages and wording, no Finance evidence carried over | | S1 | BE 2 | Open |
| QA2-B16 | Achievements | Move a former roadmap item to done | Badge appears in `/api/achievements` once, tokens granted once | | S2 | BE 1 | Open |
| QA2-B17 | Achievements | Call the old milestones route | 410 `roadmap_moved`, no list | | S3 | BE 1 | Open |

Status values: `Open` → `In progress` → `Fixed` → `Retest` → `Closed` (or
`Reopened`). A task is not done until its row is `Closed`.

## QA traceability

Every section of the report maps to at least one task. Backend tasks (BF/BB)
live in this file; frontend tasks (FF/FB) live in `SPRINT2_FRONTEND.md`. The
report's numbered list repeats 5 and 6, so the rows below use the section names.

| QA section | Finding | Backend tasks | Frontend tasks |
|---|---|---|---|
| Overall feedback | Plain and confusing for a first-time user | BB-1, BB-2, BB-7 | FB-2, FB-5, FB-7, FB-8, FF-9 |
| Navigation & back buttons | Back buttons, return to Home, menu consistency | — (client-side) | FF-1, FF-2, FF-3, FF-10 |
| Industry switching | Discoverability, correct content, tutorial on entry | BF-5, BF-6, BF-7 | FF-4, FF-5, FF-6 |
| Industry "Learn More" | Link on all four industry cards + guide content | BB-1, BB-2, BB-7 | FB-1, FB-8 |
| About Us | Mission, vision, South Africa impact | BB-2 | FB-5 |
| Contact Us | Contact form / channel | BB-4, BB-9 | FB-6 |
| Help & Support | Central help, navigation guide, feature guides, troubleshooting | BB-1, BB-2, BB-3 | FB-2, FB-4 |
| FAQ | Ten listed questions, beginner-friendly answers | BB-1, BB-2 | FB-3 |
| Tutorial videos | Video/voice-over, accessible after a skip | BB-3, BF-7 | FF-6, FB-4 |
| Visual appearance | People/technology/AI imagery, not decoration | BB-1 (image keys), BB-7 | FB-8, FB-1, FB-2 |
| Verification | Upload, paste, citations, honest results, useful errors | BF-1, BF-2, BF-3, BF-4, BF-8, BB-8 | FF-7 |
| Logout | Log out in the hamburger menu | — (auth already correct) | FF-8 |
| Skill Roadmap (product feedback) | Roadmap reads as a journey, not a badge list; old items become achievements | BF-9, BB-10 | FF-11, FB-9 |
| Suggested priorities | Ordering followed | All P0 items first | All P0 items first |
| QA approach | Record, reproduce, retest, regression | QA record + tests on every task | QA record + tests on every task |

## Out of scope for this sprint

- Interview Practice for the three non-Legal tracks.
- Prompt Design task content and scoring.
- Admin panel *screens* for support content (API only here).
- A shareable or downloadable AI Readiness Passport. The roadmap shows the
  credential state only; issuing and verifying a passport is its own sprint.
- Custom roadmap paths per industry beyond wording — the five stages and the ten
  requirements are shared, so the tracker is comparable across tracks.
- Real-time analytics dashboards (the insights endpoint is enough for QA).
- Voice cloning or synthetic narration for walkthroughs (see the frontend note).
- **OCR and vision-model reading of scanned PDFs.** Decision taken for Sprint 2:
  text extraction only. Image-only documents are rejected with a clear remedy.
  Revisit only if QA round 2 confirms a scanned upload, and then as a contained
  fallback (page/time capped) rather than a rewrite of the pipeline.

## Risks

- **LLM provider flakiness** could still fail verification. Mitigation: typed
  errors, one repair attempt, a non-thinking profile, and no claim of certainty
  when checks did not run. The report is honest even when the provider is not.
- **Track-scoped progress migration** touches derived data. Run it on a staging
  copy, keep `user_progress` as the global XP store, and make the backfill
  reproducible from `task_attempts`.
- **Media hosting** may not be ready. The tour manifest ships with `media: null`
  and transcripts, so the feature is not blocked on video production.
- **Scope pressure** will push toward skipping BF-6. Do not: without it, industry
  switching is cosmetically fixed but still wrong, which is exactly what QA will
  retest.
- **Scanned PDFs remain unsupported** by design this sprint. The retest must use
  a text-based PDF; a scanned upload is expected to fail with
  `document_no_text`, and that is the correct behaviour, not a regression.
- **Extraction quality varies by producer.** Page-aware parsing and the quality
  flag reduce the risk, but a badly encoded PDF can still produce poor text.
  Keep the original file out of logs and make the report's limitations visible.
- **Roadmap content is easy to get wrong.** A requirement that no track can
  satisfy (an activity that does not exist, a capstone score above what the
  marker awards) locks the journey forever. Mitigation: seed targets from real
  data, assert in `roadmap.test.js` that every seeded milestone is reachable
  with the fixture learner, and review copy with the domain owner.
- **Two lists drifting back together.** The roadmap must never read XP, streaks
  or achievements, and achievements must never gate a stage. Review both
  endpoints in the same PR pair.
