import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/storage/secure_storage.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

/// Repository that orchestrates auth data source calls + token persistence.
class AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final NotificationService _notificationService = NotificationService();
  static const String _rememberMeKey = 'auth_remember_me';

  /// Last profile fetched from the server, so a launch with no connectivity can
  /// restore the session instead of dumping the user on the login screen.
  static const String _cachedUserKey = 'auth_cached_user';

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
    bool rememberMe = true,
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, rememberMe);
    await _syncFcmToken();
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
    await _syncFcmToken();
    return response;
  }

  Future<void> forgotPassword({required String email}) async {
    await _remoteDataSource.forgotPassword(email: email);
  }

  Future<String> verifyResetOtp({
    required String email,
    required String otp,
  }) {
    return _remoteDataSource.verifyResetOtp(email: email, otp: otp);
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
    await _endSession(await SharedPreferences.getInstance());
  }

  Future<UserModel?> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final remembered = prefs.getBool(_rememberMeKey) ?? true;
    if (!remembered) {
      await _endSession(prefs);
      await prefs.remove(_rememberMeKey);
      return null;
    }

    final token = await SecureStorage.getAccessToken();
    if (token == null) return null;

    try {
      // A 401 here is refreshed and retried by the API client's interceptor,
      // so reaching the catch means the session is gone or the server is not
      // reachable — two cases that must be handled very differently.
      final user = await fetchCurrentUser();
      await _cacheUser(prefs, user);
      await _syncFcmToken();
      return user;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _endSession(prefs);
        return null;
      }
      // Server unreachable, timed out, or erroring: the session is still valid,
      // so honour "keep me signed in" and carry on with the cached profile.
      return _readCachedUser(prefs);
    } catch (_) {
      return _readCachedUser(prefs);
    }
  }

  Future<UserModel> fetchCurrentUser() => _remoteDataSource.getMe();

  /// Rotates the token pair. Delegates to the API client so this shares the
  /// single-flight guard with the interceptor's own refresh — two rotations at
  /// once look like a stolen token to the server and kill the whole session.
  Future<bool> refreshSessionTokens() =>
      ApiClient.refreshSessionTokensIfNeeded();

  Future<bool> hasToken() async {
    final token = await SecureStorage.getAccessToken();
    return token != null;
  }

  Future<UserModel> updateProfile({
    required String name,
    String? avatarPath,
  }) async {
    String? avatarUrl;
    if (avatarPath != null && avatarPath.isNotEmpty) {
      avatarUrl = await _remoteDataSource.uploadAvatar(filePath: avatarPath);
    }

    final user = await _remoteDataSource.updateProfile(name: name);
    final updated = avatarUrl != null && avatarUrl.isNotEmpty
        ? UserModel(
            id: user.id,
            email: user.email,
            name: user.name,
            avatarUrl: avatarUrl,
            emailVerified: user.emailVerified,
            role: user.role,
            plan: user.plan,
            premiumUntil: user.premiumUntil,
            totalPoints: user.totalPoints,
          )
        : user;

    await _cacheUser(await SharedPreferences.getInstance(), updated);
    return updated;
  }

  Future<void> _persistTokens(AuthResponse response) async {
    await SecureStorage.saveTokens(
      accessToken: response.tokens.accessToken,
      refreshToken: response.tokens.refreshToken,
    );
    await _cacheUser(await SharedPreferences.getInstance(), response.user);
  }

  Future<void> _cacheUser(SharedPreferences prefs, UserModel user) async {
    await prefs.setString(_cachedUserKey, jsonEncode(user.toJson()));
  }

  UserModel? _readCachedUser(SharedPreferences prefs) {
    final raw = prefs.getString(_cachedUserKey);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Wipes every trace of the signed-in user.
  Future<void> _endSession(SharedPreferences prefs) async {
    await SecureStorage.clearTokens();
    await prefs.remove(_cachedUserKey);
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
