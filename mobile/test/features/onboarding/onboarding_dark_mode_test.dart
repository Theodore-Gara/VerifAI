// The onboarding screens must read in both themes: the industry picker and
// the welcome tour are the first screens a new learner sees.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_theme.dart';
import 'package:verifai/features/auth/providers.dart';
import 'package:verifai/features/onboarding/presentation/industry_select_screen.dart';
import 'package:verifai/features/onboarding/presentation/welcome_tutorial_screen.dart';

import '../../support/mock_api_client.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Renders [child] under the app's light or dark theme. The palette is a
  /// global the app flips alongside the MaterialApp theme, so the test has to
  /// do the same.
  Widget themed(Widget child, AppPalette palette) {
    AppColors.palette = palette;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => child),
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const Scaffold(body: Text('Dashboard')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(MockApiClient()),
        currentUserProvider.overrideWith((ref) async => null),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.themeFor(palette),
      ),
    );
  }

  tearDown(() => AppColors.palette = AppPalette.light);

  testWidgets('the industry picker renders in dark mode', (tester) async {
    await tester.pumpWidget(
      themed(
        const Scaffold(body: IndustrySelectScreen()),
        AppPalette.dark,
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('What do you work in?'), findsOneWidget);
    expect(find.text('STEP 1 OF 2'), findsOneWidget);
    // No layout errors in dark mode.
    expect(tester.takeException(), isNull);
  });

  testWidgets('the welcome tour renders in dark mode', (tester) async {
    await tester.pumpWidget(
      themed(
        const Scaffold(body: WelcomeTutorialScreen()),
        AppPalette.dark,
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('AI assists.\nHumans verify.'), findsOneWidget);
    expect(find.text('STEP 2 OF 2'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Walk the previews too: each page has to survive the dark palette.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(find.text('EXAMPLE PROGRESS'), findsWidgets);
  });

  testWidgets('the industry picker renders in light mode', (tester) async {
    await tester.pumpWidget(
      themed(
        const Scaffold(body: IndustrySelectScreen()),
        AppPalette.light,
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('What do you work in?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
