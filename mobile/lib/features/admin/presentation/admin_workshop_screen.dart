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
        content: TextField(
          controller: reason,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Reason (optional)'),
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
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(adminString(p['body']),
                                maxLines: 3, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                                '${adminString(p['author_name'])} · ${adminString(p['created_at'])}',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: () => _moderate(adminInt(p['id']),
                                      hidden ? 'unhide' : 'hide'),
                                  child: Text(hidden ? 'Unhide' : 'Hide'),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                OutlinedButton(
                                  onPressed: () =>
                                      _moderate(adminInt(p['id']), 'delete'),
                                  child: Text('Delete',
                                      style: TextStyle(color: AppColors.error)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  _list(
                      _reports,
                      'reports',
                      (r) => Card(
                            child: ListTile(
                              title:
                                  Text('Report: ${adminString(r['reason'])}'),
                              subtitle: Text(
                                  'Post by ${adminString(r['author_email'])} · reported by ${adminString(r['reporter_email'])}'
                                  '\n${adminString(r['post_body'])}'),
                              isThreeLine: true,
                              trailing: IconButton(
                                icon: const Icon(Icons.visibility_off_rounded),
                                onPressed: () =>
                                    _moderate(adminInt(r['post_id']), 'hide'),
                              ),
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
        if (items.isEmpty) return const Center(child: Text('Nothing here.'));
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) => item(items[i]),
        );
      },
    );
  }
}
