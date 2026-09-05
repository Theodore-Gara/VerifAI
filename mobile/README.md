# VerifAI Mobile App

Flutter-based mobile frontend for the VerifAI platform — AI Workplace Readiness App.

## Foundation Complete (Person 1)

This branch (`chore/foundation`) establishes the complete app foundation for the frontend team.

### Architecture

- **State Management**: Riverpod 2.6 (async notifiers, providers, streams)
- **Navigation**: GoRouter 13.2 with auth guards and redirect logic
- **Dependency Injection**: Provider-based with mock/real API client swap
- **Code Generation**: Freezed + JSON Serializable + Riverpod Generator
- **Design System**: Custom theme matching brand guidelines (Manrope font, 8pt spacing, navy/green/cyan palette)

### Core Packages

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `go_router` | Declarative routing with auth guards |
| `dio` | HTTP client (ready for real backend) |
| `flutter_secure_storage` | Encrypted token/user persistence |
| `shared_preferences` | Mock user DB |
| `google_fonts` | Manrope typography |
| `fl_chart` | Dashboard charts (score ring, dimension bars) |
| `shimmer` | Loading placeholders |

### Design System (`lib/core/theme/`)

- **Colors**: Primary Navy `#0E1B2A`, Accent Green `#10B981`, Accent Cyan `#2DD4BF`, semantic colors
- **Typography**: Manrope via `google_fonts` — full type scale (Display, H1–H3, Body, Label, Caption)
- **Spacing**: 8pt grid tokens (xs=4 ... xxxxxl=48) + component-specific (buttonHeight=52, inputHeight=52)
- **Radius**: Tokenized (xs=4 ... xxxl=24) with component mapping (button=12, input=10, card=16)
- **Theme**: Material 3 `ThemeData` with full component theming (buttons, inputs, cards, chips, progress)

### Shared Widgets (`lib/shared/widgets/`)

| Widget | Variants |
|--------|----------|
| `VerifAIButton` | Primary (navy), Verification (green), Secondary (outline), Ghost |
| `VerifAIInput` | Email, Password, Text, Name — with validation, obscure toggle |
| `VerifAICard` | Elevated, Outlined, Filled |
| `DimensionBar` | Horizontal progress bar with label/value |
| `ScoreRing` | Circular progress (120dp, stroke 8) |
| `StreakBadge` / `StreakBadgeLarge` | Fire icon + day count |
| `DailyTaskCard` | Task title, scenario, dimension/track chips, difficulty badge, Start CTA |
| `ShimmerLoader` / `ShimmerCard` / `ShimmerList` | Loading placeholders |
| `EmptyState` / `ErrorState` / `NoConnectionState` | Illustrations + retry CTAs |

### Models (Freezed + JSON)

| Model | Fields |
|-------|--------|
| `User` | id, email, name, trackId, trackName, hasCompletedOnboarding, createdAt |
| `IndustryTrack` | id, name, description |
| `DailyTask` | id, title, scenario, dimension, trackName, difficulty, trackId |
| `DashboardData` | overallScore, dimensionScores (map), streakDays, dailyTask |
| `AuthState` | unauthenticated, authenticated(user,token), needsOnboarding(user,token), loading |

### Mock Backend (Swap-Ready)

`MockApiClient` implements `ApiClient` interface with:
- `getTracks()` → 4 tracks (Finance, Legal, IT/Software, Business Consulting)
- `syncUser()` → generates mock JWT, persists user
- `getDashboard()` → realistic scores per dimension + streak + daily task
- `submitTask()` → score, feedback, XP

In-memory delay 300–800ms. Swap to `RealDioClient` when backend ready.

### Secure Storage

`SecureStorageService` wraps `flutter_secure_storage`:
- Auth token, user profile, track selection, onboarding flag
- `getUserData()` / `saveUserData()` / `updateTrack()` / `clearAll()`

### Screens Implemented

| Screen | Route | State | Key Features |
|--------|-------|-------|--------------|
| **Splash** | `/splash` | Stateless + AnimationController | 2s brand animation (fade/scale/slide), checks auth → routes to login/industry-select/dashboard |
| **Login** | `/login` | ConsumerStateful | Email/password form, validation, `authNotifierProvider`, Google button placeholder, snackbar errors |
| **Register** | `/register` | ConsumerStateful | Name + email + password + confirm, validation, auto-login → industry-select |
| **Industry Select** | `/industry-select` | ConsumerStateful | Grid of 4 track cards (tap highlight + continue), shimmer loading, persist to secure storage |
| **Dashboard** | `/dashboard` | ConsumerStateful | ScoreRing (overall), 5 DimensionBars, StreakBadgeLarge, DailyTaskCard (Start→placeholder), pull-to-refresh, logout dialog |

### Routing & Auth Guard (`lib/core/router/app_router.dart`)

```dart
/splash           → always accessible
/login, /register → only if unauthenticated
/industry-select  → authenticated + !hasCompletedOnboarding
/dashboard        → authenticated + hasCompletedOnboarding
```

Redirects use `AuthState.when()` pattern matching on `authStateProvider` (StreamProvider).

### Providers Structure

```
core/providers/app_providers.dart      # Dio, SharedPreferences, SecureStorage, ApiClient (mock)
features/auth/providers.dart           # authRepository, authState, currentUser, authNotifier
features/onboarding/providers.dart     # trackRepository, tracks, selectedTrack, selectTrack
features/dashboard/providers.dart      # dashboardRepository, dashboard, refreshDashboard
```

### Getting Started

```bash
cd mobile
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

> **Note**: Requires Flutter 3.13+. Enable Developer Mode on Windows for symlinks.

### Next Steps (Person 2 / Backend Integration)

1. **Task Screen** — display AI scenario, flaw input, submit → feedback
2. **Feedback Screen** — per-dimension score, right/wrong explanation, XP animation
3. **Progress Screen** — fl_chart trends, streak history calendar
4. **Profile + Achievements** — user info, badges, logout
5. **Real Backend** — replace `MockApiClient` with `DioClient` + Firebase ID token interceptor
6. **Firebase Auth** — swap mock auth for `firebase_auth` + Google Sign-In

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
│   └── dashboard/
│       ├── data/        # dashboard_repository (mock)
│       ├── presentation/# dashboard screen
│       └── providers.dart
├── shared/
│   ├── models/          # freezed models + json
│   ├── widgets/         # all reusable UI components
│   └── widgets.dart     # barrel export
└── main.dart            # ProviderScope + MaterialApp.router
```