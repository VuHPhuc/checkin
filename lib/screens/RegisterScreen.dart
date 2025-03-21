import 'dart:convert';
import 'dart:typed_data';
import 'package:checkin/model/apiHandler.dart';
import 'package:checkin/model/users.dart';
import 'package:checkin/screens/HomeScreen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:dio/dio.dart';

class RegisterScreen extends StatefulWidget {
  // Màn hình đăng ký
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Khai báo các biến trạng thái
  final TextEditingController nameController =
      TextEditingController(); // Controller cho trường tên
  final TextEditingController emailController =
      TextEditingController(); // Controller cho trường email
  final TextEditingController passwordController =
      TextEditingController(); // Controller cho trường mật khẩu
  final TextEditingController confirmPasswordController =
      TextEditingController(); // Controller cho trường xác nhận mật khẩu
  final TextEditingController phoneController =
      TextEditingController(); // Controller cho trường số điện thoại

  String? _nameErrorText; // Biến để hiển thị lỗi cho trường tên
  String? _emailErrorText; // Biến để hiển thị lỗi cho trường email
  String? _passwordErrorText; // Biến để hiển thị lỗi cho trường mật khẩu
  String?
      _confirmPasswordErrorText; // Biến để hiển thị lỗi cho trường xác nhận mật khẩu
  String? _phoneErrorText; // Biến để hiển thị lỗi cho trường số điện thoại

