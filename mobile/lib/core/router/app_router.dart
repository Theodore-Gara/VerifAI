import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/features/auth/presentation.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/assistant/presentation/learning_assistant_screen.dart';
import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/features/task/presentation/task_run_screen.dart';
import 'package:verifai/features/dashboard/providers.dart';
import 'package:verifai/features/feedback/presentation/feedback_screen.dart';
import 'package:verifai/features/navigation/main_nav_shell.dart';
import 'package:verifai/features/onboarding/presentation.dart';
import 'package:verifai/features/scoreboard/presentation/scoreboard_screen.dart';
import 'package:verifai/features/task/presentation/task_screen.dart';
import 'package:verifai/features/verification/presentation/verification_screen.dart';
import 'package:verifai/features/judgement/presentation/judgement_screen.dart';
import 'package:verifai/features/risk_governance/presentation/risk_governance_screen.dart';
import 'package:verifai/features/interview/presentation/interview_practice_screen.dart';
import 'package:verifai/features/progress/presentation/progress_screen.dart';
import 'package:verifai/shared/models.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshNotifier();

  // Re-evaluate redirects whenever auth state changes WITHOUT rebuilding the
  // router (rebuilding it would reset navigation back to the splash screen).
  ref.listen<AsyncValue<AuthState>>(authStateProvider, (previous, next) {
    refreshNotifier.notify();
    // Drop user-scoped caches so a newly signed-in user never sees the previous
    // user's dashboard data (shared-device data leak).
    ref.invalidate(dashboardProvider);
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
      final isPublicRoute = location == '/login' || location == '/register';

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
        builder: (context, state) => const TaskScreen(),
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
          return const Scaffold(
            body: Center(child: Text('Open the assistant from a task.')),
          );
        },
      ),
      GoRoute(
        path: '/progress',
        name: 'progress',
        builder: (context, state) => const ProgressScreen(),
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
            onContinue: () =>
                _continueToNextTask(context, ref, result.task),
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

  final messenger = ScaffoldMessenger.of(context);
  try {
    final next = await ref.read(apiClientProvider).getNextTask(
          feature: task.feature,
          difficulty: task.difficulty,
        );
    if (!context.mounted) return;
    if (next == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No more tasks at this difficulty yet.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.pushReplacement('/task-run',
        extra: TaskRunArgs(next, practice: next.isRepeat));
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Could not load the next task. Please try again.'),
        behavior: SnackBarBehavior.floating,
      ),
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
  context.pushReplacement('/task-run', extra: TaskRunArgs(task, practice: true));
}
