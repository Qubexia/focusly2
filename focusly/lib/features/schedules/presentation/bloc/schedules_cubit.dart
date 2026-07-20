import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:zakerly/core/localization/app_l10n.dart';
import '../../data/datasources/schedules_remote_datasource.dart';
import 'schedules_state.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/schedule_focus_bus.dart';
import '../../data/models/schedule_model.dart';

class SchedulesCubit extends Cubit<SchedulesState> {
  SchedulesCubit()
      : super(SchedulesState(focusedDay: _dateOnly(DateTime.now()))) {
    _lastSeenRevision = ScheduleFocusBus.instance.revision.value;
    ScheduleFocusBus.instance.revision.addListener(_onSchedulesChangedElsewhere);
  }

  final SchedulesRemoteDataSource _dataSource = SchedulesRemoteDataSource();
  final NotificationService _notificationService = NotificationService();

  /// Guards against reacting to the bus bump this cubit itself published.
  int _lastSeenRevision = 0;

  /// Occurrence window the currently loaded [SchedulesState.completedKeys] came
  /// from, so browsing the calendar only re-fetches when it leaves that range.
  DateTime? _completionsFrom;
  DateTime? _completionsTo;

  @override
  Future<void> close() {
    ScheduleFocusBus.instance.revision
        .removeListener(_onSchedulesChangedElsewhere);
    return super.close();
  }

  void _onSchedulesChangedElsewhere() {
    final revision = ScheduleFocusBus.instance.revision.value;
    if (revision == _lastSeenRevision) return;
    _lastSeenRevision = revision;
    loadSchedules();
  }

  void _publishChange() {
    // Claim the next revision before publishing so our own listener skips it.
    _lastSeenRevision = ScheduleFocusBus.instance.revision.value + 1;
    ScheduleFocusBus.instance.notifySchedulesChanged();
  }

