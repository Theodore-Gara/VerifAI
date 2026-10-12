import 'package:flutter/material.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';

class XPBar extends StatelessWidget {
  final int currentXP;
  final int nextLevelXP;
  final int level;
  final bool compact;

  const XPBar({
    super.key,
    required this.currentXP,
    required this.nextLevelXP,
    this.level = 1,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        (currentXP / (nextLevelXP > 0 ? nextLevelXP : 1)).clamp(0.0, 1.0);

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: AppColors.xpPurple,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: [
                BoxShadow(
                  color: AppColors.xpPurple.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              'LVL $level',
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 9.5,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            width: 68,
            height: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Stack(
                children: [
                  Container(color: AppColors.xpPurpleLight),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.xpPurple, AppColors.accentCyan],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.xpPurple, Color(0xFF6D28D9)],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.xpPurple.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'LVL $level',
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'AI Practitioner',
                    style: AppTypography.textTheme.labelMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
              Text(
                '$currentXP / $nextLevelXP XP',
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              height: 7,
              color: AppColors.border.withValues(alpha: 0.6),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.xpPurple, AppColors.accentCyan],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
