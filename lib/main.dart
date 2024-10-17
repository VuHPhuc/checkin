import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:checkin/model/apiHandler.dart';
import 'package:checkin/model/users.dart';
import 'package:checkin/screens/GuestNewsScreen.dart';
import 'package:checkin/screens/NewsScreen.dart';
import 'package:checkin/screens/HomeScreen.dart';
import 'package:checkin/screens/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  runApp(MyApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void didChangeDependencies() {
    getLocale().then((locale) => setLocale(locale));
    super.didChangeDependencies();
  }

  // Function to get the preferred language from SharedPreferences
  Future<Locale> getLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? languageCode = prefs.getString('languageCode');
    if (languageCode != null) {
      return Locale(languageCode);
    } else {
      // Default language is English
      return const Locale('en');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HAU Reminder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _locale,
      home: const KeyboardVisibilityProvider(
        child: AuthCheck(), // Use AuthCheck as the initial home
      ),
    );
  }
}

// This class is used to manage authentication state
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  late SharedPreferences sharedPreferences;
  User? _currentUser;

  // Use a ValueNotifier to manage the auth state
  final _authState = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Check the login status only once in initState
  }

  // Check the login status
  void _checkLoginStatus() async {
    sharedPreferences = await SharedPreferences.getInstance();

    // Fetch user data from SharedPreferences
    String? email = sharedPreferences.getString('EmployeeEmail');
    String? name = sharedPreferences.getString('EmployeeName');
    int? userId = sharedPreferences.getInt('UserId');
    String? phone = sharedPreferences.getString('EmployeePhone');
    String? address = sharedPreferences.getString('EmployeeAddress');
    String? avatar = sharedPreferences.getString('EmployeeAvatar');
    String? avatarLocation =
        sharedPreferences.getString('EmployeeAvatarLocation');

    if (email != null && name != null && userId != null) {
      _currentUser = User(
        userId: userId,
        name: name,
        email: email,
        password: '',
        phone: int.tryParse(phone!) ?? 0,
        address: address ?? '',
        avatar: avatar ?? '',
        avatarLocation: avatarLocation ?? '',
      );
      // Update the auth state with the ValueNotifier
      _authState.value = true; // User is logged in
    } else {
      // Update the auth state with the ValueNotifier
      _authState.value = false; // User is not logged in
    }
  }

  @override
  void dispose() {
    _authState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _authState,
      builder: (context, isLoggedIn, child) {
        return isLoggedIn
            ? HomeScreen(currentUser: _currentUser!)
            : GuestNewsScreen();
      },
    );
  }
}
