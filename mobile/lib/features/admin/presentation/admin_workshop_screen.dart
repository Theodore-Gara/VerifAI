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

class AdminWorkshopScreen extends ConsumerStatefulWidget {
  const AdminWorkshopScreen({super.key});

  @override
  ConsumerState<AdminWorkshopScreen> createState() =>
      _AdminWorkshopScreenState();
}

class _AdminWorkshopScreenState extends ConsumerState<AdminWorkshopScreen> {
  Future<Map<String, dynamic>>? _posts;
  Future<Map<String, dynamic>>? _reports;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _posts = ref
        .read(apiClientProvider)
        .adminRequest('GET', 'workshop')
        .then(adminMap);
    _reports = ref
        .read(apiClientProvider)
        .adminRequest('GET', 'workshop/reports')
        .then(adminMap);
  }

  Future<void> _moderate(int id, String action) async {
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${action[0].toUpperCase()}${action.substring(1)} post?'),
        content: AdminDialogBody(
          children: [
            const AdminDialogHint(
              'The reason is recorded in the audit log and shown to the author.',
            ),
            TextField(
              controller: reason,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Reason (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(action)),
        ],
      ),
    );
    final text = reason.text.trim();
    reason.dispose();
    if (confirmed != true) return;
    try {
      await ref.read(apiClientProvider).adminRequest(
        'POST',
        'workshop/$id',
        data: {'action': action, 'reason': text.isEmpty ? null : text},
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
      title: 'Workshop',
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(tabs: [Tab(text: 'Posts'), Tab(text: 'Reports')]),
            Expanded(
              child: TabBarView(
                children: [
                  _list(_posts, 'posts', (p) {
                    final hidden = p['hidden'] == true;
                    return _PostCard(
                      body: adminString(p['body']),
                      author: adminString(p['author_name']),
                      createdAt: adminString(p['created_at']),
                      hidden: hidden,
                      onAction: (action) =>
                          _moderate(adminInt(p['id']), action),
                    );
                  }),
                  _list(
                      _reports,
                      'reports',
                      (r) => AdminCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AdminDataRow(
                                  label:
                                      'Reported by ${adminString(r['reporter_email'])}'
                                      ' · post by ${adminString(r['author_email'])}',
                                  value: 'Report: ${adminString(r['reason'])}',
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md),
                                  ),
                                  child: Text(
                                    adminString(r['post_body']),
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.textTheme.bodySmall
                                        ?.copyWith(
                                      color: AppColors.textPrimary,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _moderate(
                                        adminInt(r['post_id']), 'hide'),
                                    icon: const Icon(
                                        Icons.visibility_off_rounded, size: 18),
                                    label: const Text('Hide post'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(Future<Map<String, dynamic>>? future, String key,
      Widget Function(Map<String, dynamic>) item) {
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminLoading();
        }
        if (snapshot.hasError) {
          return AdminErrorView(onRetry: () => setState(_load));
        }
        final items = adminList(snapshot.data?[key]);
        if (items.isEmpty) {
          return AdminEmptyState(
            message: key == 'posts'
                ? 'No workshop posts yet.'
                : 'No open reports.',
            icon: Icons.forum_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            AppSpacing.xxl,
          ),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, i) => item(items[i]),
        );
      },
    );
  }
}

/// A workshop post with its moderation actions in a footer row.
class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.body,
    required this.author,
    required this.createdAt,
    required this.hidden,
    required this.onAction,
  });

  final String body;
  final String author;
  final String createdAt;
  final bool hidden;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hidden) ...[
            AdminStatusPill(
                label: 'Hidden', color: AppColors.warning),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            body,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '$author · $createdAt',
            style: AppTypography.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onAction(hidden ? 'unhide' : 'hide'),
                  icon: Icon(
                    hidden
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    size: 18,
                  ),
                  label: Text(hidden ? 'Unhide' : 'Hide'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onAction('delete'),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
