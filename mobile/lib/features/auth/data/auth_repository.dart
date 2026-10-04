import 'dart:async';
import 'package:flutter/services.dart' show PlatformException;
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

/// Real authentication: Firebase Auth (email/password + Google) with the
/// backend as the source of truth for the user profile. There is no local
/// user store any more.
class FirebaseAuthRepository implements AuthRepository {
  final SecureStorageService _secureStorage;
  final ApiClient _apiClient;
  final _authStateController = StreamController<AuthState>.broadcast();

  /// Firebase project verif-ai-5a435 -> Web OAuth client (client_type 3 in
  /// google-services.json). Passed as serverClientId so google_sign_in always
  /// requests a Google ID token for Firebase, instead of relying on the
  /// auto-generated `default_web_client_id` resource lookup.
  static const _googleServerClientId =
      '813373583048-alfif0t7ptkoru684ghp23dfra4t4sct.apps.googleusercontent.com';

  FirebaseAuthRepository({
    required SecureStorageService secureStorage,
    required ApiClient apiClient,
  })  : _secureStorage = secureStorage,
        _apiClient = apiClient;

  @override
  Future<AuthResult> register(
      String email, String password, String name) async {
    final trimmedName = name.trim();

    // createUserWithEmailAndPassword throws FirebaseAuthException
    // (e.g. email-already-in-use, weak-password) which the UI humanizes.
    final credential = await firebase_auth.FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    final fbUser = credential.user;
    if (fbUser == null) {
      throw Exception('Account could not be created. Please try again.');
    }

    if (trimmedName.isNotEmpty) {
      await fbUser.updateDisplayName(trimmedName);
      // Force a token refresh so the `name` claim is present when the backend
      // decodes the ID token during /auth/sync.
      await fbUser.getIdToken(true);
    }

    return _syncAndStore(_userFromFirebase(fbUser, name: trimmedName));
  }

  @override
  Future<AuthResult> login(String email, String password) async {
    // Throws FirebaseAuthException (wrong-password, user-not-found,
    // invalid-credential, too-many-requests, ...) which the UI humanizes.
    final credential = await firebase_auth.FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

    final fbUser = credential.user;
    if (fbUser == null) {
      throw Exception('Sign-in failed. Please try again.');
    }

    return _syncAndStore(_userFromFirebase(fbUser));
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

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

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

    final firebase_auth.OAuthCredential credential =
        firebase_auth.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final firebase_auth.UserCredential userCredential;
    try {
      userCredential = await firebase_auth.FirebaseAuth.instance
          .signInWithCredential(credential);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(
          'Firebase rejected the Google credential (${e.code}). ${e.message ?? ''}'
              .trim());
    }

    final firebase_auth.User? firebaseUser = userCredential.user;

    if (firebaseUser == null) {
      throw Exception('Google Sign-In failed: Firebase returned no user.');
    }

    return _syncAndStore(_userFromFirebase(firebaseUser));
  }

  /// Syncs the Firebase identity to the backend (POST /auth/sync + GET
  /// /users/me), persists the session and emits the resulting auth state.
  Future<AuthResult> _syncAndStore(User user) async {
    final syncResult = await _apiClient.syncUser(user);
    final synced = syncResult.user;
    final token = syncResult.token;

    await _secureStorage.saveAuthToken(token);
    await _secureStorage.saveUserData(
      userId: synced.id,
      email: synced.email,
      name: synced.name,
      trackId: synced.trackId,
      trackName: synced.trackName,
      hasCompletedOnboarding: synced.hasCompletedOnboarding,
    );

    _authStateController.add(
      synced.hasCompletedOnboarding
          ? AuthState.authenticated(user: synced, token: token)
          : AuthState.needsOnboarding(user: synced, token: token),
    );

    return AuthResult(user: synced, token: token);
  }

  User _userFromFirebase(firebase_auth.User fbUser, {String? name}) {
    return User(
      id: fbUser.uid,
      email: fbUser.email ?? '',
      name: (name != null && name.isNotEmpty) ? name : fbUser.displayName,
      trackId: null,
      trackName: null,
      hasCompletedOnboarding: false,
      createdAt: DateTime.now().toIso8601String(),
    );
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

  /// Onboarding is derived from the backend: after the track has been saved
  /// (PUT /users/profile), re-fetch the profile and read `industry_track_id`.
  @override
  Future<void> completeOnboarding() async {
    final current = await getCurrentUser();
    if (current == null) return;

    try {
      final syncResult = await _apiClient.syncUser(current);
      final synced = syncResult.user;
      final token = syncResult.token;

      await _secureStorage.saveUserData(
        userId: synced.id,
        email: synced.email,
        name: synced.name,
        trackId: synced.trackId,
        trackName: synced.trackName,
        hasCompletedOnboarding: synced.hasCompletedOnboarding,
      );

      _authStateController.add(
        synced.hasCompletedOnboarding
            ? AuthState.authenticated(user: synced, token: token)
            : AuthState.needsOnboarding(user: synced, token: token),
      );
    } catch (_) {
      // Offline / backend hiccup: fall back to the locally stored selection so
      // onboarding is never a dead end.
      final token = await _secureStorage.getAuthToken() ?? '';
      _authStateController.add(
        AuthState.authenticated(user: current.copyWith(hasCompletedOnboarding: true), token: token),
      );
    }
  }

  @override
  Future<void> logout() async {
    await _secureStorage.clearAll();
    try {
      await firebase_auth.FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } catch (_) {
      // Firebase may be unavailable in tests; clearing local state is enough.
    }
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

  void dispose() {
    _authStateController.close();
  }
}
