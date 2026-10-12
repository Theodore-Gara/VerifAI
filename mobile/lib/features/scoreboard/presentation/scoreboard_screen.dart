import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verifai/core/providers/app_reconnect.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/scoreboard/providers.dart';
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
              'Cohort readiness & rankings',
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
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
      body: Stack(
        children: [
          // Ambient Mesh Glows (Mint & Cyan on-theme lighting)
          Positioned(
            top: -50,
            right: -30,
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
            top: 260,
            left: -60,
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
        ],
      ),
    );
  }

  Widget _buildBoard(LeaderboardData data, User? user) {
    final entries = data.entries;
    final hasTopThree = entries.length >= 3;

    final trackTabLabel = (user?.trackName != null && user!.trackName!.isNotEmpty)
        ? '${user.trackName} Track'
        : 'Industry Track';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.xs,
        AppSpacing.screenPadding,
        100, // accommodates floating dock
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
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.primaryNavy,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryNavy.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
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

          // Your Cohort Standing Bento Card
          _buildStandingBanner(data.me, entries.length),
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
              // Elite Top 3 Showcase
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
                    fontSize: 10.5,
                  ),
                ),
                Text(
                  '${entries.length} members',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Remaining Cohort List
            ...entries
                .skip(hasTopThree ? 3 : 0)
                .map(_buildLeaderboardTile),
          ],
        ],
      ),
    );
  }

  Widget _buildStandingBanner(LeaderboardEntry me, int totalEntries) {
    final percentile = totalEntries > 0
        ? math.max(1, ((me.rank / math.max(totalEntries, me.rank)) * 100).ceil())
        : 1;
    final cohortContext = me.rank == 1
        ? 'Top 1% · Leader'
        : 'Top $percentile% Cohort';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryNavy,
            Color(0xFF132235),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.glassBorderDark),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          const BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mini Readiness Gauge
          ScoreRing(
            score: me.readinessScore,
            size: 58,
            strokeWidth: 5.5,
            progressColor: AppColors.accentCyan,
            trackColor: Colors.white.withValues(alpha: 0.12),
            child: Center(
              child: Text(
                '${me.readinessScore}',
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
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
                    color: AppColors.accentCyan,
                    fontWeight: FontWeight.w800,
                    fontSize: 9.5,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Rank #${me.rank} · ${me.tier}',
                  style: AppTypography.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${me.streak} day streak · ${me.xp} XP',
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: AppColors.accentGreen.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              cohortContext,
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: AppColors.accentCyan,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformersShowcase(List<LeaderboardEntry> topThree) {
    final first = topThree[0];
    final second = topThree[1];
    final third = topThree[2];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TOP PERFORMERS',
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                fontSize: 10.5,
              ),
            ),
            Text(
              'Verified Readiness',
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _buildEliteSpot(
                entry: second,
                rank: 2,
                isFirst: false,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildEliteSpot(
                entry: first,
                rank: 1,
                isFirst: true,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildEliteSpot(
                entry: third,
                rank: 3,
                isFirst: false,
              ),
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

    if (isFirst) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryNavy,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: AppColors.accentGreen.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryNavy.withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: AppColors.accentGreen.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rank 1 Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: BoxDecoration(
                color: AppColors.accentGreen,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    size: 12,
                    color: AppColors.primaryNavy,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '#1',
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      color: AppColors.primaryNavy,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Avatar
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accentGreen, width: 2),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryDark,
                child: Text(
                  initial,
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // First Name
            Text(
              firstName,
              style: AppTypography.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Readiness Score Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: AppColors.accentGreen.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                '${entry.readinessScore}% Ready',
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: AppColors.accentCyan,
                  fontWeight: FontWeight.w900,
                  fontSize: 9.5,
                ),
              ),
            ),
            const SizedBox(height: 4),

            // XP
            Text(
              '${entry.xp} XP',
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Rank 2 & 3
    final isRank2 = rank == 2;
    final badgeBg = isRank2 ? AppColors.silverLight : AppColors.bronzeLight;
    final badgeColor = isRank2 ? AppColors.textSecondary : AppColors.bronze;
    final badgeBorder = isRank2
        ? AppColors.silver.withValues(alpha: 0.5)
        : AppColors.bronze.withValues(alpha: 0.4);
    final badgeIcon =
        isRank2 ? Icons.shield_outlined : Icons.military_tech_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rank Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: badgeBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badgeIcon, size: 11, color: badgeColor),
                const SizedBox(width: 3),
                Text(
                  '#$rank',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: badgeColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Avatar
          CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.background,
            child: Text(
              initial,
              style: AppTypography.textTheme.labelMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 5),

          // First Name
          Text(
            firstName,
            style: AppTypography.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Readiness Score Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accentLight.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: AppColors.accentGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '${entry.readinessScore}% Ready',
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: AppColors.accentGreen,
                fontWeight: FontWeight.w800,
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // XP
          Text(
            '${entry.xp} XP',
            style: AppTypography.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
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
          color: entry.isCurrentUser
              ? AppColors.accentGreen
              : AppColors.border,
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
              '#${entry.rank}',
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
                color: entry.isCurrentUser
                    ? Colors.white
                    : AppColors.primaryNavy,
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
                          color: AppColors.accentGreen,
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
                Row(
                  children: [
                    Text(
                      entry.tier,
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 13,
                      color: AppColors.primaryNavy,
                    ),
                    Text(
                      '${entry.streak}d',
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: AppColors.primaryNavy,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: AppColors.accentGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 12,
                      color: AppColors.accentGreen,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${entry.readinessScore}%',
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${entry.xp} XP',
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 10.5,
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
            decoration: const BoxDecoration(
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
              fontSize: 9.5,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
