import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/support/presentation/support_screens.dart';
import 'package:verifai/shared/models.dart';

import 'support/mock_api_client.dart';

void main() {
  testWidgets('contact form validates and shows the ticket reference',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/support/contact',
      routes: [
        GoRoute(
          path: '/support/contact',
          builder: (context, state) => const ContactSupportScreen(),
        ),
        GoRoute(
          path: '/support/tickets/:ref',
          builder: (context, state) =>
              Scaffold(body: Text(state.pathParameters['ref'] ?? '')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(MockApiClient()),
          currentUserProvider.overrideWith((ref) async => const User(
                id: '1',
                email: 'learner@verifai.app',
                name: 'Learner',
                createdAt: '',
              )),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Learner');
    await tester.enterText(fields.at(1), 'learner@verifai.app');
    await tester.enterText(fields.at(2), 'A problem');
    await tester.enterText(
        fields.at(3), 'This is a detailed description of the problem.');
    final send = find.widgetWithText(FilledButton, 'Send request');
    await tester.ensureVisible(send);
    await tester.pumpAndSettle();
    await tester.tap(send);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.textContaining('VF-MOCK1234'), findsOneWidget);
  });
}
