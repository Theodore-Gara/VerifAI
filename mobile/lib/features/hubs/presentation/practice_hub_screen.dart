import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/dashboard/providers.dart';
import 'package:verifai/features/task/presentation/task_run_screen.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets.dart';
import 'package:verifai/shared/widgets/hub_tile.dart';

/// Practice — the hub for doing: the recommended task first, then the skill
/// scenarios and the practice tools that used to live in the drawer.
class PracticeHubScreen extends ConsumerStatefulWidget {
  const PracticeHubScreen({super.key});

  @override
  ConsumerState<PracticeHubScreen> createState() => _PracticeHubScreenState();
}

class _PracticeHubScreenState extends ConsumerState<PracticeHubScreen> {
  bool _starting = false;

  Future<void> _startTask(DailyTask task) async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      await context.push('/task-run',
          extra: TaskRunArgs(task, practice: task.isRepeat));
      ref.invalidate(dashboardProvider);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackName = ref.watch(currentUserProvider).valueOrNull?.trackName;
    final isLegal = (trackName ?? '').toLowerCase() == 'legal';
    final nextTask = ref.watch(dashboardProvider).valueOrNull?.dailyTask;

    final scenarios = <HubEntry>[
      const HubEntry(
        title: 'Verification',
        subtitle: 'Catch AI\u2019s mistakes and fix them',
        icon: Icons.shield_rounded,
        route: '/verification',
      ),
      const HubEntry(
        title: 'AI Judgement',
        subtitle: 'Decide when AI should or shouldn\u2019t be used',
        icon: Icons.psychology_rounded,
        route: '/judgement',
      ),
      const HubEntry(
        title: 'Risk & Governance',
        subtitle: 'Spot privacy, bias and compliance risks',
        icon: Icons.gavel_rounded,
        route: '/risk-governance',
      ),
      if (isLegal)
        const HubEntry(
          title: 'Interview practice',
          subtitle: 'Work through interview questions',
          icon: Icons.question_answer_rounded,
          route: '/interview',
        ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: AppSpacing.screenPadding,
        title: Text(
          'Practice',
          style: AppTypography.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Ask Vera',
            onPressed: () => context.push('/assistant'),
            icon: Icon(Icons.auto_awesome_rounded,
                color: AppColors.primaryNavy),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.ambientCyan,
                ),
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.sm,
              AppSpacing.screenPadding,
              110,
            ),
            children: [
              Text(
                'Do the work',
                style: AppTypography.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'One scenario at a time, then check what changed.',
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (nextTask != null) ...[
                _NextTaskCard(
                  task: nextTask,
                  isStarting: _starting,
                  onStart: () => _startTask(nextTask),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              const HubSectionTitle('Skill scenarios'),
              for (final entry in scenarios) HubTile(entry: entry),
              const HubSectionTitle('Practice tools'),
              HubTile(
                entry: HubEntry(
                  title: 'Verification Studio',
                  subtitle: 'Paste AI output and get a structured critique',
                  icon: Icons.fact_check_rounded,
                  onTap: () => context.push('/verification-studio'),
                ),
              ),
              HubTile(
                entry: HubEntry(
                  title: 'Industry practice cases',
                  subtitle: 'Read a workplace case and record the decision',
                  icon: Icons.business_center_rounded,
                  onTap: () => context.push('/industry-practice'),
                ),
              ),
              HubTile(
                entry: HubEntry(
                  title: 'Task history',
                  subtitle: 'Every graded attempt, with the feedback',
                  icon: Icons.history_rounded,
                  onTap: () => context.push('/task-history'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NextTaskCard extends StatelessWidget {
  final DailyTask task;
  final bool isStarting;
  final VoidCallback onStart;

  const _NextTaskCard({
    required this.task,
    required this.isStarting,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Next task: ${task.title}. '
          '${task.dimension}, ${task.difficulty ?? 'medium'} difficulty.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: AppColors.primaryNavy.withValues(alpha: 0.16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.isRepeat ? 'PRACTICE AGAIN' : 'YOUR NEXT TASK',
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: AppColors.accentGreen,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              task.title,
              style: AppTypography.textTheme.titleLarge?.copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${task.dimension} · ${task.difficulty ?? 'medium'}',
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            VerifAIButton(
              label: task.isRepeat ? 'Practise again' : 'Start task',
              trailingIcon: Icons.arrow_forward_rounded,
              isLoading: isStarting,
              onPressed: isStarting ? null : onStart,
            ),
          ],
        ),
      ),
    );
  }
}
