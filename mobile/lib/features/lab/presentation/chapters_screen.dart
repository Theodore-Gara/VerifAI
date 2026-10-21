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

/// The chapter list for one textbook (lesson). Book > chapters > topics.
class LabChaptersScreen extends ConsumerWidget {
  const LabChaptersScreen({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(labLessonProvider(code));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/ai-lab'),
        ),
        title: Text('Book',
            style: AppTypography.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
      ),
      body: detailAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: const [
            ShimmerLoader(height: 120),
            SizedBox(height: AppSpacing.md),
            ShimmerLoader(height: 200)
          ],
        ),
        error: (e, _) => AsyncErrorView(
          error: e,
          fallbackMessage: 'Failed to load this book.',
          onRetry: () => ref.invalidate(labLessonProvider(code)),
        ),
        data: (detail) {
          final chapters = detail.chapters;
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
                AppSpacing.sm, AppSpacing.screenPadding, AppSpacing.xxl),
            children: [
              Text(detail.lesson.title,
                  style: AppTypography.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryNavy)),
              const SizedBox(height: AppSpacing.xs),
              Text(detail.lesson.summary,
                  style: AppTypography.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary, height: 1.45)),
              const SizedBox(height: AppSpacing.md),
              _progressChip(detail),
              const SizedBox(height: AppSpacing.lg),
              if (chapters.isEmpty)
                const EmptyState(
                    icon: Icons.menu_book_outlined,
                    title: 'No chapters',
                    message: 'This book has no reading material yet.')
              else
                for (var i = 0; i < chapters.length; i++)
                  _chapterTile(context, detail, chapters[i], i),
              if (detail.activities.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => context.push('/ai-lab/practice/$code'),
                  icon: const Icon(Icons.quiz_outlined),
                  label: Text('Practise ${detail.activities.length} questions'),
                ),
              ],
              if (detail.attributions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Text('Sources',
                    style: AppTypography.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.xs),
                for (final a in detail.attributions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(a.creditLine,
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary, height: 1.4)),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _progressChip(LabLessonDetail detail) {
    final done = detail.progress.sectionsCompleted;
    final total = detail.topicCount;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border:
                Border.all(color: AppColors.accentGreen.withValues(alpha: .4)),
          ),
          child: Text('$done / $total topics read',
              style: AppTypography.textTheme.labelMedium?.copyWith(
                  color: AppColors.accentGreen, fontWeight: FontWeight.w800)),
        ),
        if (detail.shareAlike) ...[
          const SizedBox(width: 8),
          Text('CC BY-SA', style: AppTypography.textTheme.labelSmall),
        ],
      ],
    );
  }

  Widget _chapterTile(BuildContext context, LabLessonDetail detail,
      LabSection chapter, int index) {
    final count = detail.topicsOf(chapter.id).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => context.push('/ai-lab/lessons/$code/chapter/$index'),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primaryFill,
                    child: Text('${index + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800))),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(chapter.heading,
                          style: AppTypography.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryNavy)),
                      const SizedBox(height: 2),
                      Text('$count topic${count == 1 ? '' : 's'}',
                          style: AppTypography.textTheme.labelSmall
                              ?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
