import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show PlatformException;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:verifai/core/services/api_client.dart';
import 'package:verifai/core/services/secure_storage_service.dart';
import 'package:verifai/shared/models.dart';

abstract class AuthRepository {
  Future<AuthResult> login(String email, String password);
  Future<AuthResult> register(String email, String password, String name);
  Future<AuthResult> signInWithGoogle();
  Future<void> completeOnboarding();
  Future<void> logout();
  Future<User?> getCurrentUser();
  Stream<AuthState> authStateChanges();
}

class MockAuthRepository implements AuthRepository {
  final SecureStorageService _secureStorage;
  final ApiClient _apiClient;
  final SharedPreferences _prefs;
  final _authStateController = StreamController<AuthState>.broadcast();

  static const _keyUsers = 'mock_users';
  static const _keyUsersSeeded = 'mock_users_seeded_v1';

  /// Firebase project verif-ai-5a435 -> Web OAuth client (client_type 3 in
  /// google-services.json). Passed as serverClientId so google_sign_in always
  /// requests a Google ID token for Firebase, instead of relying on the
  /// auto-generated `default_web_client_id` resource lookup.
  static const _googleServerClientId =
      '813373583048-alfif0t7ptkoru684ghp23dfra4t4sct.apps.googleusercontent.com';

  /// Prototype seed accounts (no backend yet). Default password: password123
  static const Map<String, Map<String, dynamic>> _seedUsers = {
    'theo@verif.com': {
      'id': 'seed-theo',
      'email': 'theo@verif.com',
      'password': 'password123',
      'name': 'Theodore Nangara',
      'trackId': null,
      'trackName': null,
      'hasCompletedOnboarding': false,
      'createdAt': '2026-09-01T00:00:00.000Z',
    },
    'vusani@verif.com': {
      'id': 'seed-vusani',
      'email': 'vusani@verif.com',
      'password': 'password123',
      'name': 'Vusani Earl Mulaudzi',
      'trackId': null,
      'trackName': null,
      'hasCompletedOnboarding': false,
      'createdAt': '2026-09-01T00:00:00.000Z',
    },
    'naledi@verif.com': {
      'id': 'seed-naledi',
      'email': 'naledi@verif.com',
      'password': 'password123',
      'name': 'Lwandle Naledi Chloe Mvelase',
      'trackId': null,
      'trackName': null,
      'hasCompletedOnboarding': false,
      'createdAt': '2026-09-01T00:00:00.000Z',
    },
    'mpho@verif.com': {
      'id': 'seed-mpho',
      'email': 'mpho@verif.com',
      'password': 'password123',
      'name': 'Mpho Mokoena',
      'trackId': null,
      'trackName': null,
      'hasCompletedOnboarding': false,
      'createdAt': '2026-09-01T00:00:00.000Z',
    },
    'meshaque@verif.com': {
      'id': 'seed-meshaque',
      'email': 'meshaque@verif.com',
      'password': 'password123',
      'name': 'Meshaque Kalonji',
      'trackId': null,
      'trackName': null,
      'hasCompletedOnboarding': false,
      'createdAt': '2026-09-01T00:00:00.000Z',
    },
  };

  MockAuthRepository({
    required SecureStorageService secureStorage,
    required ApiClient apiClient,
    required SharedPreferences prefs,
  })  : _secureStorage = secureStorage,
        _apiClient = apiClient,
        _prefs = prefs;

  /// Seeds the prototype accounts on first run (once per install).
  Future<void> _ensureSeedUsers() async {
    final alreadySeeded = _prefs.getBool(_keyUsersSeeded) ?? false;
    if (alreadySeeded) return;

    final users = _getUsers();
    var changed = false;
    _seedUsers.forEach((email, data) {
      if (!users.containsKey(email)) {
        users[email] = Map<String, dynamic>.from(data);
        changed = true;
      }
    });
    if (changed) {
      await _saveUsers(users);
    }
    await _prefs.setBool(_keyUsersSeeded, true);
  }

