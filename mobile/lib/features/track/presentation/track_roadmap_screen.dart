import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/track/providers.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/empty_state.dart';
import 'package:verifai/shared/widgets/shimmer_loader.dart';

enum MilestoneStatus { completed, active, locked }

class TrackRoadmapScreen extends ConsumerWidget {
  const TrackRoadmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final trackName = user?.trackName ?? 'Your track';
    final milestonesAsync = ref.watch(milestonesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Track Roadmap'),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.screenPadding),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded,
                    size: 14, color: AppColors.accentGreen),
                const SizedBox(width: 4),
                Text(
                  'YOUR JOURNEY',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(milestonesProvider),
        child: milestonesAsync.when(
          data: (milestones) => _buildContent(trackName, milestones),
          loading: () => _buildShimmer(),
          error: (error, stackTrace) => AsyncErrorView(
            error: error,
            fallbackMessage: 'Failed to load your track milestones.',
            onRetry: () => ref.invalidate(milestonesProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(String trackName, List<Milestone> milestones) {
    final achieved = milestones.where((m) => m.achieved).length;
    final progress =
        milestones.isEmpty ? 0.0 : achieved / milestones.length;

    // First not-yet-achieved milestone is the active one; the rest are locked.
    final activeIndex = milestones.indexWhere((m) => !m.achieved);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        100, // accommodates floating dock
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Track Hero Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryNavy, Color(0xFF1E293B)],
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.alt_route_rounded,
                        color: AppColors.accentGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SPECIALIZATION PATH',
                          style: AppTypography.textTheme.labelSmall?.copyWith(
                            color: AppColors.accentCyan,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            fontSize: 9.5,
                          ),
                        ),
                        Text(
                          trackName,
                          style: AppTypography.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Track your milestones and earn your readiness credential.',
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Progress Track Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Container(
                    height: 6,
                    color: Colors.white.withValues(alpha: 0.15),
                    child: Stack(
                      children: [
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.accentGreen,
                                  AppColors.accentCyan
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$achieved of ${milestones.length} milestones reached',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          Text(
            'Your learning journey',
            style: AppTypography.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          if (milestones.isEmpty)
            const EmptyState(
              icon: Icons.alt_route_rounded,
              title: 'No milestones yet',
              message:
                  'Milestones appear once your track has content to work through.',
            )
          else
            ...List.generate(milestones.length, (index) {
              final milestone = milestones[index];
              final isLast = index == milestones.length - 1;
              final status = milestone.achieved
                  ? MilestoneStatus.completed
                  : (index == activeIndex
                      ? MilestoneStatus.active
                      : MilestoneStatus.locked);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline Node & Connector Line
                  Column(
                    children: [
                      _buildNodeIndicator(status),
                      if (!isLast)
                        Container(
                          width: 3,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: status == MilestoneStatus.completed
                                ? const LinearGradient(
                                    colors: [
                                      AppColors.accentGreen,
                                      AppColors.accentCyan
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  )
                                : null,
                            color: status == MilestoneStatus.completed
                                ? null
                                : AppColors.border,
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Node Card
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: _buildMilestoneCard(milestone, status),
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  IconData _iconFor(String code) {
    if (code.startsWith('first_task')) return Icons.flag_rounded;
    if (code.startsWith('track_master')) return Icons.military_tech_rounded;
    if (code.startsWith('xp_')) return Icons.bolt_rounded;
    if (code.startsWith('streak_')) return Icons.local_fire_department_rounded;
    if (code.startsWith('level_')) return Icons.workspace_premium_rounded;
    return Icons.emoji_events_rounded;
  }

  Widget _buildNodeIndicator(MilestoneStatus status) {
    switch (status) {
      case MilestoneStatus.completed:
        return Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.accentGreen,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x4410B981),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.check, size: 20, color: Colors.white),
        );
      case MilestoneStatus.active:
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accentCyan, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentCyan.withValues(alpha: 0.4),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: AppColors.accentCyan,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      case MilestoneStatus.locked:
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.background,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: const Icon(Icons.lock_rounded,
              size: 16, color: AppColors.textSecondary),
        );
    }
  }

  Widget _buildMilestoneCard(Milestone milestone, MilestoneStatus status) {
    final isActive = status == MilestoneStatus.active;
    final isLocked = status == MilestoneStatus.locked;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white
            : (isLocked ? AppColors.background : AppColors.surface),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isActive
              ? AppColors.accentCyan
              : (isLocked
                  ? AppColors.border
                  : AppColors.accentGreen.withValues(alpha: 0.3)),
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.accentCyan.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isLocked
                      ? AppColors.border.withValues(alpha: 0.5)
                      : AppColors.accentLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  milestone.achieved
                      ? Icons.check_circle_rounded
                      : _iconFor(milestone.code),
                  size: 16,
                  color: isLocked
                      ? AppColors.textSecondary
                      : AppColors.accentGreen,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  milestone.name,
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: isLocked
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: milestone.achieved
                      ? AppColors.accentLight
                      : AppColors.xpPurpleLight,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${milestone.current}/${milestone.target}',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: milestone.achieved
                        ? AppColors.accentGreen
                        : AppColors.xpPurple,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            milestone.description,
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
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
        ShimmerLoader(height: 140),
        SizedBox(height: AppSpacing.xl),
        ShimmerLoader(height: 24, width: 200),
        SizedBox(height: AppSpacing.md),
        ShimmerLoader(height: 90),
        SizedBox(height: AppSpacing.sm),
        ShimmerLoader(height: 90),
        SizedBox(height: AppSpacing.sm),
        ShimmerLoader(height: 90),
      ],
    );
  }
}
