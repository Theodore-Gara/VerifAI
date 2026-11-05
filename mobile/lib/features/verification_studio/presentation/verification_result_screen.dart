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
  const VerificationResultScreen({
    super.key,
    required this.result,
    this.canRetry = false,
  });

  final VerificationResult result;

  /// Set when the report was produced by the studio: lets the learner return
  /// to the form (with its input intact) or re-run the same check.
  final bool canRetry;

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

  /// Green is reserved for a report that actually checked at least one claim
  /// against at least one source. A report with no evidence is neutral.
  String get _statusLabel => result.isSound
      ? 'Appears sound'
      : result.overallStatus == 'insufficient_evidence' ||
              result.overallStatus == 'appears_sound'
          ? 'Not enough evidence'
          : 'Human review required';

  Color get _statusColor => result.isSound
      ? AppColors.accentGreen
      : result.overallStatus == 'insufficient_evidence' ||
              result.overallStatus == 'appears_sound'
          ? AppColors.info
          : AppColors.goldDark;

  IconData get _statusIcon => result.isSound
      ? Icons.verified_rounded
      : result.overallStatus == 'insufficient_evidence' ||
              result.overallStatus == 'appears_sound'
          ? Icons.info_outline_rounded
          : Icons.report_problem_rounded;

  String _verdictLabel(String verdict) => switch (verdict) {
        'supported' => 'Supported',
        'contradicted' => 'Contradicted',
        _ => 'Unverified',
      };

  Color _verdictColor(String verdict) => switch (verdict) {
        'supported' => AppColors.accentGreen,
        'contradicted' => AppColors.error,
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
                    Icon(_statusIcon, color: _statusColor),
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
              result.checks != null ||
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
                  if (result.checks != null) ...[
                    _checkChip(
                      label: 'Web search',
                      detail: result.checks!.webSearch ? 'on' : 'off',
                      icon: Icons.travel_explore_rounded,
                    ),
                    _checkChip(
                      label: '${result.checks!.sourcesFound} sources found',
                      detail: '',
                      icon: Icons.verified_rounded,
                    ),
                    _checkChip(
                      label: '${result.checks!.claimsChecked} claims checked',
                      detail: '',
                      icon: Icons.fact_check_rounded,
                    ),
                    _checkChip(
                      label:
                          '${result.checks!.citationsChecked} citations checked',
                      detail: '',
                      icon: Icons.format_quote_rounded,
                    ),
                  ] else ...[
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
          ..._disclosures(),
          if (result.claims.isNotEmpty) ...[
            Text('CLAIMS CHECKED (${result.claims.length})',
                style: AppTypography.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: .5)),
            const SizedBox(height: AppSpacing.sm),
            for (final claim in result.claims) _claimCard(claim),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text('ITEMS REQUIRING REVIEW (${result.items.length})',
              style: AppTypography.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: .5)),
          const SizedBox(height: AppSpacing.sm),
          if (result.items.isEmpty)
            Text(
                result.isSound
                    ? 'No issues were flagged in the content that was checked.'
                    : 'Nothing was flagged, but this is not a clean bill of health — review the scope and sources above.',
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
          if (canRetry) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Edit input'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Try again'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Scope warnings must appear before claims so a cut-off or hard-to-read
  /// document cannot look like a complete check.
  List<Widget> _disclosures() {
    final warnings = <Widget>[];
    for (final input in result.inputs) {
      if (input.truncated) {
        final pages = input.pages;
        final read = input.pagesRead ?? pages;
        warnings.add(_warning(pages != null && read != null
            ? 'We read pages 1–$read of $pages; later pages were not checked.'
            : 'Only part of this document was read; later pages were not checked.'));
      }
      if (input.quality?.toLowerCase() == 'low') {
        warnings.add(_warning(
            'The text in this document was hard to read. Paste the text or upload a clearer file for a fuller check.'));
      }
      if (input.warning?.trim().isNotEmpty == true) {
        warnings.add(_warning(input.warning!.trim()));
      }
    }
    return warnings;
  }

  Widget _warning(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.goldDark.withValues(alpha: .35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: AppColors.goldDark),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _claimCard(VerificationClaim claim) {
    final color = _verdictColor(claim.verdict);
    return Container(
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  claim.claim,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  _verdictLabel(claim.verdict),
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (claim.concern.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(claim.concern,
                style:
                    AppTypography.textTheme.bodySmall?.copyWith(height: 1.4)),
          ],
          if (claim.page != null) ...[
            const SizedBox(height: 4),
            Text('Page ${claim.page}',
                style: AppTypography.textTheme.labelSmall
                    ?.copyWith(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}
