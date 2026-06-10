import 'package:flutter/foundation.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/storage/secure_storage.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

/// Repository that orchestrates auth data source calls + token persistence.
class AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final NotificationService _notificationService = NotificationService();

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
    await _syncFcmToken();
    return response;
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final deviceId = await _getOrCreateDeviceId();
    final fcmToken = await _notificationService.getFcmToken();
    final response = await _remoteDataSource.login(
      email: email,
      password: password,
      deviceId: deviceId,
      fcmToken: fcmToken,
    );
    await _persistTokens(response);
    return response;
  }

  Future<AuthResponse> googleLogin({required String idToken}) async {
    final deviceId = await _getOrCreateDeviceId();
    final fcmToken = await _notificationService.getFcmToken();
    final response = await _remoteDataSource.googleLogin(
      idToken: idToken,
      deviceId: deviceId,
      fcmToken: fcmToken,
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

  Future<void> verifyEmail({required String token}) async {
    await _remoteDataSource.verifyEmail(token: token);
  }

  Future<void> resendVerificationEmail() async {
    await _remoteDataSource.resendVerificationEmail();
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
      final user = await fetchCurrentUser();
      await _syncFcmToken();
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> fetchCurrentUser() => _remoteDataSource.getMe();

  Future<bool> refreshSessionTokens() async {
    final refreshToken = await SecureStorage.getRefreshToken();
    final deviceId = await SecureStorage.getDeviceId();
    if (refreshToken == null || deviceId == null) return false;

    try {
      final data = await _remoteDataSource.refreshSession(
        refreshToken: refreshToken,
        deviceId: deviceId,
      );
      await SecureStorage.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasToken() async {
    final token = await SecureStorage.getAccessToken();
    return token != null;
  }

  Future<UserModel> updateProfile({
    required String name,
    String? avatarPath,
  }) async {
    if (avatarPath != null && avatarPath.isNotEmpty) {
      await _remoteDataSource.uploadAvatar(filePath: avatarPath);
    }

    return _remoteDataSource.updateProfile(name: name);
  }

  Future<void> _persistTokens(AuthResponse response) async {
    await SecureStorage.saveTokens(
      accessToken: response.tokens.accessToken,
      refreshToken: response.tokens.refreshToken,
    );
  }

  Future<void> _syncFcmToken() async {
    try {
      final fcmToken = await _notificationService.getFcmToken();
      if (fcmToken == null || fcmToken.isEmpty) return;
      await _remoteDataSource.updateFcmToken(fcmToken: fcmToken);
    } catch (_) {
      // FCM sync should not block auth flow
    }
  }
}
