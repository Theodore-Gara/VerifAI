import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verifai/core/providers/app_reconnect.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/scoreboard/providers.dart';
import 'package:verifai/shared/widgets/dock_clearance.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/empty_state.dart';
import 'package:verifai/shared/widgets/score_ring.dart';
import 'package:verifai/shared/widgets/shimmer_loader.dart';

class ScoreboardScreen extends ConsumerStatefulWidget {
  const ScoreboardScreen({super.key});

  @override
  ConsumerState<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends ConsumerState<ScoreboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Switching tabs changes the board scope, so rebuild on index change.
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int? _scopeTrackId() {
    if (_tabController.index == 0) return null;
    final trackId = ref.read(currentUserProvider).valueOrNull?.trackId;
    return trackId == null ? null : int.tryParse(trackId);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final scope = _scopeTrackId();
    final boardAsync = ref.watch(leaderboardProvider(scope));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scoreboard',
              style: AppTypography.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Cohort XP & rankings',
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.screenPadding),
            child: Center(child: _LiveBenchmarkPill()),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(leaderboardProvider),
          child: boardAsync.when(
            data: (data) => _buildBoard(data, user),
            loading: () => _buildShimmer(),
            error: (error, _) => AsyncErrorView(
              error: error,
              fallbackMessage: 'Failed to load the leaderboard.',
              onRetry: () => reconnectApp(ref),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoard(LeaderboardData data, User? user) {
    final entries = data.entries;
    final hasTopThree = entries.length >= 3;

    final trackTabLabel =
        (user?.trackName != null && user!.trackName!.isNotEmpty)
            ? '${user.trackName} Track'
            : 'Industry Track';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.xs,
        AppSpacing.screenPadding,
        dockClearance(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scope Control Tabs (Global vs Track Cohort)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.primaryFill,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTypography.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
              ),
              tabs: [
                const Tab(text: 'Global Cohort'),
                Tab(text: trackTabLabel),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Your standing
          _buildStandingBanner(data.me),
          const SizedBox(height: AppSpacing.lg),

          if (entries.isEmpty)
            const EmptyState(
              icon: Icons.workspace_premium_outlined,
              title: 'No rankings yet',
              message:
                  'Be the first to complete verification challenges and establish your AI readiness score.',
            )
          else ...[
            if (hasTopThree) ...[
              _buildTopPerformersHeader(),
              _buildTopPerformersShowcase(entries.take(3).toList()),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'COHORT RANKINGS',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    fontSize: 11.5,
                  ),
                ),
                Text(
                  '${entries.length} members',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Remaining Cohort List
            ...entries.skip(hasTopThree ? 3 : 0).map(_buildLeaderboardTile),
          ],
        ],
      ),
    );
  }

  Widget _buildStandingBanner(LeaderboardEntry me) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ScoreRing(
            score: me.readinessScore,
            size: 58,
            strokeWidth: 5.5,
            child: Center(
              child: Text(
                '${me.readinessScore}',
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryNavy,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR BENCHMARK',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Rank ${me.rank} · ${me.tier}',
                  style: AppTypography.textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${me.streak} day streak · ${me.xp} XP',
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformersHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'TOP PERFORMERS',
          style: AppTypography.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            fontSize: 11.5,
          ),
        ),
        Text(
          'Total XP',
          style: AppTypography.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.7),
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTopPerformersShowcase(List<LeaderboardEntry> topThree) {
    final first = topThree[0];
    final second = topThree[1];
    final third = topThree[2];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _buildEliteSpot(entry: second, rank: 2, isFirst: false),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildEliteSpot(entry: first, rank: 1, isFirst: true),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildEliteSpot(entry: third, rank: 3, isFirst: false),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEliteSpot({
    required LeaderboardEntry entry,
    required int rank,
    required bool isFirst,
  }) {
    final initial = entry.name.trim().isEmpty ? '?' : entry.name.trim()[0];
    final firstName = entry.name.trim().split(RegExp(r'\s+')).first;

    final rankColor = switch (rank) {
      1 => AppColors.gold,
      2 => AppColors.silver,
      _ => AppColors.bronze,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: isFirst ? AppColors.surface : AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isFirst
              ? AppColors.primaryNavy.withValues(alpha: 0.5)
              : AppColors.border,
          width: isFirst ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$rank',
            style: AppTypography.textTheme.titleMedium?.copyWith(
              color: rankColor,
              fontWeight: FontWeight.w900,
              fontSize: isFirst ? 15 : 13,
            ),
          ),
          const SizedBox(height: 8),
          CircleAvatar(
            radius: isFirst ? 20 : 17,
            backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.08),
            child: Text(
              initial,
              style: AppTypography.textTheme.labelMedium?.copyWith(
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            firstName,
            style: AppTypography.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${entry.xp} XP',
            style: AppTypography.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTile(LeaderboardEntry entry) {
    final initial = entry.name.trim().isEmpty ? '?' : entry.name.trim()[0];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? AppColors.accentLight.withValues(alpha: 0.45)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: entry.isCurrentUser ? AppColors.accentGreen : AppColors.border,
          width: entry.isCurrentUser ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: entry.isCurrentUser
                ? AppColors.accentGreen.withValues(alpha: 0.08)
                : AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${entry.rank}',
              style: AppTypography.textTheme.labelMedium?.copyWith(
                color: entry.isCurrentUser
                    ? AppColors.accentGreen
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          CircleAvatar(
            radius: 17,
            backgroundColor: entry.isCurrentUser
                ? AppColors.accentGreen
                : AppColors.primaryNavy.withValues(alpha: 0.08),
            child: Text(
              initial,
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color:
                    entry.isCurrentUser ? Colors.white : AppColors.primaryNavy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.name,
                        style: AppTypography.textTheme.bodyMedium?.copyWith(
                          fontWeight: entry.isCurrentUser
                              ? FontWeight.w800
                              : FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.isCurrentUser) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.greenFill,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          'YOU',
                          style: AppTypography.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  entry.tier,
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.xp} XP',
                style: AppTypography.textTheme.titleSmall?.copyWith(
                  color: entry.isCurrentUser
                      ? AppColors.accentGreen
                      : AppColors.primaryNavy,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        100,
      ),
      children: [
        const ShimmerLoader(
          height: 44,
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
        ),
        const SizedBox(height: AppSpacing.md),
        const ShimmerLoader(
          height: 84,
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        ),
        const SizedBox(height: AppSpacing.lg),
        const ShimmerLoader(
          height: 124,
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        ),
        const SizedBox(height: AppSpacing.md),
        ...List.generate(
          4,
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: ShimmerLoader(
              height: 64,
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveBenchmarkPill extends StatelessWidget {
  const _LiveBenchmarkPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: AppColors.accentLight.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.accentGreen.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.accentGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'LIVE BENCHMARK',
            style: AppTypography.textTheme.labelSmall?.copyWith(
              color: AppColors.primaryNavy,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
