import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/profile/providers.dart';
import 'package:verifai/main.dart';
import 'package:verifai/shared/models.dart';

import 'support/mock_api_client.dart';

/// A backend that has not woken up yet: every call fails like a Render cold
/// start that outlives the request timeout.
class _ColdApiClient extends MockApiClient {
  @override
  Future<AdminIdentity> getMe() async => throw Exception('cold start');
}

const _user = User(
  id: 'admin',
  email: 'admin@verifai.app',
  name: 'Admin',
  createdAt: '',
);

Widget _app(List<Override> overrides) => ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(MockApiClient()),
        authStateProvider.overrideWith(
          (ref) => Stream.value(
            const AuthState.authenticated(user: _user, token: 'token'),
          ),
        ),
        ...overrides,
      ],
      child: const VerifAIApp(),
    );

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an admin lands in the native admin portal, not the learner app',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(
      _app([adminRoleProvider.overrideWith((ref) async => 'admin')]),
    );
    await _settle(tester);

    expect(find.text('VerifAI Admin'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets(
      'a cached admin stays in the portal when the backend is cold on restart',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      // Written at sign-in by the auth repository; the router must trust it
      // instead of asking a sleeping backend.
      'admin_role': 'admin',
    });

    await tester.pumpWidget(ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(_ColdApiClient()),
        authStateProvider.overrideWith(
          (ref) => Stream.value(
            const AuthState.authenticated(user: _user, token: 'token'),
          ),
        ),
      ],
      child: const VerifAIApp(),
    ));
    await _settle(tester);

    expect(find.text('VerifAI Admin'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });
}
