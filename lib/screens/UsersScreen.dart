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
  // Màn hình thông tin người dùng
  const UsersScreen({super.key, required this.currentUser});

  final User currentUser; // Người dùng hiện tại

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  // Khai báo các biến trạng thái
  double screenHeight = 0; // Chiều cao màn hình
  double screenWidth = 0; // Chiều rộng màn hình

  final Color primaryColor =
      const Color.fromARGB(253, 239, 68, 76); // Màu chủ đạo

  late SharedPreferences
      sharedPreferences; // Đối tượng SharedPreferences để lưu trữ dữ liệu

  // Biến để lưu trữ thông tin người dùng
  late User
      _currentUser; // Người dùng hiện tại (sẽ được khởi tạo trong initState)

  bool _isLoading =
      true; // Variable to check loading status (Biến để kiểm tra trạng thái đang tải)

  // Các controller cho các trường nhập liệu
  final TextEditingController _phoneController =
      TextEditingController(); // Controller cho trường số điện thoại
  final TextEditingController _addressController =
      TextEditingController(); // Controller cho trường địa chỉ
  final TextEditingController _oldPasswordController =
      TextEditingController(); // Controller cho trường mật khẩu cũ
  final TextEditingController _newPasswordController =
      TextEditingController(); // Controller cho trường mật khẩu mới
  final TextEditingController _confirmPasswordController =
      TextEditingController(); // Controller cho trường xác nhận mật khẩu
  final TextEditingController _passwordConfirmationController =
      TextEditingController(); // Controller cho trường xác nhận mật khẩu trước khi chỉnh sửa profile

  // Các biến để lưu lỗi cho các trường nhập liệu
  String? _phoneErrorText; // Biến để hiển thị lỗi cho trường số điện thoại
  String? _addressErrorText; // Biến để hiển thị lỗi cho trường địa chỉ
  String? _oldPasswordErrorText; // Biến để hiển thị lỗi cho trường mật khẩu cũ
  String? _newPasswordErrorText; // Biến để hiển thị lỗi cho trường mật khẩu mới
  String?
      _confirmPasswordErrorText; // Biến để hiển thị lỗi cho trường xác nhận mật khẩu
  String?
      _passwordConfirmationErrorText; // Biến để hiển thị lỗi cho trường xác nhận mật khẩu trước khi chỉnh sửa profile

  // Khởi tạo APIHandler
  final APIHandler _apiHandler = APIHandler();

  // Biến để lưu trữ ngôn ngữ được chọn
  String _selectedLanguage = 'en'; // Ngôn ngữ được chọn (mặc định là tiếng Anh)

  // Các biến trạng thái để xử lý hình ảnh
  File? _selectedImage; // Biến để lưu trữ hình ảnh đã chọn
  bool _isLoadingImage = false; // Biến để kiểm tra trạng thái đang tải ảnh lên
  final ImagePicker _picker =
      ImagePicker(); // Đối tượng ImagePicker để chọn hình ảnh

  // Hàm thay đổi ngôn ngữ
  void _changeLanguage(String? language) {
    if (language != null) {
      setState(() {
        _selectedLanguage = language; // Cập nhật ngôn ngữ được chọn
      });
      // Lưu ngôn ngữ vào SharedPreferences
      _saveLanguageToPrefs(language);
      // Cập nhật locale
      Locale newLocale = Locale(language);
      MyApp.setLocale(context, newLocale);

      if (language == 'ko') {
        print('flutter: korean');
      } else if (language == 'en') {
        print('flutter: english');
      } else if (language == 'vi') {
        print('flutter: vietnamese');
      }
    }
  }

  // Hàm lưu ngôn ngữ vào SharedPreferences
  Future<void> _saveLanguageToPrefs(String language) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', language);
  }

  @override
  void initState() {
    // Hàm initState được gọi khi widget được khởi tạo
    super.initState();
    // Gán giá trị cho _currentUser
    _currentUser = widget.currentUser;
    // Gọi hàm _loadUserData để lấy dữ liệu người dùng từ SharedPreferences
    _loadUserData();
  }

  // Tải dữ liệu người dùng từ SharedPreferences và cập nhật giao diện
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
    int? isAdmin = sharedPreferences.getInt('isAdmin') ?? 0;

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
        isAdmin: isAdmin,
      );
      _phoneController.text =
          _currentUser.phone.toString(); // Set giá trị cho trường số điện thoại
      _addressController.text =
          _currentUser.address ?? ''; // Set giá trị cho trường địa chỉ

      // Cập nhật giao diện với ngôn ngữ mới
      setState(() {
        _isLoading = false;
        // Cập nhật _selectedLanguage sau khi tải dữ liệu
        _selectedLanguage = sharedPreferences.getString('languageCode') ?? 'en';
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
    // Trả về dữ liệu người dùng đã cập nhật
    return _currentUser;
  }

  // Xử lý đăng xuất
  // Xử lý đăng xuất
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Xóa toàn bộ dữ liệu trong SharedPreferences
    await prefs.clear();

    // Ẩn bàn phím trước khi đăng xuất
    FocusScope.of(context).unfocus();

    // Xóa toàn bộ stack điều hướng và chuyển về GuestNewsScreen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const GuestNewsScreen()),
      (Route<dynamic> route) => false, // Xóa tất cả các route trước đó
    ).then((_) {
      // Reset hoàn toàn ứng dụng
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GuestNewsScreen()),
      );
    });
  }

  // Xử lý lưu thay đổi thông tin cá nhân
  Future<void> _saveProfileChanges() async {
    // Kiểm tra số điện thoại và địa chỉ mới
    String? newPhone = _phoneController.text.trim();
    String? newAddress = _addressController.text.trim();

    // Kiểm tra số điện thoại
    if (newPhone.isEmpty) {
      _showErrorMessage(AppLocalizations.of(context)!.editProfileErrorPhone);
      return;
    } else if (!RegExp(r'^[0-9]+$').hasMatch(newPhone)) {
      _showErrorMessage(
          AppLocalizations.of(context)!.editProfileErrorPhoneInvalid);
      return;
    }

    // Kiểm tra địa chỉ
    if (newAddress.isEmpty) {
      _showErrorMessage(AppLocalizations.of(context)!.editProfileErrorAddress);
      return;
    }

    // Cập nhật thông tin người dùng trong SharedPreferences
    await sharedPreferences.setString('EmployeePhone', newPhone);
    await sharedPreferences.setString('EmployeeAddress', newAddress);

    // Cập nhật thông tin người dùng trong đối tượng _currentUser
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
      // Lấy dữ liệu người dùng mới nhất và cập nhật _currentUser
      await _loadUserData(); // Gọi _loadUserData khi cập nhật thành công
    } else {
      _showErrorMessage(AppLocalizations.of(context)!.editProfileErrorUpdate);
    }
  }

  // Xử lý lưu thay đổi mật khẩu
  Future<void> _savePasswordChanges() async {
    // Kiểm tra giá trị mật khẩu mới
    String? oldPassword = _oldPasswordController.text.trim();
    String? newPassword = _newPasswordController.text.trim();
    String? confirmPassword = _confirmPasswordController.text.trim();

    // Kiểm tra mật khẩu cũ
    if (oldPassword.isEmpty) {
      _showErrorMessage(
          AppLocalizations.of(context)!.changePasswordErrorOldPassword);
      return;
    } else if (oldPassword != _currentUser.password) {
      // Kiểm tra mật khẩu cũ có khớp với mật khẩu hiện tại không
      _showErrorMessage(AppLocalizations.of(context)!
          .changePasswordErrorOldPasswordIncorrect);
      return;
    }

    // Kiểm tra mật khẩu mới
    if (newPassword.isEmpty) {
      _showErrorMessage(
          AppLocalizations.of(context)!.changePasswordErrorNewPassword);
      return;
    } else if (newPassword.length < 6) {
      _showErrorMessage(
          AppLocalizations.of(context)!.changePasswordErrorNewPasswordLength);
      return;
    }

    // Kiểm tra mật khẩu xác nhận
    if (confirmPassword.isEmpty) {
      _showErrorMessage(
          AppLocalizations.of(context)!.changePasswordErrorConfirmPassword);
      return;
    } else if (confirmPassword != newPassword) {
      _showErrorMessage(AppLocalizations.of(context)!
          .changePasswordErrorConfirmPasswordMatch);
      return;
    }

    bool success = await _apiHandler.updateUserPassword(
        _currentUser.userId, newPassword); // Gọi API để cập nhật mật khẩu

    if (success) {
      // Hiển thị thông báo thành công và đóng dialog
      _showSuccessMessage(
          // ignore: use_build_context_synchronously
          AppLocalizations.of(context)!.changePasswordSuccessUpdate);
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop(); // Close the dialog

      // Lấy dữ liệu người dùng mới nhất và cập nhật _currentUser
      await _loadUserData(); // Gọi _loadUserData khi cập nhật thành công
    } else {
      // Hiển thị thông báo lỗi
      _showErrorMessage(
          // ignore: use_build_context_synchronously
          AppLocalizations.of(context)!.changePasswordErrorUpdate);
    }

    // Đóng chế độ chỉnh sửa
    setState(() {});
  }

  // Hiển thị popup chỉnh sửa thông tin cá nhân
  void _showEditProfilePopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)!
                .editProfileTitle, // Hiển thị tiêu đề popup
            style: const TextStyle(
                color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _phoneController, // Trường nhập số điện thoại
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!
                      .editProfilePhoneLabel, // Hiển thị nhãn trường số điện thoại
                  hintText: AppLocalizations.of(context)!
                      .editProfilePhoneHint, // Hiển thị gợi ý cho trường số điện thoại
                  errorText:
                      _phoneErrorText, // Hiển thị lỗi cho trường số điện thoại
                ),
                keyboardType: TextInputType.phone,
                onChanged: (text) {
                  // Kiểm tra số điện thoại khi người dùng nhập
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
                controller: _addressController, // Trường nhập địa chỉ
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!
                      .editProfileAddressLabel, // Hiển thị nhãn trường địa chỉ
                  hintText: AppLocalizations.of(context)!
                      .editProfileAddressHint, // Hiển thị gợi ý cho trường địa chỉ
                  errorText:
                      _addressErrorText, // Hiển thị lỗi cho trường địa chỉ
                ),
                onChanged: (text) {
                  // Kiểm tra địa chỉ khi người dùng nhập
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
                Navigator.of(context).pop(); // Đóng dialog
              },
              child: Text(AppLocalizations.of(context)!
                  .editProfileCancel), // Hiển thị nút hủy
            ),
            TextButton(
              onPressed: _saveProfileChanges, // Gọi hàm lưu thay đổi
              child: Text(AppLocalizations.of(context)!
                  .editProfileSave), // Hiển thị nút lưu
            ),
          ],
        );
      },
    );
  }

  // Hiển thị popup thay đổi mật khẩu
  void _showChangePasswordPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)!
                .changePasswordTitle, // Hiển thị tiêu đề popup
            style: const TextStyle(
                color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _oldPasswordController, // Trường nhập mật khẩu cũ
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!
                      .changePasswordOldPasswordHint, // Hiển thị gợi ý cho trường mật khẩu cũ
                  errorText:
                      _oldPasswordErrorText, // Hiển thị lỗi cho trường mật khẩu cũ
                ),
                obscureText: true,
                onChanged: (text) {
                  // Kiểm tra mật khẩu cũ khi người dùng nhập
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
                controller: _newPasswordController, // Trường nhập mật khẩu mới
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!
                      .changePasswordNewPasswordHint, // Hiển thị gợi ý cho trường mật khẩu mới
                  errorText:
                      _newPasswordErrorText, // Hiển thị lỗi cho trường mật khẩu mới
                ),
                obscureText: true,
                onChanged: (text) {
                  // Kiểm tra mật khẩu mới khi người dùng nhập
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
                controller:
                    _confirmPasswordController, // Trường nhập xác nhận mật khẩu
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!
                      .changePasswordConfirmPasswordHint, // Hiển thị gợi ý cho trường xác nhận mật khẩu
                  errorText:
                      _confirmPasswordErrorText, // Hiển thị lỗi cho trường xác nhận mật khẩu
                ),
                obscureText: true,
                onChanged: (text) {
                  // Kiểm tra mật khẩu xác nhận khi người dùng nhập
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
                Navigator.of(context).pop(); // Đóng dialog
              },
              child: Text(AppLocalizations.of(context)!
                  .changePasswordCancel), // Hiển thị nút hủy
            ),
            TextButton(
              onPressed: _savePasswordChanges, // Gọi hàm lưu thay đổi mật khẩu
              child: Text(AppLocalizations.of(context)!
                  .changePasswordSave), // Hiển thị nút lưu
            ),
          ],
        );
      },
    );
  }

  // Hiển thị popup xác nhận đăng xuất
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!
              .logoutConfirmationTitle), // Hiển thị tiêu đề popup
          content: Text(AppLocalizations.of(context)!
              .logoutConfirmationContent), // Hiển thị nội dung popup
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
              },
              child: Text(AppLocalizations.of(context)!
                  .logoutConfirmationCancel), // Hiển thị nút hủy
            ),
            TextButton(
              onPressed: _logout, // Gọi hàm đăng xuất
              child: Text(AppLocalizations.of(context)!
                  .logoutConfirmationLogout), // Hiển thị nút đăng xuất
            ),
          ],
        );
      },
    );
  }

  // Hiển thị popup xác nhận mật khẩu trước khi hiển thị popup chỉnh sửa thông tin cá nhân
  void _showPasswordConfirmationPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!
              .passwordConfirmationTitle), // Hiển thị tiêu đề popup
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller:
                    _passwordConfirmationController, // Trường nhập xác nhận mật khẩu
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!
                      .passwordConfirmationHint, // Hiển thị gợi ý cho trường xác nhận mật khẩu
                  errorText:
                      _passwordConfirmationErrorText, // Hiển thị lỗi cho trường xác nhận mật khẩu
                ),
                obscureText: true,
                onChanged: (text) {
                  // Kiểm tra mật khẩu xác nhận khi người dùng nhập
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
                Navigator.of(context).pop(); // Đóng dialog
              },
              child: Text(AppLocalizations.of(context)!
                  .passwordConfirmationCancel), // Hiển thị nút hủy
            ),
            TextButton(
              onPressed: () {
                String enteredPassword = _passwordConfirmationController.text
                    .trim(); // Lấy mật khẩu đã nhập
                if (enteredPassword.isEmpty) {
                  _showErrorMessage(AppLocalizations.of(context)!
                      .passwordConfirmationErrorEmpty); // Hiển thị lỗi nếu mật khẩu rỗng
                  return;
                } else if (enteredPassword != _currentUser.password) {
                  // Nếu mật khẩu không đúng thì hiển thị lỗi
                  _showErrorMessage(AppLocalizations.of(context)!
                      .passwordConfirmationErrorIncorrect);
                  return;
                } else {
                  _passwordConfirmationErrorText =
                      null; // Xóa lỗi nếu mật khẩu đúng
                  Navigator.of(context).pop(); // Đóng dialog
                  // Hiển thị popup chỉnh sửa thông tin cá nhân sau khi xác nhận mật khẩu
                  _showEditProfilePopup();
                }
              },
              child: Text(AppLocalizations.of(context)!
                  .passwordConfirmationConfirm), // Hiển thị nút xác nhận
            ),
          ],
        );
      },
    );
  }

  // Hàm trợ giúp hiển thị thông báo lỗi
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Hàm trợ giúp hiển thị thông báo thành công
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Hàm chọn ảnh từ thư viện
  Future<void> _pickImage() async {
    // Yêu cầu quyền truy cập bộ nhớ
    await Permission.storage.request();

    // Chọn nguồn ảnh (camera hoặc thư viện)
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery, // Chọn nguồn là thư viện
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path); // Lưu file ảnh đã chọn
        // Tải ảnh lên ngay sau khi chọn ảnh
        _uploadAvatar();
      });
    }
  }

  // Hàm tải ảnh đã chọn lên làm avatar
  Future<void> _uploadAvatar() async {
    if (_selectedImage != null) {
      // Đặt trạng thái đang tải
      setState(() {
        _isLoadingImage = true;
      });
      try {
        // Đổi tên ảnh
        final filename =
            '${_currentUser.userId}_${removeSign4VietnameseString(_currentUser.name.replaceAll(' ', '_').toLowerCase())}.jpg';

        // Tạo đối tượng FormData với ảnh
        final FormData formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(_selectedImage!.path,
              filename: filename),
        });

        final apiUrl =
            '${_apiHandler.baseUrl}/users/avatar/${_currentUser.userId}'; // Tạo đường dẫn API
        final response = await Dio().post(
          apiUrl,
          data: formData,
          options: Options(
            headers: {'Content-Type': 'multipart/form-data'},
          ),
        ); // Gọi API để tải ảnh lên

        // Xử lý phản hồi
        if (response.statusCode == 200) {
          // Cập nhật avatarLocation của người dùng từ phản hồi
          _currentUser = _currentUser.copyWith(
              avatarLocation: response.data['url'] as String);

          // Lưu avatarLocation mới vào SharedPreferences
          await sharedPreferences.setString(
              'EmployeeAvatarLocation', _currentUser.avatarLocation!);

          // Làm mới giao diện sau khi lưu avatarLocation mới
          // _loadUserData();
          _showSuccessMessage(
              AppLocalizations.of(context)!.editProfileSuccessUpdateAvatar);

          // Đặt lại ảnh đã chọn
          // Chỉ gọi setState một lần sau khi tải lên thành công
          setState(() {
            _selectedImage = null;
          });
          await _loadUserData();
        } else {
          // Xử lý lỗi khi tải avatar lên
          _showErrorMessage(
              AppLocalizations.of(context)!.editProfileErrorUpdateAvatar);
        }
      } catch (e) {
        // Xử lý các lỗi chung
        _showErrorMessage(
            AppLocalizations.of(context)!.editProfileErrorUpdateAvatar);
      } finally {
        // Đặt lại trạng thái đang tải
        setState(() {
          _isLoadingImage = false;
        });
      }
    } else {
      // Xử lý trường hợp không có ảnh nào được chọn
      _showErrorMessage(AppLocalizations.of(context)!.editProfileSelectImage);
    }
  }

  Future<void> _fetchLatestUserData() async {
    // Hàm lấy dữ liệu người dùng mới nhất
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
    // Hàm build giao diện người dùng
    screenHeight = MediaQuery.of(context).size.height; // Lấy chiều cao màn hình
    screenWidth = MediaQuery.of(context).size.width; // Lấy chiều rộng màn hình
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!
              .employeeInfo, // Hiển thị tiêu đề "Thông tin nhân viên"
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            onPressed:
                _showLogoutConfirmation, // Gọi hàm hiển thị popup xác nhận đăng xuất
            icon: const Icon(Icons.logout), // Hiển thị icon đăng xuất
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
                    // Hiển thị avatar nếu có
                    if (_currentUser.avatarLocation != null &&
                        _currentUser.avatarLocation != "")
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(
                          // Đoạn .substring(0, _apiHandler.baseUrl.length - 4) sẽ xóa phần api trong baseUrl ở apihandler
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
                        _currentUser.name, // Hiển thị tên người dùng
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
                    AppLocalizations.of(context)!
                        .employeeId, // Hiển thị nhãn "ID nhân viên"
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_currentUser.userId}', // Hiển thị ID người dùng
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!
                        .employeeEmail, // Hiển thị nhãn "Email nhân viên"
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _currentUser.email, // Hiển thị email người dùng
                    style: const TextStyle(color: Colors.black, fontSize: 16),
                  ),
                  Text(
                    AppLocalizations.of(context)!
                        .employeePhone, // Hiển thị nhãn "Số điện thoại nhân viên"
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_currentUser.phone}', // Hiển thị số điện thoại người dùng
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!
                        .employeeAddress, // Hiển thị nhãn "Địa chỉ nhân viên"
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_currentUser.address}', // Hiển thị địa chỉ người dùng
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
                            Text(AppLocalizations.of(context)!
                                .viLanguage), // Hiển thị ngôn ngữ tiếng Việt
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
                            Text(AppLocalizations.of(context)!
                                .enLanguage), // Hiển thị ngôn ngữ tiếng Anh
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
                            Text(AppLocalizations.of(context)!
                                .krLanguage), // Hiển thị ngôn ngữ tiếng Hàn
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Thêm nút để thay đổi avatar
            Center(
              child: Column(
                children: [
                  SizedBox(
                    width: screenWidth,
                    height: screenHeight / 15,
                    child: ElevatedButton(
                      onPressed: _pickImage, // Gọi hàm chọn ảnh khi nhấn
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        textStyle:
                            const TextStyle(fontSize: 16, color: Colors.white),
                        padding: const EdgeInsets.all(16),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!
                            .editProfileSelectImage, // Hiển thị nút "Chọn ảnh"
                        // Cho phép văn bản xuống dòng nếu cần
                        textAlign: TextAlign.center,
                        softWrap: true,
                        overflow: TextOverflow
                            .ellipsis, // Hiển thị "..." nếu văn bản quá dài
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: screenWidth,
                    height: screenHeight / 15,
                    child: ElevatedButton(
                      onPressed:
                          _showPasswordConfirmationPopup, // Gọi hàm hiển thị popup xác nhận mật khẩu
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        textStyle:
                            const TextStyle(fontSize: 17, color: Colors.white),
                        padding: const EdgeInsets.all(16),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!
                            .editProfile, // Hiển thị nút "Chỉnh sửa thông tin"
                        // Cho phép văn bản xuống dòng nếu cần
                        textAlign: TextAlign.center,
                        softWrap: true,
                        overflow: TextOverflow
                            .ellipsis, // Hiển thị "..." nếu văn bản quá dài
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: screenWidth,
                    height: screenHeight / 15,
                    child: ElevatedButton(
                      onPressed:
                          _showChangePasswordPopup, // Gọi hàm hiển thị popup thay đổi mật khẩu
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 252, 136, 97),
                        textStyle:
                            const TextStyle(fontSize: 17, color: Colors.white),
                        padding: const EdgeInsets.all(16),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!
                            .changePassword, // Hiển thị nút "Thay đổi mật khẩu"
                        textAlign: TextAlign.center,
                        softWrap: true,
                        overflow: TextOverflow
                            .ellipsis, // Hiển thị "..." nếu văn bản quá dài
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

  // Ghi đè didChangeDependencies để cập nhật giao diện khi ngôn ngữ thay đổi
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cập nhật giao diện khi ngôn ngữ thay đổi
    _loadUserData();
  }

  @override
  void dispose() {
    // Hàm dispose được gọi khi widget bị hủy
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
