import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/providers/app_reconnect.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/dashboard/providers.dart';
import 'package:verifai/features/profile/presentation/admin_panel_screen.dart';
import 'package:verifai/features/profile/providers.dart';
import 'package:verifai/features/navigation/nav_drawer_controller.dart';
import 'package:verifai/features/scoreboard/providers.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/empty_state.dart';
import 'package:verifai/shared/widgets/shimmer_loader.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Uint8List? _localProfileImage;
  bool _deleting = false;

  /// Human label for the staff role badge on the profile.
  String _adminRoleLabel(String role) {
    switch (role) {
      case 'super':
        return 'SUPER ADMIN';
      case 'moderator':
        return 'MODERATOR';
      default:
        return 'ADMIN';
    }
  }

  /// Admin dashboard URL derived from the app's API base URL
  /// (.../api/ becomes .../admin/). Same backend that serves the app.
  String _adminPanelUrl() {
    const base = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://verifai-2wnm.onrender.com/api/',
    );
    final trimmed = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    return trimmed.endsWith('/api')
        ? '${trimmed.substring(0, trimmed.length - 4)}/admin/'
        : '$trimmed/admin/';
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'This permanently removes your account, your progress and your data. It cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await ref.read(apiClientProvider).deleteAccount();
      if (!mounted) return;
      await ref.read(authNotifierProvider.notifier).logout();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not delete the account. Try again.')));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Photo preview updated on this device. Profile storage is not connected.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open your photo gallery. Try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
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
    final adminRole = ref.watch(adminIdentityProvider).valueOrNull?.role;

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
          'Profile',
          style: AppTypography.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Account & privacy',
            onPressed: _deleting ? null : () => _showAccountOptions(context),
            icon: _deleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.manage_accounts_rounded,
                    color: AppColors.accentGreen,
                  ),
          ),
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
                color: AppColors.ambientCyan,
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
                              child: GestureDetector(
                                onTap: _chooseProfileImage,
                                child: CircleAvatar(
                                  radius: 42,
                                  backgroundColor: AppColors.primaryNavy,
                                  backgroundImage: _localProfileImage == null
                                      ? null
                                      : MemoryImage(_localProfileImage!),
                                  child: _localProfileImage == null
                                      ? Text(
                                          initial,
                                          style: AppTypography
                                              .textTheme.displaySmall
                                              ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        )
                                      : null,
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
                              child: const Icon(Icons.camera_alt_rounded,
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
                          Text(
                            trackName,
                            textAlign: TextAlign.center,
                            style:
                                AppTypography.textTheme.labelMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                        if (adminRole != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35)),
                            ),
                            child: Text(
                              _adminRoleLabel(adminRole),
                              style: AppTypography.textTheme.labelSmall
                                  ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Staff entry point: opens the admin dashboard in an in-app
                  // browser view. Hidden for regular learners.
                  if (adminRole != null) ...[
                    Material(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.35)),
                        ),
                        leading: const Icon(Icons.admin_panel_settings,
                            color: Colors.white),
                        title: const Text(
                          'Open Admin Panel',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          'Task approvals, users, analytics',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75)),
                        ),
                        trailing: const Icon(Icons.chevron_right,
                            color: Colors.white),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => AdminPanelScreen(
                                panelUrl: _adminPanelUrl()),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

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

                  _buildAchievements(ref, achievementsAsync),
                  const SizedBox(height: AppSpacing.xl),
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
          value: leagueRank == null ? '—' : '$leagueRank',
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
            Text(
              'Achievements',
              style: AppTypography.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: AppColors.textPrimary,
              ),
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

  void _showAccountOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.modal),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account & privacy',
                style: AppTypography.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Manage your account and personal data.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.swap_horiz_rounded,
                  color: AppColors.accentGreen,
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
                onTap: () {
                  Navigator.pop(sheetContext);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) context.go('/change-industry');
                  });
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.delete_forever_outlined,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Delete account',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: const Text(
                  'Permanently remove your account and data.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _deleteAccount();
                  });
                },
              ),
            ],
          ),
        ),
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
