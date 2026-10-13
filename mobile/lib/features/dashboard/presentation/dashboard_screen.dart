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
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryNavy,
              child: Text(
                (user?.name?.isNotEmpty == true)
                    ? user!.name![0].toUpperCase()
                    : 'U',
                style: AppTypography.textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Home',
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  user?.trackName ?? 'Specialization Active',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () => ref.invalidate(dashboardProvider),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Modern Ambient Background Glows
          Positioned(
            top: -60,
            right: -40,
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
            top: 240,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.ambientGreen,
              ),
            ),
          ),

          // Main Scrollable Content
          RefreshIndicator(
            onRefresh: () async => ref.invalidate(dashboardProvider),
            child: dashboardAsync.when(
              data: (data) => _buildDashboard(data, user),
              loading: () => _buildShimmer(),
              error: (error, stackTrace) => AsyncErrorView(
                error: error,
                fallbackMessage: 'Failed to load dashboard. Pull to refresh.',
                onRetry: () => reconnectApp(ref),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(DashboardData data, User? user) {
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
          // Hero Score Bento Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryNavy.withValues(alpha: 0.05),
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
                ScoreRing(
                  score: data.overallScore,
                  size: 116,
                  strokeWidth: 11,
                  tierLabel: data.tier,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI readiness score',
                        style: AppTypography.textTheme.titleMedium?.copyWith(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'This score reflects how consistently you verify AI output across the assessed skills.',
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Duo Metric Row — quiet stat tiles, no icons
          Row(
            children: [
              Expanded(
                child: _statTile(
                  value: '${data.streakDays} Days',
                  label: 'Streak Active',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _statTile(
                  value: '${data.completedTasks} Tasks',
                  label: 'Completed',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildQuickLaunches(context),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        ShimmerLoader(
          height: 54,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        const SizedBox(height: AppSpacing.md),
        const ShimmerLoader.card(height: 120),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: ShimmerLoader(
                height: 70,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ShimmerLoader(
                height: 70,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const ShimmerLoader.card(height: 200),
      ],
    );
  }

  Widget _statTile({
    required String value,
    required String label,
    bool accent = false,
  }) {
    return Container(
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
    );
  }

  Widget _buildQuickLaunches(BuildContext context) {
    final gridItems =
        <({String title, String subtitle, IconData icon, String route})>[
      (
        title: 'AI Assistant',
        subtitle: 'Thinking partner',
        icon: Icons.auto_awesome_rounded,
        route: '/assistant',
      ),
      (
        title: 'AI Lab',
        subtitle: 'Learn by doing',
        icon: Icons.science_rounded,
        route: '/ai-lab',
      ),
      (
        title: 'Practice',
        subtitle: 'Real scenarios',
        icon: Icons.psychology_alt_rounded,
        route: '/industry-practice',
      ),
      (
        title: 'Rewards',
        subtitle: 'XP & milestones',
        icon: Icons.workspace_premium_rounded,
        route: '/rewards',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore VerifAI',
          style: AppTypography.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Build confidence. Verify before you rely.',
          style: AppTypography.textTheme.bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),

        // Featured Hero Bento Card: Verification Studio
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: () => context.push('/verification-studio'),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md + 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: AppColors.primaryNavy.withValues(alpha: 0.18),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verification Studio',
                              style:
                                  AppTypography.textTheme.titleMedium?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryNavy,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Interactive sandbox to inspect documents, claims, AI output & sources.',
                              style:
                                  AppTypography.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Supported artifact chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      'Document',
                      'Claim',
                      'AI Output',
                      'Sources',
                    ].map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          tag,
                          style: AppTypography.textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 9.5,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 11),

        // 2x2 Bento Grid for Secondary Tools
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: gridItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 11,
            mainAxisSpacing: 11,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (context, index) {
            final item = gridItems[index];
            return Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.card),
                onTap: () => context.push(item.route),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              item.icon,
                              color: AppColors.primaryNavy,
                              size: 18,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_outward_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            item.subtitle,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 5),

        // Task History Strip
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: () => context.push('/task-history'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 6,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      size: 18,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Task History',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Review past attempts and track your consistency',
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: AppColors.primaryNavy,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
