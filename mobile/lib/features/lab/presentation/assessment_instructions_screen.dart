import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';
import 'package:verifai/features/lab/presentation/assessment_paper_screen.dart';
import 'package:verifai/features/lab/providers.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/app_feedback_banner.dart';
import 'package:verifai/shared/widgets/empty_state.dart';
import 'package:verifai/shared/widgets/shimmer_loader.dart';

/// What the paper screen hands back after a submission.
class AssessmentOutcome {
  const AssessmentOutcome({required this.result, required this.attemptId});
  final LabAssessmentResult result;
  final int attemptId;
}

/// The assessment instructions / results screen.
class LabAssessmentInstructionsScreen extends ConsumerStatefulWidget {
  const LabAssessmentInstructionsScreen(
      {super.key, required this.code, this.outcome});
  final String code;
  final AssessmentOutcome? outcome;

  @override
  ConsumerState<LabAssessmentInstructionsScreen> createState() => _State();
}

class _State extends ConsumerState<LabAssessmentInstructionsScreen> {
  bool _starting = false;

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      final start =
          await ref.read(apiClientProvider).startAssessment(widget.code);
      if (!mounted) return;
      context.push('/ai-lab/assessments/${widget.code}/paper',
          extra: PaperArgs(code: widget.code, start: start));
    } catch (_) {
      if (!mounted) return;
      showFeedback(
        context,
        FeedbackKind.error,
        'Could not start the paper. Try again.',
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paperAsync = ref.watch(assessmentPaperProvider(widget.code));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/ai-lab/assessments'),
        ),
        title: Text('Assessment',
            style: AppTypography.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
        actions: [
          TextButton(
            onPressed: () => context.go('/ai-lab/assessments'),
            child: const Text('Assessments'),
          ),
        ],
      ),
      body: paperAsync.when(
        loading: () => ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: const [
              ShimmerLoader(height: 40),
              SizedBox(height: AppSpacing.md),
              ShimmerLoader(height: 200)
            ]),
        error: (e, _) => AsyncErrorView(
          error: e,
          fallbackMessage: 'Failed to load the assessment.',
          onRetry: () => ref.invalidate(assessmentPaperProvider(widget.code)),
        ),
        data: (paper) => ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
              AppSpacing.sm, AppSpacing.screenPadding, AppSpacing.xxl),
          children: [
            Text(paper.assessment.title,
                style: AppTypography.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
            if (paper.assessment.summary.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(paper.assessment.summary,
                  style: AppTypography.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary, height: 1.45)),
            ],
            const SizedBox(height: AppSpacing.md),
            _metaRow(paper.assessment),
            if (paper.assessment.instructions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _block('RULES',
                  paper.assessment.instructions.map((e) => '• $e').join('\n')),
            ],
            const SizedBox(height: AppSpacing.lg),
            _marksBreakdown(paper),
            const SizedBox(height: AppSpacing.xl),
            if (widget.outcome == null)
              // Starting a paper is a network round trip before navigation, so
              // the button reports that it is working instead of looking dead.
              FilledButton.icon(
                onPressed:
                    _starting || paper.assessment.viewOnly ? null : _start,
                icon: _starting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(
                  paper.assessment.viewOnly
                      ? 'View only: attempts used'
                      : _starting
                          ? 'Starting…'
                          : 'Start attempt',
                ),
              )
            else
              _resultPanel(context, paper, widget.outcome!),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(LabAssessment a) {
    final chips = [
      '${a.totalMarks} marks',
      '${(a.timeLimitSeconds / 60).round()} minutes',
      'Pass ${a.passScore}%',
      '${a.attemptsRemaining} of ${a.maxAttempts} attempts left',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in chips)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                  color: AppColors.accentGreen.withValues(alpha: .35)),
            ),
            child: Text(c,
                style: AppTypography.textTheme.labelMedium?.copyWith(
                    color: AppColors.primaryNavy, fontWeight: FontWeight.w800)),
          ),
      ],
    );
  }

  Widget _marksBreakdown(LabAssessmentPaper paper) {
    // Group the sub-questions under their numbered Question (1..6) and show
    // each question's total marks.
    final groups = <int?, List<LabAssessmentQuestion>>{};
    for (final q in paper.questions) {
      groups.putIfAbsent(q.questionNo, () => []).add(q);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('QUESTION BREAKDOWN',
            style: AppTypography.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: .5)),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (final entry in groups.entries)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key == null
                              ? 'Question'
                              : 'Question ${entry.key}',
                          style: AppTypography.textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                          '${entry.value.fold<int>(0, (s, q) => s + q.marks)} marks',
                          style: AppTypography.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryNavy)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _block(String label, String body) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: .5)),
          const SizedBox(height: 6),
          Text(body,
              style: AppTypography.textTheme.bodyMedium?.copyWith(height: 1.5)),
        ],
      );

  Widget _resultPanel(BuildContext context, LabAssessmentPaper paper,
      AssessmentOutcome outcome) {
    final r = outcome.result;
    final analysisAsync = ref.watch(assessmentAnalysisProvider(
        AssessmentKey(widget.code, outcome.attemptId)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: (r.passed ? AppColors.accentGreen : AppColors.warning)
                .withValues(alpha: .08),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
                color: (r.passed ? AppColors.accentGreen : AppColors.warning)
                    .withValues(alpha: .4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  r.pendingMarking
                      ? 'Submitted, awaiting marking'
                      : (r.passed ? 'Passed' : 'Not passed'),
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryNavy)),
              const SizedBox(height: 6),
              Text(
                  '${r.marksAwarded} / ${r.totalMarks} marks  ·  ${r.score}%'
                  '${r.timedOut ? '  ·  time expired' : ''}',
                  style: AppTypography.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              if (r.xpEarned > 0 || r.tokensEarned > 0) ...[
                const SizedBox(height: 6),
                Text(
                    'Earned ${r.xpEarned} XP and ${r.tokensEarned} tokens'
                    '${r.achievement != null ? ' · badge unlocked' : ''}',
                    style: AppTypography.textTheme.labelMedium?.copyWith(
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.w800)),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('PER-QUESTION',
            style: AppTypography.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: .5)),
        const SizedBox(height: AppSpacing.sm),
        for (final q in r.questions)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                    q.pending
                        ? Icons.hourglass_empty_rounded
                        : (q.correct == true
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded),
                    size: 16,
                    color: q.pending
                        ? AppColors.textSecondary
                        : (q.correct == true
                            ? AppColors.accentGreen
                            : AppColors.warning)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${q.awarded ?? '-'} / ${q.max} marks',
                      style: AppTypography.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Text("VERA'S ANALYSIS",
            style: AppTypography.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: .5)),
        const SizedBox(height: AppSpacing.sm),
        analysisAsync.when(
          loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: ShimmerLoader(height: 60)),
          error: (e, _) => Text('Analysis unavailable right now.',
              style: AppTypography.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary)),
          data: (a) => Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (a.headline.isNotEmpty)
                  Text(a.headline,
                      style: AppTypography.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryNavy)),
                if (a.report.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(a.report,
                      style: AppTypography.textTheme.bodyMedium
                          ?.copyWith(height: 1.5)),
                ],
                if (a.focus.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('Focus next: ${a.focus.join('; ')}',
                      style: AppTypography.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
