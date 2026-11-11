import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/features/admin/providers.dart';

class AdminOverviewScreen extends ConsumerStatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  ConsumerState<AdminOverviewScreen> createState() =>
      _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends ConsumerState<AdminOverviewScreen> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ref
        .read(apiClientProvider)
        .adminRequest('GET', 'overview')
        .then(adminMap);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminUnreadTicketsProvider);
        setState(_load);
        await _future;
      },
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorRetry(
                error: snapshot.error, onRetry: () => setState(_load));
          }
          final data = snapshot.data ?? const {};
          final byFeature = adminMap(data['tasks_by_feature']);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              Text('Overview',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _Stat('New tickets', adminInt(data['new_tickets']),
                      Icons.mark_email_unread_rounded, AppColors.error),
                  _Stat('Open tickets', adminInt(data['open_tickets']),
                      Icons.support_agent_rounded, AppColors.info),
                  _Stat('Learners', adminInt(data['users_total']),
                      Icons.people_alt_rounded, AppColors.accentGreen),
                  _Stat('Tasks', adminInt(data['tasks_total']),
                      Icons.task_alt_rounded, AppColors.goldDark),
                  _Stat('Attempts', adminInt(data['attempts_total']),
                      Icons.fact_check_rounded, AppColors.xpPurple),
                  _Stat('Avg score', adminInt(data['avg_attempt_score']),
                      Icons.insights_rounded, AppColors.accentGreen),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Tasks by feature',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: AppSpacing.sm),
              for (final entry in byFeature.entries)
                Card(
                  child: ListTile(
                    title: Text(entry.key.replaceAll('_', ' ')),
                    trailing: Text('${entry.value}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon, this.color);
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: AppSpacing.sm),
              Text('$value',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900)),
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textSecondary),
        const SizedBox(height: AppSpacing.md),
        Text('Could not load the admin overview.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ),
      ],
    );
  }
}
