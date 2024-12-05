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
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  String? _emailErrorText;
  String? _passwordErrorText;

  final Color primaryColor = const Color.fromARGB(251, 96, 244, 255);

  late SharedPreferences sharedPreferences;
  final APIHandler _apiHandler = APIHandler();

  // Check if the user has logged in
  bool _isLoggedIn = false;

  // Validate email format
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
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Check if the user has logged in
  Future<void> _checkLoginStatus() async {
    sharedPreferences = await SharedPreferences.getInstance();
    String? email = sharedPreferences.getString('EmployeeEmail');
    String? password = sharedPreferences.getString('EmployeePassword');
    int? userId = sharedPreferences.getInt('UserId');
    String? name = sharedPreferences.getString('EmployeeName');
    String? avatar = sharedPreferences.getString('EmployeeAvatar');
    String? avatarLocation =
        sharedPreferences.getString('EmployeeAvatarLocation');

    if (email != null && password != null && userId != null) {
      // If the user has logged in, redirect to HomeScreen
      _isLoggedIn = true;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // If the user has logged in, redirect to HomeScreen
    if (_isLoggedIn) {
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
      ));
    }

    return Scaffold(
      resizeToAvoidBottomInset:
          false, // Disable automatic resizing to avoid bottom inset
      body: GestureDetector(
        onTap: () {
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
                    ),
              Container(
                margin: EdgeInsets.only(
                  top: screenHeight / 40,
                ),
                child: Text(
                  AppLocalizations.of(context)!.loginWelcomeBack,
                  style: TextStyle(
                      fontSize: screenWidth / 14, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                margin: EdgeInsets.only(
                  bottom: screenHeight / 40,
                ),
                child: Text(
                  AppLocalizations.of(context)!.loginLoginToAccount,
                  style: TextStyle(
                    fontSize: screenWidth / 20,
                    color: Colors.black45,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(
                  top: screenHeight / 40,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth / 10),
                  child: Column(
                    children: [
                      customField(
                          AppLocalizations.of(context)!.loginEnterEmail,
                          emailController,
                          false,
                          _emailErrorText,
                          FontAwesomeIcons.envelope,
                          primaryColor,
                          screenWidth),
                      customField(
                          AppLocalizations.of(context)!.loginEnterPassword,
                          passController,
                          true,
                          _passwordErrorText,
                          FontAwesomeIcons.key,
                          primaryColor,
                          screenWidth),
                      // Login button
                      GestureDetector(
                        onTap: () async {
                          FocusScope.of(context).unfocus();
                          final String email = emailController.text.trim();
                          final String password = passController.text.trim();

                          if (email.isEmpty) {
                            setState(() {
                              _emailErrorText =
                                  AppLocalizations.of(context)!.loginEmailEmpty;
                            });
                          } else {
                            _emailErrorText = validateEmail(email);
                          }

                          if (password.isEmpty) {
                            setState(() {
                              _passwordErrorText = AppLocalizations.of(context)!
                                  .loginPasswordEmpty;
                            });
                          } else {
                            _passwordErrorText = null;
                          }

                          if (_emailErrorText == null &&
                              _passwordErrorText == null) {
                            try {
                              // Validate email and password against database
                              User? user =
                                  await _apiHandler.getUser(email, password);
                              if (user != null) {
                                // Check if email and password match database
                                if (user.email == email &&
                                    user.password == password) {
                                  sharedPreferences =
                                      await SharedPreferences.getInstance();
                                  await sharedPreferences.setString(
                                      'EmployeeEmail', email);
                                  await sharedPreferences.setString(
                                      'EmployeePassword',
                                      password); // Save password
                                  await sharedPreferences.setString(
                                      'EmployeeName', user.name);
                                  await sharedPreferences.setInt(
                                      'UserId', user.userId);
                                  await sharedPreferences.setString(
                                      'EmployeePhone', user.phone.toString());
                                  await sharedPreferences.setString(
                                      'EmployeeAddress',
                                      user.address ?? ''); // Lưu address
                                  await sharedPreferences.setString(
                                      'EmployeeAvatar', user.avatar ?? '');
                                  await sharedPreferences.setString(
                                      'EmployeeAvatarLocation',
                                      user.avatarLocation ??
                                          ''); // Save avatarLocation

                                  // Redirect to HomeScreen
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          HomeScreen(currentUser: user),
                                    ),
                                  );
                                } else {
                                  setState(() {
                                    _passwordErrorText =
                                        AppLocalizations.of(context)!
                                            .loginIncorrectPassword;
                                  });
                                }
                              } else {
                                setState(() {
                                  _passwordErrorText =
                                      AppLocalizations.of(context)!
                                          .loginIncorrectPassword;
                                });
                              }
                            } catch (e) {
                              print(e.toString());
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Nhân Viên Không Tồn Tại")),
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
                              AppLocalizations.of(context)!.loginLogin,
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
                                    .loginDontHaveAccount,
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width / 20,
                                  color: Colors.grey,
                                ),
                              ),
                              TextSpan(
                                text:
                                    AppLocalizations.of(context)!.loginRegister,
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
                      ),
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
