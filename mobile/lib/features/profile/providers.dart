import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/shared/models.dart';

/// Achievements the signed-in user has earned (GET /api/achievements/me).
final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return await apiClient.getAchievements();
});

/// Staff identity for the signed-in user (GET /api/auth/me). Null role means
/// a regular learner; 'super' | 'admin' | 'moderator' drives the profile role
/// badge and the Admin Panel entry point.
final adminIdentityProvider = FutureProvider<AdminIdentity?>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    return await apiClient.getMe();
  } catch (_) {
    return null; // offline or not staff — profile renders without the badge
  }
});
