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
import 'package:verifai/shared/widgets/app_feedback_banner.dart';
import 'package:verifai/shared/widgets/verifai_button.dart';

/// Carries a task into the full-screen runner via the route `extra`.
class TaskRunArgs {
  final DailyTask task;
  final bool practice;

  const TaskRunArgs(this.task, {this.practice = false});
}

/// Full-screen verification task runner (choice or line_text). The Learning
/// Assistant is reachable from the app bar.
class TaskRunScreen extends ConsumerStatefulWidget {
  final DailyTask task;
  final bool practice;

  const TaskRunScreen({
    super.key,
    required this.task,
    this.practice = false,
  });

  @override
  ConsumerState<TaskRunScreen> createState() => _TaskRunScreenState();
}

class _TaskRunScreenState extends ConsumerState<TaskRunScreen> {
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

      ref.invalidate(dashboardProvider);
      ref.invalidate(achievementsProvider);

      if (!mounted) return;
      final feedback = FeedbackResult(
        score: response.score,
        passed: response.passed,
        feedback: response.feedback,
        xpEarned: response.xpEarned,
        correctAnswer: response.correctAnswer,
        matchedKeywords: response.matchedKeywords,
        missedKeywords: response.missedKeywords,
        newlyEarnedAchievements: response.newlyEarnedAchievements,
        task: widget.task,
      );
      // Replace the task screen with the feedback so the back stack stays
      // constant as the user continues through tasks.
      context.pushReplacement('/feedback', extra: feedback);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showFeedback(
        context,
        FeedbackKind.error,
        'Could not submit your answer. ${classifyError(e).message}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _dimensionLabel(widget.task.dimension),
          style: AppTypography.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Ask the Learning Assistant',
            icon: Icon(Icons.support_agent_rounded,
                color: AppColors.primaryNavy),
            onPressed: () => context.push('/assistant', extra: widget.task),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          AppSpacing.xxl,
        ),
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
            if (widget.task.scenario != null) ...[
              _scenarioCard(),
              const SizedBox(height: AppSpacing.md),
            ],
            if (widget.task.embeddedFlaw?.isNotEmpty == true) ...[
              _flawCard(),
              const SizedBox(height: AppSpacing.lg),
            ],
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
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: VerifAIButton(
            label: widget.practice ? 'Submit Practice' : 'Submit Answer',
            variant: VerifAIButtonVariant.verification,
            isLoading: _isSubmitting,
            onPressed: _canSubmit ? _handleSubmit : null,
          ),
        ),
      ),
    );
  }

  Widget _scenarioCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_rounded,
                  size: 18, color: AppColors.primaryNavy),
              const SizedBox(width: 6),
              Text(
                'AI SCENARIO OUTPUT',
                style: AppTypography.textTheme.labelSmall?.copyWith(
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
    );
  }

  Widget _flawCard() {
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
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ISSUE TO INVESTIGATE',
            style: AppTypography.textTheme.labelSmall?.copyWith(
              color: AppColors.primaryNavy,
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
    );
  }

  Widget _buildOption(TaskOption option) {
    final isSelected = _selectedOptionId == option.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => setState(() => _selectedOptionId = option.id),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isSelected ? AppColors.primaryNavy : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryNavy.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isSelected ? AppColors.primaryNavy : Colors.transparent,
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primaryNavy : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
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

  String _dimensionLabel(String key) {
    const labels = {
      'verification': 'Verification',
      'judgement': 'AI Judgement',
      'ai_judgement': 'AI Judgement',
      'prompt_design': 'Prompt Design',
      'risk_governance': 'Risk & Governance',
      'human_ai_collab': 'Human-AI Collaboration',
    };
    return labels[key] ??
        key
            .replaceAll('_', ' ')
            .split(' ')
            .map(
                (w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');
  }
}
