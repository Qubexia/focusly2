import 'pomodoro_session_model.dart';

class PomodoroTodayModel {
  final List<PomodoroSessionModel> sessions;
  final int totalFocusMinutes;
  final PomodoroSessionModel? activeSession;

  const PomodoroTodayModel({
    required this.sessions,
    required this.totalFocusMinutes,
    this.activeSession,
  });

  factory PomodoroTodayModel.fromJson(Map<String, dynamic> json) {
    final rawSessions = (json['sessions'] as List<dynamic>? ?? const []);
    return PomodoroTodayModel(
      sessions: rawSessions
          .map(
            (item) =>
                PomodoroSessionModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      totalFocusMinutes: _asInt(json['totalFocusMinutes'], fallback: 0),
      activeSession: json['activeSession'] is Map<String, dynamic>
          ? PomodoroSessionModel.fromJson(
              json['activeSession'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  static int _asInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }
}
