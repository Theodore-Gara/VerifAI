import 'dart:async';
import 'dart:io' show SocketException;

import 'package:dio/dio.dart';

/// Coarse category of a failed request, used to pick the right screen state
/// (offline, timeout, session expired, ...) and the right copy.
enum ApiFailureKind { offline, timeout, unauthorized, server, client, unknown }

/// Thrown by code that detects the session is no longer valid (for example
/// after the 401 interceptor could not recover it).
class SessionExpiredException implements Exception {
  const SessionExpiredException();

  @override
  String toString() => 'SessionExpiredException: session expired';
}

class ApiFailure {
  final ApiFailureKind kind;
  final String message;
  final int? statusCode;

  const ApiFailure(this.kind, this.message, {this.statusCode});

  bool get isOffline => kind == ApiFailureKind.offline;
  bool get isTimeout => kind == ApiFailureKind.timeout;
  bool get isUnauthorized => kind == ApiFailureKind.unauthorized;

  /// Worth showing a Retry button for.
  bool get isRetryable =>
      kind == ApiFailureKind.offline ||
      kind == ApiFailureKind.timeout ||
      kind == ApiFailureKind.server ||
      kind == ApiFailureKind.unknown;
}

const _offlineMessage =
    'You appear to be offline. Check your connection and try again.';
const _timeoutMessage =
    'The server took too long to respond. Please try again.';
const _unauthorizedMessage = 'Your session has expired. Please sign in again.';
const _serverMessage =
    'Something went wrong on our side. Please try again in a moment.';
const _clientFallbackMessage = 'We could not complete that request.';
const _unknownMessage = 'Something went wrong. Please try again.';

/// Turns any thrown object into an [ApiFailure] with user-facing copy.
/// Never leaks raw exception text (stack traces, URLs, JSON dumps) to the UI.
ApiFailure classifyError(Object error) {
  if (error is SessionExpiredException) {
    return const ApiFailure(ApiFailureKind.unauthorized, _unauthorizedMessage,
        statusCode: 401);
  }
  if (error is TimeoutException) {
    return const ApiFailure(ApiFailureKind.timeout, _timeoutMessage);
  }
  if (error is SocketException) {
    return const ApiFailure(ApiFailureKind.offline, _offlineMessage);
  }
  if (error is DioException) return _classifyDio(error);

  final text = error.toString().toLowerCase();
  if (text.contains('network-request-failed') ||
      text.contains('socketexception') ||
      text.contains('failed host lookup')) {
    return const ApiFailure(ApiFailureKind.offline, _offlineMessage);
  }
  if (text.contains('timeout')) {
    return const ApiFailure(ApiFailureKind.timeout, _timeoutMessage);
  }
  if (text.contains('sign in with google before connecting')) {
    return const ApiFailure(ApiFailureKind.unauthorized, _unauthorizedMessage);
  }
  return const ApiFailure(ApiFailureKind.unknown, _unknownMessage);
}

ApiFailure _classifyDio(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const ApiFailure(ApiFailureKind.timeout, _timeoutMessage);
    case DioExceptionType.connectionError:
      return const ApiFailure(ApiFailureKind.offline, _offlineMessage);
    case DioExceptionType.badResponse:
      return _classifyStatus(error);
    case DioExceptionType.cancel:
      return const ApiFailure(
          ApiFailureKind.unknown, 'The request was cancelled.');
    case DioExceptionType.badCertificate:
      return const ApiFailure(ApiFailureKind.unknown,
          'We could not establish a secure connection. Please try again.');
    case DioExceptionType.unknown:
      if (error.error is SocketException) {
        return const ApiFailure(ApiFailureKind.offline, _offlineMessage);
      }
      if (error.error is SessionExpiredException) {
        return const ApiFailure(
            ApiFailureKind.unauthorized, _unauthorizedMessage,
            statusCode: 401);
      }
      return const ApiFailure(ApiFailureKind.unknown, _unknownMessage);
  }
}

ApiFailure _classifyStatus(DioException error) {
  final status = error.response?.statusCode;
  if (status == 401) {
    return const ApiFailure(ApiFailureKind.unauthorized, _unauthorizedMessage,
        statusCode: 401);
  }
  if (status != null && status >= 500) {
    return ApiFailure(ApiFailureKind.server, _serverMessage,
        statusCode: status);
  }
  // 4xx: the backend sends `{ "error": "<readable message>" }`.
  final data = error.response?.data;
  final serverMessage = data is Map ? data['error'] : null;
  return ApiFailure(
    ApiFailureKind.client,
    serverMessage is String && serverMessage.trim().isNotEmpty
        ? serverMessage.trim()
        : _clientFallbackMessage,
    statusCode: status,
  );
}
