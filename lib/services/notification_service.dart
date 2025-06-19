import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  static Future<void> scheduleTaskReminder(Task task) async {
    final scheduledDate = tz.TZDateTime.from(task.dueDate, tz.local).subtract(
      const Duration(minutes: 5),
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      task.hashCode, // unique id
      'Task Reminder',
      'Reminder: ${task.title}',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_channel',
          'Task Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ✅ Add this to fix your "member not found" error
  static void cancelNotification(String id) {
    final intId = int.tryParse(id);
    if (intId != null) {
      _flutterLocalNotificationsPlugin.cancel(intId);
    }
  }
}
