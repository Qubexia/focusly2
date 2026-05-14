import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper around flutter_secure_storage for token management.
class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _deviceIdKey = 'device_id';

  // ─── Access Token ───
  static Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  static Future<String?> getAccessToken() =>
      _storage.read(key: _accessTokenKey);

  static Future<void> deleteAccessToken() =>
      _storage.delete(key: _accessTokenKey);

  // ─── Refresh Token ───
  static Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  static Future<String?> getRefreshToken() =>
      _storage.read(key: _refreshTokenKey);

  static Future<void> deleteRefreshToken() =>
      _storage.delete(key: _refreshTokenKey);

  // ─── Device ID ───
  static Future<void> saveDeviceId(String deviceId) =>
      _storage.write(key: _deviceIdKey, value: deviceId);

  static Future<String?> getDeviceId() =>
      _storage.read(key: _deviceIdKey);

  // ─── Bulk ops ───
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
  }

  static Future<void> clearTokens() async {
    await deleteAccessToken();
    await deleteRefreshToken();
  }

  static Future<void> clearAll() => _storage.deleteAll();
}
