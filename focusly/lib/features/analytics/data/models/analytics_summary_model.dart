class AnalyticsSummaryModel {
  final int totalFocusMinutes;
  final int totalSessions;
  final int totalTasksCompleted;
  /// Consecutive study days, not days inside the selected range.
  final int streak;

  /// Days inside the selected range that had any focus time.
  final int activeDays;

  /// Total days the selected range covers, in the user's own calendar.
  final int dayCount;
  final List<DailyFocusModel> dailyFocus;

  const AnalyticsSummaryModel({
    required this.totalFocusMinutes,
    required this.totalSessions,
    required this.totalTasksCompleted,
    required this.streak,
    required this.dailyFocus,
    this.activeDays = 0,
    this.dayCount = 0,
  });

  /// Minutes per day across the whole range — days without study included.
  int get averageDailyMinutes {
    final days = dayCount > 0 ? dayCount : dailyFocus.length;
    if (days <= 0) return 0;
    return (totalFocusMinutes / days).round();
  }

  factory AnalyticsSummaryModel.fromJson(Map<String, dynamic> json) {
    final dailyFocus = (json['dailyFocus'] as List<dynamic>?)
            ?.map((e) => DailyFocusModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return AnalyticsSummaryModel(
      totalFocusMinutes: _asInt(json['totalFocusMinutes']),
      totalSessions: _asInt(json['totalSessions']),
      totalTasksCompleted: _asInt(
        json['totalTasksCompleted'] ?? json['totalPlannedItems'],
      ),
      streak: _asInt(json['streak'] ?? json['streakDays']),
      activeDays: _asInt(json['activeDays']),
      dayCount: _asInt(json['dayCount']),
      dailyFocus: dailyFocus,
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
