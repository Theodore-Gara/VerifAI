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
          content: AdminDialogBody(
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Display name'),
              ),
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
        content: AdminDialogBody(
          children: [
            const AdminDialogHint(
              'The learner is told why on their next sign-in. This is recorded '
              'in the audit log.',
            ),
            TextField(
              controller: reason,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Reason (optional)'),
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
        content: AdminDialogBody(
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
        content: const AdminDialogHint(
          'This removes the learner, attempts, achievements and Firebase '
          'identity. It cannot be undone.',
        ),
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
            return const AdminLoading();
          }
          if (snapshot.hasError) {
            return AdminErrorView(
              message: 'Could not load this learner.',
              onRetry: () => setState(_load),
            );
          }
          final data = snapshot.data ?? const {};
          final user = adminMap(data['user']);
          final attempts = adminList(data['attempts']);
          final achievements = adminList(data['achievements']);
          final moderation = adminList(data['moderation']);
          final name =
              adminString(user['display_name'], adminString(user['email']));
          final status = adminString(user['status'], 'active');

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.md,
              AppSpacing.screenPadding,
              AppSpacing.xxl,
            ),
            children: [
              // --- Identity: the subject of the page, so it is the largest
              // thing on screen. Everything else is metadata under it.
              Text(
                name,
                style: AppTypography.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                adminString(user['email']),
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AdminStatusPill(
                    label: status,
                    color: switch (status) {
                      'active' => AppColors.accentGreen,
                      'suspended' => AppColors.warning,
                      'banned' => AppColors.error,
                      _ => AppColors.textSecondary,
                    },
                  ),
                  _MetaChip(
                    icon: Icons.work_outline_rounded,
                    label: adminString(user['track_name'], 'No industry'),
                  ),
                ],
              ),
              if (adminString(user['status_reason']).isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                AdminCard(
                  color: AppColors.errorLight,
                  borderColor: AppColors.error.withValues(alpha: 0.3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 18, color: AppColors.error),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          adminString(user['status_reason']),
                          style:
                              AppTypography.textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),

              // --- Key numbers
              Text(
                'PROGRESS',
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 640 ? 4 : 2;
                  final width = (constraints.maxWidth -
                          (columns - 1) * AppSpacing.sm) /
                      columns;
                  final tiles = [
                    ('XP', '${adminInt(user['xp'])}'),
                    ('Level', '${adminInt(user['level'])}'),
                    ('Tokens', '${adminInt(user['tokens'])}'),
                    ('Readiness', '${adminInt(user['readiness_score'])}'),
                  ];
                  return Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final tile in tiles)
                        SizedBox(
                          width: width,
                          child: AdminStatTile(
                            label: tile.$1,
                            value: tile.$2,
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // --- Actions
              Text(
                'ACTIONS',
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AdminCard(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _edit(user),
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Edit profile'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _grant(),
                      icon: const Icon(Icons.add_circle_outline_rounded,
                          size: 18),
                      label: const Text('Grant XP / tokens'),
                    ),
                    if (status == 'active') ...[
                      OutlinedButton.icon(
                        onPressed: () => _status('suspend'),
                        icon: const Icon(Icons.pause_circle_outline_rounded,
                            size: 18),
                        label: const Text('Suspend'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _status('ban'),
                        icon: const Icon(Icons.block_rounded, size: 18),
                        label: const Text('Ban'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                      ),
                    ] else
                      OutlinedButton.icon(
                        onPressed: () => _status('activate'),
                        icon: const Icon(Icons.play_circle_outline_rounded,
                            size: 18),
                        label: const Text('Reactivate'),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => _act(() async {
                        await ref.read(apiClientProvider).adminRequest(
                          'POST',
                          'users/${widget.id}/firebase',
                          data: {'disabled': status == 'active'},
                        );
                      }),
                      icon: const Icon(Icons.lock_outline_rounded, size: 18),
                      label: const Text('Toggle Firebase sign-in'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // --- History sections
              AdminSection(
                title: 'Recent attempts',
                children: [
                  for (final a in attempts.take(8))
                    AdminDataRow(
                      label: adminString(a['feature'], 'Attempt'),
                      value: adminString(
                          a['task_title'], 'Task ${a['task_id']}'),
                      detail:
                          '${adminInt(a['score'])} · ${a['passed'] == true ? 'passed' : 'not passed'}',
                    ),
                  if (attempts.isEmpty)
                    const AdminDialogHint('No attempts yet.'),
                ],
              ),
              AdminSection(
                title: 'Achievements',
                children: [
                  for (final a in achievements)
                    AdminDataRow(
                      label: 'Earned ${adminString(a['earned_at'])}',
                      value: adminString(a['name']),
                    ),
                  if (achievements.isEmpty)
                    const AdminDialogHint('None earned yet.'),
                ],
              ),
              AdminSection(
                title: 'Moderation history',
                children: [
                  for (final m in moderation)
                    AdminDataRow(
                      label: adminString(m['created_at']),
                      value: adminString(m['action']),
                      detail: adminString(m['admin_email']),
                    ),
                  if (moderation.isEmpty)
                    const AdminDialogHint('No admin actions on this learner.'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A quiet chip for a piece of metadata next to the learner's name.
class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
