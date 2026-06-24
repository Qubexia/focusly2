class PomodoroSessionModel {
  final String id;
  final String? subjectId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int focusMinutes;
  final int breakMinutes;
  final int sessionMinutes;
  final String breakMode;
  final int completedCycles;
  final int totalFocusMinutes;
  final String status;
  final DateTime lastTickAt;

  const PomodoroSessionModel({
    required this.id,
    this.subjectId,
    required this.startedAt,
    this.endedAt,
    required this.focusMinutes,
    required this.breakMinutes,
    required this.sessionMinutes,
    this.breakMode = 'cycles',
    required this.completedCycles,
    required this.totalFocusMinutes,
    required this.status,
    required this.lastTickAt,
  });

  factory PomodoroSessionModel.fromJson(Map<String, dynamic> json) {
    return PomodoroSessionModel(
      id: _stringifyId(json['id'] ?? json['_id']),
      subjectId: _nullableStringifyId(json['subjectId']),
      startedAt: _parseDate(json['startedAt']) ?? DateTime.now(),
      endedAt: _parseDate(json['endedAt']),
      focusMinutes: _asInt(json['focusMinutes'], fallback: 25),
      breakMinutes: _asInt(json['breakMinutes'], fallback: 5),
      sessionMinutes: _asInt(json['sessionMinutes'], fallback: 120),
      breakMode: (json['breakMode'] ?? 'cycles') as String,
      completedCycles: _asInt(json['completedCycles'], fallback: 0),
      totalFocusMinutes: _asInt(json['totalFocusMinutes'], fallback: 0),
      status: (json['status'] ?? 'active') as String,
      lastTickAt: _parseDate(json['lastTickAt']) ?? DateTime.now(),
    );
  }

  static String _stringifyId(dynamic value) {
    if (value == null) return '';
    if (value is Map<String, dynamic>) {
      final nestedId = value['id'] ?? value['_id'] ?? value[r'$oid'];
      if (nestedId != null) return _stringifyId(nestedId);
    }
    if (value is String) return value;
    return value.toString();
  }

  static String? _nullableStringifyId(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) {
      final nestedId = value['id'] ?? value['_id'] ?? value[r'$oid'];
      if (nestedId != null) return _stringifyId(nestedId);
      return null;
    }
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
