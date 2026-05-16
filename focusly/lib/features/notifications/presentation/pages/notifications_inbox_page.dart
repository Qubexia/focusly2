import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/notifications_inbox_cubit.dart';
import '../../data/models/notification_inbox_model.dart';

class NotificationsInboxPage extends StatelessWidget {
  const NotificationsInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationsInboxCubit()..loadNotifications(),
      child: const _NotificationsInboxView(),
    );
  }
}

class _NotificationsInboxView extends StatelessWidget {
  const _NotificationsInboxView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          BlocBuilder<NotificationsInboxCubit, NotificationsInboxState>(
            builder: (context, state) {
              if (state.notifications.isEmpty) return const SizedBox.shrink();
              return IconButton(
                onPressed: () => _showClearAllDialog(context),
                icon: const Icon(Icons.delete_sweep_rounded),
                tooltip: 'Clear All',
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsInboxCubit, NotificationsInboxState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.notifications.isEmpty) {
            return _buildEmptyState(context, isDark);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.notifications.length,
            itemBuilder: (context, index) {
              final notification = state.notifications[index];
              return _NotificationTile(
                notification: notification,
                onDelete: () => context
                    .read<NotificationsInboxCubit>()
                    .deleteNotification(notification.id),
                onTap: () => context
                    .read<NotificationsInboxCubit>()
                    .markAsRead(notification.id),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 80,
            color: AppColors.primary.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'Your inbox is empty',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We will notify you about your study progress.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<NotificationsInboxCubit>().clearAll();
              Navigator.pop(dialogContext);
            },
            child: const Text('Clear All', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onDelete,
    required this.onTap,
  });

  final NotificationInboxModel notification;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat.jm().format(notification.createdAt);
    final dateStr = DateFormat.MMMd().format(notification.createdAt);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: notification.isRead
                  ? (isDark ? AppColors.borderDark : AppColors.borderLight)
                  : AppColors.primary.withValues(alpha: 0.3),
            ),
            boxShadow: notification.isRead
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(notification.type),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead ? FontWeight.bold : FontWeight.w900,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$dateStr • $timeStr',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(String? type) {
    IconData icon;
    Color color;

    if (type != null && type.contains('pomodoro')) {
      icon = Icons.timer_rounded;
      color = AppColors.primary;
    } else if (type != null && type.contains('schedule')) {
      icon = Icons.calendar_today_rounded;
      color = AppColors.secondary;
    } else {
      icon = Icons.notifications_rounded;
      color = Colors.blueAccent;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}
