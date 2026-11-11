import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/services/api_error.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/features/admin/presentation/admin_shell_screen.dart';
import 'package:verifai/features/admin/providers.dart';
import 'package:verifai/features/profile/providers.dart';
import 'package:verifai/shared/widgets/app_feedback_banner.dart';

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  const AdminUserDetailScreen({super.key, required this.id});
  final int id;

  @override
  ConsumerState<AdminUserDetailScreen> createState() =>
      _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ref
        .read(apiClientProvider)
        .adminRequest('GET', 'users/${widget.id}')
        .then(adminMap);
  }

  Future<void> _act(Future<void> Function() action) async {
    try {
      await action();
      if (!mounted) return;
      setState(_load);
    } catch (e) {
      if (!mounted) return;
      showFeedback(context, FeedbackKind.error, classifyError(e).message);
    }
  }

  Future<void> _edit(Map<String, dynamic> user) async {
    final tracks = await ref.read(apiClientProvider).getTracks();
    if (!mounted) return;
    final name = TextEditingController(text: adminString(user['display_name']));
    int trackId = adminInt(user['industry_track_id']);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit learner'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Display name'),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<int>(
                initialValue: trackId,
                decoration: const InputDecoration(labelText: 'Industry'),
                items: [
                  const DropdownMenuItem(value: 0, child: Text('No industry')),
                  for (final track in tracks)
                    DropdownMenuItem(value: track.id, child: Text(track.name)),
                ],
                onChanged: (value) =>
                    setDialogState(() => trackId = value ?? 0),
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
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    final newName = name.text.trim();
    name.dispose();
    if (result != true) return;
    await _act(() async {
      await ref.read(apiClientProvider).adminRequest(
        'PATCH',
        'users/${widget.id}',
        data: {
          'display_name': newName,
          'industry_track_id': trackId == 0 ? null : trackId,
        },
      );
    });
  }

  Future<void> _status(String action) async {
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title:
            Text('${action[0].toUpperCase()}${action.substring(1)} account?'),
        content: TextField(
          controller: reason,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Reason (optional)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(action[0].toUpperCase() + action.substring(1)),
          ),
        ],
      ),
    );
    final text = reason.text.trim();
    reason.dispose();
    if (confirmed != true) return;
    await _act(() async {
      await ref.read(apiClientProvider).adminRequest(
        'POST',
        'users/${widget.id}/status',
        data: {'action': action, 'reason': text.isEmpty ? null : text},
      );
    });
  }

  Future<void> _grant() async {
    final xp = TextEditingController();
    final tokens = TextEditingController();
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Grant XP / tokens'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: xp,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'XP'),
            ),
            TextField(
              controller: tokens,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Tokens'),
            ),
            TextField(
              controller: reason,
              decoration: const InputDecoration(labelText: 'Reason'),
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
            child: const Text('Grant'),
          ),
        ],
      ),
    );
    final xpValue = int.tryParse(xp.text) ?? 0;
    final tokenValue = int.tryParse(tokens.text) ?? 0;
    final reasonText = reason.text.trim();
    xp.dispose();
    tokens.dispose();
    reason.dispose();
    if (confirmed != true) return;
    await _act(() async {
      await ref.read(apiClientProvider).adminRequest(
        'POST',
        'users/${widget.id}/grant',
        data: {
          'xp': xpValue,
          'tokens': tokenValue,
          'reason': reasonText.isEmpty ? 'Admin grant' : reasonText,
        },
      );
    });
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this account permanently?'),
        content: const Text(
            'This removes the learner, attempts, achievements and Firebase identity. It cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _act(() async {
      await ref
          .read(apiClientProvider)
          .adminRequest('DELETE', 'users/${widget.id}');
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(adminRoleProvider).valueOrNull;
    return AdminToolScaffold(
      title: 'Learner',
      actions: [
        if (role == 'super')
          IconButton(
            tooltip: 'Delete account',
            onPressed: _delete,
            icon: Icon(Icons.delete_forever_rounded, color: AppColors.error),
          ),
      ],
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: FilledButton(
                  onPressed: () => setState(_load), child: const Text('Retry')),
            );
          }
          final data = snapshot.data ?? const {};
          final user = adminMap(data['user']);
          final attempts = adminList(data['attempts']);
          final achievements = adminList(data['achievements']);
          final moderation = adminList(data['moderation']);
          final name =
              adminString(user['display_name'], adminString(user['email']));
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    child: Text(name.characters.first.toUpperCase()),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900)),
                        Text(adminString(user['email']),
                            style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _Pill('Status: ${adminString(user['status'])}'),
                  _Pill('Track: ${adminString(user['track_name'], 'None')}'),
                  _Pill('XP: ${adminInt(user['xp'])}'),
                  _Pill('Tokens: ${adminInt(user['tokens'])}'),
                  _Pill('Level: ${adminInt(user['level'])}'),
                  _Pill('Readiness: ${adminInt(user['readiness_score'])}'),
                ],
              ),
              if (adminString(user['status_reason']).isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text('Reason: ${adminString(user['status_reason'])}',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _edit(user),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit profile'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _grant(),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Grant XP / tokens'),
                  ),
                  if (adminString(user['status']) == 'active') ...[
                    OutlinedButton.icon(
                      onPressed: () => _status('suspend'),
                      icon: const Icon(Icons.pause_circle_outline_rounded),
                      label: const Text('Suspend'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _status('ban'),
                      icon: const Icon(Icons.block_rounded),
                      label: const Text('Ban'),
                    ),
                  ] else
                    OutlinedButton.icon(
                      onPressed: () => _status('activate'),
                      icon: const Icon(Icons.play_circle_outline_rounded),
                      label: const Text('Reactivate'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => _act(() async {
                      await ref.read(apiClientProvider).adminRequest(
                        'POST',
                        'users/${widget.id}/firebase',
                        data: {
                          'disabled': adminString(user['status']) == 'active'
                        },
                      );
                    }),
                    icon: const Icon(Icons.lock_outline_rounded),
                    label: const Text('Toggle Firebase sign-in'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _Section(
                title: 'Recent attempts',
                children: [
                  for (final a in attempts.take(8))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                          adminString(a['task_title'], 'Task ${a['task_id']}')),
                      subtitle: Text(
                          '${adminString(a['feature'])} · ${adminInt(a['score'])} · ${a['passed'] == true ? 'passed' : 'not passed'}'),
                    ),
                  if (attempts.isEmpty) const Text('No attempts.'),
                ],
              ),
              _Section(
                title: 'Achievements',
                children: [
                  for (final a in achievements)
                    Text(
                        '${adminString(a['name'])} · ${adminString(a['earned_at'])}'),
                  if (achievements.isEmpty) const Text('None yet.'),
                ],
              ),
              _Section(
                title: 'Moderation history',
                children: [
                  for (final m in moderation)
                    Text(
                        '${adminString(m['action'])} · ${adminString(m['admin_email'])} · ${adminString(m['created_at'])}'),
                  if (moderation.isEmpty) const Text('No admin actions.'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Chip(label: Text(text));
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.xs),
          ...children,
        ],
      ),
    );
  }
}
