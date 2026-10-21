import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/industry_practice/providers.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/app_feedback_banner.dart';
import 'package:verifai/shared/widgets/empty_state.dart';
import 'package:verifai/shared/widgets/shimmer_loader.dart';

/// Industry Practice: real workplace case studies (scenario, cause, solution).
class IndustryPracticeScreen extends ConsumerWidget {
  const IndustryPracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(industryCasesProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text('Industry Practice',
            style: AppTypography.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
      ),
      body: async.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: const [
            ShimmerLoader(height: 80),
            SizedBox(height: AppSpacing.sm),
            ShimmerLoader(height: 80),
            SizedBox(height: AppSpacing.sm),
            ShimmerLoader(height: 80)
          ],
        ),
        error: (e, _) => AsyncErrorView(
          error: e,
          fallbackMessage: 'Failed to load case studies.',
          onRetry: () => ref.invalidate(industryCasesProvider),
        ),
        data: (cases) => cases.isEmpty
            ? const EmptyState(
                icon: Icons.work_outline_rounded,
                title: 'No case studies yet',
                message: 'Real-world cases for your field are coming soon.')
            : ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
                    AppSpacing.sm, AppSpacing.screenPadding, AppSpacing.xxl),
                children: [
                  Text(
                      'Learn from real workplace mistakes, then read what fixed them.',
                      style: AppTypography.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.lg),
                  for (final c in cases) _card(context, c),
                ],
              ),
      ),
    );
  }

  Widget _card(BuildContext context, IndustryCase c) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    IndustryCaseDetailScreen(id: c.id, title: c.title))),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                    color: c.read
                        ? AppColors.accentGreen.withValues(alpha: .4)
                        : AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(c.title,
                        style: AppTypography.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryNavy,
                            height: 1.3)),
                  ),
                  if (c.read)
                    Icon(Icons.check_circle_rounded,
                        size: 18, color: AppColors.accentGreen)
                  else
                    Icon(Icons.chevron_right_rounded,
                        color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
      );
}

class IndustryCaseDetailScreen extends ConsumerStatefulWidget {
  const IndustryCaseDetailScreen(
      {super.key, required this.id, required this.title});
  final int id;
  final String title;

  @override
  ConsumerState<IndustryCaseDetailScreen> createState() =>
      _IndustryCaseDetailScreenState();
}

class _IndustryCaseDetailScreenState
    extends ConsumerState<IndustryCaseDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Reading the case marks it as read; refresh the list when we leave.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(apiClientProvider).markIndustryCaseRead(widget.id);
        ref.invalidate(industryCasesProvider);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(industryCaseProvider(widget.id));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text('Case study',
            style: AppTypography.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
      ),
      body: async.when(
        loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.screenPadding),
            child: ShimmerLoader(height: 300)),
        error: (e, _) => AsyncErrorView(
          error: e,
          fallbackMessage: 'Failed to load this case.',
          onRetry: () => ref.invalidate(industryCaseProvider(widget.id)),
        ),
        data: (c) => ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
              AppSpacing.sm, AppSpacing.screenPadding, AppSpacing.xxl),
          children: [
            Text(c.title,
                style: AppTypography.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
            const SizedBox(height: AppSpacing.lg),
            _block('WHAT HAPPENED', c.scenario, AppColors.primaryNavy),
            const SizedBox(height: AppSpacing.md),
            _block('WHAT CAUSED IT', c.cause, AppColors.goldDark),
            const SizedBox(height: AppSpacing.md),
            _block('HOW IT WAS RESOLVED', c.solution, AppColors.accentGreen),
            if (c.sourceTitle != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('Source: ${c.sourceTitle}',
                  style: AppTypography.textTheme.labelSmall
                      ?.copyWith(color: AppColors.textSecondary)),
              if (c.sourceUrl != null && c.sourceUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: InkWell(
                    onTap: () => _openUrl(context, c.sourceUrl!),
                    child: Text(c.sourceUrl!,
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                            color: AppColors.info,
                            decoration: TextDecoration.underline)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _block(String label, String body, Color accent) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTypography.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accent,
                    letterSpacing: .5)),
            const SizedBox(height: 6),
            Text(body,
                style:
                    AppTypography.textTheme.bodyMedium?.copyWith(height: 1.5)),
          ],
        ),
      );
}

Future<void> _openUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    if (context.mounted) {
      showFeedback(context, FeedbackKind.error, 'Could not open the link.');
    }
  }
}
