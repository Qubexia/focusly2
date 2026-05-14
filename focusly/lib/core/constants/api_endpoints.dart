import 'dart:io';

/// All backend API endpoint paths (v1).
class ApiEndpoints {
  ApiEndpoints._();

  // Base
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000'; // Android emulator
    }
    return 'http://localhost:3000'; // Windows/iOS/Web
  }

  // Auth
  static const String register = '/v1/auth/register';
  static const String login = '/v1/auth/login';
  static const String googleLogin = '/v1/auth/google';
  static const String refresh = '/v1/auth/refresh';
  static const String logout = '/v1/auth/logout';
  static const String logoutAll = '/v1/auth/logout-all';
  static const String forgotPassword = '/v1/auth/forgot-password';
  static const String resetPassword = '/v1/auth/reset-password';
  static const String verifyEmail = '/v1/auth/verify-email';
  static const String sessions = '/v1/auth/sessions';

  // Users
  static const String usersMe = '/v1/users/me';
  static const String usersSettings = '/v1/users/me/settings';
  static const String usersAvatar = '/v1/users/me/avatar';
  static const String usersFcmToken = '/v1/users/me/fcm-token';
}
