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
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/app_feedback_banner.dart';

class AdminTicketDetailScreen extends ConsumerStatefulWidget {
  const AdminTicketDetailScreen({super.key, required this.id});
  final int id;

  @override
  ConsumerState<AdminTicketDetailScreen> createState() =>
      _AdminTicketDetailScreenState();
}

class _AdminTicketDetailScreenState
    extends ConsumerState<AdminTicketDetailScreen> {
  final _reply = TextEditingController();
  Future<SupportTicketDetail>? _future;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  void _load() {
    _future = _fetch();
  }

  Future<SupportTicketDetail> _fetch() async {
    final data = await ref
        .read(apiClientProvider)
        .adminRequest('GET', 'support/messages/${widget.id}');
    final map = adminMap(data);
    final detail = SupportTicketDetail(
      ticket: SupportTicket.fromJson(adminMap(map['message'])),
      replies: adminList(map['replies']).map(SupportReply.fromJson).toList(),
    );
    // Clear the admin badge for this ticket after it has been opened.
    ref
        .read(apiClientProvider)
        .adminRequest('POST', 'support/messages/${widget.id}/read')
        .then((_) => ref.invalidate(adminUnreadTicketsProvider))
        .catchError((_) => null);
    return detail;
  }

  Future<void> _send({required bool resolve}) async {
    final text = _reply.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(apiClientProvider).adminRequest(
        'POST',
        'support/messages/${widget.id}/replies',
        data: {'body': text, 'resolve': resolve},
      );
      if (!mounted) return;
      _reply.clear();
      ref.invalidate(adminUnreadTicketsProvider);
      setState(_load);
    } catch (e) {
      if (!mounted) return;
      showFeedback(context, FeedbackKind.error, classifyError(e).message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _setStatus(String status) async {
    try {
      await ref.read(apiClientProvider).adminRequest(
        'PUT',
        'support/messages/${widget.id}',
        data: {'status': status},
      );
      if (!mounted) return;
      setState(_load);
    } catch (e) {
      if (!mounted) return;
      showFeedback(context, FeedbackKind.error, classifyError(e).message);
    }
  }

  Future<void> _editNote(String current) async {
    final controller = TextEditingController(text: current);
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Internal note'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          maxLength: 2000,
          decoration: const InputDecoration(hintText: 'Visible to admins only'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note == null) return;
    try {
      await ref.read(apiClientProvider).adminRequest(
        'PUT',
        'support/messages/${widget.id}',
        data: {'internal_note': note},
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
      title: 'Ticket',
      child: FutureBuilder<SupportTicketDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load this ticket.'),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton(
                      onPressed: () => setState(_load),
                      child: const Text('Retry')),
                ],
              ),
            );
          }
          final detail = snapshot.data!;
          final t = detail.ticket;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.md,
              AppSpacing.screenPadding,
              AppSpacing.xxl,
            ),
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AdminStatusPill(
                    label: t.status.replaceAll('_', ' '),
                    color: switch (t.status) {
                      'new' => AppColors.error,
                      'in_progress' => AppColors.info,
                      'resolved' => AppColors.accentGreen,
                      _ => AppColors.textSecondary,
                    },
                  ),
                  _MetaChip(label: t.publicRef),
                  _MetaChip(label: t.category),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // The subject is the subject: largest thing on the screen.
              Text(
                t.subject,
                style: AppTypography.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  color: AppColors.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${t.name ?? ''} · ${t.email ?? ''}',
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _Bubble(
                text: t.message ?? '',
                author: t.name ?? 'User',
                isAdmin: false,
              ),
              for (final reply in detail.replies)
                _Bubble(
                  text: reply.body,
                  author: reply.authorType == 'admin' ? 'Admin' : 'User',
                  isAdmin: reply.authorType == 'admin',
                ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _reply,
                minLines: 3,
                maxLines: 8,
                maxLength: 4000,
                decoration: const InputDecoration(
                  hintText: 'Write a reply to the user…',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _sending ? null : () => _send(resolve: false),
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Send reply'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _sending ? null : () => _send(resolve: true),
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Reply & resolve'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'STATUS',
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final status in const ['new', 'in_progress', 'resolved'])
                    ChoiceChip(
                      label: Text(status.replaceAll('_', ' ')),
                      selected: t.status == status,
                      onSelected: (_) => _setStatus(status),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton.icon(
                onPressed: () => _editNote(''),
                icon: const Icon(Icons.note_alt_outlined),
                label: const Text('Add internal note'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A quiet chip for a piece of metadata next to the ticket subject.
class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

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

class _Bubble extends StatelessWidget {
  const _Bubble(
      {required this.text, required this.author, required this.isAdmin});
  final String text;
  final String author;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isAdmin ? AppColors.accentLight : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(author,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color:
                      isAdmin ? AppColors.accentGreen : AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(height: 1.45)),
        ],
      ),
    );
  }
}
