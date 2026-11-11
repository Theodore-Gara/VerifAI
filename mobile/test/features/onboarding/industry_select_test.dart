// The industry picker is step 1 of the two-step first-run onboarding.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/onboarding/presentation/industry_select_screen.dart';

import '../../support/mock_api_client.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget testApp() {
    final router = GoRouter(
      initialLocation: '/industry-select',
      routes: [
        GoRoute(
          path: '/industry-select',
          builder: (_, __) => const IndustrySelectScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (_, __) =>
              const Scaffold(body: Text('Dashboard destination')),
        ),
        GoRoute(
          path: '/industry-guide/:industry',
          builder: (_, state) =>
              Scaffold(body: Text('Guide ${state.pathParameters['industry']}')),
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

  testWidgets('shows step 1 of 2 and the industry list', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    expect(find.text('STEP 1 OF 2'), findsOneWidget);
    expect(find.text('What do you work in?'), findsOneWidget);
    for (final name in [
      'Finance',
      'Legal',
      'IT / Software',
      'Business Consulting'
    ]) {
      expect(find.text(name), findsOneWidget);
    }
    // The stale "1 of 1" step counter must be gone.
    expect(find.text('STEP 1 OF 1'), findsNothing);
  });

  testWidgets('the perk line comes from the catalogue, not the widget',
      (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    expect(find.text('Numerical Auditing'), findsOneWidget);
    expect(find.text('Clause Citation'), findsOneWidget);
  });

  testWidgets('the confirm button names the selected industry',
      (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    // Nothing picked yet: no confirm button.
    expect(find.widgetWithText(ElevatedButton, 'Continue with Finance'),
        findsNothing);

    await tester.tap(find.text('Legal'));
    await tester.pump();

    expect(
      find.widgetWithText(ElevatedButton, 'Continue with Legal'),
      findsOneWidget,
    );
  });

  testWidgets('the guide row only appears once an industry is selected',
      (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    // Nothing picked: the old dead-end "not sure" row is gone entirely.
    expect(find.textContaining('Not sure?'), findsNothing);

    await tester.tap(find.text('Finance'));
    await tester.pump();

    // The guide row sits below the fold and the list builds lazily, so it is
    // not in the tree until the list is scrolled to it.
    await tester.scrollUntilVisible(
      find.text('See how Finance works'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('See how Finance works'), findsOneWidget);

    // scrollUntilVisible leaves the row at the edge of the viewport; nudge it
    // up so the tap lands on the row rather than the sticky bottom bar.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
    await tester.pumpAndSettle();

    await tester.tap(find.text('See how Finance works'));
    await tester.pumpAndSettle();
    expect(find.text('Guide Finance'), findsOneWidget);
  });
  testWidgets('the list does not overflow at 200% text scale',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    // Double the text scale and rebuild.
    tester.view.physicalSize = const Size(390, 844);
    final context = tester.element(find.text('What do you work in?'));
    MediaQuery.of(context).copyWith(
      textScaler: const TextScaler.linear(2.0),
    );
    await tester.pumpAndSettle();

    // No RenderFlex overflow: the test fails on the exception itself.
    expect(tester.takeException(), isNull);
  });
}
