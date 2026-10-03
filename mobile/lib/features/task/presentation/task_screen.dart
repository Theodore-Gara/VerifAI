import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/dashboard/presentation/task_challenge_modal.dart';
import 'package:verifai/shared/models/daily_task.dart';
import 'package:verifai/shared/widgets/daily_task_card.dart';
import 'package:verifai/shared/widgets/empty_state.dart';

class TaskScreen extends ConsumerStatefulWidget {
  const TaskScreen({super.key});

  @override
  ConsumerState<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends ConsumerState<TaskScreen> {
  static const List<DailyTask> _availableTasks = [
    DailyTask(
      id: 101,
      title: 'Audit the Loan Approval Summary',
      scenario:
          'The AI drafted a loan approval summary citing "a strong credit history and stable income." '
          'The applicant\'s file shows two recent defaults and no verified income documents.',
      dimension: 'Verification',
      trackName: 'Finance',
      difficulty: 'Medium',
    ),
    DailyTask(
      id: 102,
      title: 'Draft a Safe Client Follow-up Email',
      scenario:
          'You asked the AI to write a follow-up to a client about their contract renewal. '
          'It included specific pricing numbers it was never given.',
      dimension: 'Risk & Governance',
      trackName: 'Business Consulting',
      difficulty: 'Hard',
    ),
    DailyTask(
      id: 103,
      title: 'Improve a Vague Data-Analysis Prompt',
      scenario:
          'A colleague prompted: "Look at this data and tell me what is important." '
          'The output was generic and partly invented. Rewrite the prompt for reliable results.',
      dimension: 'Prompt Design',
      trackName: 'IT / Software',
      difficulty: 'Easy',
    ),
  ];

  void _startTask(DailyTask task) {
    HapticFeedback.mediumImpact();
    TaskChallengeModal.show(context, task, () {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Tasks',
          style: AppTypography.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.screenPadding),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                  color: AppColors.accentGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sports_esports_rounded,
                    size: 14, color: AppColors.accentGreen),
                const SizedBox(width: 4),
                Text(
                  'VERIFICATION QUEUE',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 9.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Ambient Mesh Glows
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
            top: 300,
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
          SafeArea(
            top: false,
            child: _availableTasks.isEmpty
                ? const EmptyState(
                    icon: Icons.task_alt_rounded,
                    title: 'All caught up!',
                    message:
                        'No active missions right now. Check back tomorrow for your next challenge.',
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      AppSpacing.sm,
                      AppSpacing.screenPadding,
                      100, // accommodate floating dock
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verification tasks',
                          style:
                              AppTypography.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ...List.generate(_availableTasks.length, (index) {
                          final task = _availableTasks[index];
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: DailyTaskCard(
                              task: task,
                              onStart: () => _startTask(task),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
