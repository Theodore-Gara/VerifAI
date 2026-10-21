import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/features/task/presentation/task_run_screen.dart';
import 'package:verifai/features/verification/providers.dart';
import 'package:verifai/shared/models.dart';

import '../../support/mock_api_client.dart';

/// Returns a different task per call so a re-fetch is observable, and counts
/// the calls.
class _CountingApiClient extends MockApiClient {
  int nextTaskCalls = 0;

  @override
  Future<DailyTask?> getNextTask({String? feature, String? difficulty}) async {
    nextTaskCalls++;
    return DailyTask(
      id: nextTaskCalls,
      title: 'Task $nextTaskCalls',
      dimension: 'verification',
      difficulty: difficulty ?? 'easy',
      options: const [TaskOption(id: 1, label: 'Fix it')],
    );
  }
}

void main() {
  const task = DailyTask(
    id: 99,
    title: 'Review the output',
    dimension: 'verification',
    format: 'choice',
    difficulty: 'easy',
    options: [TaskOption(id: 7, label: 'Fix it')],
  );

  testWidgets(
      'submitting a task invalidates the verification hub list, so the '
      'answered task is not served again', (tester) async {
    final api = _CountingApiClient();
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);

    // The hub list is loaded and kept alive (the hub stays mounted under the
    // task runner), so it caches an attemptable task.
    await container.read(verificationTasksProvider.future);
    final afterHubLoad = api.nextTaskCalls;
    expect(afterHubLoad, 3);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TaskRunScreen(task: task)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fix it'));
    await tester.pump();
    await tester.tap(find.text('Submit Answer'));
    await tester.pumpAndSettle();

    // Re-reading the hub list re-queries the backend instead of replaying the
    // cached (now answered) task.
    await container.read(verificationTasksProvider.future);
    expect(api.nextTaskCalls, greaterThan(afterHubLoad),
        reason: 'the hub list must be invalidated after a submit');
  });
}
