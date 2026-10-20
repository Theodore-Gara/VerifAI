import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:verifai/core/providers/app_reconnect.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/dashboard/providers.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/dimension_index_card.dart';
import 'package:verifai/shared/widgets/empty_state.dart';
import 'package:verifai/shared/widgets/score_ring.dart';
import 'package:verifai/shared/widgets/shimmer_loader.dart';
import 'package:verifai/shared/widgets/verifai_button.dart';

class FeedbackScreen extends ConsumerWidget {
  final int score;
  final bool passed;
  final String feedback;
  final int xpEarned;
  final List<String> matchedKeywords;
  final List<String> missedKeywords;
  final List<Achievement> newlyEarnedAchievements;
  final Map<String, int> dimensionScores;
  final VoidCallback? onContinue;
  final VoidCallback? onRetry;
  final String? correctAnswer;

  const FeedbackScreen({
    super.key,
    required this.score,
    this.passed = false,
    required this.feedback,
    required this.xpEarned,
    this.matchedKeywords = const [],
    this.missedKeywords = const [],
    this.newlyEarnedAchievements = const [],
    this.dimensionScores = const {},
    this.onContinue,
    this.onRetry,
    this.correctAnswer,
  });

  bool get _didPass => passed;

  String get _headline => _didPass
      ? 'You found the issue. Here\'s why it matters.'
      : 'Not quite. Here\'s what to review before your next attempt.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Prefer any passed-in scores; otherwise use the live readiness breakdown which can still be loading or fail to load (handled in the section below)
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Feedback',
          style: AppTypography.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Ambient Mesh Glows
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.ambientGreen,
              ),
            ),
          ),
          Positioned(
            top: 260,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.ambientCyan,
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.sm,
                AppSpacing.screenPadding,
                100, // accommodate floating dock
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Result Bento Card (Asymmetric 2-column)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: ScoreRing(
                            score: score,
                            size: 108,
                            strokeWidth: 9,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _didPass
                                    ? AppColors.accentLight
                                    : AppColors.error.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _didPass
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    size: 12,
                                    color: _didPass
                                        ? AppColors.accentGreen
                                        : AppColors.error,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _didPass ? 'CORRECT' : 'INCORRECT',
                                    style: AppTypography.textTheme.labelSmall
                                        ?.copyWith(
                                      color: _didPass
                                          ? AppColors.accentGreen
                                          : AppColors.error,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 9.5,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.bolt_rounded,
                                    color: AppColors.primaryNavy,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '+$xpEarned XP',
                                    style: AppTypography.textTheme.labelSmall
                                        ?.copyWith(
                                      color: AppColors.primaryNavy,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Divider(color: AppColors.border.withValues(alpha: 0.6)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _headline,
                          style: AppTypography.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.3,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (feedback.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            feedback,
                            style: AppTypography.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                        if (!_didPass && correctAnswer?.isNotEmpty == true) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'A STRONGER RESPONSE',
                                  style: AppTypography.textTheme.labelSmall
                                      ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    fontSize: 9,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  correctAnswer!,
                                  style: AppTypography.textTheme.bodySmall
                                      ?.copyWith(
                                    color: AppColors.textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (newlyEarnedAchievements.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accentLight,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: AppColors.accentGreen
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.workspace_premium_rounded,
                                  color: AppColors.accentGreen,
                                  size: 15,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'New achievement: ${newlyEarnedAchievements.map((a) => a.name).join(', ')}',
                                    style: AppTypography.textTheme.labelSmall
                                        ?.copyWith(
                                      color: AppColors.accentGreen,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 9.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Matched / missed concepts
                  if (matchedKeywords.isNotEmpty ||
                      missedKeywords.isNotEmpty) ...[
                    Text(
                      'Concepts',
                      style: AppTypography.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        ...matchedKeywords
                            .map((k) => _ConceptChip(label: k, matched: true)),
                        ...missedKeywords
                            .map((k) => _ConceptChip(label: k, matched: false)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Skill Breakdown
                  Text(
                    'Skill Breakdown',
                    style: AppTypography.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (dimensionScores.isNotEmpty)
                    DimensionIndexCard(scores: dimensionScores)
                  else
                    ...dashboardAsync.when(
                      data: (data) => [
                        DimensionIndexCard(scores: data.dimensionScores),
                      ],
                      loading: () => const <Widget>[
                        ShimmerLoader(height: 120),
                      ],
                      error: (error, _) => <Widget>[
                        InlineErrorCard(
                          error: error,
                          fallbackMessage:
                              'We could not load your skill breakdown.',
                          onRetry: () => reconnectApp(ref),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom Continue Action
      bottomNavigationBar: onContinue != null || onRetry != null
          ? SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.sm,
                  AppSpacing.screenPadding,
                  MediaQuery.of(context).padding.bottom > 0 ? 8 : 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_didPass && onRetry != null) ...[
                      OutlinedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text('Try this task again'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (onContinue != null)
                      VerifAIButton(
                        label: 'Continue',
                        variant: VerifAIButtonVariant.verification,
                        onPressed: onContinue,
                        trailingIcon: Icons.arrow_forward_rounded,
                      ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _ConceptChip extends StatelessWidget {
  final String label;
  final bool matched;

  const _ConceptChip({required this.label, required this.matched});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: matched
                  ? AppColors.accentGreen
                  : AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.textTheme.labelSmall?.copyWith(
              color: matched ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carries a completed attempt's outcome to the /feedback route via `extra`.
class FeedbackResult {
  final int score;
  final bool passed;
  final String feedback;
  final int xpEarned;
  final List<String> matchedKeywords;
  final List<String> missedKeywords;
  final List<Achievement> newlyEarnedAchievements;
  final String? correctAnswer;
  final DailyTask? task;

  const FeedbackResult({
    required this.score,
    this.passed = false,
    required this.feedback,
    required this.xpEarned,
    this.matchedKeywords = const [],
    this.missedKeywords = const [],
    this.newlyEarnedAchievements = const [],
    this.correctAnswer,
    this.task,
  });
}

/// Shown when /feedback is opened without a completed attempt (deep link, estored route, ...). Showing a zero score there would look like a failed attempt, which it is not.
class FeedbackEmptyScreen extends StatelessWidget {
  const FeedbackEmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Feedback',
          style: AppTypography.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: EmptyState(
        icon: Icons.rate_review_rounded,
        title: 'No feedback yet',
        message:
            'Complete a task to see your personalised feedback and skill breakdown here.',
        actionLabel: 'Back to dashboard',
        onAction: () => context.go('/dashboard'),
      ),
    );
  }
}
