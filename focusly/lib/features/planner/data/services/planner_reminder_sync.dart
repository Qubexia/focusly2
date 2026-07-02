import 'dart:developer' as developer;

import 'package:zakerly/core/localization/app_l10n.dart';

import '../../../../core/services/notification_service.dart';
import '../models/planned_item_model.dart';

/// Shared local-notification scheduling for planner items.
class PlannerReminderSync {
  PlannerReminderSync({NotificationService? notificationService})
      : _notificationService = notificationService ?? NotificationService();

  final NotificationService _notificationService;

  static int dueNotificationId(String itemId) => 'planner_due_$itemId'.hashCode;

  static int reminderNotificationId(String itemId) =>
      'planner_reminder_$itemId'.hashCode;

  void _log(String message) =>
      developer.log(message, name: 'PlannerNotifications');

  Future<void> syncItems(List<PlannedItemModel> items) async {
    if (items.isEmpty) return;

    final ready = await _notificationService.ensureReadyForScheduling(
      requestIfMissing: true,
    );
    if (!ready) {
      _log('Skipped sync — notification permissions not granted');
      return;
    }

    final now = DateTime.now();
    for (final item in items) {
      if (item.id.isEmpty || item.completed || !item.reminderEnabled) {
        await cancelItem(item.id);
        continue;
      }
      if (!item.date.isAfter(now)) continue;

      final payload = 'planner:${item.type}:${item.id}';
      final offset = item.reminderMinutesBefore;

      if (offset > 0) {
        final remindAt = item.date.subtract(Duration(minutes: offset));
        if (remindAt.isAfter(now)) {
          try {
            await _notificationService.scheduleNotification(
              id: reminderNotificationId(item.id),
              title: AppL10n.current.plannerReminderNotificationTitle(item.title),
              body: AppL10n.current.plannerReminderNotificationBody(offset),
              scheduledDate: remindAt,
              payload: payload,
              recordInInbox: false,
            );
            _log('Synced REMINDER for "${item.title}" at $remindAt');
          } catch (e) {
            _log('Failed REMINDER sync for "${item.title}": $e');
          }
        }
      }

      try {
        await _notificationService.scheduleNotification(
          id: dueNotificationId(item.id),
          title: AppL10n.current.plannerDueNotificationTitle(item.title),
          body: AppL10n.current.plannerDueNotificationBody,
          scheduledDate: item.date,
          payload: payload,
          recordInInbox: false,
        );
        _log('Synced DUE for "${item.title}" at ${item.date}');
      } catch (e) {
        _log('Failed DUE sync for "${item.title}": $e');
      }
    }

    await _notificationService.logPendingNotifications();
  }

  Future<void> scheduleNewItem({
    required String itemId,
    required String title,
    required PlannedItemType type,
    required DateTime due,
    int? reminderMinutesBefore,
    bool reminderEnabled = true,
  }) async {
    if (itemId.isEmpty || !reminderEnabled || reminderMinutesBefore == null) {
      return;
    }

    final ready = await _notificationService.ensureReadyForScheduling(
      requestIfMissing: true,
    );
    if (!ready) {
      throw StateError('Notification permissions missing');
    }

    await cancelItem(itemId);

    final now = DateTime.now();
    final payload = 'planner:${type.key}:$itemId';

    if (reminderMinutesBefore > 0) {
      final remindAt = due.subtract(Duration(minutes: reminderMinutesBefore));
      if (remindAt.isAfter(now)) {
        await _notificationService.scheduleNotification(
          id: reminderNotificationId(itemId),
          title: AppL10n.current.plannerReminderNotificationTitle(title),
          body: AppL10n.current.plannerReminderNotificationBody(reminderMinutesBefore),
          scheduledDate: remindAt,
          payload: payload,
        );
        _log('Scheduled REMINDER for "$title" at $remindAt');
      }
    }

    if (due.isAfter(now)) {
      await _notificationService.scheduleNotification(
        id: dueNotificationId(itemId),
        title: AppL10n.current.plannerDueNotificationTitle(title),
        body: AppL10n.current.plannerDueNotificationBody,
        scheduledDate: due,
        payload: payload,
      );
      _log('Scheduled DUE for "$title" at $due');
    }
  }

  Future<void> cancelItem(String itemId) async {
    if (itemId.isEmpty) return;
    await _notificationService.cancel(dueNotificationId(itemId));
    await _notificationService.cancel(reminderNotificationId(itemId));
  }
}
