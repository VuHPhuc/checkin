import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';
import 'package:checkin/model/task.dart';
import 'package:rxdart/rxdart.dart';

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher2');

    /// Note: permissions aren't requested here just to demonstrate that can be
    /// done later
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
            onDidReceiveLocalNotification:
                (int id, String? title, String? body, String? payload) async {
              didReceiveLocalNotificationSubject.add(ReceivedNotification(
                  id: id, title: title, body: body, payload: payload));
            });

    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        //This is where you would handle the user tapping on the notification.

        if (notificationResponse.payload != null) {
          debugPrint('notification payload: ${notificationResponse.payload}');
        }
      },
    );
  }

  Future<void> scheduleNotification(Task task) async {
    final now = DateTime.now();
    final taskDate = DateFormat('yyyy-MM-dd').parse(task.date!);
    final startTime = TimeOfDay(
        hour: int.parse(task.startTime!.split(":")[0]),
        minute: int.parse(task.startTime!.split(":")[1]));

    final scheduledDate = DateTime(taskDate.year, taskDate.month, taskDate.day,
        startTime.hour, startTime.minute);

    final notificationTime =
        scheduledDate.subtract(Duration(minutes: task.remind!));

    if (notificationTime.isAfter(now)) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
          task.id!,
          task.title,
          task.note,
          tz.TZDateTime.from(notificationTime, tz.local),
          const NotificationDetails(
              android: AndroidNotificationDetails(
                  'your channel id', 'your channel name',
                  channelDescription: 'your channel description',
                  importance: Importance.max,
                  priority: Priority.high,
                  showWhen: false)),
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time);
    }
  }

  final didReceiveLocalNotificationSubject =
      PublishSubject<ReceivedNotification>();

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}

class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String? title;
  final String? body;
  final String? payload;
}
