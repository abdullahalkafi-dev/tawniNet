import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android/iOS local notifications for foreground heads-up banners.
class LocalNotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Important notifications',
    description: 'Payment confirmations, support replies, chat, and KYC',
    importance: Importance.high,
  );

  static bool _initialized = false;

  static Future<void> init({
    void Function(NotificationResponse)? onDidReceiveNotificationResponse,
  }) async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(channel);
      await androidImpl.requestNotificationsPermission();
    }

    _initialized = true;
  }

  /// Show a heads-up notification for a foreground FCM message.
  static Future<void> showFromRemoteMessage(RemoteMessage message) async {
    if (kIsWeb) return;
    final notification = message.notification;
    final data = message.data;
    final title =
        notification?.title ?? data['title'] as String? ?? 'Notification';
    final body = notification?.body ?? data['body'] as String? ?? '';

    await show(
      title: title,
      body: body,
      payload: encodePayload(data),
    );
  }

  /// Encode FCM data map as query string so tap can deep-link with ids.
  static String encodePayload(Map<String, dynamic> data) {
    final parts = <String>[];
    data.forEach((k, v) {
      if (v == null) return;
      parts.add('$k=${Uri.encodeComponent(v.toString())}');
    });
    return parts.join('&');
  }

  static Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('[LocalNotif] show failed: $e');
    }
  }
}
