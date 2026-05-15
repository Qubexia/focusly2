enum PlannedItemType {
  task,
  revision,
  lecture,
  exam;

  String get key {
    switch (this) {
      case PlannedItemType.task:
        return 'task';
      case PlannedItemType.revision:
        return 'revision';
      case PlannedItemType.lecture:
        return 'lecture';
      case PlannedItemType.exam:
        return 'exam';
    }
  }

  static PlannedItemType fromKey(String key) {
    switch (key.toLowerCase()) {
      case 'revision':
        return PlannedItemType.revision;
      case 'lecture':
        return PlannedItemType.lecture;
      case 'exam':
        return PlannedItemType.exam;
      case 'task':
      default:
        return PlannedItemType.task;
    }
  }
}

class PlannedItemModel {
  final String id;
  final String title;
  final String? notes;
  final DateTime date;
  final String? time;
  final String? subjectId;
  final bool completed;
  final String type; // Using String to match backend but map to PlannedItemType locally

  const PlannedItemModel({
    required this.id,
    required this.title,
    this.notes,
    required this.date,
    this.time,
    this.subjectId,
    required this.completed,
    required this.type,
  });

  PlannedItemType get itemType => PlannedItemType.fromKey(type);

  factory PlannedItemModel.fromJson(Map<String, dynamic> json) {
    final plannedAt = _parseDate(json['plannedAt'] ?? json['date']);
    return PlannedItemModel(
      id: _stringifyId(json['id'] ?? json['_id']),
      title: _stringifyId(json['title']),
      notes: _nullableString(json['notes']),
      date: plannedAt,
      time: _extractTime(json['time'], plannedAt),
      subjectId: _nullableString(json['subjectId'] ?? json['subject']),
      completed: (json['completed'] ?? false) as bool,
      type: _stringifyId(json['type'] ?? json['kind'] ?? 'task'),
    );
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

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  static String? _extractTime(dynamic rawTime, DateTime plannedAt) {
    final parsed = _nullableString(rawTime);
    if (parsed != null && parsed.isNotEmpty) return parsed;

    final hasExplicitTime =
        plannedAt.hour != 0 || plannedAt.minute != 0 || plannedAt.second != 0;
    if (!hasExplicitTime) return null;

    final hours = plannedAt.hour.toString().padLeft(2, '0');
    final minutes = plannedAt.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
