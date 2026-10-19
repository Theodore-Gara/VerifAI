import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/services/mock_api_client.dart';
import 'package:verifai/features/wellness/presentation/wellness_center_screen.dart';

String _dateOffset(int days) =>
    DateTime.now().subtract(Duration(days: days)).toIso8601String().substring(0, 10);

// Advances the fake clock past the mock client's simulated delays without
// relying on pumpAndSettle (the breathing sheet animates continuously).
Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}

Future<MockApiClient> _pumpWellness(WidgetTester tester, {MockApiClient? api}) async {
  final client = api ?? MockApiClient();
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(client)],
    child: const MaterialApp(home: WellnessCenterScreen()),
  ));
  await _settle(tester);
  return client;
}

void main() {
  testWidgets('saves a mood check-in and shows recent history', (tester) async {
    final api = MockApiClient();
    // Real async outside the fake test clock, so the mock's delay elapses.
    await tester.runAsync(() async {
      await api.saveMoodCheckin('Calm', date: _dateOffset(1));
      await api.saveMoodCheckin('Tired', date: _dateOffset(2));
    });
    await _pumpWellness(tester, api: api);

    expect(find.text('Recent check-ins'), findsOneWidget);

    await tester.tap(find.text('Great'));
    await tester.pump();
    await tester.tap(find.text('Save my check-in'));
    await _settle(tester);

    expect(find.text('Check-in saved.'), findsOneWidget);
    expect(find.text('Check-in saved'), findsOneWidget);

    final checkins = await tester.runAsync(() => api.getMoodCheckins());
    expect(checkins!.first.mood, 'Great');
    expect(checkins.first.date, DateTime.now().toIso8601String().substring(0, 10));
  });

  testWidgets('saves a journal reflection to the account', (tester) async {
    final api = await _pumpWellness(tester);

    await tester.scrollUntilVisible(
      find.text('Journal your thoughts'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Journal your thoughts'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), 'I need a quiet moment.');
    await tester.tap(find.text('Save reflection'));
    await _settle(tester);

    expect(find.text('Reflection saved to your account.'), findsOneWidget);
    final entries = await tester.runAsync(() => api.getJournalEntries());
    expect(entries!.single.content, 'I need a quiet moment.');
  });

  testWidgets('a completed breathing exercise is logged for the week',
      (tester) async {
    await _pumpWellness(tester);

    await tester.scrollUntilVisible(
      find.text('Mindful breathing'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Mindful breathing'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('One mindful minute'), findsOneWidget);

    await tester.tap(find.text('Finish'));
    await tester.pump();
    await _settle(tester);

    expect(find.text('Logged. Nicely done.'), findsOneWidget);
    expect(find.text('1 self-care moment this week'), findsOneWidget);
  });
}
