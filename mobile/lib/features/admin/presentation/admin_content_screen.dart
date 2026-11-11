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

class AdminContentScreen extends ConsumerStatefulWidget {
  const AdminContentScreen({super.key});

  @override
  ConsumerState<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends ConsumerState<AdminContentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  Future<Map<String, dynamic>>? _help;
  Future<Map<String, dynamic>>? _faqs;
  Future<Map<String, dynamic>>? _lab;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _load() {
    _help = ref
        .read(apiClientProvider)
        .adminRequest('GET', 'support/help')
        .then(adminMap);
    _faqs = ref
        .read(apiClientProvider)
        .adminRequest('GET', 'support/faqs')
        .then(adminMap);
    _lab =
        ref.read(apiClientProvider).adminRequest('GET', 'lab').then(adminMap);
  }

  Future<void> _editHelp(Map<String, dynamic> article) async {
    final title = TextEditingController(text: adminString(article['title']));
    final summary =
        TextEditingController(text: adminString(article['summary']));
    final body = TextEditingController(text: adminString(article['body_md']));
    bool published = article['published'] == true;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit help article'),
          content: SingleChildScrollView(
            child: AdminDialogBody(
              children: [
                TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Title')),
                TextField(
                    controller: summary,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Summary')),
                TextField(
                    controller: body,
                    maxLines: 10,
                    decoration:
                        const InputDecoration(labelText: 'Body (Markdown)')),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Published'),
                  value: published,
                  onChanged: (v) => setDialogState(() => published = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Save')),
          ],
        ),
      ),
    );
    final values = {
      'title': title.text.trim(),
      'summary': summary.text.trim(),
      'body': body.text.trim(),
      'published': published,
    };
    title.dispose();
    summary.dispose();
    body.dispose();
    if (saved != true) return;
    await _put('support/help/${adminInt(article['id'])}', values);
  }

  Future<void> _editFaq(Map<String, dynamic> faq) async {
    final question = TextEditingController(text: adminString(faq['question']));
    final answer = TextEditingController(text: adminString(faq['answer_md']));
    bool published = faq['published'] == true;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit FAQ'),
          content: SingleChildScrollView(
            child: AdminDialogBody(
              children: [
                TextField(
                    controller: question,
                    decoration: const InputDecoration(labelText: 'Question')),
                TextField(
                    controller: answer,
                    maxLines: 8,
                    decoration:
                        const InputDecoration(labelText: 'Answer (Markdown)')),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Published'),
                  value: published,
                  onChanged: (v) => setDialogState(() => published = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Save')),
          ],
        ),
      ),
    );
    final values = {
      'question': question.text.trim(),
      'answer_md': answer.text.trim(),
      'published': published,
    };
    question.dispose();
    answer.dispose();
    if (saved != true) return;
    await _put('support/faqs/${adminInt(faq['id'])}', values);
  }

  Future<void> _put(String path, Map<String, dynamic> data) async {
    try {
      await ref.read(apiClientProvider).adminRequest('PUT', path, data: data);
      if (!mounted) return;
      setState(_load);
      showFeedback(context, FeedbackKind.success, 'Saved.');
    } catch (e) {
      if (!mounted) return;
      showFeedback(context, FeedbackKind.error, classifyError(e).message);
    }
  }

  Future<void> _openLab(Map<String, dynamic> lesson) async {
    final data = await ref
        .read(apiClientProvider)
        .adminRequest('GET', 'lab/${adminInt(lesson['id'])}');
    if (!mounted) return;
    final map = adminMap(data);
    final sections = adminList(map['sections']);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .8,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            Text(adminString(lesson['title']),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: AppSpacing.md),
            for (final section in sections)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AdminCard(
                  child: AdminDataRow(
                    label: adminString(section['body']),
                    value: adminString(section['heading'], 'Section'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: () => _editLabSection(section),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editLabSection(Map<String, dynamic> section) async {
    final heading =
        TextEditingController(text: adminString(section['heading']));
    final body = TextEditingController(text: adminString(section['body']));
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit lab section'),
        content: SingleChildScrollView(
          child: AdminDialogBody(
            children: [
              TextField(
                  controller: heading,
                  decoration: const InputDecoration(labelText: 'Heading')),
              TextField(
                  controller: body,
                  maxLines: 10,
                  decoration:
                      const InputDecoration(labelText: 'Body (Markdown)')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save')),
        ],
      ),
    );
    final values = {'heading': heading.text.trim(), 'body': body.text.trim()};
    heading.dispose();
    body.dispose();
    if (saved != true) return;
    await _put('lab/sections/${adminInt(section['id'])}', values);
  }

  @override
  Widget build(BuildContext context) {
    return AdminToolScaffold(
      title: 'Content',
      child: Column(
        children: [
          TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Help'),
              Tab(text: 'FAQs'),
              Tab(text: 'Lab'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _contentList(
                    _help,
                    'articles',
                    _editHelp,
                    (a) =>
                        '${adminString(a['title'])} · ${adminString(a['category'])}'),
                _contentList(
                    _faqs, 'faqs', _editFaq, (f) => adminString(f['question'])),
                _contentList(
                    _lab,
                    'lessons',
                    _openLab,
                    (l) =>
                        '${adminString(l['title'])} · ${adminString(l['track_name'])}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contentList(
    Future<Map<String, dynamic>>? future,
    String key,
    Future<void> Function(Map<String, dynamic>) onTap,
    String Function(Map<String, dynamic>) label,
  ) {
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
          return const AdminEmptyState(
            message: 'No content here.',
            icon: Icons.menu_book_rounded,
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
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) => AdminCard(
            onTap: () => onTap(items[i]),
            child: AdminDataRow(
              label: 'Published content',
              value: label(items[i]),
              trailing: Icon(Icons.edit_rounded,
                  color: AppColors.textSecondary, size: 20),
            ),
          ),
        );
      },
    );
  }
}
