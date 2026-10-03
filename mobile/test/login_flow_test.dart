// Verifies the login error snackbar shows once and Dismiss removes it.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:verifai/features/auth/presentation/login_screen.dart';
import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/services/mock_api_client.dart';

void main() {
  testWidgets('failed login shows error snackbar and Dismiss removes it',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();

    await tester.enterText(
        find.byType(TextFormField).at(0), 'nobody@verif.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrongpass');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // mock delay + error

    expect(
        find.textContaining('email or password is incorrect'), findsOneWidget);

    await tester.tap(find.text('Dismiss'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // snackbar exit animation

    expect(find.textContaining('email or password is incorrect'), findsNothing);
  });

  testWidgets('second failed attempt shows the error again (not stuck)',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();

    await tester.enterText(
        find.byType(TextFormField).at(0), 'nobody@verif.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrongpass');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
        find.textContaining('email or password is incorrect'), findsOneWidget);

    // Try again — the button must be enabled and the error re-shown once.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
        find.textContaining('email or password is incorrect'), findsOneWidget);
  });
}
