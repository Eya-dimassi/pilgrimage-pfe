import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/domain/auth_session.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return const SecureStorageService(FlutterSecureStorage());
});

class SecureStorageService {
  const SecureStorageService(this._storage);

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _sessionKey = 'auth_session';
  static const String _introSeenKey = 'intro_seen';

  final FlutterSecureStorage _storage;

  Future<void> saveSession(AuthSession session) async {
    await _storage.write(key: _accessTokenKey, value: session.accessToken);
    await _storage.write(key: _refreshTokenKey, value: session.refreshToken);
    await _storage.write(key: _sessionKey, value: jsonEncode(session.toJson()));
  }

  Future<AuthSession?> readSession() async {
    final rawSession = await _storage.read(key: _sessionKey);
    if (rawSession == null || rawSession.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawSession) as Map<String, dynamic>;
      return AuthSession.fromJson(decoded);
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> readRefreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<void> updateSessionTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);

    final session = await readSession();
    if (session == null) {
      return;
    }

    final updatedSession = session.copyWith(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    await _storage.write(key: _sessionKey, value: jsonEncode(updatedSession.toJson()));
  }

  Future<void> markIntroSeen() {
    return _storage.write(key: _introSeenKey, value: 'true');
  }

  Future<bool> hasSeenIntro() async {
    final rawValue = await _storage.read(key: _introSeenKey);
    return rawValue == 'true';
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _sessionKey);
  }
}
