import 'package:flutter_test/flutter_test.dart';
import 'package:verifai/core/services/dio_api_client.dart';

void main() {
  test('parseAdminIdentity reads the role from the snake_case /auth/me payload',
      () {
    // Mirrors authController.me: integer id, display_name/created_at, is_admin.
    final json = <String, dynamic>{
      'user': <String, dynamic>{
        'id': 108,
        'firebase_uid': 'abc',
        'email': 'vusani@verify.com',
        'display_name': 'Vusani',
        'created_at': '2026-10-01T00:00:00.000Z',
      },
      'is_admin': true,
      'role': 'super',
    };

    final identity = parseAdminIdentity(json);

    expect(identity.role, 'super');
    expect(identity.isAdmin, isTrue);
    expect(identity.user.email, 'vusani@verify.com');
    expect(identity.user.id, '108');
  });

  test('parseAdminIdentity yields a null role for regular learners', () {
    final json = <String, dynamic>{
      'user': <String, dynamic>{'id': 1, 'email': 'learner@example.com'},
      'is_admin': false,
      'role': null,
    };

    final identity = parseAdminIdentity(json);

    expect(identity.role, isNull);
    expect(identity.isAdmin, isFalse);
  });
}
