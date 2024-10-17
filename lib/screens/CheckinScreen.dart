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
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

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
  String? _ipv4Address;
  bool _isValidWifi = false;
  final APIHandler _apiHandler = APIHandler();
  late Records? _latestRecord;

  // Define a list of valid IP addresses
  final List<String> _validIpAddresses = [
    "192.168.0.106",
    "192.168.0.103",
    "192.168.112.153",
    "192.168.1.105",
    "10.154.20.218"
  ];

  // StreamController to manage data updates
  final _recordStreamController = StreamController<Records?>.broadcast();

  // Timer for updating the time display
  Timer? _timeUpdateTimer;
  Timer? _recordUpdateTimer;
  int _currentDayCheckOutCount = 0;

  // State variable to track image upload progress
  bool _isLoadingImage = false;

  @override
  void initState() {
    super.initState();
    _getRecord(); // Fetch initial data
    _getipv4();
  }

  @override
  void dispose() {
    // Cancel the time and record update timers when the widget is disposed
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

      // Update state ONLY when _latestRecord is not null
      if (_latestRecord != null) {
        setState(() {
          checkIn = _latestRecord!.checkIn;
          checkOut = _latestRecord!.checkOut;
        });
      }

      // Update the StreamController
      _recordStreamController.add(_latestRecord);
    } catch (e) {
      // Update UI
      setState(() {
        // Call setstate
        checkIn = "--/--";
        checkOut = "--/--";
      });
      // Add null to stream controller when error
      _recordStreamController.add(_latestRecord);
    }
  }

  // Check if the IP address is in the valid list
  bool _isWifiValid(String? ipAddress) {
    if (ipAddress == null) {
      return false;
    }
    return _validIpAddresses.contains(ipAddress);
  }

  Future<void> _getImageFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 25,
    );

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);

      // Save imageFile directly
      _image = imageFile;

      setState(() {
        _image = _image;
        _isImageCaptured = true;
        _getipv4();
      });
    }
  }

  // Get IP address from network
  Future<void> _getipv4() async {
    String? ipAddress = await NetworkInfo().getWifiIP();
    setState(() {
      _ipv4Address = ipAddress;
      _isValidWifi = _isWifiValid(_ipv4Address);
    });
  }

  // Function to resize and compress image using flutter_image_compress
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

  // Function to upload the selected image and return the image location
  Future<String?> _uploadImageAndReturnLocation(
      File? imageFile, String type) async {
    if (imageFile != null) {
      // Set loading flag
      setState(() {
        _isLoadingImage = true;
      });
      try {
        // Rename image based on type (check-in or check-out)
        String filename;
        if (type == 'checkin') {
          filename =
              'checkin_${widget.currentUser.userId}_${widget.currentUser.name}_${DateTime.now().toIso8601String().replaceAll(':', '.')}.jpg';
        } else {
          filename =
              'checkout-${_currentDayCheckOutCount}_${widget.currentUser.userId}_${widget.currentUser.name}_${DateTime.now().toIso8601String().replaceAll(':', '.')}.jpg';
          _currentDayCheckOutCount++;
        }

        // Create FormData object with the image
        final FormData formData = FormData.fromMap({
          'file':
              await MultipartFile.fromFile(imageFile.path, filename: filename),
        });

        // API endpoint for check-in/check-out image
        final apiUrl = '${_apiHandler.baseUrl}/records/location';
        final response = await Dio().post(
          apiUrl,
          data: formData,
          options: Options(
            headers: {'Content-Type': 'multipart/form-data'},
          ),
        );

        // Handle the response
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
          // Handle errors during image upload
          _showErrorMessage(AppLocalizations.of(context)!.checkinUploadError);
        }
      } catch (e) {
        // Handle general errors
        _showErrorMessage(AppLocalizations.of(context)!.checkinUploadError);
      } finally {
        // Reset loading flag
        setState(() {
          _isLoadingImage = false;
        });
      }
    } else {
      // Handle the case where no image is selected
      _showErrorMessage(AppLocalizations.of(context)!.checkinSelectImage);
    }
    return null; // Return null if image upload fails
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
                      AppLocalizations.of(context)!.checkinYourIp,
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
                    Row(
                      children: [
                        Text(
                          ':  ${_ipv4Address ?? '...'}',
                          style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _isValidWifi ? Colors.green : Colors.red,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: Text(
                              _isValidWifi
                                  ? AppLocalizations.of(context)!.checkinValid
                                  : AppLocalizations.of(context)!
                                      .checkinInvalid,
                              style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      _isValidWifi ? Colors.green : Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            Container(
              alignment: Alignment.centerLeft,
              // margin: const EdgeInsets.only(top: 20),
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
                      // Update checkIn using StreamBuilder
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
                      // Update checkOut using StreamBuilder
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
            // Part for displaying the take picture button and image preview
            Row(
              children: [
                // Take picture button
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
                // Image preview
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
            // Check-in button
            if (checkIn == "--/--")
              Container(
                margin: const EdgeInsets.only(top: 15),
                child: SizedBox(
                  width: screenWidth,
                  height: screenHeight / 15,
                  child: ElevatedButton(
                    onPressed: _isImageCaptured &&
                            _isValidWifi &&
                            _image != null &&
                            !_isLoadingImage
                        ? () async {
                            // Get the image location
                            String? locationImg =
                                await _uploadImageAndReturnLocation(
                                    _image, 'checkin');

                            // Create a new record
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
                                  'checkin_${widget.currentUser.userId}_${widget.currentUser.name}_${DateTime.now().millisecondsSinceEpoch}.jpg', // Gán tên file mới cho imgName
                              ip: _ipv4Address ?? '',
                            );

                            // Send check-in request to API
                            try {
                              // Call API to insert a new record
                              final response = await _apiHandler.insertRecord(
                                  record, _image);

                              // Handle different responses based on update type:
                              if (response.statusCode == 201) {
                                print(
                                    'Check-in successful: ${response.statusCode}');
                                setState(() {
                                  checkIn = DateFormat('HH:mm').format(
                                      DateTime.now()); // Update checkIn here

                                  // Now call _getRecord to update the StreamBuilder
                                  _getRecord();
                                });
                              } else {
                                // Handle specific API errors based on response.statusCode
                                if (response.statusCode == 400) {
                                  // Display error message based on API response
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        "Invalid data: ${response.data}"), // Access data using response.data
                                  ));
                                } else {
                                  // Handle other errors
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        "Check-in Error: ${response.data}"), // Access data using response.data
                                  ));
                                }
                              }
                            } catch (e) {
                              // Handle API call errors
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        "Check-in Error: ${e.toString()}")),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isImageCaptured && _isValidWifi
                          ? primaryColor
                          : Colors.grey[400]!,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      _isImageCaptured && _isValidWifi
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
            // Check-out button
            if (checkIn != "--/--")
              Container(
                margin: const EdgeInsets.only(top: 15),
                child: SizedBox(
                  width: screenWidth,
                  height: screenHeight / 15,
                  child: ElevatedButton(
                    onPressed: _isImageCaptured &&
                            _isValidWifi &&
                            _image != null &&
                            !_isLoadingImage
                        ? () async {
                            String? locationImg =
                                await _uploadImageAndReturnLocation(
                                    _image, 'checkout');
                            // Create Records object (with location)
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
                                  'checkout-${_currentDayCheckOutCount}_${widget.currentUser.userId}_${widget.currentUser.name}_${DateTime.now().millisecondsSinceEpoch}.jpg', // Gán tên file mới cho imgName
                              ip: _ipv4Address!,
                            );

                            // Send check-out request to API
                            try {
                              // Call API to insert a new record
                              final response = await _apiHandler.insertRecord(
                                  record, _image);

                              // Handle different responses based on update type:
                              if (response.statusCode == 201) {
                                print(
                                    'Check-out successful: ${response.statusCode}');
                                setState(() {
                                  checkOut = DateFormat('HH:mm')
                                      .format(DateTime.now());
                                  // Do not reset checkIn, keep it as it is
                                  _getRecord(); // Fetch updated record
                                });
                                ;
                              } else {
                                // Handle specific API errors based on response.statusCode
                                if (response.statusCode == 400) {
                                  // Display error message based on API response
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        "Invalid data: ${response.data}"), // Access data using response.data
                                  ));
                                } else {
                                  // Handle other errors
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        "Check-out Error: ${response.data}"), // Access data using response.data
                                  ));
                                }
                              }
                            } catch (e) {
                              // Handle API call errors
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        "Check-out Error: ${e.toString()}")),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isImageCaptured && _isValidWifi
                          ? primaryColor
                          : Colors.grey[400]!,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      _isImageCaptured && _isValidWifi
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
                    // Navigate to CalendarScreen when the button is pressed
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
                    AppLocalizations.of(context)!
                        .checkinViewHistory, // Replace with your desired text
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            // Display message "You have checked in today"
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
