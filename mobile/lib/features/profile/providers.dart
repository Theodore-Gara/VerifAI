import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/shared/models.dart';

/// Achievements catalog with earned and locked state (GET /api/achievements).
final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return await apiClient.getAchievementCatalog();
});

/// Staff identity for the signed-in user (GET /api/auth/me). Null role means
/// a regular learner; 'super' | 'admin' | 'moderator' confines the account to
/// the native admin portal.
///
/// Kept alive because the router uses it to decide between the learner app and
/// the admin portal on every navigation. Invalidate it on auth changes.
final adminIdentityProvider = FutureProvider<AdminIdentity?>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    return await apiClient.getMe();
  } catch (_) {
    return null; // offline or not staff — profile renders without the badge
  }
});
