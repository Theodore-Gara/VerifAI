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

/// Lesson catalogue. Used for both Learning material and Practice entry points.
class LabLessonsScreen extends ConsumerWidget {
  const LabLessonsScreen({super.key, this.practice = false});
  final bool practice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(labLessonsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(practice ? 'Practice' : 'Learning material',
            style: AppTypography.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
      ),
      body: lessonsAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: const [
            ShimmerLoader(height: 90),
            SizedBox(height: AppSpacing.md),
            ShimmerLoader(height: 90),
            SizedBox(height: AppSpacing.md),
            ShimmerLoader(height: 90),
          ],
        ),
        error: (e, _) => AsyncErrorView(
          error: e,
          fallbackMessage: 'Failed to load lessons.',
          onRetry: () => ref.invalidate(labLessonsProvider),
        ),
        data: (lessons) => lessons.isEmpty
            ? const EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'No lessons yet',
                message: 'Lessons for your track are coming soon.')
            : ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm,
                    AppSpacing.screenPadding, AppSpacing.xxl),
                children: [for (final l in lessons) _lessonCard(context, l)],
              ),
      ),
    );
  }

  Widget _lessonCard(BuildContext context, LabLesson lesson) {
    final count = practice
        ? '${lesson.activitiesCount} questions${lesson.activitiesCompleted > 0 ? ' · ${lesson.activitiesCompleted} done' : ''}'
        : '${lesson.sectionsCount} topics · ${lesson.estimatedMinutes} min';
    final route = practice ? '/ai-lab/practice/${lesson.code}' : '/ai-lab/lessons/${lesson.code}';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => context.push(route),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                  color: lesson.completed
                      ? AppColors.accentGreen.withValues(alpha: .4)
                      : AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lesson.title,
                          style: AppTypography.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800, color: AppColors.primaryNavy)),
                      const SizedBox(height: 4),
                      Text(count,
                          style: AppTypography.textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (lesson.completed)
                  const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 20)
                else
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
