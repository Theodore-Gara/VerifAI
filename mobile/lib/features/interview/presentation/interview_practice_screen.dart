import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/interview/providers.dart';
import 'package:verifai/shared/widgets/dock_clearance.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/empty_state.dart';
import 'package:verifai/shared/widgets/shimmer_loader.dart';

class InterviewPracticeScreen extends ConsumerStatefulWidget {
  const InterviewPracticeScreen({super.key});

  @override
  ConsumerState<InterviewPracticeScreen> createState() =>
      _InterviewPracticeScreenState();
}

class _InterviewPracticeScreenState
    extends ConsumerState<InterviewPracticeScreen> {
  final Set<int> _expanded = {};
  final Set<int> _marking = {};

  Future<void> _reveal(InterviewQuestion question) async {
    setState(() => _expanded.add(question.id));
    if (question.practiced || _marking.contains(question.id)) return;
    _marking.add(question.id);
    try {
      await ref.read(apiClientProvider).markInterviewPracticed(question.id);
      ref.invalidate(interviewQuestionsProvider);
    } catch (_) {
      // Best effort; the answer is already revealed.
    } finally {
      _marking.remove(question.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(interviewQuestionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Interview Practice',
          style: AppTypography.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: questionsAsync.when(
        loading: () => _shimmer(),
        error: (error, _) => AsyncErrorView(
          error: error,
          fallbackMessage: 'Failed to load interview questions.',
          onRetry: () => ref.invalidate(interviewQuestionsProvider),
        ),
        data: (questions) => questions.isEmpty
            ? const EmptyState(
                icon: Icons.question_answer_outlined,
                title: 'No questions yet',
                message:
                    'Interview practice questions are coming to your track soon.',
              )
            : _buildList(questions),
      ),
    );
  }

  Widget _buildList(List<InterviewQuestion> questions) {
    final covered = questions.where((q) => q.practiced).length;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        dockClearance(context),
      ),
      children: [
        Text(
          'Practise, then reveal the model answer.',
          style: AppTypography.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border:
                Border.all(color: AppColors.accentGreen.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  size: 16, color: AppColors.accentGreen),
              const SizedBox(width: 6),
              Text(
                '$covered / ${questions.length} practised',
                style: AppTypography.textTheme.labelMedium?.copyWith(
                  color: AppColors.accentGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ...questions.map(_buildCard),
      ],
    );
  }

  Widget _buildCard(InterviewQuestion question) {
    final expanded = _expanded.contains(question.id);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: question.practiced
              ? AppColors.accentGreen.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => expanded
            ? setState(() => _expanded.remove(question.id))
            : _reveal(question),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      question.question,
                      style: AppTypography.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                  if (question.practiced)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(Icons.check_circle_rounded,
                          size: 16, color: AppColors.accentGreen),
                    ),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: AppSpacing.md),
                _block('SAMPLE ANSWER', question.sampleAnswer),
                const SizedBox(height: AppSpacing.sm),
                _block(
                    "WHAT EMPLOYERS ARE TESTING", question.whatEmployersTest),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _block(String label, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            fontSize: 11.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          body,
          style: AppTypography.textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _shimmer() => ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: const [
          ShimmerLoader(height: 18, width: 240),
          SizedBox(height: AppSpacing.lg),
          ShimmerLoader(height: 70),
          SizedBox(height: AppSpacing.sm),
          ShimmerLoader(height: 70),
          SizedBox(height: AppSpacing.sm),
          ShimmerLoader(height: 70),
        ],
      );
}
