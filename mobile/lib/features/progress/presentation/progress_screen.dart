import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:verifai/core/providers/app_reconnect.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/dashboard/providers.dart';
import 'package:verifai/features/progress/providers.dart';
import 'package:verifai/features/scoreboard/providers.dart';
import 'package:verifai/features/navigation/nav_drawer_controller.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/dimension_index_card.dart';
import 'package:verifai/shared/widgets/empty_state.dart';
import 'package:verifai/shared/widgets/shimmer_loader.dart';
import 'package:verifai/shared/widgets/xp_bar.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final activityAsync = ref.watch(activityProvider);

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
              onRefresh: () async {
                ref.invalidate(dashboardProvider);
                ref.invalidate(activityProvider);
              },
              child: dashboardAsync.when(
                data: (data) => _buildContent(ref, data, activityAsync),
                loading: () => _buildShimmer(),
                error: (error, stackTrace) => AsyncErrorView(
                  error: error,
                  fallbackMessage: 'Failed to load your progress.',
                  onRetry: () => reconnectApp(ref),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(WidgetRef ref, DashboardData data,
      AsyncValue<ActivityData> activityAsync) {
    // Mirrors the backend's rising level curve (each level costs +60 more XP).
    final nextLevelXP = _xpForLevel(data.level + 1);

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

          // Duo metric quiet stat tiles
          Row(
            children: [
              _statTile(
                value: '${data.streakDays} Days',
                label: 'Streak Active',
              ),
              const SizedBox(width: AppSpacing.md),
              _statTile(
                value: '${data.completedTasks} Tasks',
                label: 'Completed',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Leaderboard entry point
          _leaderboardCard(ref, ref.watch(leaderboardProvider(null))),
          const SizedBox(height: AppSpacing.xl),

          // Weekly XP Activity
          Text(
            'Practice activity',
            style: AppTypography.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'XP earned over the last 7 days.',
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          activityAsync.when(
            data: (activity) => _buildWeeklyChart(activity),
            loading: () => const ShimmerLoader(height: 150),
            error: (error, _) => InlineErrorCard(
              error: error,
              fallbackMessage: 'We could not load your activity.',
              onRetry: () => reconnectApp(ref),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Dimension Scores
          Text(
            'Readiness Skills',
            style: AppTypography.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DimensionIndexCard(scores: data.dimensionScores),
        ],
      ),
    );
  }

  Widget _leaderboardCard(WidgetRef ref, AsyncValue<LeaderboardData> async) {
    final rank = async.valueOrNull?.me.rank;
    final subtitle = (rank != null && rank > 0)
        ? 'You\'re ranked $rank. Open the scoreboard.'
        : 'Check how you rank against your peers.';
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 1,
      shadowColor: AppColors.shadow,
      child: InkWell(
        onTap: () => ref.context.push('/scoreboard'),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    color: AppColors.primaryNavy, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leaderboard',
                      style: AppTypography.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
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
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(ActivityData activity) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Week runs Monday..Sunday so the bars line up with working days.
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final xpByDate = activity.xpByDate;
    final days = List.generate(7, (i) {
      final date = monday.add(Duration(days: i));
      final iso = '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      return MapEntry(date, xpByDate[iso] ?? 0);
    });
    final maxXp = days.map((d) => d.value).fold(0, (a, b) => a > b ? a : b);
    const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
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
        children: days.asMap().entries.map((entry) {
          final xp = entry.value.value;
          final ratio = maxXp == 0 ? 0.0 : xp / maxXp;
          final height = 12.0 + 88.0 * ratio;
          return Expanded(
            child: Column(
              children: [
                Text(
                  xp == 0 ? '' : '$xp',
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
                    color: ratio > 0
                        ? AppColors.primaryNavy
                        : AppColors.border.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  weekdayLabels[entry.key],
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
    );
  }

  Widget _statTile({
    required String value,
    required String label,
    bool accent = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: accent
                ? AppColors.accentGreen.withValues(alpha: 0.4)
                : AppColors.border,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTypography.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: accent ? AppColors.accentGreen : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _xpForLevel(int level) {
    final k = level - 1;
    return 250 * k + 30 * k * (k - 1);
  }

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: const [
        ShimmerLoader(height: 78),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: ShimmerLoader(height: 74)),
            SizedBox(width: AppSpacing.md),
            Expanded(child: ShimmerLoader(height: 74)),
          ],
        ),
        SizedBox(height: AppSpacing.xl),
        ShimmerLoader(height: 150),
        SizedBox(height: AppSpacing.xl),
        ShimmerLoader(height: 24, width: 200),
        SizedBox(height: AppSpacing.md),
        ShimmerLoader(height: 16),
        SizedBox(height: AppSpacing.sm),
        ShimmerLoader(height: 16),
      ],
    );
  }
}
