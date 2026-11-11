import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/services/api_error.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/admin/presentation/admin_shell_screen.dart';
import 'package:verifai/features/admin/presentation/admin_widgets.dart';
import 'package:verifai/features/admin/providers.dart';
import 'package:verifai/shared/widgets/app_feedback_banner.dart';

/// Track progress: engagement and skill analytics, organised by track.
///
/// The endpoint returns seven different shapes. Each gets its own section
/// with a heading, so the screen reads as a report rather than a data dump.
class AdminProgressScreen extends ConsumerStatefulWidget {
  const AdminProgressScreen({super.key});
  @override
  ConsumerState<AdminProgressScreen> createState() =>
      _AdminProgressScreenState();
}

class _AdminProgressScreenState extends ConsumerState<AdminProgressScreen> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ref
        .read(apiClientProvider)
        .adminRequest('GET', 'track-progress')
        .then(adminMap);
  }

  @override
  Widget build(BuildContext context) => AdminToolScaffold(
        title: 'Track progress',
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
            final tracks = adminList(data['tracks']);
            final funnel = adminMap(data['funnel']);
            final cohorts = adminList(data['cohorts']);
            final hardest = adminList(data['hardest_tasks']);
            final balance = adminList(data['content_balance']);
            final dims = adminList(data['skill_dimensions']);

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
                  const _ReportIntro(
                    title: 'Track progress',
                    subtitle:
                        'Engagement and skill averages for every industry '
                        'track.',
                  ),
                  AdminSection(
                    title: 'By track',
                    subtitle: '${tracks.length} tracks',
                    children: [
                      for (final t in tracks)
                        _TrackProgressRow(track: t),
                      if (tracks.isEmpty)
                        const AdminDialogHint('No track data.'),
                    ],
                  ),
                  AdminSection(
                    title: 'Onboarding funnel',
                    subtitle: 'Where learners drop off',
                    children: [
                      _FunnelRow(
                        label: 'Signed up',
                        value: adminInt(funnel['signed_up']),
                      ),
                      _FunnelRow(
                        label: 'Chose an industry',
                        value: adminInt(funnel['track_selected']),
                      ),
                      _FunnelRow(
                        label: 'Made a first attempt',
                        value: adminInt(funnel['first_attempt']),
                      ),
                      _FunnelRow(
                        label: 'Reached five attempts',
                        value: adminInt(funnel['five_attempts']),
                      ),
                      _FunnelRow(
                        label: 'Passed a task',
                        value: adminInt(funnel['first_pass']),
                      ),
                      _FunnelRow(
                        label: 'Active in the last 30 days',
                        value: adminInt(funnel['active_30d']),
                      ),
                    ],
                  ),
                  AdminSection(
                    title: 'Cohorts',
                    subtitle: 'Signup month against current engagement',
                    children: [
                      for (final c in cohorts)
                        AdminDataRow(
                          label:
                              '${adminInt(c['users'])} learners · ${adminInt(c['active_30d'])} active in 30d',
                          value: adminString(c['cohort']),
                          detail:
                              'Avg readiness ${adminInt(c['avg_readiness'])} · avg XP ${adminInt(c['avg_xp'])}',
                        ),
                      if (cohorts.isEmpty)
                        const AdminDialogHint('No cohort data yet.'),
                    ],
                  ),
                  AdminSection(
                    title: 'Hardest tasks',
                    subtitle: 'Lowest pass rate with at least 3 attempts',
                    children: [
                      for (final t in hardest)
                        AdminDataRow(
                          label: '${adminString(t['track_name'])} · ${adminString(t['feature'])} · ${adminInt(t['attempts'])} attempts',
                          value: adminString(t['title']),
                          detail: '${adminInt(t['pass_rate'])}% pass rate',
                          trailing: SizedBox(
                            width: 70,
                            child: AdminProportionBar(
                              value: adminInt(t['pass_rate']).toDouble(),
                              max: 100,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      if (hardest.isEmpty)
                        const AdminDialogHint('No task has enough attempts yet.'),
                    ],
                  ),
                  AdminSection(
                    title: 'Content balance',
                    subtitle: 'Task coverage per feature and track',
                    children: [
                      for (final b in balance)
                        AdminDataRow(
                          label:
                              'Verification ${adminInt(b['verification'])} · Judgement ${adminInt(b['judgement'])} · Risk ${adminInt(b['risk_governance'])}',
                          value: adminString(b['track']),
                          detail: '${adminInt(b['drafts'])} drafts',
                        ),
                      if (balance.isEmpty)
                        const AdminDialogHint('No content balance data.'),
                    ],
                  ),
                  AdminSection(
                    title: 'Skill dimensions',
                    subtitle: 'Average score per track and dimension',
                    children: [
                      for (final d in dims)
                        AdminDataRow(
                          label: adminString(d['track_name']),
                          value: adminString(d['dimension']),
                          detail: 'Avg ${adminInt(d['avg_score'])}',
                        ),
                      if (dims.isEmpty)
                        const AdminDialogHint('No skill scores yet.'),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
}

/// One track's engagement numbers.
class _TrackProgressRow extends StatelessWidget {
  const _TrackProgressRow({required this.track});

  final Map<String, dynamic> track;

  @override
  Widget build(BuildContext context) {
    final attempts = adminInt(track['attempts']);
    final passed = adminInt(track['passed']);
    final passRate = attempts == 0 ? 0 : (passed * 100 / attempts).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminDataRow(
          label:
              '${adminInt(track['users'])} learners · ${adminInt(track['active_7d'])} active in 7d'
              ' · ${adminInt(track['active_30d'])} in 30d',
          value: adminString(track['name']),
          detail:
              'Avg readiness ${adminInt(track['avg_readiness'])} · avg level ${adminDouble(track['avg_level'])}'
              ' · ${adminInt(track['task_count'])} tasks',
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AdminProportionBar(
                value: passRate.toDouble(),
                max: 100,
                color: AppColors.accentGreen,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '$passRate% pass',
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One step of the onboarding funnel, with the drop from the previous step.
class _FunnelRow extends StatelessWidget {
  const _FunnelRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Learners reached this step',
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          '$value',
          style: AppTypography.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.accentGreen,
          ),
        ),
      ],
    );
  }
}

/// The heading every report screen opens with.
class _ReportIntro extends StatelessWidget {
  const _ReportIntro({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// App-wide usage and performance.
class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});
  @override
  ConsumerState<AdminAnalyticsScreen> createState() =>
      _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ref
        .read(apiClientProvider)
        .adminRequest('GET', 'analytics')
        .then(adminMap);
  }

  @override
  Widget build(BuildContext context) => AdminToolScaffold(
        title: 'Analytics',
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
            final users = adminMap(data['users']);
            final features = adminList(data['features']);
            final tokens = adminMap(data['tokens']);
            final workshop = adminMap(data['workshop']);
            final llm = adminMap(data['llm_30d']);
            final moderation = adminList(data['moderation_30d']);
            final weekly = adminList(users['weekly_signups']);

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
                  const _ReportIntro(
                    title: 'Analytics',
                    subtitle: 'Usage, engagement and the token economy.',
                  ),
                  AdminSection(
                    title: 'Growth',
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 640 ? 3 : 2;
                          final width = (constraints.maxWidth -
                                  (columns - 1) * AppSpacing.sm) /
                              columns;
                          final tiles = [
                            ('Total learners', '${adminInt(users['total'])}'),
                            ('New in 7d', '${adminInt(users['new_7d'])}'),
                            ('New in 30d', '${adminInt(users['new_30d'])}'),
                            ('Active in 1d', '${adminInt(users['active_1d'])}'),
                            ('Active in 7d', '${adminInt(users['active_7d'])}'),
                            (
                              'Active in 30d',
                              '${adminInt(users['active_30d'])}'
                            ),
                          ];
                          return Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (final tile in tiles)
                                SizedBox(
                                  width: width,
                                  child: AdminStatTile(
                                      label: tile.$1, value: tile.$2),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  AdminSection(
                    title: 'Weekly signups',
                    subtitle: 'Last 12 weeks',
                    children: [
                      for (final w in weekly)
                        AdminDataRow(
                          label: 'Week of ${adminString(w['week_start'])}',
                          value: '${adminInt(w['signups'])} signups',
                        ),
                      if (weekly.isEmpty)
                        const AdminDialogHint('No signups recorded yet.'),
                    ],
                  ),
                  AdminSection(
                    title: 'By feature',
                    children: [
                      for (final f in features)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AdminDataRow(
                              label:
                                  '${adminInt(f['attempts'])} attempts · ${adminInt(f['users'])} learners',
                              value: _pretty(adminString(f['feature'])),
                              detail: '${adminInt(f['pass_rate'])}% pass rate',
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            AdminProportionBar(
                              value: adminInt(f['pass_rate']).toDouble(),
                              max: 100,
                              color: AppColors.info,
                            ),
                          ],
                        ),
                      if (features.isEmpty)
                        const AdminDialogHint('No attempts recorded yet.'),
                    ],
                  ),
                  AdminSection(
                    title: 'Token economy',
                    children: [
                      AdminDataRow(
                        label: 'Issued to learners',
                        value: '${adminInt(tokens['issued'])}',
                      ),
                      AdminDataRow(
                        label: 'Spent on rewards',
                        value: '${adminInt(tokens['spent'])}',
                      ),
                      AdminDataRow(
                        label: 'Adjusted by admins',
                        value: '${adminInt(tokens['admin_adjusted'])}',
                      ),
                      AdminDataRow(
                        label: 'Outstanding balance',
                        value: '${adminInt(tokens['outstanding_balance'])}',
                      ),
                    ],
                  ),
                  AdminSection(
                    title: 'Workshop',
                    children: [
                      AdminDataRow(
                        label: '${adminInt(workshop['posts_7d'])} posts in the last 7 days',
                        value: '${adminInt(workshop['posts'])} posts',
                      ),
                      AdminDataRow(
                        label: '${adminInt(workshop['posts_with_reports'])} posts have reports',
                        value: '${adminInt(workshop['reports_total'])} reports',
                      ),
                      AdminDataRow(
                        label: 'Currently hidden',
                        value: '${adminInt(workshop['hidden'])}',
                      ),
                    ],
                  ),
                  AdminSection(
                    title: 'AI usage (30 days)',
                    children: [
                      AdminDataRow(
                        label: 'Learning Assistant sessions',
                        value: '${adminInt(llm['assistant_30d'])}',
                      ),
                      AdminDataRow(
                        label: 'Vera sessions',
                        value: '${adminInt(llm['vera_30d'])}',
                      ),
                      AdminDataRow(
                        label: 'Verification analyses',
                        value: '${adminInt(llm['verification_30d'])}',
                      ),
                    ],
                  ),
                  AdminSection(
                    title: 'Moderation (30 days)',
                    children: [
                      for (final m in moderation)
                        AdminDataRow(
                          label: 'Admin actions',
                          value: _pretty(adminString(m['action'])),
                          detail: '${adminInt(m['count'])} times',
                        ),
                      if (moderation.isEmpty)
                        const AdminDialogHint('No admin actions in 30 days.'),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );

  static String _pretty(String key) =>
      key.replaceAll('_', ' ').replaceAllMapped(
          RegExp(r'^[a-z]'), (m) => m.group(0)!.toUpperCase());
}

/// Every admin action, newest first.
class AdminAuditScreen extends ConsumerStatefulWidget {
  const AdminAuditScreen({super.key});
  @override
  ConsumerState<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends ConsumerState<AdminAuditScreen> {
  Future<Map<String, dynamic>>? _future;
  String _action = 'all';
  String _query = '';

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
            final all = adminList(snapshot.data?['events']);
            final actions = <String>{
              for (final e in all) adminString(e['action']),
            }.toList()
              ..sort();

            // Filtered on the client: the endpoint already returns the most
            // recent 200 events, which is the whole log the portal shows.
            final events = all.where((e) {
              if (_action != 'all' && adminString(e['action']) != _action) {
                return false;
              }
              if (_query.trim().isEmpty) return true;
              final q = _query.trim().toLowerCase();
              return adminString(e['action']).toLowerCase().contains(q) ||
                  adminString(e['admin_email']).toLowerCase().contains(q) ||
                  adminString(e['reason']).toLowerCase().contains(q);
            }).toList();

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
                  const _ReportIntro(
                    title: 'Audit log',
                    subtitle: 'Every admin action, newest first.',
                  ),
                  AdminFilterBar(
                    children: [
                      TextField(
                        onChanged: (value) => setState(() => _query = value),
                        decoration: const InputDecoration(
                          hintText: 'Search action, admin or reason',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: _action,
                        decoration: const InputDecoration(labelText: 'Action'),
                        items: [
                          const DropdownMenuItem(
                              value: 'all', child: Text('All actions')),
                          for (final a in actions)
                            DropdownMenuItem(value: a, child: Text(_pretty(a))),
                        ],
                        onChanged: (value) =>
                            setState(() => _action = value ?? 'all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (events.isEmpty)
                    const AdminEmptyState(
                      message: 'No admin actions match.',
                      icon: Icons.history_rounded,
                    )
                  else
                    AdminSection(
                      title: 'Events',
                      subtitle: '${events.length} shown',
                      children: [
                        for (final e in events)
                          AdminDataRow(
                            label: '${adminString(e['admin_email'])} · ${adminString(e['created_at'])}',
                            value: _pretty(adminString(e['action'])),
                            detail: adminString(e['reason']),
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.accentLight.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.history_rounded,
                                  size: 18, color: AppColors.primaryNavy),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      );

  static String _pretty(String key) =>
      key.replaceAll('_', ' ').replaceAllMapped(
          RegExp(r'^[a-z]'), (m) => m.group(0)!.toUpperCase());
}

/// Health, feature flags and configuration.
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

  /// Runtime config keys that are genuinely on/off. These get a switch
  /// instead of a text field, because "on" or "off" as editable prose is
  /// easy to get wrong.
  static const _toggleKeys = {
    'maintenance_mode',
    'flag_workshop',
    'flag_assistant',
    'flag_vera',
  };

  Future<void> _setToggle(String key, bool on) async {
    try {
      await ref
          .read(apiClientProvider)
          .adminRequest('PUT', 'config', data: {key: on ? 'on' : 'off'});
      if (mounted) setState(_load);
    } catch (e) {
      if (!mounted) return;
      showFeedback(context, FeedbackKind.error, classifyError(e).message);
    }
  }

  Future<void> _editText(String key, dynamic value) async {
    final controller = TextEditingController(text: '$value');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_pretty(key)),
        content: AdminDialogBody(
          children: [
            TextField(controller: controller, maxLines: 3),
          ],
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
            final system = adminMap(data['system']);
            final config = adminMap(adminMap(data['config'])['config']);

            final toggles = <String, String>{};
            final texts = <String, String>{};
            for (final entry in config.entries) {
              if (_toggleKeys.contains(entry.key)) {
                toggles[entry.key] = '${entry.value}'.toLowerCase();
              } else {
                texts[entry.key] = '${entry.value}';
              }
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.md,
                AppSpacing.screenPadding,
                AppSpacing.xxl,
              ),
              children: [
                const _ReportIntro(
                  title: 'System',
                  subtitle: 'Health, feature flags and runtime configuration.',
                ),
                AdminSection(
                  title: 'Health',
                  children: [
                    for (final entry in system.entries)
                      if (entry.key != 'request_id')
                        AdminDataRow(
                          label: _pretty(entry.key),
                          value: _healthValue(entry.value),
                        ),
                  ],
                ),
                AdminSection(
                  title: 'Feature flags',
                  subtitle: 'Takes effect on the next request',
                  children: [
                    for (final entry in toggles.entries)
                      _ConfigToggle(
                        label: _pretty(entry.key),
                        enabled: entry.value == 'on',
                        onChanged: (value) => _setToggle(entry.key, value),
                      ),
                  ],
                ),
                if (texts.isNotEmpty)
                  AdminSection(
                    title: 'Other configuration',
                    children: [
                      for (final entry in texts.entries)
                        AdminDataRow(
                          label: _pretty(entry.key),
                          value: entry.value,
                          trailing: IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            onPressed: () => _editText(entry.key, entry.value),
                          ),
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
      );

  static String _pretty(String key) =>
      key.replaceAll('_', ' ').replaceAllMapped(
          RegExp(r'^[a-z]'), (m) => m.group(0)!.toUpperCase());

  static String _healthValue(dynamic value) {
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is Map) return '${value.length} entries';
    if (value is List) return '${value.length} items';
    return '$value';
  }
}

/// A configuration key that is on or off, shown as a switch.
class _ConfigToggle extends StatelessWidget {
  const _ConfigToggle({
    required this.label,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                enabled ? 'On' : 'Off',
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: enabled
                      ? AppColors.accentGreen
                      : AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Switch(
          value: enabled,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.accentGreen,
        ),
      ],
    );
  }
}
