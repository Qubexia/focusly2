import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../data/datasources/schedules_remote_datasource.dart';
import 'schedules_state.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/models/schedule_model.dart';

class SchedulesCubit extends Cubit<SchedulesState> {
  SchedulesCubit() : super(SchedulesState(focusedDay: _dateOnly(DateTime.now())));

  final SchedulesRemoteDataSource _dataSource = SchedulesRemoteDataSource();
  final NotificationService _notificationService = NotificationService();

  Future<void> loadSchedules({DateTime? from, DateTime? to}) async {
    final start = from ??
        DateTime(state.focusedDay.year, state.focusedDay.month,
            state.focusedDay.day - 7);
    final end = to ??
        DateTime(state.focusedDay.year, state.focusedDay.month,
            state.focusedDay.day + 7);

    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final schedules = await _dataSource.getSchedules(from: start, to: end);
      emit(state.copyWith(
        schedules: schedules,
        isLoading: false,
      ));
      _syncNotifications(schedules);
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load schedules: ${e.toString()}',
      ));
    }
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
        feedbackMessage: 'Schedule created successfully!',
      ));

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
        feedbackMessage: 'Failed to create schedule: ${e.toString()}',
      ));
    }
  }

  Future<void> deleteSchedule(String id) async {
    try {
      await _dataSource.deleteSchedule(id);
      emit(state.copyWith(
        feedbackType: SchedulesFeedbackType.success,
        feedbackMessage: 'Schedule deleted.',
      ));
      await loadSchedules();
    } catch (e) {
      emit(state.copyWith(
        feedbackType: SchedulesFeedbackType.error,
        feedbackMessage: 'Failed to delete schedule.',
      ));
    }
  }

  void updateFocusedDay(DateTime day) {
    emit(state.copyWith(focusedDay: _dateOnly(day)));
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

    return 'Failed to create schedule. Please check the selected data.';
  }

  Future<void> _syncNotifications(List<StudyScheduleModel> schedules) async {
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
            title: 'Study Reminder: ${schedule.title}',
            body: 'Your study session starts in ${schedule.reminderMinutesBefore} minutes.',
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
