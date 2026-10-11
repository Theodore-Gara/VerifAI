import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:verifai/core/providers/app_reconnect.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/dashboard/providers.dart';
import 'package:verifai/features/profile/providers.dart';
import 'package:verifai/features/scoreboard/providers.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/empty_state.dart';
import 'package:verifai/shared/widgets/shimmer_loader.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final dashboardAsync = ref.watch(dashboardProvider);
    // Achievements earned by this user (GET /api/achievements/me). The full
    // catalog is known to the app, so locked ones can be shown too
    final achievementsAsync = ref.watch(achievementsProvider);
    final leagueAsync = ref.watch(leaderboardProvider(null));

    final userName = (user?.name?.isNotEmpty == true) ? user!.name! : null;
    final displayName = userName ?? user?.email ?? '';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final trackName = user?.trackName;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile',
          style: AppTypography.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: AppColors.error, size: 22),
            tooltip: 'Sign Out',
            onPressed: () => _showLogoutDialog(context, ref),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Stack(
        children: [
          // Ambient Mesh Glows
          Positioned(
            top: -50,
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
                color: AppColors.ambientCyan,
              ),
            ),
          ),
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardProvider);
              ref.invalidate(achievementsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.sm,
                AppSpacing.screenPadding,
                100, // accommodate floating navigation dock
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modern Hero Player Bento Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryNavy.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                        const BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar with glowing gradient halo
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primaryNavy,
                                    AppColors.accentGreen
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accentCyan
                                        .withValues(alpha: 0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 42,
                                backgroundColor: AppColors.primaryNavy,
                                child: Text(
                                  initial,
                                  style: AppTypography.textTheme.displaySmall
                                      ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: AppColors.accentGreen,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.surface, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accentGreen
                                        .withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.verified_rounded,
                                  size: 14, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (user == null) ...[
                          // Profile still loading: placeholders instead of
                          // made-up identity text.
                          ShimmerLoader(
                            width: 160,
                            height: 26,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          const SizedBox(height: 6),
                          ShimmerLoader(
                            width: 200,
                            height: 14,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ] else ...[
                          Text(
                            displayName,
                            style: AppTypography.textTheme.headlineMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (userName != null && user.email.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              user.email,
                              style:
                                  AppTypography.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                        if (trackName != null && trackName.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.accentGreen.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                  color: AppColors.accentGreen
                                      .withValues(alpha: 0.45)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.workspace_premium_rounded,
                                    size: 14, color: AppColors.accentGreen),
                                const SizedBox(width: 6),
                                Text(
                                  trackName,
                                  style: AppTypography.textTheme.labelSmall
                                      ?.copyWith(
                                    color: AppColors.accentGreen,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Bento Stat Metrics Row
                  dashboardAsync.when(
                    data: (progress) => _buildStatsRow(
                      ref,
                      progress.currentXp,
                      progress.streakDays,
                      leagueAsync.valueOrNull?.me.rank,
                    ),
                    loading: () => const Row(
                      children: [
                        Expanded(child: ShimmerLoader(height: 96)),
                        SizedBox(width: AppSpacing.md),
                        Expanded(child: ShimmerLoader(height: 96)),
                        SizedBox(width: AppSpacing.md),
                        Expanded(child: ShimmerLoader(height: 96)),
                      ],
                    ),
                    error: (error, _) => InlineErrorCard(
                      error: error,
                      fallbackMessage: 'We could not load your stats.',
                      onRetry: () => reconnectApp(ref),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _buildAchievements(ref, achievementsAsync),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(WidgetRef ref, int xp, int streak, int? leagueRank) {
    return Row(
      children: [
        _buildBentoStat(
          label: 'TOTAL XP',
          value: _formatNumber(xp),
          icon: Icons.bolt_rounded,
          iconColor: AppColors.xpPurple,
          bgColor: AppColors.xpPurpleLight.withValues(alpha: 0.5),
        ),
        const SizedBox(width: AppSpacing.md),
        _buildBentoStat(
          label: 'STREAK',
          value: '$streak Days',
          icon: Icons.local_fire_department_rounded,
          iconColor: AppColors.primaryNavy,
          bgColor: AppColors.background,
        ),
        const SizedBox(width: AppSpacing.md),
        _buildBentoStat(
          label: 'LEAGUE RANK',
          value: leagueRank == null ? '—' : '#$leagueRank',
          icon: Icons.emoji_events_rounded,
          iconColor: AppColors.accentGreen,
          bgColor: AppColors.accentLight,
          onTap: () => ref.context.push('/scoreboard'),
        ),
      ],
    );
  }

  Widget _buildAchievements(
      WidgetRef ref, AsyncValue<List<Achievement>> achievementsAsync) {
    final earnedCodes = (achievementsAsync.valueOrNull ?? const <Achievement>[])
        .map((a) => a.code)
        .toSet();
    final badges = _badgeCatalog
        .map((spec) => _Badge(
              title: spec.name,
              description: spec.description,
              isUnlocked: earnedCodes.contains(spec.code),
              icon: spec.icon,
              color: spec.color,
            ))
        .toList();
    final unlockedCount = badges.where((b) => b.isUnlocked).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badges & Achievements Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Achievements',
                  style: AppTypography.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.xpPurpleLight,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'TROPHIES',
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.xpPurple,
                    ),
                  ),
                ),
              ],
            ),
            if (achievementsAsync.hasValue)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '$unlockedCount / ${_badgeCatalog.length} Unlocked',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        achievementsAsync.when(
          // Grid of modern Bento Badges
          data: (_) => _buildBadgeGrid(badges),
          loading: () => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              mainAxisExtent: 136,
            ),
            itemCount: 4,
            itemBuilder: (context, index) => const ShimmerLoader.card(),
          ),
          error: (error, _) => InlineErrorCard(
            error: error,
            fallbackMessage: 'We could not load your achievements.',
            onRetry: () => reconnectApp(ref),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeGrid(List<_Badge> badges) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        mainAxisExtent: 136,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) => _buildModernBadgeTile(badges[index]),
    );
  }

  Widget _buildBentoStat({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md, horizontal: AppSpacing.sm),
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
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernBadgeTile(_Badge badge) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: badge.isUnlocked
            ? AppColors.surface
            : const Color(0xFFF1F5F9).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: badge.isUnlocked
              ? badge.color.withValues(alpha: 0.35)
              : AppColors.border.withValues(alpha: 0.8),
          width: badge.isUnlocked ? 1.5 : 1,
        ),
        boxShadow: badge.isUnlocked
            ? [
                BoxShadow(
                  color: badge.color.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: badge.isUnlocked
                      ? badge.color.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  badge.isUnlocked ? badge.icon : Icons.lock_outline_rounded,
                  size: 18,
                  color: badge.isUnlocked
                      ? badge.color
                      : AppColors.textSecondary.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              if (badge.isUnlocked)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.accentLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 12, color: AppColors.accentGreen),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            badge.title,
            style: AppTypography.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: badge.isUnlocked
                  ? AppColors.textPrimary
                  : AppColors.textSecondary.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            badge.description,
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.8),
              fontSize: 10.5,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatNumber(int value) => value.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (m) => '${m[1]},',
      );

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.modal)),
        title: Text(
          'Sign Out',
          style: AppTypography.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        content: const Text('Are you sure you want to log out of VerifAI?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(authNotifierProvider.notifier).logout();
            },
            child: const Text('Log Out',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _Badge {
  final String title;
  final String description;
  final bool isUnlocked;
  final IconData icon;
  final Color color;

  _Badge({
    required this.title,
    required this.description,
    required this.isUnlocked,
    required this.icon,
    required this.color,
  });
}

/// Known achievement catalog, mirroring the backend `achievements` seed.
/// `GET /api/achievements/me` returns only earned rows, so the catalog lives
/// here to render the locked state as well.
class _BadgeSpec {
  final String code;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const _BadgeSpec(
      this.code, this.name, this.description, this.icon, this.color);
}

const List<_BadgeSpec> _badgeCatalog = [
  _BadgeSpec(
      'first-task',
      'First Assessment',
      'Complete your first workplace readiness task.',
      Icons.flag_rounded,
      AppColors.accentGreen),
  _BadgeSpec(
      'five-tasks',
      'Five in the Bag',
      'Complete five workplace readiness tasks.',
      Icons.checklist_rounded,
      AppColors.accentCyan),
  _BadgeSpec(
      'ten-tasks',
      'Consistent Practitioner',
      'Complete ten workplace readiness tasks.',
      Icons.military_tech_rounded,
      AppColors.xpPurple),
  _BadgeSpec('xp-500', '500 XP', 'Earn at least 500 XP.', Icons.bolt_rounded,
      AppColors.gold),
  _BadgeSpec(
      'dimension-80',
      'Strong Skill',
      'Reach a score of at least 80 in one readiness skill.',
      Icons.workspace_premium_rounded,
      AppColors.info),
];
