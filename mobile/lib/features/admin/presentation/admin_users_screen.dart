import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/theme/app_spacing.dart';
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
          child: Column(
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
              const SizedBox(height: AppSpacing.sm),
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
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: FilledButton(
                    onPressed: () => setState(_load),
                    child: const Text('Retry'),
                  ),
                );
              }
              final data = snapshot.data ?? const {};
              final users = adminList(data['users']);
              final total = adminInt(data['total']);
              if (users.isEmpty) {
                return const Center(child: Text('No learners match.'));
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
                        padding: const EdgeInsets.all(AppSpacing.screenPadding),
                        itemCount: users.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) {
                          final u = users[i];
                          final status = adminString(u['status']);
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(adminString(u['display_name'],
                                        adminString(u['email']))
                                    .characters
                                    .first
                                    .toUpperCase()),
                              ),
                              title: Text(adminString(
                                  u['display_name'], adminString(u['email']))),
                              subtitle: Text(
                                '${adminString(u['email'])} · ${adminString(u['track_name'], 'No industry')}'
                                '\n$status · XP ${adminInt(u['xp'])} · Level ${adminInt(u['level'])}'
                                ' · ${adminInt(u['attempts'])} attempts',
                              ),
                              isThreeLine: true,
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => context
                                  .push('/admin/users/${adminInt(u['id'])}'),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _page == 0
                            ? null
                            : () => setState(() {
                                  _page--;
                                  _load();
                                }),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Text(
                          '${_page + 1} of ${(total / _pageSize).ceil().clamp(1, 9999)}'),
                      IconButton(
                        onPressed: (_page + 1) * _pageSize >= total
                            ? null
                            : () => setState(() {
                                  _page++;
                                  _load();
                                }),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
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
