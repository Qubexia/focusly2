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
      totalFocusMinutes: json['totalFocusMinutes'] as int? ?? 0,
      totalSessions: json['totalSessions'] as int? ?? 0,
      totalTasksCompleted: json['totalTasksCompleted'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      dailyFocus: (json['dailyFocus'] as List<dynamic>?)
              ?.map((e) => DailyFocusModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
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
      minutes: json['minutes'] as int? ?? 0,
    );
  }
}
