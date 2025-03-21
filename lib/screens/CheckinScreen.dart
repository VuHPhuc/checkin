import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:checkin/model/apiHandler.dart';
import 'package:checkin/model/records.dart';
import 'package:checkin/model/users.dart';
import 'package:checkin/screens/CalenderScreen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:dio/dio.dart';

class CheckinScreen extends StatefulWidget {
  // Màn hình check-in, nhận vào một User object
  final User currentUser;

  const CheckinScreen({required this.currentUser, super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  // Khai báo các biến trạng thái
  double screenHeight = 0; // Chiều cao màn hình
  double screenWidth = 0; // Chiều rộng màn hình
  String checkIn = "--/--"; // Thời gian check-in
  String checkOut = "--/--"; // Thời gian check-out
  final Color primaryColor =
      const Color.fromARGB(253, 239, 68, 76); // Màu chủ đạo
  final GlobalKey key = GlobalKey(); // Key toàn cục
  File? _image; // File ảnh
  bool _isImageCaptured = false; // Trạng thái đã chụp ảnh
  final APIHandler _apiHandler =
      APIHandler(); // Đối tượng APIHandler để tương tác với API
  late Records? _latestRecord; // Bản ghi check-in/out mới nhất

  final _recordStreamController = StreamController<
      Records?>.broadcast(); // Stream để cập nhật dữ liệu check-in/out

  Timer? _timeUpdateTimer; // Timer cập nhật thời gian
  Timer? _recordUpdateTimer; // Timer cập nhật bản ghi
  int _currentDayCheckOutCount = 0; // Số lần check-out trong ngày

  bool _isLoadingImage = false; // Trạng thái đang tải ảnh lên

  @override
  void initState() {
    // Hàm initState được gọi khi widget được khởi tạo
    super.initState();
    _getRecord(); // Lấy dữ liệu bản ghi check-in/out
  }

  @override
  void dispose() {
    // Hàm dispose được gọi khi widget bị hủy
    _timeUpdateTimer?.cancel(); // Hủy timer cập nhật thời gian
    _recordUpdateTimer?.cancel(); // Hủy timer cập nhật bản ghi
    _recordStreamController.close(); // Đóng stream controller
    super.dispose();
  }

  void _showErrorMessage(String message) {
    // Hàm hiển thị thông báo lỗi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    // Hàm hiển thị thông báo thành công
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future _getRecord() async {
    // Hàm lấy thông tin bản ghi check-in/out mới nhất
    try {
      DateTime currentDate = DateTime.now(); // Lấy ngày hiện tại
      _latestRecord = await _apiHandler.getLatestRecord(
          widget.currentUser.userId, currentDate); // Gọi API để lấy bản ghi

      if (_latestRecord != null) {
        // Nếu có bản ghi
        setState(() {
          checkIn = _latestRecord!.checkIn; // Cập nhật thời gian check-in
          checkOut = _latestRecord!.checkOut; // Cập nhật thời gian check-out
        });
      }

      _recordStreamController.add(_latestRecord); // Thêm dữ liệu vào stream
    } catch (e) {
      // Nếu có lỗi
      setState(() {
        checkIn = "--/--"; // Đặt lại thời gian check-in
        checkOut = "--/--"; // Đặt lại thời gian check-out
      });
      _recordStreamController.add(_latestRecord); // Thêm dữ liệu vào stream
    }
  }

  Future<void> _getImageFromCamera() async {
    // Hàm chụp ảnh từ camera
    final picker = ImagePicker(); // Tạo đối tượng ImagePicker
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera, // Nguồn ảnh là camera
      imageQuality: 25,
    ); // Chọn ảnh từ camera

    if (pickedFile != null) {
      // Nếu có ảnh được chọn
      final imageFile = File(pickedFile.path); // Tạo file từ đường dẫn ảnh

      _image = imageFile; // Gán file ảnh

      setState(() {
        _image = _image; // Cập nhật file ảnh
        _isImageCaptured = true; // Cập nhật trạng thái đã chụp ảnh
      });
    }
  }

  Future<Uint8List?> resizeAndCompressImage(
      File imageFile, int maxWidth, int maxHeight) async {
    // Hàm resize và nén ảnh
    var result = await FlutterImageCompress.compressWithFile(
      imageFile.absolute.path,
      minWidth: maxWidth,
      minHeight: maxHeight,
      quality: 80,
    );
    return result;
  }

  Future<String?> _uploadImageAndReturnLocation(
      File? imageFile, String type) async {
    // Hàm tải ảnh lên server và trả về location
    if (imageFile != null) {
      // Nếu có ảnh
      setState(() {
        _isLoadingImage = true; // Đặt trạng thái đang tải ảnh lên
      });
      try {
        String filename;
        if (type == 'checkin') {
          // Tạo tên file ảnh cho check-in
          filename =
              'checkin_${widget.currentUser.userId}_${widget.currentUser.name}_${DateTime.now().toIso8601String().replaceAll(':', '.')}.jpg';
        } else {
          // Tạo tên file ảnh cho check-out
          filename =
              'checkout-${_currentDayCheckOutCount}_${widget.currentUser.userId}_${widget.currentUser.name}_${DateTime.now().toIso8601String().replaceAll(':', '.')}.jpg';
          _currentDayCheckOutCount++; // Tăng số lần check-out trong ngày
        }

        final FormData formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(imageFile.path,
              filename: filename), // Tạo FormData để tải file lên
        });

        final apiUrl =
            '${_apiHandler.baseUrl}/records/location'; // API endpoint
        final response = await Dio().post(
          apiUrl,
          data: formData,
          options: Options(
            headers: {
              'Content-Type': 'multipart/form-data'
            }, // Thiết lập header
          ),
        );

        if (response.statusCode == 200) {
          // Nếu tải lên thành công
          _showSuccessMessage(AppLocalizations.of(context)!
              .checkinImageUploadSuccess); // Hiển thị thông báo thành công
          setState(() {
            _image = null; // Đặt lại file ảnh
            _isImageCaptured = false; // Đặt lại trạng thái đã chụp ảnh
          });
          await _getRecord(); // Lấy lại thông tin bản ghi
          return response.data['location']; // Trả về location của ảnh
        } else {
          // Nếu tải lên thất bại
          _showErrorMessage(AppLocalizations.of(context)!
              .checkinUploadError); // Hiển thị thông báo lỗi
        }
      } catch (e) {
        // Nếu có lỗi
        _showErrorMessage(AppLocalizations.of(context)!
            .checkinUploadError); // Hiển thị thông báo lỗi
      } finally {
        setState(() {
          _isLoadingImage = false; // Đặt trạng thái không tải ảnh
        });
      }
    } else {
      _showErrorMessage(AppLocalizations.of(context)!
          .checkinSelectImage); // Hiển thị thông báo lỗi nếu không có ảnh
    }
    return null; // Trả về null nếu không thành công
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
            Container(
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.only(top: 15),
              child: Text(
                AppLocalizations.of(context)!.checkinHello, // Hiển thị lời chào
                style: const TextStyle(color: Colors.black45, fontSize: 25),
              ),
            ),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!
                          .checkinMrMrs, // Hiển thị Mr/Mrs
                      style: TextStyle(
                          color: primaryColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      AppLocalizations.of(context)!
                          .checkinEmail, // Hiển thị Email
                      style: TextStyle(
                          color: primaryColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      AppLocalizations.of(context)!
                          .checkinYourLocation, // Hiển thị vị trí
                      style: TextStyle(
                          color: primaryColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(width: screenWidth / 55),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ':  ${widget.currentUser.name}', // Hiển thị tên người dùng
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      ':  ${widget.currentUser.email}', // Hiển thị email người dùng
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      ':  ...', // Hiển thị "..."
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              alignment: Alignment.centerLeft,
              child: Text(
                AppLocalizations.of(context)!
                    .checkinTodayInformation, // Hiển thị thông tin ngày
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 25,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              child: RichText(
                  text: TextSpan(
                      text: DateTime.now().day.toString(),
                      style: TextStyle(
                          color: primaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                      children: [
                    TextSpan(
                        text: DateFormat(" MM yyyy").format(DateTime.now()),
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 17,
                            fontWeight: FontWeight.bold))
                  ])),
            ),
            StreamBuilder(
                stream: Stream.periodic(
                    const Duration(seconds: 1)), // Stream để cập nhật thời gian
                builder: (context, Snapshot) {
                  return Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      DateFormat("HH:mm:ss").format(
                          DateTime.now()), // Hiển thị thời gian hiện tại
                      style:
                          const TextStyle(fontSize: 17, color: Colors.black45),
                    ),
                  );
                }),
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 15),
              height: 100,
              decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black45,
                        blurRadius: 10,
                        offset: Offset(2, 2))
                  ],
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)!
                            .checkinCheckin, // Hiển thị nhãn check-in
                        style: const TextStyle(
                            fontSize: 20, color: Colors.black54),
                      ),
                      StreamBuilder<Records?>(
                        stream: _recordStreamController
                            .stream, // Stream để cập nhật thời gian check-in
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              snapshot.data?.checkIn ??
                                  checkIn, // Hiển thị thời gian check-in
                              style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            );
                          } else {
                            return Text(
                              checkIn,
                              style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            );
                          }
                        },
                      )
                    ],
                  )),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)!
                            .checkinCheckout, // Hiển thị nhãn check-out
                        style: const TextStyle(
                            fontSize: 20, color: Colors.black54),
                      ),
                      StreamBuilder<Records?>(
                        stream: _recordStreamController
                            .stream, // Stream để cập nhật thời gian check-out
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              snapshot.data?.checkOut ??
                                  checkOut, // Hiển thị thời gian check-out
                              style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            );
                          } else {
                            return Text(
                              checkOut,
                              style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            );
                          }
                        },
                      )
                    ],
                  ))
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _getImageFromCamera, // Gọi hàm chụp ảnh khi nhấn
                  icon: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 50, color: primaryColor),
                      Icon(FontAwesomeIcons.expand,
                          size: 90, color: primaryColor),
                    ],
                  ),
                ),
                if (_isImageCaptured)
                  Expanded(
                    child: Image.file(
                      alignment: Alignment.centerRight,
                      _image!,
                      width: screenWidth / 2,
                      height: screenHeight / 4,
                    ),
                  ),
              ],
            ),
            if (checkIn == "--/--")
              Container(
                margin: const EdgeInsets.only(top: 15),
                child: SizedBox(
                  width: screenWidth,
                  height: screenHeight / 15,
                  child: ElevatedButton(
                    onPressed: _isImageCaptured &&
                            _image != null &&
                            !_isLoadingImage
                        ? () async {
                            // Hàm check-in
                            String? locationImg =
                                await _uploadImageAndReturnLocation(
                                    _image, 'checkin'); // Tải ảnh lên server

                            Records record = Records(
                              id: 0,
                              userId: widget.currentUser.userId,
                              date: DateTime.now(),
                              checkIn:
                                  DateFormat('HH:mm').format(DateTime.now()),
                              checkOut: '--/--',
                              shiftId: 1,
                              lateMinutes: 0,
                              status: 'Working',
                              location: locationImg ?? '', // Lưu vị trí ảnh
                              remark: 'None',
                              imgName:
                                  'checkin_${widget.currentUser.userId}_${widget.currentUser.name}_${DateTime.now().millisecondsSinceEpoch}.jpg', // Lưu tên ảnh
                              ip: 'none', // ip set as empty string
                            );

                            try {
                              final response = await _apiHandler.insertRecord(
                                  record, _image); // Gọi API để check-in

                              if (response.statusCode == 201) {
                                print(
                                    'Check-in successful: ${response.statusCode}');
                                setState(() {
                                  checkIn = DateFormat('HH:mm').format(DateTime
                                      .now()); // Cập nhật thời gian check-in

                                  _getRecord(); // Lấy lại thông tin bản ghi
                                });
                              } else {
                                if (response.statusCode == 400) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content:
                                        Text("Invalid data: ${response.data}"),
                                  ));
                                } else {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        "Check-in Error: ${response.data}"),
                                  ));
                                }
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        "Check-in Error: ${e.toString()}")),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isImageCaptured ? primaryColor : Colors.grey[400]!,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      _isImageCaptured
                          ? AppLocalizations.of(context)!
                              .checkinPressToCheckIn // Hiển thị nhãn check-in
                          : AppLocalizations.of(context)!
                              .checkinTakePictureAndCheckLocation, // Hiển thị nhãn chụp ảnh
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            if (checkIn != "--/--")
              Container(
                margin: const EdgeInsets.only(top: 15),
                child: SizedBox(
                  width: screenWidth,
                  height: screenHeight / 15,
                  child: ElevatedButton(
                    onPressed: _isImageCaptured &&
                            _image != null &&
                            !_isLoadingImage
                        ? () async {
                            // Hàm check-out
                            String? locationImg =
                                await _uploadImageAndReturnLocation(
                                    _image, 'checkout'); // Tải ảnh lên server

                            Records record = Records(
                              id: 0,
                              userId: widget.currentUser.userId,
                              date: DateTime.now(),
                              checkIn: checkIn,
                              checkOut:
                                  DateFormat('HH:mm').format(DateTime.now()),
                              shiftId: 1,
                              lateMinutes: 0,
                              status: 'Off work',
                              location: locationImg ?? '', // Lưu vị trí ảnh
                              remark: 'None',
                              imgName:
                                  'checkout-${_currentDayCheckOutCount}_${widget.currentUser.userId}_${widget.currentUser.name}_${DateTime.now().millisecondsSinceEpoch}.jpg', // Lưu tên ảnh
                              ip: 'none', // ip set as empty string
                            );
                            try {
                              final response = await _apiHandler.insertRecord(
                                  record, _image); // Gọi API để check-out

                              if (response.statusCode == 201) {
                                print(
                                    'Check-out successful: ${response.statusCode}');
                                setState(() {
                                  checkOut = DateFormat('HH:mm').format(DateTime
                                      .now()); // Cập nhật thời gian check-out

                                  _getRecord(); // Lấy lại thông tin bản ghi
                                });
                              } else {
                                if (response.statusCode == 400) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content:
                                        Text("Invalid data: ${response.data}"),
                                  ));
                                } else {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        "Check-out Error: ${response.data}"),
                                  ));
                                }
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        "Check-out Error: ${e.toString()}")),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isImageCaptured ? primaryColor : Colors.grey[400]!,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      _isImageCaptured
                          ? AppLocalizations.of(context)!
                              .checkinPressToCheckOut // Hiển thị nhãn check-out
                          : AppLocalizations.of(context)!
                              .checkinTakePictureAndCheckLocation, // Hiển thị nhãn chụp ảnh
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            Container(
              margin: const EdgeInsets.only(top: 15),
              child: SizedBox(
                width: screenWidth,
                height: screenHeight / 15,
                child: ElevatedButton(
                  onPressed: () {
                    // Mở màn hình lịch
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CalendarScreen(currentUser: widget.currentUser),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!
                        .checkinViewHistory, // Hiển thị nhãn xem lịch sử
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            if (checkIn != "--/--" && checkOut != "--/--")
              Container(
                margin: const EdgeInsets.only(top: 25),
                child: Text(
                    AppLocalizations.of(context)!
                        .checkinCheckedInToday, // Hiển thị thông báo đã check-in
                    style: TextStyle(
                        fontSize: screenWidth / 20, color: Colors.black54)),
              )
          ],
        ),
      ),
    );
  }
}
