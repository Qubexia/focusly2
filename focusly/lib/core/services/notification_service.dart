import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    // Exact-alarm + battery-optimisation grants are handled in
    // requestPermissions() (called right after init) so we can check status
    // first and avoid opening the system settings page twice.

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
      await _ensureAndroidAlarmReliability();
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

  /// Scheduled reminders fire through Android's [AlarmManager]. Two device
  /// policies silently drop those alarms in a release build (they never bite in
  /// debug because the tooling keeps the process alive):
  ///   1. Missing the "Alarms & reminders" (SCHEDULE_EXACT_ALARM) grant — exact
  ///      alarms are refused, so reminders only fire inexactly (or not at all).
  ///   2. Battery optimisation force-stopping the app, which wipes every pending
  ///      alarm the app registered.
  /// Requesting both up front is what makes reminders actually fire after the
  /// user installs the APK and swipes the app away.
  Future<void> _ensureAndroidAlarmReliability() async {
    try {
      final exactAlarm = await Permission.scheduleExactAlarm.status;
      if (!exactAlarm.isGranted) {
        final result = await Permission.scheduleExactAlarm.request();
        _log('scheduleExactAlarm permission after request: $result');
      }
    } catch (e) {
      _log('Could not resolve exact-alarm permission: $e');
    }

    try {
      final battery = await Permission.ignoreBatteryOptimizations.status;
      if (!battery.isGranted) {
        final result = await Permission.ignoreBatteryOptimizations.request();
        _log('ignoreBatteryOptimizations after request: $result');
      }
    } catch (e) {
      _log('Could not request battery-optimisation exemption: $e');
    }
  }

  /// Whether the OS will let us schedule exact alarms. Reminders downgrade to
  /// inexact (and may be batched far past their time) when this is false.
  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    try {
      return (await Permission.scheduleExactAlarm.status).isGranted;
    } catch (_) {
      return false;
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
    await _rememberFireTime(id, scheduledDate);

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
    // Order matters for reliability in a release build left in Doze:
    //  1. exactAllowWhileIdle — fires on time when SCHEDULE_EXACT_ALARM is
    //     granted; throws exact_alarms_not_permitted when it isn't.
    //  2. alarmClock — setAlarmClock(); fires reliably even in Doze and does
    //     NOT need the exact-alarm permission, so it's the right fallback when
    //     exact is refused (NOT inexact, which Doze batches for hours).
    //  3. inexactAllowWhileIdle — last resort; always schedules but may be
    //     delayed heavily.
    const modes = [
      AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.alarmClock,
      AndroidScheduleMode.inexactAllowWhileIdle,
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

  /// Dumps every notification currently registered with the OS alarm manager.
  /// Use while debugging to confirm a scheduled reminder actually landed and
  /// when it is expected to fire.
  Future<void> logPendingNotifications() async {
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    final fireTimes = await _readFireTimes();
    _log('Pending notifications: ${pending.length}');
    for (final p in pending) {
      final at = fireTimes[p.id.toString()] ?? 'unknown';
      _log('  • id=${p.id} fires=$at title="${p.title}" payload=${p.payload}');
    }
  }

  // The plugin's pendingNotificationRequests() doesn't expose the scheduled
  // fire time, so we remember it ourselves keyed by notification id. Stored
  // times are best-effort and only used for debugging/observability.
  static const String _fireTimesKey = 'notification_fire_times';

  Future<Map<String, String>> _readFireTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_fireTimesKey);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value.toString()));
  }

  Future<void> _rememberFireTime(int id, DateTime scheduledDate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final times = await _readFireTimes();
      times[id.toString()] = scheduledDate.toIso8601String();
      await prefs.setString(_fireTimesKey, jsonEncode(times));
    } catch (e) {
      _log('Could not remember fire time for $id: $e');
    }
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
