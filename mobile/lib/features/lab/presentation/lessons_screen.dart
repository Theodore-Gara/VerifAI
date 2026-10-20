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
///
/// The catalogue is filtered locally by title, summary and competency, so a
/// learner can find a topic without scrolling the whole book list (the audit's
/// "no search anywhere" finding).
class LabLessonsScreen extends ConsumerStatefulWidget {
  const LabLessonsScreen({super.key, this.practice = false});
  final bool practice;

  @override
  ConsumerState<LabLessonsScreen> createState() => _LabLessonsScreenState();
}

class _LabLessonsScreenState extends ConsumerState<LabLessonsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  bool get practice => widget.practice;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LabLesson> _filter(List<LabLesson> lessons) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return lessons;
    return lessons.where((l) {
      return l.title.toLowerCase().contains(q) ||
          l.summary.toLowerCase().contains(q) ||
          (l.competency ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
        data: (lessons) {
          if (lessons.isEmpty) {
            return const EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'No lessons yet',
                message: 'Lessons for your track are coming soon.');
          }
          final filtered = _filter(lessons);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
                    AppSpacing.sm, AppSpacing.screenPadding, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search lessons',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No matches',
                        message: 'No lesson matches "$_query".')
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenPadding,
                            AppSpacing.md,
                            AppSpacing.screenPadding,
                            AppSpacing.xxl),
                        children: [
                          for (final l in filtered) _lessonCard(context, l)
                        ],
                      ),
              ),
            ],
          );
        },
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
                  Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 20)
                else
                  Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
