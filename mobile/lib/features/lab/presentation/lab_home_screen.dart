import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';

/// AI Lab home: the three pillars: Learning material, Practice, Assessments.
class LabHomeScreen extends StatelessWidget {
  const LabHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = <({String title, String subtitle, IconData icon, String route})>[
      (
        title: 'Learning material',
        subtitle: 'Textbook lessons, worked through topic by topic',
        icon: Icons.menu_book_rounded,
        route: '/ai-lab/lessons',
      ),
      (
        title: 'Practice',
        subtitle: 'Recall questions drawn from each lesson, earn XP',
        icon: Icons.quiz_outlined,
        route: '/ai-lab/practice',
      ),
      (
        title: 'Assessments',
        subtitle: 'Module capstones: scenario based, timed and marked',
        icon: Icons.workspace_premium_rounded,
        route: '/ai-lab/assessments',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
        title: Text('AI Lab',
            style: AppTypography.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm,
              AppSpacing.screenPadding, AppSpacing.xxl),
          children: [
            Text('Learn, practise, then prove it.',
                style: AppTypography.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.lg),
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    onTap: () => context.push(e.route),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                AppColors.accentGreen.withValues(alpha: .18),
                                AppColors.accentCyan.withValues(alpha: .18),
                              ]),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(e.icon, color: AppColors.primaryNavy),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.title,
                                    style: AppTypography.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryNavy)),
                                const SizedBox(height: 3),
                                Text(e.subtitle,
                                    style: AppTypography.textTheme.bodySmall
                                        ?.copyWith(color: AppColors.textSecondary, height: 1.35)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
