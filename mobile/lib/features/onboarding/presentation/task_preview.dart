import 'package:flutter/material.dart';

import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/shared/models.dart';

/// A miniature of the task screen, used in the welcome tour so the learner
/// sees the real product before they meet it.
///
/// Built from the same widgets the task screen uses, so it cannot drift out of
/// date the way a screenshot would. It is decorative and non-interactive:
/// the preview is about showing the shape of a task, not running one.
class TaskPreview extends StatelessWidget {
  const TaskPreview({
    super.key,
    required this.task,
    this.selectedOptionId,
  });

  final DailyTask task;

  /// Which option is pre-selected, to show the "your answer" state.
  final int? selectedOptionId;

  @override
  Widget build(BuildContext context) {
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
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PreviewLabel('AI SCENARIO OUTPUT',
              icon: Icons.psychology_rounded),
          const SizedBox(height: AppSpacing.sm),
          Text(
            task.scenario?.isNotEmpty == true
                ? task.scenario!
                : 'The AI drafts a summary for you to check.',
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              height: 1.45,
              fontSize: 12.5,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          if (task.embeddedFlaw?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.md),
            const _PreviewLabel('ISSUE TO INVESTIGATE',
                icon: Icons.search_rounded),
            const SizedBox(height: 6),
            Text(
              task.embeddedFlaw!,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
                fontSize: 12.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (task.options.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            for (final option in task.options.take(2)) ...[
              _PreviewOption(
                label: option.label,
                isSelected: option.id == selectedOptionId,
              ),
              const SizedBox(height: 6),
            ],
          ],
        ],
      ),
    );
  }
}

class _PreviewLabel extends StatelessWidget {
  const _PreviewLabel(this.text, {required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primaryNavy),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primaryNavy,
              letterSpacing: 0.5,
              fontSize: 10.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewOption extends StatelessWidget {
  const _PreviewOption({required this.label, required this.isSelected});

  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.accentLight.withValues(alpha: 0.5) : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isSelected ? AppColors.accentGreen : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSelected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 15,
            color: isSelected ? AppColors.accentGreen : AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The fallback shown when the learner has no task available yet (a fresh
/// account, or an exhausted rotation). It mirrors the shape of a real task so
/// the preview never looks broken.
class TaskPreviewPlaceholder extends StatelessWidget {
  const TaskPreviewPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
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
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PreviewLabel('AI SCENARIO OUTPUT',
              icon: Icons.psychology_rounded),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'The AI drafts a quarterly risk summary for a client. It reads '
            'well — but one figure does not match the source data.',
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              height: 1.45,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const _PreviewLabel('ISSUE TO INVESTIGATE',
              icon: Icons.search_rounded),
          const SizedBox(height: 6),
          Text(
            'Check the figure against the source, then give your verdict.',
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
