import 'package:flutter/material.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/shared/models/daily_task.dart';
import 'package:verifai/shared/widgets/verifai_button.dart';

class DailyTaskCard extends StatelessWidget {
  final DailyTask task;
  final VoidCallback? onStart;
  final bool isLoading;

  const DailyTaskCard({
    super.key,
    required this.task,
    this.onStart,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGreen.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          const BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mission Header Ribbon
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primaryNavy,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.card - 1),
                topRight: Radius.circular(AppRadius.card - 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.stars_rounded,
                  size: 16,
                  color: AppColors.accentCyan,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'DAILY QUEST',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                // XP Reward Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.xpPurple, Color(0xFF6D28D9)],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.badge),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.xpPurple.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, size: 14, color: AppColors.gold),
                      const SizedBox(width: 2),
                      Text(
                        '+120 XP',
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Card Content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (task.difficulty != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(task.difficulty!).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.badge),
                        ),
                        child: Text(
                          task.difficulty!.toUpperCase(),
                          style: AppTypography.textTheme.labelSmall?.copyWith(
                            color: _getDifficultyColor(task.difficulty!),
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    const SizedBox(width: AppSpacing.sm),
                    _DimensionChip(dimension: task.dimension),
                    const Spacer(),
                    if (task.trackName != null)
                      _TrackChip(trackName: task.trackName!),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  task.title,
                  style: AppTypography.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (task.scenario != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      task.scenario!,
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                VerifAIButton(
                  label: 'Play Mission',
                  variant: VerifAIButtonVariant.verification,
                  isLoading: isLoading,
                  onPressed: onStart,
                  leadingIcon: Icons.play_arrow_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.accentGreen;
      case 'medium':
        return AppColors.warning;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _DimensionChip extends StatelessWidget {
  final String dimension;

  const _DimensionChip({required this.dimension});

  @override
  Widget build(BuildContext context) {
    final color = _getDimensionColor(dimension);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Text(
        _formatDimension(dimension),
        style: AppTypography.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }

  Color _getDimensionColor(String dimension) {
    switch (dimension.toLowerCase()) {
      case 'verification':
        return AppColors.accentGreen;
      case 'judgement':
      case 'ai_judgement':
        return AppColors.accentCyan;
      case 'prompt_design':
        return AppColors.primaryNavy;
      case 'risk_governance':
      case 'risk':
        return AppColors.warning;
      case 'human_ai_collab':
      case 'collaboration':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDimension(String dimension) {
    return dimension
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? (w[0].toUpperCase() + w.substring(1)) : '')
        .join(' ');
  }
}

class _TrackChip extends StatelessWidget {
  final String trackName;

  const _TrackChip({required this.trackName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.badge),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        trackName,
        style: AppTypography.textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}