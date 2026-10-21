import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/dashboard/presentation/dashboard_screen.dart';
import 'package:verifai/features/dashboard/providers.dart';
import 'package:verifai/features/hubs/presentation/learn_hub_screen.dart';
import 'package:verifai/features/navigation/main_nav_shell.dart';
import 'package:verifai/shared/models.dart';

DashboardData _empty() => const DashboardData(
      overallScore: 0,
      dimensionScores: {'Verification': 60},
      streakDays: 3,
      currentXp: 0,
      level: 1,
      xpIntoLevel: 0,
      xpForNextLevel: 100,
      completedTasks: 0,
      tier: 'Novice',
    );

User _user() => const User(
      id: '1',
      email: 'thabo@example.com',
      name: 'Thabo Mokoena',
      trackName: 'Finance',
      createdAt: '2026-10-01T00:00:00.000Z',
    );

void main() {
  testWidgets('re-entering a hub from a quick-launch tile after leaving works',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const MainNavShell(initialIndex: 0),
        ),
        GoRoute(
          path: '/learn',
          builder: (_, __) => const MainNavShell(initialIndex: 1),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) async => _user()),
          dashboardProvider.overrideWith((ref) async => _empty()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // First tap on the Learn tile.
    await tester.tap(find.text('Learn').first);
    await tester.pumpAndSettle();
    expect(find.byType(LearnHubScreen), findsOneWidget, reason: 'first tap');

    // Back to the dashboard tab (in-shell, as the dock does).
    await tester.tap(find.byIcon(Icons.home_rounded).last);
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget, reason: 'back home');

    // Second tap on the Learn tile.
    await tester.tap(find.text('Learn').first);
    await tester.pumpAndSettle();
    expect(find.byType(LearnHubScreen), findsOneWidget, reason: 'second tap');
  });
}
