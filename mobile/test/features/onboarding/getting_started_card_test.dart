// The "Getting started" card exists for learners who skipped the tour. A
// learner who completed the whole onboarding does not need it.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/onboarding/providers.dart';
import 'package:verifai/shared/models.dart';
import 'package:verifai/shared/widgets/getting_started_card.dart';

import '../../support/mock_api_client.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget testApp({TutorialState? serverState}) {
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const Scaffold(body: GettingStartedCard()),
        ),
        GoRoute(
          path: '/welcome-tour',
          builder: (_, __) => const Scaffold(body: Text('Tour')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(MockApiClient()),
        currentUserProvider.overrideWith((ref) async => null),
        if (serverState != null)
          tourStateProvider.overrideWith(
            (ref) async => serverState,
          ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('a skipped tour shows the card', (tester) async {
    await tester.pumpWidget(
      testApp(serverState: const TutorialState(status: 'skipped')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Getting started'), findsOneWidget);
  });

  testWidgets('a completed tour hides the card', (tester) async {
    await tester.pumpWidget(
      testApp(serverState: const TutorialState(status: 'completed')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Getting started'), findsNothing);
  });

  testWidgets('a tour never taken shows the card', (tester) async {
    await tester.pumpWidget(
      testApp(serverState: const TutorialState(status: null)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Getting started'), findsOneWidget);
  });

  testWidgets('a locally completed tour hides the card when the fetch fails',
      (tester) async {
    // The server is unreachable, so the card falls back to local storage.
    SharedPreferences.setMockInitialValues({
      'verifai_tutorial_current_status_v1': 'completed',
    });

    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    expect(find.text('Getting started'), findsNothing);
  });
}
