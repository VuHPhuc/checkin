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
  final User currentUser;

  const HomeScreen({required this.currentUser, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double screenHeight = 0;
  double screenWidth = 0;

  final Color primaryColor = const Color.fromARGB(253, 239, 68, 76);

  int currentIndex = 0;

  final List<IconData> navigationIcons = [
    FontAwesomeIcons.newspaper,
    FontAwesomeIcons.calendarCheck,
    FontAwesomeIcons.check,
    FontAwesomeIcons.user,
  ];

  late SharedPreferences sharedPreferences;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: [
          const NewsScreen(),
          ExamCalendarScreen(),
          CheckinScreen(currentUser: widget.currentUser),
          UsersScreen(currentUser: widget.currentUser),
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
                      setState(() {
                        currentIndex = i;
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
                              navigationIcons[i],
                              color: i == currentIndex
                                  ? primaryColor
                                  : Colors.black54,
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
                              ),
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
