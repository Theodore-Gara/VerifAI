// Widget test of the themed feedback banner: showFeedback renders a calm,
// branded banner (never the dark Material snackbar strip) whose Dismiss
// action clears it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifai/shared/widgets/app_feedback_banner.dart';

void main() {
  testWidgets('feedback banner Dismiss clears it', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () => showFeedback(
                  context,
                  FeedbackKind.error,
                  'The email or password is incorrect.',
                  actionLabel: 'Dismiss',
                  onAction: (hide) => hide(),
                ),
                child: const Text('raise'),
              ),
            );
          },
        ),
      ),
    ));

    await tester.tap(find.text('raise'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('email or password is incorrect'), findsOneWidget);

    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();

    expect(find.textContaining('email or password is incorrect'), findsNothing);
  });
}
