import 'package:checkin/model/apiHandler.dart';
import 'package:checkin/model/task.dart';
import 'package:checkin/model/users.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:checkin/screens/AddTaskScreen.dart'; // Make sure this path is correct
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

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
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher2');
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
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
            final date = task.startTime; // Corrected - removed .toDate()
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
      // TODO: Handle error, e.g., show a snackbar
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
            setState(() {
              final date = newTask.startTime; // Corrected - removed .toDate()
              if (_tasks.containsKey(date)) {
                _tasks[date]!.add(newTask);
              } else {
                _tasks[date] = [newTask];
              }
            });
            _scheduleReminder(newTask);
          },
        ),
      ),
    ).then((_) => _loadTasks());
  }

  Future<void> _scheduleReminder(Task task) async {
    if (task.remindBefore > 0) {
      final reminderTime =
          task.startTime.subtract(Duration(milliseconds: task.remindBefore));

      final androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'your_channel_id', 'your_channel_name',
          channelDescription: 'your_channel_description',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker');

      final NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        task.taskId.hashCode,
        'Reminder',
        task.title,
        tz.TZDateTime.from(reminderTime, tz.local),
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
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
              _loadTasks(); // Load tasks when the page changes
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
                  subtitle: Text(
                      DateFormat('HH:mm').format(task.startTime.toLocal())),
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