  final Color primaryColor =
      const Color.fromARGB(252, 56, 242, 255); // Màu chủ đạo
  final APIHandler _apiHandler =
      APIHandler(); // Đối tượng APIHandler để tương tác với API

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
  Widget build(BuildContext context) {
    // Hàm build giao diện người dùng
    final screenHeight =
        MediaQuery.of(context).size.height; // Lấy chiều cao màn hình
    final screenWidth =
        MediaQuery.of(context).size.width; // Lấy chiều rộng màn hình

    return Scaffold(
      resizeToAvoidBottomInset:
          true, // Cho phép màn hình cuộn khi bàn phím hiện lên
      body: SingleChildScrollView(
        child: Column(
          children: [
            MediaQuery.of(context).viewInsets.bottom > 0
                ? const SizedBox(height: 50)
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
                top: screenHeight / 30,
                bottom: screenHeight / 35,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Quay lại màn hình trước
                    },
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ), // Nút quay lại
                  const SizedBox(width: 16),
                  Text(
                    AppLocalizations.of(context)!
                        .registerTitle, // Hiển thị tiêu đề
                    style: TextStyle(fontSize: screenWidth / 15),
                  ),
                ],
              ),
            ), // Phần hiển thị tiêu đề màn hình và nút quay lại
            GestureDetector(
              onTap: () async {
                // Hàm xử lý khi người dùng nhấn nút đăng ký
                FocusScope.of(context).unfocus(); // Đóng bàn phím
                final String name = nameController.text.trim(); // Lấy tên
                final String email = emailController.text.trim(); // Lấy email
                final String password =
                    passwordController.text.trim(); // Lấy mật khẩu
                final String confirmPassword = confirmPasswordController.text
                    .trim(); // Lấy mật khẩu xác nhận
                final String phone =
                    phoneController.text.trim(); // Lấy số điện thoại

                if (name.isEmpty) {
                  setState(() {
                    _nameErrorText = AppLocalizations.of(context)!
                        .registerNameEmpty; // Nếu tên rỗng trả về thông báo lỗi
                  });
                } else {
                  _nameErrorText = null; // Nếu có dữ liệu thì không có lỗi
                }
                if (email.isEmpty) {
                  setState(() {
                    _emailErrorText = AppLocalizations.of(context)!
                        .registerEmailEmpty; // Nếu email rỗng trả về thông báo lỗi
                  });
                } else {
                  _emailErrorText =
                      validateEmail(email); // Kiểm tra định dạng email
                }
                if (password.isEmpty) {
                  setState(() {
                    _passwordErrorText = AppLocalizations.of(context)!
                        .registerPasswordEmpty; // Nếu mật khẩu rỗng trả về thông báo lỗi
                  });
                } else {
                  _passwordErrorText = null; // Nếu có dữ liệu thì không có lỗi
                }
                if (confirmPassword.isEmpty) {
                  setState(() {
                    _confirmPasswordErrorText = AppLocalizations.of(context)!
                        .registerConfirmPasswordEmpty; // Nếu mật khẩu xác nhận rỗng trả về thông báo lỗi
                  });
                } else {
                  _confirmPasswordErrorText =
                      null; // Nếu có dữ liệu thì không có lỗi
                }
                if (password != confirmPassword) {
                  setState(() {
                    _confirmPasswordErrorText = AppLocalizations.of(context)!
                        .registerPasswordMismatch; // Nếu mật khẩu không trùng nhau trả về thông báo lỗi
                  });
                }
                if (phone.isEmpty) {
                  setState(() {
                    _phoneErrorText = AppLocalizations.of(context)!
                        .registerPhoneEmpty; // Nếu số điện thoại rỗng trả về thông báo lỗi
                  });
                } else {
                  _phoneErrorText = null; // Nếu có dữ liệu thì không có lỗi
                }

                if (_nameErrorText == null &&
                    _emailErrorText == null &&
                    _passwordErrorText == null &&
                    _confirmPasswordErrorText == null &&
                    _phoneErrorText == null) {
                  // Nếu không có lỗi
                  try {
                    User newUser = User(
                      userId: 0,
                      name: name,
                      email: email,
                      password: password,
                      phone: int.parse(phone),
                      address: "",
                      avatar: "",
                      avatarLocation: "",
                      isAdmin: 0,
                    ); // Tạo mới đối tượng user

                    // Register user with the updated avatarLocation
                    bool success = await _apiHandler
                        .registerUser(newUser); // Gọi API để đăng ký
                    if (success) {
                      // Nếu đăng ký thành công
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!
                              .registerSuccess), // Hiển thị thông báo thành công
                          backgroundColor: Colors.green,
                        ),
                      );

                      // Save login information
                      SharedPreferences prefs = await SharedPreferences
                          .getInstance(); // Lưu thông tin đăng nhập vào SharedPreferences
                      await prefs.setString('EmployeeEmail', email);
                      await prefs.setString('EmployeePassword', password);
                      await prefs.setInt('UserId', newUser.userId);
                      await prefs.setString('EmployeeName', name);
                      await prefs.setString(
                          'EmployeeAvatar', newUser.avatar ?? '');
                      await prefs.setString('EmployeeAvatarLocation',
                          newUser.avatarLocation ?? '');

                      // Redirect to HomeScreen
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeScreen(
                            currentUser: newUser, // Chuyển sang màn hình home
                          ),
                        ),
                      );
                    } else {
                      // Nếu đăng ký thất bại
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!
                                .registerFailed, // Hiển thị thông báo thất bại
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    // Nếu có lỗi
                    print(e.toString());
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!
                              .registerError, // Hiển thị thông báo lỗi
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Container(
                alignment: Alignment.centerLeft,
                margin: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width / 10),
                child: Column(
                  children: [
                    customField(
                        AppLocalizations.of(context)!
                            .registerEnterName, // Hiển thị trường nhập tên
                        nameController,
                        false,
                        _nameErrorText,
                        FontAwesomeIcons.user),
                    customField(
                        AppLocalizations.of(context)!
                            .registerEnterEmail, // Hiển thị trường nhập email
                        emailController,
                        false,
                        _emailErrorText,
                        FontAwesomeIcons.envelope),
                    customField(
                        AppLocalizations.of(context)!
                            .registerEnterPassword, // Hiển thị trường nhập mật khẩu
                        passwordController,
                        true,
                        _passwordErrorText,
                        FontAwesomeIcons.key),
                    customField(
                        AppLocalizations.of(context)!
                            .registerConfirmPassword, // Hiển thị trường xác nhận mật khẩu
                        confirmPasswordController,
                        true,
                        _confirmPasswordErrorText,
                        FontAwesomeIcons.key),
                    customField(
                        AppLocalizations.of(context)!
                            .registerEnterPhone, // Hiển thị trường nhập số điện thoại
                        phoneController,
                        false,
                        _phoneErrorText,
                        FontAwesomeIcons.phone),
                    Container(
                      height: 60,
                      width: MediaQuery.of(context).size.width,
                      margin: EdgeInsets.only(top: screenHeight / 40),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(40)),
                      ),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!
                              .registerRegister, // Hiển thị nút đăng ký
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width / 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ), // Phần hiển thị các trường nhập liệu và nút đăng ký
          ],
        ),
      ),
    );
  }

  Widget customField(String hint, TextEditingController controller,
      bool obscure, String? errorText, IconData iconData) {
    // Hàm xây dựng một trường nhập liệu tùy chỉnh
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.only(bottom: 12),
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
                  iconData,
                  color: primaryColor,
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
                keyboardType: TextInputType.multiline,
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
