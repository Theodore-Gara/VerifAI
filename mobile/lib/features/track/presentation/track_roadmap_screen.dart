import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/providers/app_reconnect.dart';
import 'package:verifai/core/providers/track_scope.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/dashboard/providers.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/dock_clearance.dart';
import 'package:verifai/shared/widgets/verifai_page_scaffold.dart';
import 'package:verifai/shared/widgets.dart';

/// Skill roadmap: where the learner stands in their industry track.
///
/// Milestones were removed — they duplicated the achievements catalog and the
/// readiness ring with a third, weaker progress story. The screen now leads
/// with the readiness score and the per-dimension breakdown that actually
/// drive it, plus where to practise next.
class TrackRoadmapScreen extends ConsumerWidget {
  const TrackRoadmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final trackName = user?.trackName ?? 'Your track';
    // trackRevision re-keys this watch so a track change re-fetches instead of
    // showing the previous industry's scores.
    ref.watch(trackRevisionProvider);
    final dashboardAsync = ref.watch(dashboardProvider);

    return VerifaiPageScaffold(
      title: 'Skill roadmap',
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardProvider);
          try {
            await ref.read(dashboardProvider.future);
          } on Object {
            // Rendered by the error branch below.
          }
        },
        child: dashboardAsync.when(
          data: (data) => _buildContent(context, trackName, data),
          loading: () => _buildShimmer(),
          error: (error, stackTrace) => AsyncErrorView(
            error: error,
            fallbackMessage: 'Failed to load your roadmap. Pull to refresh.',
            onRetry: () => reconnectApp(ref),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, String trackName, DashboardData data) {
    final dimensions = data.dimensionScores;
    final dimensionNames = dimensions.keys.toList()..sort();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        dockClearance(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Track hero banner.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryNavy, AppColors.primaryFill],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryNavy.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SPECIALIZATION PATH',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.accentCyan,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  trackName,
                  style: AppTypography.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Readiness grows as you verify, judge and govern AI in your '
                  'industry. Every graded task moves it.',
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          Text(
            'Your skills',
            style: AppTypography.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (dimensions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Run your first task and your skill scores will appear here.',
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            for (final name in dimensionNames) ...[
              _dimensionRow(name, dimensions[name] ?? 0),
              const SizedBox(height: AppSpacing.sm),
            ],

          const SizedBox(height: AppSpacing.xl),
          Text(
            'Where to next',
            style: AppTypography.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: VerifAIButton(
                  label: 'Practise a task',
                  onPressed: () => context.push('/practice'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: VerifAIButton(
                  label: 'Learn a lesson',
                  variant: VerifAIButtonVariant.secondary,
                  onPressed: () => context.push('/learn'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dimensionRow(String name, int score) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dimensionLabel(name),
                  style: AppTypography.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: SizedBox(
                    height: 8,
                    child: Stack(
                      children: [
                        Container(color: AppColors.background),
                        FractionallySizedBox(
                          widthFactor: (score.clamp(0, 100)) / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.accentGreen,
                                  AppColors.accentCyan,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '$score',
            style: AppTypography.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.primaryNavy,
            ),
          ),
        ],
      ),
    );
  }

  String _dimensionLabel(String key) {
    final cleaned = key
        .replaceAll('_', ' ')
        .trim();
    if (cleaned.isEmpty) return 'Skill';
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: const [
        ShimmerLoader(height: 140),
        SizedBox(height: AppSpacing.xl),
        ShimmerLoader(height: 24, width: 200),
        SizedBox(height: AppSpacing.md),
        ShimmerLoader(height: 72),
        SizedBox(height: AppSpacing.sm),
        ShimmerLoader(height: 72),
      ],
    );
  }
}