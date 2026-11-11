import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/admin/presentation/admin_widgets.dart';

class AdminMoreScreen extends ConsumerWidget {
  const AdminMoreScreen({super.key, this.role});
  final String? role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = <_ToolGroup>[
      const _ToolGroup('Content', [
        _Tool('Tasks', 'Create, edit, import and delete tasks',
            Icons.task_alt_rounded, '/admin/tools/tasks'),
        _Tool('Approvals', 'Review pending task content',
            Icons.fact_check_rounded, '/admin/tools/approvals'),
        _Tool('Content', 'Edit help articles, FAQs and lab lessons',
            Icons.menu_book_rounded, '/admin/tools/content'),
        _Tool('Workshop', 'Moderate posts and reports', Icons.forum_rounded,
            '/admin/tools/workshop'),
      ]),
      const _ToolGroup('Insight', [
        _Tool('Track progress', 'Engagement and skill analytics by track',
            Icons.insights_rounded, '/admin/tools/progress'),
        _Tool('Analytics', 'App-wide usage and performance',
            Icons.bar_chart_rounded, '/admin/tools/analytics'),
        _Tool('CSV exports', 'Download users, attempts and track reports',
            Icons.download_rounded, '/admin/tools/exports'),
      ]),
      const _ToolGroup('System', [
        _Tool('System', 'Health, feature flags and configuration',
            Icons.settings_rounded, '/admin/tools/system'),
        _Tool('Audit log', 'Every admin action, newest first',
            Icons.history_rounded, '/admin/tools/audit'),
      ]),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.xxl,
      ),
      children: [
        Text(
          'Admin tools',
          style: AppTypography.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Everything from the legacy admin panel, rebuilt for mobile.',
          style: AppTypography.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final group in groups) ...[
          AdminSection(
            title: group.title,
            children: [
              for (final tool in group.tools) _ToolRow(tool: tool),
            ],
          ),
        ],
      ],
    );
  }
}

/// One tool row: the name is the subject, the description is metadata.
class _ToolRow extends StatelessWidget {
  const _ToolRow({required this.tool});

  final _Tool tool;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(tool.route),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.accentLight.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(tool.icon, size: 21, color: AppColors.primaryNavy),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tool.title,
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tool.subtitle,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ToolGroup {
  const _ToolGroup(this.title, this.tools);
  final String title;
  final List<_Tool> tools;
}

class _Tool {
  const _Tool(this.title, this.subtitle, this.icon, this.route);
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}
