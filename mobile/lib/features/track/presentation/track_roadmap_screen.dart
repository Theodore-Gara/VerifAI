import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/providers/track_scope.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/features/track/providers.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/dock_clearance.dart';
import 'package:verifai/shared/widgets/shimmer_loader.dart';
import 'package:verifai/shared/widgets/verifai_page_scaffold.dart';

/// Stage-based readiness roadmap from `GET /api/roadmap`.
class TrackRoadmapScreen extends ConsumerWidget {
  const TrackRoadmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-read when the industry changes.
    ref.watch(trackRevisionProvider);
    final roadmapAsync = ref.watch(roadmapProvider);

    return VerifaiPageScaffold(
      title: 'Skill roadmap',
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(roadmapProvider);
          try {
            await ref.read(roadmapProvider.future);
          } on Object {
            // Rendered by the error branch.
          }
        },
        child: roadmapAsync.when(
          data: (roadmap) => _RoadmapBody(roadmap: roadmap),
          loading: () => _shimmer(),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              const SizedBox(height: 80),
              Icon(Icons.route_rounded, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Could not load your roadmap. Pull to refresh.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: FilledButton(
                  onPressed: () => ref.invalidate(roadmapProvider),
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmer() => ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: const [
          ShimmerLoader(height: 170),
          SizedBox(height: AppSpacing.xl),
          ShimmerLoader(height: 110),
          SizedBox(height: AppSpacing.md),
          ShimmerLoader(height: 110),
        ],
      );
}

class _RoadmapBody extends StatelessWidget {
  const _RoadmapBody({required this.roadmap});
  final RoadmapData roadmap;

  @override
  Widget build(BuildContext context) {
    final summary = roadmap.summary;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        dockClearance(context),
      ),
      children: [
        _hero(context, summary),
        const SizedBox(height: AppSpacing.lg),
        if (roadmap.nextAction != null) ...[
          _NextActionCard(action: roadmap.nextAction!),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(
          'Your stages',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final stage in roadmap.stages) ...[
          _StageCard(stage: stage),
          const SizedBox(height: AppSpacing.md),
        ],
        if (roadmap.credential != null)
          _CredentialCard(credential: roadmap.credential!),
      ],
    );
  }

  Widget _hero(BuildContext context, RoadmapSummary summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryFill, AppColors.greenFill],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'READINESS ROADMAP',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.9,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      roadmap.trackName.isEmpty
                          ? 'Your industry'
                          : roadmap.trackName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 58,
                height: 58,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: summary.percent / 100,
                      strokeWidth: 5,
                      backgroundColor: Colors.white24,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.gold),
                    ),
                    Text(
                      '${summary.percent}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _HeroPill('Stage ${summary.currentStage}'),
              _HeroPill('${summary.milestonesCompleted}/${summary.milestonesTotal} milestones'),
              _HeroPill('Readiness ${summary.readinessScore}'),
              _HeroPill(summary.tier),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Readiness grows as you complete the evidence in each stage. '
            'Nothing is taken away when you retake a task.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.4,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
          ),
        ),
      );
}

class _NextActionCard extends StatelessWidget {
  const _NextActionCard({required this.action});
  final RoadmapNextAction action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.accentGreen.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          Icon(Icons.flag_rounded, color: AppColors.accentGreen),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next step',
                  style: TextStyle(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: .6,
                  ),
                ),
                Text(
                  action.label,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (action.route != null)
            FilledButton(
              onPressed: () => context.push(action.route!),
              child: const Text('Go'),
            ),
        ],
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({required this.stage});
  final RoadmapStage stage;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (stage.status) {
      'complete' => (Icons.check_circle_rounded, AppColors.accentGreen, 'Complete'),
      'active' => (Icons.play_circle_fill_rounded, AppColors.accentGreen, 'Active'),
      _ => (Icons.lock_rounded, AppColors.textSecondary, 'Locked'),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: stage.active
              ? AppColors.accentGreen.withValues(alpha: .45)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${stage.order}. ${stage.title}',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (stage.outcome.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              stage.outcome,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
                fontSize: 12.5,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          for (final milestone in stage.milestones) ...[
            _MilestoneRow(milestone: milestone),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({required this.milestone});
  final RoadmapMilestone milestone;

  @override
  Widget build(BuildContext context) {
    final color = switch (milestone.status) {
      'complete' => AppColors.accentGreen,
      'current' => AppColors.accentGreen,
      'up_next' => AppColors.info,
      _ => AppColors.textSecondary,
    };
    final icon = switch (milestone.status) {
      'complete' => Icons.check_rounded,
      'current' => Icons.radio_button_checked_rounded,
      'up_next' => Icons.radio_button_unchecked_rounded,
      _ => Icons.lock_outline_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  milestone.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight:
                        milestone.isCurrent ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '${milestone.current}/${milestone.target} ${milestone.unit}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          if (milestone.description.isNotEmpty) ...[
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(left: 23),
              child: Text(
                milestone.description,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ),
          ],
          if (!milestone.complete) ...[
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 23),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: milestone.progress,
                  minHeight: 5,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
          ],
          if (milestone.action?.route != null &&
              milestone.status == 'current') ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push(milestone.action!.route!),
                child: Text(milestone.action!.label),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CredentialCard extends StatelessWidget {
  const _CredentialCard({required this.credential});
  final RoadmapCredential credential;

  @override
  Widget build(BuildContext context) {
    final color = credential.unlocked
        ? AppColors.goldDark
        : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: credential.unlocked
              ? [AppColors.goldLight, AppColors.surface]
              : [AppColors.background, AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        children: [
          Icon(
            credential.unlocked
                ? Icons.workspace_premium_rounded
                : Icons.lock_outline_rounded,
            color: color,
            size: 30,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  credential.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (credential.description != null)
                  Text(
                    credential.description!,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                Text(
                  credential.unlocked
                      ? 'Unlocked — all stages complete.'
                      : 'Locked until the final stage is complete.',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
