import 'package:checkin/model/apiHandler.dart';
import 'package:checkin/model/task.dart';
import 'package:checkin/model/users.dart';
import 'package:flutter/material.dart';

class AddTaskScreen extends StatefulWidget {
  final User currentUser;
  final DateTime selectedDate;
  final Function(Task) onTaskAdded; // Callback trả về task đã tạo

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
  Duration? _selectedReminder;
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

  Duration? _calculateReminderDuration() {
    if (_selectedReminderDays != null ||
        _selectedReminderHours != null ||
        _selectedReminderMinutes != null) {
      return Duration(
        days: _selectedReminderDays ?? 0,
        hours: _selectedReminderHours ?? 0,
        minutes: _selectedReminderMinutes ?? 0,
      );
    }
    return null;
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
                        _selectedReminderDays = int.tryParse(value) ?? null;
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
                        _selectedReminderHours = int.tryParse(value) ?? null;
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
                        _selectedReminderMinutes = int.tryParse(value) ?? null;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            const Text('Chọn màu:'),
            Wrap(
              spacing: 8.0,
              children: [
                _buildColorOption(Colors.amber, setState),
                _buildColorOption(Colors.blue, setState),
                _buildColorOption(Colors.red, setState),
                _buildColorOption(Colors.grey[300]!, setState),
              ],
            ),
            const SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: () async {
                _selectedReminder = _calculateReminderDuration();
                final newTask = Task(
                  taskId: 0, //id này có thể  gây lỗi khi thêm task
                  title: _taskTitleController.text,
                  time: _selectedTime!,
                  color: _selectedColor ?? Colors.grey,
                  day: widget.selectedDate.day,
                  month: widget.selectedDate.month,
                  year: widget.selectedDate.year,
                  userId: widget.currentUser.userId,
                  reminderDuration: _selectedReminder,
                );

                final APIHandler apiHandler = APIHandler();
                final success = await apiHandler.insertTask(newTask);
                if (success) {
                  // Gọi callback và truyền task mới
                  widget.onTaskAdded(newTask);
                  Navigator.pop(context);
                } else {
                  // Xử lý lỗi khi thêm task
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lỗi khi thêm task!')),
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
