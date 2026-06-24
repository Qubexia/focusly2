class SubjectModel {
  final String id;
  final String name;
  final String? color;
  final String? icon;
  final int dailyTargetMinutes;
  final String goalType; // 'daily' | 'weekly'
  final List<int> goalDays; // 0=Sun..6=Sat; empty = every day
  final int progressPercent;
  final bool isArchived;

  const SubjectModel({
    required this.id,
    required this.name,
    this.color,
    this.icon,
    required this.dailyTargetMinutes,
    this.goalType = 'daily',
    this.goalDays = const [],
    required this.progressPercent,
    required this.isArchived,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: _stringifyId(json['id'] ?? json['_id']),
      name: _stringifyId(json['name']),
      color: _nullableString(json['color']),
      icon: _nullableString(json['icon']),
      dailyTargetMinutes: _asInt(json['dailyTargetMinutes'], fallback: 0),
      goalType: (json['goalType'] ?? 'daily') as String,
      goalDays: _asIntList(json['goalDays']),
      progressPercent: _asInt(json['progressPercent'], fallback: 0),
      isArchived: (json['isArchived'] ?? false) as bool,
    );
  }

  static List<int> _asIntList(dynamic value) {
    if (value is List) {
      return value.map((e) => _asInt(e, fallback: 0)).toList();
    }
    return const [];
  }

  static String _stringifyId(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static int _asInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }
}
