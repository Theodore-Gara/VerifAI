import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const _keyAuthToken = 'auth_token';
  static const _keyUserId = 'user_id';
  static const _keyUserEmail = 'user_email';
  static const _keyUserName = 'user_name';
  static const _keyTrackId = 'track_id';
  static const _keyTrackName = 'track_name';
  static const _keyHasCompletedOnboarding = 'has_completed_onboarding';

  // Auth token
  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _keyAuthToken, value: token);
  }

  Future<String?> getAuthToken() async {
    try {
      return await _storage.read(key: _keyAuthToken);
    } catch (e) {
      if (_isDecryptionError(e)) {
        debugPrint('Secure storage decryption failed, clearing corrupted data: $e');
        await _handleCorruptedStorage();
      }
      return null;
    }
  }

  Future<void> deleteAuthToken() async {
    await _storage.delete(key: _keyAuthToken);
  }

  // User data
  Future<void> saveUserData({
    required String userId,
    required String email,
    String? name,
    String? trackId,
    String? trackName,
    bool hasCompletedOnboarding = false,
  }) async {
    await Future.wait([
      _storage.write(key: _keyUserId, value: userId),
      _storage.write(key: _keyUserEmail, value: email),
      if (name != null) _storage.write(key: _keyUserName, value: name),
      if (trackId != null) _storage.write(key: _keyTrackId, value: trackId),
      if (trackName != null) _storage.write(key: _keyTrackName, value: trackName),
      _storage.write(key: _keyHasCompletedOnboarding, value: hasCompletedOnboarding.toString()),
    ]);
  }

  Future<UserData?> getUserData() async {
    try {
      final userId = await _storage.read(key: _keyUserId);
      if (userId == null) return null;

      return UserData(
        userId: userId,
        email: await _storage.read(key: _keyUserEmail) ?? '',
        name: await _storage.read(key: _keyUserName),
        trackId: await _storage.read(key: _keyTrackId),
        trackName: await _storage.read(key: _keyTrackName),
        hasCompletedOnboarding: (await _storage.read(key: _keyHasCompletedOnboarding)) == 'true',
      );
    } catch (e) {
      if (_isDecryptionError(e)) {
        debugPrint('Secure storage decryption failed in getUserData, clearing: $e');
        await _handleCorruptedStorage();
      }
      return null;
    }
  }

  Future<void> updateTrack(String trackId, String trackName) async {
    await Future.wait([
      _storage.write(key: _keyTrackId, value: trackId),
      _storage.write(key: _keyTrackName, value: trackName),
      _storage.write(key: _keyHasCompletedOnboarding, value: 'true'),
    ]);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Handle corrupted encrypted storage (BadPaddingException)
  bool _isDecryptionError(Object error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('badpadding') ||
           errorStr.contains('bad_padding') ||
           errorStr.contains('bad decrypt') ||
           errorStr.contains('cipher') ||
           errorStr.contains('decrypt');
  }

  Future<void> _handleCorruptedStorage() async {
    try {
      await _storage.deleteAll();
      debugPrint('Cleared corrupted secure storage');
    } catch (e) {
      debugPrint('Failed to clear corrupted storage: $e');
    }
  }
}

class UserData {
  final String userId;
  final String email;
  final String? name;
  final String? trackId;
  final String? trackName;
  final bool hasCompletedOnboarding;

  UserData({
    required this.userId,
    required this.email,
    this.name,
    this.trackId,
    this.trackName,
    required this.hasCompletedOnboarding,
  });
}