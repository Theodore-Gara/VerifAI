import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/services/api_error.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/features/admin/presentation/admin_shell_screen.dart';
import 'package:verifai/features/admin/presentation/admin_widgets.dart';
import 'package:verifai/features/admin/providers.dart';
import 'package:verifai/shared/widgets/app_feedback_banner.dart';

class AdminProgressScreen extends ConsumerStatefulWidget {
  const AdminProgressScreen({super.key});
  @override
  ConsumerState<AdminProgressScreen> createState() =>
      _AdminProgressScreenState();
}

class _AdminProgressScreenState extends ConsumerState<AdminProgressScreen> {
  Future<dynamic>? _future;
  @override
  void initState() {
    super.initState();
    _future = ref.read(apiClientProvider).adminRequest('GET', 'track-progress');
  }

  @override
  Widget build(BuildContext context) => AdminToolScaffold(
        title: 'Track progress',
        child: FutureBuilder<dynamic>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AdminLoading();
            }
            if (snapshot.hasError) {
              return AdminErrorView(
                  onRetry: () => setState(() {
                        _future = ref
                            .read(apiClientProvider)
                            .adminRequest('GET', 'track-progress');
                      }));
            }
            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _future = ref
                      .read(apiClientProvider)
                      .adminRequest('GET', 'track-progress');
                });
                await _future;
              },
              child: AdminJsonView(data: snapshot.data),
            );
          },
        ),
      );
}

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});
  @override
  ConsumerState<AdminAnalyticsScreen> createState() =>
      _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  Future<dynamic>? _future;
  @override
  void initState() {
    super.initState();
    _future = ref.read(apiClientProvider).adminRequest('GET', 'analytics');
  }

  @override
  Widget build(BuildContext context) => AdminToolScaffold(
        title: 'Analytics',
        child: FutureBuilder<dynamic>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AdminLoading();
            }
            if (snapshot.hasError) {
              return AdminErrorView(
                  onRetry: () => setState(() {
                        _future = ref
                            .read(apiClientProvider)
                            .adminRequest('GET', 'analytics');
                      }));
            }
            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _future = ref
                      .read(apiClientProvider)
                      .adminRequest('GET', 'analytics');
                });
                await _future;
              },
              child: AdminJsonView(data: snapshot.data),
            );
          },
        ),
      );
}

class AdminAuditScreen extends ConsumerStatefulWidget {
  const AdminAuditScreen({super.key});
  @override
  ConsumerState<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends ConsumerState<AdminAuditScreen> {
  Future<Map<String, dynamic>>? _future;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ref.read(apiClientProvider).adminRequest('GET', 'moderation',
        query: {'limit': 200}).then(adminMap);
  }

  @override
  Widget build(BuildContext context) => AdminToolScaffold(
        title: 'Audit log',
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AdminLoading();
            }
            if (snapshot.hasError) {
              return AdminErrorView(onRetry: () => setState(_load));
            }
            final events = adminList(snapshot.data?['events']);
            if (events.isEmpty) {
              return const Center(child: Text('No admin actions yet.'));
            }
            return RefreshIndicator(
              onRefresh: () async {
                setState(_load);
                await _future;
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                itemCount: events.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final e = events[i];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.history_rounded),
                      title: Text(adminString(e['action'])),
                      subtitle: Text(
                          '${adminString(e['admin_email'])} · ${adminString(e['created_at'])}'
                          '${adminString(e['reason']).isEmpty ? '' : '\n${adminString(e['reason'])}'}'),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
}

class AdminSystemScreen extends ConsumerStatefulWidget {
  const AdminSystemScreen({super.key});
  @override
  ConsumerState<AdminSystemScreen> createState() => _AdminSystemScreenState();
}

class _AdminSystemScreenState extends ConsumerState<AdminSystemScreen> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = Future.wait([
      ref.read(apiClientProvider).adminRequest('GET', 'system'),
      ref.read(apiClientProvider).adminRequest('GET', 'config'),
    ]).then((values) => {
          'system': values[0],
          'config': values[1],
        });
  }

  Future<void> _editConfig(String key, dynamic value) async {
    final controller = TextEditingController(text: '$value');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(key.replaceAll('_', ' ')),
        content: TextField(controller: controller, maxLines: 3),
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
    final text = controller.text.trim();
    controller.dispose();
    if (saved != true) return;
    try {
      await ref
          .read(apiClientProvider)
          .adminRequest('PUT', 'config', data: {key: text});
      if (mounted) setState(_load);
    } catch (e) {
      if (!mounted) return;
      showFeedback(context, FeedbackKind.error, classifyError(e).message);
    }
  }

  @override
  Widget build(BuildContext context) => AdminToolScaffold(
        title: 'System',
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AdminLoading();
            }
            if (snapshot.hasError) {
              return AdminErrorView(onRetry: () => setState(_load));
            }
            final data = snapshot.data ?? const {};
            final config = adminMap(adminMap(data['config'])['config']);
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                Text('Health',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 360,
                  child: AdminJsonView(data: data['system']),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Configuration',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: AppSpacing.sm),
                for (final entry in config.entries)
                  Card(
                    child: ListTile(
                      title: Text(entry.key.replaceAll('_', ' ')),
                      subtitle: Text('${entry.value}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_rounded),
                        onPressed: () => _editConfig(entry.key, entry.value),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
}
