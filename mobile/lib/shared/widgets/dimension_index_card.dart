import 'package:flutter/material.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';

/// Unified Master Bento Card ("Competency Index") displaying all readiness
/// dimensions in a single executive container with precision gauges,
/// monospaced percentages, and text-based competency tiers.
/// Strictly zero icons to maintain a clean, minimal aesthetic.
class DimensionIndexCard extends StatelessWidget {
  final Map<String, int> scores;
  final String title;

  const DimensionIndexCard({
    super.key,
    required this.scores,
    this.title = 'READINESS COMPETENCY INDEX',
  });

  static String formatLabel(String key) {
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

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'Your readiness skills will appear once a task has been scored.',
          style: AppTypography.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final entries = scores.entries.toList();
    final avgScore =
        (entries.map((e) => e.value).reduce((a, b) => a + b) / entries.length)
            .round();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    fontSize: 11.5,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '$avgScore% AVG',
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      color: AppColors.primaryNavy,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: AppColors.border),

          // Skill Rows with Hairline Dividers
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: entries.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: AppColors.border.withValues(alpha: 0.5),
            ),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _SkillRow(
                label: formatLabel(entry.key),
                value: entry.value.clamp(0, 100),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  final String label;
  final int value;

  const _SkillRow({
    required this.label,
    required this.value,
  });

  _TierInfo get _tier {
    if (value >= 85) {
      return _TierInfo(
        label: 'Expert',
        textColor: AppColors.accentGreen,
        bgColor: AppColors.accentLight,
      );
    } else if (value >= 70) {
      return _TierInfo(
        label: 'Proficient',
        textColor: AppColors.textPrimary,
        bgColor: AppColors.background,
      );
    } else if (value >= 50) {
      return _TierInfo(
        label: 'Developing',
        textColor: AppColors.textSecondary,
        bgColor: AppColors.background,
      );
    } else {
      return _TierInfo(
        label: 'Foundational',
        textColor: AppColors.textSecondary,
        bgColor: AppColors.background,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (value / 100.0).clamp(0.0, 1.0);
    final tier = _tier;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.textTheme.labelMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: tier.bgColor,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.7),
                  ),
                ),
                child: Text(
                  tier.label,
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: tier.textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 36,
                child: Text(
                  '$value%',
                  textAlign: TextAlign.end,
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.primaryNavy,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              height: 5,
              width: double.infinity,
              color: AppColors.border.withValues(alpha: 0.4),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentGreen,
                        AppColors.accentCyan,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TierInfo {
  final String label;
  final Color textColor;
  final Color bgColor;

  const _TierInfo({
    required this.label,
    required this.textColor,
    required this.bgColor,
  });
}
