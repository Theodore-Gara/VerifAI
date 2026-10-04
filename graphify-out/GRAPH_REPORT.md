# Graph Report - VerifAI  (2026-10-04)

## Corpus Check
- 149 files · ~85,146 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 62 file(s) not represented in the graph (top: (none) 15, .xml 9, .plist 8)

## Summary
- 1380 nodes · 1883 edges · 105 communities (79 shown, 26 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 45 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `6595b608`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- package.json
- daily_task_card.dart
- AppDelegate
- app_colors.dart
- VerifAI
- scoreboard_screen.dart
- package:verifai/core/theme/app_colors.dart
- Screens Implemented — 9 Screens
- score_ring.dart
- Medium value
- app_spacing.dart
- tasksController.js
- currentUserProvider
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
- task_challenge_modal.dart
- verifai_card.dart
- feedback_screen.dart
- empty_state.dart
- app.js
- app_router.dart
- industry_track.dart
- package:flutter/material.dart
- dashboard_screen.dart
- Win32Window
- app_typography.dart
- MessageHandler
- check.js
- Endpoints
- progress_screen.dart
- manifest.json
- MessageHandler
- profile_screen.dart
- pool.js
- package:verifai/shared/models.dart
- onboarding/providers.dart
- track_repository.dart
- db-setup.js
- @freezed
- windows/flutter/generated_plugin_registrant.cc
- generate_app_icons.py
- schema.sql
- dashboard/providers.dart
- tasks.js
- models.dart
- @JsonSerializable
- VerifAI Deliverable 4 Backend Handoff
- auth/presentation.dart
- Point
- CONTRIBUTING.md
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
- track_roadmap_screen.dart
- achievements.js
- progress.js
- deploy
- flutter_window.h
- Migrating off `railway.json` to Infrastructure as Code
- scripts
- auth_error_messages.dart
- VerifAI Backend Audit — Deliverable 4
- server.js
- pull_request_template.md
- TEST_MATRIX.md
- firebase_auth_plugin_c_api
- firebase_core_plugin_c_api
- package_unsigned_ipa.sh

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 24 edges
2. `VerifAI Backend — Beginner User Manual` - 16 edges
3. `authNotifierProvider` - 13 edges
4. `MessageHandler` - 12 edges
5. `Screens Implemented — 9 Screens` - 11 edges
6. `VerifAI — Backend Tasks` - 10 edges
7. `FlutterWindow` - 10 edges
8. `submitAttempt()` - 10 edges
9. `AuthState` - 10 edges
10. `Create` - 10 edges

## Surprising Connections (you probably didn't know these)
- ``embedded_flaw` is never returned to the app` --references--> `getNextTask()`  [INFERRED]
  BACKEND_TASKS.md → backend/controllers/tasksController.js
- `P0 — Task volume and "run out" behaviour` --references--> `getNextTask()`  [INFERRED]
  BACKEND_TASKS.md → backend/controllers/tasksController.js
- `P2 — Streak timezone correctness` --references--> `submitAttempt()`  [INFERRED]
  BACKEND_TASKS.md → backend/controllers/tasksController.js
- `Mock Backend (Swap-Ready) — `ApiClient` Interface` --references--> `getTracks()`  [INFERRED]
  mobile/README.md → backend/controllers/tracksController.js
- `Mock Backend (Swap-Ready) — `ApiClient` Interface` --references--> `syncUser()`  [INFERRED]
  mobile/README.md → backend/controllers/authController.js

## Import Cycles
- None detected.

## Communities (105 total, 26 thin omitted)

### Community 0 - "package.json"
Cohesion: 0.10
Nodes (18): description, devDependencies, jest, nodemon, supertest, main, name, version (+10 more)

### Community 1 - "daily_task_card.dart"
Cohesion: 0.17
Nodes (11): build, DailyTaskCard, dimension, _formatDimension, _getDifficultyColor, _getDimensionColor, isLoading, onStart (+3 more)

### Community 2 - "AppDelegate"
Cohesion: 0.06
Nodes (27): Any, Cocoa, Flutter, flutter_secure_storage_macos, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterMacOS (+19 more)

### Community 3 - "app_colors.dart"
Cohesion: 0.05
Nodes (39): accentCyan, accentGreen, accentLight, ambientCyan, ambientGold, ambientGreen, AppColors, background (+31 more)

### Community 4 - "VerifAI"
Cohesion: 0.08
Nodes (24): About the Project, AI Workplace Readiness App, Avoiding merge conflicts (team playbook), Backend setup, Branch naming, CI (GitHub Actions), Database setup, Getting Started (+16 more)

### Community 5 - "scoreboard_screen.dart"
Cohesion: 0.13
Nodes (14): _buildLeaderboardTile, _buildPodiumSpot, createState, dispose, initState, isCurrentUser, _LeaderboardEntry, name (+6 more)

### Community 6 - "package:verifai/core/theme/app_colors.dart"
Cohesion: 0.10
Nodes (20): AuthBrandHeader, build, subtitle, title, build, days, label, showIcon (+12 more)

### Community 7 - "Screens Implemented — 9 Screens"
Cohesion: 0.08
Nodes (24): 1. Visual Philosophy & Core Pillars, 2. Design Tokens Reference, 3. Key Component Usage Guidelines, 4. Git Collaborator Guide (Rules for Adding Code), Auth Flow (3), Border Radii (`lib/core/theme/app_radius.dart`), Color Palette (`lib/core/theme/app_colors.dart`), `DailyTaskCard` (`lib/shared/widgets/daily_task_card.dart`) (+16 more)

### Community 8 - "score_ring.dart"
Cohesion: 0.11
Nodes (17): CustomPainter, build, child, color, _getDefaultTier, _getScoreColor, maxScore, _ModernScoreRingPainter (+9 more)

### Community 9 - "Medium value"
Cohesion: 0.13
Nodes (14): 1. Stop shipping fake data on real-looking screens, 2. Task UI must consume the backend options (and the flaw), 3. 401 / token-expiry handling, 4. Task-exhaustion UX, 5. Test coverage, 6. Keep the web build deployed, 7. Git hygiene, 8. Accessibility pass (+6 more)

### Community 10 - "app_spacing.dart"
Cohesion: 0.06
Nodes (32): AppRadius, badge, button, card, fab, input, lg, md (+24 more)

### Community 11 - "tasksController.js"
Cohesion: 0.07
Nodes (41): awardAchievements(), getCurrentUser(), getNextTask(), pool, { positiveIntegerParam, requiredString }, preferredDifficulties(), { scoreAnswer, calculateXp, calculateLevel }, submitAttempt() (+33 more)

### Community 12 - "currentUserProvider"
Cohesion: 0.14
Nodes (21): ConsumerState, ConsumerStatefulWidget, ConsumerWidget, currentUserProvider, build, DashboardScreen, _DashboardScreenState, dashboardProvider (+13 more)

### Community 13 - "secure_storage_service.dart"
Cohesion: 0.05
Nodes (42): core/router/app_router.dart, core/theme/app_theme.dart, firebase_options.dart, routerProvider, clearAll, deleteAuthToken, email, getAuthToken (+34 more)

### Community 15 - "my_application.cc"
Cohesion: 0.08
Nodes (26): FlPluginRegistry, flutter_linux, flutter_secure_storage_linux_plugin, FlView, GApplication, gboolean, gchar, gdkx (+18 more)

### Community 16 - "verifai_input.dart"
Cohesion: 0.05
Nodes (45): dart:ui, FocusNode?, FormFieldValidator, List, build, _buildNavItem, createState, _currentIndex (+37 more)

### Community 17 - "auth_repository.dart"
Cohesion: 0.09
Nodes (23): dart:convert, _apiClient, AuthRepository, authStateChanges, _authStateController, completeOnboarding, dispose, _ensureSeedUsers (+15 more)

### Community 18 - "utils.cpp"
Cohesion: 0.18
Nodes (13): flutter_windows, _In_, _In_opt_, io, iostream, wWinMain(), string, wchar_t (+5 more)

### Community 19 - "auth/providers.dart"
Cohesion: 0.13
Nodes (21): AsyncNotifier, apiClient, AuthNotifier, authRepositoryProvider, build, completeOnboarding, getCurrentUser, login (+13 more)

### Community 20 - "user.dart"
Cohesion: 0.12
Nodes (17): createdAt, email, hasCompletedOnboarding, hashCode, id, name, operator, _privateConstructorUsedError (+9 more)

### Community 21 - "win32_window.cpp"
Cohesion: 0.16
Nodes (15): dwmapi, wchar_t, Scale(), Create, Destroy, SetQuitOnClose, Show, UpdateTheme (+7 more)

### Community 22 - "industry_select_screen.dart"
Cohesion: 0.12
Nodes (18): build, _buildShimmerList, _buildTracksList, createState, _getTrackIcon, _getTrackPerk, _handleContinue, IndustrySelectScreen (+10 more)

### Community 23 - "register_screen.dart"
Cohesion: 0.09
Nodes (29): auth_brand_header.dart, auth_error_messages.dart, FormState, build, createState, dispose, _emailController, _formKey (+21 more)

### Community 24 - "VerifAI Backend — Beginner User Manual"
Cohesion: 0.08
Nodes (24): 10. How the attempt flow works, 11. GitHub — safest beginner workflow, 12. Railway deployment, 13. Common problems, 14. What must never be committed, 15. Final pre-submission checklist, 1. What this backend does, 2. Important project rule (+16 more)

### Community 25 - "dashboard_data.dart"
Cohesion: 0.11
Nodes (17): completedTasks, currentXp, dailyTask, dimensionScores, hashCode, level, operator, overallScore (+9 more)

### Community 26 - "api_client.dart"
Cohesion: 0.12
Nodes (16): answer, AuthSyncResponse, explanation, feedback, getDashboard, getTracks, score, submitTask (+8 more)

### Community 27 - "splash_screen.dart"
Cohesion: 0.14
Nodes (15): Animation, AnimationController, build, _controller, createState, dispose, _fadeAnimation, initState (+7 more)

### Community 28 - "auth_state.dart"
Cohesion: 0.13
Nodes (14): _, hashCode, operator, _privateConstructorUsedError, token, toString, user, int get (+6 more)

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
Cohesion: 0.13
Nodes (14): BorderRadius?, EdgeInsetsGeometry?, borderRadius, build, card, height, itemCount, itemHeight (+6 more)

### Community 33 - "task_challenge_modal.dart"
Cohesion: 0.05
Nodes (40): api_client.dart, Dio, FirebaseAuth, apiClientProvider, dio, dioProvider, getInstance, secureStorageProvider (+32 more)

### Community 34 - "verifai_card.dart"
Cohesion: 0.14
Nodes (13): backgroundColor, borderRadius, build, child, _getBackgroundColor, _getBorder, _getShadow, margin (+5 more)

### Community 35 - "feedback_screen.dart"
Cohesion: 0.15
Nodes (12): bool get, build, _defaultDimensionScores, dimensionScores, feedback, FeedbackResult, _headline, onContinue (+4 more)

### Community 36 - "empty_state.dart"
Cohesion: 0.09
Nodes (22): FeedbackEmptyScreen, FeedbackScreen, _TrackCard, _DimensionChip, _TrackChip, actionLabel, actionVariant, build (+14 more)

### Community 37 - "app.js"
Cohesion: 0.11
Nodes (15): achievementRoutes, allowedOrigins, app, authRoutes, cors, errorHandler, express, healthRoutes (+7 more)

### Community 38 - "app_router.dart"
Cohesion: 0.13
Nodes (14): AsyncValue, ChangeNotifier, GoRouter, GoRouterRefreshNotifier, notify, refreshNotifier, router, package:verifai/features/auth/presentation.dart (+6 more)

### Community 39 - "industry_track.dart"
Cohesion: 0.14
Nodes (12): description, hashCode, id, name, operator, _privateConstructorUsedError, toJson, toString (+4 more)

### Community 40 - "package:flutter/material.dart"
Cohesion: 0.25
Nodes (12): main, main, main, package:flutter/material.dart, package:flutter_riverpod/flutter_riverpod.dart, package:flutter_secure_storage/flutter_secure_storage.dart, package:flutter_test/flutter_test.dart, package:shared_preferences/shared_preferences.dart (+4 more)

### Community 41 - "dashboard_screen.dart"
Cohesion: 0.20
Nodes (9): _buildDashboard, _buildShimmer, createState, _playTask, package:go_router/go_router.dart, package:verifai/features/auth/providers.dart, package:verifai/shared/widgets.dart, Route /progress (+1 more)

### Community 42 - "Win32Window"
Cohesion: 0.16
Nodes (18): FlutterViewController, FlutterWindow, flutter_controller_, OnCreate, OnDestroy, project_, DartProject, HWND (+10 more)

### Community 43 - "app_typography.dart"
Cohesion: 0.15
Nodes (11): app_colors.dart, app_radius.dart, app_spacing.dart, app_typography.dart, AppTheme, AppTypography, _heading, _inter (+3 more)

### Community 44 - "MessageHandler"
Cohesion: 0.18
Nodes (10): generated_plugin_registrant, DartProject, HWND, LPARAM, LRESULT, UINT, WPARAM, FlutterWindow::FlutterWindow() (+2 more)

### Community 45 - "check.js"
Cohesion: 0.22
Nodes (7): files, fs, path, roots, { spawnSync }, ref_child_process, ref_fs

### Community 46 - "Endpoints"
Cohesion: 0.12
Nodes (15): Authentication, Database setup, Endpoints, Error format, GET /api/achievements/me, GET /api/health, GET /api/progress/me, GET /api/tasks/next (+7 more)

### Community 47 - "progress_screen.dart"
Cohesion: 0.10
Nodes (23): _buildContent, _buildShimmer, _dimensionLabel, _weeklyActivity, _buildShimmer, _buildTasks, createState, _startTask (+15 more)

### Community 48 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 49 - "MessageHandler"
Cohesion: 0.36
Nodes (10): HWND, LPARAM, LRESULT, UINT, WPARAM, EnableFullDpiSupportIfAvailable(), GetHandle, GetThisFromHandle (+2 more)

### Community 50 - "profile_screen.dart"
Cohesion: 0.10
Nodes (19): Color?, IconData?, _Badge, _buildBentoStat, _buildModernBadgeTile, color, description, _formatNumber (+11 more)

### Community 51 - "pool.js"
Cohesion: 0.15
Nodes (11): getTracks(), pool, { Pool }, express, pool, router, express, { getTracks } (+3 more)

### Community 52 - "package:verifai/shared/models.dart"
Cohesion: 0.29
Nodes (7): _apiClient, DashboardRepository, getDashboard, MockDashboardRepository, refreshDashboard, package:verifai/core/services/api_client.dart, package:verifai/shared/models.dart

### Community 53 - "onboarding/providers.dart"
Cohesion: 0.22
Nodes (8): apiClient, getTracks, repository, secureStorage, selectedTrackProvider, selectTrack, trackRepositoryProvider, package:verifai/features/onboarding/data/track_repository.dart

### Community 54 - "track_repository.dart"
Cohesion: 0.18
Nodes (11): ApiClient, DioApiClient, MockApiClient, SecureStorageService, _apiClient, getTracks, MockTrackRepository, _secureStorage (+3 more)

### Community 55 - "db-setup.js"
Cohesion: 0.22
Nodes (12): baseline(), crypto, DB_DIR, ensureLedger(), fs, listMigrations(), main(), MIGRATIONS_DIR (+4 more)

### Community 56 - "@freezed"
Cohesion: 0.15
Nodes (13): @freezed, AuthResult, DailyTask, DashboardData, IndustryTrack, DailyTask, _DailyTask, DashboardData (+5 more)

### Community 57 - "windows/flutter/generated_plugin_registrant.cc"
Cohesion: 0.33
Nodes (4): flutter_secure_storage_windows_plugin, RegisterPlugins(), plugin_registry, PluginRegistry

### Community 58 - "generate_app_icons.py"
Cohesion: 0.29
Nodes (7): generate(), _logo_on_canvas(), Generate VerifAI launcher icons from the master icon (transparent PNG).…, Center the logo on a square canvas, scaled to `fill` of its largest side., os, pil, sys

### Community 59 - "schema.sql"
Cohesion: 0.12
Nodes (24): idx_skill_scores_user, idx_task_attempts_user, idx_task_attempts_user_task, idx_tasks_track_difficulty, idx_user_achievements_user, set_updated_at, trg_skill_scores_updated_at, trg_user_progress_updated_at (+16 more)

### Community 60 - "dashboard/providers.dart"
Cohesion: 0.25
Nodes (7): apiClient, dashboardRepositoryProvider, getDashboard, refreshDashboard, refreshDashboardProvider, repository, package:verifai/features/dashboard/data/dashboard_repository.dart

### Community 61 - "tasks.js"
Cohesion: 0.16
Nodes (13): admin, fs, getFirebaseAdmin(), loadServiceAccount(), path, { getFirebaseAdmin }, verifyFirebaseToken(), express (+5 more)

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

### Community 75 - "VerifAI Backend — Deliverable 4"
Cohesion: 0.22
Nodes (8): Core Deliverable 4 flow, Database, Documentation, Git workflow, Quick start, Security, Stack, VerifAI Backend — Deliverable 4

### Community 86 - "routes/auth.js"
Cohesion: 0.13
Nodes (14): pool, syncUser(), express, router, { syncUser }, { verifyFirebaseToken }, Architecture, Core Packages (+6 more)

### Community 87 - "dependencies"
Cohesion: 0.22
Nodes (9): dependencies, cors, dotenv, express, express-rate-limit, firebase-admin, helmet, pg (+1 more)

### Community 88 - "track_roadmap_screen.dart"
Cohesion: 0.18
Nodes (10): _buildMilestoneCard, _buildNodeIndicator, description, icon, _Milestone, MilestoneStatus, status, title (+2 more)

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

### Community 95 - "Migrating off `railway.json` to Infrastructure as Code"
Cohesion: 0.15
Nodes (12): Before deployment, Current state, Deploy, Footguns, Migrating off `railway.json` to Infrastructure as Code, Optional: a real `DATABASE_URL` reference, Production verification, Railway Deployment Checklist (+4 more)

### Community 96 - "scripts"
Cohesion: 0.25
Nodes (8): scripts, check, db:migrate, db:setup, dev, start, test, test:watch

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
- **743 isolated node(s):** `The live data does not match the repo`, `Scoring is mismatched with the data`, `Move to the multiple-choice model (pending restructure)`, `P1 — Leaderboard / scoreboard endpoint`, `P1 — Activity / streak history endpoint` (+738 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 900 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **26 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Win32Window` connect `Win32Window` to `Point`, `MessageHandler`, `MessageHandler`, `win32_window.cpp`, `flutter_window.h`?**
  _High betweenness centrality (0.026) - this node is a cross-community bridge._
- **Why does `FlutterWindow` connect `Win32Window` to `MessageHandler`, `flutter_window.h`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **Why does `ApiClient` connect `track_repository.dart` to `task_challenge_modal.dart`, `api_client.dart`, `package:verifai/shared/models.dart`, `auth_repository.dart`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **What connects `The live data does not match the repo`, `Scoring is mismatched with the data`, `Move to the multiple-choice model (pending restructure)` to the rest of the system?**
  _743 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `package.json` be split into smaller, more focused modules?**
  _Cohesion score 0.1 - nodes in this community are weakly interconnected._
- **Should `AppDelegate` be split into smaller, more focused modules?**
  _Cohesion score 0.05975609756097561 - nodes in this community are weakly interconnected._
- **Should `app_colors.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._