import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/schedules_remote_datasource.dart';
import 'schedules_state.dart';

class SchedulesCubit extends Cubit<SchedulesState> {
  SchedulesCubit() : super(SchedulesState(focusedDay: _dateOnly(DateTime.now())));

  final SchedulesRemoteDataSource _dataSource = SchedulesRemoteDataSource();

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
}
