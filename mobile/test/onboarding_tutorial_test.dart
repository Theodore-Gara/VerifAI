// Regression test for the onboarding tutorial bug: after the first page,
// tapping Next used to leave the pager stuck on page 1 (onPageChanged never
// fired with NeverScrollableScrollPhysics), so users could not continue.
// This test walks all five pages via the Continue button and asserts the
// content advances every time, then verifies skip persists completion.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verifai/features/onboarding/presentation/welcome_tutorial_screen.dart';

Widget _harness() {
  return MaterialApp(
    home: Builder(builder: (context) {
      return InheritedGoRouter(
        goRouter: _StubGoRouter.instance,
        child: const WelcomeTutorialScreen(),
      );
    }),
  );
}

/// Minimal GoRouter stand-in so the tutorial's context.go('/dashboard')
/// completes without the full app router (a real navigation is covered by
/// the existing onboarding_flow_test end-to-end case).
class _StubGoRouter implements GoRouter {
  static final _StubGoRouter instance = _StubGoRouter();

  @override
  void go(String location, {Object? extra}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<void> pumpTutorial(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(_harness());
    await tester.pump();
  }

  testWidgets('Continue advances through every tutorial page', (tester) async {
    await pumpTutorial(tester);

    // Page 1: welcome.
    expect(find.text('WELCOME TO VERIFAI'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Continue'), findsOneWidget);

    final continueButton = find.widgetWithText(ElevatedButton, 'Continue');

    for (final eyebrow in [
      '01 · LEARN',
      '02 · VERIFY',
      '03 · GET SUPPORT',
      '04 · GROW',
    ]) {
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      expect(find.text(eyebrow), findsOneWidget);
    }

    // After the last page the primary CTA becomes Start learning.
    expect(
        find.widgetWithText(ElevatedButton, 'Start learning'), findsOneWidget);
    expect(find.text('Skip tutorial'), findsOneWidget);
  });

  testWidgets('Back returns to the previous page', (tester) async {
    await pumpTutorial(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(find.text('01 · LEARN'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('WELCOME TO VERIFAI'), findsOneWidget);
  });

  testWidgets('Skip tutorial persists completion', (tester) async {
    await pumpTutorial(tester);

    // Skip persists the completion flag, then calls context.go('/dashboard').
    // Under the bare MaterialApp harness the go() call fails its GoRouter
    // assertion. Fully-app navigation is covered by the existing
    // onboarding_flow_test, so this harness only asserts the local flag
    // landed (saved before the navigation attempt).
    await tester.tap(find.text('Skip tutorial'));
    await tester.pump();

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool('verifai_welcome_tutorial_completed_v1'),
      isTrue,
    );
  });
}
