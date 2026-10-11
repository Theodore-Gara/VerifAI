import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/shared/models.dart';

/// Leaderboard for a scope: `null` = global, an industry-track id = that track.
/// Backed by `GET /api/leaderboard`.
final leaderboardProvider =
    FutureProvider.family<LeaderboardData, int?>((ref, trackId) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getLeaderboard(trackId: trackId);
});
