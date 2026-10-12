import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifai/features/judgement/presentation/judgement_screen.dart';
import 'package:verifai/features/judgement/providers.dart';
import 'package:verifai/shared/models.dart';

const _judgementTask = DailyTask(
  id: 2,
  title: 'The Month-End Agenda',
  scenario: 'You are a junior accountant preparing the agenda.',
  dimension: 'AI Judgement',
  feature: 'judgement',
  format: 'choice',
  options: [
    TaskOption(id: 11, kind: 'decision', label: 'Use AI'),
    TaskOption(id: 12, kind: 'decision', label: 'Use AI with human review'),
    TaskOption(id: 13, kind: 'decision', label: "Don't use AI"),
    TaskOption(id: 14, kind: 'reason', label: 'A. Routine, low-risk work.'),
    TaskOption(id: 15, kind: 'reason', label: 'B. AI always saves time.'),
    TaskOption(id: 16, kind: 'reason', label: 'C. AI looks unprofessional.'),
  ],
);

void main() {
  testWidgets('judgement screen renders the decision and reason sections',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        judgementTaskProvider.overrideWith((ref) async => _judgementTask),
      ],
      child: const MaterialApp(home: JudgementScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('How should AI be used here?'), findsOneWidget);
    expect(find.text('Pick the best reason'), findsOneWidget);
    expect(find.text('Use AI'), findsOneWidget);
    expect(find.text("Don't use AI"), findsOneWidget);
    expect(find.text('B. AI always saves time.'), findsOneWidget);
  });

  testWidgets('submit stays disabled until a decision and reason are picked',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        judgementTaskProvider.overrideWith((ref) async => _judgementTask),
      ],
      child: const MaterialApp(home: JudgementScreen()),
    ));
    await tester.pumpAndSettle();

    // No selection yet: the Submit button is disabled.
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);

    await tester.tap(find.text('Use AI'));
    await tester.tap(find.text('A. Routine, low-risk work.'));
    await tester.pump();

    final enabled = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(enabled.onPressed, isNotNull);
  });
}
