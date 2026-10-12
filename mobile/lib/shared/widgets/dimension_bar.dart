import 'package:flutter/material.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';

class DimensionBar extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Color? progressColor;
  final bool showValue;
  final IconData? icon;

  const DimensionBar({
    super.key,
    required this.label,
    required this.value,
    this.maxValue = 100,
    this.progressColor,
    this.showValue = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value / maxValue).clamp(0.0, 1.0);
    final color = progressColor ?? AppColors.accentGreen;

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.textTheme.labelMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              if (showValue)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '$value%',
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              height: 6.5,
              color: AppColors.border.withValues(alpha: 0.6),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color,
                            color.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
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
