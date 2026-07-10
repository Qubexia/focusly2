import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

class NotificationPreferences {
  const NotificationPreferences({
    this.reminders = true,
    this.streak = true,
    this.marketing = false,
  });

  final bool reminders;
  final bool streak;
  final bool marketing;

  NotificationPreferences copyWith({
    bool? reminders,
    bool? streak,
    bool? marketing,
  }) {
    return NotificationPreferences(
      reminders: reminders ?? this.reminders,
      streak: streak ?? this.streak,
      marketing: marketing ?? this.marketing,
    );
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const NotificationPreferences();
    return NotificationPreferences(
      reminders: (json['reminders'] ?? true) as bool,
      streak: (json['streak'] ?? true) as bool,
      marketing: (json['marketing'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'reminders': reminders,
        'streak': streak,
        'marketing': marketing,
      };
}

class AuthSessionModel {
  const AuthSessionModel({
    required this.id,
    required this.deviceLabel,
    required this.createdAt,
    this.current = false,
  });

  final String id;
  final String deviceLabel;
  final DateTime? createdAt;
  final bool current;

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      deviceLabel: (json['deviceLabel'] ?? json['userAgent'] ?? 'Device').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      current: (json['current'] ?? false) as bool,
    );
  }
}

class ProfileRemoteDataSource {
  final Dio _dio = ApiClient.instance;

  Future<NotificationPreferences> getNotificationPreferences() async {
    final response = await _dio.get(ApiEndpoints.notificationsPreferences);
    return NotificationPreferences.fromJson(
      response.data as Map<String, dynamic>?,
    );
  }

  Future<bool> getFocusMode() async {
    final response = await _dio.get(ApiEndpoints.usersMe);
    final data = response.data as Map<String, dynamic>?;
    final settings = data?['settings'] as Map<String, dynamic>?;
    return (settings?['focusMode'] ?? false) as bool;
  }

  Future<void> updateSettings({
    String? locale,
    String? timezone,
    bool? focusMode,
    NotificationPreferences? notifications,
  }) async {
    await _dio.patch(
      ApiEndpoints.usersSettings,
      data: {
        if (locale != null) 'locale': locale,
        if (timezone != null) 'timezone': timezone,
        if (focusMode != null) 'focusMode': focusMode,
        if (notifications != null)
          'notifications': notifications.toJson(),
      },
    );
  }

  Future<List<AuthSessionModel>> getSessions() async {
    final response = await _dio.get(ApiEndpoints.sessions);
    final data = response.data as List<dynamic>;
    return data
        .map((s) => AuthSessionModel.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<void> revokeSession(String sessionId) async {
    await _dio.delete(ApiEndpoints.authSessionById(sessionId));
  }

  Future<void> deleteAccount() async {
    await _dio.delete(ApiEndpoints.usersMe);
  }
}
