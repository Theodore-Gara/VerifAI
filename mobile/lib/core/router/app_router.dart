import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/features/auth/presentation.dart';
import 'package:verifai/features/auth/presentation/recovery_screen.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/assistant/presentation/learning_assistant_screen.dart';
import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/features/vera/presentation/vera_assistant_screen.dart';
import 'package:verifai/features/verification_studio/presentation/verification_studio_screen.dart';
import 'package:verifai/features/lab/presentation/lab_home_screen.dart';
import 'package:verifai/features/lab/presentation/lessons_screen.dart';
import 'package:verifai/features/lab/presentation/chapters_screen.dart';
import 'package:verifai/features/lab/presentation/topics_screen.dart';
import 'package:verifai/features/lab/presentation/topic_reader_screen.dart';
import 'package:verifai/features/lab/presentation/practice_lesson_screen.dart';
import 'package:verifai/features/lab/presentation/activity_screen.dart';
import 'package:verifai/features/lab/presentation/assessments_screen.dart';
import 'package:verifai/features/lab/presentation/assessment_instructions_screen.dart';
import 'package:verifai/features/lab/presentation/assessment_paper_screen.dart';
import 'package:verifai/features/industry_practice/presentation/industry_practice_screen.dart';
import 'package:verifai/features/rewards/presentation/rewards_screen.dart';
import 'package:verifai/features/history/presentation/history_screen.dart';
import 'package:verifai/features/task/presentation/task_run_screen.dart';
import 'package:verifai/features/dashboard/providers.dart';
import 'package:verifai/features/progress/providers.dart';
import 'package:verifai/features/history/providers.dart';
import 'package:verifai/features/scoreboard/providers.dart';
import 'package:verifai/features/rewards/providers.dart';
import 'package:verifai/features/profile/providers.dart';
import 'package:verifai/features/track/providers.dart';
import 'package:verifai/features/lab/providers.dart';
import 'package:verifai/features/interview/providers.dart';
import 'package:verifai/features/judgement/providers.dart';
import 'package:verifai/features/risk_governance/providers.dart';
import 'package:verifai/features/vera/providers.dart';
import 'package:verifai/features/onboarding/providers.dart';
import 'package:verifai/features/verification_studio/providers.dart';
import 'package:verifai/features/feedback/presentation/feedback_screen.dart';
import 'package:verifai/features/navigation/main_nav_shell.dart';
import 'package:verifai/features/wellness/presentation/wellness_center_screen.dart';
import 'package:verifai/features/onboarding/presentation.dart';
import 'package:verifai/features/scoreboard/presentation/scoreboard_screen.dart';
import 'package:verifai/features/verification/presentation/verification_screen.dart';
import 'package:verifai/features/judgement/presentation/judgement_screen.dart';
import 'package:verifai/features/risk_governance/presentation/risk_governance_screen.dart';
import 'package:verifai/features/interview/presentation/interview_practice_screen.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/app_feedback_banner.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshNotifier();

  // Re-evaluate redirects whenever auth state changes WITHOUT rebuilding the
  // router (rebuilding it would reset navigation back to the splash screen).
  ref.listen<AsyncValue<AuthState>>(authStateProvider, (previous, next) {
    refreshNotifier.notify();
    // Drop ALL user-scoped caches so a newly signed-in user never sees the
    // previous user's data (shared-device data leak).
    ref.invalidate(dashboardProvider);
    ref.invalidate(activityProvider);
    ref.invalidate(historyProvider);
    ref.invalidate(rewardsProvider);
    ref.invalidate(achievementsProvider);
    ref.invalidate(milestonesProvider);
    ref.invalidate(labLessonsProvider);
    ref.invalidate(labAssessmentsProvider);
    ref.invalidate(interviewQuestionsProvider);
    ref.invalidate(judgementTaskProvider);
    ref.invalidate(riskGovernanceTaskProvider);
    ref.invalidate(veraSessionsProvider);
    ref.invalidate(veraMemoryProvider);
    ref.invalidate(veraTipsProvider);
    ref.invalidate(verificationHistoryProvider);
    ref.invalidate(tracksProvider);
    ref.invalidate(currentUserProvider);
    // Family providers — invalidating the family clears all keyed instances.
    ref.invalidate(leaderboardProvider);
    ref.invalidate(labLessonProvider);
    ref.invalidate(assessmentPaperProvider);
    ref.invalidate(assessmentAnalysisProvider);
    ref.invalidate(veraSessionProvider);
    ref.read(selectedTrackProvider.notifier).state = null;
  });

  final router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      // valueOrNull: null while loading or errored, so redirects never crash.
      final authState = ref.read(authStateProvider).valueOrNull;
      final location = state.matchedLocation;

      // Allow splash screen always
      if (location == '/splash') return null;

      // Check auth state using when pattern matching
      final bool isAuthenticated;
      final bool needsOnboarding;
      if (authState == null) {
        isAuthenticated = false;
        needsOnboarding = false;
      } else {
        isAuthenticated = authState.when(
          unauthenticated: () => false,
          authenticated: (user1, token1) => true,
          needsOnboarding: (user2, token2) => true,
          loading: () => false,
        );
        needsOnboarding = authState.when(
          unauthenticated: () => false,
          authenticated: (user3, token3) => false,
          needsOnboarding: (user4, token4) => true,
          loading: () => false,
        );
      }

      // Public routes (login, register)
      final isPublicRoute = location == '/login' ||
          location == '/register' ||
          location == '/forgot-password' ||
          location == '/forgot-email';

      if (!isAuthenticated && !isPublicRoute) {
        return '/login';
      }

      if (isAuthenticated && isPublicRoute) {
        // Redirect to appropriate screen based on onboarding status
        if (needsOnboarding) {
          return '/industry-select';
        }
        return '/dashboard';
      }

      // Check onboarding status for authenticated users
      if (needsOnboarding) {
        if (location != '/industry-select') {
          return '/industry-select';
        }
      }

      if (isAuthenticated && !needsOnboarding) {
        if (location == '/industry-select') {
          return '/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const RecoveryScreen(),
      ),
      GoRoute(
        path: '/forgot-email',
        name: 'forgot-email',
        builder: (context, state) => const RecoveryScreen(forgotEmail: true),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/industry-select',
        name: 'industry-select',
        builder: (context, state) => const IndustrySelectScreen(),
      ),
      GoRoute(
        path: '/change-industry',
        name: 'change-industry',
        builder: (context, state) =>
            const IndustrySelectScreen(isChangingIndustry: true),
      ),
      GoRoute(
        path: '/welcome-tour',
        name: 'welcome-tour',
        builder: (context, state) => const WelcomeTutorialScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const MainNavShell(initialIndex: 0),
      ),
      GoRoute(
        path: '/track',
        name: 'track',
        builder: (context, state) => const MainNavShell(initialIndex: 1),
      ),
      GoRoute(
        path: '/scoreboard',
        name: 'scoreboard',
        builder: (context, state) => const ScoreboardScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const MainNavShell(initialIndex: 4),
      ),
      GoRoute(
        path: '/tasks',
        name: 'tasks',
        builder: (context, state) => const MainNavShell(initialIndex: 2),
      ),
      GoRoute(
        path: '/verification',
        name: 'verification',
        builder: (context, state) => const VerificationScreen(),
      ),
      GoRoute(
        path: '/judgement',
        name: 'judgement',
        builder: (context, state) => const JudgementScreen(),
      ),
      GoRoute(
        path: '/risk-governance',
        name: 'risk-governance',
        builder: (context, state) => const RiskGovernanceScreen(),
      ),
      GoRoute(
        path: '/interview',
        name: 'interview',
        builder: (context, state) => const InterviewPracticeScreen(),
      ),
      GoRoute(
        path: '/task-run',
        name: 'task-run',
        builder: (context, state) {
          final args = state.extra;
          if (args is TaskRunArgs) {
            return TaskRunScreen(task: args.task, practice: args.practice);
          }
          return const Scaffold(
            body: Center(child: Text('Open a task to start.')),
          );
        },
      ),
      GoRoute(
        path: '/assistant',
        name: 'assistant',
        builder: (context, state) {
          final task = state.extra;
          if (task is DailyTask) {
            return LearningAssistantScreen(task: task);
          }
          return const VeraAssistantScreen();
        },
      ),
      GoRoute(
        path: '/verification-studio',
        name: 'verification-studio',
        builder: (context, state) => const VerificationStudioScreen(),
      ),
      GoRoute(
        path: '/ai-lab',
        name: 'ai-lab',
        builder: (context, state) => const LabHomeScreen(),
      ),
      GoRoute(
        path: '/ai-lab/lessons',
        name: 'lab-lessons',
        builder: (context, state) => const LabLessonsScreen(),
      ),
      GoRoute(
        path: '/ai-lab/lessons/:code',
        name: 'lab-chapters',
        builder: (context, state) =>
            LabChaptersScreen(code: state.pathParameters['code'] ?? ''),
      ),
      GoRoute(
        path: '/ai-lab/lessons/:code/chapter/:chapterIndex',
        name: 'lab-topics',
        builder: (context, state) => LabTopicsScreen(
          code: state.pathParameters['code'] ?? '',
          chapterIndex:
              int.tryParse(state.pathParameters['chapterIndex'] ?? '0') ?? 0,
        ),
      ),
      GoRoute(
        path: '/ai-lab/lessons/:code/topic/:index',
        name: 'lab-topic',
        builder: (context, state) => LabTopicReaderScreen(
          code: state.pathParameters['code'] ?? '',
          index: int.tryParse(state.pathParameters['index'] ?? '0') ?? 0,
        ),
      ),
      GoRoute(
        path: '/ai-lab/practice',
        name: 'lab-practice',
        builder: (context, state) => const LabLessonsScreen(practice: true),
      ),
      GoRoute(
        path: '/ai-lab/practice/activity',
        name: 'lab-activity',
        builder: (context, state) {
          final args = state.extra;
          if (args is ActivityArgs) return LabActivityScreen(args: args);
          return const Scaffold(
              body: Center(child: Text('Open a practice question.')));
        },
      ),
      GoRoute(
        path: '/ai-lab/practice/:code',
        name: 'lab-practice-lesson',
        builder: (context, state) =>
            LabPracticeScreen(code: state.pathParameters['code'] ?? ''),
      ),
      GoRoute(
        path: '/ai-lab/assessments',
        name: 'lab-assessments',
        builder: (context, state) => const LabAssessmentsScreen(),
      ),
      GoRoute(
        path: '/ai-lab/assessments/:code/paper',
        name: 'lab-assessment-paper',
        builder: (context, state) {
          final args = state.extra;
          if (args is PaperArgs) return LabAssessmentPaperScreen(args: args);
          return const Scaffold(
              body: Center(child: Text('Open an assessment to start.')));
        },
      ),
      GoRoute(
        path: '/ai-lab/assessments/:code',
        name: 'lab-assessment',
        builder: (context, state) => LabAssessmentInstructionsScreen(
          code: state.pathParameters['code'] ?? '',
          outcome: state.extra is AssessmentOutcome
              ? state.extra as AssessmentOutcome
              : null,
        ),
      ),
      GoRoute(
        path: '/industry-practice',
        name: 'industry-practice',
        builder: (context, state) => const IndustryPracticeScreen(),
      ),
      GoRoute(
        path: '/rewards',
        name: 'rewards',
        builder: (context, state) => const RewardsScreen(),
      ),
      GoRoute(
        path: '/task-history',
        name: 'task-history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/wellness',
        name: 'wellness',
        builder: (context, state) => const WellnessCenterScreen(),
      ),
      GoRoute(
        path: '/progress',
        name: 'progress',
        builder: (context, state) => const MainNavShell(initialIndex: 3),
      ),
      GoRoute(
        path: '/feedback',
        name: 'feedback',
        builder: (context, state) {
          final result = state.extra;
          // Opened without a completed attempt (deep link / restored route):
          // show the empty state instead of a misleading zero score.
          if (result is! FeedbackResult) return const FeedbackEmptyScreen();
          return FeedbackScreen(
            score: result.score,
            passed: result.passed,
            feedback: result.feedback,
            xpEarned: result.xpEarned,
            correctAnswer: result.correctAnswer,
            matchedKeywords: result.matchedKeywords,
            missedKeywords: result.missedKeywords,
            newlyEarnedAchievements: result.newlyEarnedAchievements,
            onRetry: result.task == null
                ? null
                : () => _retryTask(context, ref, result.task!),
            onContinue: () => _continueToNextTask(context, ref, result.task),
          );
        },
      ),
    ],
  );

  ref.onDispose(refreshNotifier.dispose);

  return router;
});

class GoRouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// "Continue" on the feedback screen: load the next unseen task at the same
/// difficulty and launch it in place, so the run keeps its level.
Future<void> _continueToNextTask(
  BuildContext context,
  Ref ref,
  DailyTask? task,
) async {
  if (task == null) {
    _returnToFeature(context);
    return;
  }

  // Judgement / Risk & Governance run as full-screen flows; "Continue" returns
  // to that screen (which reloads the next task) rather than reopening a sheet.
  if (_isChoiceFeature(task)) {
    _returnToFeature(context);
    return;
  }

  try {
    final next = await ref.read(apiClientProvider).getNextTask(
          feature: task.feature,
          difficulty: task.difficulty,
        );
    if (!context.mounted) return;
    if (next == null) {
      showFeedback(
        context,
        FeedbackKind.info,
        'No more tasks at this difficulty yet.',
      );
      return;
    }
    context.pushReplacement('/task-run',
        extra: TaskRunArgs(next, practice: next.isRepeat));
  } catch (_) {
    if (!context.mounted) return;
    showFeedback(
      context,
      FeedbackKind.error,
      'Could not load the next task. Please try again.',
    );
  }
}

bool _isChoiceFeature(DailyTask task) =>
    task.feature == 'judgement' || task.feature == 'risk_governance';

/// Return to the full-screen feature flow (which reloads the next task), or the
/// dashboard when there is nothing to pop.
void _returnToFeature(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/dashboard');
  }
}

void _retryTask(BuildContext context, Ref ref, DailyTask task) {
  if (_isChoiceFeature(task)) {
    _returnToFeature(context);
    return;
  }
  context.pushReplacement('/task-run',
      extra: TaskRunArgs(task, practice: true));
}
