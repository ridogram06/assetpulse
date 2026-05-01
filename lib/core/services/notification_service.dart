import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static const _channelId = 'assetpulse_alerts';
  static const _channelName = 'AssetPulse Alerts';

  static Future<void> initialize(
      FlutterLocalNotificationsPlugin plugin) async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await plugin.initialize(initSettings);

    await _createChannel(plugin);
    await _setupFCM();
  }

  static Future<void> _createChannel(
      FlutterLocalNotificationsPlugin plugin) async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
      enableVibration: true,
    );
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> _setupFCM() async {
    await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(
        title: message.notification?.title ?? 'AssetPulse',
        body: message.notification?.body ?? '',
      );
    });
  }

  static Future<String?> getFCMToken() =>
      FirebaseMessaging.instance.getToken();

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await FlutterLocalNotificationsPlugin().show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }
}
