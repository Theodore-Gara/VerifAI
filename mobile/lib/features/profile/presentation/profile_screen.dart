import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
import 'package:verifai/shared/widgets/app_feedback_banner.dart';
import 'package:verifai/shared/widgets/empty_state.dart';
import 'package:verifai/shared/widgets/shimmer_loader.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Uint8List? _localProfileImage;

  Future<void> _chooseProfileImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() => _localProfileImage = bytes);
      showFeedback(
        context,
        FeedbackKind.info,
        'Photo preview updated on this device. Profile storage is not connected.',
      );
    } catch (_) {
      if (!mounted) return;
      showFeedback(
        context,
        FeedbackKind.error,
        'Could not open your photo gallery. Try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          TextButton(
            onPressed: () => _showLogoutDialog(context, ref),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Sign Out'),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: RefreshIndicator(
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
              // Hero Player Card — calm navy
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryNavy.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _chooseProfileImage,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.accentGreen.withValues(alpha: 0.6),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 42,
                          backgroundColor: AppColors.primaryDark,
                          backgroundImage: _localProfileImage == null
                              ? null
                              : MemoryImage(_localProfileImage!),
                          child: _localProfileImage == null
                              ? Text(
                                  initial,
                                  style: AppTypography.textTheme.displaySmall
                                      ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: _chooseProfileImage,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accentGreen,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Change photo'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
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
                        style: AppTypography.textTheme.headlineMedium?.copyWith(
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
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                    if (trackName != null && trackName.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        trackName.toUpperCase(),
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: AppColors.accentGreen,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Stat metrics row
              dashboardAsync.when(
                data: (progress) => _buildStatsRow(
                  ref,
                  progress.currentXp,
                  progress.streakDays,
                  leagueAsync.valueOrNull?.me.rank,
                ),
                loading: () => const Row(
                  children: [
                    Expanded(child: ShimmerLoader(height: 84)),
                    SizedBox(width: AppSpacing.md),
                    Expanded(child: ShimmerLoader(height: 84)),
                    SizedBox(width: AppSpacing.md),
                    Expanded(child: ShimmerLoader(height: 84)),
                  ],
                ),
                error: (error, _) => InlineErrorCard(
                  error: error,
                  fallbackMessage: 'We could not load your stats.',
                  onRetry: () => reconnectApp(ref),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              _buildAchievements(ref, achievementsAsync, userName),
              const SizedBox(height: AppSpacing.xl),

              Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  title: const Text(
                    'Explore another industry',
                    style: TextStyle(
                      color: AppColors.primaryNavy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: const Text(
                    'Switch learning pathways without signing out.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onTap: () => context.go('/change-industry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(WidgetRef ref, int xp, int streak, int? leagueRank) {
    return Row(
      children: [
        _statTile(
          label: 'TOTAL XP',
          value: _formatNumber(xp),
        ),
        const SizedBox(width: AppSpacing.md),
        _statTile(
          label: 'STREAK',
          value: streak == 1 ? '1 Day' : '$streak Days',
        ),
        const SizedBox(width: AppSpacing.md),
        _statTile(
          label: 'LEAGUE RANK',
          value: leagueRank == null ? '—' : '#$leagueRank',
          accent: leagueRank != null,
        ),
      ],
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    bool accent = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: accent || label == 'LEAGUE RANK'
            ? () => ref.context.push('/scoreboard')
            : null,
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
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color:
                      accent ? AppColors.accentGreen : AppColors.textSecondary,
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

  Widget _buildAchievements(WidgetRef ref,
      AsyncValue<List<Achievement>> achievementsAsync, String? userName) {
    final earnedCodes = (achievementsAsync.valueOrNull ?? const <Achievement>[])
        .map((a) => a.code)
        .toSet();
    final badges = _badgeCatalog
        .map((spec) => _Badge(
              title: spec.name,
              description: spec.description,
              isUnlocked: earnedCodes.contains(spec.code),
              color: spec.color,
            ))
        .toList();
    final unlockedCount = badges.where((b) => b.isUnlocked).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Achievements',
              style: AppTypography.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          data: (_) => _buildBadgeGrid(badges),
          loading: () => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              mainAxisExtent: 110,
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
        mainAxisExtent: 110,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) => _badgeTile(badges[index]),
    );
  }

  Widget _badgeTile(_Badge badge) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: badge.isUnlocked
            ? AppColors.surface
            : AppColors.background.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: badge.isUnlocked
              ? badge.color.withValues(alpha: 0.45)
              : AppColors.border,
          width: badge.isUnlocked ? 1.5 : 1,
          style: BorderStyle.solid,
        ),
        boxShadow: badge.isUnlocked
            ? [
                const BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: Offset(0, 2),
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
              Expanded(
                child: Text(
                  badge.title,
                  style: AppTypography.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: badge.isUnlocked
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badge.isUnlocked
                      ? badge.color
                      : AppColors.border.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            badge.description,
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: badge.isUnlocked
                  ? AppColors.textSecondary
                  : AppColors.textSecondary.withValues(alpha: 0.65),
              fontSize: 10.5,
              height: 1.3,
            ),
            maxLines: 3,
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
  final Color color;

  _Badge({
    required this.title,
    required this.description,
    required this.isUnlocked,
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
  final Color color;

  const _BadgeSpec(this.code, this.name, this.description, this.color);
}

const List<_BadgeSpec> _badgeCatalog = [
  _BadgeSpec('first-task', 'First Assessment',
      'Complete your first workplace readiness task.', AppColors.accentGreen),
  _BadgeSpec('five-tasks', 'Five in the Bag',
      'Complete five workplace readiness tasks.', AppColors.accentCyan),
  _BadgeSpec('ten-tasks', 'Consistent Practitioner',
      'Complete ten workplace readiness tasks.', AppColors.xpPurple),
  _BadgeSpec('xp-500', '500 XP', 'Earn at least 500 XP.', AppColors.gold),
  _BadgeSpec('dimension-80', 'Strong Skill',
      'Reach a score of at least 80 in one readiness skill.', AppColors.info),
];
