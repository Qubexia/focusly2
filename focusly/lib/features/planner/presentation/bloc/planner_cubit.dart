import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zakerly/core/localization/app_l10n.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/models/planned_item_model.dart';
import '../../data/repositories/planner_repository.dart';

part 'planner_state.dart';

class PlannerCubit extends Cubit<PlannerState> {
  PlannerCubit({
    PlannerRepository? repository,
    NotificationService? notificationService,
    this.subjectId,
  })  : _repository = repository ?? PlannerRepository(),
        _notificationService = notificationService ?? NotificationService(),
        super(PlannerState(selectedDate: DateTime.now()));

  final PlannerRepository _repository;
  final NotificationService _notificationService;

  /// When set, the planner only loads/creates items scoped to this subject.
  final String? subjectId;

  /// Stable notification id for the "due now" alert of an item.
  static int _dueNotificationId(String itemId) =>
      'planner_due_$itemId'.hashCode;

  /// Stable notification id for the "before due" reminder of an item.
  static int _reminderNotificationId(String itemId) =>
      'planner_reminder_$itemId'.hashCode;

  void _log(String message) =>
      developer.log(message, name: 'PlannerNotifications');

  Future<void> loadDate(DateTime date) async {
    emit(state.copyWith(selectedDate: date, isLoading: true, clearError: true));

    final dateStr = _formatDate(date);

    try {
      // Fetch all 4 categories in parallel
      final results = await Future.wait([
        _repository.getItems(type: PlannedItemType.task, from: dateStr, to: dateStr, subjectId: subjectId),
        _repository.getItems(type: PlannedItemType.revision, from: dateStr, to: dateStr, subjectId: subjectId),
        _repository.getItems(type: PlannedItemType.lecture, from: dateStr, to: dateStr, subjectId: subjectId),
        _repository.getItems(type: PlannedItemType.exam, from: dateStr, to: dateStr, subjectId: subjectId),
      ]);

      emit(state.copyWith(
        isLoading: false,
        tasks: results[0],
        revisions: results[1],
        lectures: results[2],
        exams: results[3],
      ));

      // Re-arm "due" notifications for the loaded items. zonedSchedule survives
      // app restarts and reboots, but re-syncing here heals any that were
      // dropped and covers items created on another device.
      await _syncDueNotifications([
        ...results[0],
        ...results[1],
        ...results[2],
        ...results[3],
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
  }) async {
    emit(state.copyWith(isSaving: true));
    try {
      final created = await _repository.createItem(
        type: type,
        title: title,
        notes: notes,
        plannedAt: _toPlannedAtIso(date, time),
        subjectId: subjectId ?? this.subjectId,
      );

      _log('Created item "${created.title}" (id=${created.id}, type=${type.key})');

      // Reminders are best-effort: a scheduling failure on release APKs
      // (exact-alarm permission, timezone, etc.) must not fail the create flow.
      try {
        await _scheduleItemReminders(
          itemId: created.id,
          title: title,
          type: type,
          due: _composeDueDateTime(date, time),
          reminderMinutesBefore: reminderMinutesBefore,
        );
      } catch (e, st) {
        _log('Reminder scheduling failed after create (item persisted): $e\n$st');
      }

      emit(state.copyWith(
        isSaving: false,
        feedbackType: PlannerFeedbackType.success,
        feedbackMessage: AppL10n.current.plannerCreateSuccess,
      ));
      
      // Refresh list for the selected date
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

  Future<void> completeItem(PlannedItemType type, String id) async {
    try {
      await _repository.completeItem(type: type, id: id);
      // A completed item no longer needs reminders.
      await _cancelItemReminders(id);
      // Refresh the date to get updated statuses and potentially points (though UI updates optimistically if we want)
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
      await _cancelItemReminders(id);
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _toPlannedAtIso(DateTime date, String? time) {
    return _composeDueDateTime(date, time).toIso8601String();
  }

  /// Combines the chosen [date] with the optional [time] string into a single
  /// local [DateTime]. When no time is given the item is treated as midnight.
  DateTime _composeDueDateTime(DateTime date, String? time) {
    final parsedTime = _parseTime(time);
    return DateTime(
      date.year,
      date.month,
      date.day,
      parsedTime?.$1 ?? 0,
      parsedTime?.$2 ?? 0,
    );
  }

  /// Schedules the "due now" alert and, when requested, a "before due"
  /// reminder for a freshly created item. Cancels any prior notifications for
  /// the same item first so re-creating/editing never stacks duplicates.
  Future<void> _scheduleItemReminders({
    required String itemId,
    required String title,
    required PlannedItemType type,
    required DateTime due,
    int? reminderMinutesBefore,
  }) async {
    if (itemId.isEmpty) {
      _log('Skipped scheduling — item has no id (title="$title")');
      return;
    }

    await _cancelItemReminders(itemId);

    final now = DateTime.now();
    final payload = 'planner:${type.key}:$itemId';

    // "Before due" reminder.
    if (reminderMinutesBefore != null && reminderMinutesBefore > 0) {
      final remindAt = due.subtract(Duration(minutes: reminderMinutesBefore));
      if (remindAt.isAfter(now)) {
        await _notificationService.scheduleNotification(
          id: _reminderNotificationId(itemId),
          title: AppL10n.current.plannerReminderNotificationTitle(title),
          body: AppL10n.current
              .plannerReminderNotificationBody(reminderMinutesBefore),
          scheduledDate: remindAt,
          payload: payload,
        );
        _log('Scheduled REMINDER for "$title" at $remindAt '
            '($reminderMinutesBefore min before due $due)');
      } else {
        _log('Skipped REMINDER for "$title" — $remindAt already passed');
      }
    }

    // "Due now" alert.
    if (due.isAfter(now)) {
      await _notificationService.scheduleNotification(
        id: _dueNotificationId(itemId),
        title: AppL10n.current.plannerDueNotificationTitle(title),
        body: AppL10n.current.plannerDueNotificationBody,
        scheduledDate: due,
        payload: payload,
      );
      _log('Scheduled DUE alert for "$title" at $due');
    } else {
      _log('Skipped DUE alert for "$title" — due $due already passed');
    }
  }

  /// Re-arms the "due now" alert for already-persisted items. Runs on every
  /// [loadDate] so reminders heal after the OS drops them. Inbox writes are
  /// suppressed here so repeated syncs don't pile up duplicate history rows.
  Future<void> _syncDueNotifications(List<PlannedItemModel> items) async {
    final now = DateTime.now();
    for (final item in items) {
      if (item.id.isEmpty || item.completed) continue;
      if (!item.date.isAfter(now)) continue;

      try {
        await _notificationService.scheduleNotification(
          id: _dueNotificationId(item.id),
          title: AppL10n.current.plannerDueNotificationTitle(item.title),
          body: AppL10n.current.plannerDueNotificationBody,
          scheduledDate: item.date,
          payload: 'planner:${item.type}:${item.id}',
          recordInInbox: false,
        );
      } catch (e) {
        _log('Skipped re-sync for "${item.title}": $e');
      }
    }
    _log('Re-synced due notifications for ${items.length} loaded item(s)');
  }

  Future<void> _cancelItemReminders(String itemId) async {
    if (itemId.isEmpty) return;
    await _notificationService.cancel(_dueNotificationId(itemId));
    await _notificationService.cancel(_reminderNotificationId(itemId));
  }

  (int, int)? _parseTime(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final normalized = value.trim().toUpperCase();
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
