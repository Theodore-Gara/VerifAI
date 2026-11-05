import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/onboarding/presentation/welcome_tutorial_screen.dart';

import 'support/mock_api_client.dart';

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
    return ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(MockApiClient()),
        currentUserProvider.overrideWith((ref) async => null),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('tutorial has a visible skip action and navigates to dashboard',
      (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    expect(find.text('AI assists.\nHumans verify.'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard destination'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(
        preferences.getString('verifai_tutorial_current_status_v1'), 'skipped');
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
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('verifai_tutorial_current_status_v1'),
        'completed');
  });

  testWidgets('next stays visible on a narrow screen after advancing',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
  });
}
