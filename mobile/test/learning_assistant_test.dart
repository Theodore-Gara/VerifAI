import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/services/mock_api_client.dart';
import 'package:verifai/features/assistant/presentation/learning_assistant_screen.dart';
import 'package:verifai/shared/models/daily_task.dart';

void main() {
  testWidgets('assistant offers task-scoped help and replies to a prompt',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: const MaterialApp(
          home: LearningAssistantScreen(
            task: DailyTask(
              id: 7,
              title: 'Review the forecast',
              scenario: 'The forecast ignores a new competitor.',
              dimension: 'verification',
              trackName: 'Finance',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Learning Assistant'), findsOneWidget);
    expect(find.text('Review the forecast'), findsOneWidget);
    await tester.tap(find.text('Can you give me a hint?'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Can you give me a hint?'), findsOneWidget);
    expect(find.textContaining('Start by identifying the specific claim'),
        findsOneWidget);
  });
}
