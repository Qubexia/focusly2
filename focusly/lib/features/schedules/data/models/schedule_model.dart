
class StudyScheduleModel {
  final String id;
  final String subjectId;
  final String title;
  final DateTime startAt;
  final DateTime? endAt;
  final List<int> daysOfWeek;
  final int reminderMinutesBefore;
  final bool reminderEnabled;
  final bool isActive;

  const StudyScheduleModel({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.startAt,
    this.endAt,
    required this.daysOfWeek,
    required this.reminderMinutesBefore,
    required this.reminderEnabled,
    required this.isActive,
  });

  factory StudyScheduleModel.fromJson(Map<String, dynamic> json) {
    return StudyScheduleModel(
      id: _stringifyId(json['id'] ?? json['_id']),
      subjectId: _stringifyId(json['subjectId']),
      title: _stringifyId(json['title']),
      startAt: _parseDate(json['startAt']),
      endAt: json['endAt'] != null ? _parseDate(json['endAt']) : null,
      daysOfWeek: _asIntList(json['daysOfWeek']),
      reminderMinutesBefore: _asInt(json['reminderMinutesBefore'], fallback: 15),
      reminderEnabled: (json['reminderEnabled'] ?? true) as bool,
      isActive: (json['isActive'] ?? true) as bool,
    );
  }

  static String _stringifyId(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  static List<int> _asIntList(dynamic value) {
    if (value is List) {
      return value.map((e) => _asInt(e, fallback: 0)).toList();
    }
    return [];
  }

  static int _asInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}
