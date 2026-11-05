import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/shared/models.dart';

/// Achievements catalog with earned and locked state (GET /api/achievements).
final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return await apiClient.getAchievementCatalog();
});

/// Staff identity for the signed-in user (GET /api/auth/me). Null role means
/// a regular learner; 'super' | 'admin' | 'moderator' drives the profile role
/// badge and the Admin Panel entry point.
/// autoDispose so the check re-runs every time the profile screen opens: an
/// account promoted to staff while the app is running gets the entry point on
/// the next profile visit instead of only after an app restart.
final adminIdentityProvider = FutureProvider.autoDispose<AdminIdentity?>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    return await apiClient.getMe();
  } catch (_) {
    return null; // offline or not staff — profile renders without the badge
  }
});
