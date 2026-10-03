import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/auth/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    final badges = [
      _Badge(
          title: 'Prompt Ninja',
          description: 'Crafted 10 optimal prompts',
          isUnlocked: true,
          icon: Icons.bolt_rounded,
          color: AppColors.xpPurple),
      _Badge(
          title: 'Streak Titan',
          description: 'Maintained a 7-day streak',
          isUnlocked: true,
          icon: Icons.local_fire_department_rounded,
          color: AppColors.gold),
      _Badge(
          title: 'Bug Hunter',
          description: 'Found 15 subtle hallucinations',
          isUnlocked: true,
          icon: Icons.bug_report_rounded,
          color: AppColors.accentGreen),
      _Badge(
          title: 'Risk Guardian',
          description: 'Solved 5 high-risk scenarios',
          isUnlocked: false,
          icon: Icons.security_rounded,
          color: AppColors.info),
      _Badge(
          title: 'AI Maestro',
          description: 'Reach 85+ Overall Score',
          isUnlocked: false,
          icon: Icons.military_tech_rounded,
          color: AppColors.accentCyan),
      _Badge(
          title: 'Class Master',
          description: 'Complete your Industry Track',
          isUnlocked: false,
          icon: Icons.school_rounded,
          color: AppColors.warning),
    ];

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
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.screenPadding),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded,
                  color: AppColors.error, size: 20),
              tooltip: 'Sign Out',
              onPressed: () => _showLogoutDialog(context, ref),
            ),
          ),
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
          SingleChildScrollView(
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
                                (user?.name?.isNotEmpty == true)
                                    ? user!.name![0].toUpperCase()
                                    : 'U',
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
                      Text(
                        user?.name ?? 'Alex Mercer',
                        style: AppTypography.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? 'alex.mercer@company.com',
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
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
                              user?.trackName ?? 'Finance Track Specialist',
                              style:
                                  AppTypography.textTheme.labelSmall?.copyWith(
                                color: AppColors.accentGreen,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Bento Stat Metrics Row
                Row(
                  children: [
                    _buildBentoStat(
                      label: 'TOTAL XP',
                      value: '2,450',
                      icon: Icons.bolt_rounded,
                      iconColor: AppColors.xpPurple,
                      bgColor: AppColors.xpPurpleLight.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _buildBentoStat(
                      label: 'STREAK',
                      value: '7 Days',
                      icon: Icons.local_fire_department_rounded,
                      iconColor: AppColors.goldDark,
                      bgColor: AppColors.goldLight,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _buildBentoStat(
                      label: 'LEAGUE RANK',
                      value: '#8',
                      icon: Icons.emoji_events_rounded,
                      iconColor: AppColors.accentGreen,
                      bgColor: AppColors.accentLight,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Badges & Achievements Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Achievements',
                          style:
                              AppTypography.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        '3 / 6 Unlocked',
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Grid of modern Bento Badges
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    mainAxisExtent: 136,
                  ),
                  itemCount: badges.length,
                  itemBuilder: (context, index) {
                    final badge = badges[index];
                    return _buildModernBadgeTile(badge);
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                // Account status
                Container(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primaryNavy.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Icon(Icons.alt_route_rounded,
                                size: 20, color: AppColors.primaryNavy),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Account status',
                                  style: AppTypography.textTheme.titleSmall
                                      ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Your profile and readiness data are synced.',
                                  style: AppTypography.textTheme.bodySmall
                                      ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.verified_rounded,
                                size: 18, color: AppColors.accentGreen),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Verified profile',
                              style:
                                  AppTypography.textTheme.labelLarge?.copyWith(
                                color: AppColors.accentGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoStat({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Expanded(
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
