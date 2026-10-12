import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifai/core/services/mock_api_client.dart';
import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/features/interview/presentation/interview_practice_screen.dart';
import 'package:verifai/features/interview/providers.dart';

void main() {
  testWidgets('interview screen lists questions and reveals the sample answer',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(MockApiClient()),
      ],
      child: const MaterialApp(home: InterviewPracticeScreen()),
    ));
    // Let the mock client's simulated delay elapse, then settle.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.textContaining('practised'), findsOneWidget);
    expect(find.textContaining('verify an AI-generated legal citation'),
        findsOneWidget);

    // The sample answer is hidden until the question is tapped.
    expect(find.text('SAMPLE ANSWER'), findsNothing);
    await tester.tap(find.textContaining('verify an AI-generated legal citation'));
    await tester.pumpAndSettle();
    expect(find.text('SAMPLE ANSWER'), findsOneWidget);
    expect(find.text('WHAT EMPLOYERS ARE TESTING'), findsOneWidget);
  });
}
