import '../datasources/notifications_local_datasource.dart';
import '../datasources/notifications_remote_datasource.dart';
import '../models/notification_inbox_model.dart';

class NotificationsRepository {
  NotificationsRepository({
    NotificationsRemoteDataSource? remoteDataSource,
    NotificationsLocalDataSource? localDataSource,
  })  : _remote = remoteDataSource ?? NotificationsRemoteDataSource(),
        _local = localDataSource ?? NotificationsLocalDataSource();

  final NotificationsRemoteDataSource _remote;
  final NotificationsLocalDataSource _local;

  Future<List<NotificationInboxModel>> getNotifications() async {
    try {
      return await _remote.getNotifications();
    } catch (_) {
      return _local.getNotifications();
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _remote.markAsRead(id);
    } catch (_) {
      await _local.markAsRead(id);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _remote.markAllRead();
    } catch (_) {
      final items = await _local.getNotifications();
      for (final item in items) {
        if (!item.isRead) {
          await _local.markAsRead(item.id);
        }
      }
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _remote.deleteNotification(id);
    } catch (_) {
      await _local.deleteNotification(id);
    }
  }

  Future<void> cachePushNotification(NotificationInboxModel notification) {
    return _local.saveNotification(notification);
  }
}
