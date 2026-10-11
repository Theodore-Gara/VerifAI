import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/scoreboard/providers.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/empty_state.dart';
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
    final scope = _scopeTrackId();
    final boardAsync = ref.watch(leaderboardProvider(scope));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Scoreboard'),
        centerTitle: false,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.screenPadding),
            child: Center(child: _Pill(label: 'LIVE RANKING')),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Ambient Mesh Glows
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.ambientGold,
              ),
            ),
          ),
          Positioned(
            top: 280,
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
                data: (data) => _buildBoard(data),
                loading: () => _buildShimmer(),
                error: (error, _) => AsyncErrorView(
                  error: error,
                  fallbackMessage: 'Failed to load the leaderboard.',
                  onRetry: () => ref.invalidate(leaderboardProvider),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard(LeaderboardData data) {
    final entries = data.entries;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.xs,
        AppSpacing.screenPadding,
        100, // accommodates floating dock
      ),
      child: Column(
        children: [
          // Your standing
          _buildStandingBanner(data.me),
          const SizedBox(height: AppSpacing.sm),

          // Tabs (Global vs Track)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.border),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.primaryNavy,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTypography.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
              tabs: const [
                Tab(text: 'Global'),
                Tab(text: 'Industry Track'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (entries.isEmpty)
            const EmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'No rankings yet',
              message:
                  'Be the first to earn XP in this board. Rankings appear once users start completing tasks.',
            )
          else ...[
            if (entries.length >= 3)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPodiumSpot(
                    entry: entries[1],
                    place: 2,
                    color: AppColors.silver,
                    height: 92,
                    crownIcon: Icons.military_tech_rounded,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _buildPodiumSpot(
                    entry: entries[0],
                    place: 1,
                    color: AppColors.gold,
                    height: 124,
                    crownIcon: Icons.emoji_events_rounded,
                    isFirst: true,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _buildPodiumSpot(
                    entry: entries[2],
                    place: 3,
                    color: AppColors.bronze,
                    height: 76,
                    crownIcon: Icons.workspace_premium_rounded,
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.md),
            ...entries
                .skip(entries.length >= 3 ? 3 : 0)
                .map(_buildLeaderboardTile),
          ],
        ],
      ),
    );
  }

  Widget _buildStandingBanner(LeaderboardEntry me) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryNavy, Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: AppColors.accentCyan, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR STANDING',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.accentCyan,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  'Rank #${me.rank} · ${me.tier} · ${me.xp} XP',
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumSpot({
    required LeaderboardEntry entry,
    required int place,
    required Color color,
    required double height,
    required IconData crownIcon,
    bool isFirst = false,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(crownIcon, color: color, size: isFirst ? 26 : 20),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: isFirst ? 2 : 1.5),
              boxShadow: isFirst
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: CircleAvatar(
              radius: isFirst ? 22 : 18,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Text(
                entry.name.substring(0, 1),
                style: AppTypography.textTheme.labelLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.name.split(' ')[0],
            style: AppTypography.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.xpPurpleLight,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '${entry.xp} XP',
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: AppColors.xpPurple,
                fontWeight: FontWeight.w800,
                fontSize: 9.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.22),
                  color.withValues(alpha: 0.06),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.lg),
                topRight: Radius.circular(AppRadius.lg),
              ),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Center(
              child: Text(
                '#$place',
                style: AppTypography.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTile(LeaderboardEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? AppColors.accentLight.withValues(alpha: 0.6)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: entry.isCurrentUser ? AppColors.accentGreen : AppColors.border,
          width: entry.isCurrentUser ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#${entry.rank}',
              style: AppTypography.textTheme.labelLarge?.copyWith(
                color: entry.isCurrentUser
                    ? AppColors.accentGreen
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor:
                entry.isCurrentUser ? AppColors.accentGreen : AppColors.border,
            child: Text(
              entry.name.substring(0, 1),
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color:
                    entry.isCurrentUser ? Colors.white : AppColors.textPrimary,
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
                            horizontal: 6, vertical: 1.5),
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
                Row(
                  children: [
                    Text(
                      entry.tier,
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.local_fire_department_rounded,
                        size: 13, color: AppColors.goldDark),
                    Text(
                      '${entry.streak}d',
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: AppColors.goldDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${entry.xp} XP',
            style: AppTypography.textTheme.labelLarge?.copyWith(
              color: AppColors.xpPurple,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: const [
        ShimmerLoader(height: 54),
        SizedBox(height: AppSpacing.md),
        ShimmerLoader(height: 44),
        SizedBox(height: AppSpacing.md),
        ShimmerLoader.card(height: 200),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.goldLight,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_rounded,
              size: 14, color: AppColors.goldDark),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.textTheme.labelSmall?.copyWith(
              color: AppColors.goldDark,
              fontWeight: FontWeight.w800,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}
