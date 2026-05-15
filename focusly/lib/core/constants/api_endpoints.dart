import 'package:flutter/foundation.dart';

/// All backend API endpoint paths (v1).
class ApiEndpoints {
  ApiEndpoints._();

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  // Base
  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    if (kIsWeb) {
      final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
      final scheme = Uri.base.scheme.isEmpty ? 'http' : Uri.base.scheme;
      return '$scheme://$host:5000';
    }

    // IMPORTANT: If testing on a physical Android device, use your PC's local IP (e.g., 192.168.1.3)
    // 10.0.2.2 is only for the standard Android Emulator.
    const String localIp = '192.168.1.3'; 

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Try local IP first, then fallback to emulator loopback
        return 'http://$localIp:5000'; 
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return 'http://localhost:5000';
    }
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

  // Subjects
  static const String subjects = '/v1/subjects';

  static String subjectById(String id) => '$subjects/$id';
  static String subjectProgress(String id) => '$subjects/$id/progress';
  static String subjectChapters(String id) => '$subjects/$id/chapters';
  static String subjectChapterById(String subjectId, String chapterId) =>
      '$subjects/$subjectId/chapters/$chapterId';
}
