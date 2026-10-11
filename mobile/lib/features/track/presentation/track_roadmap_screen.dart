import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/shared/widgets/sample_data_banner.dart';
import 'package:verifai/shared/widgets/verifai_button.dart';

enum MilestoneStatus {
  completed,
  active,
  locked,
}

class TrackRoadmapScreen extends ConsumerWidget {
  const TrackRoadmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final trackName = user?.trackName ?? 'Your track';

    final milestones = [
      _Milestone(
        title: 'AI Verification Fundamentals',
        description:
            'Understand hallucination patterns and basic factuality checks',
        status: MilestoneStatus.completed,
        icon: Icons.shield_rounded,
        xpReward: 100,
      ),
      _Milestone(
        title: 'Hallucination Spotting',
        description:
            'Detect subtle numerical errors and fabricated citations in outputs',
        status: MilestoneStatus.completed,
        icon: Icons.search_rounded,
        xpReward: 150,
      ),
      _Milestone(
        title: 'Prompt Quality & Robustness',
        description:
            'Design deterministic constraints and few-shot calibration guides',
        status: MilestoneStatus.active,
        icon: Icons.terminal_rounded,
        xpReward: 200,
      ),
      _Milestone(
        title: 'Risk & Compliance Guardrails',
        description:
            'Corporate policy adherence, privacy leaks, and bias filters',
        status: MilestoneStatus.locked,
        icon: Icons.gavel_rounded,
        xpReward: 250,
      ),
      _Milestone(
        title: 'Capstone: Autonomous Agent Oversight',
        description:
            'Master enterprise-grade verification for multi-agent workflows',
        status: MilestoneStatus.locked,
        icon: Icons.military_tech_rounded,
        xpReward: 400,
      ),
    ];

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          100, // accommodates floating dock
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SampleDataBanner(
              message:
                  'Preview roadmap with sample milestones. Your real milestone progress is not tracked here yet.',
            ),
            const SizedBox(height: AppSpacing.md),

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
                    'Follow the path, master AI verification milestones, and earn your certified readiness credential.',
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
                            widthFactor: 0.4,
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

            // Skill Tree Nodes
            ...List.generate(milestones.length, (index) {
              final milestone = milestones[index];
              final isLast = index == milestones.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline Node & Connector Line
                  Column(
                    children: [
                      _buildNodeIndicator(context, milestone.status),
                      if (!isLast)
                        Container(
                          width: 3,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient:
                                milestone.status == MilestoneStatus.completed
                                    ? const LinearGradient(
                                        colors: [
                                          AppColors.accentGreen,
                                          AppColors.accentCyan
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      )
                                    : null,
                            color: milestone.status == MilestoneStatus.completed
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
                      child: _buildMilestoneCard(context, milestone),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeIndicator(BuildContext context, MilestoneStatus status) {
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

  Widget _buildMilestoneCard(BuildContext context, _Milestone milestone) {
    final isActive = milestone.status == MilestoneStatus.active;
    final isLocked = milestone.status == MilestoneStatus.locked;

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
                      : (isActive
                          ? AppColors.accentLight
                          : AppColors.accentLight.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  milestone.icon,
                  size: 16,
                  color: isLocked
                      ? AppColors.textSecondary
                      : (isActive
                          ? AppColors.primaryNavy
                          : AppColors.accentGreen),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  milestone.title,
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
                  color: AppColors.xpPurpleLight,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '+${milestone.xpReward} XP',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.xpPurple,
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
          if (isActive) ...[
            const SizedBox(height: AppSpacing.md),
            VerifAIButton(
              label: 'Continue learning',
              variant: VerifAIButtonVariant.verification,
              height: 40,
              leadingIcon: Icons.play_arrow_rounded,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Milestone quests are coming soon.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _Milestone {
  final String title;
  final String description;
  final MilestoneStatus status;
  final IconData icon;
  final int xpReward;

  _Milestone({
    required this.title,
    required this.description,
    required this.status,
    required this.icon,
    required this.xpReward,
  });
}
