import 'package:checkin/model/apiHandler.dart';
import 'package:checkin/model/task.dart';
import 'package:checkin/model/users.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:checkin/screens/AddTaskScreen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ExamCalendarScreen extends StatefulWidget {
  final User currentUser;

  const ExamCalendarScreen({Key? key, required this.currentUser})
      : super(key: key);

  @override
  _ExamCalendarScreenState createState() => _ExamCalendarScreenState();
}

class _ExamCalendarScreenState extends State<ExamCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Task>> _tasks = {};
  final APIHandler _apiHandler = APIHandler();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _initializeNotifications();
    tz.initializeTimeZones();
  }

  Future<void> _initializeNotifications() async {
    final InitializationSettings initializationSettings =
        const InitializationSettings(
      android: AndroidInitializationSettings("ic_launcher2"),
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }

  @override
  void dispose() {
    // Hủy bỏ các hoạt động không đồng bộ ở đây nếu có
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    try {
      final userTasks = await _apiHandler.getUserTasks(
          widget.currentUser.userId, firstDayOfMonth, lastDayOfMonth);

      if (mounted) {
        setState(() {
          _tasks = {};
          for (var task in userTasks) {
            final date = DateTime(task.year, task.month, task.day);
            if (_tasks.containsKey(date)) {
              _tasks[date]!.add(task);
            } else {
              _tasks[date] = [task];
            }
          }
        });
      }
    } catch (e) {
      print('Error loading tasks: $e');
    }
  }

  List<Task> _getTasksForDay(DateTime day) {
    return _tasks[day] ?? [];
  }

  void _navigateToAddTaskScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(
          currentUser: widget.currentUser,
          selectedDate: _selectedDay ?? _focusedDay,
          onTaskAdded: (newTask) {
            // Nhận task mới từ AddTaskScreen
            setState(() {
              final date = DateTime(newTask.year, newTask.month, newTask.day);
              if (_tasks.containsKey(date)) {
                _tasks[date]!.add(newTask);
              } else {
                _tasks[date] = [newTask];
              }
            });

            // Lên lịch thông báo (nếu cần)
            _scheduleReminder(newTask);
          },
        ),
      ),
    );
  }

  Future<void> _scheduleReminder(Task task) async {
    if (task.reminderDuration != null) {
      final DateTime taskTime = DateTime(
        task.year,
        task.month,
        task.day,
        task.time.hour,
        task.time.minute,
      );
      final DateTime reminderTime = taskTime.subtract(task.reminderDuration!);

      // Không cần cấu hình icon trong AndroidNotificationDetails
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'your_channel_id',
        'your_channel_name',
        channelDescription: 'your_channel_description',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        task.taskId, // Sử dụng taskId làm notificationId
        'Reminder',
        'Bạn có reminder "${task.title}"',
        tz.TZDateTime.from(reminderTime, tz.local),
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'reminder_payload',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch reminder"),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              }
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _loadTasks();
            },
            eventLoader: _getTasksForDay,
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ListView.builder(
              itemCount: _getTasksForDay(_selectedDay ?? _focusedDay).length,
              itemBuilder: (context, index) {
                final task =
                    _getTasksForDay(_selectedDay ?? _focusedDay)[index];
                return ListTile(
                  title: Text(task.title),
                  trailing: Container(
                    width: 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.color,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTaskScreen,
        child: const Icon(Icons.add),
      ),
    );
  }
}
