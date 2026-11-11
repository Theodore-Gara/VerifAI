import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/services/api_error.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
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
        content: AdminDialogBody(
          children: [
            const AdminDialogHint(
              'Your note is shown to the content team and recorded in the '
              'audit log.',
            ),
            TextField(
              controller: note,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
          ],
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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.md,
              AppSpacing.screenPadding,
              0,
            ),
            child: AdminFilterBar(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                        value: 'approved', child: Text('Approved')),
                    DropdownMenuItem(
                        value: 'rejected', child: Text('Rejected')),
                  ],
                  onChanged: (value) => setState(() {
                    _status = value ?? 'pending';
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
                  return AdminErrorView(onRetry: () => setState(_load));
                }
                final tasks = adminList(snapshot.data?['tasks']);
                if (tasks.isEmpty) {
                  return const AdminEmptyState(
                    message: 'Nothing in this queue.',
                    icon: Icons.fact_check_rounded,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.md,
                    AppSpacing.screenPadding,
                    AppSpacing.xxl,
                  ),
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) {
                    final t = tasks[i];
                    return _ApprovalCard(
                      task: t,
                      onReview: (action) =>
                          _review(adminInt(t['id']), action),
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

/// One task awaiting review.
class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({required this.task, required this.onReview});

  final Map<String, dynamic> task;
  final ValueChanged<String> onReview;

  @override
  Widget build(BuildContext context) {
    final note = adminString(task['approval_note']);

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            adminString(task['title']),
            style: AppTypography.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _MetaPill(label: adminString(task['feature'])),
              _MetaPill(label: adminString(task['track_name'])),
              _MetaPill(label: adminString(task['code'])),
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                note,
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.45,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          // The actions sit in their own footer row so they never crowd the
          // content above them.
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onReview('reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.4)),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: () => onReview('approve'),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A small metadata chip.
class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: AppTypography.textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 11.5,
        ),
      ),
    );
  }
}
