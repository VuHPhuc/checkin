import 'dart:convert';
import 'dart:typed_data';
import 'package:checkin/main.dart';
import 'package:checkin/model/apiHandler.dart';
import 'package:checkin/model/users.dart';
import 'package:checkin/screens/GuestNewsScreen.dart';
import 'package:checkin/screens/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key, required this.currentUser});

  final User currentUser;

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  double screenHeight = 0;
  double screenWidth = 0;

  final Color primaryColor = const Color.fromARGB(253, 239, 68, 76);

  late SharedPreferences sharedPreferences;

  // Variable to store User information
  late User _currentUser;

  bool _isLoading = true; // Variable to check loading status

  // Controllers for input fields
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _passwordConfirmationController =
      TextEditingController();

  // Variables to store errors for input fields
  String? _phoneErrorText;
  String? _addressErrorText;
  String? _oldPasswordErrorText;
  String? _newPasswordErrorText;
  String? _confirmPasswordErrorText;
  String? _passwordConfirmationErrorText;

  // Initialize APIHandler
  final APIHandler _apiHandler = APIHandler();

  // Variable to store selected language
  String _selectedLanguage = 'en';

  // State variables for image handling
  File? _selectedImage;
  bool _isLoadingImage = false;
  final ImagePicker _picker = ImagePicker();

  // Function to change the language
  void _changeLanguage(String? language) {
    if (language != null) {
      setState(() {
        _selectedLanguage = language; // Update selected language
      });
      // Save the language to SharedPreferences
      _saveLanguageToPrefs(language);
      // Update the locale
      Locale newLocale = Locale(language);
      MyApp.setLocale(context, newLocale);
    }
  }

  // Function to save language to SharedPreferences
  Future<void> _saveLanguageToPrefs(String language) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', language);
  }

  @override
  void initState() {
    super.initState();
    // Gán giá trị cho _currentUser
    _currentUser = widget.currentUser;
    // Call the _loadUserData function to get the user data from SharedPreferences
    _loadUserData();
  }

  // Load user data from SharedPreferences and update UI
  Future<User> _loadUserData() async {
    sharedPreferences = await SharedPreferences.getInstance();
    String? email = sharedPreferences.getString('EmployeeEmail');
    String? name = sharedPreferences.getString('EmployeeName');
    String? password = sharedPreferences.getString('EmployeePassword');
    int? userId = sharedPreferences.getInt('UserId');
    String? phone = sharedPreferences.getString('EmployeePhone');
    String? address = sharedPreferences.getString('EmployeeAddress');
    String? avatar = sharedPreferences.getString('EmployeeAvatar');
    String? avatarLocation =
        sharedPreferences.getString('EmployeeAvatarLocation');

    if (email != null &&
        name != null &&
        userId != null &&
        password != null &&
        phone != null &&
        mounted) {
      _currentUser = User(
        userId: userId,
        name: name,
        email: email,
        password: password,
        phone: int.tryParse(phone) ?? 0,
        address: address ?? ' ',
        avatar: avatar,
        avatarLocation: avatarLocation ?? '',
      );
      _phoneController.text = _currentUser.phone.toString();
      _addressController.text = _currentUser.address ?? '';

      // Update UI with new language
      setState(() {
        _isLoading = false;
        // Update _selectedLanguage after loading data
        _selectedLanguage = sharedPreferences.getString('languageCode') ?? 'en';
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
    // Return the updated user data
    return _currentUser;
  }

  // Handle logout
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('UserId');
    await prefs.remove('EmployeeEmail');
    await prefs.remove('EmployeeName');
    await prefs.remove('EmployeePhone');
    await prefs.remove('EmployeeAddress');
    await prefs.remove('EmployeePassword');
    await prefs.remove('EmployeeAvatar');
    await prefs.remove('EmployeeAvatarLocation');
    // Hide key board before logout
    FocusScope.of(context).unfocus();
    Navigator.pushAndRemoveUntil(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (context) => const GuestNewsScreen()),
      (route) => true,
    );
  }

  // Handle saving profile changes
  Future<void> _saveProfileChanges() async {
    // Validate new phone number and address
    String? newPhone = _phoneController.text.trim();
    String? newAddress = _addressController.text.trim();

    // Validate phone number
    if (newPhone.isEmpty) {
      _showErrorMessage(AppLocalizations.of(context)!.editProfileErrorPhone);
      return;
    } else if (!RegExp(r'^[0-9]+$').hasMatch(newPhone)) {
      _showErrorMessage(
          AppLocalizations.of(context)!.editProfileErrorPhoneInvalid);
      return;
    }

    // Validate address
    if (newAddress.isEmpty) {
      _showErrorMessage(AppLocalizations.of(context)!.editProfileErrorAddress);
      return;
    }

    // Update user information in SharedPreferences
    await sharedPreferences.setString('EmployeePhone', newPhone);
    await sharedPreferences.setString('EmployeeAddress', newAddress);

    // Update user information in the _currentUser object
    _currentUser = _currentUser.copyWith(
      phone: int.tryParse(newPhone)!,
      address: newAddress,
    );

    // Sử dụng Future.wait để chờ đợi cả 2 hàm cập nhật
    final updateResults = await Future.wait([
      _apiHandler.updateUserAddress(_currentUser.userId, newAddress),
      _apiHandler.updateUserPhone(_currentUser.userId, int.tryParse(newPhone)!),
    ]);

    if (updateResults.every((result) => result)) {
      _showSuccessMessage(
          AppLocalizations.of(context)!.editProfileSuccessUpdate);
      Navigator.of(context).pop();
      // Fetch latest user data and update _currentUser
      await _loadUserData(); // Call _loadUserData when update success
    } else {
      _showErrorMessage(AppLocalizations.of(context)!.editProfileErrorUpdate);
    }
  }

  // Handle saving password changes
  Future<void> _savePasswordChanges() async {
    // Validate new password values
    String? oldPassword = _oldPasswordController.text.trim();
    String? newPassword = _newPasswordController.text.trim();
    String? confirmPassword = _confirmPasswordController.text.trim();

    // Validate old password
    if (oldPassword.isEmpty) {
      _showErrorMessage(
          AppLocalizations.of(context)!.changePasswordErrorOldPassword);
      return;
    } else if (oldPassword != _currentUser.password) {
      // Validate against current password
      _showErrorMessage(AppLocalizations.of(context)!
          .changePasswordErrorOldPasswordIncorrect);
      return;
    }

    // Validate new password
    if (newPassword.isEmpty) {
      _showErrorMessage(
          AppLocalizations.of(context)!.changePasswordErrorNewPassword);
      return;
    } else if (newPassword.length < 6) {
      _showErrorMessage(
          AppLocalizations.of(context)!.changePasswordErrorNewPasswordLength);
      return;
    }

    // Validate confirm password
    if (confirmPassword.isEmpty) {
      _showErrorMessage(
          AppLocalizations.of(context)!.changePasswordErrorConfirmPassword);
      return;
    } else if (confirmPassword != newPassword) {
      _showErrorMessage(AppLocalizations.of(context)!
          .changePasswordErrorConfirmPasswordMatch);
      return;
    }

    bool success =
        await _apiHandler.updateUserPassword(_currentUser.userId, newPassword);

    if (success) {
      // Show success message and close the dialog
      _showSuccessMessage(
          // ignore: use_build_context_synchronously
          AppLocalizations.of(context)!.changePasswordSuccessUpdate);
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop(); // Close the dialog

      // Fetch latest user data and update _currentUser
      await _loadUserData(); // Call _loadUserData when update success
    } else {
      // Show error message
      _showErrorMessage(
          // ignore: use_build_context_synchronously
          AppLocalizations.of(context)!.changePasswordErrorUpdate);
    }

    // Close edit mode
    setState(() {});
  }

  // Show edit profile popup
  void _showEditProfilePopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.editProfileTitle,
            style: const TextStyle(
                color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context)!.editProfilePhoneLabel,
                  hintText: AppLocalizations.of(context)!.editProfilePhoneHint,
                  errorText: _phoneErrorText,
                ),
                keyboardType: TextInputType.phone,
                onChanged: (text) {
                  // Validate phone number as the user types
                  setState(() {
                    _phoneErrorText = text.isEmpty
                        ? AppLocalizations.of(context)!.editProfileErrorPhone
                        : (!RegExp(r'^[0-9]+$').hasMatch(text))
                            ? AppLocalizations.of(context)!
                                .editProfileErrorPhoneInvalid
                            : null;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context)!.editProfileAddressLabel,
                  hintText:
                      AppLocalizations.of(context)!.editProfileAddressHint,
                  errorText: _addressErrorText,
                ),
                onChanged: (text) {
                  // Validate address as the user types
                  setState(() {
                    _addressErrorText = text.isEmpty
                        ? AppLocalizations.of(context)!.editProfileErrorAddress
                        : null;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.editProfileCancel),
            ),
            TextButton(
              onPressed: _saveProfileChanges,
              child: Text(AppLocalizations.of(context)!.editProfileSave),
            ),
          ],
        );
      },
    );
  }

  // Show change password popup
  void _showChangePasswordPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.changePasswordTitle,
            style: const TextStyle(
                color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _oldPasswordController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!
                      .changePasswordOldPasswordHint,
                  errorText: _oldPasswordErrorText,
                ),
                obscureText: true,
                onChanged: (text) {
                  // Validate old password as the user types
                  setState(() {
                    _oldPasswordErrorText = text.isEmpty
                        ? AppLocalizations.of(context)!
                            .changePasswordErrorOldPassword
                        : (text != _currentUser.password)
                            ? AppLocalizations.of(context)!
                                .changePasswordErrorOldPasswordIncorrect
                            : null;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!
                      .changePasswordNewPasswordHint,
                  errorText: _newPasswordErrorText,
                ),
                obscureText: true,
                onChanged: (text) {
                  // Validate new password as the user types
                  setState(() {
                    _newPasswordErrorText = text.isEmpty
                        ? AppLocalizations.of(context)!
                            .changePasswordErrorNewPassword
                        : (text.length < 6)
                            ? AppLocalizations.of(context)!
                                .changePasswordErrorNewPasswordLength
                            : null;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!
                      .changePasswordConfirmPasswordHint,
                  errorText: _confirmPasswordErrorText,
                ),
                obscureText: true,
                onChanged: (text) {
                  // Validate confirm password as the user types
                  setState(() {
                    _confirmPasswordErrorText = text.isEmpty
                        ? AppLocalizations.of(context)!
                            .changePasswordErrorConfirmPassword
                        : (text != _newPasswordController.text)
                            ? AppLocalizations.of(context)!
                                .changePasswordErrorConfirmPasswordMatch
                            : null;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.changePasswordCancel),
            ),
            TextButton(
              onPressed: _savePasswordChanges,
              child: Text(AppLocalizations.of(context)!.changePasswordSave),
            ),
          ],
        );
      },
    );
  }

  // Show logout confirmation popup
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.logoutConfirmationTitle),
          content:
              Text(AppLocalizations.of(context)!.logoutConfirmationContent),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child:
                  Text(AppLocalizations.of(context)!.logoutConfirmationCancel),
            ),
            TextButton(
              onPressed: _logout,
              child:
                  Text(AppLocalizations.of(context)!.logoutConfirmationLogout),
            ),
          ],
        );
      },
    );
  }

  // Show password confirmation popup before showing edit profile popup
  void _showPasswordConfirmationPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.passwordConfirmationTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _passwordConfirmationController,
                decoration: InputDecoration(
                  hintText:
                      AppLocalizations.of(context)!.passwordConfirmationHint,
                  errorText: _passwordConfirmationErrorText,
                ),
                obscureText: true,
                onChanged: (text) {
                  // Validate confirm password as the user types
                  setState(() {
                    _passwordConfirmationErrorText = text.isEmpty
                        ? AppLocalizations.of(context)!
                            .passwordConfirmationErrorEmpty
                        : (text != _currentUser.password)
                            ? AppLocalizations.of(context)!
                                .passwordConfirmationErrorIncorrect
                            : null;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                  AppLocalizations.of(context)!.passwordConfirmationCancel),
            ),
            TextButton(
              onPressed: () {
                String enteredPassword =
                    _passwordConfirmationController.text.trim();
                if (enteredPassword.isEmpty) {
                  _showErrorMessage(AppLocalizations.of(context)!
                      .passwordConfirmationErrorEmpty);
                  return;
                } else if (enteredPassword != _currentUser.password) {
                  _showErrorMessage(AppLocalizations.of(context)!
                      .passwordConfirmationErrorIncorrect);
                  return;
                } else {
                  _passwordConfirmationErrorText = null;
                  Navigator.of(context).pop();
                  // Show edit profile popup after confirmation
                  _showEditProfilePopup();
                }
              },
              child: Text(
                  AppLocalizations.of(context)!.passwordConfirmationConfirm),
            ),
          ],
        );
      },
    );
  }

  // Helper function to show error message
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Helper function to show success message
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Function to pick image from gallery
  Future<void> _pickImage() async {
    // Request storage permission
    await Permission.storage.request();

    // Choose image source (camera or gallery)
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery, // Choose gallery source
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        // Upload avatar right away after pick image
        _uploadAvatar();
      });
    }
  }

  // Function to upload the selected image as avatar
  Future<void> _uploadAvatar() async {
    if (_selectedImage != null) {
      // Set loading flag
      setState(() {
        _isLoadingImage = true;
      });
      try {
        // Rename image
        final filename =
            '${_currentUser.userId}_${removeSign4VietnameseString(_currentUser.name.replaceAll(' ', '_').toLowerCase())}.jpg';

        // Create FormData object with the image
        final FormData formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(_selectedImage!.path,
              filename: filename),
        });

        final apiUrl =
            '${_apiHandler.baseUrl}/users/avatar/${_currentUser.userId}';
        final response = await Dio().post(
          apiUrl,
          data: formData,
          options: Options(
            headers: {'Content-Type': 'multipart/form-data'},
          ),
        );

        // Handle the response
        if (response.statusCode == 200) {
          // Update the user's avatarLocation from the response
          _currentUser = _currentUser.copyWith(
              avatarLocation: response.data['url'] as String);

          // Save the new avatarLocation to SharedPreferences
          await sharedPreferences.setString(
              'EmployeeAvatarLocation', _currentUser.avatarLocation!);

          // Refresh UI after saving new avatarLocation
          // _loadUserData();
          _showSuccessMessage(
              AppLocalizations.of(context)!.editProfileSuccessUpdateAvatar);

          // Reset the selected image
          // Call setState only once after successful upload
          setState(() {
            _selectedImage = null;
          });
          await _loadUserData();
        } else {
          // Handle errors during avatar upload
          _showErrorMessage(
              AppLocalizations.of(context)!.editProfileErrorUpdateAvatar);
        }
      } catch (e) {
        // Handle general errors
        _showErrorMessage(
            AppLocalizations.of(context)!.editProfileErrorUpdateAvatar);
      } finally {
        // Reset loading flag
        setState(() {
          _isLoadingImage = false;
        });
      }
    } else {
      // Handle the case where no image is selected
      _showErrorMessage(AppLocalizations.of(context)!.editProfileSelectImage);
    }
  }

  Future<void> _fetchLatestUserData() async {
    User? updatedUser =
        await _apiHandler.getUser(_currentUser.email, _currentUser.password);

    if (updatedUser != null && updatedUser != _currentUser) {
      setState(() {
        _currentUser = updatedUser;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.employeeInfo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showLogoutConfirmation,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (_currentUser.name.isNotEmpty)
              Center(
                child: Column(
                  children: [
                    // Display the avatar if available
                    if (_currentUser.avatarLocation != null &&
                        _currentUser.avatarLocation != "")
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(
                          // The .substring(0, _apiHandler.baseUrl.length - 4)} will delete the api in baseUrl in apihandler
                          '${_apiHandler.baseUrl.substring(0, _apiHandler.baseUrl.length - 4)}${_currentUser.avatarLocation!}',
                        ),
                      )
                    else
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.black,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _currentUser.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.employeeId,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_currentUser.userId}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.employeeEmail,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _currentUser.email,
                    style: const TextStyle(color: Colors.black, fontSize: 16),
                  ),
                  Text(
                    AppLocalizations.of(context)!.employeePhone,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_currentUser.phone}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.employeeAddress,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_currentUser.address}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Center(
                child: Container(
                  width: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    icon: const Icon(Icons.language),
                    underline: Container(),
                    onChanged: (value) {
                      _changeLanguage(value);
                      setState(() {});
                    },
                    items: [
                      DropdownMenuItem(
                        value: 'vi',
                        child: Row(
                          children: [
                            Image.asset('assets/img/country_flags/VietNam.png',
                                width: 20),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.viLanguage),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'en',
                        child: Row(
                          children: [
                            Image.asset('assets/img/country_flags/US.png',
                                width: 20),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.enLanguage),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'ko',
                        child: Row(
                          children: [
                            Image.asset(
                                'assets/img/country_flags/SouthKorea.png',
                                width: 20),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.krLanguage),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Add the button to change the avatar
            Center(
              child: Column(
                children: [
                  SizedBox(
                    width: screenWidth,
                    height: screenHeight / 15,
                    child: ElevatedButton(
                      onPressed: _pickImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        textStyle:
                            const TextStyle(fontSize: 16, color: Colors.white),
                        padding: const EdgeInsets.all(16),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.editProfileSelectImage,
                        // Allow text to wrap to multiple lines if necessary
                        textAlign: TextAlign.center,
                        softWrap: true,
                        overflow: TextOverflow
                            .ellipsis, // Display "..." if text is too long
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: screenWidth,
                    height: screenHeight / 15,
                    child: ElevatedButton(
                      onPressed: _showPasswordConfirmationPopup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        textStyle:
                            const TextStyle(fontSize: 17, color: Colors.white),
                        padding: const EdgeInsets.all(16),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.editProfile,
                        // Allow text to wrap to multiple lines if necessary
                        textAlign: TextAlign.center,
                        softWrap: true,
                        overflow: TextOverflow
                            .ellipsis, // Display "..." if text is too long
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: screenWidth,
                    height: screenHeight / 15,
                    child: ElevatedButton(
                      onPressed: _showChangePasswordPopup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 252, 136, 97),
                        textStyle:
                            const TextStyle(fontSize: 17, color: Colors.white),
                        padding: const EdgeInsets.all(16),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.changePassword,
                        textAlign: TextAlign.center,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Override didChangeDependencies to update UI when language changes
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update UI when language changes
    _loadUserData();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  // Hàm RemoveSign4VietnameseString để loại bỏ dấu tiếng Việt
  String removeSign4VietnameseString(String text) {
    String result = text;
    const vietnameseSigns = {
      'à': 'a',
      'á': 'a',
      'ả': 'a',
      'ã': 'a',
      'ạ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'ặ': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ậ': 'a',
      'đ': 'd',
      'è': 'e',
      'é': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ẹ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ệ': 'e',
      'ì': 'i',
      'í': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ị': 'i',
      'ò': 'o',
      'ó': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ọ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ộ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ợ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ụ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ự': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'ỵ': 'y',
    };

    vietnameseSigns.forEach((sign, replacement) {
      result = result.replaceAll(sign, replacement);
    });
    return result;
  }
}