  @override
  Future<AuthResult> login(String email, String password) async {
    await _ensureSeedUsers();
    final users = _getUsers();
    final userData = users[email.toLowerCase()];

    if (userData == null) {
      throw Exception('User not found');
    }

    if (userData['password'] != password) {
      throw Exception('Invalid password');
    }

    final user = User(
      id: userData['id'] as String,
      email: email,
      name: userData['name'] as String?,
      trackId: userData['trackId'] as String?,
      trackName: userData['trackName'] as String?,
      hasCompletedOnboarding: userData['hasCompletedOnboarding'] as bool? ?? false,
      createdAt: userData['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );

    final syncResult = await _apiClient.syncUser(user);
    final token = syncResult.token;

    await _secureStorage.saveAuthToken(token);
    await _secureStorage.saveUserData(
      userId: user.id,
      email: user.email,
      name: user.name,
      trackId: user.trackId,
      trackName: user.trackName,
      hasCompletedOnboarding: user.hasCompletedOnboarding,
    );

    _authStateController.add(
      user.hasCompletedOnboarding
          ? AuthState.authenticated(user: user, token: token)
          : AuthState.needsOnboarding(user: user, token: token),
    );

    return AuthResult(user: user, token: token);
  }

  @override
  Future<AuthResult> register(String email, String password, String name) async {
    await _ensureSeedUsers();
    final users = _getUsers();
    final normalizedEmail = email.toLowerCase();

    if (users.containsKey(normalizedEmail)) {
      throw Exception('Email already registered');
    }

    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    final newUser = {
      'id': userId,
      'email': normalizedEmail,
      'password': password, // In real app, hash this!
      'name': name,
      'trackId': null,
      'trackName': null,
      'hasCompletedOnboarding': false,
      'createdAt': DateTime.now().toIso8601String(),
    };

    users[normalizedEmail] = newUser;
    await _saveUsers(users);

    final user = User(
      id: userId,
      email: email,
      name: name,
      trackId: null,
      trackName: null,
      hasCompletedOnboarding: false,
      createdAt: newUser['createdAt'] as String,
    );

    final syncResult = await _apiClient.syncUser(user);
    final token = syncResult.token;

    await _secureStorage.saveAuthToken(token);
    await _secureStorage.saveUserData(
      userId: user.id,
      email: user.email,
      name: user.name,
      trackId: null,
      trackName: null,
      hasCompletedOnboarding: false,
    );

    _authStateController.add(AuthState.needsOnboarding(user: user, token: token));

    return AuthResult(user: user, token: token);
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: _googleServerClientId,
    );

    GoogleSignInAccount? googleUser;
    try {
      googleUser = await googleSignIn.signIn();
    } on PlatformException catch (e) {
      throw Exception(_googleSignInErrorMessage(e));
    }

    if (googleUser == null) {
      throw Exception('Google Sign-In cancelled');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Firebase needs the Google ID token. It is null when the Google provider
    // is not enabled in Firebase Auth, or when this build's SHA-1 fingerprint
    // is not registered (oauth_client is empty in google-services.json).
    if (googleAuth.idToken == null) {
      throw Exception(
        'Google Sign-In returned no ID token. Enable the Google provider under '
        'Firebase Authentication for project verif-ai-5a435, register this '
        'build\'s SHA-1, then re-download google-services.json.',
      );
    }

    final firebase_auth.OAuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final firebase_auth.UserCredential userCredential;
    try {
      userCredential = await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception('Firebase rejected the Google credential (${e.code}). ${e.message ?? ''}'.trim());
    }

    final firebase_auth.User? firebaseUser = userCredential.user;

    if (firebaseUser == null) {
      throw Exception('Google Sign-In failed: Firebase returned no user.');
    }

    // Create or get user from our mock storage
    final users = _getUsers();
    final normalizedEmail = firebaseUser.email?.toLowerCase() ?? '';
    
    Map<String, dynamic>? userData;
    if (users.containsKey(normalizedEmail)) {
      userData = users[normalizedEmail];
    } else {
      // Create new user
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      final newUser = {
        'id': userId,
        'email': normalizedEmail,
        'password': '', // Google users don't have passwords
        'name': firebaseUser.displayName ?? 'Google User',
        'trackId': null,
        'trackName': null,
        'hasCompletedOnboarding': false,
        'createdAt': DateTime.now().toIso8601String(),
      };
      users[normalizedEmail] = newUser;
      await _saveUsers(users);
      userData = newUser;
    }

    // userData is guaranteed to be non-null at this point
    final data = userData!;
    final user = User(
      id: data['id'] as String,
      email: normalizedEmail,
      name: data['name'] as String?,
      trackId: data['trackId'] as String?,
      trackName: data['trackName'] as String?,
      hasCompletedOnboarding: data['hasCompletedOnboarding'] as bool? ?? false,
      createdAt: data['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );

    final syncResult = await _apiClient.syncUser(user);
    final token = syncResult.token;

    await _secureStorage.saveAuthToken(token);
    await _secureStorage.saveUserData(
      userId: user.id,
      email: user.email,
      name: user.name,
      trackId: user.trackId,
      trackName: user.trackName,
      hasCompletedOnboarding: user.hasCompletedOnboarding,
    );

    _authStateController.add(
      user.hasCompletedOnboarding
          ? AuthState.authenticated(user: user, token: token)
          : AuthState.needsOnboarding(user: user, token: token),
    );

    return AuthResult(user: user, token: token);
  }

  /// Maps google_sign_in platform failures to actionable messages.
  /// Android codes: 10 = DEVELOPER_ERROR, 12501 = user cancelled,
  /// 12500 = sign-in failed (usually missing/invalid OAuth client).
  String _googleSignInErrorMessage(PlatformException e) {
    switch (e.code) {
      case 'sign_in_failed':
      case '10':
        return 'Google Sign-In is not configured for this build (DEVELOPER_ERROR). '
            'Register this build\'s SHA-1 in Firebase for package com.verifai.app '
            'and re-download google-services.json.';
      case '12501':
      case '12502':
        return 'Google Sign-In cancelled';
      case '12500':
        return 'Google Sign-In failed: no matching OAuth client. Enable the Google '
            'provider in Firebase Authentication and re-download google-services.json.';
      default:
        return 'Google Sign-In failed (${e.code}): ${e.message ?? 'unknown error'}';
    }
  }

  @override
  Future<void> completeOnboarding() async {
    final userData = await _secureStorage.getUserData();
    if (userData == null) return;
    final token = await _secureStorage.getAuthToken() ?? '';
    final user = User(
      id: userData.userId,
      email: userData.email,
      name: userData.name,
      trackId: userData.trackId,
      trackName: userData.trackName,
      hasCompletedOnboarding: true,
      createdAt: DateTime.now().toIso8601String(),
    );
    _authStateController.add(AuthState.authenticated(user: user, token: token));
  }

  @override
  Future<void> logout() async {
    await _secureStorage.clearAll();
    _authStateController.add(const AuthState.unauthenticated());
  }

  @override
  Future<User?> getCurrentUser() async {
    final token = await _secureStorage.getAuthToken();
    if (token == null) return null;

    final userData = await _secureStorage.getUserData();
    if (userData == null) return null;

    return User(
      id: userData.userId,
      email: userData.email,
      name: userData.name,
      trackId: userData.trackId,
      trackName: userData.trackName,
      hasCompletedOnboarding: userData.hasCompletedOnboarding,
      createdAt: DateTime.now().toIso8601String(), // fallback
    );
  }

  @override
  Stream<AuthState> authStateChanges() {
    return _authStateController.stream;
  }

  Map<String, Map<String, dynamic>> _getUsers() {
    final jsonString = _prefs.getString(_keyUsers);
    if (jsonString == null) return {};
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, Map<String, dynamic>.from(value as Map)));
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveUsers(Map<String, Map<String, dynamic>> users) async {
    await _prefs.setString(_keyUsers, jsonEncode(users));
  }

  void dispose() {
    _authStateController.close();
  }
}