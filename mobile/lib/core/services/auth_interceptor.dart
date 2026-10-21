import 'dart:async';

import 'package:dio/dio.dart';

typedef TokenRefresher = Future<String?> Function();
typedef TokenProvider = Future<String?> Function();
typedef SessionExpiredCallback = Future<void> Function();

/// Recovers from expired tokens.
///
/// When an authenticated request comes back 401 the interceptor forces a fresh
/// token, retries the request once, and only if that also fails signs the user
/// out via [onSessionExpired] (which sends them back to the login screen).
///
/// The same interceptor also *attaches* the ID token to every request, so
/// callers never build `Authorization` headers themselves (they used to do it
/// in ~20 places, and two endpoints forgot, so behaviour differed per call).
///
/// * Requests without an `Authorization` header (e.g. the public tracks list)
///   are never treated as an expired session.
/// * Parallel 401s (the dashboard fires three requests at once) share one
///   refresh and trigger at most one sign-out.
class AuthInterceptor extends Interceptor {
  static const retriedKey = 'auth_retried';
  static const skipAuthKey = 'skip_auth';

  final Dio _dio;
  final TokenProvider _token;
  final TokenRefresher _refreshToken;
  final SessionExpiredCallback _onSessionExpired;

  final Map<String, Future<String?>> _refreshes = {};
  final Map<String, String?> _refreshedTokens = {};
  final Set<String> _expiredAuthorizations = {};
  bool _expiring = false;

  AuthInterceptor({
    required Dio dio,
    required TokenProvider token,
    required TokenRefresher refreshToken,
    required SessionExpiredCallback onSessionExpired,
  })  : _dio = dio,
        _token = token,
        _refreshToken = refreshToken,
        _onSessionExpired = onSessionExpired;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Public endpoints opt out with `extra: {'skip_auth': true}`.
    if (options.extra[skipAuthKey] == true ||
        options.headers.containsKey('Authorization')) {
      handler.next(options);
      return;
    }
    try {
      final token = await _token();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // No signed-in user: let the request go out unauthenticated so a 401 from
      // a protected route surfaces as an error instead of a thrown StateError.
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    final hadAuthHeader = options.headers.containsKey('Authorization');
    final authorization = options.headers['Authorization']?.toString() ?? '';

    if (!isUnauthorized || !hadAuthHeader) {
      handler.next(err);
      return;
    }

    if (options.extra[retriedKey] != true) {
      final token = await _refresh(authorization);
      if (token != null && token.isNotEmpty) {
        try {
          final response = await _dio.fetch<dynamic>(options.copyWith(
            headers: {...options.headers, 'Authorization': 'Bearer $token'},
            extra: {...options.extra, retriedKey: true},
          ));
          handler.resolve(response);
          return;
        } on DioException catch (retryError) {
          if (retryError.response?.statusCode != 401) {
            handler.next(retryError);
            return;
          }
          // The retried request's interceptor already handled session expiry.
          handler.next(retryError);
          return;
        }
      }
    }

    await _expireSession(authorization);
    handler.next(err);
  }

  Future<String?> _refresh(String authorization) {
    if (_refreshedTokens.containsKey(authorization)) {
      return Future.value(_refreshedTokens[authorization]);
    }
    return _refreshes.putIfAbsent(authorization, () async {
      try {
        final token = await _refreshToken();
        _refreshedTokens[authorization] = token;
        return token;
      } catch (_) {
        _refreshedTokens[authorization] = null;
        return null;
      } finally {
        _refreshes.remove(authorization);
      }
    });
  }

  Future<void> _expireSession(String authorization) async {
    if (_expiring || !_expiredAuthorizations.add(authorization)) return;
    _expiring = true;
    try {
      await _onSessionExpired();
    } catch (_) {
      // Signing out is best effort; the router redirects once auth state flips.
    } finally {
      _expiring = false;
    }
  }
}
