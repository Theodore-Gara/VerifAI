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
import 'package:verifai/shared/widgets/dimension_bar.dart';
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
              decoration: const BoxDecoration(
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
              decoration: const BoxDecoration(
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
                  // Hero Result Bento Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryNavy.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                        const BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _didPass
                                ? AppColors.accentLight
                                : AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
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
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ScoreRing(score: score, size: 132, strokeWidth: 12),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _headline,
                          style: AppTypography.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.35,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (feedback.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            feedback,
                            style: AppTypography.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        if (!_didPass && correctAnswer?.isNotEmpty == true) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.accentLight,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card),
                              border: Border.all(
                                color: AppColors.accentGreen
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'A STRONGER RESPONSE',
                                  style: AppTypography.textTheme.labelSmall
                                      ?.copyWith(
                                    color: AppColors.accentGreen,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  correctAnswer!,
                                  style: AppTypography.textTheme.bodyMedium
                                      ?.copyWith(
                                    color: AppColors.textPrimary,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        // XP Reward Row
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.xpPurpleLight,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(
                                color:
                                    AppColors.xpPurple.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt_rounded,
                                  color: AppColors.xpPurple, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '+$xpEarned XP',
                                style: AppTypography.textTheme.labelLarge
                                    ?.copyWith(
                                  color: AppColors.xpPurple,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Newly earned achievements
                        if (newlyEarnedAchievements.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.accentLight,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card),
                              border: Border.all(
                                  color: AppColors.accentGreen
                                      .withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.workspace_premium_rounded,
                                    color: AppColors.accentGreen, size: 20),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'New achievement: ${newlyEarnedAchievements.map((a) => a.name).join(', ')}',
                                    style: AppTypography.textTheme.labelMedium
                                        ?.copyWith(
                                      color: AppColors.accentGreen,
                                      fontWeight: FontWeight.w800,
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
                    ..._dimensionBars(dimensionScores)
                  else
                    ...dashboardAsync.when(
                      data: (data) => data.dimensionScores.isEmpty
                          ? [
                              Text(
                                'Your readiness skills will appear once a task has been scored.',
                                style: AppTypography.textTheme.bodyMedium
                                    ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ]
                          : _dimensionBars(data.dimensionScores),
                      loading: () => const <Widget>[
                        ShimmerLoader(height: 16),
                        SizedBox(height: AppSpacing.sm),
                        ShimmerLoader(height: 16),
                        SizedBox(height: AppSpacing.sm),
                        ShimmerLoader(height: 16),
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

  List<Widget> _dimensionBars(Map<String, int> dimensions) {
    return dimensions.entries
        .map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: DimensionBar(
                label: _dimensionLabel(entry.key),
                value: entry.value,
              ),
            ))
        .toList();
  }

  String _dimensionLabel(String key) {
    const labels = {
      'verification': 'Verification',
      'judgement': 'AI Judgement',
      'ai_judgement': 'AI Judgement',
      'prompt_design': 'Prompt Design',
      'risk_governance': 'Risk & Governance',
      'human_ai_collab': 'Human-AI Collaboration',
    };
    return labels[key] ??
        key
            .replaceAll('_', ' ')
            .split(' ')
            .map(
                (w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');
  }
}

class _ConceptChip extends StatelessWidget {
  final String label;
  final bool matched;

  const _ConceptChip({required this.label, required this.matched});

  @override
  Widget build(BuildContext context) {
    final color = matched ? AppColors.accentGreen : AppColors.goldDark;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: matched ? AppColors.accentLight : AppColors.goldLight,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            matched ? Icons.check_circle_rounded : Icons.remove_circle_outline,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
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
