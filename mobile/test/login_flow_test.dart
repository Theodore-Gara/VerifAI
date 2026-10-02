// Verifies the login error snackbar shows once and Dismiss removes it.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:verifai/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('failed login shows error snackbar and Dismiss removes it',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), 'nobody@verif.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrongpass');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // mock delay + error

    expect(find.textContaining('User not found'), findsOneWidget);

    await tester.tap(find.text('Dismiss'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // snackbar exit animation

    expect(find.textContaining('User not found'), findsNothing);
  });

  testWidgets('second failed attempt shows the error again (not stuck)',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), 'nobody@verif.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrongpass');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('User not found'), findsOneWidget);

    // Try again — the button must be enabled and the error re-shown once.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('User not found'), findsOneWidget);
  });
}