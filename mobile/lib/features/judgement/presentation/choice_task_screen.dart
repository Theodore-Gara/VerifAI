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
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/empty_state.dart';
import 'package:verifai/shared/widgets/shimmer_loader.dart';
import 'package:verifai/shared/widgets/verifai_button.dart';

/// Shared controlled-choice task screen: a scenario with a Decision section and
/// a Reason section. Used by AI Judgement and Risk & Governance.
class ChoiceTaskScreen extends ConsumerStatefulWidget {
  final FutureProvider<DailyTask?> taskProvider;
  final String feature;
  final String categoryLabel;
  final String decisionPrompt;
  final String reasonPrompt;

  const ChoiceTaskScreen({
    super.key,
    required this.taskProvider,
    required this.feature,
    required this.categoryLabel,
    this.decisionPrompt = 'What should you do?',
    this.reasonPrompt = 'Pick the best reason',
  });

  @override
  ConsumerState<ChoiceTaskScreen> createState() => _ChoiceTaskScreenState();
}

class _ChoiceTaskScreenState extends ConsumerState<ChoiceTaskScreen> {
  int? _decisionId;
  int? _reasonId;
  final _rationaleController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _rationaleController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _decisionId != null && _reasonId != null && !_submitting;

  Future<void> _submit(DailyTask task) async {
    setState(() => _submitting = true);
    try {
      final response = await ref.read(apiClientProvider).submitTask(
            TaskSubmissionRequest(
              taskId: task.id,
              decisionOptionId: _decisionId,
              reasonOptionId: _reasonId,
              rationale: _rationaleController.text.trim().isEmpty
                  ? null
                  : _rationaleController.text.trim(),
              practice: task.isRepeat,
            ),
          );
      if (!mounted) return;
      ref.invalidate(widget.taskProvider);
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
          task: task,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not submit. ${classifyError(e).message}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(widget.taskProvider);
    final task = taskAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.categoryLabel,
          style: AppTypography.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (task != null)
            IconButton(
              tooltip: 'Ask the Learning Assistant',
              icon: const Icon(Icons.support_agent_rounded,
                  color: AppColors.primaryNavy),
              onPressed: () => context.push('/assistant', extra: task),
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: taskAsync.when(
        loading: () => _shimmer(),
        error: (error, _) => AsyncErrorView(
          error: error,
          fallbackMessage: 'Failed to load your ${widget.categoryLabel} task.',
          onRetry: () => ref.invalidate(widget.taskProvider),
        ),
        data: (task) => task == null
            ? const EmptyState(
                icon: Icons.task_alt_rounded,
                title: 'All caught up!',
                message: 'No tasks are available for your track right now.',
              )
            : _buildTask(task),
      ),
    );
  }

  Widget _buildTask(DailyTask task) {
    final decisions =
        task.options.where((o) => o.kind == 'decision').toList();
    final reasons = task.options.where((o) => o.kind == 'reason').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task.isRepeat)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.goldLight,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border:
                    Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
              ),
              child: Text(
                'PRACTICE RUN — this task was completed before, so it earns no XP.',
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: AppColors.goldDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 9.5,
                ),
              ),
            ),
          Text(
            task.title,
            style: AppTypography.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (task.scenario != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                task.scenario!,
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),

          _sectionTitle(widget.decisionPrompt),
          const SizedBox(height: AppSpacing.sm),
          ...decisions.map((o) => _choiceTile(
                option: o,
                selected: _decisionId == o.id,
                onTap: () => setState(() => _decisionId = o.id),
              )),

          const SizedBox(height: AppSpacing.xl),
          _sectionTitle(widget.reasonPrompt),
          const SizedBox(height: AppSpacing.sm),
          ...reasons.map((o) => _choiceTile(
                option: o,
                selected: _reasonId == o.id,
                onTap: () => setState(() => _reasonId = o.id),
              )),

          const SizedBox(height: AppSpacing.xl),
          Text(
            'Rationale (optional)',
            style: AppTypography.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _rationaleController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Add a short justification (not scored).',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          VerifAIButton(
            label: _submitting ? 'Submitting…' : 'Submit',
            variant: VerifAIButtonVariant.verification,
            isLoading: _submitting,
            onPressed: _canSubmit ? () => _submit(task) : null,
            leadingIcon: Icons.check_circle_rounded,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: AppTypography.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      );

  Widget _choiceTile({
    required TaskOption option,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accentLight.withValues(alpha: 0.7)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? AppColors.accentGreen : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color:
                    selected ? AppColors.accentGreen : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  option.label,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
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
          ShimmerLoader(height: 28, width: 220),
          SizedBox(height: AppSpacing.md),
          ShimmerLoader.card(height: 140),
          SizedBox(height: AppSpacing.md),
          ShimmerLoader(height: 60),
          SizedBox(height: AppSpacing.sm),
          ShimmerLoader(height: 60),
        ],
      );
}
