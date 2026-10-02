<div align="center">

# VerifAI
### AI Workplace Readiness App

*Build the skills. Earn the trust. Advance your future.*

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Railway](https://img.shields.io/badge/Railway-0B0D0E?style=for-the-badge&logo=railway&logoColor=white)

</div>

---

## About the Project

VerifAI is a mobile application that measures and builds a graduate's readiness to work with AI in real jobs. Rather than teaching AI tools, VerifAI tests whether users can be trusted to use them — through real, employer-sourced workplace scenarios that assess judgement, verification, prompting, and risk governance.

Users receive AI-generated workplace tasks containing deliberate flaws or decisions. They identify the issue, correct it, and explain their reasoning. Each completed task updates their readiness profile across five competency dimensions.

### The Five Readiness Dimensions

| Dimension | What It Tests |
|---|---|
| **Verification** | Can you catch AI's mistakes and fix them? |
| **AI Judgement** | Do you know when AI should or shouldn't be used? |
| **Prompt Design** | Can you write prompts that get reliable, safe outputs? |
| **Risk & Governance** | Can you avoid privacy, bias, and compliance risks? |

### Industry Tracks
Finance · Legal · IT / Software · Business Consulting

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile Frontend | Flutter (Dart) |
| Backend API | Node.js + Express |
| Database | PostgreSQL (hosted on **Supabase**) |
| Authentication | Firebase Auth |
| Hosting | Railway (API), Supabase (database) |

**Architecture overview:**
- The Flutter app communicates with the Express REST API over HTTPS
- Firebase Auth handles user authentication client-side; the Express backend verifies tokens using the Firebase Admin SDK
- PostgreSQL stores users, industry tracks, pre-seeded tasks, scores per readiness dimension, and progress history
- The API and database are both deployed on Railway

---

## Project Structure

```
verifai/
├── mobile/              # Flutter app
│   ├── lib/
│   │   ├── screens/     # UI screens (Dashboard, Task, Feedback, Profile, etc.)
│   │   ├── widgets/     # Reusable components
│   │   ├── models/      # Data models
│   │   ├── services/    # API calls, Firebase Auth
│   │   └── main.dart
│   └── pubspec.yaml
│
├── backend/             # Node.js + Express API
│   ├── src/
│   │   ├── routes/      # API route handlers
│   │   ├── controllers/ # Business logic
│   │   ├── models/      # DB query functions
│   │   └── middleware/  # Auth verification, error handling
│   ├── db/
│   │   ├── schema.sql   # Table definitions
│   │   └── seed.sql     # Pre-seeded tasks and scenarios
│   ├── index.js
│   └── package.json
│
└── README.md
```

---

## Knowledge Graph (Graphify)

This repo ships an auto-generated **knowledge graph** of the codebase so the team can explore architecture instead of grepping files.

### What it does

`graphify` parses the code locally (tree-sitter AST — no data leaves your machine, no API cost) and builds:

```
graphify-out/
├── graph.html        # open in any browser — clickable, searchable graph
├── GRAPH_REPORT.md   # highlights, god nodes, community hubs
└── graph.json        # the queryable graph
```

The generated graph is **committed to the repo** so everyone on the team starts with a map. Only `graphify-out/cost.json` is git-ignored (local-only).

### Install (one-time, per contributor)

```bash
# 1. Install graphify (uses uv/tool env; the CLI command is `graphify`)
uv tool install graphifyy
uv tool update-shell   # if `graphify` isn't on PATH yet

# 2. Register the skill with your AI assistant
graphify install --platform opencode
```

> Prefer `uv`/`pipx` over plain `pip` to avoid environment conflicts.

### Querying the graph

```bash
graphify query "how does auth flow?"      # plain-language scoped question
graphify explain "SomeController"         # node + its edges
graphify path "User" "Score"              # shortest cross-file path
graphify update .                         # refresh after git pull
```

Or open `graphify-out/graph.html` in a browser and click around.

### Keeping the graph current

- **Git hooks** (`post-commit` / `post-checkout`) rebuild the graph automatically on every commit and branch switch. ⚠️ Hooks live in `.git/hooks/` and are **not** version-controlled, so each contributor must enable them once locally:
  ```bash
  graphify hook install
  ```
- After `git pull` (or a merge), run `graphify update .` to re-sync the graph with what you just pulled.
- Committed `graph.json` merges cleanly thanks to the `.gitattributes` merge driver.

---

## Git Workflow

We use a **feature branch workflow**. The `main` branch always reflects production-ready code. No one pushes directly to `main`.

### Branch naming

```
feature/   → new functionality         e.g. feature/task-screen
fix/       → bug fixes                 e.g. fix/score-calculation
chore/     → setup, config, tooling    e.g. chore/db-schema
```

### Step-by-step process

1. **Pull the latest main** before starting any work
   ```bash
   git checkout main
   git pull origin main
   ```

2. **Create a feature branch** from main
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Commit regularly** with clear, descriptive messages
   ```bash
   git add .
   git commit -m "feat: add task submission endpoint"
   ```

4. **Push your branch** and open a Pull Request on GitHub
   ```bash
   git push origin feature/your-feature-name
   ```

5. **Request a review** — at least one other team member must review and approve before merging

6. **Merge to main** only after approval — use "Squash and merge" to keep the history clean

> ⚠️ Never push directly to `main`. All changes go through a PR and review.

### CI (GitHub Actions)

Every push and every PR automatically runs the **Tests** workflow:

| Job | What it does |
|---|---|
| **Backend tests** | Installs backend deps and runs `npm test` (skips until a test script exists) |
| **Mobile tests** | `flutter pub get`, format check, `flutter analyze`, `flutter test` (skips until `mobile/test/` exists) |
| **Security tests** | `npm audit` for vulnerable dependencies + **gitleaks** secret scanning (fails on leaked keys/tokens) |
| **Tests summary** | Single gate — fails if any job failed |

PRs to `main` additionally require **owner approval** (`@Theodore-Gara`) via the `owner-approval` workflow. PRs should not be merged while any check is red.

### Avoiding merge conflicts (team playbook)

Conflicts come from branches living apart for too long — not from merges themselves. Follow these rules:

1. **Keep branches small and short-lived.** One feature = one branch = one PR. Aim to merge within **1–3 days**. Big features? Split them into slices (`feature/task-model` → merge → `feature/task-ui`).

2. **Sync your branch with main daily.** While your branch is open:
   ```bash
   git fetch origin
   git merge origin/main
   ```
   Small conflicts resolved today beat one giant merge-week disaster.

3. **Split work by files, not by layers.** Coordinate so people own disjoint areas of the codebase. Never have two people editing the same file (especially `main.dart`, `index.js`, or `package.json`/`pubspec.yaml`) at the same time — dependency files conflict constantly.

4. **Merge PRs quickly after approval.** First PR merged wins; the second one resolves the conflicts. Don't let approved PRs pile up.

5. **Never PR a huge branch whole.** If your branch is way ahead, break it into stacked/incremental PRs. A 40-file PR is unreviewable and conflict-prone.

#### Resolving a conflict (quick reference)

```bash
git checkout feature/your-branch
git fetch origin
git merge origin/main
# Git marks the conflicted files — open them, edit between <<<<<<< ======= >>>>>>>
git add <resolved-files>
git commit          # completes the merge
git push origin feature/your-branch
```

When in doubt, ask the person who wrote the other side of the conflict — don't guess their intent.

---

## Getting Started

### Prerequisites
- Flutter SDK (≥ 3.0)
- Node.js (≥ 18)
- PostgreSQL (local, or a **Supabase** project — this is what we use in production)
- Firebase project with Auth enabled
- Railway account
- Supabase account (hosts the PostgreSQL database)

### Backend setup

```bash
cd backend
npm install
cp .env.example .env   # Fill in: Supabase DATABASE_URL + Firebase Admin credentials
npm run dev
```

> `DATABASE_URL` comes from **Supabase → Project Settings → Database → Connection string**.
> Firebase Admin credentials come from **Firebase Console → Project Settings → Service accounts**.
> See `.env.example` for every variable the backend expects.
### Mobile setup

```bash
cd mobile
flutter pub get
flutter run
```

> **Firebase config files are NOT committed.** Download `google-services.json` (Android) and/or
> `GoogleService-Info.plist` (iOS) from Firebase Console → Project Settings, and place them at:
> - `mobile/android/app/google-services.json`
> - `mobile/ios/Runner/GoogleService-Info.plist`
>
> Both paths are git-ignored — never commit them (CI secret scanning will flag them).

### Database setup

Schema and seed data live in `backend/db/`. Run them against your Supabase Postgres instance
(via the Supabase SQL Editor, or locally with `psql`):

```bash
psql "$DATABASE_URL" -f backend/db/schema.sql
psql "$DATABASE_URL" -f backend/db/seed.sql
```

---

## Team — Group SE16

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
