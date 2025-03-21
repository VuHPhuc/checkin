import 'dart:async';
import 'package:checkin/model/users.dart';
import 'package:checkin/model/records.dart';
import 'package:checkin/model/apiHandler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

class CalendarScreen extends StatefulWidget {
  // Màn hình lịch, hiển thị lịch sử check-in/out của người dùng
  final User currentUser;

  const CalendarScreen({super.key, required this.currentUser});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // Khai báo các biến trạng thái
  double screenHeight = 0; // Chiều cao màn hình
  double screenWidth = 0; // Chiều rộng màn hình

  final Color primaryColor =
      const Color.fromARGB(253, 239, 68, 76); // Màu chủ đạo

  final APIHandler _apiHandler =
      APIHandler(); // Đối tượng APIHandler để tương tác với API

  DateTime _selectedDate = DateTime.now(); // Ngày được chọn trên lịch
  Map<DateTime, List<Records>> _groupedRecords =
      {}; // Map chứa các bản ghi được nhóm theo ngày

  final _recordsStreamController = StreamController<
      List<Records>>.broadcast(); // Stream để cập nhật dữ liệu bản ghi

  Timer? _timer; // Timer

  @override
  void initState() {
    // Hàm initState được gọi khi widget được khởi tạo
    super.initState();
    _fetchRecords().then((records) {
      // Gọi hàm lấy dữ liệu bản ghi và cập nhật stream
      setState(() {
        _recordsStreamController.add(records);
      });
    });
  }

  @override
  void dispose() {
    // Hàm dispose được gọi khi widget bị hủy
    _timer?.cancel(); // Hủy timer
    _recordsStreamController.close(); // Đóng stream controller
    super.dispose();
  }

