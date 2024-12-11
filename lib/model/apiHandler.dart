import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:checkin/model/records.dart';
import 'package:checkin/model/shifts.dart';
import 'package:checkin/model/users.dart';
import 'package:checkin/model/task.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

class APIHandler {
  final String baseUrl = 'http://192.168.0.120:5176/api';
  final Dio dio = Dio();

  // Get user from SQL Server
  Future<User?> getUser(String email, String password) async {
    try {
      final response = await dio.get(
        '$baseUrl/users?email=$email',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List && data.isNotEmpty) {
          for (var user in data) {
            User userObj = User.fromJson(user);
            if (userObj.email == email && userObj.password == password) {
              return userObj;
            }
          }
          return null;
        } else if (data is Map) {
          return User.fromJson(data as Map<String, dynamic>);
        }
      } else {
        print('Error fetching User: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('API call error: $e');
      return null;
    }
  }

  // Update check-in/check-out
  Future<bool> updateCheckInOut(Records record) async {
    try {
      final response = await dio.put(
        '$baseUrl/records/${record.id}',
        data: record.toJson(),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error updating check-in/check-out: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('API call error: $e');
      return false;
    }
  }

  // Get list of shifts
  Future<List<Shift>?> getShifts() async {
    try {
      final response = await dio.get(
        '$baseUrl/shifts',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((shift) => Shift.fromJson(shift)).toList();
      } else {
        print('Error fetching Shifts: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('API call error: $e');
      return null;
    }
  }

  // **Sửa đổi API để lọc dữ liệu theo userId**
  Future<List<Records>> getUserRecords(int userId, DateTime date) async {
    try {
      // Tạo URL API với userId và date
      final apiUrl =
          '$baseUrl/records?userId=$userId&date=${date.year}-${date.month}';

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((record) => Records.fromJson(record)).toList();
      } else {
        print('Error fetching records: ${response.statusCode}');
        return []; // Trả về danh sách rỗng nếu có lỗi
      }
    } catch (e) {
      print('API call error: $e');
      return []; // Trả về danh sách rỗng nếu có lỗi
    }
  }

  // Insert a Records record with image
  Future<Response<dynamic>> insertRecord(
      Records record, File? imageFile) async {
    try {
      // Upload ảnh và lấy đường dẫn
      String? locationImg =
          imageFile != null ? await uploadLocationImage(imageFile) : null;

      // Cập nhật trường location trong record
      record = record.copyWith(location: locationImg);

      // Tạo FormData object để xử lý dữ liệu bản ghi
      FormData formData = FormData.fromMap({
        'records.userId': record.userId, // Thêm userId vào FormData
        'records.date': DateFormat('yyyy-MM-dd')
            .format(record.date), // Thêm date vào FormData
        'records.checkIn': record.checkIn, // Thêm checkIn vào FormData
        'records.checkOut': record.checkOut, // Thêm checkOut vào FormData
        'records.shiftId': record.shiftId, // Thêm shiftId vào FormData
        'records.lateMinutes':
            record.lateMinutes, // Thêm lateMinutes vào FormData
        'records.status': record.status, // Thêm status vào FormData
        'records.location': record.location, // Thêm location vào FormData
        'records.remark': record.remark, // Thêm remark vào FormData
        'records.imgName': record.imgName, // Thêm imgName vào FormData
        'records.ip': record.ip, // Thêm ip vào FormData
      });

      // Sử dụng POST để tạo bản ghi
      final response = await dio.post(
        '$baseUrl/records', // Endpoint cho tạo bản ghi
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'application/json', // Đảm bảo Content-Type là đúng
          },
          // Tắt validateStatus nếu cần
          validateStatus: (status) {
            return true; // Cho phép xử lý tất cả các mã lỗi
          },
        ),
      );

      // Kiểm tra response.statusCode
      if (response.statusCode == 201) {
        // Assuming API returns 201 Created when inserted successfully
        // Get the record id from the response
        // **Sửa lại để lấy record.Id sau khi thêm vào database**
        final recordId = response.data[
            'id']; // Replace 'id' with the actual field name in your API response

        return response;
      } else {
        print(
            'Error inserting record: ${response.statusCode}, ${response.data}');
        throw Exception(
            'Error inserting record: ${response.statusCode}, ${response.data}');
      }
    } catch (e) {
      print('API call error: $e');
      throw e;
    }
  }

  Future<Records?> getLatestRecord(int userId, DateTime date) async {
    try {
      // Create a Request object with cacheControl
      final request = http.Request(
        'GET',
        Uri.parse('$baseUrl/records?userId=$userId'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.headers['cache-control'] = 'no-cache'; // Set cache control

      final response = await request.send();

      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final List<dynamic> data = jsonDecode(body);
        // Filter data by userId and requested date
        final filteredData = data.where((record) {
          final recordDate = DateTime.parse(record['date'] as String);
          return recordDate.day == date.day &&
              recordDate.month == date.month &&
              recordDate.year == date.year &&
              record['userId'] == userId; // Check userId
        }).toList();

        // Sort the filtered records by combined date and time in descending order
        filteredData.sort((a, b) {
          // Extract date and time components from date strings
          final dateTimeA = DateTime.parse(a['date'] as String);
          final dateTimeB = DateTime.parse(b['date'] as String);

          // Compare dates first
          if (dateTimeB.compareTo(dateTimeA) != 0) {
            return dateTimeB.compareTo(dateTimeA);
          } else {
            // If dates are the same, compare times
            return (b['checkOut'] ?? '').compareTo(a['checkOut'] ?? '');
          }
        });

        if (filteredData.isNotEmpty) {
          return Records.fromJson(filteredData.first as Map<String, dynamic>);
        } else {
          print('No record found for the requested date');
          return null;
        }
      } else {
        print('Error fetching latest record: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('API call error: $e');
      return null;
    }
  }

  // Register new user (modified to handle avatarLocation)
  Future<bool> registerUser(User newUser) async {
    try {
      final response = await dio.post(
        '$baseUrl/users',
        data: jsonEncode(newUser.toJson()),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Error registering user: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('API call error: $e');
      return false;
    }
  }

  // New function to get the list of all users
  Future<List<User>> getAllUsers() async {
    try {
      final response = await dio.get(
        '$baseUrl/users',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((user) => User.fromJson(user)).toList();
      } else {
        print('Error fetching users: ${response.statusCode}');
        return []; // Return empty list if there is an error
      }
    } catch (e) {
      print('API call error: $e');
      return []; // Return empty list if there is an error
    }
  }

  // Get the highest userId
  Future<int> getLatestUserId(User newUser) async {
    try {
      List<User> users = await getAllUsers();
      if (users.isNotEmpty) {
        // Find the highest userId in the list
        int maxUserId =
            users.reduce((a, b) => a.userId > b.userId ? a : b).userId;
        return maxUserId;
      } else {
        return 0; // Return 0 if no users
      }
    } catch (e) {
      print('API call error: $e');
      return 0;
    }
  }

  Future<bool> updateUser(int userId, User user) async {
    try {
      final response = await dio.put(
        '$baseUrl/users/$userId',
        data: user.toJson(),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      // Handle different responses based on update type:
      if (response.statusCode == 200) {
        // Profile update successful (returns 200)
        return true;
      } else if (response.statusCode == 204) {
        // Password update successful (returns 204)
        return true;
      } else {
        print('Error updating user: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('API call error: $e');
      return false;
    }
  }

  // Function to upload user's avatar
  Future<bool> uploadAvatar(File imageFile, int userId) async {
    try {
      // Get MIME type for the image
      final mimeType = lookupMimeType(imageFile.path);

      // Create multipart request
      final request = http.MultipartRequest(
          'PUT', Uri.parse('$baseUrl/users/$userId/avatar'));
      final boundary =
          '----WebKitFormBoundary${DateTime.now().millisecondsSinceEpoch}';
      request.headers['Content-Type'] =
          'multipart/form-data; boundary=$boundary';
      request.headers['Accept'] = '*/*';

      // Add image file
      final file = http.MultipartFile.fromBytes(
        'file',
        imageFile.readAsBytesSync(),
        filename: path.basename(imageFile.path),
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      );
      request.files.add(file);

      final response = await request.send();

      // Check response status code
      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 204) {
        return true;
      } else {
        print('Error uploading avatar: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('API call error: $e');
      return false;
    }
  }

  // **Removed uploadLocationImage function**

  // **New API call for updating phone number**
  Future<bool> updateUserPhone(int userId, int phone) async {
    try {
      final response = await dio.put(
        '$baseUrl/users/phone/$userId',
        data: jsonEncode(phone),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        print('Error updating phone number: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('API call error: $e');
      return false;
    }
  }

  // **New API call for updating address**
  Future<bool> updateUserAddress(int userId, String address) async {
    try {
      final response = await dio.put(
        '$baseUrl/users/address/$userId',
        data: jsonEncode(address),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        print('Error updating address: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('API call error: $e');
      return false;
    }
  }

  // **New API call for updating password**
  Future<bool> updateUserPassword(int userId, String newPassword) async {
    try {
      final response = await dio.put(
        '$baseUrl/users/password/$userId',
        data: jsonEncode(newPassword),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        print('Error updating password: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('API call error: $e');
      return false;
    }
  }

  // **Removed getRecordImage function**

  // Function to upload image and return the location
  Future<String?> uploadLocationImage(File? imageFile) async {
    try {
      // Rename image
      final filename =
          '${DateTime.now().millisecondsSinceEpoch}.jpg'; // Use a unique name

      // Create FormData object with the image
      final FormData formData = FormData.fromMap({
        'file':
            await MultipartFile.fromFile(imageFile!.path, filename: filename),
      });

      // API endpoint for check-in/check-out image
      final apiUrl = '$baseUrl/records/location';
      final response = await dio.post(
        apiUrl,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      // Handle the response
      if (response.statusCode == 200) {
        return response.data['location']; // Return the location from response
      } else {
        // Handle errors during image upload
        throw Exception(
            'Error uploading image: ${response.statusCode}, ${response.data}');
      }
    } catch (e) {
      // Handle general errors
      throw e;
    }
  }
}
