// Basic smoke test for the VerifAI app.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:verifai/main.dart';
import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/services/mock_api_client.dart';

void main() {
  testWidgets('VerifAI app renders the splash screen',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: const VerifAIApp(),
      ),
    );
    await tester.pump();

    // Splash screen shows the tagline while the entry animation plays.
    expect(find.text('AI Workplace Readiness'), findsOneWidget);

    // Let the splash timer fire and the navigation settle so no timers pend.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 5));
  });
}