  Future<List<Records>> _fetchRecords() async {
    // Hàm lấy danh sách bản ghi check-in/out từ API
    try {
      final allRecords = await _apiHandler
          .getUserRecords(widget.currentUser.userId); //fetch all records
      //filter by user id
      final userRecords = allRecords
          .where((record) => record.userId == widget.currentUser.userId)
          .toList();

      final filteredRecords = userRecords
          .where((record) =>
              record.date.year == _selectedDate.year &&
              record.date.month == _selectedDate.month)
          .toList(); // Lọc các bản ghi theo tháng được chọn

      return filteredRecords; // Trả về danh sách bản ghi
    } catch (e) {
      print('Error fetching records: $e'); // In lỗi nếu có
      return []; // Trả về danh sách rỗng nếu có lỗi
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hàm build giao diện người dùng
    screenHeight = MediaQuery.of(context).size.height; // Lấy chiều cao màn hình
    screenWidth = MediaQuery.of(context).size.width; // Lấy chiều rộng màn hình
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTitle(), // Xây dựng tiêu đề
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      Navigator.pop(context); // Quay lại màn hình trước
                    },
                  ),
                )
              ],
            ),
            _buildMonthYearSelector(), // Xây dựng bộ chọn tháng/năm
            const SizedBox(height: 20),
            _buildRecordsListView(), // Xây dựng danh sách bản ghi
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    // Hàm xây dựng tiêu đề
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(top: 20),
      child: Text(
        AppLocalizations.of(context)!
            .calendarYourAttendanceRecord, // Hiển thị tiêu đề
        style: const TextStyle(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMonthYearSelector() {
    // Hàm xây dựng bộ chọn tháng/năm
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          alignment: Alignment.centerLeft,
          margin: const EdgeInsets.only(top: 25),
          child: Text(
            DateFormat('MM / yyyy')
                .format(_selectedDate), // Hiển thị tháng/năm đang chọn
            style: TextStyle(
              color: primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 25),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: InkWell(
            onTap: () {
              // Hàm chọn ngày trên lịch
              showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              ).then((pickedDate) {
                // Khi chọn xong ngày
                if (pickedDate != null) {
                  setState(() {
                    _selectedDate = pickedDate; // Cập nhật ngày được chọn
                    _fetchRecords().then((records) {
                      // Gọi hàm lấy lại dữ liệu và cập nhật stream
                      setState(() {
                        _recordsStreamController.add(records);
                      });
                    });
                  });
                }
              });
            },
            child: Text(
              AppLocalizations.of(context)!
                  .calendarChangeMonthYear, // Hiển thị nhãn chọn tháng/năm
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordsListView() {
    // Hàm xây dựng danh sách bản ghi
    return StreamBuilder<List<Records>>(
      stream:
          _recordsStreamController.stream, // Stream để cập nhật dữ liệu bản ghi
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // Nếu có dữ liệu
          final records = snapshot.data!;
          _groupedRecords =
              groupRecordsByDay(records); // Nhóm các bản ghi theo ngày
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _groupedRecords.keys.length,
            itemBuilder: (context, index) {
              final date = _groupedRecords.keys.elementAt(index); // Lấy ngày
              final dayRecords =
                  _groupedRecords[date]!; // Lấy danh sách bản ghi của ngày đó
              return _buildDayRecord(date,
                  dayRecords); // Xây dựng widget hiển thị bản ghi của ngày
            },
          );
        } else if (snapshot.hasError) {
          // Nếu có lỗi
          return Center(
              child: Text(
                  "${AppLocalizations.of(context)!.calendarError}${snapshot.error}")); // Hiển thị thông báo lỗi
        } else {
          return const Center(
              child:
                  CircularProgressIndicator()); // Hiển thị loading khi đang tải dữ liệu
        }
      },
    );
  }

  Map<DateTime, List<Records>> groupRecordsByDay(List<Records> records) {
    // Hàm nhóm các bản ghi theo ngày
    Map<DateTime, List<Records>> groupedRecords = {}; // Tạo Map để lưu trữ
    for (var record in records) {
      // Duyệt qua từng bản ghi
      if (record.date.year == _selectedDate.year &&
          record.date.month == _selectedDate.month) {
        // Kiểm tra xem bản ghi có thuộc tháng và năm đang chọn không
        final date = DateTime(record.date.year, record.date.month,
            record.date.day); // Tạo đối tượng DateTime từ ngày
        groupedRecords.update(
          date,
          (existingRecords) => existingRecords..add(record),
          ifAbsent: () => [record],
        ); // Thêm bản ghi vào Map
      }
    }

    // Sắp xếp các ngày theo thứ tự giảm dần (ngày mới nhất lên đầu)
    final sortedKeys = groupedRecords.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    // Tạo một bản sao của `groupedRecords` với các ngày được sắp xếp
    Map<DateTime, List<Records>> sortedGroupedRecords = {};
    sortedKeys.forEach((key) {
      sortedGroupedRecords[key] = groupedRecords[key]!;
    });

    return sortedGroupedRecords; // Trả về Map đã nhóm
  }

  Widget _buildDayRecord(DateTime date, List<Records> dayRecords) {
    // Hàm xây dựng widget hiển thị bản ghi theo ngày
    return InkWell(
      onTap: () {
        // Hàm hiển thị chi tiết bản ghi khi nhấn vào ngày
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Container(
              padding: const EdgeInsets.only(
                  bottom: 10, top: 10, left: 20, right: 20),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                DateFormat(AppLocalizations.of(context)!.calendarDateFormat)
                    .format(date), // Hiển thị ngày
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            content: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (dayRecords.isNotEmpty &&
                        dayRecords.last.checkIn != "--/--")
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          '${AppLocalizations.of(context)!.calendarCheckin}: ${dayRecords.last.checkIn}', // Hiển thị thời gian check-in
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(253, 239, 68, 76),
                          ),
                        ),
                      ),
                    for (var record in dayRecords
                        .where((record) => record.location != null)
                        .toList()) // Lọc các bản ghi có location
                      Column(
                        children: [
                          if (record.checkOut.isNotEmpty &&
                              record.checkOut.trim() != ' ' &&
                              record.checkOut !=
                                  "--/--") // Kiểm tra có checkout
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                '${AppLocalizations.of(context)!.calendarCheckout}: ${record.checkOut}', // Hiển thị thời gian check-out
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          FutureBuilder(
                            future: _fetchImageFromLocation(
                                record.location), // Lấy ảnh từ location
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                final imageData = snapshot.data
                                    as Uint8List?; // Lấy dữ liệu ảnh
                                if (imageData != null) {
                                  // Hiển thị ảnh
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Image.memory(
                                      imageData,
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                } else {
                                  // Nếu không có ảnh
                                  return const SizedBox.shrink();
                                }
                              } else if (snapshot.hasError) {
                                // Nếu có lỗi khi lấy ảnh
                                return Text(
                                    '${AppLocalizations.of(context)!.calendarError}${snapshot.error}');
                              } else {
                                // Hiển thị loading khi đang lấy ảnh
                                return const CircularProgressIndicator();
                              }
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), // Đóng dialog
                child: Text(
                  AppLocalizations.of(context)!
                      .calendarClose, // Hiển thị nhãn đóng
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.only(
                  bottom: 40, top: 40, left: 10, right: 10),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy').format(date), // Hiển thị ngày
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!
                      .calendarCheckin, // Hiển thị nhãn check-in
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  dayRecords.first.checkIn, // Hiển thị thời gian check-in
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!
                      .calendarCheckout, // Hiển thị nhãn check-out
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: screenWidth / 20,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  dayRecords.last.checkOut, // Hiển thị thời gian check-out
                  style: TextStyle(
                      color: Colors.black, fontSize: screenWidth / 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List?> _fetchImageFromLocation(String? location) async {
    // Hàm lấy ảnh từ location
    if (location == null) return null; // Trả về null nếu location không có
    try {
      final baseUrl = _apiHandler.baseUrl
          .replaceFirst('/api', ''); // Tạo baseUrl từ APIHandler
      final completeImageUrl = '$baseUrl$location'; // Tạo đường dẫn ảnh đầy đủ

      final response =
          await http.get(Uri.parse(completeImageUrl)); // Gọi API để lấy ảnh
      if (response.statusCode == 200) {
        // Nếu thành công
        return response.bodyBytes; // Trả về dữ liệu ảnh
      } else {
        print('Error fetching image: ${response.statusCode}'); // In lỗi nếu có
        return null;
      }
    } catch (e) {
      print('Error fetching image: $e'); // In lỗi nếu có
      return null;
    }
  }
}
