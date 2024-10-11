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
  final User currentUser;

  const CalendarScreen({super.key, required this.currentUser});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  double screenHeight = 0;
  double screenWidth = 0;

  final Color primaryColor = const Color.fromARGB(253, 239, 68, 76);

  final APIHandler _apiHandler = APIHandler();

  DateTime _selectedDate = DateTime.now();
  Map<DateTime, List<Records>> _groupedRecords = {};

  final _recordsStreamController = StreamController<List<Records>>.broadcast();

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchRecords().then((records) {
      setState(() {
        _recordsStreamController.add(records);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recordsStreamController.close();
    super.dispose();
  }

  Future<List<Records>> _fetchRecords() async {
    try {
      final records = await _apiHandler.getUserRecords(
          widget.currentUser.userId,
          DateTime(_selectedDate.year, _selectedDate.month, 1));
      final filteredRecords = records
          .where((record) =>
              record.date.year == _selectedDate.year &&
              record.date.month == _selectedDate.month)
          .toList();

      return filteredRecords;
    } catch (e) {
      print('Error fetching records: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTitle(),
            _buildMonthYearSelector(),
            const SizedBox(height: 20),
            StreamBuilder<List<Records>>(
              stream: Stream.periodic(const Duration(seconds: 1), (count) {
                return _fetchRecords();
              }).asyncMap((_) async => await _),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final records = snapshot.data!;
                  _groupedRecords = groupRecordsByDay(records);
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _groupedRecords.keys.length,
                    itemBuilder: (context, index) {
                      final date = _groupedRecords.keys.elementAt(index);
                      final dayRecords = _groupedRecords[date]!;
                      return _buildDayRecord(date, dayRecords);
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(
                      child: Text(
                          "${AppLocalizations.of(context)!.calendarError}${snapshot.error}"));
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(top: 20),
      child: Text(
        AppLocalizations.of(context)!.calendarYourAttendanceRecord,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMonthYearSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          alignment: Alignment.centerLeft,
          margin: const EdgeInsets.only(top: 25),
          child: Text(
            DateFormat('MM / yyyy').format(_selectedDate),
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
              showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              ).then((pickedDate) {
                if (pickedDate != null) {
                  setState(() {
                    _selectedDate = pickedDate;
                    _fetchRecords().then((records) {
                      setState(() {
                        _recordsStreamController.add(records);
                      });
                    });
                  });
                }
              });
            },
            child: Text(
              AppLocalizations.of(context)!.calendarChangeMonthYear,
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
    return StreamBuilder<List<Records>>(
      stream: _recordsStreamController.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final records = snapshot.data!;
          _groupedRecords = groupRecordsByDay(records);
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _groupedRecords.keys.length,
            itemBuilder: (context, index) {
              final date = _groupedRecords.keys.elementAt(index);
              final dayRecords = _groupedRecords[date]!;
              return _buildDayRecord(date, dayRecords);
            },
          );
        } else if (snapshot.hasError) {
          return Center(
              child: Text(
                  "${AppLocalizations.of(context)!.calendarError}${snapshot.error}"));
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Map<DateTime, List<Records>> groupRecordsByDay(List<Records> records) {
    Map<DateTime, List<Records>> groupedRecords = {};
    for (var record in records) {
      if (record.date.year == _selectedDate.year &&
          record.date.month == _selectedDate.month) {
        final date =
            DateTime(record.date.year, record.date.month, record.date.day);
        groupedRecords.update(
          date,
          (existingRecords) => existingRecords..add(record),
          ifAbsent: () => [record],
        );
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

    return sortedGroupedRecords;
  }

  Widget _buildDayRecord(DateTime date, List<Records> dayRecords) {
    return InkWell(
      onTap: () {
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
                    .format(date),
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
                          '${AppLocalizations.of(context)!.calendarCheckin}: ${dayRecords.last.checkIn}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(253, 239, 68, 76),
                          ),
                        ),
                      ),
                    for (var record in dayRecords
                        .where((record) => record.location != null)
                        .toList())
                      Column(
                        children: [
                          if (record.checkOut.isNotEmpty &&
                              record.checkOut.trim() != ' ' &&
                              record.checkOut != "--/--")
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                '${AppLocalizations.of(context)!.calendarCheckout}: ${record.checkOut}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          FutureBuilder(
                            future: _fetchImageFromLocation(record.location),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                final imageData = snapshot.data as Uint8List?;
                                if (imageData != null) {
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
                                  return const SizedBox.shrink();
                                }
                              } else if (snapshot.hasError) {
                                return Text(
                                    '${AppLocalizations.of(context)!.calendarError}${snapshot.error}');
                              } else {
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
                onPressed: () => Navigator.pop(context),
                child: Text(
                  AppLocalizations.of(context)!.calendarClose,
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
                    DateFormat('dd/MM/yyyy').format(date),
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
                  AppLocalizations.of(context)!.calendarCheckin,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  dayRecords.first.checkIn,
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.calendarCheckout,
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: screenWidth / 20,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  dayRecords.last.checkOut,
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
    if (location == null) return null;
    try {
      final baseUrl = _apiHandler.baseUrl.replaceFirst('/api', '');
      final completeImageUrl = '$baseUrl$location';

      final response = await http.get(Uri.parse(completeImageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print('Error fetching image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching image: $e');
      return null;
    }
  }
}
