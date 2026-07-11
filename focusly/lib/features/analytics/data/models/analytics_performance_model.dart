class AnalyticsPerformanceModel {
  const AnalyticsPerformanceModel({
    required this.totalFocusMinutes,
    required this.totalSessions,
    required this.totalTasksCompleted,
    required this.streak,
    this.completionScoreOverride,
  });

  final int totalFocusMinutes;
  final int totalSessions;
  final int totalTasksCompleted;
  final int streak;
  final double? completionScoreOverride;

  factory AnalyticsPerformanceModel.fromJson(Map<String, dynamic> json) {
    final totals = (json['totals'] as Map<String, dynamic>?) ?? json;
    return AnalyticsPerformanceModel(
      totalFocusMinutes: _asInt(totals['totalFocusMinutes']),
      totalSessions: _asInt(totals['totalSessions']),
      totalTasksCompleted: _asInt(
        totals['totalTasksCompleted'] ?? totals['totalPlannedItems'],
      ),
      streak: _asInt(totals['streak'] ?? totals['streakDays']),
      completionScoreOverride: _asDouble(json['completionScore']),
    );
  }

  AnalyticsPerformanceModel mergeWithSummary({
    required int focusMinutes,
    required int sessions,
    required int tasksCompleted,
    required int streakDays,
  }) {
    final mergedFocus =
        totalFocusMinutes > 0 ? totalFocusMinutes : focusMinutes;
    final mergedSessions = totalSessions > 0 ? totalSessions : sessions;
    final mergedTasks =
        totalTasksCompleted > 0 ? totalTasksCompleted : tasksCompleted;
    final mergedStreak = streak > 0 ? streak : streakDays;
    final filledFromSummary = mergedFocus != totalFocusMinutes ||
        mergedSessions != totalSessions ||
        mergedTasks != totalTasksCompleted ||
        mergedStreak != streak;

    return AnalyticsPerformanceModel(
      totalFocusMinutes: mergedFocus,
      totalSessions: mergedSessions,
      totalTasksCompleted: mergedTasks,
      streak: mergedStreak,
      // Drop stale server score when we had to backfill from summary.
      completionScoreOverride:
          filledFromSummary ? null : completionScoreOverride,
    );
  }

  /// 0..1 score based on focus volume, sessions, tasks, and streak.
  double get completionScore {
    if (completionScoreOverride != null) {
      return completionScoreOverride!.clamp(0.0, 1.0);
    }

    if (totalFocusMinutes <= 0 &&
        totalSessions <= 0 &&
        totalTasksCompleted <= 0) {
      return 0;
    }

    // Local fallback when the API does not send completionScore yet.
    final focusRatio = (totalFocusMinutes / 175).clamp(0.0, 1.0); // ~25m × 7d
    final sessionRatio = (totalSessions / 7).clamp(0.0, 1.0);
    final taskRatio = totalTasksCompleted > 0
        ? (totalTasksCompleted / 7).clamp(0.0, 1.0)
        : focusRatio;
    final streakRatio = (streak / 7).clamp(0.0, 1.0);
    final score =
        0.45 * focusRatio + 0.25 * sessionRatio + 0.2 * taskRatio + 0.1 * streakRatio;
    return score.clamp(0.05, 1.0);
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return null;
  }
}
