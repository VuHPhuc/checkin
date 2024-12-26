import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:checkin/model/apiHandler.dart';
import 'package:checkin/model/task.dart';
import 'package:checkin/model/users.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  String? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int _remind = 5;
  String _repeat = 'None';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.addTaskTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.addTaskTitleLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.addTaskTitleError;
                  }
                  return null;
                },
                onSaved: (value) => _title = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.addTaskNoteLabel,
                  border: const OutlineInputBorder(),
                  hintText: AppLocalizations.of(context)!.addTaskNoteHint,
                ),
                onSaved: (value) => _note = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.addTaskDateLabel,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _date = DateFormat('yyyy-MM-dd').format(pickedDate);
                    });
                  }
                },
                controller: TextEditingController(
                  text: _date,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context)!.addTaskStartTimeLabel,
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.access_time),
                      ),
                      readOnly: true,
                      onTap: () async {
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          setState(() => _startTime = pickedTime);
                        }
                      },
                      controller: TextEditingController(
                        text: _startTime != null
                            ? _startTime!.format(context)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context)!.addTaskEndTimeLabel,
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.access_time),
                      ),
                      readOnly: true,
                      onTap: () async {
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          setState(() => _endTime = pickedTime);
                        }
                      },
                      controller: TextEditingController(
                        text:
                            _endTime != null ? _endTime!.format(context) : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.addTaskRemindLabel,
                  border: const OutlineInputBorder(),
                ),
                value: _remind,
                items: [
                  DropdownMenuItem(
                      value: 5,
                      child:
                          Text(AppLocalizations.of(context)!.addTaskRemind5)),
                  DropdownMenuItem(
                      value: 10,
                      child:
                          Text(AppLocalizations.of(context)!.addTaskRemind10)),
                  DropdownMenuItem(
                      value: 15,
                      child:
                          Text(AppLocalizations.of(context)!.addTaskRemind15)),
                  DropdownMenuItem(
                      value: 20,
                      child:
                          Text(AppLocalizations.of(context)!.addTaskRemind20)),
                  DropdownMenuItem(
                      value: 25,
                      child:
                          Text(AppLocalizations.of(context)!.addTaskRemind25)),
                  DropdownMenuItem(
                      value: 30,
                      child:
                          Text(AppLocalizations.of(context)!.addTaskRemind30)),
                ],
                onChanged: (value) => setState(() => _remind = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.addTaskRepeatLabel,
                  border: const OutlineInputBorder(),
                ),
                value: _repeat,
                items: [
                  DropdownMenuItem(
                      value: 'None',
                      child: Text(
                          AppLocalizations.of(context)!.addTaskRepeatNone)),
                  DropdownMenuItem(
                      value: 'Daily',
                      child: Text(
                          AppLocalizations.of(context)!.addTaskRepeatDaily)),
                  DropdownMenuItem(
                      value: 'Weekly',
                      child: Text(
                          AppLocalizations.of(context)!.addTaskRepeatWeekly)),
                  DropdownMenuItem(
                      value: 'Monthly',
                      child: Text(
                          AppLocalizations.of(context)!.addTaskRepeatMonthly)),
                ],
                onChanged: (value) => setState(() => _repeat = value!),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    Task newTask = Task(
                      userId: widget.currentUser.userId,
                      title: _title,
                      note: _note,
                      isCompleted: 0,
                      date: _date,
                      startTime: _startTime?.format(context),
                      endTime: _endTime?.format(context),
                      remind: _remind,
                      repeat: _repeat,
                    );

                    try {
                      final apiHandler = APIHandler();
                      final response = await apiHandler.insertTask(newTask);

                      if (response.statusCode == 201 ||
                          response.statusCode == 200) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(AppLocalizations.of(context)!
                                  .addTaskCreateSuccess)),
                        );
                        Navigator.of(context).pop(true);
                      } else {
                        print('Failed to create task: ${response.statusCode}');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(AppLocalizations.of(context)!
                                  .addTaskCreateFail)),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                '${AppLocalizations.of(context)!.error}: $e')),
                      );
                    }
                  }
                },
                child: Text(AppLocalizations.of(context)!.addTaskCreateButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
