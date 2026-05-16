import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_inbox_model.dart';

class NotificationsLocalDataSource {
  static const String _storageKey = 'notifications_inbox';

  Future<List<NotificationInboxModel>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data == null) return [];

    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((j) => NotificationInboxModel.fromJson(j)).toList();
  }

  Future<void> saveNotification(NotificationInboxModel notification) async {
    final notifications = await getNotifications();
    notifications.insert(0, notification); // Newest first
    
    // Keep only last 50 notifications to save space
    if (notifications.length > 50) {
      notifications.removeRange(50, notifications.length);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(notifications.map((n) => n.toJson()).toList()));
  }

  Future<void> markAsRead(String id) async {
    final notifications = await getNotifications();
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(notifications.map((n) => n.toJson()).toList()));
    }
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> deleteNotification(String id) async {
    final notifications = await getNotifications();
    notifications.removeWhere((n) => n.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(notifications.map((n) => n.toJson()).toList()));
  }
}
