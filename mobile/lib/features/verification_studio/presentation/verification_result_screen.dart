import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/shared/models.dart';

/// Shows a Verification Studio report.
class VerificationResultScreen extends StatelessWidget {
  const VerificationResultScreen({super.key, required this.result});
  final VerificationResult result;

  String get _statusLabel => switch (result.overallStatus) {
        'appears_sound' => 'Appears sound',
        'insufficient_evidence' => 'Insufficient evidence',
        _ => 'Human review required',
      };

  Color get _statusColor => switch (result.overallStatus) {
        'appears_sound' => AppColors.accentGreen,
        'insufficient_evidence' => AppColors.info,
        _ => AppColors.goldDark,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text('Verification report',
            style: AppTypography.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm,
            AppSpacing.screenPadding, AppSpacing.xxl),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: _statusColor.withValues(alpha: .4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(result.needsReview ? Icons.report_problem_rounded : Icons.verified_rounded,
                        color: _statusColor),
                    const SizedBox(width: 8),
                    Text(_statusLabel,
                        style: AppTypography.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
                  ],
                ),
                if (result.documentName != null) ...[
                  const SizedBox(height: 4),
                  Text(result.documentName!,
                      style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (result.summary.isNotEmpty) ...[
            Text('SUMMARY',
                style: AppTypography.textTheme.labelSmall
                    ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: .5)),
            const SizedBox(height: 6),
            Text(result.summary, style: AppTypography.textTheme.bodyMedium?.copyWith(height: 1.5)),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text('ITEMS REQUIRING REVIEW (${result.items.length})',
              style: AppTypography.textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: .5)),
          const SizedBox(height: AppSpacing.sm),
          if (result.items.isEmpty)
            Text('Nothing flagged.',
                style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary))
          else
            for (final item in result.items)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.claim,
                        style: AppTypography.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primaryNavy)),
                    const SizedBox(height: 4),
                    Text(item.concern,
                        style: AppTypography.textTheme.bodySmall?.copyWith(height: 1.4)),
                  ],
                ),
              ),
          if (result.sources.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('SOURCES (${result.sources.length})',
                style: AppTypography.textTheme.labelSmall
                    ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: .5)),
            const SizedBox(height: AppSpacing.sm),
            for (final s in result.sources)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () {
                    final uri = Uri.tryParse(s.url);
                    if (uri != null) {
                      launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) => false);
                    }
                  },
                  child: Text('• ${s.title}\n  ${s.url}',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                          height: 1.4, color: AppColors.info, decoration: TextDecoration.underline)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
