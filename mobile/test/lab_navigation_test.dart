import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/services/mock_api_client.dart';
import 'package:verifai/features/lab/presentation/assessment_paper_screen.dart';
import 'package:verifai/features/lab/presentation/topic_reader_screen.dart';
import 'package:verifai/shared/models.dart';

void main() {
  testWidgets('lesson reader advances pages', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(_LabApi())],
      child: const MaterialApp(
        home: LabTopicReaderScreen(code: 'demo', index: 0),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Topic one'), findsOneWidget);
    expect(find.text('Mark as read & finish'), findsNothing);

    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.text('Mark as read & finish'), findsOneWidget);
  });

  testWidgets('assessment paper next button advances questions',
      (tester) async {
    final expiresAt =
        DateTime.now().add(const Duration(minutes: 20)).toIso8601String();
    await tester.pumpWidget(MaterialApp(
      home: ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(_LabApi())],
        child: LabAssessmentPaperScreen(
          args: PaperArgs(
            code: 'demo',
            start: LabAssessmentStart(
              attemptId: 1,
              startedAt: DateTime.now().toIso8601String(),
              expiresAt: expiresAt,
              timeLimitSeconds: 1200,
              passScore: 60,
              totalMarks: 2,
              attemptsRemaining: 2,
              scenario: const {
                'title': 'Case study X',
                'background': 'bg',
                'facts': ['fact one'],
              },
              questions: const [
                LabAssessmentQuestion(
                  id: 1,
                  type: 'multiple_choice',
                  section: 'Section A · Application',
                  prompt: 'First question',
                  marks: 1,
                  payload: {
                    'options': ['A', 'B'],
                    'question_no': 1,
                  },
                ),
                LabAssessmentQuestion(
                  id: 2,
                  type: 'true_false',
                  prompt: 'Second question',
                  marks: 1,
                  payload: {'question_no': 2},
                ),
              ],
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Question 1 of 2'), findsOneWidget);
    expect(find.text('Section A · Application'), findsOneWidget);
    expect(find.text('Case study X'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.text('Question 2 of 2'), findsOneWidget);
    expect(find.text('Submit paper'), findsOneWidget);
    expect(find.text('Section A · Application'), findsNothing);
    expect(find.text('Case study X'), findsOneWidget);
  });
}

class _LabApi extends MockApiClient {
  @override
  Future<LabLessonDetail> getLabLesson(String code) async {
    return LabLessonDetail(
      lesson: LabLesson(id: 1, code: code, title: 'Demo lesson', summary: ''),
      sections: [
        const LabSection(id: 1, heading: 'Chapter one', body: ''),
        const LabSection(id: 2, parentId: 1, heading: 'Topic one', body: ''),
        LabSection(id: 3, parentId: 2, heading: 'A subtopic', body: List.filled(810, 'A').join()),
      ],
    );
  }

  @override
  Future<LabProgress> recordLessonProgress(
    String code, {
    required int sectionsCompleted,
    required int activitiesCompleted,
  }) async {
    return const LabProgress(sectionsCompleted: 1);
  }
}
