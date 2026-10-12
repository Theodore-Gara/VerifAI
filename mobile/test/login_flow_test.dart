// Verifies the login error snackbar shows once and Dismiss removes it.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:verifai/features/auth/data/auth_repository.dart';
import 'package:verifai/features/auth/presentation/login_screen.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/shared/models.dart';

/// Minimal stand-in so the login screen can be exercised without Firebase.
/// Login always fails with a Firebase-style wrong-credentials error.
class _FailingAuthRepository implements AuthRepository {
  @override
  Future<AuthResult> login(String email, String password) async {
    throw Exception('firebase_auth/wrong-password');
  }

  @override
  Future<AuthResult> register(
      String email, String password, String name) async {
    throw Exception('firebase_auth/email-already-in-use');
  }

  @override
  Future<AuthResult> signInWithGoogle() async =>
      throw UnimplementedError('not used in this test');

  @override
  Future<void> completeOnboarding() async {}

  @override
  Future<void> logout() async {}

  @override
  Future<User?> getCurrentUser() async => null;

  @override
  Stream<AuthState> authStateChanges() => const Stream.empty();
}

Widget _harness() {
  return ProviderScope(
    overrides: [
      authRepositoryProvider
          .overrideWith((ref) async => _FailingAuthRepository()),
    ],
    child: const MaterialApp(home: LoginScreen()),
  );
}

void main() {
  testWidgets('failed login shows error snackbar and Dismiss removes it',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(_harness());
    await tester.pump();

    await tester.enterText(
        find.byType(TextFormField).at(0), 'nobody@verif.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrongpass');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // error + snackbar

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

    await tester.pumpWidget(_harness());
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
