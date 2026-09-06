# VerifAI Mobile App

Flutter-based mobile frontend for the VerifAI platform — AI Workplace Readiness App.

## Person 1 — Foundation Complete ✅

This branch (`chore/foundation`) establishes the complete app foundation. **Person 1 delivered significantly beyond the original scope.**

### Architecture

- **State Management**: Riverpod 2.6 (async notifiers, providers, streams, code generation)
- **Navigation**: GoRouter 13.2 with auth guards, redirect logic, IndexedStack bottom nav shell
- **Dependency Injection**: Provider-based DI with mock/real API client swap-ready interface
- **Code Generation**: Freezed + JSON Serializable + Riverpod Generator (build_runner)
- **Design System**: Complete theme matching brand guidelines (Manrope font, 8pt spacing, navy/green/cyan/xp-purple/gold palette)

### Core Packages

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `riverpod_generator` / `riverpod_annotation` | Compile-time provider generation |
| `go_router` | Declarative routing with auth guards |
| `dio` | HTTP client (ready for real backend) |
| `flutter_secure_storage` | Encrypted token/user persistence |
| `shared_preferences` | Mock user DB |
| `google_fonts` | Manrope typography |
| `fl_chart` | Charts (dashboard score ring, dimension bars) |
| `shimmer` | Loading placeholders |

### Design System (`lib/core/theme/`)

- **Colors**: Primary Navy `#0E1B2A`, Accent Green `#10B981`, Accent Cyan `#2DD4BF`, XP Purple `#7C3AED`, Gold `#F59E0B`, Silver/Bronze, semantic colors
- **Typography**: Manrope via `google_fonts` — full type scale (Display, H1–H3, Body, Label, Caption)
- **Spacing**: 8pt grid tokens (xs=4 ... xxxxxl=48) + component-specific (buttonHeight=52, inputHeight=52)
- **Radius**: Tokenized (xs=4 ... xxxl=24) with component mapping (button=12, input=10, card=16, badge=6, xl=20, xxl=24)
- **Theme**: Material 3 `ThemeData` with full component theming (buttons, inputs, cards, chips, progress, appBar, bottomNav)

### Shared Widgets (`lib/shared/widgets/`) — 10 Components

| Widget | Variants / Features |
|--------|---------------------|
| `VerifAIButton` | Primary (navy), Verification (green), Secondary (outline), Ghost; loading, full-width, icons |
| `VerifAIInput` | Email, Password, Text, Name — validation, obscure toggle, focus styling |
| `VerifAICard` | Elevated, Outlined, Filled; tap callbacks, custom padding/radius |
| `DimensionBar` | Horizontal progress with label/value, custom progress color |
| `ScoreRing` | Circular progress (120dp default, stroke 8), centered value display |
| `StreakBadge` / `StreakBadgeLarge` | Fire icon + day count; compact & large variants |
| `DailyTaskCard` | Task title, scenario, dimension/track chips, difficulty badge, Start CTA |
| `TaskChallengeModal` | Bottom sheet with 4-option verification, celebration dialog, XP/streak rewards |
| `XPBar` | Compact & full variants; level badge, gradient progress, XP text |
| `ShimmerLoader` / `ShimmerCard` / `ShimmerList` | Loading placeholders |
| `EmptyState` / `ErrorState` / `NoConnectionState` | Illustrations + retry CTAs |

### Models (Freezed + JSON Serializable) — 5 Models

| Model | Fields |
|-------|--------|
| `User` | id, email, name, trackId, trackName, hasCompletedOnboarding, createdAt |
| `IndustryTrack` | id, name, description |
| `DailyTask` | id, title, scenario, dimension, trackName, difficulty, trackId |
| `DashboardData` | overallScore, dimensionScores (map), streakDays, dailyTask |
| `AuthState` | unauthenticated, authenticated(user,token), needsOnboarding(user,token), loading |

### Mock Backend (Swap-Ready) — `ApiClient` Interface

`MockApiClient` implements `ApiClient` with 300–800ms simulated latency:
- `getTracks()` → 4 tracks (Finance, Legal, IT/Software, Business Consulting)
- `syncUser()` → generates mock JWT, persists user
- `getDashboard()` → realistic scores per dimension + streak + daily task
- `submitTask()` → score, feedback, XP earned

In-memory data seeded from schema. Swap to `RealDioClient` when backend ready.

### Secure Storage

`SecureStorageService` wraps `flutter_secure_storage`:
- Auth token, user profile, track selection, onboarding flag
- `getUserData()` / `saveUserData()` / `updateTrack()` / `clearAll()`

---

## Screens Implemented — 9 Screens

### Auth Flow (3)
| Screen | Route | Features |
|--------|-------|----------|
| **Splash** | `/splash` | 2s brand animation (fade/scale/slide), checks auth → routes to login/industry-select/dashboard |
| **Login** | `/login` | Email/password, validation, `authNotifierProvider`, Google placeholder, snackbar errors |
| **Register** | `/register` | Name + email + password + confirm, validation, auto-login → industry-select |

