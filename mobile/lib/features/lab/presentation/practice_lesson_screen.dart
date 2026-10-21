import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/lab/presentation/activity_screen.dart';
import 'package:verifai/features/lab/providers.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/empty_state.dart';
import 'package:verifai/shared/widgets/shimmer_loader.dart';

/// The practice activities for one lesson.
class LabPracticeScreen extends ConsumerWidget {
  const LabPracticeScreen({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(labLessonProvider(code));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text('Practice',
            style: AppTypography.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
      ),
      body: detailAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: const [
            ShimmerLoader(height: 70),
            SizedBox(height: AppSpacing.sm),
            ShimmerLoader(height: 70),
            SizedBox(height: AppSpacing.sm),
            ShimmerLoader(height: 70)
          ],
        ),
        error: (e, _) => AsyncErrorView(
          error: e,
          fallbackMessage: 'Failed to load practice questions.',
          onRetry: () => ref.invalidate(labLessonProvider(code)),
        ),
        data: (detail) {
          final activities = detail.activities;
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
                AppSpacing.sm, AppSpacing.screenPadding, AppSpacing.xxl),
            children: [
              Text(detail.lesson.title,
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryNavy)),
              const SizedBox(height: 4),
              Text(
                  '${activities.where((a) => a.passed).length} / ${activities.length} passed',
                  style: AppTypography.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              if (activities.isEmpty)
                const EmptyState(
                    icon: Icons.quiz_outlined,
                    title: 'No questions',
                    message: 'Practice questions are coming soon.')
              else
                for (var i = 0; i < activities.length; i++)
                  _tile(context, ref, activities[i], i),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(
      BuildContext context, WidgetRef ref, LabActivity activity, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () async {
            await context.push('/ai-lab/practice/activity',
                extra: ActivityArgs(activity: activity, code: code));
            ref.invalidate(labLessonProvider(code));
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                  color: activity.passed
                      ? AppColors.accentGreen.withValues(alpha: .4)
                      : AppColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                    radius: 13,
                    backgroundColor: activity.passed
                        ? AppColors.accentGreen
                        : (activity.attempted
                            ? AppColors.textSecondary
                            : AppColors.primaryNavy),
                    child: Icon(
                        activity.passed
                            ? Icons.check_rounded
                            : (activity.attempted
                                ? Icons.replay_rounded
                                : Icons.help_outline_rounded),
                        size: 15,
                        color: Colors.white)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(activity.prompt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600, height: 1.35)),
                ),
                Text(
                    activity.attempted
                        ? 'Practice'
                        : '+${activity.xpReward} XP',
                    style: AppTypography.textTheme.labelSmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
