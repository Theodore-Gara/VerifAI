import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/services/api_client.dart';
import 'package:verifai/core/services/api_error.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/dashboard/providers.dart';
import 'package:verifai/features/feedback/presentation/feedback_screen.dart';
import 'package:verifai/features/profile/providers.dart';
import 'package:verifai/shared/models/daily_task.dart';
import 'package:verifai/shared/widgets/verifai_button.dart';

class TaskChallengeModal extends ConsumerStatefulWidget {
  final DailyTask task;
  final VoidCallback onTaskCompleted;
  final bool practice;

  const TaskChallengeModal({
    super.key,
    required this.task,
    required this.onTaskCompleted,
    this.practice = false,
  });

  static Future<void> show(
    BuildContext context,
    DailyTask task,
    VoidCallback onCompleted, {
    bool practice = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskChallengeModal(
        task: task,
        onTaskCompleted: onCompleted,
        practice: practice,
      ),
    );
  }

  @override
  ConsumerState<TaskChallengeModal> createState() => _TaskChallengeModalState();
}

class _TaskChallengeModalState extends ConsumerState<TaskChallengeModal> {
  int? _selectedOptionId;
  final Set<int> _selectedLines = {};
  final _fixController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fixController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (widget.task.format == 'line_text') {
      return _selectedLines.isNotEmpty &&
          _fixController.text.trim().isNotEmpty &&
          _reasonController.text.trim().isNotEmpty;
    }
    return widget.task.format == 'choice' &&
        widget.task.options.isNotEmpty &&
        _selectedOptionId != null;
  }

  Future<void> _handleSubmit() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);

    try {
      final response = await ref.read(apiClientProvider).submitTask(
            TaskSubmissionRequest(
              taskId: widget.task.id,
              answerOptionId:
                  widget.task.format == 'choice' ? _selectedOptionId : null,
              selectedLines: widget.task.format == 'line_text'
                  ? (_selectedLines.toList()..sort())
                  : null,
              fix: widget.task.format == 'line_text'
                  ? _fixController.text.trim()
                  : null,
              reason: widget.task.format == 'line_text'
                  ? _reasonController.text.trim()
                  : null,
              practice: widget.practice,
            ),
          );

      if (!mounted) return;
      Navigator.of(context).pop();

      // A scored attempt changes XP/streak/next task and may unlock a badge.
      ref.invalidate(dashboardProvider);
      ref.invalidate(achievementsProvider);

      if (!context.mounted) return;
      context.push(
        '/feedback',
        extra: FeedbackResult(
          score: response.score,
          passed: response.passed,
          feedback: response.feedback,
          xpEarned: response.xpEarned,
          correctAnswer: response.correctAnswer,
          matchedKeywords: response.matchedKeywords,
          missedKeywords: response.missedKeywords,
          newlyEarnedAchievements: response.newlyEarnedAchievements,
          task: widget.task,
        ),
      );
      widget.onTaskCompleted();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Could not submit your answer. ${classifyError(e).message}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xxxl),
          topRight: Radius.circular(AppRadius.xxxl),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(AppRadius.badge),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sports_esports_rounded,
                          size: 16, color: AppColors.accentGreen),
                      const SizedBox(width: 4),
                      Text(
                        'VERIFICATION',
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: AppColors.accentGreen,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task.title,
                    style: AppTypography.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Scenario Card
                  if (widget.task.scenario != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.psychology_rounded,
                                  size: 18, color: AppColors.primaryNavy),
                              const SizedBox(width: 6),
                              Text(
                                'AI SCENARIO OUTPUT',
                                style: AppTypography.textTheme.labelSmall
                                    ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryNavy,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            widget.task.scenario!,
                            style: AppTypography.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  if (widget.task.embeddedFlaw?.isNotEmpty == true) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.goldLight,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.45)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ISSUE TO INVESTIGATE',
                            style: AppTypography.textTheme.labelSmall?.copyWith(
                              color: AppColors.goldDark,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            widget.task.embeddedFlaw!,
                            style: AppTypography.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/assistant', extra: widget.task),
                    icon: const Icon(Icons.support_agent_rounded),
                    label: const Text('Ask the Learning Assistant'),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Text(
                    widget.task.format == 'line_text'
                        ? 'Select the flawed line(s), then enter a correction and reason.'
                        : widget.practice
                            ? 'Practice: choose the best response'
                            : 'What would you do with this output?',
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (widget.task.format == 'line_text')
                    _buildLineTextAnswer()
                  else if (widget.task.format == 'choice' &&
                      widget.task.options.isNotEmpty)
                    ...widget.task.options.map(_buildOption)
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Text(
                        'This task does not include supported answer content. Refresh your task list and try again.',
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),

          // Bottom Action
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: VerifAIButton(
              label:
                  widget.practice ? 'Submit Practice' : 'Submit Verification',
              variant: VerifAIButtonVariant.verification,
              isLoading: _isSubmitting,
              onPressed: _canSubmit ? _handleSubmit : null,
              leadingIcon: Icons.check_circle_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(TaskOption option) {
    final isSelected = _selectedOptionId == option.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => setState(() => _selectedOptionId = option.id),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accentLight.withValues(alpha: 0.7)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isSelected ? AppColors.accentGreen : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isSelected ? AppColors.accentGreen : Colors.transparent,
                  border: Border.all(
                    color:
                        isSelected ? AppColors.accentGreen : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  option.label,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineTextAnswer() {
    if (widget.task.aiOutputLines.isEmpty) {
      return const Text(
        'This task has no AI output lines to review. Refresh your task list and try again.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...widget.task.aiOutputLines.asMap().entries.map((entry) {
          final lineNumber = entry.key + 1;
          final selected = _selectedLines.contains(lineNumber);
          return Material(
            color: AppColors.surface,
            child: CheckboxListTile(
              value: selected,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                '${lineNumber.toString().padLeft(2, '0')}  ${entry.value}',
                style:
                    AppTypography.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
              onChanged: (checked) => setState(() {
                if (checked == true) {
                  _selectedLines.add(lineNumber);
                } else {
                  _selectedLines.remove(lineNumber);
                }
              }),
            ),
          );
        }),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _fixController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'How would you correct the output?',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _reasonController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Why is this correction needed?',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}
