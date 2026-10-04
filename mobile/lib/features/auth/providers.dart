import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/features/auth/data/auth_repository.dart';
import 'package:verifai/features/auth/data/auth_repository.dart' as auth_data;
import 'package:verifai/shared/models.dart';

final authRepositoryProvider = FutureProvider<AuthRepository>((ref) async {
  final secureStorage = ref.watch(secureStorageProvider);
  final apiClient = ref.watch(apiClientProvider);
  return auth_data.FirebaseAuthRepository(
    secureStorage: secureStorage,
    apiClient: apiClient,
  );
});

final authStateProvider = StreamProvider<AuthState>((ref) async* {
  final repository = await ref.watch(authRepositoryProvider.future);
  // Emit the restored session (if any) first, so the router knows on startup,
  // then follow live auth changes (login / register / onboarding / logout).
  User? user;
  try {
    user = await repository.getCurrentUser();
  } catch (e) {
    debugPrint('authStateProvider: getCurrentUser failed: $e');
    user = null;
  }
  if (user == null) {
    yield const AuthState.unauthenticated();
  } else if (!user.hasCompletedOnboarding) {
    yield AuthState.needsOnboarding(user: user, token: '');
  } else {
    yield AuthState.authenticated(user: user, token: '');
  }
  yield* repository.authStateChanges();
});

/// The signed-in user, derived from [authStateProvider] so it always tracks
/// the current session. Reading it from storage directly would cache the
/// previous user across login/logout (a cross-user data leak on shared devices).
final currentUserProvider = FutureProvider<User?>((ref) async {
  final auth = ref.watch(authStateProvider);
  return auth.valueOrNull?.when(
    unauthenticated: () => null,
    authenticated: (user, _) => user,
    needsOnboarding: (user, _) => user,
    loading: () => null,
  );
});

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    try {
      final repository = await ref.read(authRepositoryProvider.future);
      final user = await repository.getCurrentUser();
      if (user == null) return const AuthState.unauthenticated();
      if (!user.hasCompletedOnboarding) {
        return AuthState.needsOnboarding(user: user, token: '');
      }
      return AuthState.authenticated(user: user, token: '');
    } catch (e) {
      // Handle corrupted secure storage or other errors gracefully
      debugPrint('AuthNotifier.build() error: $e');
      return const AuthState.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    final previous = state.valueOrNull;
    state = const AsyncLoading();
    try {
      final repository = await ref.read(authRepositoryProvider.future);
      final result = await repository.login(email, password);
      state = AsyncData(
        result.user.hasCompletedOnboarding
            ? AuthState.authenticated(user: result.user, token: result.token)
            : AuthState.needsOnboarding(user: result.user, token: result.token),
      );
    } catch (e) {
      // Surface the error to listeners, then restore a usable state so the
      // screen isn't stuck showing the error (and error snackbars don't stack).
      state = AsyncError(e, StackTrace.current);
      state = AsyncData(previous ?? const AuthState.unauthenticated());
    }
  }

  Future<void> register(String email, String password, String name) async {
    final previous = state.valueOrNull;
    state = const AsyncLoading();
    try {
      final repository = await ref.read(authRepositoryProvider.future);
      final result = await repository.register(email, password, name);
      state = AsyncData(AuthState.needsOnboarding(user: result.user, token: result.token));
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      state = AsyncData(previous ?? const AuthState.unauthenticated());
    }
  }

  Future<void> completeOnboarding() async {
    final repository = await ref.read(authRepositoryProvider.future);
    await repository.completeOnboarding();
    final user = await repository.getCurrentUser();
    if (user != null) {
      state = AsyncData(AuthState.authenticated(user: user, token: ''));
    }
  }

  Future<void> logout() async {
    final previous = state.valueOrNull;
    state = const AsyncLoading();
    try {
      final repository = await ref.read(authRepositoryProvider.future);
      await repository.logout();
      state = const AsyncData(AuthState.unauthenticated());
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      state = AsyncData(previous ?? const AuthState.unauthenticated());
    }
  }

  Future<void> signInWithGoogle() async {
    final previous = state.valueOrNull;
    state = const AsyncLoading();
    try {
      final repository = await ref.read(authRepositoryProvider.future);
      final result = await repository.signInWithGoogle();
      state = AsyncData(
        result.user.hasCompletedOnboarding
            ? AuthState.authenticated(user: result.user, token: result.token)
            : AuthState.needsOnboarding(user: result.user, token: result.token),
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      state = AsyncData(previous ?? const AuthState.unauthenticated());
      rethrow;
    }
  }
}