import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/dashboard/providers.dart';
import 'package:verifai/features/history/providers.dart';
import 'package:verifai/features/interview/providers.dart';
import 'package:verifai/features/lab/providers.dart';
import 'package:verifai/features/industry_practice/providers.dart';
import 'package:verifai/features/profile/providers.dart';
import 'package:verifai/features/progress/providers.dart';
import 'package:verifai/features/rewards/providers.dart';
import 'package:verifai/features/scoreboard/providers.dart';
import 'package:verifai/features/track/providers.dart';

/// Refreshes the learner's data when the app comes back to the foreground.
///
/// The data providers are deliberately long-lived (no `autoDispose`): keeping
/// them alive means switching tabs never re-fetches, but it also meant a
/// learner could stare at yesterday's XP because nothing ever invalidated them.
/// Returning to the app is the natural moment to re-read — it is cheap, it
/// covers every screen at once, and it does not flicker a tab that is on
/// screen (the previous value is kept while the new one loads).
///
/// Resumes within [minimumInterval] of the previous refresh are ignored, so
/// flicking to the notification shade and back does not trigger a burst.
class ResumeRefresh extends ConsumerStatefulWidget {
  const ResumeRefresh({super.key, required this.child});

  final Widget child;

  static const minimumInterval = Duration(seconds: 30);

  @override
  ConsumerState<ResumeRefresh> createState() => _ResumeRefreshState();
}

class _ResumeRefreshState extends ConsumerState<ResumeRefresh>
    with WidgetsBindingObserver {
  DateTime? _lastRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final now = DateTime.now();
    if (_lastRefresh != null &&
        now.difference(_lastRefresh!) < ResumeRefresh.minimumInterval) {
      return;
    }
    _lastRefresh = now;
    _refreshLearnerData();
  }

  void _refreshLearnerData() {
    final signedIn = ref.read(currentUserProvider).valueOrNull != null;
    if (!signedIn) return;
    // Providers that hold server state the learner expects to be current.
    ref.invalidate(dashboardProvider);
    ref.invalidate(activityProvider);
    ref.invalidate(achievementsProvider);
    ref.invalidate(milestonesProvider);
    ref.invalidate(historyProvider);
    ref.invalidate(rewardsProvider);
    ref.invalidate(labLessonsProvider);
    ref.invalidate(labAssessmentsProvider);
    ref.invalidate(interviewQuestionsProvider);
    ref.invalidate(industryCasesProvider);
    ref.invalidate(leaderboardProvider);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
