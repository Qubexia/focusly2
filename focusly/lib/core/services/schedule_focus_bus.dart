import 'package:flutter/foundation.dart';

/// A request to open the Focus (Pomodoro) tab pre-configured for a study
/// schedule occurrence the user tapped.
@immutable
class ScheduleFocusLaunch {
  const ScheduleFocusLaunch({
    required this.scheduleId,
    required this.subjectId,
    required this.title,
    required this.sessionMinutes,
    required this.date,
  });

  final String scheduleId;
  final String? subjectId;
  final String title;
  final int sessionMinutes;

  /// The local occurrence date, formatted 'YYYY-MM-DD'.
  final String date;
}

/// A study schedule occurrence that was just completed via a focus session.
@immutable
class ScheduleCompletion {
  const ScheduleCompletion(this.scheduleId, this.date);

  final String scheduleId;
  final String date;

  String get key => '$scheduleId|$date';
}

/// Bridges the Schedules and Pomodoro tabs, which live as sibling tabs with
/// independent blocs. The Schedules tab pushes a [ScheduleFocusLaunch] when a
/// row is tapped; the Pomodoro tab pushes a [ScheduleCompletion] when the linked
/// session finishes so the row can show its checkmark.
class ScheduleFocusBus {
  ScheduleFocusBus._();

  static final ScheduleFocusBus instance = ScheduleFocusBus._();

  /// Pending launch request (null once consumed by the Pomodoro tab).
  final ValueNotifier<ScheduleFocusLaunch?> launch =
      ValueNotifier<ScheduleFocusLaunch?>(null);

  /// Most recently completed occurrence (observed by the Schedules tab).
  final ValueNotifier<ScheduleCompletion?> completed =
      ValueNotifier<ScheduleCompletion?>(null);

  void requestLaunch(ScheduleFocusLaunch request) => launch.value = request;

  void consumeLaunch() => launch.value = null;

  void markCompleted(ScheduleCompletion completion) =>
      completed.value = completion;
}
