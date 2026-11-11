import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/shared/models.dart';

/// Achievements catalog with earned and locked state (GET /api/achievements).
final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return await apiClient.getAchievementCatalog();
});

/// Staff role for the signed-in user (GET /api/auth/me). Null means the account
/// is a learner; 'super' | 'admin' | 'moderator' confines it to the admin portal.
///
/// The last resolved role is persisted with the session, because the router
/// needs it on every navigation and on app restart. Routing on a live request
/// meant a sleeping backend (10s timeout) downgraded an admin to the learner UI.
///
/// The cached value is returned immediately and refreshed in the background;
/// a network failure keeps the cached role, and only a session that never
/// resolved a role rethrows so the splash can wait instead of guessing.
final adminRoleProvider = FutureProvider<String?>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final cached = await secureStorage.getAdminRole();
  try {
    final identity = await apiClient.getMe();
    await secureStorage.saveAdminRole(identity.role);
    return identity.role;
  } catch (_) {
    if (cached == null) rethrow;
    return cached.isEmpty ? null : cached;
  }
});
