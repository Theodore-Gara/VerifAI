import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifai/core/services/api_error.dart';

DioException _dio(
  DioExceptionType type, {
  int? status,
  Object? data,
  Object? error,
}) {
  final request = RequestOptions(path: '/x');
  return DioException(
    requestOptions: request,
    type: type,
    error: error,
    response: status == null
        ? null
        : Response(requestOptions: request, statusCode: status, data: data),
  );
}

void main() {
  group('classifyError', () {
    test('timeouts', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.transformTimeout,
      ]) {
        expect(classifyError(_dio(type)).kind, ApiFailureKind.timeout);
      }
      expect(
          classifyError(TimeoutException('slow')).kind, ApiFailureKind.timeout);
    });

    test('offline', () {
      expect(classifyError(_dio(DioExceptionType.connectionError)).kind,
          ApiFailureKind.offline);
      expect(
          classifyError(_dio(DioExceptionType.unknown,
                  error: const SocketException('no route')))
              .kind,
          ApiFailureKind.offline);
      expect(classifyError(const SocketException('x')).isOffline, isTrue);
    });

    test('401 is unauthorized', () {
      final failure =
          classifyError(_dio(DioExceptionType.badResponse, status: 401));
      expect(failure.kind, ApiFailureKind.unauthorized);
      expect(classifyError(const SessionExpiredException()).isUnauthorized,
          isTrue);
    });

    test('5xx is a server error with generic copy', () {
      final failure = classifyError(_dio(DioExceptionType.badResponse,
          status: 503, data: {'error': 'stack trace here'}));
      expect(failure.kind, ApiFailureKind.server);
      expect(failure.message, isNot(contains('stack trace')));
    });

    test('4xx surfaces the backend error message', () {
      final failure = classifyError(_dio(DioExceptionType.badResponse,
          status: 400,
          data: {
            'error': 'Select an industry track before requesting a task.'
          }));
      expect(failure.kind, ApiFailureKind.client);
      expect(failure.message,
          'Select an industry track before requesting a task.');
    });

    test('unknown errors never leak raw exception text', () {
      final failure = classifyError(StateError('Instance of _Foo at 0x1234'));
      expect(failure.kind, ApiFailureKind.unknown);
      expect(failure.message, isNot(contains('0x1234')));
    });
  });
}
