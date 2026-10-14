import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/lab/providers.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/empty_state.dart';
import 'package:verifai/shared/widgets/shimmer_loader.dart';

typedef _Block = ({bool heading, String text});

/// Reads one topic, showing all of its subtopics at once (paginated). Arrows
/// sit at the bottom; on the last page the flow advances to the next topic.
class LabTopicReaderScreen extends ConsumerStatefulWidget {
  const LabTopicReaderScreen(
      {super.key, required this.code, required this.index});
  final String code;
  final int index;

  @override
  ConsumerState<LabTopicReaderScreen> createState() =>
      _LabTopicReaderScreenState();
}

class _LabTopicReaderScreenState extends ConsumerState<LabTopicReaderScreen> {
  final _pageController = PageController();
  int _page = 0;
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_syncPageIndex);
  }

  void _syncPageIndex() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page;
    if (page == null) return;
    final rounded = page.round();
    if (rounded != _page && mounted) {
      setState(() => _page = rounded);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_syncPageIndex);
    _pageController.dispose();
    super.dispose();
  }

  List<String> _paragraphs(String body) => body
      .split(RegExp('\n\\s*\n'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  /// Flattens a topic into heading/paragraph blocks, then chunks them into pages.
  List<List<_Block>> _paginate(LabSection topic, List<LabSection> subtopics) {
    final items = <_Block>[];
    for (final p in _paragraphs(topic.body)) {
      items.add((heading: false, text: p));
    }
    for (final s in subtopics) {
      items.add((heading: true, text: s.heading));
      for (final p in _paragraphs(s.body)) {
        items.add((heading: false, text: p));
      }
    }
    if (items.isEmpty) return [[]];
    final pages = <List<_Block>>[];
    var current = <_Block>[];
    var length = 0;
    for (final item in items) {
      if (length + item.text.length > 800 && current.isNotEmpty) {
        pages.add(current);
        current = <_Block>[];
        length = 0;
      }
      current.add(item);
      length += item.text.length;
    }
    if (current.isNotEmpty) pages.add(current);
    return pages.isEmpty ? [items] : pages;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/ai-lab/lessons/${widget.code}'),
        ),
        title: Text('Topic ${widget.index + 1}',
            style: AppTypography.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800, color: AppColors.primaryNavy)),
        actions: [
          TextButton(
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go('/ai-lab/lessons/${widget.code}'),
              child: const Text('Contents')),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.screenPadding),
            child: ShimmerLoader(height: 300)),
        error: (e, _) => AsyncErrorView(
          error: e,
          fallbackMessage: 'Failed to load this topic.',
          onRetry: () => ref.invalidate(labLessonProvider(widget.code)),
        ),
        data: (detail) {
          final topics = detail.orderedTopics;
          if (widget.index < 0 || widget.index >= topics.length) {
            return const EmptyState(
                icon: Icons.article_outlined,
                title: 'Topic not found',
                message: '');
          }
          final topic = topics[widget.index];
          final pages = _paginate(topic, detail.subtopicsOf(topic.id));
          final isLastTopic = widget.index == topics.length - 1;
          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pages.length,
                    onPageChanged: (i) {
                      if (i != _page) setState(() => _page = i);
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
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenPadding,
                          AppSpacing.md,
                          AppSpacing.screenPadding,
                          AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (i == 0) ...[
                            Text(topic.heading,
                                style: AppTypography.textTheme.headlineSmall
                                    ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primaryNavy)),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          for (final block in pages[i])
                            block.heading
                                ? Padding(
                                    padding: EdgeInsets.only(
                                        top: block == pages[i].first
                                            ? 0
                                            : AppSpacing.md,
                                        bottom: AppSpacing.xs),
                                    child: Text(block.text,
                                        style: AppTypography
                                            .textTheme.titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.primaryNavy)),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: AppSpacing.sm),
                                    child: Text(block.text,
                                        style: AppTypography.textTheme.bodyLarge
                                            ?.copyWith(height: 1.6)),
                                  ),
                          const SizedBox(height: AppSpacing.lg),
                          _pageActions(context, pages.length, isLastTopic,
                              detail.progress),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _markReadAndAdvance(
      LabProgress progress, bool isLastTopic) async {
    final sectionsRead = progress.sectionsCompleted > widget.index + 1
        ? progress.sectionsCompleted
        : widget.index + 1;
    await _recordRead(sectionsRead, progress.activitiesCompleted);
    if (!mounted) return;
    if (isLastTopic) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/ai-lab/lessons/${widget.code}');
      }
    } else {
      context.pushReplacement(
          '/ai-lab/lessons/${widget.code}/topic/${widget.index + 1}');
    }
  }

  Widget _pageActions(BuildContext context, int pageCount, bool isLastTopic,
      LabProgress progress) {
    final onLastPage = _page == pageCount - 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: _page > 0
                ? () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOut)
                : null,
            icon: const Icon(Icons.arrow_back_rounded, size: 17),
            label: const Text('Back'),
          ),
          const Spacer(),
          Text('${_page + 1} / $pageCount',
              style: AppTypography.textTheme.labelMedium),
          const Spacer(),
          FilledButton.icon(
            onPressed: () {
              if (!onLastPage) {
                _pageController.nextPage(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOut);
              } else {
                _markReadAndAdvance(progress, isLastTopic);
              }
            },
            icon: Icon(
                onLastPage
                    ? Icons.check_circle_outline_rounded
                    : Icons.arrow_forward_rounded,
                size: 17),
            label: Text(onLastPage
                ? (isLastTopic
                    ? 'Mark as read & finish'
                    : 'Mark as read & next topic')
                : 'Next'),
          ),
        ],
      ),
    );
  }
}