  Future<void> loadSchedules({DateTime? from, DateTime? to}) async {
    // Schedules recur weekly and the list filters by weekday, so a row must be
    // fetched even when its start date sits far outside the focused week.
    final today = _dateOnly(DateTime.now());
    final start = from ?? today.subtract(const Duration(days: 90));
    final end = to ?? today.add(const Duration(days: 365));

    // Completions are per-occurrence, so they stay scoped to the focused week.
    final completionsFrom = state.focusedDay.subtract(const Duration(days: 45));
    final completionsTo = state.focusedDay.add(const Duration(days: 45));

    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final schedules = await _dataSource.getSchedules(from: start, to: end);
      Set<String> completedKeys = state.completedKeys;
      try {
        completedKeys = await _dataSource.getCompletions(
          from: completionsFrom,
          to: completionsTo,
        );
        _completionsFrom = completionsFrom;
        _completionsTo = completionsTo;
      } catch (_) {
        // Keep schedules usable even if completion markers fail to load.
      }
      emit(state.copyWith(
        schedules: schedules,
        completedKeys: completedKeys,
        isLoading: false,
      ));
      _syncNotifications(schedules);
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: AppL10n.current.schedulesLoadFailed,
      ));
    }
  }

  /// Records a completed occurrence locally (already persisted on the backend by
  /// the focus session) so the row's checkmark appears immediately.
  void markScheduleCompletedLocally(String scheduleId, String date) {
    final key = '$scheduleId|$date';
    if (state.completedKeys.contains(key)) return;
    emit(state.copyWith(
      completedKeys: {...state.completedKeys, key},
    ));
  }

  static String completionKey(String scheduleId, DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$scheduleId|$y-$m-$d';
  }

  static String formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> createSchedule({
    required String subjectId,
    required String title,
    required DateTime startAt,
    DateTime? endAt,
    required List<int> daysOfWeek,
    int reminderMinutesBefore = 15,
    bool reminderEnabled = true,
  }) async {
    emit(state.copyWith(isSaving: true));

    try {
      await _dataSource.createSchedule(
        subjectId: subjectId,
        title: title,
        startAt: startAt,
        endAt: endAt,
        daysOfWeek: daysOfWeek,
        reminderMinutesBefore: reminderMinutesBefore,
        reminderEnabled: reminderEnabled,
      );

      emit(state.copyWith(
        isSaving: false,
        feedbackType: SchedulesFeedbackType.success,
        feedbackMessage: AppL10n.current.schedulesCreateSuccess,
      ));

      _publishChange();
      await loadSchedules();
    } on DioException catch (e) {
      emit(state.copyWith(
        isSaving: false,
        feedbackType: SchedulesFeedbackType.error,
        feedbackMessage: _extractErrorMessage(e),
      ));
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        feedbackType: SchedulesFeedbackType.error,
        feedbackMessage: AppL10n.current.schedulesCreateFailed,
      ));
    }
  }

  Future<void> updateSchedule({
    required String id,
    required String subjectId,
    required String title,
    required DateTime startAt,
    DateTime? endAt,
    required List<int> daysOfWeek,
    int reminderMinutesBefore = 15,
    bool reminderEnabled = true,
  }) async {
    emit(state.copyWith(isSaving: true));

    try {
      await _dataSource.updateSchedule(
        id: id,
        title: title,
        startAt: startAt,
        endAt: endAt,
        daysOfWeek: daysOfWeek,
        reminderMinutesBefore: reminderMinutesBefore,
        reminderEnabled: reminderEnabled,
      );

      emit(state.copyWith(
        isSaving: false,
        feedbackType: SchedulesFeedbackType.success,
        feedbackMessage: AppL10n.current.schedulesEditSuccess,
      ));

      _publishChange();
      await loadSchedules();
    } on DioException catch (e) {
      emit(state.copyWith(
        isSaving: false,
        feedbackType: SchedulesFeedbackType.error,
        feedbackMessage: _extractErrorMessage(e),
      ));
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        feedbackType: SchedulesFeedbackType.error,
        feedbackMessage: AppL10n.current.schedulesUpdateFailed,
      ));
    }
  }

  Future<bool> deleteSchedule(String id) async {
    try {
      await _dataSource.deleteSchedule(id);
      await _notificationService.cancel(id.hashCode);
      emit(state.copyWith(
        feedbackType: SchedulesFeedbackType.success,
        feedbackMessage: AppL10n.current.schedulesDeleteSuccess,
      ));
      _publishChange();
      await loadSchedules();
      return true;
    } catch (e) {
      emit(state.copyWith(
        feedbackType: SchedulesFeedbackType.error,
        feedbackMessage: AppL10n.current.schedulesDeleteFailed,
      ));
      return false;
    }
  }

  void updateFocusedDay(DateTime day) {
    final focused = _dateOnly(day);
    emit(state.copyWith(focusedDay: focused));

    final from = _completionsFrom;
    final to = _completionsTo;
    if (from == null || to == null) return;
    if (focused.isBefore(from) || focused.isAfter(to)) {
      loadSchedules();
    }
  }

  void clearFeedback() {
    emit(state.copyWith(clearFeedback: true));
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  int _apiWeekdayToDartWeekday(int weekday) {
    return weekday == 0 ? DateTime.sunday : weekday;
  }

  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
      if (message is List && message.isNotEmpty) {
        return message.join('\n');
      }
    }

    return AppL10n.current.schedulesCreateInvalidData;
  }

  Future<void> _syncNotifications(List<StudyScheduleModel> schedules) async {
    final ready = await _notificationService.ensureReadyForScheduling(
      requestIfMissing: true,
    );
    if (!ready) return;

    // Basic implementation: Schedule next occurrence for each active schedule
    for (final schedule in schedules) {
      if (!schedule.isActive || !schedule.reminderEnabled) {
        // Cancel existing if any (using hash of ID as notification ID)
        await _notificationService.cancel(schedule.id.hashCode);
        continue;
      }

      final nextOccurrence = _calculateNextOccurrence(schedule);
      if (nextOccurrence != null) {
        final scheduledDate = nextOccurrence.subtract(
          Duration(minutes: schedule.reminderMinutesBefore),
        );

        if (scheduledDate.isAfter(DateTime.now())) {
          await _notificationService.scheduleNotification(
            id: schedule.id.hashCode,
            title: AppL10n.current.schedulesReminderNotificationTitle(schedule.title),
            body: AppL10n.current
                .schedulesReminderNotificationBody(schedule.reminderMinutesBefore),
            scheduledDate: scheduledDate,
          );
        }
      }
    }
  }

  DateTime? _calculateNextOccurrence(StudyScheduleModel schedule) {
    final now = DateTime.now();
    // Simplified logic: find next day in daysOfWeek starting from today
    for (int i = 0; i <= 7; i++) {
      final date = now.add(Duration(days: i));
      final normalizedDays =
          schedule.daysOfWeek.map(_apiWeekdayToDartWeekday).toSet();
      if (normalizedDays.contains(date.weekday)) {
        final occurrence = DateTime(
          date.year,
          date.month,
          date.day,
          schedule.startAt.hour,
          schedule.startAt.minute,
        );
        if (occurrence.isAfter(now)) {
          return occurrence;
        }
      }
    }
    return null;
  }
}
