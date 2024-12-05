import 'package:checkin/model/apiHandler.dart';
import 'package:checkin/model/task.dart';
import 'package:checkin/model/users.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AddTaskScreen extends StatefulWidget {
  final User currentUser;
  final DateTime selectedDate;
  final Function(Task) onTaskAdded;

  const AddTaskScreen({
    Key? key,
    required this.currentUser,
    required this.selectedDate,
    required this.onTaskAdded,
  }) : super(key: key);

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _taskTitleController = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int remindBefore = 0;
  Color? _selectedColor = Colors.grey;
  int? _selectedReminderDays;
  int? _selectedReminderHours;
  int? _selectedReminderMinutes;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    tz.initializeTimeZones();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher2');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Widget _buildColorOption(Color color, StateSetter setState) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
        });
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: color == _selectedColor ? Colors.black : Colors.transparent,
            width: 2.0,
          ),
        ),
      ),
    );
  }

  void _calculateRemindBefore() {
    remindBefore = Duration(
      days: _selectedReminderDays ?? 0,
      hours: _selectedReminderHours ?? 0,
      minutes: _selectedReminderMinutes ?? 0,
    ).inMilliseconds;
  }

  Future<void> _scheduleReminder(Task task) async {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    if (task.remindBefore > 0) {
      final startTimeReminderTime =
          task.startTime.subtract(Duration(milliseconds: task.remindBefore));
      await _flutterLocalNotificationsPlugin.zonedSchedule(
          task.taskId.hashCode + 1,
          'Reminder - Start',
          task.title,
          tz.TZDateTime.from(startTimeReminderTime, tz.local),
          platformChannelSpecifics,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime);
    }

    await _flutterLocalNotificationsPlugin.zonedSchedule(
        task.taskId.hashCode + 2,
        'Reminder - End',
        task.title,
        tz.TZDateTime.from(task.endTime, tz.local),
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm reminder'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _taskTitleController,
              decoration: const InputDecoration(labelText: 'Nội dung reminder'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: _startTime ?? TimeOfDay.now(),
                );
                if (pickedTime != null) {
                  setState(() {
                    _startTime = pickedTime;
                  });
                }
              },
              child: Text(
                _startTime != null
                    ? _startTime!.format(context)
                    : 'Chọn giờ bắt đầu',
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: _endTime ?? TimeOfDay.now(),
                );
                if (pickedTime != null) {
                  setState(() {
                    _endTime = pickedTime;
                  });
                }
              },
              child: Text(
                _endTime != null
                    ? _endTime!.format(context)
                    : 'Chọn giờ kết thúc',
              ),
            ),
            const SizedBox(height: 16.0),
            const Text('Nhắc trước:'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Ngày'),
                    onChanged: (value) {
                      setState(() {
                        _selectedReminderDays = int.tryParse(value);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Giờ'),
                    onChanged: (value) {
                      setState(() {
                        _selectedReminderHours = int.tryParse(value);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Phút'),
                    onChanged: (value) {
                      setState(() {
                        _selectedReminderMinutes = int.tryParse(value);
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            const Text('Chọn màu:'),
            StatefulBuilder(
              builder: (context, setState) {
                return Wrap(
                  spacing: 8.0,
                  children: [
                    _buildColorOption(Colors.amber, setState),
                    _buildColorOption(Colors.blue, setState),
                    _buildColorOption(Colors.red, setState),
                    _buildColorOption(Colors.grey, setState),
                  ],
                );
              },
            ),
            const SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: () async {
                if (_taskTitleController.text.isEmpty ||
                    _startTime == null ||
                    _endTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Vui lòng nhập nội dung và chọn giờ bắt đầu và kết thúc!')),
                  );
                  return;
                }

                _calculateRemindBefore();

                final startTime = DateTime(
                  widget.selectedDate.year,
                  widget.selectedDate.month,
                  widget.selectedDate.day,
                  _startTime!.hour,
                  _startTime!.minute,
                );

                final endTime = DateTime(
                  widget.selectedDate.year,
                  widget.selectedDate.month,
                  widget.selectedDate.day,
                  _endTime!.hour,
                  _endTime!.minute,
                );

                try {
                  final newTask = Task(
                    taskId: const Uuid().v4(),
                    title: _taskTitleController.text,
                    startTime: startTime,
                    endTime: endTime,
                    remindBefore: remindBefore,
                    userId: widget.currentUser.userId,
                    color: _selectedColor,
                  );

                  newTask.updateColor();

                  final apiHandler = APIHandler();
                  final success = await apiHandler.insertTask(newTask);

                  if (success) {
                    _scheduleReminder(newTask);
                    widget.onTaskAdded(newTask);
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lỗi khi thêm task!')),
                    );
                  }
                } catch (e) {
                  print("Error creating task: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid user ID')),
                  );
                }
              },
              child: const Text('Thêm reminder'),
            ),
          ],
        ),
      ),
    );
  }
}
