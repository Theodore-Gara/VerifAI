import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/admin/presentation/admin_widgets.dart';
import 'package:verifai/features/admin/providers.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _search = TextEditingController();
  String _status = 'all';
  int _page = 0;
  Future<Map<String, dynamic>>? _future;

  static const _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _load() {
    final query = <String, dynamic>{
      'limit': _pageSize,
      'offset': _page * _pageSize,
    };
    if (_search.text.trim().isNotEmpty) query['q'] = _search.text.trim();
    if (_status != 'all') query['status'] = _status;
    _future = ref
        .read(apiClientProvider)
        .adminRequest('GET', 'users', query: query)
        .then(adminMap);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
              AppSpacing.md, AppSpacing.screenPadding, 0),
          child: AdminFilterBar(
            children: [
              TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => setState(() {
                  _page = 0;
                  _load();
                }),
                decoration: InputDecoration(
                  hintText: 'Search learners by name or email',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded),
                    onPressed: () => setState(() {
                      _page = 0;
                      _load();
                    }),
                  ),
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(
                      value: 'suspended', child: Text('Suspended')),
                  DropdownMenuItem(value: 'banned', child: Text('Banned')),
                ],
                onChanged: (value) => setState(() {
                  _status = value ?? 'all';
                  _page = 0;
                  _load();
                }),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AdminLoading();
              }
              if (snapshot.hasError) {
                return AdminErrorView(
                  message: 'Could not load the learner list.',
                  onRetry: () => setState(_load),
                );
              }
              final data = snapshot.data ?? const {};
              final users = adminList(data['users']);
              final total = adminInt(data['total']);
              if (users.isEmpty) {
                return const AdminEmptyState(
                  message: 'No learners match these filters.',
                  icon: Icons.people_alt_rounded,
                );
              }
              return Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        setState(_load);
                        await _future;
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenPadding,
                          AppSpacing.md,
                          AppSpacing.screenPadding,
                          AppSpacing.md,
                        ),
                        itemCount: users.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) {
                          final u = users[i];
                          return _LearnerRow(
                            name: adminString(
                                u['display_name'], adminString(u['email'])),
                            email: adminString(u['email']),
                            track: adminString(u['track_name'], 'No industry'),
                            status: adminString(u['status']),
                            onTap: () => context
                                .push('/admin/users/${adminInt(u['id'])}'),
                          );
                        },
                      ),
                    ),
                  ),
                  _Pager(
                    page: _page,
                    pageSize: _pageSize,
                    total: total,
                    onChanged: (next) => setState(() {
                      _page = next;
                      _load();
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// One learner.
///
/// Deliberately spare: the name is the subject and everything else is
/// metadata. Progress, level and attempt counts live on the detail screen,
/// where there is room for them.
class _LearnerRow extends StatelessWidget {
  const _LearnerRow({
    required this.name,
    required this.email,
    required this.track,
    required this.status,
    required this.onTap,
  });

  final String name;
  final String email;
  final String track;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.work_outline_rounded,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        track,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary, size: 20),
        ],
      ),
    );
  }
}

/// Page controls, separated from the list so they never float over a row.
class _Pager extends StatelessWidget {
  const _Pager({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.onChanged,
  });

  final int page;
  final int pageSize;
  final int total;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final pages = (total / pageSize).ceil().clamp(1, 9999);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Previous page',
                onPressed:
                    page == 0 ? null : () => onChanged(page - 1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Page ${page + 1} of $pages',
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                tooltip: 'Next page',
                onPressed: (page + 1) * pageSize >= total
                    ? null
                    : () => onChanged(page + 1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
