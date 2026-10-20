import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/empty_state.dart';
import 'package:verifai/features/feedback/presentation/feedback_screen.dart';

/// Feedback for one attempt, fetched by id.
///
/// The result screen used to receive the whole result through `state.extra`, so
/// a restart or a deep link fell back to an empty state. `/feedback/:attemptId`
/// re-reads the attempt (score, pass flag, feedback text) and renders the same
/// screen.
final attemptFeedbackProvider =
    FutureProvider.autoDispose.family<AttemptFeedback, int>((ref, id) {
  return ref.watch(apiClientProvider).getAttemptFeedback(id);
});

class AttemptFeedbackScreen extends ConsumerWidget {
  final int attemptId;
  const AttemptFeedbackScreen({super.key, required this.attemptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(attemptFeedbackProvider(attemptId));

    return async.when(
      data: (attempt) => FeedbackScreen(
        score: attempt.score,
        passed: attempt.passed,
        feedback: attempt.feedback,
        xpEarned: attempt.xpEarned,
        onContinue: () => context.go('/dashboard'),
      ),
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Feedback'),
        ),
        body: EmptyState(
          icon: Icons.rate_review_rounded,
          title: 'Feedback unavailable',
          message: 'This attempt could not be loaded. It may belong to another '
              'account or no longer exist.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(attemptFeedbackProvider(attemptId)),
        ),
      ),
    );
  }
}
