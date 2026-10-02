import 'package:flutter/material.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/shared/widgets/dimension_bar.dart';
import 'package:verifai/shared/widgets/streak_badge.dart';
import 'package:verifai/shared/widgets/xp_bar.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  static const int _streakDays = 7;
  static const int _currentXP = 340;
  static const int _nextLevelXP = 500;
  static const int _level = 3;
  static const int _completedTasks = 23;

  static const List<Map<String, int>> _weeklyActivity = [
    {'day': 1, 'xp': 40},
    {'day': 2, 'xp': 70},
    {'day': 3, 'xp': 25},
    {'day': 4, 'xp': 55},
    {'day': 5, 'xp': 60},
    {'day': 6, 'xp': 30},
    {'day': 7, 'xp': 60},
  ];

  static const Map<String, int> _dimensionScores = {
    'Verification': 78,
    'AI Judgement': 64,
    'Prompt Design': 71,
    'Risk & Governance': 55,
  };

  @override
  Widget build(BuildContext context) {
    final maxWeekXP = _weeklyActivity.map((e) => e['xp']!).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Progress',
          style: AppTypography.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Ambient Mesh Glows
          Positioned(
            top: -60,
            left: -40,
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
            right: -80,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.sm,
                AppSpacing.screenPadding,
                100, // accommodate floating dock
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Level + XP Bento Card (shared XPBar component)
                  const XPBar(
                    currentXP: _currentXP,
                    nextLevelXP: _nextLevelXP,
                    level: _level,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Duo Metric Bento Row
                  Row(
                    children: [
                      // Streak Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              StreakBadge(days: _streakDays),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Completed Tasks Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentGreen.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.accentLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.task_alt_rounded,
                                  color: AppColors.accentGreen,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$_completedTasks',
                                      style: AppTypography.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    Text(
                                      'Completed',
                                      style: AppTypography.textTheme.labelSmall?.copyWith(
                                        color: AppColors.accentGreen,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Weekly XP Activity
                  Text(
                    'Weekly XP Activity',
                    style: AppTypography.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: _weeklyActivity.map((entry) {
                        final xp = entry['xp']!;
                        final height = 12.0 + 88.0 * (xp / maxWeekXP);
                        return Expanded(
                          child: Column(
                            children: [
                              Text(
                                '$xp',
                                style: AppTypography.textTheme.labelSmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 16,
                                height: height,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.accentGreen, AppColors.accentCyan],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'D${entry['day']}',
                                style: AppTypography.textTheme.labelSmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Dimension Scores
                  Text(
                    'Readiness Dimensions',
                    style: AppTypography.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ..._dimensionScores.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: DimensionBar(
                        label: entry.key,
                        value: entry.value,
                        icon: Icons.insights_rounded,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}