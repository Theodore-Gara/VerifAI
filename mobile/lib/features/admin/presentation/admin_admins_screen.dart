import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/services/api_error.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/features/admin/providers.dart';
import 'package:verifai/features/profile/providers.dart';
import 'package:verifai/shared/widgets/app_feedback_banner.dart';

class AdminAdminsScreen extends ConsumerStatefulWidget {
  const AdminAdminsScreen({super.key});

  @override
  ConsumerState<AdminAdminsScreen> createState() => _AdminAdminsScreenState();
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Learner accounts cannot be promoted. Use a separate email for the admin account.'),
              const SizedBox(height: AppSpacing.md),
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
          content: SelectableText(
            link == null || link.isEmpty
                ? 'The account is ready. The admin can sign in with Google or use “Forgot password” to set a password.'
                : 'Share this password-setup link with the admin:\n\n$link',
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
        content: const Text(
            'They will lose access to the admin portal on the next check.'),
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
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: FilledButton(
                onPressed: () => setState(_load), child: const Text('Retry')),
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
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Admin accounts',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900)),
                  ),
                  FilledButton.icon(
                    onPressed: _create,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Create admin'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              for (final admin in dbAdmins)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.admin_panel_settings_rounded),
                    title: Text(adminString(admin['email'])),
                    subtitle: Text(
                        '${adminString(admin['role'])} · added by ${adminString(admin['added_by'], 'system')}'),
                    trailing: myRole == 'super'
                        ? IconButton(
                            tooltip: 'Remove admin',
                            onPressed: () =>
                                _remove(adminString(admin['email'])),
                            icon: Icon(Icons.person_remove_rounded,
                                color: AppColors.error),
                          )
                        : null,
                  ),
                ),
              if (dbAdmins.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Text('No database-registered admins.'),
                ),
              const SizedBox(height: AppSpacing.lg),
              Text('Environment admins',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: AppSpacing.xs),
              for (final admin in envAdmins)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.terminal_rounded),
                  title: Text(adminString(admin['email'])),
                  subtitle:
                      Text('${adminString(admin['role'])} · ADMIN_EMAILS'),
                ),
            ],
          ),
        );
      },
    );
  }
}
