import 'package:flutter/material.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';

class SampleDataBanner extends StatelessWidget {
  final String message;

  const SampleDataBanner({
    super.key,
    this.message =
        'Preview with sample data. This screen does not reflect your real activity yet.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.goldLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline_rounded,
                size: 16, color: AppColors.goldDark),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.goldDark,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small inline tag for a single illustrative widget (for example one chart).
class SampleDataPill extends StatelessWidget {
  const SampleDataPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.goldLight,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'SAMPLE DATA',
        style: AppTypography.textTheme.labelSmall?.copyWith(
          color: AppColors.goldDark,
          fontWeight: FontWeight.w800,
          fontSize: 9,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
