import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/navigation/sections.dart';
import 'package:verifai/shared/models.dart';

/// Shows a Verification Studio report.
class VerificationResultScreen extends StatelessWidget {
  const VerificationResultScreen({super.key, required this.result});
  final VerificationResult result;

  /// One pill in the what-was-checked strip.
  Widget _checkChip(
      {required String label, required String detail, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accentLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accentGreen),
          const SizedBox(width: 5),
          Text(
            detail.isEmpty ? label : '$label · $detail',
            style: AppTypography.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

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
            style: AppTypography.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
        actions: [
          IconButton(
            tooltip: 'Home',
            icon: const Icon(Icons.home_outlined),
            onPressed: () => goHome(context),
          ),
          IconButton(
            tooltip: 'All sections',
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => showAllSectionsSheet(context),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
            AppSpacing.sm, AppSpacing.screenPadding, AppSpacing.xxl),
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
                    Icon(
                        result.needsReview
                            ? Icons.report_problem_rounded
                            : Icons.verified_rounded,
                        color: _statusColor),
                    const SizedBox(width: 8),
                    Text(_statusLabel,
                        style: AppTypography.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryNavy)),
                  ],
                ),
                if (result.documentName != null) ...[
                  const SizedBox(height: 4),
                  Text(result.documentName!,
                      style: AppTypography.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // What was checked: the analysis inputs, whether the web was
          // searched and how many sources were confirmed — so the learner can
          // see the scope of the report at a glance.
          if (result.inputs.isNotEmpty ||
              result.webSearched ||
              result.sourcesConfirmed > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.border),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('WHAT WAS CHECKED',
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                          letterSpacing: .5)),
                  for (final input in result.inputs)
                    _checkChip(
                      label: input.label.isEmpty ? input.type : input.label,
                      detail: '${input.chars} chars',
                      icon: input.type == 'url'
                          ? Icons.link_rounded
                          : input.type == 'document'
                              ? Icons.description_rounded
                              : Icons.notes_rounded,
                    ),
                  if (result.webSearched)
                    _checkChip(
                        label: 'Web search',
                        detail: 'run',
                        icon: Icons.travel_explore_rounded),
                  if (result.sourcesConfirmed > 0)
                    _checkChip(
                        label: '${result.sourcesConfirmed} sources confirmed',
                        detail: '',
                        icon: Icons.verified_rounded),
                ],
              ),
            ),
          if (result.summary.isNotEmpty) ...[
            Text('SUMMARY',
                style: AppTypography.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: .5)),
            const SizedBox(height: 6),
            Text(result.summary,
                style:
                    AppTypography.textTheme.bodyMedium?.copyWith(height: 1.5)),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text('ITEMS REQUIRING REVIEW (${result.items.length})',
              style: AppTypography.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: .5)),
          const SizedBox(height: AppSpacing.sm),
          if (result.items.isEmpty)
            Text('Nothing flagged.',
                style: AppTypography.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary))
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
                        style: AppTypography.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy)),
                    const SizedBox(height: 4),
                    Text(item.concern,
                        style: AppTypography.textTheme.bodySmall
                            ?.copyWith(height: 1.4)),
                  ],
                ),
              ),
          if (result.sources.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('SOURCES (${result.sources.length})',
                style: AppTypography.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: .5)),
            const SizedBox(height: AppSpacing.sm),
            for (final s in result.sources)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () {
                    final uri = Uri.tryParse(s.url);
                    if (uri != null) {
                      launchUrl(uri, mode: LaunchMode.externalApplication)
                          .catchError((_) => false);
                    }
                  },
                  child: Text('• ${s.title}\n  ${s.url}',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                          height: 1.4,
                          color: AppColors.info,
                          decoration: TextDecoration.underline)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
