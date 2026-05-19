class StreakModel {
  const StreakModel({
    required this.current,
    required this.longest,
    required this.points,
    this.lastActiveDate,
  });

  final int current;
  final int longest;
  final int points;
  final String? lastActiveDate;

  factory StreakModel.fromJson(Map<String, dynamic> json) {
    return StreakModel(
      current: _asInt(json['current']),
      longest: _asInt(json['longest']),
      points: _asInt(json['points']),
      lastActiveDate: json['lastActiveDate'] as String?,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
