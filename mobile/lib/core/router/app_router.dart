import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/features/auth/presentation.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/feedback/presentation/feedback_screen.dart';
import 'package:verifai/features/navigation/main_nav_shell.dart';
import 'package:verifai/features/onboarding/presentation.dart';
import 'package:verifai/features/progress/presentation/progress_screen.dart';
import 'package:verifai/features/task/presentation/task_screen.dart';
import 'package:verifai/shared/models.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshNotifier();

  // Re-evaluate redirects whenever auth state changes WITHOUT rebuilding the
  // router (rebuilding it would reset navigation back to the splash screen).
  ref.listen<AsyncValue<AuthState>>(authStateProvider, (previous, next) {
    refreshNotifier.notify();
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
        builder: (context, state) => const MainNavShell(initialIndex: 2),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const MainNavShell(initialIndex: 3),
      ),
      GoRoute(
        path: '/tasks',
        name: 'tasks',
        builder: (context, state) => const TaskScreen(),
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
          final result = state.extra is FeedbackResult
              ? state.extra! as FeedbackResult
              : const FeedbackResult(score: 0, feedback: '', xpEarned: 0);
          return FeedbackScreen(
            score: result.score,
            feedback: result.feedback,
            xpEarned: result.xpEarned,
            onContinue: () => context.pop(),
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