import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/features/admin/providers.dart';
import 'package:verifai/shared/models.dart';

class AdminSupportScreen extends ConsumerStatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  ConsumerState<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends ConsumerState<AdminSupportScreen> {
  final _search = TextEditingController();
  String _status = 'all';
  String _category = 'all';
  Future<List<SupportTicket>>? _future;

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
    final query = <String, dynamic>{'limit': 200};
    if (_status != 'all') query['status'] = _status;
    if (_category != 'all') query['category'] = _category;
    _future = ref
        .read(apiClientProvider)
        .adminRequest('GET', 'support/messages', query: query)
        .then((data) => adminList(data is Map ? data['messages'] : null)
            .map(SupportTicket.fromJson)
            .toList());
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
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search reference, email, name or subject',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(value: 'new', child: Text('New')),
                        DropdownMenuItem(
                            value: 'in_progress', child: Text('In progress')),
                        DropdownMenuItem(
                            value: 'resolved', child: Text('Resolved')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _status = value ?? 'all';
                          _load();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(value: 'bug', child: Text('Bug')),
                        DropdownMenuItem(
                            value: 'account', child: Text('Account')),
                        DropdownMenuItem(
                            value: 'content', child: Text('Content')),
                        DropdownMenuItem(
                            value: 'verification', child: Text('Verification')),
                        DropdownMenuItem(
                            value: 'feedback', child: Text('Feedback')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _category = value ?? 'all';
                          _load();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<SupportTicket>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _Error(onRetry: () => setState(_load));
              }
              final all = snapshot.data ?? const <SupportTicket>[];
              final q = _search.text.trim().toLowerCase();
              final tickets = q.isEmpty
                  ? all
                  : all
                      .where((t) =>
                          t.publicRef.toLowerCase().contains(q) ||
                          t.subject.toLowerCase().contains(q) ||
                          t.category.toLowerCase().contains(q) ||
                          (t.name ?? '').toLowerCase().contains(q) ||
                          (t.email ?? '').toLowerCase().contains(q))
                      .toList();
              if (tickets.isEmpty) {
                return const Center(child: Text('No tickets match.'));
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(adminUnreadTicketsProvider);
                  setState(_load);
                  await _future;
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  itemCount: tickets.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final t = tickets[i];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          t.unread
                              ? Icons.mark_email_unread_rounded
                              : Icons.support_agent_rounded,
                          color: t.unread
                              ? AppColors.error
                              : AppColors.accentGreen,
                        ),
                        title: Text('${t.publicRef} · ${t.subject}',
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          '${t.category} · ${t.status.replaceAll('_', ' ')}'
                          '${t.replyCount > 0 ? ' · ${t.replyCount} replies' : ''}',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/admin/support/${t.id}'),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Could not load the support inbox.'),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
