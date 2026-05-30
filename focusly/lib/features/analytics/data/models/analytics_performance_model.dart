class AnalyticsPerformanceModel {
  const AnalyticsPerformanceModel({
    required this.totalFocusMinutes,
    required this.totalSessions,
    required this.totalTasksCompleted,
    required this.streak,
  });

  final int totalFocusMinutes;
  final int totalSessions;
  final int totalTasksCompleted;
  final int streak;

  factory AnalyticsPerformanceModel.fromJson(Map<String, dynamic> json) {
    final totals = (json['totals'] as Map<String, dynamic>?) ?? json;
    return AnalyticsPerformanceModel(
      totalFocusMinutes: _asInt(totals['totalFocusMinutes']),
      totalSessions: _asInt(totals['totalSessions']),
      totalTasksCompleted: _asInt(totals['totalTasksCompleted']),
      streak: _asInt(totals['streak']),
    );
  }

  double get completionScore {
    final denom = totalTasksCompleted + totalSessions;
    if (denom == 0) return 0;
    return (totalTasksCompleted / denom).clamp(0.0, 1.0);
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}
