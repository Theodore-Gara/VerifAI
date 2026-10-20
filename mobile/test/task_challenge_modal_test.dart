import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifai/core/providers/app_providers.dart';
import 'support/mock_api_client.dart';
import 'package:verifai/features/task/presentation/task_run_screen.dart';
import 'package:verifai/shared/models/daily_task.dart';

void main() {
  testWidgets('choice task renders backend options and issue', (tester) async {
    const task = DailyTask(
      id: 42,
      title: 'Review the forecast',
      scenario: 'The forecast claims revenue will rise.',
      dimension: 'verification',
      embeddedFlaw: 'It uses an outdated comparison period.',
      options: [
        TaskOption(id: 101, label: 'Check the underlying records.'),
        TaskOption(id: 102, label: 'Approve the forecast immediately.'),
      ],
    );

    await tester.pumpWidget(_taskHarness(task));
    await tester.pumpAndSettle();

    expect(find.text('It uses an outdated comparison period.'), findsOneWidget);
    expect(find.text('Check the underlying records.'), findsOneWidget);
    expect(find.text('Approve the forecast immediately.'), findsOneWidget);
  });

  testWidgets('line-text task renders selectable AI output lines',
      (tester) async {
    const task = DailyTask(
      id: 43,
      title: 'Check the calculation',
      dimension: 'verification',
      format: 'line_text',
      aiOutputLines: [
        'Revenue increased by 15%.',
        'The comparison uses the current quarter.',
      ],
    );

    await tester.pumpWidget(_taskHarness(task));
    await tester.pumpAndSettle();

    expect(find.textContaining('Revenue increased by 15%.'), findsOneWidget);
    expect(find.textContaining('The comparison uses the current quarter.'),
        findsOneWidget);
    expect(find.text('How would you correct the output?'), findsOneWidget);
    expect(find.text('Why is this correction needed?'), findsOneWidget);
  });
}

Widget _taskHarness(DailyTask task) {
  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
    child: MaterialApp(home: TaskRunScreen(task: task)),
  );
}
