import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );
  }

  static Future<void> showMotivation(String message) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'motivai_channel',
        'MotivAI',
        channelDescription: 'Motivatsiya xabarnomalar',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      0,
      '🎯 MotivAI',
      message,
      details,
    );
  }

  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String message,
  }) async {
    // Implementation for daily reminders
  }
}
