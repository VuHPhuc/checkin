import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:checkin/screens/AddTaskScreen.dart';
import 'package:checkin/model/users.dart';
import 'package:checkin/model/task.dart';
import 'package:checkin/model/apiHandler.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:checkin/services/NotificationService.dart';

class ExamCalendarScreen extends StatefulWidget {
  final User currentUser;
  const ExamCalendarScreen({Key? key, required this.currentUser})
      : super(key: key);

  @override
  _ExamCalendarScreenState createState() => _ExamCalendarScreenState();
}

class _ExamCalendarScreenState extends State<ExamCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  final ScrollController _scrollController = ScrollController();
  List<Task> _tasks = [];
  Timer? _refreshTimer;
  static DateTime? lastSnackbarTime;
  Map<int, Color> _taskColors = {};
  List<Color> _availableColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.pink,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _fetchTasks();
    });
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToSelectedDate());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() {
        _selectedDate = pickedDate;
        _scrollToSelectedDate();
      });
    });
  }

  void _scrollToSelectedDate() {
    double screenWidth = MediaQuery.of(context).size.width;
    double tileWidth = screenWidth / 5;
    int daysDifference = _selectedDate
        .difference(DateTime.now().subtract(const Duration(days: 2)))
        .inDays;
    double scrollOffset = daysDifference * tileWidth;
    _scrollController.animateTo(scrollOffset,
        duration: const Duration(milliseconds: 300), curve: Curves.ease);
  }

  Future<void> _fetchTasks() async {
    try {
      final apiHandler = APIHandler();
      final allTasks = await apiHandler.getTasks(widget.currentUser.userId!);

      final filteredTasks = allTasks
          .where((task) => task.userId == widget.currentUser.userId)
          .toList();
      setState(() {
        _tasks = filteredTasks;
      });

      for (var task in filteredTasks) {
        if (task.startTime != null && task.date != null) {
          int notificationId;
          if (task.id != null) {
            notificationId = task.id!;
          } else {
            notificationId = DateTime.now().hashCode;
            if (notificationId < 0) {
              notificationId = -notificationId;
            }
          }
          final taskDate = DateFormat('yyyy-MM-dd').parse(task.date!);
          final taskStartTime = DateFormat('HH:mm').parse(task.startTime!);
          DateTime scheduledStartDateTime = DateTime(
              taskDate.year,
              taskDate.month,
              taskDate.day,
              taskStartTime.hour,
              taskStartTime.minute);
          final now = DateTime.now();
          if (now.year == scheduledStartDateTime.year &&
              now.month == scheduledStartDateTime.month &&
              now.day == scheduledStartDateTime.day &&
              now.hour == scheduledStartDateTime.hour &&
              now.minute == scheduledStartDateTime.minute) {
            String title = task.title ?? 'Task Reminder';
            String body =
                '${task.note ?? 'No note'} \n ${task.startTime ?? 'No start time'} - ${task.endTime ?? 'No end time'}';
            await NotificationService().showNotification(
                id: notificationId,
                title: title,
                body: body,
                remind: task.remind ?? 5);
          }

          if (task.endTime != null) {
            final taskEndTime = DateFormat('HH:mm').parse(task.endTime!);
            DateTime scheduledEndDateTime = DateTime(
                taskDate.year,
                taskDate.month,
                taskDate.day,
                taskEndTime.hour,
                taskEndTime.minute);

            if (now.year == scheduledEndDateTime.year &&
                now.month == scheduledEndDateTime.month &&
                now.day == scheduledEndDateTime.day &&
                now.hour == scheduledEndDateTime.hour &&
                now.minute == scheduledEndDateTime.minute) {
              String title = task.title ?? 'Task Reminder';
              String body =
                  '${task.note ?? 'No note'} \n ${task.startTime ?? 'No start time'} - ${task.endTime ?? 'No end time'}';
              await NotificationService().showNotification(
                  id: notificationId,
                  title: title,
                  body: body,
                  remind: task.remind ?? 5);
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching tasks: $e');
      const snackbarInterval = Duration(minutes: 5);
      final now = DateTime.now();
      if (lastSnackbarTime == null ||
          now.difference(lastSnackbarTime!) > snackbarInterval) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${AppLocalizations.of(context)!.calendarError}$e')));
        lastSnackbarTime = now;
      }
    }
  }

  Color _getTaskColor(int taskId, bool isCompleted) {
    if (isCompleted) {
      return Colors.grey;
    } else if (_taskColors.containsKey(taskId)) {
      return _taskColors[taskId]!;
    } else {
      Random random = Random();
      int randomIndex;
      do {
        randomIndex = random.nextInt(_availableColors.length);
      } while (_availableColors[randomIndex] == Colors.white ||
          _availableColors[randomIndex] == Colors.black ||
          _availableColors[randomIndex] == Colors.grey);
      Color newColor = _availableColors[randomIndex];
      _taskColors[taskId] = newColor;
      return newColor;
    }
  }

  Future<void> _completeTask(Task task) async {
    try {
      final apiHandler = APIHandler();
      Task updatedTask = task.copyWith(isCompleted: 1);
      final response = await apiHandler.updateTaskStatus(task.id!, updatedTask);
      if (response.statusCode == 204) {
        _fetchTasks();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.calendarTaskComplete)));
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.calendarTaskUpdateFail}${response.data}')));
      }
    } catch (e) {
      print('Error completing task: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${AppLocalizations.of(context)!.calendarTaskCompleteError}$e')));
    }
  }

  Future<void> _deleteTask(int taskId) async {
    try {
      final apiHandler = APIHandler();
      final response = await apiHandler.deleteTask(taskId);
      if (response.statusCode == 204) {
        _fetchTasks();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.calendarTaskDelete)));
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.calendarTaskDeleteFail}${response.data}')));
      }
    } catch (e) {
      print('Error deleting task: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${AppLocalizations.of(context)!.calendarTaskDeleteError}$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryClr = const Color(0xFF90CAF9);
    String todayDate =
        DateFormat(AppLocalizations.of(context)!.calendarDateFormat)
            .format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.calendarTodayTitle,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                Text(todayDate, style: const TextStyle(fontSize: 18)),
              ],
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: primaryClr,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            AddTaskScreen(currentUser: widget.currentUser)));
              },
              child: Text(
                  '${AppLocalizations.of(context)!.add} ${AppLocalizations.of(context)!.addTaskTitle}',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 140,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemBuilder: (context, index) {
                DateTime date = DateTime.now()
                    .subtract(const Duration(days: 2))
                    .add(Duration(days: index));
                return _buildDateTile(date, primaryClr, context);
              },
              itemCount: 365 * 10,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildTaskList()),
        ],
      ),
    );
  }

  Widget _buildDateTile(DateTime date, Color primaryClr, BuildContext context) {
    bool isSelected = date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;
    double tileWidth = MediaQuery.of(context).size.width / 5;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedDate = date;
        _scrollToSelectedDate();
      }),
      child: SizedBox(
        width: tileWidth,
        height: 110,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? primaryClr : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(DateFormat('MMM').format(date).toUpperCase(),
                  style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white : Colors.grey)),
              Text(DateFormat('dd').format(date),
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black)),
              Text(DateFormat('yyyy').format(date),
                  style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    List<Task> filteredTasks = _tasks.where((task) {
      if (task.date == null) return false;
      DateTime taskDate = DateFormat('yyyy-MM-dd').parse(task.date!);
      return taskDate.year == _selectedDate.year &&
          taskDate.month == _selectedDate.month &&
          taskDate.day == _selectedDate.day;
    }).toList();

    if (filteredTasks.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.calendarNoTask));
    } else {
      return ListView.builder(
        itemCount: filteredTasks.length,
        itemBuilder: (context, index) {
          final task = filteredTasks[index];
          Color taskColor = _getTaskColor(task.id!, task.isCompleted == 1);
          return GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title:
                      Text(AppLocalizations.of(context)!.calendarTaskOptions),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () => _completeTask(task),
                        child: Text(AppLocalizations.of(context)!
                            .calendarTaskMarkComplete),
                      ),
                      // ElevatedButton(
                      //   onPressed: () {
                      //     //Empty for the button to still exist
                      //   },
                      //   child: Text("Show Test Notification"),
                      // ),
                      ElevatedButton(
                        onPressed: () => _deleteTask(task.id!),
                        child: Text(AppLocalizations.of(context)!
                            .calendarTaskDeleteButton),
                      ),
                    ],
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(AppLocalizations.of(context)!.calendarClose),
                    ),
                  ],
                ),
              );
            },
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: taskColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title ?? AppLocalizations.of(context)!.noTitle,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time),
                        const SizedBox(width: 4),
                        Text(
                            '${task.startTime ?? AppLocalizations.of(context)!.notApplicable} - ${task.endTime ?? AppLocalizations.of(context)!.notApplicable}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(task.note ?? AppLocalizations.of(context)!.noNote),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  }
}
