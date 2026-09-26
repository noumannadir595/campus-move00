import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin notifPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings settings =
      InitializationSettings(android: androidSettings);
  await notifPlugin.initialize(settings);
}

Future<void> showReminder(String title, String body) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'reminders',
    'Campus Move Reminders',
    importance: Importance.high,
    priority: Priority.high,
  );
  const NotificationDetails details =
      NotificationDetails(android: androidDetails);
  await notifPlugin.show(0, title, body, details);
}