import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/notifications/data/datasources/notifications_local_datasource.dart';
import '../../features/notifications/data/models/notification_inbox_model.dart';
import '../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final NotificationsLocalDataSource _localDataSource = NotificationsLocalDataSource();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  bool _isInitialized = false;

  static const AndroidNotificationChannel _mainChannel =
      AndroidNotificationChannel(
        'focusly_main_channel',
        'Focusly Notifications',
        description: 'Main channel for Focusly alerts',
        importance: Importance.max,
      );

  static const AndroidNotificationChannel _scheduledChannel =
      AndroidNotificationChannel(
        'focusly_scheduled_channel',
        'Focusly Scheduled Notifications',
        description: 'Channel for scheduled study reminders',
        importance: Importance.max,
      );

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {},
    );

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_mainChannel);
    await androidPlugin?.createNotificationChannel(_scheduledChannel);

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (Platform.isAndroid) {
      await Permission.notification.request();
    } else if (Platform.isIOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  Future<String?> getFcmToken() {
    return _messaging.getToken();
  }

  Stream<String> onTokenRefresh() {
    return _messaging.onTokenRefresh;
  }

  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'focusly_main_channel',
          'Focusly Notifications',
          channelDescription: 'Main channel for Focusly alerts',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );

    // Save to local inbox
    await _localDataSource.saveNotification(
      NotificationInboxModel(
        id: id.toString(),
        title: title,
        body: body,
        createdAt: DateTime.now(),
        type: payload,
      ),
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'focusly_scheduled_channel',
          'Focusly Scheduled Notifications',
          channelDescription: 'Channel for scheduled study reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );

    // Save to local inbox
    await _localDataSource.saveNotification(
      NotificationInboxModel(
        id: id.toString(),
        title: title,
        body: body,
        createdAt: scheduledDate,
        type: payload,
      ),
    );
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await showNotification(
      id: message.messageId.hashCode,
      title: notification.title ?? 'Focusly',
      body: notification.body ?? '',
      payload: message.data.isEmpty ? null : message.data.toString(),
    );
  }
}
