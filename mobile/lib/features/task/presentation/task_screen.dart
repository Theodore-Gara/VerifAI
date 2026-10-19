import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/navigation/nav_drawer_controller.dart';

/// Tasks tab — a hub of skill categories. Each card leads to that skill's
/// dedicated task flow.
class TaskScreen extends ConsumerWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackName = ref.watch(currentUserProvider).valueOrNull?.trackName;
    final isLegal = (trackName ?? '').toLowerCase() == 'legal';

    final categories = <_Category>[
      const _Category(
        icon: Icons.shield_rounded,
        title: 'Verification',
        subtitle: 'Catch AI\u2019s mistakes and fix them',
        route: '/verification',
        color: AppColors.accentGreen,
      ),
      const _Category(
        icon: Icons.psychology_rounded,
        title: 'AI Judgement',
        subtitle: 'Decide when AI should or shouldn\u2019t be used',
        route: '/judgement',
        color: AppColors.accentCyan,
      ),
      const _Category(
        icon: Icons.gavel_rounded,
        title: 'Risk & Governance',
        subtitle: 'Spot privacy, bias and compliance risks',
        route: '/risk-governance',
        color: AppColors.xpPurple,
      ),
      if (isLegal)
        const _Category(
          icon: Icons.question_answer_rounded,
          title: 'Interview Practice',
          subtitle: 'Work through interview questions',
          route: '/interview',
          color: AppColors.gold,
        ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const IconButton(
          tooltip: 'Open navigation menu',
          icon: Icon(Icons.menu_rounded, color: AppColors.textPrimary),
          onPressed: openVerifaiNavigationDrawer,
        ),
        title: Text(
          'Tasks',
          style: AppTypography.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.ambientCyan,
              ),
            ),
          ),
          Positioned(
            top: 320,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.ambientGreen,
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.sm,
                AppSpacing.screenPadding,
                100,
              ),
              children: [
                Text(
                  'Choose a skill',
                  style: AppTypography.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Practise a skill, then take on its workplace scenarios.',
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/assistant'),
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Ask Vera'),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final category in categories) ...[
                  _CategoryCard(category: category),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Category {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Color color;

  const _Category({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.color,
  });
}

class _CategoryCard extends StatelessWidget {
  final _Category category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push(category.route);
      },
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.title,
                    style: AppTypography.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.subtitle,
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
