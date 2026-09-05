import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/dashboard/presentation/task_challenge_modal.dart';
import 'package:verifai/features/dashboard/providers.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryNavy,
              child: Text(
                (user?.name?.isNotEmpty == true) ? user!.name![0].toUpperCase() : 'U',
                style: AppTypography.textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  user?.trackName ?? 'Specialization Active',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(dashboardProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardProvider),
        child: dashboardAsync.when(
          data: (data) => _buildDashboard(data, user),
          loading: () => _buildShimmer(),
          error: (error, stackTrace) => ErrorState(
            message: 'Failed to load dashboard. Pull to refresh.',
            onRetry: () => ref.invalidate(dashboardProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(DashboardData data, User? user) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player HUD: Level, XP, and Streak
          const XPBar(
            currentXP: 340,
            nextLevelXP: 500,
            level: 3,
          ),
          const SizedBox(height: AppSpacing.md),

          // Streak Banner
          StreakBadgeLarge(
            days: data.streakDays,
            label: 'Keep up the momentum to reach a 10-day milestone!',
          ),
          const SizedBox(height: AppSpacing.xl),

          // Overall Readiness Ring Card
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
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                ScoreRing(
                  score: data.overallScore,
                  size: 110,
                  strokeWidth: 10,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(AppRadius.badge),
                        ),
                        child: Text(
                          'READINESS SCORE',
                          style: AppTypography.textTheme.labelSmall?.copyWith(
                            color: AppColors.accentGreen,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'AI Workplace Ready',
                        style: AppTypography.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You are in the top 15% of peers in your industry track.',
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Daily Mission Card
          if (data.dailyTask != null) ...[
            Text(
              'Active Mission',
              style: AppTypography.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DailyTaskCard(
              task: data.dailyTask!,
              onStart: () => _playTask(data.dailyTask!),
            ),
          ] else ...[
            EmptyState(
              icon: Icons.task_alt_rounded,
              title: 'All caught up today!',
              message: 'Great work! Check back tomorrow for your next AI challenge.',
              actionLabel: 'Refresh',
              onAction: () => ref.invalidate(dashboardProvider),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),

          // Dimension Breakdown Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Skill Mastery',
                style: AppTypography.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '5 Dimensions',
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Dimension Bars
          ...data.dimensionScores.entries.map((entry) {
            final color = _getDimensionColor(entry.key);
            final icon = _getDimensionIcon(entry.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: DimensionBar(
                label: _formatDimension(entry.key),
                value: entry.value,
                progressColor: color,
                icon: icon,
              ),
            );
          }),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        ShimmerLoader(height: 54, borderRadius: BorderRadius.circular(AppRadius.card)),
        const SizedBox(height: AppSpacing.md),
        ShimmerLoader(height: 80, borderRadius: BorderRadius.circular(AppRadius.card)),
        const SizedBox(height: AppSpacing.xl),
        const ShimmerLoader.card(height: 120),
        const SizedBox(height: AppSpacing.xl),
        const ShimmerLoader.card(height: 200),
        const SizedBox(height: AppSpacing.xl),
        ...List.generate(4, (index) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ShimmerLoader(height: 56, borderRadius: BorderRadius.circular(AppRadius.lg)),
            )),
      ],
    );
  }

  void _playTask(DailyTask task) {
    TaskChallengeModal.show(context, task, () {
      ref.invalidate(dashboardProvider);
    });
  }

  Color _getDimensionColor(String dimension) {
    switch (dimension.toLowerCase()) {
      case 'verification':
        return AppColors.accentGreen;
      case 'judgement':
        return AppColors.accentCyan;
      case 'prompt_design':
        return AppColors.xpPurple;
      case 'risk_governance':
        return AppColors.warning;
      case 'human_ai_collab':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getDimensionIcon(String dimension) {
    switch (dimension.toLowerCase()) {
      case 'verification':
        return Icons.verified_user_rounded;
      case 'judgement':
        return Icons.psychology_rounded;
      case 'prompt_design':
        return Icons.terminal_rounded;
      case 'risk_governance':
        return Icons.security_rounded;
      case 'human_ai_collab':
        return Icons.group_work_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  String _formatDimension(String dimension) {
    return dimension
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? (w[0].toUpperCase() + w.substring(1)) : '')
        .join(' ');
  }
}