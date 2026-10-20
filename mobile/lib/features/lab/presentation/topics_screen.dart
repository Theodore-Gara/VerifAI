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

/// The topics inside one chapter of a textbook.
class LabTopicsScreen extends ConsumerWidget {
  const LabTopicsScreen({super.key, required this.code, required this.chapterIndex});
  final String code;
  final int chapterIndex;

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
          onPressed: () => context.canPop() ? context.pop() : context.go('/ai-lab/lessons/$code'),
        ),
        title: Text('Topics',
            style: AppTypography.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
      ),
      body: detailAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: const [ShimmerLoader(height: 120), SizedBox(height: AppSpacing.md), ShimmerLoader(height: 200)],
        ),
        error: (e, _) => AsyncErrorView(
          error: e,
          fallbackMessage: 'Failed to load this chapter.',
          onRetry: () => ref.invalidate(labLessonProvider(code)),
        ),
        data: (detail) {
          final chapters = detail.chapters;
          if (chapterIndex < 0 || chapterIndex >= chapters.length) {
            return const EmptyState(icon: Icons.menu_book_outlined, title: 'Chapter not found', message: '');
          }
          final chapter = chapters[chapterIndex];
          final topics = detail.topicsOf(chapter.id);
          var offset = 0;
          for (var i = 0; i < chapterIndex; i++) {
            offset += detail.topicsOf(chapters[i].id).length;
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm,
                AppSpacing.screenPadding, AppSpacing.xxl),
            children: [
              Text(chapter.heading,
                  style: AppTypography.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
              const SizedBox(height: AppSpacing.xs),
              Text('${topics.length} topic${topics.length == 1 ? '' : 's'}',
                  style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              if (topics.isEmpty)
                const EmptyState(
                    icon: Icons.article_outlined,
                    title: 'No topics',
                    message: 'This chapter has no topics yet.')
              else
                for (var i = 0; i < topics.length; i++) _topicTile(context, topics[i], offset + i, i),
            ],
          );
        },
      ),
    );
  }

  Widget _topicTile(BuildContext context, LabSection section, int globalIndex, int localIndex) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => context.push('/ai-lab/lessons/$code/topic/$globalIndex'),
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
                    backgroundColor: AppColors.primaryNavy,
                    child: Text('${localIndex + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(section.heading,
                      style: AppTypography.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primaryNavy)),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
