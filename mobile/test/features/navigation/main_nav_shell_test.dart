import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/dashboard/providers.dart';
import 'package:verifai/features/hubs/presentation/learn_hub_screen.dart';
import 'package:verifai/features/hubs/presentation/practice_hub_screen.dart';
import 'package:verifai/features/navigation/main_nav_shell.dart';
import 'package:verifai/shared/models.dart';

DashboardData _dashboard() => const DashboardData(
      overallScore: 42,
      dimensionScores: {'Verification': 60},
      streakDays: 3,
      currentXp: 320,
      level: 4,
      xpIntoLevel: 70,
      xpForNextLevel: 430,
      completedTasks: 7,
      tier: 'Developing',
    );

User _user() => const User(
      id: '1',
      email: 'thabo@example.com',
      name: 'Thabo Mokoena',
      trackName: 'Finance',
      createdAt: '2026-10-01T00:00:00.000Z',
    );

Future<void> _pumpShell(WidgetTester tester, {double textScale = 1.0}) async {
  tester.view.physicalSize = const Size(900, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) async => _user()),
        dashboardProvider.overrideWith((ref) async => _dashboard()),
      ],
      child: MaterialApp(
        home: MediaQuery.withNoTextScaling(
          child: const MainNavShell(),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('the dock carries the five areas of the new layout',
      (tester) async {
    await _pumpShell(tester);

    final semantics = tester.ensureSemantics();
    for (final label in ['Home', 'Learn', 'Practice', 'Progress', 'Profile']) {
      expect(find.bySemanticsLabel(RegExp('^$label')), findsWidgets,
          reason: 'missing $label tab');
    }
    semantics.dispose();
  });

  testWidgets('Learn and Practice open their hubs', (tester) async {
    await _pumpShell(tester);

    final semantics = tester.ensureSemantics();
    await tester.tap(find.byIcon(Icons.menu_book_rounded).last);
    await tester.pumpAndSettle();
    expect(find.byType(LearnHubScreen), findsOneWidget);
    expect(find.text('AI Lab lessons'), findsOneWidget);
    expect(find.text('Capstone assessments'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_circle_outline_rounded).last);
    await tester.pumpAndSettle();
    expect(find.byType(PracticeHubScreen), findsOneWidget);
    expect(find.text('SKILL SCENARIOS'), findsOneWidget);
    expect(find.text('Verification Studio'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Home, Learn and Practice survive a 200% text scale',
      (tester) async {
    // Regression guard for the text-scale audit: fixed-height cards and
    // aspect-ratio grids used to overflow once the OS text setting doubled.
    await _pumpShell(tester, textScale: 2.0);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.menu_book_rounded).last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.play_circle_outline_rounded).last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the drawer is still available as a secondary index',
      (tester) async {
    await _pumpShell(tester);

    await tester.tap(find.byTooltip('All sections'));
    await tester.pumpAndSettle();

    expect(find.text('LEARN'), findsOneWidget);
    expect(find.text('PRACTICE'), findsOneWidget);
    expect(find.text('Learn hub'), findsOneWidget);
    expect(find.text('Task history'), findsOneWidget);
  });
}
