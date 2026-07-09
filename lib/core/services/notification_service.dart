import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'blood_network_channel',
      'Blood Network Alerts',
      channelDescription: 'Emergency requests and donation updates',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  // ===== Firebase Cloud Messaging (real push notifications) =====
  static Future<void> initFCM() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // All app users subscribe to this topic. Admin can then broadcast an
    // announcement to everyone by sending a message to this topic —
    // either from the Firebase Console (Cloud Messaging > New notification
    // > Send to topic "all_users"), or via a backend using the Admin SDK.
    await messaging.subscribeToTopic('all_users');

    // Foreground: app is open — show as a local notification banner
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? 'Blood Network';
      final body = message.notification?.body ?? '';
      showNotification(title: title, body: body);
    });

    // App was in background and user tapped the notification to open it
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Currently just a hook — extend later to deep-link to a specific screen
    });
  }
}