import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/services/api_error.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/admin/presentation/admin_widgets.dart';
import 'package:verifai/features/admin/providers.dart';
import 'package:verifai/features/profile/providers.dart';
import 'package:verifai/shared/widgets/app_feedback_banner.dart';

class AdminAdminsScreen extends ConsumerStatefulWidget {
  const AdminAdminsScreen({super.key});

  @override
  ConsumerState<AdminAdminsScreen> createState() =>
      _AdminAdminsScreenState();
}

class _AdminAdminsScreenState extends ConsumerState<AdminAdminsScreen> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ref
        .read(apiClientProvider)
        .adminRequest('GET', 'admins')
        .then(adminMap);
  }

  Future<void> _create() async {
    final email = TextEditingController();
    final name = TextEditingController();
    String role = 'admin';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create admin account'),
          content: AdminDialogBody(
            children: [
              const AdminDialogHint(
                'Learner accounts cannot be promoted. Use a separate email for '
                'the admin account.',
              ),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Display name'),
              ),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(
                      value: 'moderator', child: Text('Moderator')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'super', child: Text('Super')),
                ],
                onChanged: (value) =>
                    setDialogState(() => role = value ?? 'admin'),
              ),
              AdminDialogHint(
                switch (role) {
                  'super' => 'Super admins can manage other admins and delete '
                      'learner accounts.',
                  'moderator' => 'Moderators can review content and moderate '
                      'the workshop.',
                  _ => 'Admins can manage content, learners and workshop.',
                },
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
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    final emailText = email.text.trim();
    final nameText = name.text.trim();
    email.dispose();
    name.dispose();
    if (confirmed != true) return;
    try {
      final data = await ref.read(apiClientProvider).adminRequest(
        'POST',
        'admins',
        data: {
          'email': emailText,
          'display_name': nameText.isEmpty ? null : nameText,
          'role': role,
        },
      );
      if (!mounted) return;
      final link = adminMap(data)['setup_link'] as String?;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Admin account created'),
          content: AdminDialogBody(
            children: [
              SelectableText(
                link == null || link.isEmpty
                    ? 'The account is ready. The admin can sign in with Google '
                        'or use “Forgot password” to set a password.'
                    : 'Share this password-setup link with the admin:\n\n$link',
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) setState(_load);
    } catch (e) {
      if (!mounted) return;
      showFeedback(context, FeedbackKind.error, classifyError(e).message);
    }
  }

  Future<void> _remove(String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove $email?'),
        content: const AdminDialogHint(
          'They will lose access to the admin portal on the next check.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(apiClientProvider).adminRequest('DELETE', 'admins/$email');
      if (mounted) setState(_load);
    } catch (e) {
      if (!mounted) return;
      showFeedback(context, FeedbackKind.error, classifyError(e).message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myRole = ref.watch(adminRoleProvider).valueOrNull;
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminLoading();
        }
        if (snapshot.hasError) {
          return AdminErrorView(
            message: 'Could not load the admin registry.',
            onRetry: () => setState(_load),
          );
        }
        final data = snapshot.data ?? const {};
        final dbAdmins = adminList(data['db_admins']);
        final envAdmins = adminList(data['env_admins']);

        return RefreshIndicator(
          onRefresh: () async {
            setState(_load);
            await _future;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.md,
              AppSpacing.screenPadding,
              AppSpacing.xxl,
            ),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin accounts',
                          style:
                              AppTypography.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Who can reach the admin portal.',
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: _create,
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('Create'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AdminSection(
                title: 'Registered admins',
                subtitle: '${dbAdmins.length} accounts',
                children: [
                  for (final admin in dbAdmins)
                    AdminDataRow(
                      label: 'Added by '
                          '${adminString(admin['added_by'], 'system')}',
                      value: adminString(admin['email']),
                      detail: _roleLabel(adminString(admin['role'])),
                      leading: _RoleIcon(role: adminString(admin['role'])),
                      trailing: myRole == 'super'
                          ? IconButton(
                              tooltip: 'Remove admin',
                              onPressed: () =>
                                  _remove(adminString(admin['email'])),
                              icon: Icon(Icons.person_remove_rounded,
                                  color: AppColors.error, size: 20),
                            )
                          : null,
                    ),
                  if (dbAdmins.isEmpty)
                    const AdminDialogHint('No database-registered admins.'),
                ],
              ),
              AdminSection(
                title: 'Environment admins',
                subtitle: 'Declared in ADMIN_EMAILS, not removable here',
                children: [
                  for (final admin in envAdmins)
                    AdminDataRow(
                      label: 'ADMIN_EMAILS',
                      value: adminString(admin['email']),
                      detail: _roleLabel(adminString(admin['role'])),
                      leading: _RoleIcon(role: adminString(admin['role'])),
                    ),
                  if (envAdmins.isEmpty)
                    const AdminDialogHint('No environment admins.'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static String _roleLabel(String role) => switch (role) {
        'super' => 'Super admin',
        'moderator' => 'Moderator',
        'admin' => 'Admin',
        _ => role,
      };
}

/// Icon tile showing an admin's role.
class _RoleIcon extends StatelessWidget {
  const _RoleIcon({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      'super' => AppColors.xpPurple,
      'moderator' => AppColors.info,
      _ => AppColors.accentGreen,
    };
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Icon(Icons.admin_panel_settings_rounded, size: 22, color: color),
    );
  }
}
