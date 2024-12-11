import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:checkin/model/apiHandler.dart';
import 'package:checkin/model/task.dart';
import 'package:checkin/model/users.dart';

class AddTaskScreen extends StatefulWidget {
  final User currentUser;
  const AddTaskScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _title;
  String? _note;
  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int _remind = 5;
  String _repeat = 'None';
  Color? _selectedColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                onSaved: (value) => _title = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                  hintText: 'Enter note here.',
                ),
                onSaved: (value) => _note = value,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _date ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _date = pickedDate;
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: _date != null
                          ? "${_date!.month}/${_date!.day}/${_date!.year}"
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
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
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Start Time',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.access_time),
                          ),
                          controller: TextEditingController(
                            text: _startTime != null
                                ? _startTime!.format(context)
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
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
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'End Time',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.access_time),
                          ),
                          controller: TextEditingController(
                            text: _endTime != null
                                ? _endTime!.format(context)
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Remind',
                  border: OutlineInputBorder(),
                ),
                value: _remind,
                items: const [
                  DropdownMenuItem(value: 5, child: Text('5 minutes early')),
                  DropdownMenuItem(value: 10, child: Text('10 minutes early')),
                  DropdownMenuItem(value: 15, child: Text('15 minutes early')),
                  DropdownMenuItem(value: 20, child: Text('20 minutes early')),
                  DropdownMenuItem(value: 25, child: Text('25 minutes early')),
                  DropdownMenuItem(value: 30, child: Text('30 minutes early')),
                ],
                onChanged: (value) => setState(() => _remind = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Repeat',
                  border: OutlineInputBorder(),
                ),
                value: _repeat,
                items: const [
                  DropdownMenuItem(value: 'None', child: Text('None')),
                  DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                ],
                onChanged: (value) => setState(() => _repeat = value!),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Color", style: TextStyle(fontSize: 16)),
              ),
              Row(
                children: [
                  _buildColorButton(Colors.blue),
                  _buildColorButton(Colors.red),
                  _buildColorButton(Colors.orange),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    int colorValue = _selectedColor?.value ?? 0;

                    Task newTask = Task(
                      userId: widget.currentUser.userId,
                      title: _title,
                      note: _note,
                      isCompleted: 0,
                      date: _date != null
                          ? DateFormat('yyyy-MM-dd').format(_date!)
                          : null,
                      startTime: _startTime != null
                          ? _startTime!.format(context)
                          : null,
                      endTime:
                          _endTime != null ? _endTime!.format(context) : null,
                      color: colorValue,
                      remind: _remind,
                      repeat: _repeat,
                    );

                    try {
                      final apiHandler = APIHandler();
                      final response = await apiHandler.insertTask(newTask);

                      if (response.statusCode == 201) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Task created successfully')),
                        );
                        Navigator.pop(context);
                      } else {
                        print('Failed to create task: ${response.statusCode}');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Failed to create task')),
                        );
                      }
                    } catch (e) {
                      print('Error creating task: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error creating task: $e')),
                      );
                    }
                  }
                },
                child: const Text('Create Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedColor = color;
        });
      },
      child: Container(
        margin: const EdgeInsets.all(8.0),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: _selectedColor == color ? Colors.black : Colors.transparent,
            width: 2.0,
          ),
        ),
        child: _selectedColor == color
            ? const Icon(Icons.check, size: 24, color: Colors.white)
            : null,
      ),
    );
  }
}
