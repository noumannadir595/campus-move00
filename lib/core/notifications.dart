import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin notifPlugin =
    FlutterLocalNotificationsPlugin();

// ==================== INIT LOCAL NOTIFICATIONS ====================
Future<void> initNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings settings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await notifPlugin.initialize(
    settings,
    onDidReceiveNotificationResponse: (response) {
      debugPrint('Notification tapped: ${response.payload}');
    },
  );

  // Request permission (Android 13+)
  final androidImpl =
      notifPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidImpl?.requestNotificationsPermission();
}

// ==================== INIT FCM ====================
Future<void> initFCM() async {
  try {
    final messaging = FirebaseMessaging.instance;

    // Request permission
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get token
    final token = await messaging.getToken();
    debugPrint('FCM Token: $token');

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message: ${message.notification?.title}');
      if (message.notification != null) {
        showReminder(
          message.notification!.title ?? 'Campus Move',
          message.notification!.body ?? '',
        );
      }
    });

    // Background/terminated tap
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Notification opened: ${message.data}');
    });

    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('FCM init error: $e');
  }
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

// ==================== SHOW LOCAL NOTIFICATION ====================
Future<void> showReminder(String title, String body) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'reminders',
    'Campus Move Reminders',
    channelDescription: 'Campus Move notifications',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  const NotificationDetails details = NotificationDetails(
    android: androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  await notifPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    details,
  );
}