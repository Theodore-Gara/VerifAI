<div align="center">

# VerifAI
### AI Workplace Readiness App

*Build the skills. Earn the trust. Advance your future.*

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Render](https://img.shields.io/badge/Render-46E3B7?style=for-the-badge&logo=render&logoColor=white)

</div>

---

## 1. What the project is about

### The problem

Employers are adopting AI faster than graduates can be assessed on using it well. Tool
knowledge is easy to test and easy to forget; what actually determines whether a junior hire is
trustworthy with AI is **judgement** — catching a hallucinated citation, knowing when *not* to
automate a decision, spotting a privacy or bias risk before it reaches a client.

No CV states that, and no multiple-choice quiz measures it.

### What VerifAI does

VerifAI is an Android/iOS app that measures and builds a graduate's **AI workplace readiness**
through realistic, employer-style work: scenarios containing a flawed AI output or a judgement
call, where the learner has to find the problem, fix it, and justify the decision. Every graded
attempt feeds a live readiness profile — the number a recruiter could actually trust.

The app does not teach prompt tricks in isolation. It runs the full loop:

**learn the concept → practise a scenario → be assessed under exam conditions → see evidence of
your readiness → keep the habit going.**

### Who it is for

Final-year students, graduates and early-career professionals in four South African industry
tracks:

| Track | Example scenario |
|---|---|
| **Finance** | An AI-generated gross-profit summary with a payment that never arrived |
| **Legal** | A case summary citing a judgment that does not exist |
| **IT / Software** | AI-written code that silently swallows an exception |
| **Business Consulting** | An AI recommendation that ignores a client's POPIA obligations |

### The readiness model

Readiness is a single 0–100 score built from six weighted components. The weights are fixed per
track, so a learner cannot reach a high score by acing one module and skipping the rest —
**coverage counts**:

| Component | Weight | How the component score is earned |
|---|---|---|
| Verification | 0.30 | Share of that track's verification tasks passed |
| AI Judgement | 0.30 | Share of judgement tasks passed |
| Risk & Governance | 0.20 | Share of risk/governance tasks passed |
| Prompt Design | 0.10 | Scaffolded in the model; task content not yet authored |
| Interview | 0.10 | Share of the track's interview questions practised |
| Learning (AI Lab) | 0.20 | Average best capstone result |

The denominator is the sum of the weights for components the learner's track actually offers, so
an empty module can never silently cap someone below 100. A module that is offered but untouched
counts as zero coverage — which is the point.

The score maps to a tier, and the tier moves with the score (up or down):

| Tier | Readiness |
|---|---|
| Novice | 0–49 |
| Developing | 50–69 |
| Proficient | 70–84 |
| Advanced | 85–100 |

Progress mechanics sit on top of that: XP is score-proportional per difficulty, levels unlock
spendable reward tokens, achievements fire on milestones, and a daily streak (anchored to
`Africa/Johannesburg`, not the server's UTC clock) rewards consistency.

### Technology

| Layer | Technology |
|---|---|
| Mobile app | Flutter (Dart), Riverpod, go_router, Dio |
| API | Node.js 22 + Express |
| Database | PostgreSQL (Supabase), SQL schema + ledger-based migrations |
| Authentication | Firebase Auth (email/password and Google), verified server-side |
| AI | NVIDIA-hosted LLMs (analysis, chat, marking), with a fallback model |
| Live sources | Tavily web search (Verification Studio and Vera) |
| Hosting | Render (API, `render.yaml`), Supabase (database) |
| CI | GitHub Actions — backend tests, Flutter analyse/test, dependency audit, secret scan |

---

## 2. Codebase and project structure

The repository is a two-part application plus documentation:

```
VerifAI/
├── mobile/                     Flutter app (Android / iOS)
│   ├── lib/
│   │   ├── main.dart           App entry: Firebase, theme, resume-refresh hook
│   │   ├── core/
│   │   │   ├── router/         go_router: all routes and auth redirects
│   │   │   ├── theme/          Palette (light/dark), typography, spacing, radii
│   │   │   ├── providers/      Dio + ApiClient + auth interceptor wiring
│   │   │   └── services/       API client, error mapping, token refresh, SSE
│   │   ├── features/           One folder per feature (UI + providers + models)
│   │   │   ├── auth/ onboarding/ navigation/
│   │   │   ├── dashboard/ hubs/ task/ feedback/
│   │   │   ├── verification/ verification_studio/ judgement/ risk_governance/
│   │   │   ├── lab/ industry_practice/ interview/
│   │   │   ├── progress/ track/ scoreboard/ history/ rewards/
│   │   │   ├── vera/ assistant/ wellness/ profile/
│   │   └── shared/             Models and reusable widgets
│   ├── test/                   Widget, flow and unit tests
│   └── pubspec.yaml
│
├── backend/                    Express REST API
│   ├── app.js                  Middleware, routers, CORS, rate limits, /api/docs
│   ├── server.js               HTTP server + graceful shutdown
│   ├── routes/                 One router per resource (20 routers)
│   ├── controllers/            Request handling and SQL
│   ├── services/               Scoring, readiness, XP, streaks, LLM, parsing
│   ├── middleware/             Auth, roles, validation, SSE, rate limits, errors
│   ├── db/
│   │   ├── schema.sql          Full schema for a fresh database
│   │   ├── migrations/         Ledger-based incremental migrations (001–029)
│   │   ├── seed/               Curriculum, tasks, rewards, sources
│   │   └── pool.js             Shared pg pool (TLS aware)
│   ├── utils/                  Dates, HTTP caching, TTL cache, rate-limit store
│   ├── scripts/                Setup, migrate, local DB, purge, recompute
│   └── tests/                  186 tests (node:test + supertest)
│
├── render.yaml                 Render blueprint (migrate-then-start)
├── codemagic.yaml              Mobile build pipeline
├── AUDIT_REVIEW.md             Engineering audit and the fixes applied from it
├── BACKEND_TASKS.md            Backlog by area
└── FRONTEND_TASKS.md
```

### How the parts fit together

```
┌──────────────────────────────┐
│  Flutter app (iOS / Android) │
│  Riverpod state · go_router  │
└──────────────┬───────────────┘
               │ HTTPS + Firebase ID token
┌──────────────▼───────────────┐        ┌────────────────────┐
│  Express API (Render)        │───────▶│  NVIDIA LLM models │
│  auth · scoring · content    │        └────────────────────┘
│  rate limits · caching       │───────▶  Tavily web search
└──────────────┬───────────────┘
               │ pg pool
┌──────────────▼───────────────┐        ┌────────────────────┐
│  PostgreSQL (Supabase)       │◀──────▶│ Firebase Auth      │
│  users · tasks · attempts    │        │ token verification │
│  progress · content · lab    │        └────────────────────┘
└──────────────────────────────┘
```

Three conventions matter when reading the code:

1. **Feature-first mobile code.** A screen never talks to Dio directly; it reads a Riverpod
   provider, which calls an `ApiClient` method. That keeps the mockable seam in one place and
   makes widget tests possible without a network.
2. **The server is the source of truth.** Scores, XP, levels, readiness, tiers, streaks and
   "today" are computed server-side. The app renders what it is told.
3. **Schema changes are additive and recorded.** `schema.sql` describes a fresh database;
   everything after it arrives as a numbered migration, applied by a ledger script before the
   deployed server starts.

---

## 3. The app

VerifAI is a phone-first Flutter app (Material 3) with a calm, editorial visual language: soft
green and navy, bundled Inter/Manrope typography, ambient background washes and a floating
five-item dock. It supports **light, dark and system** appearance, respects the OS text scale, and
carries semantic labels on custom-drawn elements so screen readers can describe scores, streaks
and task cards.

The shell is deliberately shallow. Five areas are always one tap away; everything else is a
detail screen pushed from the area that owns it:

```
Home  ·  Learn  ·  Practice  ·  Progress  ·  Profile
```

A full index drawer is still available from the app bar as a **secondary** navigation source for
people who prefer a list (and for routes that are not part of the daily loop). It never replaces
the dock.

---

## 4. Feature walkthrough

### 4.1 Accounts, onboarding and identity

**What it does.** Sign-up, sign-in, password reset, industry-track selection, a five-step
welcome tour, and account deletion.

**How it works.** Firebase Auth handles credentials (email/password or Google). On first launch
the app signs in, then calls `POST /api/auth/sync`, which upserts the Firebase user into
PostgreSQL. A brand-new account has no track, so the router keeps it on the industry-selection
screen until a track is chosen; choosing one creates the `user_progress` row that everything else
writes to. Staff accounts are recognised through an `admin_roles` table (`owner`, `moderator`),
never through a client-side flag. Account deletion removes the profile and all learner data
through one purge path shared by the user and admin routes.

### 4.2 Home — the next action, not a dashboard of numbers

**What it does.** Opens on the one thing worth doing next: a recommended task with its dimension
and difficulty, a start/practise button, XP progress, streak and completed-task tiles, and the
readiness score with its tier.

**How it works.** One request (`GET /api/dashboard`) returns the profile, progress, dimension
scores and a single recommended task. Selection prefers unseen tasks in a difficulty band suited
to the learner's level; when a track has no unseen tasks left, the least-recently attempted task
is rotated back in and clearly labelled *Practise again*. Pull-to-refresh, an "updated just now"
hint and a resume-refresh hook keep the numbers honest.

### 4.3 Practice — scenario tasks

**What it does.** Three live skill areas (Verification, AI Judgement, Risk & Governance), each
with its own task runner and feedback.

**How it works.** A scenario is served without the answer key. The learner either picks the
defective line(s) and writes the fix and reason (Verification, line-text format), chooses the
correct answer, or makes a decision plus a justification (Judgement / Risk). The server scores
the submission, decides pass/fail against per-dimension thresholds, writes the attempt and an
analytics log row in the same statement, updates skill coverage, recomputes readiness and tier,
awards XP and tokens, advances the streak and grants any newly earned achievements — all inside
one transaction, then returns the feedback the learner sees.

Verification line-text answers have a stricter rule: the learner must reach 70 *and* score
non-zero on both the flaw and the fix, so a plausible explanation alone can never pass a task
whose point is the correction.

### 4.4 Verification Studio

**What it does.** The open-ended companion to the scenarios: paste an AI answer, upload a
document (PDF/DOCX up to 5 MB), drop in a link, or give a citation, and receive a structured
verification report.

**How it works.** Inputs are resolved into one evidence document — documents are parsed on a
separate worker process (with a page and byte cap), links are fetched and stripped to text,
citations trigger a live web search. The model is asked for a strict JSON report
(overall status, items requiring review, sources confirmed, summary), which is validated and
normalised rather than trusted. Analyses are stored as metadata and report only; the submitted
material itself is never persisted.

### 4.5 AI Lab — lessons, practice and capstones

**What it does.** A short AI-literacy curriculum with chapters, topics, practice activities, a
source library with licence metadata, and timed capstone assessments.

**How it works.** Lessons are track-specific or global, and progress is recorded per section and
per activity. Capstones are exam conditions: a time limit, a maximum number of attempts, a
pass mark and an XP/token reward. Objective questions (multiple choice, multi-select, matching,
numeric) are auto-marked; extended and rubric answers are held for moderator marking, and the AI
can suggest rubric marks to speed that up without finalising it. A completed capstone feeds
both Learning readiness and the learner's badge collection.

### 4.6 Interview practice

**What it does.** A per-track question bank with model answers, what employers are testing, and a
"practised" marker.

**How it works.** Marking a question practised is idempotent, updates interview coverage and
triggers a readiness recompute — which is why interview practice is worth 10% of readiness rather
than being a passive reading list.

### 4.7 Industry practice cases

**What it does.** Longer workplace cases — the kind of written brief a new hire actually receives
— with a recorded decision and a read state.

**How it works.** Cases are served per track; opening one is tracked so the app can distinguish
"not started" from "read". They are deliberately unscored: they build context for the scored
scenarios.

### 4.8 Progress — evidence, not vanity metrics

**What it does.** Readiness breakdown by dimension, XP and level progress, a daily activity chart,
the track roadmap of milestones, full attempt history, and the leaderboard.

**How it works.** Progress and activity come from the stored `skill_scores` and a shared
`user_activity` view (task attempts, lab practice and capstones projected into one timeline).
History is paginated and supports search and type filters; opening an entry re-fetches that
attempt so feedback survives an app restart or a deep link (`/feedback/:attemptId`). The
leaderboard supports global and per-track scopes and shows the learner's own rank.

### 4.9 Rewards

**What it does.** A catalogue of rewards with a token wallet, redemption and a token ledger.

**How it works.** XP is never spent; **tokens** are. Tokens are granted for each level gained and
for each achievement, written to an append-only ledger whose unique `(user, reason, ref)` key
makes every grant idempotent — a retried submission cannot double-credit. Redeeming a reward
checks and debits the balance atomically and records the redemption.

Each product carries a photograph in the catalogue: the API returns only the file name
(`rewards.image_asset`), and the picture ships in the app bundle, so rows render instantly and
survive a dead connection. `RewardImage` resolves the name against `assets/images/` and falls
back to a gift glyph if a new catalogue entry has no artwork yet. The nine photos are original
project artwork (see `mobile/assets/images/CREDITS.md`); they illustrate a concept rather than a
live offer, which the product page states alongside the note.

### 4.10 Vera and the in-task assistant

**What it does.** Vera is the app-wide AI coach; the assistant appears inside a task to help the
learner reason without handing them the answer.

**How it works.** Both stream replies over server-sent events so the first token appears
immediately, with keep-alive pings and upstream cancellation when the client disconnects. Vera
keeps sessions and a small, inspectable memory (the learner can add and delete memories), offers
tips, and receives a bounded context: readiness, recent activity, wellness signals and privacy
guidance. Long conversations are compacted into a running summary before they exceed the model's
context window.

### 4.11 Wellness Centre

**What it does.** Daily mood check-ins, a private journal with undo, self-care activities, a
breathing exercise and a weekly summary.

**How it works.** Mood and journal are one row per learner per day (upsert on the date), journal
entries are soft-deleted and restorable, and the weekly count is derived from live entries rather
than a counter. Dates are the **server's** configured day, so a check-in made just after midnight
cannot land on yesterday because the phone's clock disagrees. The content is private to the
learner; Vera only receives what is needed to be supportive, with explicit privacy guidance.

### 4.12 Profile and settings

**What it does.** Identity, track change, profile photo, appearance (light/dark/system), the
staff entry point to the admin portal, and account deletion.

**How it works.** Preferences are persisted locally and applied through the theme layer;
changing track reuses the onboarding repository and invalidates the progress-backed providers so
the app re-reads content for the new track.

### 4.13 Admin and moderation

**What it does.** A staff-only back office for the people who run the content and keep the
platform healthy. The mobile app is the entry point: staff see an *Admin Panel* action on their
profile that opens the browser-based portal, which runs separately and talks to `/api/admin` in
this repository.

**How it works.** The API is guarded by Firebase auth plus role checks (`owner`, `moderator`). It
covers:

- **Overview and analytics** — active learners, signups, funnel, per-track progress, answer
  summaries, system configuration.
- **Task management** — create, edit, bulk import (validated, with a dry-run mode), approve or
  reject drafts, inspect answers, delete.
- **Users** — search, inspect, suspend/reactivate, grant XP, export, delete, and mirror a
  Firebase disable.
- **Moderation** — reported workshop posts, moderation actions and an audit trail.
- **Content** — lab lessons and sections.
- **Configuration** — maintenance mode, feature flags, and admin grants (owner only).
- **CSV exports** — users, attempts and track progress for reporting.

Every privileged action is written to the moderation log with the acting staff uid and a reason.

### 4.14 Workshop (API)

The backend also ships a per-track community workshop — threads, replies, reactions, reports and
moderation endpoints — so learners can discuss cases with peers. It is not yet surfaced in the
mobile navigation; the moderation side is already available to staff.

---

## 5. User flow and navigation

### First run

```
Splash → Welcome tour (5 steps) → Sign in / Register
      → Industry selection → Home (dashboard)
```

The router enforces this: unauthenticated users are redirected to `/login`, authenticated users
without a track are held on `/industry-select`, and everyone else lands on `/dashboard`. A
signed-out or suspended session is detected by the auth interceptor, cleared, and routed back to
login.

### The daily loop

```
Home ── "Start task" ─▶ Task runner ─▶ Submit ─▶ Feedback
  ▲                                                │
  └──────────── dashboard refreshed ◀──────────────┘
```

1. Home recommends the next task (or the next practice rotation).
2. The learner answers, then submits.
3. The server scores and updates readiness, XP, streak, achievements and tokens.
4. Feedback explains what was right or missed and offers the next action.
5. Returning Home shows the updated readiness, XP and a new recommendation.

### Navigation map

| Area | Destinations |
|---|---|
| **Home** | Dashboard; drawer; task runner; feedback |
| **Learn** | AI Lab lessons → chapters → topics (with their sources); recall practice; capstone assessments → paper → results; the track roadmap; Ask Vera |
| **Practice** | Verification, AI Judgement, Risk & Governance scenarios; Verification Studio; interview practice; industry cases; task history → attempt feedback |
| **Progress** | Readiness breakdown, XP/level, activity chart, leaderboard, milestones, history, rewards |
| **Profile** | Account, track, photo, appearance, wellness centre, Vera, admin (staff), sign out, delete account |

The drawer mirrors these as a grouped list (Learn / Practice / Progress / Account) for people who
prefer an index; choosing a destination there still returns to the same shell rather than
stacking a second one.

### Data freshness

Long-lived providers keep tab switches instant. A resume hook invalidates the learner's data
providers when the app returns to the foreground (throttled to once every 30 seconds), and the
screens that matter most offer pull-to-refresh. Nothing loops in the background.

---

## 6. How it is engineered

### API surface

All routes are under `/api` and return a `request_id` for tracing.

| Group | Responsibility |
|---|---|
| `/auth`, `/users`, `/tracks` | Sign-in sync, profile, track catalogue |
| `/dashboard` | One composed payload for Home |
| `/tasks`, `/progress`, `/history` | Task selection, submissions, readiness, timeline |
| `/achievements`, `/leaderboard`, `/rewards` | Gamification and the token economy |
| `/verification`, `/interview`, `/industry-practice` | Studio, interview bank, cases |
| `/lab` | Lessons, activities, capstone assessments and marking |
| `/assistant`, `/vera` | Streaming task help and the app-wide coach |
| `/wellness` | Mood, journal and self-care |
| `/workshop` | Community threads, replies, reports |
| `/admin` | Staff operations (roles required) |
| `/health` | Liveness plus a database ping |

`GET /api/docs` lists the endpoint groups; the routers themselves are the source of truth.

### The scoring pipeline

A submission moves through a single transaction with a bounded number of round trips:

1. Load the learner and the task (with its content and options).
2. Score the answer by format and apply the pass rule for that dimension.
3. Write the attempt **and** its analytics log row in one statement.
4. Recompute that feature's coverage (passed tasks / available tasks; a practice-only pass counts
   as half) and, only if coverage actually moved, recompute readiness in a single statement whose
   inputs are JSON aggregates.
5. Award XP, level, tokens and streak through one service; grant any new achievements in one
   statement, with token grants batched.
6. Commit and return the feedback, new totals and any achievements earned.

### Performance and reliability decisions

- **One dashboard request** instead of five, three of which ran an expensive task-selection query
  and were then discarded.
- **Read-heavy payloads are cached** in-process for 60 seconds (analytics, leaderboard, static
  catalogues) and static endpoints send `ETag`/`max-age` so the app can revalidate cheaply.
- **Rate limits are counted per account** and stored in PostgreSQL, so two API instances share
  one budget instead of giving each user double the quota.
- **Document parsing runs off the request thread** in a small pool of child processes, with a
  byte cap, a page cap, a queue limit and a timeout — a large upload can no longer block every
  other request.
- **Streaming aborts upstream work** when the client goes away, and sends keep-alive pings during
  long model silences.
- **Indexes follow the queries** (`submitted_date`, partial history indexes, leaderboard ordering)
  and analytics group on stored dates rather than recomputing a timezone conversion per row.

### Security

- Every protected route verifies a Firebase ID token; the uid is resolved to a local user row
  once per request by shared middleware.
- Admin routes additionally require a role from the database; a moderator cannot grant
  themselves owner rights.
- Request bodies are size-capped per route, inputs are validated and clamped centrally, and SQL
  is parameterised throughout.
- The server never stores submitted verification material, never returns the answer key before a
  submission, and keeps model/API keys server-side only.
- Secrets live in environment variables (`backend/.env.example` documents every one); Firebase
  service-account files, `.env` files and mobile Firebase config are git-ignored, and CI runs
  gitleaks.

### Testing and CI

| Check | Scope |
|---|---|
| `cd backend && npm test` | **186 tests** — routing, auth/authorisation, scoring, readiness, capstones, wellness, rewards, lab, admin, streaming |
| `cd mobile && flutter analyze` | Static analysis; currently clean |
| `cd mobile && flutter test` | **55 tests** — auth interceptor, login/onboarding flows, task submission, lab navigation, judgement, wellness, navigation shell and a 200% text-scale regression |

GitHub Actions runs the backend suite, the Flutter format/analyze/test jobs, `npm audit` and a
gitleaks secret scan on every push and pull request. `codemagic.yaml` builds the mobile artefacts.

### Running it locally

```bash
# API
cd backend
npm install
cp .env.example .env        # DATABASE_URL, Firebase Admin, NVIDIA_API_KEY
npm run db:setup            # schema + migrations + seed (first time)
npm run db:migrate          # migrations only
npm run dev                 # http://localhost:3000

# App
cd mobile
flutter pub get
flutter run                 # add --dart-define=API_BASE_URL=http://<host>:3000/api/
```

The app talks to the deployed API by default; point it at localhost with the dart-define above.
Firebase config files are downloaded from the Firebase console and are never committed.

---

## 7. Limitations and next steps

Stated plainly, because a marker should not have to discover them:

- **Prompt Design** is present in the data model, readiness weights and feature map, but no task
  content has been authored for it (task creation rejects it for now) — the three live dimensions
  carry the score today.
- **Workshop** is complete on the API side but has no mobile screen.
- The backend test suite mocks PostgreSQL, so SQL-level regressions are caught by review and the
  schema itself rather than by an integration suite. Adding one embedded-Postgres suite is the
  highest-value testing next step.
- Offline mode is not implemented; a dropped connection surfaces an inline retry rather than a
  cached read.
- Content authoring still goes through the admin portal and seed files rather than a dedicated
  CMS workflow.

---

## 8. Conclusion

VerifAI turns a vague hiring question — *"can this graduate be trusted with AI?"* — into
something measurable. The learner works through realistic, flawed AI output; the system scores
the judgement behind the answer, not just the answer; and the result accumulates into a readiness
score, a tier and a body of evidence that an employer can inspect.

The project also demonstrates the engineering that makes such a product viable: a single
authoritative scoring pipeline, a schema that evolves through reviewed migrations, AI features
that stream and degrade gracefully, server-side authorisation for every privileged action, and a
mobile experience designed for the daily habit rather than a one-off demo.

---

## 9. Team — Group SE16

| Name | Student Number |
|---|---|
| Meshaque Kalonji | Eduv4967541 |
| Vusani Earl Mulaudzi | Eduv4915768 |
| Theodore Nangara | Con-1484616-v7z6 |
| Lwandle Naledi Chloe Mvelase | Con-1186453-hlz6 |
| Mpho Mokoena | Be.2023.m4g9b8 |

**Module:** ITMDA3-34 — Project: Mobile Application and Web Services
**Campus:** Bedfordview, Eduvos
**Lecturer:** Mpho Thobejane

---

<div align="center">

*VerifAI — Helping Africa's graduates become the most trusted AI-ready talent in the world.*

</div>
