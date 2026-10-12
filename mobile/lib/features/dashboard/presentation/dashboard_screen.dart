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
import 'package:verifai/shared/widgets/pref_row.dart';
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
      body: RefreshIndicator(
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
          // Hero Score Card — calm, typography-led
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
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This score reflects how consistently you verify AI output across the assessed skills.',
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                          fontSize: 12,
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
                  accent: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          _buildQuickLaunches(context),
        ],
      ),
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

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        ShimmerLoader(
          height: 54,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        const SizedBox(height: AppSpacing.md),
        const ShimmerLoader.card(height: 160),
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
        const ShimmerLoader.card(height: 300),
      ],
    );
  }

  Widget _buildQuickLaunches(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore VerifAI',
          style: AppTypography.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Build confidence. Verify before you rely.',
          style: AppTypography.textTheme.bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),

        // Core studio row
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: PrefRow(
            title: 'Verification Studio',
            subtitle:
                'Inspect documents, claims, AI output and sources, with uncertainty made visible.',
            showChevron: true,
            accentBorder: true,
            onTap: () => context.push('/verification-studio'),
          ),
        ),

        // Secondary tools
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: PrefRow(
            title: 'AI Assistant',
            subtitle: 'Your thinking partner for tricky claims',
            showChevron: true,
            onTap: () => context.push('/assistant'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: PrefRow(
            title: 'AI Lab',
            subtitle: 'Short interactive workshops on responsible AI',
            showChevron: true,
            onTap: () => context.push('/ai-lab'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: PrefRow(
            title: 'Practice',
            subtitle: 'Real-world scenarios across your industry',
            showChevron: true,
            onTap: () => context.push('/industry-practice'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: PrefRow(
            title: 'Rewards',
            subtitle: 'XP, milestones and feel-good goals',
            showChevron: true,
            onTap: () => context.push('/rewards'),
          ),
        ),
        PrefRow(
          title: 'Task History',
          subtitle: 'Review past attempts and track your consistency',
          showChevron: true,
          onTap: () => context.push('/task-history'),
        ),
      ],
    );
  }
}
