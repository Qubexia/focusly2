import 'package:flutter/foundation.dart';

import '../../../../core/storage/secure_storage.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

/// Repository that orchestrates auth data source calls + token persistence.
class AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepository({AuthRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSource();

  Future<String> _getOrCreateDeviceId() async {
    var deviceId = await SecureStorage.getDeviceId();
    if (deviceId == null) {
      final platformName = kIsWeb
          ? 'web'
          : defaultTargetPlatform.name.toLowerCase();
      deviceId = 'flutter-$platformName-${DateTime.now().millisecondsSinceEpoch}';
      await SecureStorage.saveDeviceId(deviceId);
    }
    return deviceId;
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final deviceId = await _getOrCreateDeviceId();
    final response = await _remoteDataSource.register(
      email: email,
      password: password,
      name: name,
      deviceId: deviceId,
    );
    await _persistTokens(response);
    return response;
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final deviceId = await _getOrCreateDeviceId();
    final response = await _remoteDataSource.login(
      email: email,
      password: password,
      deviceId: deviceId,
    );
    await _persistTokens(response);
    return response;
  }

  Future<AuthResponse> googleLogin({required String idToken}) async {
    final deviceId = await _getOrCreateDeviceId();
    final response = await _remoteDataSource.googleLogin(
      idToken: idToken,
      deviceId: deviceId,
    );
    await _persistTokens(response);
    return response;
  }

  Future<void> forgotPassword({required String email}) async {
    await _remoteDataSource.forgotPassword(email: email);
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _remoteDataSource.resetPassword(
      token: token,
      newPassword: newPassword,
    );
  }

  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } catch (_) {
      // Still clear local tokens even if API fails
    }
    await SecureStorage.clearTokens();
  }

  Future<UserModel?> tryAutoLogin() async {
    final token = await SecureStorage.getAccessToken();
    if (token == null) return null;
    try {
      return await _remoteDataSource.getMe();
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasToken() async {
    final token = await SecureStorage.getAccessToken();
    return token != null;
  }

  Future<void> _persistTokens(AuthResponse response) async {
    await SecureStorage.saveTokens(
      accessToken: response.tokens.accessToken,
      refreshToken: response.tokens.refreshToken,
    );
  }
}
