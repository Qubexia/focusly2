part of 'notifications_inbox_cubit.dart';

class NotificationsInboxState extends Equatable {
  final List<NotificationInboxModel> notifications;
  final bool isLoading;
  final String? errorMessage;

  const NotificationsInboxState({
    this.notifications = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  NotificationsInboxState copyWith({
    List<NotificationInboxModel>? notifications,
    bool? isLoading,
    String? errorMessage,
  }) {
    return NotificationsInboxState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  List<Object?> get props => [notifications, isLoading, errorMessage];
}
