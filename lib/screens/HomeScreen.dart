import 'package:checkin/model/users.dart';
import 'package:checkin/screens/CalenderScreen.dart';
import 'package:checkin/screens/CheckinScreen.dart';
import 'package:checkin/screens/NewsScreen.dart';
import 'package:checkin/screens/UsersScreen.dart';
import 'package:checkin/screens/ExamCalendarScreen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  // Màn hình chính của ứng dụng, chứa navigation bar và các màn hình con
  final User currentUser;

  const HomeScreen({required this.currentUser, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Khai báo các biến trạng thái
  double screenHeight = 0; // Chiều cao màn hình
  double screenWidth = 0; // Chiều rộng màn hình

  final Color primaryColor =
      const Color.fromARGB(253, 239, 68, 76); // Màu chủ đạo

  int currentIndex = 0; // Chỉ số trang hiện tại

  final List<IconData> navigationIcons = [
    // Danh sách các icon cho navigation bar
    FontAwesomeIcons.newspaper,
    FontAwesomeIcons.calendarCheck,
    FontAwesomeIcons.check,
    FontAwesomeIcons.user,
  ];

  late SharedPreferences
      sharedPreferences; // Đối tượng SharedPreferences để lưu trữ thông tin

  @override
  void initState() {
    // Hàm initState được gọi khi widget được khởi tạo
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Hàm build giao diện người dùng
    screenHeight = MediaQuery.of(context).size.height; // Lấy chiều cao màn hình
    screenWidth = MediaQuery.of(context).size.width; // Lấy chiều rộng màn hình

    return Scaffold(
      body: IndexedStack(
        index: currentIndex, // Hiển thị trang tương ứng với chỉ số
        children: [
          const NewsScreen(), // Màn hình tin tức
          ExamCalendarScreen(
              currentUser: widget.currentUser), // Màn hình lịch công việc
          CheckinScreen(
              currentUser: widget.currentUser), // Màn hình check-in/out
          UsersScreen(currentUser: widget.currentUser), // Màn hình người dùng
        ],
      ),
      bottomNavigationBar: Container(
        height: 70,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: ClipRRect(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < navigationIcons.length; i++) ...<Expanded>[
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Hàm xử lý khi nhấn vào một item của navigation bar
                      setState(() {
                        currentIndex = i; // Cập nhật chỉ số trang hiện tại
                      });
                    },
                    child: Container(
                      height: screenHeight,
                      width: screenWidth,
                      color: Colors.white,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              navigationIcons[i], // Hiển thị icon của item
                              color: i == currentIndex
                                  ? primaryColor
                                  : Colors
                                      .black54, // Đổi màu icon khi được chọn
                              size: i == currentIndex ? 25 : 25,
                            ),
                            if (i == currentIndex)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                height: 3,
                                width: 15,
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(40),
                                  ),
                                ),
                              ), // Hiển thị dấu gạch dưới khi item được chọn
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
