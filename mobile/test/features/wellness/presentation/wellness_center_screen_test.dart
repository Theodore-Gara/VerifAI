import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifai/core/providers/app_providers.dart';
import '../../../support/mock_api_client.dart';
import 'package:verifai/features/wellness/presentation/wellness_center_screen.dart';
import 'package:verifai/shared/models.dart';

class _FailingApi extends MockApiClient {
  @override
  Future<List<MoodCheckin>> getMoodCheckins({int limit = 30}) async =>
      throw Exception('offline');

  @override
  Future<List<JournalEntry>> getJournalEntries({int limit = 30}) async =>
      throw Exception('offline');

  @override
  Future<WellnessWeek> getWellnessWeek({int days = 7}) async =>
      throw Exception('offline');
}

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
    await tester.enterText(find.byType(TextField).last, 'I need a quiet moment.');
    await tester.tap(find.text('Save reflection'));
    await _settle(tester);

    expect(find.text('Reflection saved to your account.'), findsOneWidget);
    final entries = await tester.runAsync(() => api.getJournalEntries());
    expect(entries!.single.content, 'I need a quiet moment.');
  });

  testWidgets('saves an optional mood note and shows one check-in in history',
      (tester) async {
    final api = MockApiClient();
    await tester.runAsync(() async {
      await api.saveMoodCheckin('Tired', date: _dateOffset(1), note: 'Long day.');
    });
    await _pumpWellness(tester, api: api);

    expect(find.text('Recent check-ins'), findsOneWidget);
    await tester.tap(find.text('Tired').last);
    await tester.pump();
    expect(find.text('Long day.'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pump();

    await tester.tap(find.text('Calm'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, '  Slow morning  ');
    await tester.pump();
    await tester.tap(find.text('Save my check-in'));
    await _settle(tester);

    final checkins = await tester.runAsync(() => api.getMoodCheckins());
    expect(checkins!.first.mood, 'Calm');
    expect(checkins.first.note, 'Slow morning');
  });

  testWidgets('deletes a reflection and restores it with Undo', (tester) async {
    final api = MockApiClient();
    await tester.runAsync(() async {
      await api.saveJournalEntry('Old reflection', date: _dateOffset(1));
      await api.saveJournalEntry('Second reflection', date: _dateOffset(2));
    });
    await _pumpWellness(tester, api: api);

    await tester.scrollUntilVisible(
      find.text('Journal your thoughts'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Journal your thoughts'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('All entries (2)'));
    await tester.pump();

    final entryTile = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Old reflection'),
        matching: find.byType(ListTile),
      ).first,
    );
    entryTile.onTap!.call();
    await tester.pump();
    await tester.tap(find.text('Delete entry'));
    await tester.pump();
    await tester.tap(find.text('Delete'));
    await tester.pump();
    await _settle(tester);

    expect(find.text('Reflection deleted.'), findsOneWidget);
    var entries = await tester.runAsync(() => api.getJournalEntries());
    expect(entries!.length, 1);

    await tester.tap(find.text('Undo'));
    await _settle(tester);
    entries = await tester.runAsync(() => api.getJournalEntries());
    expect(entries!.length, 2);
  });

  testWidgets('editing a reflection does not inflate the self-care count',
      (tester) async {
    final api = await _pumpWellness(tester);

    await tester.scrollUntilVisible(
      find.text('Journal your thoughts'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    for (final text in ['First draft', 'Edited draft']) {
      await tester.tap(find.text('Journal your thoughts'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.enterText(find.byType(TextField).last, text);
      await tester.tap(find.text('Save reflection'));
      await _settle(tester);
    }

    final week = await tester.runAsync(() => api.getWellnessWeek());
    expect(week!.counts['journal'], 1);
  });

  testWidgets('shows inline errors with retry when wellness data fails',
      (tester) async {
    await _pumpWellness(tester, api: _FailingApi());

    expect(find.text('Could not load your mood history.'), findsOneWidget);
    expect(find.text('Could not load your reflections.'), findsOneWidget);
    expect(find.text('Could not load this week’s self-care.'), findsOneWidget);
    expect(find.text('Retry'), findsWidgets);
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

    // A real session runs at least 10 timer ticks before it can be logged.
    for (var i = 0; i < 11; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.tap(find.text('Finish'));
    await tester.pump();
    await _settle(tester);

    expect(find.text('Logged. Nicely done.'), findsOneWidget);
    expect(find.text('1 self-care moment this week'), findsOneWidget);
  });

  testWidgets('finishing breathing immediately is not logged', (tester) async {
    final api = await _pumpWellness(tester);

    await tester.scrollUntilVisible(
      find.text('Mindful breathing'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Mindful breathing'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Finish'));
    await tester.pump();
    await _settle(tester);

    expect(find.text('Logged. Nicely done.'), findsNothing);
    final week = await tester.runAsync(() => api.getWellnessWeek());
    expect(week!.total, 0);
  });
}
