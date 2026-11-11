import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/dashboard/providers.dart';
import 'package:verifai/features/history/providers.dart';
import 'package:verifai/features/interview/providers.dart';
import 'package:verifai/features/judgement/providers.dart';
import 'package:verifai/features/lab/providers.dart';
import 'package:verifai/features/onboarding/providers.dart';
import 'package:verifai/features/profile/providers.dart';
import 'package:verifai/features/progress/providers.dart';
import 'package:verifai/features/rewards/providers.dart';
import 'package:verifai/features/risk_governance/providers.dart';
import 'package:verifai/features/scoreboard/providers.dart';
import 'package:verifai/features/track/providers.dart';
import 'package:verifai/features/verification/providers.dart';
import 'package:verifai/features/verification_studio/providers.dart';

/// Bumped whenever the learner's industry track changes. Track-scoped screens
/// that key their state off this revision rebuild and re-fetch with the new
/// track — including family providers cached under the OLD track id, which a
/// plain invalidate would not touch until re-watched.
final trackRevisionProvider = StateProvider<int>((ref) => 0);

/// Every provider whose data depends on the learner's industry track. Called
/// after a track change so no screen keeps rendering the previous track's
/// tasks, lessons, leaderboard or readiness scores.
///
/// User-scoped (not track-scoped) providers — auth, wellness journal, Vera
/// memory — are deliberately excluded.
///
/// Accepts either a Riverpod `Ref` (from providers) or a `WidgetRef` (from
/// ConsumerState) — both expose `invalidate`, and only that is used here.
void invalidateTrackScopedProviders(dynamic ref) {
  // Content and progress.
  ref.invalidate(tracksProvider);
  ref.invalidate(dashboardProvider);
  ref.invalidate(activityProvider);
  ref.invalidate(historyProvider);
  ref.invalidate(achievementsProvider);
  ref.invalidate(rewardsProvider);
  ref.invalidate(tourStateProvider);
  ref.invalidate(roadmapProvider);

  // Practice surfaces keyed to the track's task pool.
  ref.invalidate(verificationTasksProvider);
  ref.invalidate(verificationHistoryProvider);
  ref.invalidate(judgementTaskProvider);
  ref.invalidate(riskGovernanceTaskProvider);
  ref.invalidate(interviewQuestionsProvider);

  // Learn surfaces.
  ref.invalidate(labLessonsProvider);
  ref.invalidate(labAssessmentsProvider);

  // Families — invalidating the family clears every keyed instance (e.g. the
  // leaderboard cached under the previous track id).
  ref.invalidate(leaderboardProvider);
  ref.invalidate(labLessonProvider);

  // Current-user row carries industry_track_name; refresh it so profile and
  // dashboard headers show the new track immediately.
  ref.invalidate(currentUserProvider);

  // Finally bump the revision so revision-watching screens re-fetch even when
  // they hold keyed state.
  ref.read(trackRevisionProvider.notifier).state++;
}
