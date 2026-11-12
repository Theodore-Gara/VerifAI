// End-to-end wiring test: a returning user who hasn't picked a track yet
// lands on industry select, picks a track, taps Continue and reaches the
// dashboard (the router used to bounce /dashboard back to industry select).

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:verifai/main.dart';
import 'package:verifai/core/providers/app_providers.dart';
import 'support/mock_api_client.dart';

void main() {
  testWidgets('onboarding Continue takes the user to the dashboard',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'mock_users': jsonEncode({
        'theo@verif.com': {
          'id': 'seed-theo',
          'email': 'theo@verif.com',
          'password': 'password123',
          'name': 'Theodore Nangara',
          'trackId': null,
          'trackName': null,
          'hasCompletedOnboarding': false,
          'createdAt': '2026-09-01T00:00:00.000Z',
        },
      }),
    });
    FlutterSecureStorage.setMockInitialValues({
      'auth_token': 'mock_token',
      'user_id': 'seed-theo',
      'user_email': 'theo@verif.com',
      'user_name': 'Theodore Nangara',
      'has_completed_onboarding': 'false',
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: const VerifAIApp(),
      ),
    );
    await tester.pump();

    // Splash screen first.
    expect(find.text('AI assists. Humans verify.'), findsOneWidget);

    // Splash timer navigates to industry select.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('What do you work in?'), findsOneWidget);

    // The industry picker is step 1 of the two-step onboarding.
    expect(find.text('STEP 1 OF 2'), findsOneWidget);

    // Pick the Finance track.
    await tester.tap(find.text('Finance'));
    await tester.pump();

    // The confirm button names the chosen industry.
    expect(
      find.widgetWithText(ElevatedButton, 'Continue with Finance'),
      findsOneWidget,
    );

    // Continue → first-run tutorial.
    await tester
        .tap(find.widgetWithText(ElevatedButton, 'Continue with Finance'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2)); // track save + backend sync
    await tester.pumpAndSettle();

    // The tour is step 2 of the same two-step onboarding.
    expect(find.text('STEP 2 OF 2'), findsOneWidget);
    expect(find.text('Skip tour'), findsOneWidget);

    // Skipping asks first, so the tour is not dropped by a stray tap.
    await tester.tap(find.text('Skip tour'));
    await tester.pumpAndSettle();
    expect(find.text('Skip the tour?'), findsOneWidget);
    await tester.tap(find.text('Skip tour').last);
    await tester.pumpAndSettle();

    // Flush the dashboard's mock fetch (MockApiClient delays 300-800ms
    // randomly); pumpAndSettle alone can finish before the timer fires,
    // leaving a pending timer that fails the test.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Home').first, findsOneWidget);
    expect(find.text('What do you work in?'), findsNothing);
  });

  testWidgets('the industry guide opens from the selector and keeps the pick',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      'auth_token': 'mock_token',
      'user_id': 'seed-theo',
      'user_email': 'theo@verif.com',
      'has_completed_onboarding': 'false',
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: const VerifAIApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3)); // splash
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('What do you work in?'), findsOneWidget);

    // Nothing picked yet: no dead-end "not sure" row.
    expect(find.textContaining('Not sure?'), findsNothing);

    await tester.tap(find.text('Finance'));
    await tester.pumpAndSettle();

    // Selecting a track auto-scrolls to the guide row, so it is reachable
    // without hunting for it under the continue bar.
    final guideLink = find.text('See how Finance works');
    await tester.tap(guideLink);
    await tester.pumpAndSettle();

    // The guide opens instead of bouncing back to a fresh selector.
    expect(find.text('Finance guide'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // Back on the selector with the choice still made (the list stays scrolled,
    // so assert on the app bar and the confirm button rather than the hero).
    expect(find.text('Set up your path'), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'Continue with Finance'),
      findsOneWidget,
    );
  });

  testWidgets('track cards fit without overflow on a phone-size screen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532); // 390x844 logical @3x
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      'auth_token': 'mock_token',
      'user_id': '1',
      'user_email': 'theo@verif.com',
      'has_completed_onboarding': 'false',
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: const VerifAIApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3)); // splash
    await tester.pump(const Duration(seconds: 1));

    // No RenderFlex overflow exceptions allowed — the test fails otherwise.
    expect(find.text('What do you work in?'), findsOneWidget);
    for (final name in [
      'Finance',
      'Legal',
      'IT / Software',
      'Business Consulting'
    ]) {
      expect(find.text(name), findsOneWidget);
    }
  });
}
