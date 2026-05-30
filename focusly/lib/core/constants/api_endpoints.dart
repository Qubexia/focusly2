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

  // Pomodoro
  static const String pomodoroStart = '/v1/pomodoro/start';
  static const String pomodoroToday = '/v1/pomodoro/today';
  static const String pomodoroHistory = '/v1/pomodoro/history';
  static String pomodoroPause(String id) => '/v1/pomodoro/$id/pause';
  static String pomodoroResume(String id) => '/v1/pomodoro/$id/resume';
  static String pomodoroComplete(String id) => '/v1/pomodoro/$id/complete';
  static String pomodoroAbort(String id) => '/v1/pomodoro/$id/abort';

  // Tasks
  static const String tasks = '/v1/tasks';
  static String taskById(String id) => '$tasks/$id';
  static String taskComplete(String id) => '$tasks/$id/complete';

  // Revisions
  static const String revisions = '/v1/revisions';
  static String revisionById(String id) => '$revisions/$id';
  static String revisionComplete(String id) => '$revisions/$id/complete';

  // Lectures
  static const String lectures = '/v1/lectures';
  static String lectureById(String id) => '$lectures/$id';
  static String lectureComplete(String id) => '$lectures/$id/complete';

  // Exams
  static const String exams = '/v1/exams';
  static String examById(String id) => '$exams/$id';
  static String examComplete(String id) => '$exams/$id/complete';

  // Schedules
  static const String schedules = '/v1/schedules';
  static const String schedulesCalendar = '/v1/schedules/calendar';
  static String scheduleById(String id) => '$schedules/$id';

  // Analytics
  static const String analytics = '/v1/analytics';
  static const String analyticsSummary = '$analytics/summary';
  static const String analyticsBySubject = '$analytics/by-subject';
  static const String analyticsHeatmap = '$analytics/heatmap';
  static const String analyticsPerformance = '$analytics/performance';

  // Streaks
  static const String streaksMe = '/v1/streaks/me';

  // Notifications
  static const String notifications = '/v1/notifications';
  static const String notificationsReadAll = '/v1/notifications/read-all';
  static const String notificationsPreferences = '/v1/notifications/preferences';
  static String notificationById(String id) => '$notifications/$id';
  static String notificationRead(String id) => '$notifications/$id/read';

  // Subscription
  static const String subscriptionMe = '/v1/subscription/me';
  static const String subscriptionStripeCheckout = '/v1/subscription/stripe/checkout';
  static const String subscriptionCancel = '/v1/subscription/cancel';
  static const String subscriptionPaymobCheckout = '/v1/subscription/paymob/checkout';

  // Uploads
  static const String uploadsPresign = '/v1/uploads/presign';
  static const String uploadsConfirm = '/v1/uploads/confirm';

  // AI
  static const String aiNotesJobs = '/v1/ai/notes/jobs';
  static String aiNotesJobById(String id) => '$aiNotesJobs/$id';
  static const String aiArtifacts = '/v1/ai/artifacts';

  // Auth sessions
  static String authSessionById(String id) => '$sessions/$id';
}
