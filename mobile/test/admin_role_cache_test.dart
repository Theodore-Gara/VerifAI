// The router decides between the learner app and the admin portal from the
// staff role. A sleeping backend must not be read as "learner", so the last
// resolved role is cached and only a session that never resolved one is
// reported as unknown.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:verifai/core/providers/app_providers.dart';
import 'package:verifai/core/services/api_client.dart';
import 'package:verifai/core/services/secure_storage_service.dart';
import 'package:verifai/features/profile/providers.dart';
import 'package:verifai/shared/models.dart';

import 'support/mock_api_client.dart';

const _user = User(id: '1', email: 'user@verifai.app', createdAt: '');

/// Backend that never wakes up (the request timed out).
class _ColdApiClient extends MockApiClient {
  @override
  Future<AdminIdentity> getMe() async => throw Exception('cold start');
}

/// Backend that answers "no staff role" for this account.
class _LearnerApiClient extends MockApiClient {
  @override
  Future<AdminIdentity> getMe() async =>
      const AdminIdentity(user: _user, isAdmin: false);
}

/// Backend that reports an admin role.
class _AdminApiClient extends MockApiClient {
  @override
  Future<AdminIdentity> getMe() async =>
      const AdminIdentity(user: _user, isAdmin: true, role: 'admin');
}

ProviderContainer _container(ApiClient client) => ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(client)],
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('keeps the cached admin role when the backend is unreachable', () async {
    FlutterSecureStorage.setMockInitialValues({'admin_role': 'admin'});
    final container = _container(_ColdApiClient());
    addTearDown(container.dispose);

    expect(await container.read(adminRoleProvider.future), 'admin');
  });

  test('reports unknown (not learner) when no role was ever resolved',
      () async {
    final container = _container(_ColdApiClient());
    addTearDown(container.dispose);

    await expectLater(
      container.read(adminRoleProvider.future),
      throwsA(isA<Exception>()),
    );
  });

  test('records a resolved learner so later starts need no network', () async {
    final container = _container(_LearnerApiClient());
    addTearDown(container.dispose);

    expect(await container.read(adminRoleProvider.future), isNull);
    expect(await SecureStorageService().getAdminRole(), '');
  });

  test('caches a fresh admin role for the next cold start', () async {
    final container = _container(_AdminApiClient());
    addTearDown(container.dispose);

    expect(await container.read(adminRoleProvider.future), 'admin');
    expect(await SecureStorageService().getAdminRole(), 'admin');
  });
}
