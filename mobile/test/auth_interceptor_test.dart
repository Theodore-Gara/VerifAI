import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifai/core/services/auth_interceptor.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, String body) => ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  late int refreshCalls;
  late int expiredCalls;

  setUp(() {
    refreshCalls = 0;
    expiredCalls = 0;
  });

  Dio buildDio(_Adapter adapter, {String? refreshedToken = 'new'}) {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'))
      ..httpClientAdapter = adapter;
    dio.interceptors.add(AuthInterceptor(
      dio: dio,
      refreshToken: () async {
        refreshCalls++;
        return refreshedToken;
      },
      onSessionExpired: () async => expiredCalls++,
    ));
    return dio;
  }

  Options authed() => Options(headers: {'Authorization': 'Bearer old'});

  test('refreshes the token and retries once on 401', () async {
    final adapter = _Adapter((o) => o.headers['Authorization'] == 'Bearer new'
        ? _json(200, '{"ok":true}')
        : _json(401, '{"error":"Invalid or expired token."}'));
    final dio = buildDio(adapter);

    final response =
        await dio.get<Map<String, dynamic>>('users/me', options: authed());

    expect(response.statusCode, 200);
    expect(adapter.requests.length, 2);
    expect(refreshCalls, 1);
    expect(expiredCalls, 0);
  });

  test('signs out when the refreshed token is still rejected', () async {
    final adapter =
        _Adapter((_) => _json(401, '{"error":"Invalid or expired token."}'));
    final dio = buildDio(adapter);

    await expectLater(
      dio.get<Map<String, dynamic>>('users/me', options: authed()),
      throwsA(isA<DioException>()),
    );
    expect(expiredCalls, 1);
  });

  test('signs out when no fresh token can be obtained', () async {
    final adapter =
        _Adapter((_) => _json(401, '{"error":"Invalid or expired token."}'));
    final dio = buildDio(adapter, refreshedToken: null);

    await expectLater(
      dio.get<Map<String, dynamic>>('users/me', options: authed()),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requests.length, 1);
    expect(expiredCalls, 1);
  });

  test('ignores 401s on requests that carry no Authorization header', () async {
    final adapter = _Adapter((_) => _json(401, '{"error":"nope"}'));
    final dio = buildDio(adapter);

    await expectLater(
      dio.get<Map<String, dynamic>>('tracks'),
      throwsA(isA<DioException>()),
    );
    expect(refreshCalls, 0);
    expect(expiredCalls, 0);
  });

  test('does not touch non-401 errors', () async {
    final adapter = _Adapter((_) => _json(500, '{"error":"boom"}'));
    final dio = buildDio(adapter);

    await expectLater(
      dio.get<Map<String, dynamic>>('users/me', options: authed()),
      throwsA(isA<DioException>()),
    );
    expect(refreshCalls, 0);
    expect(expiredCalls, 0);
  });

  test('parallel 401s share one refresh and one sign-out', () async {
    final adapter =
        _Adapter((_) => _json(401, '{"error":"Invalid or expired token."}'));
    final dio = buildDio(adapter);

    final results = await Future.wait([
      for (var i = 0; i < 3; i++)
        dio
            .get<Map<String, dynamic>>('users/me', options: authed())
            .then<Object?>((r) => r, onError: (Object e) => e),
    ]);

    expect(results.every((r) => r is DioException), isTrue);
    expect(refreshCalls, 1);
    expect(expiredCalls, 1);
  });
}
