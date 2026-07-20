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

/// Turns recurrence rules into the concrete occurrences falling between [from]
/// and [to] (inclusive), passing one-off items through when they land in range.
///
/// The API returns a recurring item as a single rule, so every screen that
/// lists planner items by day has to expand it. Doing that here — client-side —
/// keeps weekdays in the viewer's own timezone, the one the user picked them in.
List<PlannedItemModel> expandPlannedOccurrences(
  List<PlannedItemModel> items, {
  required DateTime from,
  required DateTime to,
}) {
  final result = <PlannedItemModel>[];
  final start = DateTime(from.year, from.month, from.day);
  final end = DateTime(to.year, to.month, to.day);

  for (final item in items) {
    if (!item.isRecurring) {
      final day = DateTime(item.date.year, item.date.month, item.date.day);
      if (!day.isBefore(start) && !day.isAfter(end)) result.add(item);
      continue;
    }

    // Step by calendar day rather than by 24h so DST shifts cannot skip a day.
    for (
      var day = start;
      !day.isAfter(end);
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      final occurrence = item.occurrenceOn(day);
      if (occurrence != null) result.add(occurrence);
    }
  }

  return result;
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
  final int reminderMinutesBefore;
  final bool reminderEnabled;

  /// `once`, `daily` or `weekly`.
  final String recurrence;

  /// Weekdays a `weekly` item repeats on, Sun=0..Sat=6. Empty falls back to the
  /// weekday of [date].
  final List<int> daysOfWeek;

  /// Last day the recurrence yields occurrences. Null repeats indefinitely.
  final DateTime? recurrenceEndAt;

  /// `YYYY-MM-DD` of every occurrence already ticked off.
  final List<String> completedDates;

  /// Set only on an expanded occurrence — the day this copy stands for.
  final String? occurrenceDate;

  const PlannedItemModel({
    required this.id,
    required this.title,
    this.notes,
    required this.date,
    this.time,
    this.subjectId,
    required this.completed,
    required this.type,
    this.reminderMinutesBefore = 15,
    this.reminderEnabled = true,
    this.recurrence = 'once',
    this.daysOfWeek = const [],
    this.recurrenceEndAt,
    this.completedDates = const [],
    this.occurrenceDate,
  });

  PlannedItemType get itemType => PlannedItemType.fromKey(type);

  bool get isRecurring => recurrence == 'daily' || recurrence == 'weekly';

  /// Unique per occurrence, so one day's reminder cannot cancel another's.
  String get notificationKey =>
      occurrenceDate == null ? id : '$id@$occurrenceDate';

  /// Builds the occurrence of a recurring rule that falls on [day], or null
  /// when the rule does not fire that day. Expansion happens client-side so the
  /// weekdays are read in the viewer's own timezone, the same one the user
  /// picked them in.
  PlannedItemModel? occurrenceOn(DateTime day) {
    if (!isRecurring) return null;

    final target = DateTime(day.year, day.month, day.day);
    final start = DateTime(date.year, date.month, date.day);
    if (target.isBefore(start)) return null;

    final end = recurrenceEndAt;
    if (end != null && target.isAfter(DateTime(end.year, end.month, end.day))) {
      return null;
    }

    if (recurrence == 'weekly') {
      final days = daysOfWeek.isEmpty ? [_apiWeekday(date)] : daysOfWeek;
      if (!days.contains(_apiWeekday(target))) return null;
    }

    final occurrence = DateTime(
      target.year,
      target.month,
      target.day,
      date.hour,
      date.minute,
    );

    return copyWith(
      date: occurrence,
      completed: completedDates.contains(formatDate(target)),
      occurrenceDate: formatDate(target),
    );
  }

  PlannedItemModel copyWith({
    DateTime? date,
    bool? completed,
    String? occurrenceDate,
  }) {
    return PlannedItemModel(
      id: id,
      title: title,
      notes: notes,
      date: date ?? this.date,
      time: time,
      subjectId: subjectId,
      completed: completed ?? this.completed,
      type: type,
      reminderMinutesBefore: reminderMinutesBefore,
      reminderEnabled: reminderEnabled,
      recurrence: recurrence,
      daysOfWeek: daysOfWeek,
      recurrenceEndAt: recurrenceEndAt,
      completedDates: completedDates,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
    );
  }

  /// Dart's Mon=1..Sun=7 mapped to the API's Sun=0..Sat=6.
  static int _apiWeekday(DateTime date) => date.weekday % 7;

  static String formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  factory PlannedItemModel.fromJson(Map<String, dynamic> json) {
    final plannedAt = _parseDate(json['plannedAt'] ?? json['date']);
    return PlannedItemModel(
      id: _stringifyId(json['id'] ?? json['_id']),
      title: _stringifyId(json['title']),
      notes: _nullableString(json['notes']),
      date: plannedAt,
      time: _extractTime(json['time'], plannedAt),
      subjectId: _nullableString(json['subjectId'] ?? json['subject']),
      completed: _parseBool(json['completed']),
      type: _stringifyId(json['type'] ?? json['kind'] ?? 'task'),
      reminderMinutesBefore: (json['reminderMinutesBefore'] as num?)?.toInt() ?? 15,
      reminderEnabled: json['reminderEnabled'] is bool
          ? json['reminderEnabled'] as bool
          : _parseBool(json['reminderEnabled'] ?? true),
      recurrence: _stringifyId(json['recurrence'] ?? 'once'),
      daysOfWeek: _parseIntList(json['daysOfWeek']),
      recurrenceEndAt: json['recurrenceEndAt'] != null
          ? _parseDate(json['recurrenceEndAt'])
          : null,
      completedDates: _parseStringList(json['completedDates']),
    );
  }

  static List<int> _parseIntList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item is num ? item.toInt() : int.tryParse('$item'))
        .whereType<int>()
        .toList();
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => '$item').toList();
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

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    // The backend returns plannedAt in UTC ("...Z"). Convert to local so the
    // displayed time and the scheduled notification both use the device's
    // wall-clock time the user actually picked.
    if (value is String) return DateTime.parse(value).toLocal();
    if (value is DateTime) return value.toLocal();
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
