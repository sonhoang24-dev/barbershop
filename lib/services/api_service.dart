import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/service.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2/barbershop/backend/auth";

  /// Đăng nhập người dùng
  static Future<User?> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/login.php");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final jsonData = jsonDecode(response.body);
      print('API Response: $jsonData'); // Log toàn bộ phản hồi

      if (jsonData['success'] == true) {
        final userData = jsonData['user'];
        print('User Data: $userData'); // Log dữ liệu người dùng

        final prefs = await SharedPreferences.getInstance();
        // Xóa toàn bộ dữ liệu cũ trước khi lưu mới
        await prefs.clear();
        print('Cleared SharedPreferences');

        final userId = int.tryParse(userData['id'].toString()) ?? 0;
        await prefs.setInt('id', userId);
        await prefs.setString('name', userData['name'] ?? '');
        await prefs.setString('email', userData['email'] ?? '');
        await prefs.setString('role', userData['role'] ?? '');
        await prefs.setString('phone', userData['phone'] ?? '');
        await prefs.setString('gender', userData['gender'] ?? '');
        await prefs.setString('avatar', userData['avatar'] ?? '');

        // Kiểm tra lại giá trị sau khi lưu
        final savedId = prefs.getInt('id');
        print('Đăng nhập thành công - Saved User ID: $savedId');

        return User.fromJson(userData);
      } else {
        print("Đăng nhập thất bại: ${jsonData['message']}");
      }
    } catch (e) {
      print("Lỗi đăng nhập: $e");
    }

    return null;
  }

  /// Cập nhật thông tin người dùng
  static Future<void> updateProfileBase64({
    required int id,
    required String name,
    required String email,
    required String phone,
    String? gender,
    String? newPassword,
    String? avatarBase64,
  }) async {
    final url = Uri.parse('http://10.0.2.2/barbershop/backend/auth/update_profile.php');

    final body = {
      "id": id,
      "name": name,
      "email": email,
      "phone": phone,
      "gender": gender,
      "newPassword": newPassword,
      "avatarBase64": avatarBase64,
    };

    // Loại bỏ key nào có giá trị null
    body.removeWhere((key, value) => value == null);

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);
    if (data["success"] != true) {
      throw Exception(data["message"] ?? "Cập nhật thất bại");
    }
  }

  static Future<List<Service>> fetchServices() async {
    final response = await http.get(Uri.parse('$baseUrl/services/list.php'));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      print("RESPONSE: ${response.body}");
      return data.map((e) => Service.fromJson(e)).toList();
    } else {
      throw Exception('Lỗi khi tải dịch vụ');
    }
  }

  static Future<int> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('id') ?? 0;
    print('Retrieved User ID from SharedPreferences: $id');
    return id;
  }
  /// Đăng xuất người dùng
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Xóa toàn bộ dữ liệu người dùng đã lưu
    print('Đã đăng xuất và xoá dữ liệu SharedPreferences');
  }

}