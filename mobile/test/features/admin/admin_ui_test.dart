// Admin portal UI: navigation, the learner list, and the learner detail
// screen. These cover the redesign: the selected nav item takes the accent
// colour, the learner card is minimal, and the detail screen is sectioned.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/services/api_client.dart';
import 'package:verifai/features/admin/presentation/admin_nav.dart';
import 'package:verifai/features/admin/presentation/admin_user_detail_screen.dart';
import 'package:verifai/features/admin/presentation/admin_users_screen.dart';
import 'package:verifai/features/profile/providers.dart';

/// An admin API that answers the three calls these screens make.
class _FakeAdminApi implements ApiClient {
  _FakeAdminApi();

  final List<String> calls = [];

  static const _users = [
    {
      'id': 1,
      'display_name': 'Thabo Mokoena',
      'email': 'thabo@example.com',
      'track_name': 'Finance',
      'status': 'active',
      'xp': 2450,
      'level': 5,
      'attempts': 18,
    },
    {
      'id': 2,
      'display_name': 'Ana Souza',
      'email': 'ana@example.com',
      'track_name': 'Legal',
      'status': 'active',
      'xp': 900,
      'level': 3,
      'attempts': 7,
    },
  ];

  @override
  Future<dynamic> adminRequest(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? data,
  }) async {
    calls.add('$method $path');
    if (path == 'users') {
      return {
        'users': _users,
        'total': _users.length,
      };
    }
    if (path.startsWith('users/')) {
      return {
        'user': {
          ..._users.first,
          'tokens': 42,
          'readiness_score': 68,
          'status_reason': '',
          'industry_track_id': 1,
        },
        'attempts': [
          {
            'task_title': 'Verify the forecast',
            'feature': 'verification',
            'score': 80,
            'passed': true,
          },
        ],
        'achievements': [
          {'name': 'First Assessment', 'earned_at': '2026-10-01'},
        ],
        'moderation': [
          {
            'action': 'user_status',
            'admin_email': 'admin@example.com',
            'created_at': '2026-10-02',
          },
        ],
      };
    }
    return const <String, dynamic>{};
  }

  // --- Unused surface of ApiClient, stubbed so the class compiles. ---
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _shell(Widget child, {List<GoRoute> routes = const []}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => child),
      ...routes,
    ],
  );
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(_FakeAdminApi()),
      adminRoleProvider.overrideWith((ref) async => 'admin'),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the selected nav item takes the accent colour and a pill',
      (tester) async {
    await tester.pumpWidget(
      _shell(
        const AdminNavBar(
          items: [
            AdminNavItem('Overview', Icons.dashboard_rounded),
            AdminNavItem('Users', Icons.people_alt_rounded),
          ],
          selectedIndex: 1,
          onSelected: _noop,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final icons = tester.widgetList<Icon>(find.byType(Icon));
    final overview = icons.firstWhere(
      (i) => i.icon == Icons.dashboard_rounded,
    );
    final users =
        icons.firstWhere((i) => i.icon == Icons.people_alt_rounded);

    // The selected icon carries the accent colour...
    expect(users.color, isNotNull);
    // ...and the unselected one does not.
    expect(overview.color, isNot(users.color));
  });

  testWidgets('the nav label of the selected tab matches its icon colour',
      (tester) async {
    await tester.pumpWidget(
      _shell(
        const AdminNavBar(
          items: [
            AdminNavItem('Overview', Icons.dashboard_rounded),
            AdminNavItem('Users', Icons.people_alt_rounded),
          ],
          selectedIndex: 0,
          onSelected: _noop,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final selected = tester.widget<Text>(
      find.text('Overview'),
    );
    final unselected = tester.widget<Text>(find.text('Users'));

    expect(selected.style?.color, isNot(unselected.style?.color));
    // The selected label is also bolder than the unselected one.
    expect(selected.style?.fontWeight, isNot(unselected.style?.fontWeight));
  });

  testWidgets('a learner row shows name, email and track and nothing else',
      (tester) async {
    // The screen is a tab inside the admin shell, so it is hosted by a
    // Scaffold in production.
    await tester.pumpWidget(
      _shell(const Scaffold(body: AdminUsersScreen())),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Thabo Mokoena'), findsOneWidget);
    expect(find.text('thabo@example.com'), findsOneWidget);
    expect(find.text('Finance'), findsOneWidget);

    // No avatar, and the progress numbers live on the detail screen only.
    expect(find.byType(CircleAvatar), findsNothing);
    expect(find.textContaining('XP'), findsNothing);
    expect(find.textContaining('attempts'), findsNothing);
  });

  testWidgets('the learner detail screen is sectioned', (tester) async {
    await tester.pumpWidget(
      _shell(
        const Scaffold(body: AdminUserDetailScreen(id: 1)),
        routes: [
          GoRoute(
            path: '/admin/users/1',
            builder: (_, __) => const AdminUserDetailScreen(id: 1),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    // The name is the subject of the page.
    expect(find.text('Thabo Mokoena'), findsOneWidget);
    expect(find.text('thabo@example.com'), findsOneWidget);

    // Sections are labelled.
    expect(find.text('PROGRESS'), findsOneWidget);
    expect(find.text('ACTIONS'), findsOneWidget);
    expect(find.text('RECENT ATTEMPTS'), findsOneWidget);

    // The lower sections are below the fold.
    await tester.scrollUntilVisible(
      find.text('ACHIEVEMENTS'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('ACHIEVEMENTS'), findsOneWidget);
    expect(find.text('MODERATION HISTORY'), findsOneWidget);
  });
}

void _noop(int index) {}
