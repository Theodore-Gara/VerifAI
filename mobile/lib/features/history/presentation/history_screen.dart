import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/empty_state.dart';
import 'package:verifai/shared/widgets/shimmer_loader.dart';

/// Task History: a unified timeline of tasks, practice activities and capstones.
/// Search and the type filter are server-side (`GET /api/history?q=&type=`), and
/// the list pages in as the learner scrolls.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  static const _pageSize = 20;

  final _scroll = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  final List<HistoryEntry> _entries = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  Object? _error;
  String? _type;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 240) {
      _load();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    // A keystroke should not fire a request; wait for a short pause.
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      if (value.trim() == _query) return;
      _query = value.trim();
      _load(reset: true);
    });
  }

  Future<void> _load({bool reset = false}) async {
    if (_loadingMore) return;
    if (!reset && !_hasMore) return;

    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _hasMore = true;
        _entries.clear();
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final page = await ref.read(apiClientProvider).getHistory(
            limit: _pageSize,
            offset: reset ? 0 : _entries.length,
            type: _type,
            query: _query,
          );
      if (!mounted) return;
      setState(() {
        _entries.addAll(page);
        _hasMore = page.length == _pageSize;
        _loading = false;
        _loadingMore = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _selectType(String? type) {
    if (_type == type) return;
    _type = type;
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text('Task History',
            style: AppTypography.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primaryNavy)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
                AppSpacing.sm, AppSpacing.screenPadding, 0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search your attempts',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding, vertical: 8),
              children: [
                _chip('All', null),
                _chip('Tasks', 'task'),
                _chip('Practice', 'activity'),
                _chip('Capstones', 'capstone'),
              ],
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _chip(String label, String? type) {
    final selected = _type == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => _selectType(type),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: const [
          ShimmerLoader(height: 64),
          SizedBox(height: AppSpacing.sm),
          ShimmerLoader(height: 64),
          SizedBox(height: AppSpacing.sm),
          ShimmerLoader(height: 64),
        ],
      );
    }
    if (_error != null) {
      return AsyncErrorView(
        error: _error!,
        fallbackMessage: 'Failed to load your history.',
        onRetry: () => _load(reset: true),
      );
    }
    if (_entries.isEmpty) {
      return EmptyState(
        icon: Icons.history_rounded,
        title: _query.isEmpty ? 'Nothing here yet' : 'No matches',
        message: _query.isEmpty
            ? 'Complete a task, practice question or capstone to build your history.'
            : 'No attempts match "$_query". Try a different search or filter.',
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
          AppSpacing.sm, AppSpacing.screenPadding, AppSpacing.xxl),
      itemCount: _entries.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _entries.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return _tile(_entries[index]);
      },
    );
  }

  Widget _tile(HistoryEntry e) {
    final (icon, color) = switch (e.type) {
      'capstone' => (Icons.workspace_premium_rounded, AppColors.primaryNavy),
      'activity' => (Icons.quiz_outlined, AppColors.accentCyan),
      _ => (Icons.task_alt_rounded, AppColors.accentGreen),
    };
    final trailing = e.score != null
        ? '${e.score}%'
        : (e.passed == true ? 'Done' : (e.passed == false ? 'Attempted' : '-'));
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          // A task attempt can be reopened by id: the feedback screen re-fetches
          // it, so it no longer depends on the result object it was pushed with.
          onTap: e.type == 'task'
              ? () => context.push('/feedback/${e.id}')
              : null,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: AppColors.primaryNavy, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryNavy)),
                      const SizedBox(height: 3),
                      Text(
                          '${_label(e)} · ${_date(e.createdAt)}${e.xpEarned > 0 ? ' · +${e.xpEarned} XP' : ''}',
                          style: AppTypography.textTheme.labelSmall
                              ?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Text(trailing,
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: e.passed == false
                            ? AppColors.goldDark
                            : AppColors.primaryNavy)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _label(HistoryEntry e) => switch (e.type) {
        'capstone' => 'Capstone',
        'activity' => 'Practice',
        _ => 'Task${e.feature != null ? ' · ${e.feature}' : ''}',
      };

  String _date(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}
