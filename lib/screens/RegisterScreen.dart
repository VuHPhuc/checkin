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
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String? _nameErrorText;
  String? _emailErrorText;
  String? _passwordErrorText;
  String? _confirmPasswordErrorText;
  String? _phoneErrorText;

  final Color primaryColor = const Color.fromARGB(252, 56, 242, 255);
  final APIHandler _apiHandler = APIHandler();

  String? validateEmail(String? value) {
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
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                  ),
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
                      Navigator.pop(context);
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
                  ),
                  const SizedBox(width: 16),

                  Text(
                    AppLocalizations.of(context)!.registerTitle,
                    style: TextStyle(fontSize: screenWidth / 15),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                FocusScope.of(context).unfocus();
                final String name = nameController.text.trim();
                final String email = emailController.text.trim();
                final String password = passwordController.text.trim();
                final String confirmPassword =
                    confirmPasswordController.text.trim();
                final String phone = phoneController.text.trim();

                if (name.isEmpty) {
                  setState(() {
                    _nameErrorText =
                        AppLocalizations.of(context)!.registerNameEmpty;
                  });
                } else {
                  _nameErrorText = null;
                }
                if (email.isEmpty) {
                  setState(() {
                    _emailErrorText =
                        AppLocalizations.of(context)!.registerEmailEmpty;
                  });
                } else {
                  _emailErrorText = validateEmail(email);
                }
                if (password.isEmpty) {
                  setState(() {
                    _passwordErrorText =
                        AppLocalizations.of(context)!.registerPasswordEmpty;
                  });
                } else {
                  _passwordErrorText = null;
                }
                if (confirmPassword.isEmpty) {
                  setState(() {
                    _confirmPasswordErrorText = AppLocalizations.of(context)!
                        .registerConfirmPasswordEmpty;
                  });
                } else {
                  _confirmPasswordErrorText = null;
                }
                if (password != confirmPassword) {
                  setState(() {
                    _confirmPasswordErrorText =
                        AppLocalizations.of(context)!.registerPasswordMismatch;
                  });
                }
                if (phone.isEmpty) {
                  setState(() {
                    _phoneErrorText =
                        AppLocalizations.of(context)!.registerPhoneEmpty;
                  });
                } else {
                  _phoneErrorText = null;
                }

                if (_nameErrorText == null &&
                    _emailErrorText == null &&
                    _passwordErrorText == null &&
                    _confirmPasswordErrorText == null &&
                    _phoneErrorText == null) {
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
                    );

                    // Register user with the updated avatarLocation
                    bool success = await _apiHandler.registerUser(newUser);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              AppLocalizations.of(context)!.registerSuccess),
                          backgroundColor: Colors.green,
                        ),
                      );

                      // Save login information
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
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
                            currentUser:
                                newUser, // Pass the User object to HomeScreen
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.registerFailed,
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    print(e.toString());
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.registerError,
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
                        AppLocalizations.of(context)!.registerEnterName,
                        nameController,
                        false,
                        _nameErrorText,
                        FontAwesomeIcons.user),
                    customField(
                        AppLocalizations.of(context)!.registerEnterEmail,
                        emailController,
                        false,
                        _emailErrorText,
                        FontAwesomeIcons.envelope),
                    customField(
                        AppLocalizations.of(context)!.registerEnterPassword,
                        passwordController,
                        true,
                        _passwordErrorText,
                        FontAwesomeIcons.key),
                    customField(
                        AppLocalizations.of(context)!.registerConfirmPassword,
                        confirmPasswordController,
                        true,
                        _confirmPasswordErrorText,
                        FontAwesomeIcons.key),
                    customField(
                        AppLocalizations.of(context)!.registerEnterPhone,
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
                          AppLocalizations.of(context)!.registerRegister,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget customField(String hint, TextEditingController controller,
      bool obscure, String? errorText, IconData iconData) {
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
            ),
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
            ),
          ],
        ),
      ),
    );
  }
}
