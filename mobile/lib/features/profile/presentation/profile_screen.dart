import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/shared/widgets/verifai_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    final badges = [
      _Badge(title: 'Prompt Ninja', description: 'Crafted 10 optimal prompts', isUnlocked: true, icon: Icons.bolt_rounded, color: AppColors.xpPurple),
      _Badge(title: 'Streak Titan', description: 'Maintained a 7-day streak', isUnlocked: true, icon: Icons.local_fire_department_rounded, color: AppColors.gold),
      _Badge(title: 'Bug Hunter', description: 'Found 15 subtle hallucinations', isUnlocked: true, icon: Icons.bug_report_rounded, color: AppColors.accentGreen),
      _Badge(title: 'Risk Guardian', description: 'Solved 5 high-risk scenarios', isUnlocked: false, icon: Icons.security_rounded, color: AppColors.info),
      _Badge(title: 'AI Maestro', description: 'Reach 85+ Overall Score', isUnlocked: false, icon: Icons.military_tech_rounded, color: AppColors.accentCyan),
      _Badge(title: 'Class Master', description: 'Complete your Industry Track', isUnlocked: false, icon: Icons.school_rounded, color: AppColors.warning),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Profile'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            onPressed: () => _showLogoutDialog(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          children: [
            // Player Card
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
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primaryNavy,
                        child: Text(
                          (user?.name?.isNotEmpty == true) ? user!.name![0].toUpperCase() : 'U',
                          style: AppTypography.textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.accentGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_rounded, size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    user?.name ?? 'Alex Mercer',
                    style: AppTypography.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    user?.email ?? 'alex.mercer@company.com',
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(AppRadius.xxl),
                    ),
                    child: Text(
                      user?.trackName ?? 'Finance Track Specialist',
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Stat Summary Cards
            Row(
              children: [
                _buildStatBox(label: 'Total XP', value: '2,450', icon: Icons.bolt_rounded, color: AppColors.xpPurple),
                const SizedBox(width: AppSpacing.md),
                _buildStatBox(label: 'Streak', value: '7 Days', icon: Icons.local_fire_department_rounded, color: AppColors.goldDark),
                const SizedBox(width: AppSpacing.md),
                _buildStatBox(label: 'Global Rank', value: '#8', icon: Icons.emoji_events_rounded, color: AppColors.accentGreen),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Badges & Achievements Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Achievements & Trophies',
                  style: AppTypography.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '3 / 6 Unlocked',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                mainAxisExtent: 130,
              ),
              itemCount: badges.length,
              itemBuilder: (context, index) {
                final badge = badges[index];
                return _buildBadgeTile(badge);
              },
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Switch Track button
            VerifAIButton(
              label: 'Change Industry Track',
              variant: VerifAIButtonVariant.secondary,
              leadingIcon: Icons.alt_route_rounded,
              onPressed: () => context.go('/industry-select'),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox({required String label, required String value, required IconData icon, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeTile(_Badge badge) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: badge.isUnlocked ? AppColors.surface : AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: badge.isUnlocked ? badge.color.withValues(alpha: 0.4) : AppColors.border,
          width: badge.isUnlocked ? 1.5 : 1,
        ),
        boxShadow: badge.isUnlocked
            ? [
                BoxShadow(
                  color: badge.color.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: badge.isUnlocked ? badge.color.withValues(alpha: 0.15) : AppColors.border.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  badge.isUnlocked ? badge.icon : Icons.lock_rounded,
                  size: 18,
                  color: badge.isUnlocked ? badge.color : AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (badge.isUnlocked)
                const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.accentGreen),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            badge.title,
            style: AppTypography.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: badge.isUnlocked ? AppColors.textPrimary : AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            badge.description,
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
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
        title: const Text('Sign Out'),
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
            child: const Text('Log Out', style: TextStyle(color: AppColors.error)),
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
