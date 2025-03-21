import 'dart:convert';
import 'dart:typed_data';

import 'package:checkin/model/apiHandler.dart';
import 'package:checkin/model/users.dart';
import 'package:checkin/screens/HomeScreen.dart';
import 'package:checkin/screens/RegisterScreen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  // Màn hình đăng nhập
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Khai báo các biến trạng thái
  final TextEditingController emailController =
      TextEditingController(); // Controller cho trường email
  final TextEditingController passController =
      TextEditingController(); // Controller cho trường mật khẩu

  String? _emailErrorText; // Biến để hiển thị lỗi cho trường email
  String? _passwordErrorText; // Biến để hiển thị lỗi cho trường mật khẩu

  final Color primaryColor =
      const Color.fromARGB(251, 96, 244, 255); // Màu chủ đạo

  late SharedPreferences
      sharedPreferences; // Đối tượng SharedPreferences để lưu trữ thông tin đăng nhập
  final APIHandler _apiHandler =
      APIHandler(); // Đối tượng APIHandler để tương tác với API

  // Check if the user has logged in
  bool _isLoggedIn = false; // Biến để kiểm tra trạng thái đăng nhập

  // Validate email format
  String? validateEmail(String? value) {
    // Hàm kiểm tra định dạng email
    const pattern = r"(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'"
        r'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-'
        r'\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*'
        r'[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4]'
        r'[0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9]'
        r'[0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\'
        r'x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])';
    final regex = RegExp(pattern);

    return value!.isNotEmpty && !regex.hasMatch(value)
        ? AppLocalizations.of(context)!.loginInvalidEmail
        : null; // Nếu email không đúng định dạng trả về thông báo lỗi
  }

  @override
  void initState() {
    // Hàm initState được gọi khi widget được khởi tạo
    super.initState();
    _checkLoginStatus(); // Kiểm tra trạng thái đăng nhập khi widget được khởi tạo
  }

  // Check if the user has logged in
  Future<void> _checkLoginStatus() async {
    // Hàm kiểm tra trạng thái đăng nhập
    sharedPreferences = await SharedPreferences
        .getInstance(); // Lấy đối tượng SharedPreferences
    String? email = sharedPreferences
        .getString('EmployeeEmail'); // Lấy email từ SharedPreferences
    String? password = sharedPreferences
        .getString('EmployeePassword'); // Lấy mật khẩu từ SharedPreferences
    int? userId =
        sharedPreferences.getInt('UserId'); // Lấy userId từ SharedPreferences
    String? name = sharedPreferences
        .getString('EmployeeName'); // Lấy tên từ SharedPreferences
    String? avatar = sharedPreferences
        .getString('EmployeeAvatar'); // Lấy avatar từ SharedPreferences
    String? avatarLocation = sharedPreferences.getString(
        'EmployeeAvatarLocation'); // Lấy avatarLocation từ SharedPreferences
    int? isAdmin = sharedPreferences.getInt('isAdmin') ??
        0; // Lấy isAdmin từ SharedPreferences

    if (email != null && password != null && userId != null) {
      // If the user has logged in, redirect to HomeScreen
      _isLoggedIn = true; // Cập nhật trạng thái đăng nhập
      setState(() {}); // Cập nhật lại giao diện
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hàm build giao diện người dùng
    final screenHeight =
        MediaQuery.of(context).size.height; // Lấy chiều cao màn hình
    final screenWidth =
        MediaQuery.of(context).size.width; // Lấy chiều rộng màn hình

    // If the user has logged in, redirect to HomeScreen
    if (_isLoggedIn) {
      // Nếu người dùng đã đăng nhập, chuyển sang màn hình home
      return HomeScreen(
          currentUser: User(
        userId: sharedPreferences.getInt('UserId')!,
        name: sharedPreferences.getString('EmployeeName')!,
        email: sharedPreferences.getString('EmployeeEmail')!,
        password: sharedPreferences.getString('EmployeePassword')!,
        phone: sharedPreferences.getInt('EmployeePhone') ?? 0,
        address: sharedPreferences.getString('EmployeeAddress') ?? '',
        avatar: sharedPreferences.getString('EmployeeAvatar')!,
        avatarLocation: sharedPreferences.getString('EmployeeAvatarLocation')!,
        isAdmin: sharedPreferences.getInt('isAdmin')!,
      ));
    }

    return Scaffold(
      resizeToAvoidBottomInset:
          false, // Disable automatic resizing to avoid bottom inset
      body: GestureDetector(
        onTap: () {
          // Hàm xử lý khi người dùng nhấn vào màn hình
          FocusScope.of(context).unfocus(); // Hide keyboard on tap
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              MediaQuery.of(context).viewInsets.bottom > 0
                  ? const SizedBox(height: 80)
                  : Container(
                      height: screenHeight / 3,
                      width: screenWidth,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(70),
                          bottomLeft: Radius.circular(70),
                        ),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 34),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(30),
                              bottomLeft: Radius.circular(30),
                            ),
                            child: Image.asset(
                              'assets/img/Hau.png',
                              width: double.infinity,
                              height: 400,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ), // Phần hiển thị logo và background trên cùng
              Container(
                margin: EdgeInsets.only(
                  top: screenHeight / 40,
                ),
                child: Text(
                  AppLocalizations.of(context)!
                      .loginWelcomeBack, // Hiển thị tiêu đề
                  style: TextStyle(
                      fontSize: screenWidth / 14, fontWeight: FontWeight.bold),
                ),
              ), // Phần hiển thị tiêu đề "Welcome Back"
              Container(
                margin: EdgeInsets.only(
                  bottom: screenHeight / 40,
                ),
                child: Text(
                  AppLocalizations.of(context)!
                      .loginLoginToAccount, // Hiển thị tiêu đề phụ
                  style: TextStyle(
                    fontSize: screenWidth / 20,
                    color: Colors.black45,
                  ),
                ),
              ), // Phần hiển thị tiêu đề phụ
              Container(
                margin: EdgeInsets.only(
                  top: screenHeight / 40,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth / 10),
                  child: Column(
                    children: [
                      customField(
                          AppLocalizations.of(context)!
                              .loginEnterEmail, // Hiển thị trường nhập email
                          emailController,
                          false,
                          _emailErrorText,
                          FontAwesomeIcons.envelope,
                          primaryColor,
                          screenWidth),
                      customField(
                          AppLocalizations.of(context)!
                              .loginEnterPassword, // Hiển thị trường nhập mật khẩu
                          passController,
                          true,
                          _passwordErrorText,
                          FontAwesomeIcons.key,
                          primaryColor,
                          screenWidth),
                      // Login button
                      GestureDetector(
                        onTap: () async {
                          // Hàm xử lý khi người dùng nhấn nút đăng nhập
                          FocusScope.of(context).unfocus(); // Đóng bàn phím
                          final String email =
                              emailController.text.trim(); // Lấy email
                          final String password =
                              passController.text.trim(); // Lấy mật khẩu

                          if (email.isEmpty) {
                            setState(() {
                              _emailErrorText = AppLocalizations.of(context)!
                                  .loginEmailEmpty; // Nếu email rỗng thì trả về thông báo lỗi
                            });
                          } else {
                            _emailErrorText = validateEmail(
                                email); // Kiểm tra định dạng email
                          }

                          if (password.isEmpty) {
                            setState(() {
                              _passwordErrorText = AppLocalizations.of(context)!
                                  .loginPasswordEmpty; // Nếu mật khẩu rỗng thì trả về thông báo lỗi
                            });
                          } else {
                            _passwordErrorText =
                                null; // Nếu có dữ liệu thì không có lỗi
                          }

                          if (_emailErrorText == null &&
                              _passwordErrorText == null) {
                            // Nếu không có lỗi
                            try {
                              // Validate email and password against database
                              User? user = await _apiHandler.getUser(
                                  email, password); // Gọi API để đăng nhập
                              if (user != null) {
                                // Check if email and password match database
                                if (user.email == email &&
                                    user.password == password) {
                                  sharedPreferences = await SharedPreferences
                                      .getInstance(); // Lấy đối tượng SharedPreferences
                                  await sharedPreferences.setString(
                                      'EmployeeEmail', email); // Lưu email
                                  await sharedPreferences.setString(
                                      'EmployeePassword',
                                      password); // Save password
                                  await sharedPreferences.setString(
                                      'EmployeeName', user.name); // Lưu tên
                                  await sharedPreferences.setInt(
                                      'UserId', user.userId); // Lưu userId
                                  await sharedPreferences.setString(
                                      'EmployeePhone',
                                      user.phone
                                          .toString()); // Lưu số điện thoại
                                  await sharedPreferences.setString(
                                      'EmployeeAddress',
                                      user.address ?? ''); // Lưu address
                                  await sharedPreferences.setString(
                                      'EmployeeAvatar',
                                      user.avatar ?? ''); // Lưu avatar
                                  await sharedPreferences.setString(
                                      'EmployeeAvatarLocation',
                                      user.avatarLocation ??
                                          ''); // Save avatarLocation

                                  // Redirect to HomeScreen
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HomeScreen(
                                          currentUser:
                                              user), // Chuyển sang màn hình home
                                    ),
                                  );
                                } else {
                                  // Nếu mật khẩu không đúng
                                  setState(() {
                                    _passwordErrorText = AppLocalizations.of(
                                            context)!
                                        .loginIncorrectPassword; // Trả về thông báo lỗi mật khẩu không đúng
                                  });
                                }
                              } else {
                                setState(() {
                                  // Nếu không tìm thấy user
                                  _passwordErrorText = AppLocalizations.of(
                                          context)!
                                      .loginIncorrectPassword; // Trả về thông báo lỗi mật khẩu không đúng
                                });
                              }
                            } catch (e) {
                              // Nếu có lỗi
                              print(e.toString());
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Nhân Viên Không Tồn Tại")), // Trả về thông báo lỗi
                              );
                            }
                          }
                        },
                        child: Container(
                          height: 60,
                          width: MediaQuery.of(context).size.width,
                          margin: EdgeInsets.only(
                              top: screenHeight / 60,
                              bottom: screenHeight / 40),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(40)),
                          ),
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!
                                  .loginLogin, // Hiển thị nút đăng nhập
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width / 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Register button
                      GestureDetector(
                        onTap: () {
                          // Chuyển sang màn hình đăng ký
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegisterScreen(),
                            ),
                          );
                        },
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: AppLocalizations.of(context)!
                                    .loginDontHaveAccount, // Hiển thị "Don't have an account?"
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width / 20,
                                  color: Colors.grey,
                                ),
                              ),
                              TextSpan(
                                text: AppLocalizations.of(context)!
                                    .loginRegister, // Hiển thị "Register"
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width / 20,
                                  color: primaryColor,
                                  decoration: TextDecoration.underline,
                                  decorationColor: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ), // Phần hiển thị nút đăng ký
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to display field title
  Widget fieldTitle(String title) {
    // Hàm hiển thị tiêu đề trường
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Text(
          title,
          style: TextStyle(fontSize: MediaQuery.of(context).size.width / 20),
        ),
      ),
    );
  }

  // Helper function to create custom input field
  Widget customField(
      String hint,
      TextEditingController controller,
      bool obscure,
      String? errorText,
      IconData icon,
      Color iconColor,
      double screenWidth) {
    // Hàm xây dựng một trường nhập liệu tùy chỉnh
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {},
              child: SizedBox(
                width: MediaQuery.of(context).size.width / 7,
                child: Icon(
                  icon,
                  color: iconColor,
                  size: MediaQuery.of(context).size.width / 10,
                ),
              ),
            ), // Icon ở đầu trường nhập liệu
            Expanded(
              child: TextFormField(
                controller: controller,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: MediaQuery.of(context).size.height / 50,
                  ),
                  border: InputBorder.none,
                  hintText: hint,
                  errorText: errorText,
                ),
                maxLines: 1,
                obscureText: obscure,
              ),
            ), // Trường nhập liệu
          ],
        ),
      ),
    );
  }
}
