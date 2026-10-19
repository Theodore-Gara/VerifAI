import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verifai/features/wellness/presentation/wellness_center_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('saves a mood check-in on the device', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: WellnessCenterScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Great'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Save my check-in'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save my check-in'));
    await tester.pumpAndSettle();

    expect(find.text('Check-in saved on this device'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    expect(preferences.getString('wellness_mood_$today'), 'Great');
  });

  testWidgets('saves a journal reflection on the device', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: WellnessCenterScreen()),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Journal your thoughts'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Journal your thoughts'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'I need a quiet moment.',
    );
    await tester.tap(find.text('Save reflection on this device'));
    await tester.pumpAndSettle();

    expect(find.text('Reflection saved on this device.'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    expect(
      preferences.getString('wellness_journal_$today'),
      'I need a quiet moment.',
    );
  });
}
