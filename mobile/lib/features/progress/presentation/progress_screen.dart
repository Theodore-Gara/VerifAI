import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/dashboard/providers.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/dimension_bar.dart';
import 'package:verifai/shared/widgets/empty_state.dart';
import 'package:verifai/shared/widgets/shimmer_loader.dart';
import 'package:verifai/shared/widgets/streak_badge.dart';
import 'package:verifai/shared/widgets/xp_bar.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  /// Weekly practice XP is not exposed by the backend yet, so this chart stays
  /// illustrative until an endpoint provides per-day activity.
  static const List<Map<String, int>> _weeklyActivity = [
    {'day': 1, 'xp': 40},
    {'day': 2, 'xp': 70},
    {'day': 3, 'xp': 25},
    {'day': 4, 'xp': 55},
    {'day': 5, 'xp': 60},
    {'day': 6, 'xp': 30},
    {'day': 7, 'xp': 60},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

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
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(dashboardProvider),
              child: dashboardAsync.when(
                data: (data) => _buildContent(context, data),
                loading: () => _buildShimmer(),
                error: (error, stackTrace) => ErrorState(
                  message: 'Failed to load your progress.',
                  onRetry: () => ref.invalidate(dashboardProvider),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, DashboardData data) {
    final maxWeekXP =
        _weeklyActivity.map((e) => e['xp']!).reduce((a, b) => a > b ? a : b);
    // Level starts at 1 and each level is 250 XP, so the next threshold is
    // level * 250. Mirrors the backend's XP -> level rule.
    final nextLevelXP = data.level * 250;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
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
          XPBar(
            currentXP: data.currentXp,
            nextLevelXP: nextLevelXP,
            level: data.level,
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
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      StreakBadge(days: data.streakDays),
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
                    border: Border.all(
                        color: AppColors.accentGreen.withValues(alpha: 0.3)),
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
                              '${data.completedTasks}',
                              style:
                                  AppTypography.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                            Text(
                              'Completed',
                              style:
                                  AppTypography.textTheme.labelSmall?.copyWith(
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

          // Weekly XP Activity (illustrative — no backend endpoint yet)
          Text(
            'Practice activity',
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
                            colors: [
                              AppColors.accentGreen,
                              AppColors.accentCyan
                            ],
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
          if (data.dimensionScores.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                'Complete a task to start building your readiness profile.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            ...data.dimensionScores.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: DimensionBar(
                  label: _dimensionLabel(entry.key),
                  value: entry.value,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        ShimmerLoader(
          height: 78,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        const SizedBox(height: AppSpacing.md),
        const Row(
          children: [
            Expanded(child: ShimmerLoader(height: 74)),
            SizedBox(width: AppSpacing.md),
            Expanded(child: ShimmerLoader(height: 74)),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const ShimmerLoader(height: 150),
        const SizedBox(height: AppSpacing.xl),
        const ShimmerLoader(height: 24, width: 200),
        const SizedBox(height: AppSpacing.md),
        const ShimmerLoader(height: 16),
        const SizedBox(height: AppSpacing.sm),
        const ShimmerLoader(height: 16),
        const SizedBox(height: AppSpacing.sm),
        const ShimmerLoader(height: 16),
      ],
    );
  }

  /// Backend dimension keys are lowercase snake_case; give the well-known ones
  /// friendly labels and title-case anything else.
  String _dimensionLabel(String key) {
    const labels = {
      'verification': 'Verification',
      'judgement': 'AI Judgement',
      'ai_judgement': 'AI Judgement',
      'prompt_design': 'Prompt Design',
      'risk_governance': 'Risk & Governance',
      'human_ai_collab': 'Human-AI Collaboration',
    };
    return labels[key] ??
        key
            .replaceAll('_', ' ')
            .split(' ')
            .map(
                (w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');
  }
}
