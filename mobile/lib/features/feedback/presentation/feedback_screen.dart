import 'package:flutter/material.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/shared/widgets/dimension_bar.dart';
import 'package:verifai/shared/widgets/empty_state.dart';
import 'package:verifai/shared/widgets/score_ring.dart';
import 'package:verifai/shared/widgets/verifai_button.dart';

class FeedbackScreen extends StatelessWidget {
  final int score;
  final String feedback;
  final int xpEarned;
  final Map<String, int> dimensionScores;
  final VoidCallback? onContinue;

  const FeedbackScreen({
    super.key,
    required this.score,
    required this.feedback,
    required this.xpEarned,
    this.dimensionScores = const {},
    this.onContinue,
  });

  static const Map<String, int> _defaultDimensionScores = {
    'Verification': 78,
    'AI Judgement': 64,
    'Prompt Design': 71,
    'Risk & Governance': 55,
  };

  bool get _passed => score >= 60;

  String get _headline => _passed
      ? 'Nice catch — that\'s exactly the instinct employers look for.'
      : 'Close one. Here\'s where it slipped, and how to nail it next time.';

  @override
  Widget build(BuildContext context) {
    final dimensions =
        dimensionScores.isEmpty ? _defaultDimensionScores : dimensionScores;

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
                            color: _passed
                                ? AppColors.accentLight
                                : AppColors.goldLight,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            _passed ? 'PASSED' : 'ALMOST THERE',
                            style: AppTypography.textTheme.labelSmall?.copyWith(
                              color: _passed
                                  ? AppColors.accentGreen
                                  : AppColors.goldDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 9.5,
                              letterSpacing: 0.5,
                            ),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Dimension Breakdown
                  Text(
                    'Dimension Breakdown',
                    style: AppTypography.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...dimensions.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: DimensionBar(
                        label: entry.key,
                        value: entry.value,
                        icon: Icons.insights_rounded,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom Continue Action
      bottomNavigationBar: onContinue != null
          ? SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.sm,
                  AppSpacing.screenPadding,
                  MediaQuery.of(context).padding.bottom > 0 ? 8 : 16,
                ),
                child: VerifAIButton(
                  label: 'Continue',
                  variant: VerifAIButtonVariant.verification,
                  onPressed: onContinue,
                  trailingIcon: Icons.arrow_forward_rounded,
                ),
              ),
            )
          : null,
    );
  }
}

/// Carries a completed attempt\'s outcome to the /feedback route via `extra`.
class FeedbackResult {
  final int score;
  final String feedback;
  final int xpEarned;

  const FeedbackResult({
    required this.score,
    required this.feedback,
    required this.xpEarned,
  });
}

/// Placeholder page variant used when the screen is opened standalone
/// without a completed attempt (e.g. from navigation).
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
      body: const EmptyState(
        icon: Icons.rate_review_rounded,
        title: 'No feedback yet',
        message:
            'Complete a mission to see your personalised feedback and dimension breakdown here.',
      ),
    );
  }
}
