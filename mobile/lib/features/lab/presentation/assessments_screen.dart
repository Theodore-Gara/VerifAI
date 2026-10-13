import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/lab/providers.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/empty_state.dart';
import 'package:verifai/shared/widgets/shimmer_loader.dart';

/// Capstone assessments for the learner's track.
class LabAssessmentsScreen extends ConsumerWidget {
  const LabAssessmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(labAssessmentsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text('Assessments',
            style: AppTypography.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
      ),
      body: async.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: const [ShimmerLoader(height: 120), SizedBox(height: AppSpacing.md), ShimmerLoader(height: 120)],
        ),
        error: (e, _) => AsyncErrorView(
          error: e,
          fallbackMessage: 'Failed to load assessments.',
          onRetry: () => ref.invalidate(labAssessmentsProvider),
        ),
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: Icons.workspace_premium_outlined,
                title: 'No assessments yet',
                message: 'Capstone assessments for your track are coming soon.')
            : ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm,
                    AppSpacing.screenPadding, AppSpacing.xxl),
                children: [for (final a in list) _card(context, a)],
              ),
      ),
    );
  }

  Widget _card(BuildContext context, LabAssessment a) {
    final status = a.passed
        ? 'Passed${a.bestScore != null ? ' · best ${a.bestScore}%' : ''}'
        : a.viewOnly
            ? 'View only'
            : '${a.attemptsRemaining} of ${a.maxAttempts} attempts left';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => context.push('/ai-lab/assessments/${a.code}'),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: a.passed ? AppColors.accentGreen.withValues(alpha: .4) : AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title,
                    style: AppTypography.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primaryNavy)),
                const SizedBox(height: 4),
                Text('${a.totalMarks} marks · ${a.questionCount} questions · ${(a.timeLimitSeconds / 60).round()} min',
                    style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text(status,
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: a.passed ? AppColors.accentGreen : AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
