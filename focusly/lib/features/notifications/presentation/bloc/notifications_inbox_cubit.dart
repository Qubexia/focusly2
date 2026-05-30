import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/notification_inbox_model.dart';
import '../../data/repositories/notifications_repository.dart';

part 'notifications_inbox_state.dart';

class NotificationsInboxCubit extends Cubit<NotificationsInboxState> {
  NotificationsInboxCubit({NotificationsRepository? repository})
      : _repository = repository ?? NotificationsRepository(),
        super(const NotificationsInboxState());

  final NotificationsRepository _repository;

  Future<void> loadNotifications() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final notifications = await _repository.getNotifications();
      emit(
        state.copyWith(
          notifications: notifications,
          isLoading: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load notifications',
        ),
      );
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      await loadNotifications();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _repository.markAllRead();
      await loadNotifications();
    } catch (_) {}
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _repository.deleteNotification(id);
      await loadNotifications();
    } catch (_) {}
  }
}
