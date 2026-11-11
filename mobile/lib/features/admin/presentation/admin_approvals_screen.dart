import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/services/api_error.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/features/admin/presentation/admin_shell_screen.dart';
import 'package:verifai/features/admin/presentation/admin_widgets.dart';
import 'package:verifai/features/admin/providers.dart';
import 'package:verifai/shared/widgets/app_feedback_banner.dart';

class AdminApprovalsScreen extends ConsumerStatefulWidget {
  const AdminApprovalsScreen({super.key});

  @override
  ConsumerState<AdminApprovalsScreen> createState() =>
      _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends ConsumerState<AdminApprovalsScreen> {
  Future<Map<String, dynamic>>? _future;
  String _status = 'pending';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ref.read(apiClientProvider).adminRequest('GET', 'approvals',
        query: {'status': _status}).then(adminMap);
  }

  Future<void> _review(int id, String action) async {
    final note = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${action == 'approve' ? 'Approve' : 'Reject'} task?'),
        content: TextField(
          controller: note,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Note (optional)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(action == 'approve' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    final text = note.text.trim();
    note.dispose();
    if (confirmed != true) return;
    try {
      await ref.read(apiClientProvider).adminRequest(
        'POST',
        'tasks/$id/approval',
        data: {'action': action, 'note': text.isEmpty ? null : text},
      );
      if (mounted) setState(_load);
    } catch (e) {
      if (!mounted) return;
      showFeedback(context, FeedbackKind.error, classifyError(e).message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminToolScaffold(
      title: 'Approvals',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'approved', child: Text('Approved')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
              ],
              onChanged: (value) => setState(() {
                _status = value ?? 'pending';
                _load();
              }),
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
                  return AdminErrorView(onRetry: () => setState(_load));
                }
                final tasks = adminList(snapshot.data?['tasks']);
                if (tasks.isEmpty) {
                  return const Center(child: Text('Nothing in this queue.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final t = tasks[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(adminString(t['title']),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                            Text(
                                '${adminString(t['feature'])} · ${adminString(t['track_name'])}'
                                ' · ${adminString(t['code'])}',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                            if (adminString(t['approval_note']).isNotEmpty)
                              Text('Note: ${adminString(t['approval_note'])}'),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: () =>
                                      _review(adminInt(t['id']), 'reject'),
                                  child: const Text('Reject'),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                FilledButton(
                                  onPressed: () =>
                                      _review(adminInt(t['id']), 'approve'),
                                  child: const Text('Approve'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
