import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/shared/widgets/sample_data_banner.dart';

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    final leaderboardUsers = [
      _LeaderboardEntry(
          rank: 1,
          name: 'Elena Rostova',
          xp: 4850,
          streak: 24,
          track: 'Finance',
          isCurrentUser: false),
      _LeaderboardEntry(
          rank: 2,
          name: 'Marcus Chen',
          xp: 4210,
          streak: 18,
          track: 'IT / Software',
          isCurrentUser: false),
      _LeaderboardEntry(
          rank: 3,
          name: 'Sarah Jenkins',
          xp: 3980,
          streak: 14,
          track: 'Legal',
          isCurrentUser: false),
      _LeaderboardEntry(
          rank: 4,
          name: 'David Kim',
          xp: 3450,
          streak: 11,
          track: 'Finance',
          isCurrentUser: false),
      _LeaderboardEntry(
          rank: 5,
          name: 'Amina Al-Sayed',
          xp: 3120,
          streak: 9,
          track: 'Consulting',
          isCurrentUser: false),
      _LeaderboardEntry(
          rank: 6,
          name: 'Lucas Meyer',
          xp: 2890,
          streak: 8,
          track: 'IT / Software',
          isCurrentUser: false),
      _LeaderboardEntry(
          rank: 7,
          name: 'Priya Sharma',
          xp: 2750,
          streak: 12,
          track: 'Finance',
          isCurrentUser: false),
      _LeaderboardEntry(
        rank: 8,
        name: user?.name ?? 'You',
        xp: 2450,
        streak: 7,
        track: user?.trackName ?? 'Finance',
        isCurrentUser: true,
      ),
      _LeaderboardEntry(
          rank: 9,
          name: 'Thomas Wright',
          xp: 2100,
          streak: 5,
          track: 'Legal',
          isCurrentUser: false),
      _LeaderboardEntry(
          rank: 10,
          name: 'Chloe Dubois',
          xp: 1980,
          streak: 6,
          track: 'Consulting',
          isCurrentUser: false),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Scoreboard'),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.screenPadding),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.goldLight,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.4), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_rounded,
                    size: 14, color: AppColors.goldDark),
                const SizedBox(width: 4),
                Text(
                  'TOP 10 ADVANCE',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.goldDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
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

          // Entire Scoreboard is smoothly scrollable together (non-sticky)
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.xs,
              AppSpacing.screenPadding,
              100, // accommodates floating dock
            ),
            child: Column(
              children: [
                const SampleDataBanner(
                  message:
                      'Preview leaderboard with sample data. Rankings, XP and the league reset timer are not live yet.',
                ),
                const SizedBox(height: AppSpacing.sm),

                // Division League Banner
                Container(
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
                              'EMERALD LEAGUE • TIER 1',
                              style:
                                  AppTypography.textTheme.labelSmall?.copyWith(
                                color: AppColors.accentCyan,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Text(
                              'Weekly reset in 2d 14h',
                              style:
                                  AppTypography.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white, size: 12),
                    ],
                  ),
                ),
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
                      Tab(text: 'Global League'),
                      Tab(text: 'Industry Track'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Top 3 Modern Podium
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 2nd Place (Silver)
                    _buildPodiumSpot(
                      entry: leaderboardUsers[1],
                      place: 2,
                      color: AppColors.silver,
                      height: 92,
                      crownIcon: Icons.military_tech_rounded,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // 1st Place (Gold)
                    _buildPodiumSpot(
                      entry: leaderboardUsers[0],
                      place: 1,
                      color: AppColors.gold,
                      height: 124,
                      crownIcon: Icons.emoji_events_rounded,
                      isFirst: true,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // 3rd Place (Bronze)
                    _buildPodiumSpot(
                      entry: leaderboardUsers[2],
                      place: 3,
                      color: AppColors.bronze,
                      height: 76,
                      crownIcon: Icons.workspace_premium_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Leaderboard List
                ...leaderboardUsers
                    .sublist(3)
                    .map((entry) => _buildLeaderboardTile(entry)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumSpot({
    required _LeaderboardEntry entry,
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

  Widget _buildLeaderboardTile(_LeaderboardEntry entry) {
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
                    Text(
                      entry.name,
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        fontWeight: entry.isCurrentUser
                            ? FontWeight.w800
                            : FontWeight.w700,
                        color: AppColors.textPrimary,
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
                      entry.track,
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
}

class _LeaderboardEntry {
  final int rank;
  final String name;
  final int xp;
  final int streak;
  final String track;
  final bool isCurrentUser;

  _LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.xp,
    required this.streak,
    required this.track,
    required this.isCurrentUser,
  });
}
