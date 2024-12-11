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
  final User currentUser;

  const CheckinScreen({required this.currentUser, super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  double screenHeight = 0;
  double screenWidth = 0;
  String checkIn = "--/--";
  String checkOut = "--/--";
  final Color primaryColor = const Color.fromARGB(253, 239, 68, 76);
  final GlobalKey key = GlobalKey();
  File? _image;
  bool _isImageCaptured = false;
  final APIHandler _apiHandler = APIHandler();
  late Records? _latestRecord;

  final _recordStreamController = StreamController<Records?>.broadcast();

  Timer? _timeUpdateTimer;
  Timer? _recordUpdateTimer;
  int _currentDayCheckOutCount = 0;

  bool _isLoadingImage = false;

  @override
  void initState() {
    super.initState();
    _getRecord();
  }

  @override
  void dispose() {
    _timeUpdateTimer?.cancel();
    _recordUpdateTimer?.cancel();
    _recordStreamController.close();
    super.dispose();
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future _getRecord() async {
    try {
      DateTime currentDate = DateTime.now();
      _latestRecord = await _apiHandler.getLatestRecord(
          widget.currentUser.userId, currentDate);

      if (_latestRecord != null) {
        setState(() {
          checkIn = _latestRecord!.checkIn;
          checkOut = _latestRecord!.checkOut;
        });
      }

      _recordStreamController.add(_latestRecord);
    } catch (e) {
      setState(() {
        checkIn = "--/--";
        checkOut = "--/--";
      });
      _recordStreamController.add(_latestRecord);
    }
  }

  Future<void> _getImageFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 25,
    );

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);

      _image = imageFile;

      setState(() {
        _image = _image;
        _isImageCaptured = true;
      });
    }
  }

  Future<Uint8List?> resizeAndCompressImage(
      File imageFile, int maxWidth, int maxHeight) async {
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
    if (imageFile != null) {
      setState(() {
        _isLoadingImage = true;
      });
      try {
        String filename;
        if (type == 'checkin') {
          filename =
              'checkin_${widget.currentUser.userId}_${widget.currentUser.name}_${DateTime.now().toIso8601String().replaceAll(':', '.')}.jpg';
        } else {
          filename =
              'checkout-${_currentDayCheckOutCount}_${widget.currentUser.userId}_${widget.currentUser.name}_${DateTime.now().toIso8601String().replaceAll(':', '.')}.jpg';
          _currentDayCheckOutCount++;
        }

        final FormData formData = FormData.fromMap({
          'file':
              await MultipartFile.fromFile(imageFile.path, filename: filename),
        });

        final apiUrl = '${_apiHandler.baseUrl}/records/location';
        final response = await Dio().post(
          apiUrl,
          data: formData,
          options: Options(
            headers: {'Content-Type': 'multipart/form-data'},
          ),
        );

        if (response.statusCode == 200) {
          _showSuccessMessage(
              AppLocalizations.of(context)!.checkinImageUploadSuccess);
          setState(() {
            _image = null;
            _isImageCaptured = false;
          });
          await _getRecord();
          return response.data['location'];
        } else {
          _showErrorMessage(AppLocalizations.of(context)!.checkinUploadError);
        }
      } catch (e) {
        _showErrorMessage(AppLocalizations.of(context)!.checkinUploadError);
      } finally {
        setState(() {
          _isLoadingImage = false;
        });
      }
    } else {
      _showErrorMessage(AppLocalizations.of(context)!.checkinSelectImage);
    }
    return null;
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
            Container(
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.only(top: 15),
              child: Text(
                AppLocalizations.of(context)!.checkinHello,
                style: const TextStyle(color: Colors.black45, fontSize: 25),
              ),
            ),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.checkinMrMrs,
                      style: TextStyle(
                          color: primaryColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      AppLocalizations.of(context)!.checkinEmail,
                      style: TextStyle(
                          color: primaryColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      AppLocalizations.of(context)!.checkinYourLocation,
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
                      ':  ${widget.currentUser.name}',
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      ':  ${widget.currentUser.email}',
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      ':  ...', // Displaying "..." as placeholder
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
                AppLocalizations.of(context)!.checkinTodayInformation,
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
                stream: Stream.periodic(const Duration(seconds: 1)),
                builder: (context, Snapshot) {
                  return Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      DateFormat("HH:mm:ss").format(DateTime.now()),
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
                        AppLocalizations.of(context)!.checkinCheckin,
                        style: const TextStyle(
                            fontSize: 20, color: Colors.black54),
                      ),
                      StreamBuilder<Records?>(
                        stream: _recordStreamController.stream,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              snapshot.data?.checkIn ?? checkIn,
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
                        AppLocalizations.of(context)!.checkinCheckout,
                        style: const TextStyle(
                            fontSize: 20, color: Colors.black54),
                      ),
                      StreamBuilder<Records?>(
                        stream: _recordStreamController.stream,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              snapshot.data?.checkOut ?? checkOut,
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
                  onPressed: _getImageFromCamera,
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
                            String? locationImg =
                                await _uploadImageAndReturnLocation(
                                    _image, 'checkin');

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
                              location: locationImg ?? '',
                              remark: 'None',
                              imgName:
                                  'checkin_${widget.currentUser.userId}_${widget.currentUser.name}_${DateTime.now().millisecondsSinceEpoch}.jpg',
                              ip: 'none', // ip set as empty string
                            );

                            try {
                              final response = await _apiHandler.insertRecord(
                                  record, _image);

                              if (response.statusCode == 201) {
                                print(
                                    'Check-in successful: ${response.statusCode}');
                                setState(() {
                                  checkIn = DateFormat('HH:mm')
                                      .format(DateTime.now());

                                  _getRecord();
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
                          ? AppLocalizations.of(context)!.checkinPressToCheckIn
                          : AppLocalizations.of(context)!
                              .checkinTakePictureAndCheckWifi,
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
                            String? locationImg =
                                await _uploadImageAndReturnLocation(
                                    _image, 'checkout');

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
                              location: locationImg ?? '',
                              remark: 'None',
                              imgName:
                                  'checkout-${_currentDayCheckOutCount}_${widget.currentUser.userId}_${widget.currentUser.name}_${DateTime.now().millisecondsSinceEpoch}.jpg',
                              ip: 'none', // ip set as empty string
                            );
                            try {
                              final response = await _apiHandler.insertRecord(
                                  record, _image);

                              if (response.statusCode == 201) {
                                print(
                                    'Check-out successful: ${response.statusCode}');
                                setState(() {
                                  checkOut = DateFormat('HH:mm')
                                      .format(DateTime.now());

                                  _getRecord();
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
                          ? AppLocalizations.of(context)!.checkinPressToCheckOut
                          : AppLocalizations.of(context)!
                              .checkinTakePictureAndCheckWifi,
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
                    AppLocalizations.of(context)!.checkinViewHistory,
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
                child: Text(AppLocalizations.of(context)!.checkinCheckedInToday,
                    style: TextStyle(
                        fontSize: screenWidth / 20, color: Colors.black54)),
              )
          ],
        ),
      ),
    );
  }
}
