import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/admin/presentation/admin_widgets.dart';
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
            return const AdminLoading();
          }
          if (snapshot.hasError) {
            return AdminErrorView(
              message: 'Could not load the admin overview.',
              onRetry: () => setState(_load),
            );
          }
          final data = snapshot.data ?? const {};
          final byFeature = adminMap(data['tasks_by_feature']);
          final featureEntries = byFeature.entries.toList()
            ..sort((a, b) => (adminInt(b.value)).compareTo(adminInt(a.value)));
          final maxFeature = featureEntries.isEmpty
              ? 0
              : adminInt(featureEntries.first.value);

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.md,
              AppSpacing.screenPadding,
              AppSpacing.xxl,
            ),
            children: [
              Text(
                'Overview',
                style: AppTypography.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Platform activity at a glance.',
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _StatGrid(data: data),
              const SizedBox(height: AppSpacing.xl),
              AdminSection(
                title: 'Tasks by feature',
                subtitle: featureEntries.isEmpty
                    ? null
                    : '${featureEntries.length} content areas',
                children: [
                  for (final entry in featureEntries)
                    _FeatureRow(
                      label: _pretty(entry.key),
                      count: adminInt(entry.value),
                      max: maxFeature,
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static String _pretty(String key) =>
      key.replaceAll('_', ' ').replaceAllMapped(
          RegExp(r'^[a-z]'), (m) => m.group(0)!.toUpperCase());
}

/// The headline numbers, laid out as a responsive grid.
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final stats = [
      (
        'New tickets',
        adminInt(data['new_tickets']),
        Icons.mark_email_unread_rounded,
        AppColors.error,
      ),
      (
        'Open tickets',
        adminInt(data['open_tickets']),
        Icons.support_agent_rounded,
        AppColors.info,
      ),
      (
        'Learners',
        adminInt(data['users_total']),
        Icons.people_alt_rounded,
        AppColors.accentGreen,
      ),
      (
        'Tasks',
        adminInt(data['tasks_total']),
        Icons.task_alt_rounded,
        AppColors.goldDark,
      ),
      (
        'Attempts',
        adminInt(data['attempts_total']),
        Icons.fact_check_rounded,
        AppColors.xpPurple,
      ),
      (
        'Avg score',
        adminInt(data['avg_attempt_score']),
        Icons.insights_rounded,
        AppColors.accentGreen,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Two columns on a phone, more as the screen widens.
        final columns = constraints.maxWidth >= 720 ? 3 : 2;
        final width =
            (constraints.maxWidth - (columns - 1) * AppSpacing.md) / columns;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final stat in stats)
              SizedBox(
                width: width,
                child: AdminStatTile(
                  label: stat.$1,
                  value: '${stat.$2}',
                  icon: stat.$3,
                  color: stat.$4,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// One feature's task count with a bar showing its share.
class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.label,
    required this.count,
    required this.max,
  });

  final String label;
  final int count;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              '$count',
              style: AppTypography.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.accentGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AdminProportionBar(value: count.toDouble(), max: max.toDouble()),
      ],
    );
  }
}
