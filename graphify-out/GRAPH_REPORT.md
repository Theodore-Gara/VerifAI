# Graph Report - VerifAI  (2026-09-30)

## Corpus Check
- 136 files · ~73,421 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 61 file(s) not represented in the graph (top: (none) 14, .xml 9, .plist 8)

## Summary
- 1251 nodes · 1693 edges · 106 communities (83 shown, 23 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 46 edges (avg confidence: 0.87)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `7f7a2c0c`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- package.json
- daily_task_card.dart
- AppDelegate
- app_colors.dart
- VerifAI
- scoreboard_screen.dart
- dashboard_screen.dart
- Screens Implemented — 9 Screens
- score_ring.dart
- main_nav_shell.dart
- app_spacing.dart
- tasksController.js
- track_roadmap_screen.dart
- secure_storage_service.dart
- @company
- my_application.cc
- verifai_input.dart
- auth_repository.dart
- utils.cpp
- auth/providers.dart
- user.dart
- win32_window.cpp
- industry_select_screen.dart
- register_screen.dart
- VerifAI Backend — Beginner User Manual
- dashboard_data.dart
- api_client.dart
- splash_screen.dart
- auth_state.dart
- daily_task.dart
- mock_api_client.dart
- verifai_button.dart
- shimmer_loader.dart
- app_providers.dart
- verifai_card.dart
- task_challenge_modal.dart
- empty_state.dart
- app.js
- app_router.dart
- industry_track.dart
- dashboard/providers.dart
- currentUserProvider
- Win32Window
- package:flutter/material.dart
- MessageHandler
- ConsumerState
- Endpoints
- widgets.dart
- manifest.json
- MessageHandler
- profile_screen.dart
- pool.js
- package:verifai/shared/models.dart
- State
- track_repository.dart
- onboarding/providers.dart
- @freezed
- windows/flutter/generated_plugin_registrant.cc
- generate_app_icons.py
- schema.sql
- FlutterWindow
- firebase.js
- models.dart
- @JsonSerializable
- VerifAI Deliverable 4 Backend Handoff
- auth/presentation.dart
- Point
- main
- FlutterActivity
- c_users_theod_verifai_mobile_ios_runner_generatedpluginregistrant_h
- LaunchImage.imageset/README.md
- dashboard/presentation.dart
- onboarding/presentation.dart
- @JsonKey
- VerifAI Backend — Deliverable 4
- fromJson
- _dailyTaskFromJson
- _dailyTaskToJson
- fromJson
- fromJson
- fromJson
- String?
- routes/auth.js
- dependencies
- check.js
- achievements.js
- progress.js
- deploy
- flutter_window.h
- _MyApplication
- Person 1 — Foundation Complete ✅
- Railway Deployment Checklist
- scripts
- linux/flutter/generated_plugin_registrant.cc
- VerifAI Backend Audit — Deliverable 4
- server.js
- pull_request_template.md
- my_application.h
- TEST_MATRIX.md
- firebase_auth_plugin_c_api
- firebase_core_plugin_c_api

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 24 edges
2. `VerifAI Backend — Beginner User Manual` - 16 edges
3. `authNotifierProvider` - 12 edges
4. `MessageHandler` - 12 edges
5. `Screens Implemented — 9 Screens` - 11 edges
6. `Endpoints` - 10 edges
7. `VerifAI Deliverable 4 Backend Handoff` - 10 edges
8. `users` - 10 edges
9. `FlutterWindow` - 10 edges
10. `main()` - 10 edges

## Surprising Connections (you probably didn't know these)
- `GitHub status` --references--> `main()`  [INFERRED]
  backend/PROJECT_HANDOFF.md → mobile/linux/runner/main.cc
- `Git workflow` --references--> `main()`  [INFERRED]
  backend/README.md → mobile/linux/runner/main.cc
- `Checklist` --references--> `main()`  [INFERRED]
  .github/pull_request_template.md → mobile/linux/runner/main.cc
- `Contributing to the VerifAI Backend` --references--> `main()`  [INFERRED]
  backend/CONTRIBUTING.md → mobile/linux/runner/main.cc
- `2. Important project rule` --references--> `main()`  [INFERRED]
  backend/USER_MANUAL.md → mobile/linux/runner/main.cc

## Import Cycles
- None detected.

## Communities (106 total, 23 thin omitted)

### Community 0 - "package.json"
Cohesion: 0.10
Nodes (18): description, devDependencies, jest, nodemon, supertest, main, name, version (+10 more)

### Community 1 - "daily_task_card.dart"
Cohesion: 0.10
Nodes (21): _TrackCard, build, DailyTaskCard, dimension, _DimensionChip, _formatDimension, _getDifficultyColor, _getDimensionColor (+13 more)

### Community 2 - "AppDelegate"
Cohesion: 0.06
Nodes (27): Any, Cocoa, Flutter, flutter_secure_storage_macos, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterMacOS (+19 more)

### Community 3 - "app_colors.dart"
Cohesion: 0.04
Nodes (42): app_colors.dart, app_radius.dart, app_spacing.dart, app_typography.dart, accentCyan, accentGreen, accentLight, ambientCyan (+34 more)

### Community 4 - "VerifAI"
Cohesion: 0.11
Nodes (18): About the Project, AI Workplace Readiness App, Backend setup, Database setup, Getting Started, Industry Tracks, Install (one-time, per contributor), Keeping the graph current (+10 more)

### Community 5 - "scoreboard_screen.dart"
Cohesion: 0.13
Nodes (14): _buildLeaderboardTile, _buildPodiumSpot, createState, dispose, initState, isCurrentUser, _LeaderboardEntry, name (+6 more)

### Community 6 - "dashboard_screen.dart"
Cohesion: 0.09
Nodes (22): _buildDashboard, _buildShimmer, createState, _playTask, build, days, label, showIcon (+14 more)

### Community 7 - "Screens Implemented — 9 Screens"
Cohesion: 0.08
Nodes (24): 1. Visual Philosophy & Core Pillars, 2. Design Tokens Reference, 3. Key Component Usage Guidelines, 4. Git Collaborator Guide (Rules for Adding Code), Auth Flow (3), Border Radii (`lib/core/theme/app_radius.dart`), Color Palette (`lib/core/theme/app_colors.dart`), `DailyTaskCard` (`lib/shared/widgets/daily_task_card.dart`) (+16 more)

### Community 8 - "score_ring.dart"
Cohesion: 0.11
Nodes (17): CustomPainter, build, child, color, _getDefaultTier, _getScoreColor, maxScore, _ModernScoreRingPainter (+9 more)

### Community 9 - "main_nav_shell.dart"
Cohesion: 0.12
Nodes (15): dart:ui, List, build, _buildNavItem, createState, _currentIndex, initialIndex, initState (+7 more)

### Community 10 - "app_spacing.dart"
Cohesion: 0.06
Nodes (32): AppRadius, badge, button, card, fab, input, lg, md (+24 more)

### Community 11 - "tasksController.js"
Cohesion: 0.10
Nodes (31): awardAchievements(), getCurrentUser(), getNextTask(), pool, { positiveIntegerParam, requiredString }, preferredDifficulties(), { scoreAnswer, calculateXp, calculateLevel }, submitAttempt() (+23 more)

### Community 12 - "track_roadmap_screen.dart"
Cohesion: 0.18
Nodes (10): _buildMilestoneCard, _buildNodeIndicator, description, icon, _Milestone, MilestoneStatus, status, title (+2 more)

### Community 13 - "secure_storage_service.dart"
Cohesion: 0.05
Nodes (41): core/router/app_router.dart, core/theme/app_theme.dart, firebase_options.dart, routerProvider, clearAll, deleteAuthToken, email, getAuthToken (+33 more)

### Community 15 - "my_application.cc"
Cohesion: 0.19
Nodes (12): GApplication, gboolean, gchar, gdkx, GObject, my_application_activate(), my_application_class_init(), my_application_dispose() (+4 more)

### Community 16 - "verifai_input.dart"
Cohesion: 0.08
Nodes (24): FocusNode?, FormFieldValidator, build, controller, createState, dispose, enabled, focusNode (+16 more)

### Community 17 - "auth_repository.dart"
Cohesion: 0.09
Nodes (22): _apiClient, AuthRepository, authStateChanges, _authStateController, completeOnboarding, dispose, _ensureSeedUsers, getCurrentUser (+14 more)

### Community 18 - "utils.cpp"
Cohesion: 0.18
Nodes (13): flutter_windows, _In_, _In_opt_, io, iostream, wWinMain(), string, wchar_t (+5 more)

### Community 19 - "auth/providers.dart"
Cohesion: 0.13
Nodes (21): AsyncNotifier, apiClient, AuthNotifier, authRepositoryProvider, build, completeOnboarding, getCurrentUser, login (+13 more)

### Community 20 - "user.dart"
Cohesion: 0.11
Nodes (18): bool get, createdAt, email, hasCompletedOnboarding, hashCode, id, name, operator (+10 more)

### Community 21 - "win32_window.cpp"
Cohesion: 0.16
Nodes (15): dwmapi, wchar_t, Scale(), Create, Destroy, SetQuitOnClose, Show, UpdateTheme (+7 more)

### Community 22 - "industry_select_screen.dart"
Cohesion: 0.12
Nodes (18): build, _buildShimmerList, _buildTracksList, createState, _getTrackIcon, _getTrackPerk, _handleContinue, IndustrySelectScreen (+10 more)

### Community 23 - "register_screen.dart"
Cohesion: 0.10
Nodes (24): FormState, build, createState, dispose, _emailController, _formKey, _handleGoogleSignIn, _handleLogin (+16 more)

### Community 24 - "VerifAI Backend — Beginner User Manual"
Cohesion: 0.08
Nodes (23): 10. How the attempt flow works, 11. GitHub — safest beginner workflow, 12. Railway deployment, 13. Common problems, 14. What must never be committed, 15. Final pre-submission checklist, 1. What this backend does, 3. Prerequisites (+15 more)

### Community 25 - "dashboard_data.dart"
Cohesion: 0.12
Nodes (15): dailyTask, dimensionScores, hashCode, operator, overallScore, _privateConstructorUsedError, streakDays, toJson (+7 more)

### Community 26 - "api_client.dart"
Cohesion: 0.12
Nodes (15): answer, AuthSyncResponse, explanation, feedback, getDashboard, getTracks, score, submitTask (+7 more)

### Community 27 - "splash_screen.dart"
Cohesion: 0.13
Nodes (16): Animation, AnimationController, build, _controller, createState, dispose, _fadeAnimation, initState (+8 more)

### Community 28 - "auth_state.dart"
Cohesion: 0.13
Nodes (14): _, hashCode, operator, _privateConstructorUsedError, token, toString, user, authenticated (+6 more)

### Community 29 - "daily_task.dart"
Cohesion: 0.13
Nodes (14): difficulty, dimension, hashCode, id, operator, _privateConstructorUsedError, scenario, title (+6 more)

### Community 30 - "mock_api_client.dart"
Cohesion: 0.13
Nodes (14): dart:async, dart:math, Map, _dailyTasks, _delay, _dimensionScores, getDashboard, getTracks (+6 more)

### Community 31 - "verifai_button.dart"
Cohesion: 0.13
Nodes (14): build, createState, height, isFullWidth, isLoading, _isPressed, label, leadingIcon (+6 more)

### Community 32 - "shimmer_loader.dart"
Cohesion: 0.14
Nodes (13): BorderRadius?, EdgeInsetsGeometry?, borderRadius, build, card, height, itemCount, itemHeight (+5 more)

### Community 33 - "app_providers.dart"
Cohesion: 0.10
Nodes (23): dart:convert, Dio, apiClientProvider, dio, dioProvider, getInstance, secureStorageProvider, sharedPreferencesProvider (+15 more)

### Community 34 - "verifai_card.dart"
Cohesion: 0.14
Nodes (13): backgroundColor, borderRadius, build, child, _getBackgroundColor, _getBorder, _getShadow, margin (+5 more)

### Community 35 - "task_challenge_modal.dart"
Cohesion: 0.17
Nodes (11): build, createState, _handleSubmit, _isSubmitting, onTaskCompleted, _options, _selectedOptionIndex, show (+3 more)

### Community 36 - "empty_state.dart"
Cohesion: 0.17
Nodes (11): actionLabel, actionVariant, build, EmptyState, icon, message, onAction, onRetry (+3 more)

### Community 37 - "app.js"
Cohesion: 0.11
Nodes (15): achievementRoutes, allowedOrigins, app, authRoutes, cors, errorHandler, express, healthRoutes (+7 more)

### Community 38 - "app_router.dart"
Cohesion: 0.17
Nodes (11): AsyncValue, ChangeNotifier, GoRouter, GoRouterRefreshNotifier, notify, refreshNotifier, router, package:go_router/go_router.dart (+3 more)

### Community 39 - "industry_track.dart"
Cohesion: 0.14
Nodes (12): description, hashCode, id, name, operator, _privateConstructorUsedError, toJson, toString (+4 more)

### Community 40 - "dashboard/providers.dart"
Cohesion: 0.17
Nodes (11): DashboardData, apiClient, dashboardRepositoryProvider, getDashboard, refreshDashboard, refreshDashboardProvider, repository, DashboardData (+3 more)

### Community 41 - "currentUserProvider"
Cohesion: 0.24
Nodes (10): ConsumerWidget, currentUserProvider, build, DashboardScreen, _DashboardScreenState, dashboardProvider, ProfileScreen, build (+2 more)

### Community 42 - "Win32Window"
Cohesion: 0.24
Nodes (12): OnCreate, OnDestroy, HWND, Win32Window, child_content_, GetClientArea, OnCreate, OnDestroy (+4 more)

### Community 43 - "package:flutter/material.dart"
Cohesion: 0.33
Nodes (5): AppTypography, textTheme, package:flutter/material.dart, package:google_fonts/google_fonts.dart, static TextTheme get

### Community 44 - "MessageHandler"
Cohesion: 0.18
Nodes (10): generated_plugin_registrant, DartProject, HWND, LPARAM, LRESULT, UINT, WPARAM, FlutterWindow::FlutterWindow() (+2 more)

### Community 45 - "ConsumerState"
Cohesion: 0.28
Nodes (9): ConsumerState, ConsumerStatefulWidget, LoginScreen, _LoginScreenState, RegisterScreen, _RegisterScreenState, ScoreboardScreen, _ScoreboardScreenState (+1 more)

### Community 46 - "Endpoints"
Cohesion: 0.12
Nodes (15): Authentication, Database setup, Endpoints, Error format, GET /api/achievements/me, GET /api/health, GET /api/progress/me, GET /api/tasks/next (+7 more)

### Community 47 - "widgets.dart"
Cohesion: 0.18
Nodes (10): package:verifai/shared/widgets/daily_task_card.dart, package:verifai/shared/widgets/dimension_bar.dart, package:verifai/shared/widgets/empty_state.dart, package:verifai/shared/widgets/score_ring.dart, package:verifai/shared/widgets/shimmer_loader.dart, package:verifai/shared/widgets/streak_badge.dart, package:verifai/shared/widgets/verifai_button.dart, package:verifai/shared/widgets/verifai_card.dart (+2 more)

### Community 48 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 49 - "MessageHandler"
Cohesion: 0.36
Nodes (10): HWND, LPARAM, LRESULT, UINT, WPARAM, EnableFullDpiSupportIfAvailable(), GetHandle, GetThisFromHandle (+2 more)

### Community 50 - "profile_screen.dart"
Cohesion: 0.11
Nodes (18): Color?, IconData?, _Badge, _buildBentoStat, _buildModernBadgeTile, color, description, icon (+10 more)

### Community 51 - "pool.js"
Cohesion: 0.15
Nodes (11): getTracks(), pool, { Pool }, express, pool, router, express, { getTracks } (+3 more)

### Community 52 - "package:verifai/shared/models.dart"
Cohesion: 0.29
Nodes (7): _apiClient, DashboardRepository, getDashboard, MockDashboardRepository, refreshDashboard, package:verifai/core/services/api_client.dart, package:verifai/shared/models.dart

### Community 53 - "State"
Cohesion: 0.27
Nodes (10): TaskChallengeModal, _TaskChallengeModalState, MainNavShell, _MainNavShellState, VerifAIButton, _VerifAIButtonState, VerifAIInput, _VerifAIInputState (+2 more)

### Community 54 - "track_repository.dart"
Cohesion: 0.20
Nodes (10): ApiClient, MockApiClient, SecureStorageService, _apiClient, getTracks, MockTrackRepository, _secureStorage, selectTrack (+2 more)

### Community 55 - "onboarding/providers.dart"
Cohesion: 0.22
Nodes (8): apiClient, getTracks, repository, secureStorage, selectedTrackProvider, selectTrack, trackRepositoryProvider, package:verifai/features/onboarding/data/track_repository.dart

### Community 56 - "@freezed"
Cohesion: 0.20
Nodes (10): @freezed, AuthResult, DailyTask, IndustryTrack, DailyTask, _DailyTask, IndustryTrack, _IndustryTrack (+2 more)

### Community 57 - "windows/flutter/generated_plugin_registrant.cc"
Cohesion: 0.33
Nodes (4): flutter_secure_storage_windows_plugin, RegisterPlugins(), plugin_registry, PluginRegistry

### Community 58 - "generate_app_icons.py"
Cohesion: 0.29
Nodes (7): generate(), _logo_on_canvas(), Generate VerifAI launcher icons from the master icon (transparent PNG).…, Center the logo on a square canvas, scaled to `fill` of its largest side., os, pil, sys

### Community 59 - "schema.sql"
Cohesion: 0.14
Nodes (26): achievements, idx_skill_scores_user, idx_task_attempts_user, idx_task_attempts_user_task, idx_tasks_track_difficulty, idx_user_achievements_user, skill_scores, task_attempts (+18 more)

### Community 60 - "FlutterWindow"
Cohesion: 0.33
Nodes (6): FlutterViewController, FlutterWindow, flutter_controller_, project_, DartProject, unique_ptr

### Community 61 - "firebase.js"
Cohesion: 0.21
Nodes (10): admin, fs, getFirebaseAdmin(), loadServiceAccount(), path, { getFirebaseAdmin }, verifyFirebaseToken(), firebase-admin (+2 more)

### Community 62 - "models.dart"
Cohesion: 0.33
Nodes (5): models/auth_state.dart, models/daily_task.dart, models/dashboard_data.dart, models/industry_track.dart, models/user.dart

### Community 63 - "@JsonSerializable"
Cohesion: 0.40
Nodes (5): @JsonSerializable, _, _, _, _

### Community 64 - "VerifAI Deliverable 4 Backend Handoff"
Cohesion: 0.18
Nodes (10): Database, Deliverable 4 additions, Existing teammate/backend foundation, GitHub status, Purpose, Railway status, Scoring, Security (+2 more)

### Community 65 - "auth/presentation.dart"
Cohesion: 0.50
Nodes (3): presentation/login_screen.dart, presentation/register_screen.dart, presentation/splash_screen.dart

### Community 66 - "Point"
Cohesion: 0.21
Nodes (6): Point, x, y, Size, height, width

### Community 67 - "main"
Cohesion: 0.24
Nodes (9): Contributing to the VerifAI Backend, 2. Important project rule, main(), Avoiding merge conflicts (team playbook), Branch naming, CI (GitHub Actions), Git Workflow, Resolving a conflict (quick reference) (+1 more)

### Community 75 - "VerifAI Backend — Deliverable 4"
Cohesion: 0.22
Nodes (8): Core Deliverable 4 flow, Database, Documentation, Git workflow, Quick start, Security, Stack, VerifAI Backend — Deliverable 4

### Community 86 - "routes/auth.js"
Cohesion: 0.25
Nodes (7): pool, syncUser(), express, router, { syncUser }, { verifyFirebaseToken }, Mock Backend (Swap-Ready) — `ApiClient` Interface

### Community 87 - "dependencies"
Cohesion: 0.22
Nodes (9): dependencies, cors, dotenv, express, express-rate-limit, firebase-admin, helmet, pg (+1 more)

### Community 88 - "check.js"
Cohesion: 0.25
Nodes (7): files, fs, path, roots, { spawnSync }, walk(), ref_child_process

### Community 89 - "achievements.js"
Cohesion: 0.29
Nodes (6): getAchievements(), pool, express, { getAchievements }, router, { verifyFirebaseToken }

### Community 90 - "progress.js"
Cohesion: 0.29
Nodes (6): getProgress(), pool, express, { getProgress }, router, { verifyFirebaseToken }

### Community 91 - "deploy"
Cohesion: 0.25
Nodes (7): deploy, healthcheckPath, healthcheckTimeout, restartPolicyMaxRetries, restartPolicyType, startCommand, $schema

### Community 92 - "flutter_window.h"
Cohesion: 0.39
Nodes (5): dart_project, flutter_view_controller, functional, memory, windows

### Community 93 - "_MyApplication"
Cohesion: 0.25
Nodes (8): FlView, GtkApplication, first_frame_cb(), my_application_init(), my_application_new(), _MyApplication, dart_entrypoint_arguments, parent_instance

### Community 94 - "Person 1 — Foundation Complete ✅"
Cohesion: 0.29
Nodes (7): Architecture, Core Packages, Design System (`lib/core/theme/`), Models (Freezed + JSON Serializable) — 5 Models, Person 1 — Foundation Complete ✅, Secure Storage, Shared Widgets (`lib/shared/widgets/`) — 10 Components

### Community 95 - "Railway Deployment Checklist"
Cohesion: 0.33
Nodes (5): Before deployment, Deploy, Production verification, Railway Deployment Checklist, Railway variables

### Community 96 - "scripts"
Cohesion: 0.33
Nodes (6): scripts, check, dev, start, test, test:watch

### Community 97 - "linux/flutter/generated_plugin_registrant.cc"
Cohesion: 0.33
Nodes (4): FlPluginRegistry, flutter_linux, flutter_secure_storage_linux_plugin, fl_register_plugins()

### Community 98 - "VerifAI Backend Audit — Deliverable 4"
Cohesion: 0.40
Nodes (4): Existing gaps found, Quality improvements included, VerifAI Backend Audit — Deliverable 4, Verification status

### Community 99 - "server.js"
Cohesion: 0.40
Nodes (3): app, pool, server

### Community 100 - "pull_request_template.md"
Cohesion: 0.40
Nodes (4): Checklist, How was it tested?, Type of change, What does this PR do?

## Knowledge Gaps
- **662 isolated node(s):** `Authentication`, `GET /api/health`, `GET /api/tracks`, `POST /api/auth/sync`, `GET /api/users/me` (+657 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 818 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **23 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `main()` connect `main` to `VerifAI Deliverable 4 Backend Handoff`, `pull_request_template.md`, `my_application.h`, `VerifAI Backend — Deliverable 4`, `_MyApplication`?**
  _High betweenness centrality (0.076) - this node is a cross-community bridge._
- **Why does `my_application_new()` connect `_MyApplication` to `main`, `my_application.cc`?**
  _High betweenness centrality (0.074) - this node is a cross-community bridge._
- **Why does `Win32Window` connect `Win32Window` to `Point`, `MessageHandler`, `flutter_window.h`, `MessageHandler`, `win32_window.cpp`, `FlutterWindow`?**
  _High betweenness centrality (0.047) - this node is a cross-community bridge._
- **What connects `Authentication`, `GET /api/health`, `GET /api/tracks` to the rest of the system?**
  _662 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `package.json` be split into smaller, more focused modules?**
  _Cohesion score 0.1 - nodes in this community are weakly interconnected._
- **Should `daily_task_card.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.09956709956709957 - nodes in this community are weakly interconnected._
- **Should `AppDelegate` be split into smaller, more focused modules?**
  _Cohesion score 0.05975609756097561 - nodes in this community are weakly interconnected._