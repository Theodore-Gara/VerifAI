import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verifai/features/onboarding/presentation/welcome_tutorial_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget testApp() {
    final router = GoRouter(
      initialLocation: '/welcome-tour',
      routes: [
        GoRoute(
          path: '/welcome-tour',
          builder: (_, __) => const WelcomeTutorialScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (_, __) =>
              const Scaffold(body: Text('Dashboard destination')),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('tutorial has a visible skip action and navigates to dashboard',
      (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    expect(find.text('AI assists.\nHumans verify.'), findsOneWidget);
    expect(find.text('Skip tutorial'), findsOneWidget);
    await tester.tap(find.text('Skip tutorial'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard destination'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(
        preferences.getBool('verifai_welcome_tutorial_completed_v1'), isTrue);
  });

  testWidgets('tutorial can be completed through all five steps',
      (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Start learning'), findsOneWidget);
    await tester.tap(find.text('Start learning'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard destination'), findsOneWidget);
  });
}
