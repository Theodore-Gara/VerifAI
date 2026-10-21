import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/shared/models.dart';

/// AI Lab lesson catalogue (`GET /api/lab/lessons`).
final labLessonsProvider = FutureProvider<List<LabLesson>>(
    (ref) => ref.watch(apiClientProvider).getLabLessons());

/// One lesson with its sections, activities, questions and attributions.
final labLessonProvider = FutureProvider.family<LabLessonDetail, String>(
    (ref, code) => ref.watch(apiClientProvider).getLabLesson(code));

/// Capstone assessments available to the learner's track.
final labAssessmentsProvider = FutureProvider<List<LabAssessment>>(
    (ref) => ref.watch(apiClientProvider).getLabAssessments());

/// One assessment paper (scenario, instructions, questions) for the instructions screen.
final assessmentPaperProvider =
    FutureProvider.family<LabAssessmentPaper, String>(
        (ref, code) => ref.watch(apiClientProvider).getAssessmentPaper(code));

class AssessmentKey {
  const AssessmentKey(this.code, this.attemptId);
  final String code;
  final int attemptId;

  @override
  bool operator ==(Object other) =>
      other is AssessmentKey &&
      other.code == code &&
      other.attemptId == attemptId;

  @override
  int get hashCode => Object.hash(code, attemptId);
}

/// Vera's post-capstone report (generated once, cached server-side).
final assessmentAnalysisProvider =
    FutureProvider.family<LabAssessmentAnalysis, AssessmentKey>((ref, key) =>
        ref
            .watch(apiClientProvider)
            .getAssessmentAnalysis(key.code, key.attemptId));