### Onboarding (1)
| Screen | Route | Features |
|--------|-------|----------|
| **Industry Select** | `/industry-select` | Grid of 4 track cards (tap highlight + continue), shimmer loading, persists to secure storage |

### Main App Shell — Bottom Navigation (4 tabs)

| Tab | Screen | Route | Features |
|-----|--------|-------|----------|
| **HQ** | Dashboard | `/dashboard` | ScoreRing (overall), 5 DimensionBars, StreakBadgeLarge, DailyTaskCard → TaskChallengeModal, pull-to-refresh, logout |
| **Track** | Track Roadmap | `/track` | 5 milestones (completed/active/locked), timeline with connectors, progress bar, XP rewards, start CTA |
| **Scores** | Scoreboard | `/scores` | Top 3 podium (gold/silver/bronze), Global/Track tabs, 10-entry leaderboard, current user highlighted, division league banner |
| **Profile** | Profile | `/profile` | Avatar + verified badge, stats (XP, streak, rank), 6 badges (3 unlocked/3 locked), stat boxes, logout, change track |

### Modals / Dialogs
- **TaskChallengeModal** — Bottom sheet (88% height), 4 verification options, animated selection, celebration dialog with XP/streak rewards
- **Celebration Dialog** — Gradient badge, rewards row (XP + streak), haptic feedback
- **Logout Dialog** — Confirmation with error-styled confirm

---

### Routing & Auth Guard (`lib/core/router/app_router.dart`)

```dart
/splash           → always accessible
/login, /register → only if unauthenticated
/industry-select  → authenticated + !hasCompletedOnboarding
/dashboard        → authenticated + hasCompletedOnboarding
/track            → authenticated + hasCompletedOnboarding (via MainNavShell)
/scores           → authenticated + hasCompletedOnboarding (via MainNavShell)
/profile          → authenticated + hasCompletedOnboarding (via MainNavShell)
```

Redirects use `AuthState.when()` pattern matching on `authStateProvider` (StreamProvider).

---

### Providers Structure

```
core/providers/app_providers.dart      # Dio, SharedPreferences, SecureStorage, ApiClient (mock)
features/auth/providers.dart           # authRepository, authState, currentUser, authNotifier
features/onboarding/providers.dart     # trackRepository, tracks, selectedTrack, selectTrack
features/dashboard/providers.dart      # dashboardRepository, dashboard, refreshDashboard
```

---

### Getting Started

```bash
cd mobile
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

> **Note**: Requires Flutter 3.13+. Enable Developer Mode on Windows for symlinks.

---

### What's Ready for Person 2 / Backend Integration

1. **All UI complete** — 9 screens, bottom nav, modals, all design system components
2. **Mock API interface defined** — `ApiClient` abstract class ready for real implementation
3. **Auth flow complete** — Mock auth with secure storage, ready for Firebase swap
4. **State management done** — Riverpod providers for all features
5. **Navigation done** — GoRouter with auth guards, IndexedStack bottom nav

### Person 2 Scope (Core Loop + Progress + Profile)
- Task Screen → Already implemented as `TaskChallengeModal` (bottom sheet with 4-option verification)
- Feedback Screen → Celebration dialog in modal already done; could expand to full screen
- Progress Screen → Scoreboard (leaderboard) + Profile stats + Track Roadmap already implemented
- Profile Screen → Fully implemented with badges, stats, logout, track switching
- Real Backend Integration → Replace `MockApiClient` with `DioClient` + Firebase ID token interceptor
- Firebase Auth → Swap mock auth for `firebase_auth` + Google Sign-In

---

### Project Structure

```
lib/
├── core/
│   ├── theme/           # app_colors, app_typography, app_spacing, app_radius, app_theme
│   ├── router/          # app_router (GoRouter + auth guard)
│   ├── services/        # api_client (interface), mock_api_client, secure_storage_service
│   └── providers/       # app_providers (DI container)
├── features/
│   ├── auth/
│   │   ├── data/        # auth_repository (mock)
│   │   ├── presentation/# splash, login, register screens
│   │   └── providers.dart
│   ├── onboarding/
│   │   ├── data/        # track_repository (mock)
│   │   ├── presentation/# industry_select screen
│   │   └── providers.dart
│   ├── dashboard/
│   │   ├── data/        # dashboard_repository (mock)
│   │   ├── presentation/# dashboard screen, task_challenge_modal
│   │   └── providers.dart
│   ├── navigation/
│   │   └── main_nav_shell.dart    # IndexedStack bottom nav (4 tabs)
│   ├── profile/
│   │   └── presentation/# profile screen
│   ├── scoreboard/
│   │   └── presentation/# scoreboard screen (podium + leaderboard)
│   └── track/
│       └── presentation/# track_roadmap_screen (milestone tree)
├── shared/
│   ├── models/          # 5 freezed models + json
│   ├── widgets/         # 10 reusable UI components + xp_bar
│   └── widgets.dart     # barrel export
└── main.dart            # ProviderScope + MaterialApp.router
```