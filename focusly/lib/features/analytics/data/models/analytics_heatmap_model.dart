class AnalyticsHeatmapDay {
  const AnalyticsHeatmapDay({
    required this.date,
    required this.focusMinutes,
  });

  final String date;
  final int focusMinutes;

  factory AnalyticsHeatmapDay.fromJson(Map<String, dynamic> json) {
    return AnalyticsHeatmapDay(
      date: (json['date'] as String?) ?? '',
      focusMinutes: _asInt(json['focusMinutes']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}

class AnalyticsHeatmapModel {
  const AnalyticsHeatmapModel({
    required this.year,
    required this.days,
  });

  final int year;
  final List<AnalyticsHeatmapDay> days;

  factory AnalyticsHeatmapModel.fromJson(Map<String, dynamic> json) {
    final rawDays = (json['days'] as List<dynamic>? ?? const []);
    return AnalyticsHeatmapModel(
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      days: rawDays
          .map(
            (d) => AnalyticsHeatmapDay.fromJson(d as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  int get maxMinutes {
    if (days.isEmpty) return 0;
    return days.map((d) => d.focusMinutes).reduce((a, b) => a > b ? a : b);
  }
}
