import 'package:checkin/model/apiHandler.dart';
import 'package:checkin/model/task.dart';
import 'package:checkin/model/users.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

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
  TimeOfDay? _selectedTime;
  int remindBefore = 0;
  Color? _selectedColor = Colors.grey;
  int? _selectedReminderDays;
  int? _selectedReminderHours;
  int? _selectedReminderMinutes;

  @override
  void initState() {
    super.initState();
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
                  initialTime: TimeOfDay.now(),
                );
                if (pickedTime != null) {
                  setState(() {
                    _selectedTime = pickedTime;
                  });
                }
              },
              child: Text(
                _selectedTime != null
                    ? _selectedTime!.format(context)
                    : 'Chọn giờ',
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
            StatefulBuilder(// Use StatefulBuilder to update colors
                builder: (context, setState) {
              return Wrap(
                spacing: 8.0,
                children: [
                  _buildColorOption(Colors.amber, setState),
                  _buildColorOption(Colors.blue, setState),
                  _buildColorOption(Colors.red, setState),
                  _buildColorOption(Colors.grey,
                      setState), // Fix: Use Colors.grey instead of Colors.grey[300]!
                ],
              );
            }),
            const SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: () async {
                if (_taskTitleController.text.isEmpty ||
                    _selectedTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Vui lòng nhập nội dung và chọn giờ!')),
                  );
                  return;
                }

                _calculateRemindBefore();

                final startTime = DateTime(
                  widget.selectedDate.year,
                  widget.selectedDate.month,
                  widget.selectedDate.day,
                  _selectedTime!.hour,
                  _selectedTime!.minute,
                );

                try {
                  final newTask = Task(
                    taskId: const Uuid().v4(),
                    title: _taskTitleController.text,
                    startTime: startTime,
                    endTime: startTime.add(const Duration(hours: 1)),
                    remindBefore: remindBefore,
                    userId: widget.currentUser.userId,
                    color: _selectedColor,
                  );

                  newTask.updateColor();

                  final apiHandler = APIHandler();
                  final success = await apiHandler.insertTask(newTask);

                  if (success) {
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
