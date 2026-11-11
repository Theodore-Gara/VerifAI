import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/profile/providers.dart';
import 'package:verifai/main.dart';
import 'package:verifai/shared/models.dart';

import 'support/mock_api_client.dart';

void main() {
  testWidgets('an admin lands in the native admin portal, not the learner app',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    const user = User(
      id: 'admin',
      email: 'admin@verifai.app',
      name: 'Admin',
      createdAt: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(MockApiClient()),
          authStateProvider
              .overrideWith((ref) => Stream.value(const AuthState.authenticated(
                    user: user,
                    token: 'token',
                  ))),
          adminIdentityProvider.overrideWith((ref) async =>
              const AdminIdentity(user: user, isAdmin: true, role: 'admin')),
        ],
        child: const VerifAIApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('VerifAI Admin'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });
}
