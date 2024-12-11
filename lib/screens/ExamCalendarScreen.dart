import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:checkin/screens/AddTaskScreen.dart';
import 'package:checkin/model/users.dart';

class ExamCalendarScreen extends StatefulWidget {
  final User currentUser;
  const ExamCalendarScreen({Key? key, required this.currentUser})
      : super(key: key);

  @override
  _ExamCalendarScreenState createState() => _ExamCalendarScreenState();
}

class _ExamCalendarScreenState extends State<ExamCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    ).then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      setState(() {
        _selectedDate = pickedDate;
        _scrollToSelectedDate();
      });
    });
  }

  void _scrollToSelectedDate() {
    double screenWidth = MediaQuery.of(context).size.width;
    double tileWidth = screenWidth / 5;

    int daysDifference = _selectedDate
        .difference(DateTime.now().subtract(Duration(days: 2)))
        .inDays;
    double scrollOffset = daysDifference * tileWidth;

    _scrollController.animateTo(scrollOffset,
        duration: Duration(milliseconds: 300), curve: Curves.ease);
  }

  @override
  Widget build(BuildContext context) {
    final primaryClr = Color(0xFF90CAF9);
    String todayDate = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(todayDate, style: TextStyle(fontSize: 18)),
              ],
            ),
            TextButton(
              style: TextButton.styleFrom(
                  backgroundColor: primaryClr,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20))),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          AddTaskScreen(currentUser: widget.currentUser)),
                );
              },
              child: Text('+ Add Task', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 140,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(vertical: 16),
              itemBuilder: (context, index) {
                DateTime date = DateTime.now()
                    .subtract(Duration(days: 2))
                    .add(Duration(days: index));
                return _buildDateTile(date, primaryClr, context);
              },
              itemCount: 365 * 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTile(DateTime date, Color primaryClr, BuildContext context) {
    bool isSelected = date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;
    double tileWidth = MediaQuery.of(context).size.width / 5;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
          _scrollToSelectedDate();
        });
      },
      child: SizedBox(
        width: tileWidth,
        height: 110,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? primaryClr : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(DateFormat('MMM').format(date).toUpperCase(),
                  style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white : Colors.grey)),
              Text(DateFormat('dd').format(date),
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black)),
              Text(DateFormat('yyyy').format(date),
                  style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
