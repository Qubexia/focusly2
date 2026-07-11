class AnalyticsSummaryModel {
  final int totalFocusMinutes;
  final int totalSessions;
  final int totalTasksCompleted;
  final int streak;
  final List<DailyFocusModel> dailyFocus;

  const AnalyticsSummaryModel({
    required this.totalFocusMinutes,
    required this.totalSessions,
    required this.totalTasksCompleted,
    required this.streak,
    required this.dailyFocus,
  });

  factory AnalyticsSummaryModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummaryModel(
      totalFocusMinutes: _asInt(json['totalFocusMinutes']),
      totalSessions: _asInt(json['totalSessions']),
      totalTasksCompleted: _asInt(
        json['totalTasksCompleted'] ?? json['totalPlannedItems'],
      ),
      streak: _asInt(json['streak'] ?? json['streakDays']),
      dailyFocus: (json['dailyFocus'] as List<dynamic>?)
              ?.map((e) => DailyFocusModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}

class DailyFocusModel {
  final String date;
  final int minutes;

  const DailyFocusModel({
    required this.date,
    required this.minutes,
  });

  factory DailyFocusModel.fromJson(Map<String, dynamic> json) {
    return DailyFocusModel(
      date: json['date'] as String? ?? '',
      minutes: _asInt(json['minutes']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}
