# Graph Report - VerifAI  (2026-10-14)

## Corpus Check
- 305 files · ~223,632 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 60 file(s) not represented in the graph (top: (none) 14, .xml 9, .plist 8)

## Summary
- 3095 nodes · 4511 edges · 219 communities (150 shown, 69 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 126 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `b915d49b`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- package.json
- lab.dart
- AppDelegate
- app_colors.dart
- VerifAI
- scoreboard_screen.dart
- topic_reader_screen.dart
- Screens Implemented — 9 Screens
- score_ring.dart
- AI Judgement — work items
- app_spacing.dart
- VerifAI — Backend Tasks
- xpService.js
- secure_storage_service.dart
- String title, kicker, headline,
- my_application.cc
- verifai_input.dart
- auth_repository.dart
- utils.cpp
- auth/providers.dart
- user.dart
- win32_window.cpp
- verification_screen.dart
- nvidiaAssistant.js
- VerifAI Backend — Beginner User Manual
- dashboard_data.dart
- api_client.dart
- splash_screen.dart
- auth_state.dart
- daily_task.dart
- mock_api_client.dart
- Win32Window
- verifai_card.dart
- dio_api_client.dart
- choice_task_screen.dart
- feedback_screen.dart
- StatelessWidget
- app.js
- app_router.dart
- industry_track.dart
- labController.js
- verificationController.js
- vera_voice.dart
- app_typography.dart
- leaderboard.dart
- tasksController.js
- Endpoints
- reward_detail_screen.dart
- manifest.json
- task_screen.dart
- industry_select_screen.dart
- Person 1 — Foundation Complete ✅
- MessageHandler
- onboarding/providers.dart
- package:verifai/core/services/api_client.dart
- db-setup.js
- DailyTask
- flutter_secure_storage_windows_plugin
- generate_app_icons.py
- 001_prototype_to_d4.sql
- @freezed
- firebase.js
- models.dart
- pool.js
- VerifAI Deliverable 4 Backend Handoff
- auth/presentation.dart
- login_flow_test.dart
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
- package:flutter_test/flutter_test.dart
- dependencies
- industry_practice_screen.dart
- achievements.js
- login_screen.dart
- deploy
- flutter_window.h
- package:flutter_riverpod/flutter_riverpod.dart
- api_error.dart
- Migrating off `railway.json` to Infrastructure as Code
- welcome_tutorial_screen.dart
- auth_error_messages.dart
- VerifAI Backend Audit — Deliverable 4
- profile_screen.dart
- pull_request_template.md
- TEST_MATRIX.md
- firebase_auth_plugin_c_api
- firebase_core_plugin_c_api
- package_unsigned_ipa.sh
- api.test.js
- task_run_screen.dart
- auth_interceptor.dart
- positiveIntegerParam
- veraController.js
- package:flutter/material.dart
- package:verifai/core/theme/app_colors.dart
- interviewController.js
- scoringService.js
- List
- activity.dart
- interview_practice_screen.dart
- capstone.test.js
- assessment_paper_screen.dart
- main_nav_shell.dart
- scoring.test.js
- judgement_screen_test.dart
- Feature Build — AI Judgement, Risk & Governance & Interview Practice (next sprint)
- app_providers.dart
- progress.js
- milestone.dart
- history.dart
- schema.sql
- leaderboard.js
- vera.dart
- recovery_screen.dart
- State
- lab_lessons
- interview_question.dart
- VerifAI — Scoring Algorithm Review
- P0 — Scoring metrics & readiness (canonical)
- verifai_button.dart
- usersController.js
- String?
- MessageHandler
- industry_tracks
- progress_screen.dart
- users
- Codemagic Android Signing
- verification.dart
- 002_restructure_tasks.sql
- tasks
- practiceActivities.test.js
- VerifAI Backend API
- task_attempts
- flutter_secure_storage_linux_plugin
- id
- toJson
- plugin_registry
- verification_tasks
- _ProfileScreenState
- track_repository.dart
- Vera — AI assistant with memory
- lab_capstone_assessments
- vera_assistant_screen.dart
- set_updated_at
- verification_studio_screen.dart
- rewards.dart
- activity_screen.dart
- assessment_instructions_screen.dart
- ConsumerState
- learning_assistant_screen.dart
- register_screen.dart
- streak.test.js
- Point
- industry_practice.dart
- verification_result_screen.dart
- Size
- inline_markdown_text.dart
- OfflineTts?
- dart:async
- lab/providers.dart
- dashboard/providers.dart
- build
- onboarding_flow_test.dart
- apiClientProvider
- _startWelcomeAndNavigate
- AI Judgement — work items
- package:verifai/features/product_hub/presentation/product_hub_screen.dart
- _piperEntry
- bool?
- LabActivity
- LabActivityResult?
- LabAssessmentResult
- LabAssessmentStart

## God Nodes (most connected - your core abstractions)
1. `Endpoints` - 49 edges
2. `users` - 24 edges
3. `Win32Window` - 24 edges
4. `VerifAI Backend — Beginner User Manual` - 16 edges
5. `requireUser()` - 15 edges
6. `positiveIntegerParam()` - 15 edges
7. `submitAttempt()` - 15 edges
8. `VerifAI — Backend Tasks` - 15 edges
9. `industry_tracks` - 14 edges
10. `express` - 14 edges

## Surprising Connections (you probably didn't know these)
- `AJ-B3 — `getNextTask`: dimension filter + options` --references--> `getNextTask()`  [INFERRED]
  BACKEND_TASKS.md → backend/controllers/tasksController.js
- `XP level curve (cosmetic)` --references--> `calculateLevel()`  [INFERRED]
  BACKEND_TASKS.md → backend/services/scoringService.js
- ``embedded_flaw` is never returned to the app` --references--> `getNextTask()`  [INFERRED]
  BACKEND_TASKS.md → backend/controllers/tasksController.js
- `P0 — Task volume and "run out" behaviour` --references--> `getNextTask()`  [INFERRED]
  BACKEND_TASKS.md → backend/controllers/tasksController.js
- `AJ-B4 — `submitAttempt`: two-part scoring path` --references--> `scoreAnswer()`  [INFERRED]
  BACKEND_TASKS.md → backend/services/scoringService.js

## Import Cycles
- None detected.

## Communities (219 total, 69 thin omitted)

### Community 0 - "package.json"
Cohesion: 0.08
Nodes (23): description, devDependencies, supertest, engines, node, main, name, overrides (+15 more)

### Community 1 - "lab.dart"
Cohesion: 0.02
Nodes (99): achievement, activities, activitiesCompleted, activitiesCount, answer, assessment, assessmentBestScore, attempted (+91 more)

### Community 2 - "AppDelegate"
Cohesion: 0.07
Nodes (22): Any, Cocoa, Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterMacOS, FlutterSceneDelegate (+14 more)

### Community 3 - "app_colors.dart"
Cohesion: 0.05
Nodes (39): accentCyan, accentGreen, accentLight, ambientCyan, ambientGold, ambientGreen, AppColors, background (+31 more)

### Community 4 - "VerifAI"
Cohesion: 0.08
Nodes (24): About the Project, AI Workplace Readiness App, Avoiding merge conflicts (team playbook), Backend setup, Branch naming, CI (GitHub Actions), Database setup, Getting Started (+16 more)

### Community 5 - "scoreboard_screen.dart"
Cohesion: 0.08
Nodes (30): currentUserProvider, build, _buildBoard, _buildEliteSpot, _buildLeaderboardTile, _buildShimmer, _buildStandingBanner, _buildTopPerformersShowcase (+22 more)

### Community 6 - "topic_reader_screen.dart"
Cohesion: 0.07
Nodes (29): historyProvider, build, _date, HistoryScreen, _label, _tile, _Block, code (+21 more)

### Community 7 - "Screens Implemented — 9 Screens"
Cohesion: 0.08
Nodes (24): 1. Visual Philosophy & Core Pillars, 2. Design Tokens Reference, 3. Key Component Usage Guidelines, 4. Git Collaborator Guide (Rules for Adding Code), Auth Flow (3), Border Radii (`lib/core/theme/app_radius.dart`), Color Palette (`lib/core/theme/app_colors.dart`), `DailyTaskCard` (`lib/shared/widgets/daily_task_card.dart`) (+16 more)

### Community 8 - "score_ring.dart"
Cohesion: 0.11
Nodes (18): CustomPainter, dart:math, build, child, color, _getScoreColor, maxScore, _ModernScoreRingPainter (+10 more)

### Community 9 - "AI Judgement — work items"
Cohesion: 0.05
Nodes (36): 1. Stop shipping fake data on real-looking screens, 2. Task UI must consume the backend options (and the flaw), 3. 401 / token-expiry handling, 4. Task-exhaustion UX, 5. Test coverage, 6. Keep the web build deployed, 7. Git hygiene, 8. Accessibility pass (+28 more)

### Community 10 - "app_spacing.dart"
Cohesion: 0.06
Nodes (32): AppRadius, badge, button, card, fab, input, lg, md (+24 more)

### Community 11 - "VerifAI — Backend Tasks"
Cohesion: 0.12
Nodes (19): getNextTask(), preferredDifficulties(), resolveFeature(), Already fine (no changes required), `embedded_flaw` is never returned to the app, Move to the multiple-choice model (pending restructure), P0 — Reconcile the task data model and fix scoring, P0 — Restructure the task schema (per-feature tables) (+11 more)

### Community 12 - "xpService.js"
Cohesion: 0.22
Nodes (8): backend_services_rewardtokens, backend_services_streak_streak_timezone, { calculateLevel }, { computeStreak, STREAK_TIMEZONE }, { grantTokens, levelGrants }, c_users_theod_verifai_backend_services_rewardtokens_granttokens, c_users_theod_verifai_backend_services_rewardtokens_levelgrants, c_users_theod_verifai_backend_services_scoringservice_calculatelevel

### Community 13 - "secure_storage_service.dart"
Cohesion: 0.08
Nodes (24): clearAll, deleteAuthToken, email, getAuthToken, getUserData, _handleCorruptedStorage, hasCompletedOnboarding, _isDecryptionError (+16 more)

### Community 15 - "my_application.cc"
Cohesion: 0.10
Nodes (23): flutter_linux, FlView, GApplication, gboolean, gchar, gdkx, GObject, gtk (+15 more)

### Community 16 - "verifai_input.dart"
Cohesion: 0.08
Nodes (24): FocusNode?, FormFieldValidator, build, controller, createState, dispose, enabled, focusNode (+16 more)

### Community 17 - "auth_repository.dart"
Cohesion: 0.11
Nodes (19): _apiClient, AuthRepository, authStateChanges, _authStateController, completeOnboarding, dispose, FirebaseAuthRepository, getCurrentUser (+11 more)

### Community 18 - "utils.cpp"
Cohesion: 0.17
Nodes (13): flutter_windows, _In_, _In_opt_, io, iostream, wWinMain(), string, wchar_t (+5 more)

### Community 19 - "auth/providers.dart"
Cohesion: 0.06
Nodes (37): AsyncNotifier, core/router/app_router.dart, core/theme/app_theme.dart, firebase_options.dart, FutureProvider, routerProvider, apiClient, auth (+29 more)

### Community 20 - "user.dart"
Cohesion: 0.12
Nodes (15): bool get, createdAt, email, hasCompletedOnboarding, hashCode, id, name, operator (+7 more)

### Community 21 - "win32_window.cpp"
Cohesion: 0.16
Nodes (15): dwmapi, wchar_t, Scale(), Create, Destroy, SetQuitOnClose, Show, UpdateTheme (+7 more)

### Community 22 - "verification_screen.dart"
Cohesion: 0.20
Nodes (11): dashboardProvider, FeedbackScreen, build, _buildShimmer, _buildTasks, createState, _startTask, VerificationScreen (+3 more)

### Community 23 - "nvidiaAssistant.js"
Cohesion: 0.09
Nodes (36): aiMarkCapstone(), coach(), getAssessmentAnalysis(), backend_services_llm_client, backend_services_llm_profiles, ANALYSIS_KINDS, analysisSystem(), assistantSystem() (+28 more)

### Community 24 - "VerifAI Backend — Beginner User Manual"
Cohesion: 0.08
Nodes (24): 10. How the attempt flow works, 11. GitHub — safest beginner workflow, 12. Railway deployment, 13. Common problems, 14. What must never be committed, 15. Final pre-submission checklist, 1. What this backend does, 2. Important project rule (+16 more)

### Community 25 - "dashboard_data.dart"
Cohesion: 0.09
Nodes (21): completedTasks, currentXp, dailyTask, dimensionScores, hashCode, level, operator, overallScore (+13 more)

### Community 26 - "api_client.dart"
Cohesion: 0.03
Nodes (70): addVeraMemory, analyzeVerification, answer, answerOptionId, AssistantMessage, AuthSyncResponse, content, correctAnswer (+62 more)

### Community 27 - "splash_screen.dart"
Cohesion: 0.10
Nodes (21): Animation, AnimationController, AudioPlayer, FlutterTts, build, _controller, createState, dispose (+13 more)

### Community 28 - "auth_state.dart"
Cohesion: 0.14
Nodes (13): _, hashCode, operator, _privateConstructorUsedError, token, toString, user, authenticated (+5 more)

### Community 29 - "daily_task.dart"
Cohesion: 0.09
Nodes (22): aiOutputLines, difficulty, dimension, embeddedFlaw, feature, format, hashCode, isRepeat (+14 more)

### Community 30 - "mock_api_client.dart"
Cohesion: 0.04
Nodes (49): addVeraMemory, analyzeVerification, _dailyTasks, _delay, deleteAccount, deleteVeraMemory, _dimensionScores, getAchievements (+41 more)

### Community 31 - "Win32Window"
Cohesion: 0.16
Nodes (18): FlutterViewController, FlutterWindow, flutter_controller_, OnCreate, OnDestroy, project_, DartProject, HWND (+10 more)

### Community 32 - "verifai_card.dart"
Cohesion: 0.07
Nodes (28): BorderRadius?, EdgeInsetsGeometry?, borderRadius, build, card, height, itemCount, itemHeight (+20 more)

### Community 33 - "dio_api_client.dart"
Cohesion: 0.04
Nodes (52): api_client.dart, FirebaseAuth, addVeraMemory, analyzeVerification, _authHeaders, deleteAccount, deleteVeraMemory, _dio (+44 more)

### Community 34 - "choice_task_screen.dart"
Cohesion: 0.09
Nodes (22): build, _buildTask, _canSubmit, categoryLabel, ChoiceTaskScreen, _ChoiceTaskScreenState, _choiceTile, createState (+14 more)

### Community 35 - "feedback_screen.dart"
Cohesion: 0.06
Nodes (32): correctAnswer, _didPass, dimensionScores, feedback, FeedbackResult, _headline, label, matched (+24 more)

### Community 36 - "StatelessWidget"
Cohesion: 0.06
Nodes (34): AuthBrandHeader, _PasswordStrengthIndicator, _ConceptChip, FeedbackEmptyScreen, _WebSearchButton, bgColor, build, DimensionIndexCard (+26 more)

### Community 37 - "app.js"
Cohesion: 0.06
Nodes (30): achievementRoutes, allowedOrigins, app, assistantRoutes, authRoutes, cors, errorHandler, express (+22 more)

### Community 38 - "app_router.dart"
Cohesion: 0.07
Nodes (33): ChangeNotifier, GoRouter, true, GoRouterRefreshNotifier, _isChoiceFeature, notify, refreshNotifier, _retryTask (+25 more)

### Community 39 - "industry_track.dart"
Cohesion: 0.17
Nodes (11): description, hashCode, id, name, operator, _privateConstructorUsedError, toJson, toString (+3 more)

### Community 40 - "labController.js"
Cohesion: 0.06
Nodes (56): applyCapstoneRewards(), attemptsUsed(), { awardXp }, findCapstone(), findLessonForUser(), { findUserByFirebaseUid }, getAssessmentPaper(), { getCoachReply, streamCoachReply, markRubric, generateCapstoneReport } (+48 more)

### Community 41 - "verificationController.js"
Cohesion: 0.10
Nodes (25): { analyzeContent }, analyzeVerification(), bad(), buildEvidence(), { extractDocument, fetchUrl }, { findUserByFirebaseUid }, { handleAiError }, KINDS (+17 more)

### Community 42 - "vera_voice.dart"
Cohesion: 0.04
Nodes (50): Completer, dart:isolate, Future, _base, _baseDir, basePath, byteRate, client (+42 more)

### Community 43 - "app_typography.dart"
Cohesion: 0.15
Nodes (11): app_colors.dart, app_radius.dart, app_spacing.dart, app_typography.dart, AppTheme, AppTypography, _heading, _inter (+3 more)

### Community 44 - "leaderboard.dart"
Cohesion: 0.12
Nodes (16): entries, fromJson, _int, isCurrentUser, LeaderboardData, LeaderboardEntry, level, me (+8 more)

### Community 45 - "tasksController.js"
Cohesion: 0.08
Nodes (31): awardAchievements(), clampInt(), DIMENSION_FEATURE, FEATURE_DIMENSION, FEATURES, getCurrentUser(), getHistory(), { grantTokens, levelGrants, achievementGrants } (+23 more)

### Community 46 - "Endpoints"
Cohesion: 0.04
Nodes (49): DELETE /api/workshop/posts/:id, Endpoints, GET /api/achievements, GET /api/achievements/me, GET /api/achievements/milestones, GET /api/health, GET /api/history, GET /api/interview/questions (+41 more)

### Community 47 - "reward_detail_screen.dart"
Cohesion: 0.15
Nodes (13): int?, build, createState, _info, _redeem, _redeeming, _remainingTokens, reward (+5 more)

### Community 48 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 49 - "task_screen.dart"
Cohesion: 0.11
Nodes (17): Color, IconData, _Category, _CategoryCard, color, icon, route, subtitle (+9 more)

### Community 50 - "industry_select_screen.dart"
Cohesion: 0.12
Nodes (16): IndustryTrack, _buildShimmerList, _buildTracksList, createState, _getTrackIcon, _getTrackPerk, isChangingIndustry, isSelected (+8 more)

### Community 51 - "Person 1 — Foundation Complete ✅"
Cohesion: 0.14
Nodes (13): getTracks(), pool, express, { getTracks }, router, Architecture, Core Packages, Design System (`lib/core/theme/`) (+5 more)

### Community 52 - "MessageHandler"
Cohesion: 0.18
Nodes (10): generated_plugin_registrant, DartProject, HWND, LPARAM, LRESULT, UINT, WPARAM, FlutterWindow::FlutterWindow() (+2 more)

### Community 53 - "onboarding/providers.dart"
Cohesion: 0.15
Nodes (15): build, _handleContinue, IndustrySelectScreen, _IndustrySelectScreenState, apiClient, getTracks, repository, secureStorage (+7 more)

### Community 54 - "package:verifai/core/services/api_client.dart"
Cohesion: 0.22
Nodes (9): ApiClient, DioApiClient, MockApiClient, _apiClient, DashboardRepository, getDashboard, MockDashboardRepository, refreshDashboard (+1 more)

### Community 55 - "db-setup.js"
Cohesion: 0.10
Nodes (23): files, fs, path, roots, { spawnSync }, baseline(), crypto, DB_DIR (+15 more)

### Community 56 - "DailyTask"
Cohesion: 0.25
Nodes (8): @JsonSerializable, _, _, _, _, DailyTask, DailyTask, _DailyTask

### Community 58 - "generate_app_icons.py"
Cohesion: 0.29
Nodes (7): generate(), _logo_on_canvas(), Generate VerifAI launcher icons from the master icon (transparent PNG).…, Center the logo on a square canvas, scaled to `fill` of its largest side., os, pil, sys

### Community 59 - "001_prototype_to_d4.sql"
Cohesion: 0.13
Nodes (15): idx_skill_scores_user, idx_task_attempts_user, idx_task_attempts_user_task, idx_tasks_track_difficulty, idx_user_achievements_user, set_updated_at, task_attempts, trg_skill_scores_updated_at (+7 more)

### Community 60 - "@freezed"
Cohesion: 0.20
Nodes (10): @freezed, AuthResult, DashboardData, DashboardData, _DashboardData, AuthResult, User, _AuthResult (+2 more)

### Community 61 - "firebase.js"
Cohesion: 0.13
Nodes (17): { cert, getApps, initializeApp }, fs, { getAuth }, getFirebaseAdmin(), getFirebaseAuth(), loadServiceAccount(), path, { getFirebaseAuth } (+9 more)

### Community 62 - "models.dart"
Cohesion: 0.12
Nodes (16): models/achievement.dart, models/activity.dart, models/auth_state.dart, models/daily_task.dart, models/dashboard_data.dart, models/history.dart, models/industry_practice.dart, models/industry_track.dart (+8 more)

### Community 63 - "pool.js"
Cohesion: 0.10
Nodes (16): pool, syncUser(), isLocalDatabase, { Pool }, express, router, { syncUser }, { verifyFirebaseToken } (+8 more)

### Community 64 - "VerifAI Deliverable 4 Backend Handoff"
Cohesion: 0.18
Nodes (10): Database, Deliverable 4 additions, Existing teammate/backend foundation, GitHub status, Purpose, Railway status, Scoring, Security (+2 more)

### Community 65 - "auth/presentation.dart"
Cohesion: 0.50
Nodes (3): presentation/login_screen.dart, presentation/register_screen.dart, presentation/splash_screen.dart

### Community 66 - "login_flow_test.dart"
Cohesion: 0.15
Nodes (12): authStateChanges, completeOnboarding, getCurrentUser, _harness, login, logout, main, register (+4 more)

### Community 75 - "VerifAI Backend — Deliverable 4"
Cohesion: 0.22
Nodes (8): Core Deliverable 4 flow, Database, Documentation, Git workflow, Quick start, Security, Stack, VerifAI Backend — Deliverable 4

### Community 86 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.11
Nodes (18): main, getLabLesson, _LabApi, main, recordLessonProgress, main, main, _taskHarness (+10 more)

### Community 87 - "dependencies"
Cohesion: 0.18
Nodes (11): dependencies, cors, dotenv, express, express-rate-limit, firebase-admin, helmet, mammoth (+3 more)

### Community 88 - "industry_practice_screen.dart"
Cohesion: 0.14
Nodes (16): industryCaseProvider, industryCasesProvider, _block, build, _card, createState, id, IndustryCaseDetailScreen (+8 more)

### Community 89 - "achievements.js"
Cohesion: 0.19
Nodes (12): buildMilestones(), getAchievements(), getCatalog(), getMilestones(), LEVEL_MILESTONES, pool, STREAK_MILESTONES, XP_MILESTONES (+4 more)

### Community 90 - "login_screen.dart"
Cohesion: 0.12
Nodes (19): AsyncValue, auth_brand_header.dart, auth_error_messages.dart, FormState, createState, dispose, _emailController, _formKey (+11 more)

### Community 91 - "deploy"
Cohesion: 0.25
Nodes (7): deploy, healthcheckPath, healthcheckTimeout, restartPolicyMaxRetries, restartPolicyType, startCommand, $schema

### Community 92 - "flutter_window.h"
Cohesion: 0.39
Nodes (5): dart_project, flutter_view_controller, functional, memory, windows

### Community 93 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.08
Nodes (29): historyProvider, industryCaseProvider, industryCasesProvider, watch, judgementTaskProvider, watch, achievementsProvider, apiClient (+21 more)

### Community 94 - "api_error.dart"
Cohesion: 0.08
Nodes (24): Exception, ApiFailure, ApiFailureKind, _classifyDio, classifyError, _classifyStatus, _clientFallbackMessage, data (+16 more)

### Community 95 - "Migrating off `railway.json` to Infrastructure as Code"
Cohesion: 0.15
Nodes (12): Before deployment, Current state, Deploy, Footguns, Migrating off `railway.json` to Infrastructure as Code, Optional: a real `DATABASE_URL` reference, Production verification, Railway Deployment Checklist (+4 more)

### Community 96 - "welcome_tutorial_screen.dart"
Cohesion: 0.10
Nodes (20): accent, _animationController, build, bullets, _completionKey, createState, description, dispose (+12 more)

### Community 98 - "VerifAI Backend Audit — Deliverable 4"
Cohesion: 0.40
Nodes (4): Existing gaps found, Quality improvements included, VerifAI Backend Audit — Deliverable 4, Verification status

### Community 99 - "profile_screen.dart"
Cohesion: 0.08
Nodes (25): authNotifierProvider, _Badge, _badgeCatalog, _BadgeSpec, _buildAchievements, _buildBadgeGrid, _buildModernBadgeTile, _buildStatsRow (+17 more)

### Community 100 - "pull_request_template.md"
Cohesion: 0.40
Nodes (4): Checklist, How was it tested?, Type of change, What does this PR do?

### Community 107 - "api.test.js"
Cohesion: 0.07
Nodes (27): app, assert, DECISION_OPTIONS, fakeClient, firebase, LEADERBOARD_ROWS, pool, queries (+19 more)

### Community 108 - "task_run_screen.dart"
Cohesion: 0.10
Nodes (20): build, _buildLineTextAnswer, _buildOption, createState, _dimensionLabel, dispose, _fixController, _flawCard (+12 more)

### Community 109 - "auth_interceptor.dart"
Cohesion: 0.11
Nodes (17): Interceptor, AuthInterceptor, _dio, _expiredAuthorizations, _expireSession, _expiring, onError, _onSessionExpired (+9 more)

### Community 110 - "positiveIntegerParam"
Cohesion: 0.33
Nodes (8): { getAssistantReply }, pool, { positiveIntegerParam, requiredString }, sendMessage(), validateMessages(), positiveIntegerParam(), requiredString(), getAssistantReply()

### Community 111 - "veraController.js"
Cohesion: 0.07
Nodes (36): addMemory(), { buildUserContext, describeContext, buildTips, buildAppKnowledge, buildAttemptAnswers }, chat(), CONTEXTS, deleteMemory(), getSession(), { getVeraReply, streamVeraReply, extractMemories }, { handleAiError } (+28 more)

### Community 112 - "package:flutter/material.dart"
Cohesion: 0.08
Nodes (32): ConsumerWidget, labLessonProvider, build, _card, LabAssessmentsScreen, build, LabChaptersScreen, build (+24 more)

### Community 113 - "package:verifai/core/theme/app_colors.dart"
Cohesion: 0.08
Nodes (29): build, subtitle, title, _chapterTile, code, _progressChip, build, LabHomeScreen (+21 more)

### Community 114 - "interviewController.js"
Cohesion: 0.21
Nodes (12): getCurrentUser(), getQuestions(), markPracticed(), pool, { positiveIntegerParam }, { refreshReadiness }, requireTrack(), express (+4 more)

### Community 115 - "scoringService.js"
Cohesion: 0.28
Nodes (15): 5. Gap vs the current implementation, compact(), criterionMatches(), DIFFICULTY_MAX_XP, extractKeywords(), isNegatedAt(), NEGATORS, normalize() (+7 more)

### Community 116 - "List"
Cohesion: 0.12
Nodes (15): dart:typed_data, DioException, HttpClientAdapter, List, _Adapter, authed, buildDio, close (+7 more)

### Community 117 - "activity.dart"
Cohesion: 0.14
Nodes (13): Map, activity, ActivityDay, attempts, date, days, fromJson, _int (+5 more)

### Community 118 - "interview_practice_screen.dart"
Cohesion: 0.12
Nodes (18): class, apiClientProvider, reconnectApp, _block, build, _buildCard, _buildList, createState (+10 more)

### Community 119 - "capstone.test.js"
Cohesion: 0.11
Nodes (17): backend_services_capstonemarking, app, assert, ASSESSMENT, attempt, AUTO_QUESTIONS, fakeClient, firebase (+9 more)

### Community 120 - "assessment_paper_screen.dart"
Cohesion: 0.06
Nodes (33): _answers, _answerWidgets, args, build, _buildPayload, _caseStudy, code, _codeBlock (+25 more)

### Community 121 - "main_nav_shell.dart"
Cohesion: 0.13
Nodes (14): dart:ui, build, _buildNavItem, createState, _currentIndex, initialIndex, initState, _onItemTapped (+6 more)

### Community 122 - "scoring.test.js"
Cohesion: 0.15
Nodes (15): scoreByFeature(), updateProgress(), calculateLevel(), backend_services_scoringservice_fix_points, backend_services_scoringservice_reason_points, scoreFlawLines(), scoreOptions(), xpForLevel() (+7 more)

### Community 123 - "judgement_screen_test.dart"
Cohesion: 0.14
Nodes (11): ElevatedButton, build, JudgementScreen, build, RiskGovernanceScreen, _judgementTask, main, package:verifai/features/judgement/presentation/choice_task_screen.dart (+3 more)

### Community 124 - "Feature Build — AI Judgement, Risk & Governance & Interview Practice (next sprint)"
Cohesion: 0.15
Nodes (12): AI Judgement — decisions locked, API, API, API contract (freeze first), Decisions locked, Feature Build — AI Judgement, Risk & Governance & Interview Practice (next sprint), Interview Practice (Legal only for now), Noted for later (do not build now) (+4 more)

### Community 125 - "app_providers.dart"
Cohesion: 0.15
Nodes (12): Dio, dio, dioProvider, getInstance, secureStorageProvider, sharedPreferencesProvider, Provider, ../services/api_client.dart (+4 more)

### Community 126 - "progress.js"
Cohesion: 0.27
Nodes (8): getActivityHistory(), getProgress(), parseDays(), pool, express, { getProgress, getActivityHistory }, router, { verifyFirebaseToken }

### Community 127 - "milestone.dart"
Cohesion: 0.17
Nodes (11): double get, achieved, code, current, description, fromJson, _int, Milestone (+3 more)

### Community 128 - "history.dart"
Cohesion: 0.15
Nodes (12): _int, _bool, createdAt, feature, fromJson, HistoryEntry, id, passed (+4 more)

### Community 129 - "schema.sql"
Cohesion: 0.12
Nodes (28): idx_industry_cases_title, idx_industry_cases_track, idx_interview_questions_track, idx_lab_activities_lesson, idx_lab_activity_attempts, idx_lab_questions_lesson, idx_reward_redemptions_user, idx_reward_token_events_user (+20 more)

### Community 130 - "leaderboard.js"
Cohesion: 0.27
Nodes (8): buildTrackFilter(), getLeaderboard(), parseLimit(), pool, express, { getLeaderboard }, router, { verifyFirebaseToken }

### Community 131 - "vera.dart"
Cohesion: 0.07
Nodes (29): body, content, context, createdAt, fromAssistant, fromJson, id, kind (+21 more)

### Community 132 - "recovery_screen.dart"
Cohesion: 0.18
Nodes (11): _busy, createState, dispose, _email, _error, forgotEmail, RecoveryScreen, _RecoveryScreenState (+3 more)

### Community 133 - "State"
Cohesion: 0.28
Nodes (9): MainNavShell, _MainNavShellState, WelcomeTutorialScreen, _WelcomeTutorialScreenState, VerifAIInput, _VerifAIInputState, SingleTickerProviderStateMixin, State (+1 more)

### Community 134 - "lab_lessons"
Cohesion: 0.14
Nodes (16): idx_lab_lesson_sections_parent, content_sources, idx_content_sources_industry, idx_content_sources_title, idx_lab_attempts_user, idx_lab_lesson_progress_viewed, idx_lab_lessons_track, idx_lab_sections_lesson (+8 more)

### Community 135 - "interview_question.dart"
Cohesion: 0.22
Nodes (8): fromJson, id, InterviewQuestion, practiced, question, sampleAnswer, sortOrder, whatEmployersTest

### Community 136 - "VerifAI — Scoring Algorithm Review"
Cohesion: 0.25
Nodes (7): 1. What the doc specifies, 2. Strengths, 3. Weaknesses / gaps (ranked), 4. Fit with the new AI Judgement scoring, 6. Recommendations, 7. Verdict, VerifAI — Scoring Algorithm Review

### Community 137 - "P0 — Scoring metrics & readiness (canonical)"
Cohesion: 0.33
Nodes (6): AI Readiness Passport unlock (FR8), P0 — Scoring metrics & readiness (canonical), Promotion tiers (status — separate from readiness), Readiness score (weighted — skills + interview coverage), Scoring metrics (per feature), XP level curve (cosmetic)

### Community 138 - "verifai_button.dart"
Cohesion: 0.12
Nodes (16): build, createState, height, isFullWidth, isLoading, _isPressed, label, leadingIcon (+8 more)

### Community 139 - "usersController.js"
Cohesion: 0.08
Nodes (27): { clampInt }, { findUserByFirebaseUid }, getHistory(), pool, AVATAR_MIME, deleteAccount(), { findUserByFirebaseUid }, getAvatar() (+19 more)

### Community 140 - "String?"
Cohesion: 0.22
Nodes (8): Achievement, code, description, earnedAt, fromJson, id, name, String?

### Community 141 - "MessageHandler"
Cohesion: 0.36
Nodes (10): HWND, LPARAM, LRESULT, UINT, WPARAM, EnableFullDpiSupportIfAvailable(), GetHandle, GetThisFromHandle (+2 more)

### Community 142 - "industry_tracks"
Cohesion: 0.24
Nodes (11): idx_interview_questions_track, interview_practice, interview_questions, industry_tracks, seed_choice_task(), seed_interview(), seed_verification(), seed_verification_text() (+3 more)

### Community 143 - "progress_screen.dart"
Cohesion: 0.10
Nodes (19): _buildDashboard, _buildQuickLaunches, _buildShimmer, createState, initState, _statTile, _buildShimmer, _buildWeeklyChart (+11 more)

### Community 144 - "users"
Cohesion: 0.21
Nodes (12): idx_vera_messages_session, idx_vera_sessions_user, idx_workshop_posts_parent, idx_workshop_posts_track, user_avatars, user_progress, users, vera_messages (+4 more)

### Community 145 - "Codemagic Android Signing"
Cohesion: 0.40
Nodes (4): Codemagic Android Signing, Configure Codemagic, Create a signing key, Run a build

### Community 146 - "verification.dart"
Cohesion: 0.07
Nodes (29): base64, chars, claim, concern, createdAt, documentName, fromJson, id (+21 more)

### Community 147 - "002_restructure_tasks.sql"
Cohesion: 0.36
Nodes (10): idx_task_attempts_user, idx_task_attempts_user_task, idx_task_options_task, idx_verification_tasks_difficulty, judgement_tasks, risk_governance_tasks, task_attempts, task_options (+2 more)

### Community 148 - "tasks"
Cohesion: 0.20
Nodes (11): idx_task_attempts_user, idx_task_attempts_user_task, idx_task_options_task, idx_tasks_feature_track, idx_verification_tasks_difficulty, judgement_tasks, risk_governance_tasks, task_attempts (+3 more)

### Community 149 - "practiceActivities.test.js"
Cohesion: 0.14
Nodes (12): backend_services_activitygrading, ACTIVITY, app, assert, fakeClient, firebase, { gradeActivity }, LESSON (+4 more)

### Community 150 - "VerifAI Backend API"
Cohesion: 0.20
Nodes (9): Authentication, Database setup, Error format, GET /api/industry-practice/cases, GET /api/industry-practice/cases/:id, Industry Practice, POST /api/industry-practice/cases/:id/read, Scoring (+1 more)

### Community 173 - "_ProfileScreenState"
Cohesion: 0.23
Nodes (13): achievementsProvider, activityProvider, currentUserProvider, dashboardProvider, leaderboardProvider, build, build, ProfileScreen (+5 more)

### Community 174 - "track_repository.dart"
Cohesion: 0.25
Nodes (8): SecureStorageService, _apiClient, getTracks, MockTrackRepository, _secureStorage, selectTrack, TrackRepository, package:verifai/core/services/secure_storage_service.dart

### Community 175 - "Vera — AI assistant with memory"
Cohesion: 0.25
Nodes (8): DELETE /api/vera/memory/:id, GET /api/vera/memory, GET /api/vera/sessions, GET /api/vera/sessions/:id, GET /api/vera/tips, POST /api/vera/chat, POST /api/vera/memory, Vera — AI assistant with memory

### Community 176 - "lab_capstone_assessments"
Cohesion: 0.40
Nodes (5): idx_lab_capstone_attempts, idx_lab_capstone_questions, lab_capstone_assessments, lab_capstone_attempts, lab_capstone_questions

### Community 177 - "vera_assistant_screen.dart"
Cohesion: 0.07
Nodes (32): active, _bubble, build, _composer, _conversation, createState, dispose, _greeted (+24 more)

### Community 180 - "verification_studio_screen.dart"
Cohesion: 0.09
Nodes (25): MaterialPageRoute, _addCitation, _addUrl, build, _citation, _context, createState, dispose (+17 more)

### Community 181 - "rewards.dart"
Cohesion: 0.07
Nodes (27): canAfford, code, costTokens, createdAt, delta, events, fromJson, id (+19 more)

### Community 182 - "activity_screen.dart"
Cohesion: 0.08
Nodes (23): LabActivity get, activity, ActivityArgs, args, _body, build, _buildResponse, _choice (+15 more)

### Community 183 - "assessment_instructions_screen.dart"
Cohesion: 0.12
Nodes (19): assessmentAnalysisProvider, assessmentPaperProvider, AssessmentOutcome, attemptId, _block, build, code, createState (+11 more)

### Community 184 - "ConsumerState"
Cohesion: 0.23
Nodes (12): ConsumerState, ConsumerStatefulWidget, LearningAssistantScreen, _LearningAssistantScreenState, DashboardScreen, _DashboardScreenState, LabActivityScreen, _LabActivityScreenState (+4 more)

### Community 185 - "learning_assistant_screen.dart"
Cohesion: 0.09
Nodes (20): build, _composer, _conversation, createState, dispose, _input, _messages, _scroll (+12 more)

### Community 186 - "register_screen.dart"
Cohesion: 0.12
Nodes (16): _confirmPasswordController, createState, dispose, _emailController, _formKey, label, _nameController, _passwordController (+8 more)

### Community 187 - "streak.test.js"
Cohesion: 0.29
Nodes (5): computeStreak(), assert, { awardXp }, { computeStreak }, { test }

### Community 189 - "Point"
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 190 - "industry_practice.dart"
Cohesion: 0.18
Nodes (10): cause, fromJson, id, IndustryCase, read, scenario, solution, sourceTitle (+2 more)

### Community 191 - "verification_result_screen.dart"
Cohesion: 0.22
Nodes (8): Color get, build, result, _statusColor, _statusLabel, VerificationResultScreen, String get, VerificationResult

### Community 192 - "Size"
Cohesion: 0.50
Nodes (3): Size, height, width

### Community 193 - "inline_markdown_text.dart"
Cohesion: 0.22
Nodes (8): build, data, InlineMarkdownText, _spans, style, textAlign, TextAlign?, TextStyle?

### Community 195 - "dart:async"
Cohesion: 0.25
Nodes (7): dart:async, dart:io, _dio, main, request, package:dio/dio.dart, package:verifai/core/services/api_error.dart

### Community 196 - "lab/providers.dart"
Cohesion: 0.20
Nodes (9): int get, assessmentAnalysisProvider, AssessmentKey, assessmentPaperProvider, attemptId, code, hashCode, labLessonProvider (+1 more)

### Community 197 - "dashboard/providers.dart"
Cohesion: 0.25
Nodes (7): apiClient, dashboardRepositoryProvider, getDashboard, refreshDashboard, refreshDashboardProvider, repository, package:verifai/features/dashboard/data/dashboard_repository.dart

### Community 198 - "build"
Cohesion: 0.50
Nodes (4): build, Route /forgot-email, Route /forgot-password, Route /register

### Community 199 - "onboarding_flow_test.dart"
Cohesion: 0.32
Nodes (6): dart:convert, main, main, package:flutter_secure_storage/flutter_secure_storage.dart, package:shared_preferences/shared_preferences.dart, package:verifai/main.dart

### Community 200 - "apiClientProvider"
Cohesion: 0.29
Nodes (7): apiClientProvider, _continueToNextTask, _send, _start, _recordRead, _openSession, _send

### Community 201 - "_startWelcomeAndNavigate"
Cohesion: 0.22
Nodes (9): _returnToFeature, build, build, _startWelcomeAndNavigate, build, _finish, Route /dashboard, Route /industry-select (+1 more)

### Community 202 - "AI Judgement — work items"
Cohesion: 0.29
Nodes (7): AI Judgement — work items, AJ-B1 — Schema: options table, AJ-B2 — Migration, AJ-B3 — `getNextTask`: dimension filter + options, AJ-B4 — `submitAttempt`: two-part scoring path, AJ-B5 — Content: 5 tasks per track, AJ-B6 — Tests

## Knowledge Gaps
- **1798 isolated node(s):** `Authentication`, `GET /api/health`, `GET /api/tracks`, `POST /api/auth/sync`, `GET /api/users/me` (+1793 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 2114 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **69 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `coach()` connect `nvidiaAssistant.js` to `labController.js`, `verificationController.js`, `positiveIntegerParam`, `Vera — AI assistant with memory`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **Why does `POST /api/vera/chat` connect `Vera — AI assistant with memory` to `nvidiaAssistant.js`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **Why does `Vera — AI assistant with memory` connect `Vera — AI assistant with memory` to `VerifAI Backend API`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **What connects `Authentication`, `GET /api/health`, `GET /api/tracks` to the rest of the system?**
  _1798 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `package.json` be split into smaller, more focused modules?**
  _Cohesion score 0.08333333333333333 - nodes in this community are weakly interconnected._
- **Should `lab.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02 - nodes in this community are weakly interconnected._
- **Should `AppDelegate` be split into smaller, more focused modules?**
  _Cohesion score 0.07058823529411765 - nodes in this community are weakly interconnected._