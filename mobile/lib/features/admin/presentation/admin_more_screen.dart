import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_spacing.dart';

class AdminMoreScreen extends ConsumerWidget {
  const AdminMoreScreen({super.key, this.role});
  final String? role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = <_Tool>[
      const _Tool('Tasks', 'Create, edit, import and delete tasks',
          Icons.task_alt_rounded, '/admin/tools/tasks'),
      const _Tool('Approvals', 'Review pending task content',
          Icons.fact_check_rounded, '/admin/tools/approvals'),
      const _Tool('Content', 'Edit help articles, FAQs and lab lessons',
          Icons.menu_book_rounded, '/admin/tools/content'),
      const _Tool('Workshop', 'Moderate posts and reports', Icons.forum_rounded,
          '/admin/tools/workshop'),
      const _Tool('Track progress', 'Engagement and skill analytics by track',
          Icons.insights_rounded, '/admin/tools/progress'),
      const _Tool('Analytics', 'App-wide usage and performance',
          Icons.bar_chart_rounded, '/admin/tools/analytics'),
      const _Tool('System', 'Health, feature flags and configuration',
          Icons.settings_rounded, '/admin/tools/system'),
      const _Tool('Audit log', 'Every admin action, newest first',
          Icons.history_rounded, '/admin/tools/audit'),
      const _Tool('CSV exports', 'Download users, attempts and track reports',
          Icons.download_rounded, '/admin/tools/exports'),
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        Text('Admin tools',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: AppSpacing.xs),
        Text('Everything from the legacy admin panel, rebuilt for mobile.',
            style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.lg),
        for (final item in items)
          Card(
            child: ListTile(
              leading: Icon(item.icon, color: AppColors.accentGreen),
              title: Text(item.title,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(item.subtitle),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(item.route),
            ),
          ),
      ],
    );
  }
}

class _Tool {
  const _Tool(this.title, this.subtitle, this.icon, this.route);
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}
