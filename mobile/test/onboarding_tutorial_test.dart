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

  Widget testApp({List<GoRoute> extraRoutes = const []}) {
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
        ...extraRoutes,
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

  testWidgets('tutorial shows step 2 of the two-step onboarding',
      (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    expect(find.text('STEP 2 OF 2'), findsOneWidget);
    expect(find.text('Page 1 of 4'), findsOneWidget);
  });

  testWidgets('page 3 previews the readiness profile', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    // Advance to the skills page.
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // The sample is labelled, so the learner knows it is an illustration
    // rather than their own score.
    expect(find.text('EXAMPLE PROFILE'), findsOneWidget);
    expect(find.text('Verification'), findsOneWidget);
    expect(find.text('AI Judgement'), findsOneWidget);
    expect(find.text('Risk & Governance'), findsOneWidget);
  });

  testWidgets('page 4 previews the progress profile', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }

    expect(find.text('EXAMPLE PROGRESS'), findsWidgets);
    // The AI Practitioner level bar is the real component.
    expect(find.text('AI Practitioner'), findsOneWidget);
    expect(find.text('Practice activity'), findsOneWidget);
  });

  testWidgets('tutorial has a visible skip action and navigates to dashboard',
      (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    expect(find.text('AI assists.\nHumans verify.'), findsOneWidget);
    expect(find.text('Skip tour'), findsOneWidget);

    // Skipping asks for confirmation first.
    await tester.tap(find.text('Skip tour'));
    await tester.pumpAndSettle();
    expect(find.text('Skip the tour?'), findsOneWidget);

    // Backing out of the dialog keeps the learner in the tour.
    await tester.tap(find.text('Keep going'));
    await tester.pumpAndSettle();
    expect(find.text('Skip the tour?'), findsNothing);

    await tester.tap(find.text('Skip tour'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Skip tour'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard destination'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(
        preferences.getString('verifai_tutorial_current_status_v1'), 'skipped');
  });

  testWidgets('tutorial can be completed through all four steps',
      (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
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
    // The tour's product preview is a live request; let it land before the
    // tree is torn down so no timer outlives the test.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('back from the tour returns to the industry picker',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/welcome-tour',
      routes: [
        GoRoute(
          path: '/welcome-tour',
          builder: (_, __) => const WelcomeTutorialScreen(),
        ),
        GoRoute(
          path: '/industry-select',
          builder: (_, __) => const Scaffold(body: Text('Industry picker')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(MockApiClient()),
          currentUserProvider.overrideWith((ref) async => null),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Industry picker'), findsOneWidget);
  });
}
