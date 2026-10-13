import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/lab/providers.dart';
import 'package:verifai/shared/widgets/empty_state.dart';
import 'package:verifai/shared/widgets/shimmer_loader.dart';

/// Reads one topic (lesson section), paginating long content. Arrows sit at the
/// bottom; reaching the last page advances to the next topic.
class LabTopicReaderScreen extends ConsumerStatefulWidget {
  const LabTopicReaderScreen({super.key, required this.code, required this.index});
  final String code;
  final int index;

  @override
  ConsumerState<LabTopicReaderScreen> createState() => _LabTopicReaderScreenState();
}

class _LabTopicReaderScreenState extends ConsumerState<LabTopicReaderScreen> {
  final _pageController = PageController();
  int _page = 0;
  bool _recorded = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> _paginate(String body) {
    final paras = body
        .split(RegExp(r'\n\s*\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (paras.isEmpty) return [body];
    final pages = <String>[];
    final buffer = StringBuffer();
    for (final p in paras) {
      if (buffer.length + p.length > 800 && buffer.isNotEmpty) {
        pages.add(buffer.toString().trim());
        buffer.clear();
      }
      if (buffer.isNotEmpty) buffer.write('\n\n');
      buffer.write(p);
    }
    if (buffer.isNotEmpty) pages.add(buffer.toString().trim());
    return pages.isEmpty ? [body] : pages;
  }

  Future<void> _recordRead(int sectionsRead, int activitiesDone) async {
    if (_recorded) return;
    _recorded = true;
    try {
      await ref.read(apiClientProvider).recordLessonProgress(widget.code,
          sectionsCompleted: sectionsRead, activitiesCompleted: activitiesDone);
      ref.invalidate(labLessonProvider(widget.code));
      ref.invalidate(labLessonsProvider);
    } catch (_) {
      _recorded = false; // best effort
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(labLessonProvider(widget.code));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text('Topic ${widget.index + 1}',
            style: AppTypography.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primaryNavy)),
        actions: [
          TextButton(onPressed: () => context.go('/ai-lab/lessons/${widget.code}'), child: const Text('Topics')),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.screenPadding), child: ShimmerLoader(height: 300)),
        error: (e, _) => AsyncErrorView(
          error: e,
          fallbackMessage: 'Failed to load this topic.',
          onRetry: () => ref.invalidate(labLessonProvider(widget.code)),
        ),
        data: (detail) {
          if (widget.index < 0 || widget.index >= detail.sections.length) {
            return const EmptyState(icon: Icons.article_outlined, title: 'Topic not found', message: '');
          }
          final section = detail.sections[widget.index];
          final pages = _paginate(section.body);
          final isLastTopic = widget.index == detail.sections.length - 1;
          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pages.length,
                    onPageChanged: (i) {
                      setState(() => _page = i);
                      if (i == pages.length - 1) {
                        _recordRead(
                          detail.progress.sectionsCompleted > widget.index + 1
                              ? detail.progress.sectionsCompleted
                              : widget.index + 1,
                          detail.progress.activitiesCompleted,
                        );
                      }
                    },
                    itemBuilder: (context, i) => SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.md,
                          AppSpacing.screenPadding, AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(section.heading,
                              style: AppTypography.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
                          const SizedBox(height: AppSpacing.md),
                          Text(pages[i],
                              style: AppTypography.textTheme.bodyLarge?.copyWith(height: 1.6)),
                        ],
                      ),
                    ),
                  ),
                ),
                _navBar(context, pages.length, isLastTopic),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _navBar(BuildContext context, int pageCount, bool isLastTopic) {
    final onLastPage = _page == pageCount - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm, AppSpacing.screenPadding, AppSpacing.md),
      decoration: const BoxDecoration(
          color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: _page > 0
                ? () => _pageController.previousPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOut)
                : null,
            icon: const Icon(Icons.arrow_back_rounded, size: 17),
            label: const Text('Back'),
          ),
          const Spacer(),
          Text('${_page + 1} / $pageCount', style: AppTypography.textTheme.labelMedium),
          const Spacer(),
          FilledButton.icon(
            onPressed: !onLastPage
                ? () => _pageController.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOut)
                : () => context.go(isLastTopic ? '/ai-lab/lessons' : '/ai-lab/lessons/${widget.code}/topic/${widget.index + 1}'),
            icon: Icon(isLastTopic && onLastPage ? Icons.done_all_rounded : Icons.arrow_forward_rounded, size: 17),
            label: Text(!onLastPage ? 'Next' : (isLastTopic ? 'Finish' : 'Next topic')),
          ),
        ],
      ),
    );
  }
}
