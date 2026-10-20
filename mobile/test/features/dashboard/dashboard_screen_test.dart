import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/dashboard/presentation/dashboard_screen.dart';
import 'package:verifai/features/dashboard/providers.dart';
import 'package:verifai/features/navigation/main_nav_shell.dart';
import 'package:verifai/features/task/presentation/task_screen.dart';
import 'package:verifai/shared/models.dart';

DashboardData _dashboard({bool withTask = true}) => DashboardData(
      overallScore: 42,
      dimensionScores: const {'Verification': 60, 'AI Judgement': 30},
      streakDays: 3,
      currentXp: 320,
      level: 4,
      xpIntoLevel: 70,
      xpForNextLevel: 430,
      completedTasks: 7,
      tier: 'Developing',
      dailyTask: withTask
          ? const DailyTask(
              id: 11,
              title: 'The Gross Profit Trap',
              dimension: 'Verification',
              difficulty: 'medium',
            )
          : null,
    );

User _user() => const User(
      id: '1',
      email: 'thabo@example.com',
      name: 'Thabo Mokoena',
      trackName: 'Finance',
      createdAt: '2026-10-01T00:00:00.000Z',
    );

Future<void> _pumpDashboard(
  WidgetTester tester, {
  required DashboardData data,
}) async {
  tester.view.physicalSize = const Size(900, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) async => _user()),
        dashboardProvider.overrideWith((ref) async => data),
      ],
      child: const MaterialApp(home: DashboardScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('Home leads with the next task, XP progress and dimensions',
      (tester) async {
    await _pumpDashboard(tester, data: _dashboard());

    expect(find.text('YOUR NEXT TASK'), findsOneWidget);
    expect(find.text('The Gross Profit Trap'), findsOneWidget);
    expect(find.text('Start task'), findsOneWidget);
    // Level curve numbers come from the server, not a client-side copy.
    expect(find.text('70 / 430 XP'), findsOneWidget);
    expect(find.text('READINESS COMPETENCY INDEX'), findsOneWidget);
    expect(find.text('Day streak'), findsOneWidget);
    // The stat tile is announced as one node, not "3" + "Day streak".
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('3 day streak'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Home falls back to an empty-state CTA when no task is available',
      (tester) async {
    await _pumpDashboard(tester, data: _dashboard(withTask: false));

    expect(find.text('Nothing lined up yet'), findsOneWidget);
    expect(find.text('Open AI Lab'), findsOneWidget);
    expect(find.text('Start task'), findsNothing);
  });

  testWidgets('the shell builds only the tab the learner is on', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) async => _user()),
          dashboardProvider.overrideWith((ref) async => _dashboard()),
        ],
        child: const MaterialApp(home: MainNavShell()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Dashboard is live, the unvisited tabs are still placeholders: an eager
    // IndexedStack resolved every tab's providers on cold start.
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.byType(TaskScreen), findsNothing);
  });
}
