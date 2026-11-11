import 'package:flutter/material.dart';

import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/shared/widgets/score_ring.dart';
import 'package:verifai/shared/widgets/xp_bar.dart';

/// Product previews for the welcome tour.
///
/// The tour shows the app rather than describing it: page 3 previews the
/// readiness profile, page 4 previews progress. Both use the same widgets
/// the real screens use, so a preview cannot drift away from the product.
///
/// The numbers are always a labelled sample. A learner on their first day has
/// no scores, and an empty ring sells nothing — but showing them a real
/// "62% readiness" would read as their own result. Labelling it as an
/// example keeps the picture honest.

/// The sample profile the readiness preview shows.
class _SampleProfile {
  static const score = 62;
  static const tier = 'Novice';

  /// The three assessed skills and their sample scores.
  static const dimensions = <String, int>{
    'Verification': 58,
    'AI Judgement': 44,
    'Risk & Governance': 31,
  };
}

/// Page 3: a preview of the readiness profile a learner builds up.
///
/// A score ring beside the three assessed skills, so the learner sees that
/// practice fills in each one and that the ring is a summary of them.
class ReadinessPreview extends StatelessWidget {
  const ReadinessPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final dimensions = _SampleProfile.dimensions.entries.toList();
    final max = dimensions.isEmpty
        ? 0
        : dimensions.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return _PreviewFrame(
      label: 'Example profile',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Semantics(
            label: 'Example AI readiness score '
                '${_SampleProfile.score} out of 100, '
                '${_SampleProfile.tier} tier',
            child: const ExcludeSemantics(
              child: ScoreRing(
                score: _SampleProfile.score,
                size: 96,
                strokeWidth: 9,
                tierLabel: _SampleProfile.tier,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in dimensions) ...[
                  Text(
                    entry.key,
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: _PreviewBar(
                          value: entry.value,
                          max: max,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${entry.value}%',
                        style:
                            AppTypography.textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Page 4: a preview of the progress a learner accumulates.
///
/// The AI Practitioner level bar, the streak and task counters, and a week
/// of XP activity — the same three things the Progress screen shows.
class ProgressPreview extends StatelessWidget {
  const ProgressPreview({super.key});

  /// Sample level curve: level 3 sits at 240 of 400 XP.
  static const _level = 3;
  static const _xpIntoLevel = 240;
  static const _xpForNextLevel = 400;

  /// A believable week of practice: Mon through Sun, with today still open.
  static const _weeklyXp = <int>[70, 40, 90, 55, 80, 20, 0];

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _PreviewFrame(
          label: 'Example progress',
          padding: EdgeInsets.all(AppSpacing.md),
          child: XPBar(
            currentXP: _xpIntoLevel,
            nextLevelXP: _xpForNextLevel,
            level: _level,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        _PreviewFrame(
          label: 'Example progress',
          padding: EdgeInsets.all(AppSpacing.md),
          child: _WeeklyStrip(xp: _weeklyXp),
        ),
      ],
    );
  }
}

/// The card frame every preview sits in, with the sample label that keeps the
/// illustration honest.
class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({
    required this.label,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final String label;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 5),
              Text(
                label.toUpperCase(),
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// A proportion bar for one skill.
class _PreviewBar extends StatelessWidget {
  const _PreviewBar({required this.value, required this.max});

  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    final factor = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        height: 6,
        color: AppColors.border.withValues(alpha: 0.6),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: factor,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accentGreen, AppColors.accentCyan],
              ),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ),
      ),
    );
  }
}


/// Seven days of XP, the same shape as the weekly chart on the Progress
/// screen.
class _WeeklyStrip extends StatelessWidget {
  const _WeeklyStrip({required this.xp});

  final List<int> xp;

  static const _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final max = xp.isEmpty ? 0 : xp.reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Practice activity',
          style: AppTypography.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 56,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < xp.length; i++)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: 8 + 26 * (max == 0 ? 0 : xp[i] / max),
                        decoration: BoxDecoration(
                          color: xp[i] > 0
                              ? AppColors.primaryNavy
                              : AppColors.border.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _labels[i],
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
