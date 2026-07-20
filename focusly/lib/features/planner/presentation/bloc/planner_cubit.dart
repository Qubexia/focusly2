import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zakerly/core/localization/app_l10n.dart';
import '../../data/models/planned_item_model.dart';
import '../../data/repositories/planner_repository.dart';
import '../../data/services/planner_reminder_sync.dart';

part 'planner_state.dart';

class PlannerCubit extends Cubit<PlannerState> {
  PlannerCubit({
    PlannerRepository? repository,
    PlannerReminderSync? reminderSync,
    this.subjectId,
  })  : _repository = repository ?? PlannerRepository(),
        _reminderSync = reminderSync ?? PlannerReminderSync(),
        super(PlannerState(selectedDate: DateTime.now()));

  final PlannerRepository _repository;
  final PlannerReminderSync _reminderSync;

  /// When set, the planner only loads/creates items scoped to this subject.
  final String? subjectId;

  Future<void> loadDate(DateTime date) async {
    emit(state.copyWith(selectedDate: date, isLoading: true, clearError: true));

    final dateStr = _formatDate(date);

    try {
      final results = await Future.wait([
        _repository.getItems(type: PlannedItemType.task, from: dateStr, to: dateStr, subjectId: subjectId),
        _repository.getItems(type: PlannedItemType.revision, from: dateStr, to: dateStr, subjectId: subjectId),
        _repository.getItems(type: PlannedItemType.lecture, from: dateStr, to: dateStr, subjectId: subjectId),
        _repository.getItems(type: PlannedItemType.exam, from: dateStr, to: dateStr, subjectId: subjectId),
      ]);

      // The API returns recurring items as rules, not occurrences, so they are
      // expanded here against the viewer's own calendar.
      final tasks = _occurrencesOn(results[0], date);
      final revisions = _occurrencesOn(results[1], date);
      final lectures = _occurrencesOn(results[2], date);
      final exams = _occurrencesOn(results[3], date);

      emit(state.copyWith(
        isLoading: false,
        tasks: tasks,
        revisions: revisions,
        lectures: lectures,
        exams: exams,
      ));

      await _reminderSync.syncItems([
        ...tasks,
        ...revisions,
        ...lectures,
        ...exams,
      ]);
    } on DioException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: _extractMessage(e),
      ));
    } catch (_) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: AppL10n.current.plannerLoadFailed,
      ));
    }
  }

  Future<void> createItem({
    required PlannedItemType type,
    required String title,
    String? notes,
    required DateTime date,
    String? time,
    String? subjectId,
    int? reminderMinutesBefore,
    String? recurrence,
    List<int>? daysOfWeek,
    DateTime? recurrenceEndAt,
  }) async {
    emit(state.copyWith(isSaving: true));
    try {
      final due = _composeDueDateTime(date, time);
      final reminderEnabled = reminderMinutesBefore != null;

      final created = await _repository.createItem(
        type: type,
        title: title,
        notes: notes,
        plannedAt: due.toUtc().toIso8601String(),
        subjectId: subjectId ?? this.subjectId,
        reminderMinutesBefore: reminderMinutesBefore,
        reminderEnabled: reminderEnabled,
        recurrence: recurrence,
        daysOfWeek: daysOfWeek,
        recurrenceEndAt: recurrenceEndAt?.toUtc().toIso8601String(),
      );

      try {
        await _reminderSync.scheduleNewItem(
          itemId: created.id,
          title: title,
          type: type,
          due: due,
          reminderMinutesBefore: reminderMinutesBefore,
          reminderEnabled: reminderEnabled,
        );
      } catch (e, st) {
        developer.log(
          'Reminder scheduling failed after create (item persisted): $e',
          name: 'PlannerNotifications',
          stackTrace: st,
        );
      }

      emit(state.copyWith(
        isSaving: false,
        feedbackType: PlannerFeedbackType.success,
        feedbackMessage: AppL10n.current.plannerCreateSuccess,
      ));

      await loadDate(state.selectedDate);
    } on DioException catch (e) {
      emit(state.copyWith(
        isSaving: false,
        feedbackType: PlannerFeedbackType.error,
        feedbackMessage: _extractMessage(e),
      ));
    } catch (_) {
      emit(state.copyWith(
        isSaving: false,
        feedbackType: PlannerFeedbackType.error,
        feedbackMessage: AppL10n.current.plannerCreateFailed,
      ));
    }
  }

  Future<void> completeItem(PlannedItemType type, PlannedItemModel item) async {
    try {
      await _repository.completeItem(
        type: type,
        id: item.id,
        occurrenceDate: item.occurrenceDate,
      );
      await _reminderSync.cancelItem(item.notificationKey);
      await loadDate(state.selectedDate);

      emit(state.copyWith(
        feedbackType: PlannerFeedbackType.success,
        feedbackMessage: AppL10n.current.plannerCompleteSuccess,
      ));
    } catch (e) {
      emit(state.copyWith(
        feedbackType: PlannerFeedbackType.error,
        feedbackMessage: AppL10n.current.plannerCompleteFailed,
      ));
    }
  }

  Future<void> deleteItem(PlannedItemType type, String id) async {
    try {
      await _repository.deleteItem(type: type, id: id);
      await _reminderSync.cancelItem(id);
      await loadDate(state.selectedDate);

      emit(state.copyWith(
        feedbackType: PlannerFeedbackType.success,
        feedbackMessage: AppL10n.current.plannerDeleteSuccess,
      ));
    } catch (e) {
      emit(state.copyWith(
        feedbackType: PlannerFeedbackType.error,
        feedbackMessage: AppL10n.current.plannerDeleteFailed,
      ));
    }
  }

  void clearFeedback() {
    emit(state.copyWith(clearFeedback: true));
  }

  /// This day's items, with recurring rules expanded and the occurrences the
  /// user already ticked off dropped.
  List<PlannedItemModel> _occurrencesOn(
    List<PlannedItemModel> items,
    DateTime day,
  ) {
    return expandPlannedOccurrences(items, from: day, to: day)
        .where((item) => !item.completed)
        .toList();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  DateTime _composeDueDateTime(DateTime date, String? time) {
    final parsedTime = _parseTime(time);
    var due = DateTime(
      date.year,
      date.month,
      date.day,
      parsedTime?.$1 ?? 9,
      parsedTime?.$2 ?? 0,
    );

    // Tasks without an explicit time default to 09:00. If that moment already
    // passed today, nudge to 30 minutes from now so reminders can still fire.
    if (parsedTime == null && !due.isAfter(DateTime.now())) {
      final now = DateTime.now();
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        due = now.add(const Duration(minutes: 30));
      }
    }

    return due;
  }

  (int, int)? _parseTime(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final ascii = value.replaceAllMapped(
      RegExp('[٠-٩]'),
      (m) => '٠١٢٣٤٥٦٧٨٩'.indexOf(m[0]!).toString(),
    );
    final normalized = ascii.trim().toUpperCase();
    final isPm = normalized.endsWith('PM');
    final isAm = normalized.endsWith('AM');
    final timePart = normalized
        .replaceAll('AM', '')
        .replaceAll('PM', '')
        .trim();
    final pieces = timePart.split(':');
    if (pieces.length != 2) return null;

    final rawHour = int.tryParse(pieces[0]);
    final rawMinute = int.tryParse(pieces[1]);
    if (rawHour == null || rawMinute == null) return null;

    var hour = rawHour;
    if (isPm && hour < 12) hour += 12;
    if (isAm && hour == 12) hour = 0;

    return (hour, rawMinute);
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return (data['message'] as String?) ?? AppL10n.current.commonError;
    }
    return AppL10n.current.commonError;
  }
}
