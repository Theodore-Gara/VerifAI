import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/services/api_error.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/features/admin/presentation/admin_shell_screen.dart';
import 'package:verifai/features/admin/presentation/admin_widgets.dart';
import 'package:verifai/features/admin/providers.dart';
import 'package:verifai/shared/widgets/app_feedback_banner.dart';

class AdminTasksScreen extends ConsumerStatefulWidget {
  const AdminTasksScreen({super.key});

  @override
  ConsumerState<AdminTasksScreen> createState() => _AdminTasksScreenState();
}

class _AdminTasksScreenState extends ConsumerState<AdminTasksScreen> {
  Future<Map<String, dynamic>>? _future;
  String _feature = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final query = <String, dynamic>{'limit': 500};
    if (_feature != 'all') query['feature'] = _feature;
    _future = ref
        .read(apiClientProvider)
        .adminRequest('GET', 'tasks', query: query)
        .then(adminMap);
  }

  Future<void> _import() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import tasks JSON'),
        content: TextField(
          controller: controller,
          maxLines: 12,
          decoration: const InputDecoration(
              hintText: '{"tasks": [ ... ]} or an array of tasks'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    final text = controller.text.trim();
    controller.dispose();
    if (confirmed != true || text.isEmpty) return;
    try {
      final decoded = jsonDecode(text);
      final data = decoded is Map
          ? {'tasks': decoded['tasks'], 'dry_run': false}
          : {'tasks': decoded, 'dry_run': false};
      await ref
          .read(apiClientProvider)
          .adminRequest('POST', 'tasks/import', data: data);
      if (mounted) setState(_load);
    } catch (e) {
      if (!mounted) return;
      showFeedback(context, FeedbackKind.error, classifyError(e).message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminToolScaffold(
      title: 'Tasks',
      actions: [
        IconButton(
          tooltip: 'Create task',
          onPressed: () => _showCreate(context),
          icon: const Icon(Icons.add_rounded),
        ),
        IconButton(
          tooltip: 'Import',
          onPressed: _import,
          icon: const Icon(Icons.file_upload_outlined),
        ),
      ],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: DropdownButtonFormField<String>(
              initialValue: _feature,
              decoration: const InputDecoration(labelText: 'Feature'),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All features')),
                DropdownMenuItem(
                    value: 'verification', child: Text('Verification')),
                DropdownMenuItem(value: 'judgement', child: Text('Judgement')),
                DropdownMenuItem(
                    value: 'risk_governance', child: Text('Risk & governance')),
              ],
              onChanged: (value) => setState(() {
                _feature = value ?? 'all';
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
                  return const Center(child: Text('No tasks.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
                      0, AppSpacing.screenPadding, AppSpacing.lg),
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final t = tasks[i];
                    final title = adminString(
                        t['title'] ?? t['j_title'] ?? t['r_title'], t['code']);
                    return Card(
                      child: ListTile(
                        title: Text(title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                            '${adminString(t['feature'])} · ${adminString(t['track_name'])}'
                            ' · ${adminString(t['approval'])}'
                            ' · ${adminInt(t['attempt_count'])} attempts'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context
                            .push('/admin/tools/tasks/${adminInt(t['id'])}'),
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

  Future<void> _showCreate(BuildContext context) async {
    final controller = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert({
        'feature': 'verification',
        'track_id': 1,
        'format': 'choice',
        'title': 'New task',
        'scenario': '',
        'embedded_flaw': '',
        'expected_answer': '',
        'feedback': '',
        'difficulty': 'easy',
        'options': [
          {'kind': 'answer', 'label': 'Option A', 'score': 100},
        ],
      }),
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create task JSON'),
        content: SingleChildScrollView(
          child: TextField(
            controller: controller,
            maxLines: 18,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
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
    );
    final text = controller.text.trim();
    controller.dispose();
    if (confirmed != true || text.isEmpty) return;
    try {
      final data = jsonDecode(text);
      await ref
          .read(apiClientProvider)
          .adminRequest('POST', 'tasks', data: data);
      if (mounted) setState(_load);
    } catch (e) {
      if (!context.mounted) return;
      showFeedback(context, FeedbackKind.error, classifyError(e).message);
    }
  }
}

class AdminTaskEditorScreen extends ConsumerStatefulWidget {
  const AdminTaskEditorScreen({super.key, required this.id});
  final int id;

  @override
  ConsumerState<AdminTaskEditorScreen> createState() =>
      _AdminTaskEditorScreenState();
}

class _AdminTaskEditorScreenState extends ConsumerState<AdminTaskEditorScreen> {
  final _controller = TextEditingController();
  Future<Map<String, dynamic>>? _future;
  bool _saving = false;
  String _feature = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _load() {
    _future = ref
        .read(apiClientProvider)
        .adminRequest('GET', 'tasks/${widget.id}')
        .then((data) {
      final map = adminMap(data);
      final content = adminMap(map['content']);
      final options = adminList(map['options']);
      _feature = adminString(adminMap(map['task'])['feature']);
      _controller.text = const JsonEncoder.withIndent('  ').convert({
        ...content,
        'options': options,
      });
      return map;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final decoded = jsonDecode(_controller.text);
      final body = decoded is Map<String, dynamic>
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
      if (_feature != 'verification') {
        final options = (body.remove('options') as List<dynamic>?) ?? const [];
        body['decisions'] = options
            .whereType<Map>()
            .where((o) => o['kind'] == 'decision')
            .map((o) => {'label': o['label'], 'score': o['score']})
            .toList();
        body['reasons'] = options
            .whereType<Map>()
            .where((o) => o['kind'] == 'reason')
            .map((o) => {'label': o['label'], 'score': o['score']})
            .toList();
      }
      await ref.read(apiClientProvider).adminRequest(
            'PUT',
            'tasks/${widget.id}',
            data: body,
          );
      if (!mounted) return;
      showFeedback(context, FeedbackKind.success, 'Task saved.');
    } catch (e) {
      if (!mounted) return;
      showFeedback(context, FeedbackKind.error, classifyError(e).message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('Attempts linked to this task will be removed.'),
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
    try {
      await ref
          .read(apiClientProvider)
          .adminRequest('DELETE', 'tasks/${widget.id}');
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      showFeedback(context, FeedbackKind.error, classifyError(e).message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminToolScaffold(
      title: 'Task editor',
      actions: [
        IconButton(
          tooltip: 'Delete task',
          onPressed: _delete,
          icon: Icon(Icons.delete_forever_rounded, color: AppColors.error),
        ),
        IconButton(
          tooltip: 'Save',
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_rounded),
        ),
      ],
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AdminLoading();
          }
          if (snapshot.hasError) {
            return AdminErrorView(onRetry: () => setState(_load));
          }
          final task = adminMap(snapshot.data?['task']);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              Text(
                  '${adminString(task['code'])} · ${adminString(task['feature'])}',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _controller,
                minLines: 18,
                maxLines: null,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  labelText: 'Content + options JSON',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
