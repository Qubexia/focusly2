import 'dart:developer' as developer;
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/notifications/data/datasources/notifications_local_datasource.dart';
import '../../features/notifications/data/models/notification_inbox_model.dart';
import '../../firebase_options.dart';

const _mainChannelId = 'Zakerly_main_channel';
const _scheduledChannelId = 'Zakerly_scheduled_channel';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.showRemoteNotification(message);
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
  bool _localTimeZoneReady = false;

  void _log(String message) =>
      developer.log(message, name: 'NotificationService');

  static const AndroidNotificationChannel _mainChannel =
      AndroidNotificationChannel(
        _mainChannelId,
        'Zakerly Notifications',
        description: 'Main channel for Zakerly alerts',
        importance: Importance.max,
      );

  static const AndroidNotificationChannel _scheduledChannel =
      AndroidNotificationChannel(
        _scheduledChannelId,
        'Zakerly Scheduled Notifications',
        description: 'Channel for scheduled study reminders',
        importance: Importance.max,
      );

  static const NotificationDetails _mainNotificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _mainChannelId,
      'Zakerly Notifications',
      channelDescription: 'Main channel for Zakerly alerts',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'ic_notification',
      largeIcon: DrawableResourceAndroidBitmap('ic_notification_large'),
      color: Color(0xFF1EA1FC),
    ),
    iOS: DarwinNotificationDetails(),
  );

  static const NotificationDetails _scheduledNotificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _scheduledChannelId,
      'Zakerly Scheduled Notifications',
      channelDescription: 'Channel for scheduled study reminders',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'ic_notification',
      largeIcon: DrawableResourceAndroidBitmap('ic_notification_large'),
      color: Color(0xFF1EA1FC),
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    await _ensureLocalTimeZone();

    const initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');
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
    await androidPlugin?.requestExactAlarmsPermission();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

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

  Future<String?> getFcmToken({int maxAttempts = 3}) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        return token;
      }

      if (attempt < maxAttempts - 1) {
        await Future<void>.delayed(Duration(seconds: 1 + attempt));
      }
    }
    return null;
  }

  Stream<String> onTokenRefresh() {
    return _messaging.onTokenRefresh;
  }

  Future<RemoteMessage?> getInitialMessage() {
    return _messaging.getInitialMessage();
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
      notificationDetails: _mainNotificationDetails,
      payload: payload,
    );

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
    bool recordInInbox = true,
  }) async {
    await _ensureLocalTimeZone();

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    await _zonedScheduleWithFallback(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzDate,
      payload: payload,
    );

    // Re-sync passes record different. When re-scheduling an already-known
    // reminder we skip the inbox write so repeated syncs don't duplicate rows.
    if (!recordInInbox) return;

    try {
      await _localDataSource.saveNotification(
        NotificationInboxModel(
          id: id.toString(),
          title: title,
          body: body,
          createdAt: scheduledDate,
          type: payload,
        ),
      );
    } catch (e) {
      _log('Inbox write failed for notification $id: $e');
    }
  }

  Future<void> _ensureLocalTimeZone() async {
    if (_localTimeZoneReady) return;

    try {
      final offset = DateTime.now().timeZoneOffset;
      final hours = offset.inHours;
      // IANA "Etc/GMT" labels invert the sign (GMT-2 == UTC+2).
      final etcName = hours >= 0 ? 'Etc/GMT-$hours' : 'Etc/GMT+${-hours}';
      tz.setLocalLocation(tz.getLocation(etcName));
    } catch (e) {
      _log('Could not resolve device timezone, using UTC: $e');
      tz.setLocalLocation(tz.UTC);
    }

    _localTimeZoneReady = true;
  }

  Future<void> _zonedScheduleWithFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String? payload,
  }) async {
    const modes = [
      AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
      AndroidScheduleMode.alarmClock,
    ];

    Object? lastError;
    for (final mode in modes) {
      try {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: _scheduledNotificationDetails,
          androidScheduleMode: mode,
          payload: payload,
        );
        return;
      } on PlatformException catch (e) {
        lastError = e;
        _log('zonedSchedule failed with $mode: ${e.code} ${e.message}');
      } catch (e) {
        lastError = e;
        _log('zonedSchedule failed with $mode: $e');
      }
    }

    throw lastError ?? StateError('Could not schedule notification $id');
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  static Future<void> showRemoteNotification(RemoteMessage message) async {
    final title = _extractTitle(message);
    final body = _extractBody(message);
    if (title == null && body == null) return;

    final plugin = FlutterLocalNotificationsPlugin();
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
      iOS: DarwinInitializationSettings(),
    );

    await plugin.initialize(settings: initializationSettings);

    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_mainChannel);

    await plugin.show(
      id: message.messageId?.hashCode ?? message.hashCode,
      title: title ?? 'Zakerly',
      body: body ?? '',
      notificationDetails: _mainNotificationDetails,
      payload: message.data.isEmpty ? null : message.data.toString(),
    );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final title = _extractTitle(message);
    final body = _extractBody(message);
    if (title == null && body == null) return;

    await showNotification(
      id: message.messageId?.hashCode ?? message.hashCode,
      title: title ?? 'Zakerly',
      body: body ?? '',
      payload: message.data.isEmpty ? null : message.data.toString(),
    );
  }

  Future<void> _handleOpenedMessage(RemoteMessage message) async {
    final title = _extractTitle(message);
    final body = _extractBody(message);
    if (title == null && body == null) return;

    await _localDataSource.saveNotification(
      NotificationInboxModel(
        id: (message.messageId ?? message.hashCode).toString(),
        title: title ?? 'Zakerly',
        body: body ?? '',
        createdAt: DateTime.now(),
        type: message.data.isEmpty ? null : message.data.toString(),
      ),
    );
  }

  static String? _extractTitle(RemoteMessage message) {
    return message.notification?.title ?? message.data['title'] as String?;
  }

  static String? _extractBody(RemoteMessage message) {
    return message.notification?.body ?? message.data['body'] as String?;
  }
}
