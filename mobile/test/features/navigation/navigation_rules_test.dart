import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/dashboard/providers.dart';
import 'package:verifai/features/navigation/main_nav_shell.dart';
import 'package:verifai/features/navigation/sections.dart' hide shellTabRoutes;
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/verifai_page_scaffold.dart';

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

void main() {
  group('destination index integrity', () {
    test('every dock route is in the index exactly once', () {
      for (final route in shellTabRoutes) {
        final matches = allSections.where((s) => s.route == route).toList();
        expect(matches, hasLength(1),
            reason: '$route must appear exactly once in allSections');
      }
    });

    test('no duplicate routes in the index', () {
      final routes = allSections.map((s) => s.route).toSet();
      expect(routes, hasLength(allSections.length));
    });

    test('industry guides are in the shared destination index', () {
      expect(
        allSections.map((section) => section.route),
        containsAll([
          '/industry-guide/Finance',
          '/industry-guide/Legal',
          '/industry-guide/IT%20%2F%20Software',
          '/industry-guide/Business%20Consulting',
        ]),
      );
    });

    test('shellTabIndexFor maps each dock route to its dock index', () {
      expect(shellTabIndexFor('/dashboard'), 0);
      expect(shellTabIndexFor('/learn'), 1);
      expect(shellTabIndexFor('/practice'), 2);
      expect(shellTabIndexFor('/progress'), 3);
      expect(shellTabIndexFor('/profile'), 4);
      expect(shellTabIndexFor('/rewards'), isNull);
    });

    test('index covers the areas the dock promises', () {
      final sections = allSections.map((s) => s.section).toSet();
      expect(sections,
          containsAll(['Home', 'Learn', 'Practice', 'Progress', 'Profile']));
      expect(sections, contains('Help & information'));
      expect(sections, hasLength(6));
    });
  });

  group('VerifaiPageScaffold', () {
    testWidgets('exposes back, home and all-sections actions', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: VerifaiPageScaffold(
          title: 'Scoreboard',
          body: SizedBox.shrink(),
        ),
      ));

      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.byTooltip('Home'), findsOneWidget);
      expect(find.byTooltip('All sections'), findsOneWidget);
      expect(find.text('Scoreboard'), findsOneWidget);
    });

    testWidgets('All sections opens the full destination sheet',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: VerifaiPageScaffold(
          title: 'Scoreboard',
          body: SizedBox.shrink(),
        ),
      ));

      await tester.tap(find.byTooltip('All sections'));
      await tester.pumpAndSettle();

      expect(find.text('All sections'), findsOneWidget);
      // The sheet's list is lazy: rows only exist once scrolled into view, and
      // scrolling on disposes rows above. Walk down the list in order.
      final scrollable = find.byType(Scrollable).last;
      for (final area in ['LEARN', 'PRACTICE', 'PROGRESS', 'PROFILE']) {
        await tester.scrollUntilVisible(find.text(area), 120,
            scrollable: scrollable);
        await tester.pumpAndSettle();
        expect(find.text(area), findsOneWidget);
      }
      await tester.scrollUntilVisible(find.text('Change industry'), 120,
          scrollable: scrollable);
      await tester.pumpAndSettle();
      expect(find.text('Change industry'), findsOneWidget,
          reason: 'industry change must be reachable from the sheet');
    });

    testWidgets('Home from a pushed route leaves the pushed screen',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/scoreboard',
        routes: [
          GoRoute(
            path: '/scoreboard',
            builder: (context, state) => const VerifaiPageScaffold(
              title: 'Scoreboard',
              body: SizedBox.shrink(),
            ),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('DASHBOARD HOME'))),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Home'));
      await tester.pumpAndSettle();

      // The pushed screen is gone; the dashboard route is showing.
      expect(find.text('Scoreboard'), findsNothing);
      expect(find.text('DASHBOARD HOME'), findsOneWidget);
    });
  });

  group('drawer', () {
    testWidgets('drawer lists change industry and log out', (tester) async {
      await _pumpShell(tester);

      await tester.tap(find.byIcon(Icons.menu_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('Change industry'), findsOneWidget);
      expect(find.text('Log out'), findsOneWidget);
      // The complete index is in the drawer too.
      expect(find.text('Task history'), findsOneWidget);
    });

    testWidgets(
        'log out asks for confirmation and cancelling keeps the shell',
        (tester) async {
      await _pumpShell(tester);

      await tester.tap(find.byIcon(Icons.menu_rounded).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      expect(find.text('Log out?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      // Shell still mounted — no forced sign-out happened.
      expect(find.byType(MainNavShell), findsOneWidget);
    });
  });
}

Future<void> _pumpShell(WidgetTester tester) async {
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
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}
