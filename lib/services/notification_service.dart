import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize notifications and request permissions
  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    // Request permissions (required for Android 13+ and iOS)
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Schedule a one-time reminder 5 minutes before dueDate
  static Future<void> scheduleTaskReminder(Task task) async {
    final int notificationId = task.id.hashCode;

    final scheduledDate = tz.TZDateTime.from(task.dueDate, tz.local).subtract(
      const Duration(minutes: 5),
    );

    // Skip if scheduled time is in the past
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      'Task Reminder',
      'Reminder: ${task.title}',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_channel',
          'Task Reminders',
          channelDescription: 'Reminders for upcoming tasks',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  /// Schedule recurring daily or weekly notifications
  static Future<void> scheduleRecurringReminder(Task task) async {
    final int notificationId = task.id.hashCode;

    final interval = task.recurrenceRule == 'daily'
        ? RepeatInterval.daily
        : task.recurrenceRule == 'weekly'
            ? RepeatInterval.weekly
            : null;

    if (interval != null) {
      await _flutterLocalNotificationsPlugin.periodicallyShow(
        notificationId,
        'Recurring Task Reminder',
        'Reminder: ${task.title}',
        interval,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'recurring_channel',
            'Recurring Reminders',
            channelDescription: 'Channel for recurring task reminders',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidAllowWhileIdle: true,
      );
    }
  }

  /// Cancel a notification by task ID
  static Future<void> cancelNotification(String taskId) async {
    final int id = taskId.hashCode;
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Show immediate alerts for overdue tasks
  static Future<void> checkOverdueTasks(List<Task> tasks) async {
    final now = DateTime.now();
    for (final task in tasks) {
      if (task.dueDate.isBefore(now)) {
        final int id = task.id.hashCode;
        await _flutterLocalNotificationsPlugin.show(
          id,
          'Overdue Task',
          '${task.title} is overdue!',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'overdue_channel',
              'Overdue Alerts',
              channelDescription: 'Notifications for overdue tasks',
              importance: Importance.high,
              priority: Priority.max,
            ),
          ),
        );
      }
    }
  }
}
