import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/features/dashboard/providers.dart';
import 'package:verifai/features/onboarding/providers.dart';
import 'package:verifai/features/profile/providers.dart';
import 'package:verifai/features/progress/providers.dart';
import 'package:verifai/features/scoreboard/providers.dart';
import 'package:verifai/features/track/providers.dart';

/// App-wide reconnect for every screen's retry button. Pinging the (public)
/// health endpoint gives the Render free-tier instance time to wake up
/// (~50s), then all feature data is refetched at once so the whole app comes
/// back rather than just the screen the retry was tapped on.
///
/// Returns whether the backend answered. On failure the screens simply keep
/// showing their error state so the user can retry again.
Future<bool> reconnectApp(WidgetRef ref) async {
  try {
    await ref.read(apiClientProvider).ping();
  } catch (_) {
    return false;
  }
  ref.invalidate(dashboardProvider);
  ref.invalidate(activityProvider);
  ref.invalidate(achievementsProvider);
  ref.invalidate(leaderboardProvider);
  ref.invalidate(milestonesProvider);
  ref.invalidate(tracksProvider);
  return true;
}
