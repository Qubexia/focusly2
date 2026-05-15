class ChapterModel {
  final String id;
  final String subjectId;
  final String title;
  final int order;
  final bool completed;
  final DateTime? completedAt;

  const ChapterModel({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.order,
    required this.completed,
    this.completedAt,
  });

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      id: _stringifyId(json['id'] ?? json['_id']),
      subjectId: _stringifyId(json['subjectId']),
      title: (json['title'] ?? '') as String,
      order: _asInt(json['order'], fallback: 0),
      completed: (json['completed'] ?? false) as bool,
      completedAt: _parseDate(json['completedAt']),
    );
  }

  static String _stringifyId(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  static int _asInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
