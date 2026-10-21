import 'package:flutter/material.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/shared/models/daily_task.dart';
import 'package:verifai/shared/widgets/verifai_button.dart';

class DailyTaskCard extends StatelessWidget {
  final DailyTask task;
  final VoidCallback? onStart;
  final bool isLoading;

  const DailyTaskCard({
    super.key,
    required this.task,
    this.onStart,
    this.isLoading = false,
  });

  // ponytail: mirrors backend DIFFICULTY_MAX_XP (scoringService.js) so the
  // card shows the real earning ceiling per difficulty; if budgets change,
  // update both sides or surface maxXp from the tasks API.
  static int _maxXp(String? difficulty) => switch (difficulty?.toLowerCase()) {
        'easy' => 50,
        'medium' => 70,
        'hard' => 100,
        _ => 50,
      };

  @override
  Widget build(BuildContext context) {
    // A card-sized InkWell: it has a ripple, focus and an accessibility action
    // (the previous bare GestureDetector had none of those).
    return Semantics(
      button: true,
      label: '${task.title}. ${task.dimension}. Start task.',
      child: InkWell(
        onTap: isLoading ? null : onStart,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Title + Difficulty Pill
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (task.difficulty != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFill,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        task.difficulty!.toUpperCase(),
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Unboxed Scenario Text
              if (task.scenario != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  task.scenario!,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: AppSpacing.md),

              // Footer Row with Gamification Tag + Action Button
              Row(
                children: [
                  if (task.isRepeat)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        'PRACTICE',
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                          letterSpacing: 0.4,
                        ),
                      ),
                    )
                  else
                    Text(
                      '+${_maxXp(task.difficulty)} XP',
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  const Spacer(),
                  VerifAIButton(
                    label: 'Start verification',
                    variant: VerifAIButtonVariant.verification,
                    isFullWidth: false,
                    height: 42,
                    isLoading: isLoading,
                    onPressed: onStart,
                    trailingIcon: Icons.arrow_forward_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
