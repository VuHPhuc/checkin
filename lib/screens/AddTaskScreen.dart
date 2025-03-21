import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:checkin/model/apiHandler.dart';
import 'package:checkin/model/task.dart';
import 'package:checkin/model/users.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:checkin/services/NotificationService.dart';

class AddTaskScreen extends StatefulWidget {
  // Lớp StatefulWidget AddTaskScreen, nhận vào một User object
  final User currentUser;
  const AddTaskScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  // Khai báo các biến trạng thái của form
  final _formKey = GlobalKey<FormState>(); // Khóa form để quản lý trạng thái
  String? _title; // Tiêu đề công việc
  String? _note; // Ghi chú công việc
  String? _date; // Ngày thực hiện công việc
  TimeOfDay? _startTime; // Thời gian bắt đầu công việc
  TimeOfDay? _endTime; // Thời gian kết thúc công việc
  int _remind = 5; // Thời gian nhắc nhở công việc (mặc định 5 phút)
  String _repeat = 'None'; // Chế độ lặp lại công việc (mặc định không lặp)

  @override
  Widget build(BuildContext context) {
    // Xây dựng giao diện người dùng
    return Scaffold(
      appBar: AppBar(
        title:
            Text(AppLocalizations.of(context)!.addTaskTitle), // Tiêu đề AppBar
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Gán formKey để quản lý form
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TextFormFields cho các trường nhập liệu
              TextFormField(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!
                      .addTaskTitleLabel, // Nhãn cho trường tiêu đề
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  // Hàm kiểm tra giá trị nhập vào có rỗng không
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!
                        .addTaskTitleError; // Trả về thông báo lỗi nếu rỗng
                  }
                  return null; // Trả về null nếu hợp lệ
                },
                onSaved: (value) =>
                    _title = value, // Lưu giá trị tiêu đề vào biến _title
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!
                      .addTaskNoteLabel, // Nhãn cho trường ghi chú
                  border: const OutlineInputBorder(),
                  hintText: AppLocalizations.of(context)!
                      .addTaskNoteHint, // Gợi ý cho trường ghi chú
                ),
                onSaved: (value) =>
                    _note = value, // Lưu giá trị ghi chú vào biến _note
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!
                      .addTaskDateLabel, // Nhãn cho trường ngày
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today), // Icon lịch
                ),
                readOnly: true, // Không cho phép nhập bằng bàn phím
                onTap: () async {
                  // Hàm mở DatePicker khi người dùng chạm vào trường ngày
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(), // Ngày mặc định
                    firstDate: DateTime(2000), // Ngày bắt đầu
                    lastDate: DateTime(2101), // Ngày kết thúc
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _date = DateFormat('yyyy-MM-dd').format(
                          pickedDate); // Định dạng ngày và cập nhật lại giao diện
                    });
                  }
                },
                controller: TextEditingController(
                  text: _date, // Hiển thị ngày đã chọn
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!
                            .addTaskStartTimeLabel, // Nhãn cho trường thời gian bắt đầu
                        border: const OutlineInputBorder(),
                        suffixIcon:
                            const Icon(Icons.access_time), // Icon đồng hồ
                      ),
                      readOnly: true, // Không cho phép nhập bằng bàn phím
                      onTap: () async {
                        // Hàm mở TimePicker khi người dùng chạm vào trường thời gian bắt đầu
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(), // Thời gian mặc định
                        );
                        if (pickedTime != null) {
                          setState(() => _startTime =
                              pickedTime); // Cập nhật thời gian bắt đầu và giao diện
                        }
                      },
                      controller: TextEditingController(
                        text: _startTime != null
                            ? _startTime!.format(
                                context) // Định dạng thời gian và hiển thị
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!
                            .addTaskEndTimeLabel, // Nhãn cho trường thời gian kết thúc
                        border: const OutlineInputBorder(),
                        suffixIcon:
                            const Icon(Icons.access_time), // Icon đồng hồ
                      ),
                      readOnly: true, // Không cho phép nhập bằng bàn phím
                      onTap: () async {
                        // Hàm mở TimePicker khi người dùng chạm vào trường thời gian kết thúc
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(), // Thời gian mặc định
                        );
                        if (pickedTime != null) {
                          setState(() => _endTime =
                              pickedTime); // Cập nhật thời gian kết thúc và giao diện
                        }
                      },
                      controller: TextEditingController(
                        text: _endTime != null
                            ? _endTime!.format(context)
                            : null, // Định dạng thời gian và hiển thị
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!
                      .addTaskRemindLabel, // Nhãn cho trường nhắc nhở
                  border: const OutlineInputBorder(),
                ),
                value: _remind, // Giá trị mặc định
                items: [
                  // Các tùy chọn nhắc nhở
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
                onChanged: (value) => setState(() =>
                    _remind = value!), // Cập nhật giá trị nhắc nhở khi chọn
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!
                      .addTaskRepeatLabel, // Nhãn cho trường lặp lại
                  border: const OutlineInputBorder(),
                ),
                value: _repeat, // Giá trị mặc định
                items: [
                  // Các tùy chọn lặp lại
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
                onChanged: (value) => setState(() =>
                    _repeat = value!), // Cập nhật giá trị lặp lại khi chọn
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: () async {
                  // Hàm xử lý khi người dùng nhấn nút tạo
                  if (_formKey.currentState!.validate()) {
                    // Kiểm tra form có hợp lệ không
                    _formKey.currentState!
                        .save(); // Lưu tất cả các giá trị trong form vào các biến

                    Task newTask = Task(
                      userId: widget.currentUser.userId,
                      title: _title,
                      note: _note,
                      isCompleted: 0, // Mặc định công việc chưa hoàn thành
                      date: _date,
                      startTime: _startTime?.format(context),
                      endTime: _endTime?.format(context),
                      remind: _remind,
                      repeat: _repeat,
                    );

                    try {
                      final apiHandler =
                          APIHandler(); // Tạo đối tượng APIHandler để tương tác với API
                      final response = await apiHandler
                          .insertTask(newTask); // Gọi API để tạo công việc mới

                      if (response.statusCode == 201 ||
                          response.statusCode == 200) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(AppLocalizations.of(context)!
                                  .addTaskCreateSuccess)),
                        );
                        if (newTask.startTime != null && newTask.date != null) {
                          int notificationId;
                          if (response.data['id'] != null) {
                            notificationId = response.data['id'];
                          } else {
                            notificationId = DateTime.now().hashCode;
                            if (notificationId < 0) {
                              notificationId = -notificationId;
                            }
                          }
                          final taskDate =
                              DateFormat('yyyy-MM-dd').parse(newTask.date!);
                          final taskTime =
                              DateFormat('HH:mm').parse(newTask.startTime!);
                          DateTime scheduledDateTime = DateTime(
                              taskDate.year,
                              taskDate.month,
                              taskDate.day,
                              taskTime.hour,
                              taskTime.minute);
                          scheduledDateTime = scheduledDateTime.subtract(
                              Duration(
                                  minutes:
                                      newTask.remind ?? 5)); //subtract remind
                          String title = newTask.title ?? 'Task Reminder';
                          String body = newTask.note ?? 'Task starting now';
                          await NotificationService().showScheduledNotification(
                            id: notificationId,
                            title: title,
                            body: body,
                            scheduledTime: scheduledDateTime,
                          );
                        }
                        Navigator.of(context).pop(true);
                      } else {
                        print(
                            'Failed to create task: ${response.statusCode}'); // In lỗi nếu API trả về thất bại
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(AppLocalizations.of(context)!
                                  .addTaskCreateFail)), // Hiển thị thông báo thất bại
                        );
                      }
                    } catch (e) {
                      // Bắt lỗi nếu có lỗi trong quá trình gọi API
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                '${AppLocalizations.of(context)!.error}: $e')), // Hiển thị thông báo lỗi
                      );
                    }
                  }
                },
                child: Text(AppLocalizations.of(context)!
                    .addTaskCreateButton), // Nhãn cho nút tạo
              ),
              const SizedBox(height: 32),
              // ElevatedButton(
              //     onPressed: () async {
              //       int notificationId = DateTime.now().hashCode;
              //       if (notificationId < 0) {
              //         notificationId = -notificationId;
              //       }
              //       await NotificationService().showNotification(
              //           id: notificationId,
              //           title: "Test Notification",
              //           body: "This is a simple test notification",
              //           remind: 5);
              //     },
              //     child: const Text("Show Test Notification")),
            ],
          ),
        ),
      ),
    );
  }
}
