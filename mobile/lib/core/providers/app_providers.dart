import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verifai/features/auth/providers.dart';

import '../services/api_client.dart';
import '../services/auth_interceptor.dart';
import '../services/dio_api_client.dart';
import '../services/secure_storage_service.dart';

final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  return DioApiClient(dio: ref.watch(dioProvider));
});

final Provider<Dio> dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      // Production backend on Render. Override for local development with
      // --dart-define=API_BASE_URL=http://<host>:3000/api/
      // Note: the Render free tier spins down when idle, so the first request
      // after a quiet period can take ~50s while the instance wakes.
      defaultValue: 'https://verifai-2wnm.onrender.com/api/',
    ),
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  // Expired / rejected token: refresh once and retry, otherwise sign out so the
  // router sends the user back to the login screen.
  dio.interceptors.add(AuthInterceptor(
    dio: dio,
    refreshToken: () async {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return user.getIdToken(true);
    },
    onSessionExpired: () async {
      await ref.read(secureStorageProvider).clearAll();
      try {
        await firebase_auth.FirebaseAuth.instance.signOut();
      } finally {
        ref.invalidate(authStateProvider);
        ref.invalidate(authNotifierProvider);
      }
    },
  ));

  // Request/response bodies contain user answers and AI feedback, so only log
  // them in debug builds.
  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: false,
      responseHeader: false,
    ));
  }

  return dio;
});
