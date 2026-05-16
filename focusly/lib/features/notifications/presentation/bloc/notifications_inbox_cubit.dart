import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/datasources/notifications_local_datasource.dart';
import '../../data/models/notification_inbox_model.dart';

part 'notifications_inbox_state.dart';

class NotificationsInboxCubit extends Cubit<NotificationsInboxState> {
  NotificationsInboxCubit() : super(const NotificationsInboxState());

  final NotificationsLocalDataSource _dataSource = NotificationsLocalDataSource();

  Future<void> loadNotifications() async {
    emit(state.copyWith(isLoading: true));
    try {
      final notifications = await _dataSource.getNotifications();
      emit(state.copyWith(
        notifications: notifications,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load notifications',
      ));
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _dataSource.markAsRead(id);
      await loadNotifications();
    } catch (_) {}
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _dataSource.deleteNotification(id);
      await loadNotifications();
    } catch (_) {}
  }

  Future<void> clearAll() async {
    try {
      await _dataSource.clearAll();
      emit(state.copyWith(notifications: []));
    } catch (_) {}
  }
}
