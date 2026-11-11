import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/admin/presentation/admin_widgets.dart';
import 'package:verifai/features/admin/providers.dart';
import 'package:verifai/shared/models.dart';

class AdminSupportScreen extends ConsumerStatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  ConsumerState<AdminSupportScreen> createState() =>
      _AdminSupportScreenState();
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
          child: AdminFilterBar(
            children: [
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search reference, email, name or subject',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
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
                return const AdminLoading();
              }
              if (snapshot.hasError) {
                return AdminErrorView(
                  message: 'Could not load the support inbox.',
                  onRetry: () => setState(_load),
                );
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
                return const AdminEmptyState(
                  message: 'No tickets match.',
                  icon: Icons.support_agent_rounded,
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(adminUnreadTicketsProvider);
                  setState(_load);
                  await _future;
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.md,
                    AppSpacing.screenPadding,
                    AppSpacing.xxl,
                  ),
                  itemCount: tickets.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final t = tickets[i];
                    return _TicketRow(
                      ticket: t,
                      onTap: () => context.push('/admin/support/${t.id}'),
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

/// One ticket: the subject is the headline, everything else is metadata.
class _TicketRow extends StatelessWidget {
  const _TicketRow({required this.ticket, required this.onTap});

  final SupportTicket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = ticket.unread;
    final status = ticket.status.replaceAll('_', ' ');

    return AdminCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // An unread ticket is marked with a dot rather than a coloured
          // icon, so the eye goes to the subject first.
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 5, right: 2),
            decoration: BoxDecoration(
              color: unread ? AppColors.error : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.subject,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${ticket.publicRef} · ${ticket.category}',
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    AdminStatusPill(
                      label: status,
                      color: switch (ticket.status) {
                        'new' => AppColors.error,
                        'in_progress' => AppColors.info,
                        'resolved' => AppColors.accentGreen,
                        _ => AppColors.textSecondary,
                      },
                    ),
                    if (ticket.replyCount > 0) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${ticket.replyCount} '
                        '${ticket.replyCount == 1 ? 'reply' : 'replies'}',
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary, size: 20),
        ],
      ),
    );
  }
}
