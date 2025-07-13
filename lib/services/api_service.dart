import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/service.dart';
import '../models/extra_service.dart';
import '../models/employee.dart';
import '../models/booking.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2/barbershop/backend";

  // -------------------- AUTH --------------------

  static Future<User?> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/auth/login.php");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.body.isEmpty) return null;

      final jsonData = jsonDecode(response.body);
      if (jsonData['success'] == true) {
        final user = User.fromJson(jsonData['user']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        await prefs.setInt('id', user.id);
        await prefs.setString('name', user.name);
        await prefs.setString('email', user.email);
        await prefs.setString('role', user.role);
        await prefs.setString('phone', user.phone);
        await prefs.setString('gender', user.gender);
        await prefs.setString('avatar', user.avatar);
        return user;
      }
    } catch (e) {
      print("Login error: $e");
    }

    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // -------------------- PROFILE --------------------

  static Future<void> updateProfileBase64({
    required int id,
    required String name,
    required String email,
    required String phone,
    String? gender,
    String? newPassword,
    String? avatarBase64,
  }) async {
    final url = Uri.parse('$baseUrl/auth/update_profile.php');
    final body = {
      "id": id,
      "name": name,
      "email": email,
      "phone": phone,
      "gender": gender,
      "newPassword": newPassword,
      "avatarBase64": avatarBase64,
    }..removeWhere((key, value) => value == null);

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.body.isEmpty) throw Exception("Phản hồi rỗng từ server");

    final data = jsonDecode(response.body);
    if (data['success'] != true) throw Exception(data['message'] ?? "Cập nhật thất bại");
  }

  static Future<int> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('id') ?? 0;
  }

  // -------------------- SERVICES --------------------

  static Future<List<Service>> fetchServices() async {
    final response = await http.get(Uri.parse('$baseUrl/services/list_for_customer.php'));
    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => Service.fromJson(e)).toList();
      }
    }
    throw Exception('Lỗi tải danh sách dịch vụ');
  }

  static Future<List<Service>> fetchAllServicesForAdmin() async {
    final response = await http.get(Uri.parse('$baseUrl/services/list_for_admin.php'));
    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final body = jsonDecode(response.body);
      if (body['success'] == true && body['data'] is List) {
        return (body['data'] as List).map((json) => Service.fromJson(json)).toList();
      }
    }
    throw Exception('Không tải được dịch vụ (admin)');
  }

  static Future<Map<String, dynamic>> addOrUpdateService({
    required String name,
    required String description,
    required double price,
    required List<XFile> images,
    int? serviceId,
    required List<ExtraService> extras,
  }) async {
    final uri = Uri.parse(serviceId == null
        ? '$baseUrl/services/add.php'
        : '$baseUrl/services/update.php');

    final request = http.MultipartRequest('POST', uri)
      ..fields['name'] = name
      ..fields['description'] = description
      ..fields['price'] = price.toString();

    if (serviceId != null) request.fields['id'] = serviceId.toString();

    for (var img in images) {
      request.files.add(await http.MultipartFile.fromPath('images[]', img.path));
    }

    if (extras.isNotEmpty) {
      final extrasJson = jsonEncode(extras.map((e) => {
        'main_service_id': e.mainServiceId?.toString(),
        'name': e.name,
        'price': e.price.toString(),
        if (e.id != null) 'id': e.id.toString(),
      }).toList());
      request.fields['extras'] = extrasJson;
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();
    return jsonDecode(body);
  }

  static Future<List<ExtraService>> fetchAllExtraServices() async {
    final uri = Uri.parse("$baseUrl/services/list_extra.php");
    final res = await http.get(uri);
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final jsonData = jsonDecode(res.body);
      final List list = jsonData['data'];
      return list.map((e) => ExtraService.fromJson(e)).toList();
    }
    throw Exception('Lỗi khi tải dịch vụ bổ sung');
  }

  // -------------------- EMPLOYEES --------------------

  static Future<List<Employee>> fetchEmployees() async {
    final response = await http.get(Uri.parse('$baseUrl/employees/get_employee.php'));
    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success'] == true) {
        return (jsonData['data'] as List).map((e) => Employee.fromJson(e)).toList();
      }
    }
    return [];
  }

  static Future<bool> addEmployeeWithServices({
    required String fullName,
    required String workingHours,
    required String phone,
    required List<int> serviceIds,
    required String status,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/employees/add_employee.php'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "full_name": fullName,
        "working_hours": workingHours,
        "phone": phone,
        "service_ids": serviceIds,
        "status": status,
      }),
    );
    return jsonDecode(response.body)['success'] == true;
  }

  static Future<bool> updateEmployee({
    required int id,
    required String fullName,
    required String workingHours,
    required String phone,
    required List<int> serviceIds,
    required String status,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/employees/update_employee.php'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id": id,
        "full_name": fullName,
        "working_hours": workingHours,
        "phone": phone,
        "service_ids": serviceIds,
        "status": status,
      }),
    );
    return jsonDecode(response.body)['success'] == true;
  }

  static Future<List<Service>> fetchEmployeeServices(int employeeId) async {
    final url = Uri.parse('$baseUrl/employees/employee_services.php?id=$employeeId');
    final response = await http.get(url);
    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List).map((e) => Service.fromJson(e)).toList();
      }
    }
    return [];
  }

// -------------------- BOOKINGS (ADMIN) --------------------

  static Future<List<Booking>> getBookings() async {
    final url = Uri.parse('$baseUrl/employees/admin_get_bookings.php');
    final res = await http.get(url);
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final json = jsonDecode(res.body);
      if (json['success'] == true && json['data'] != null) {
        return (json['data'] as List).map((e) => Booking.fromJson(e)).toList();
      }
    }
    throw Exception('Không tải được danh sách lịch hẹn');
  }

  static Future<Booking> getBookingById(int id) async {
    final url = Uri.parse('$baseUrl/employees/admin_get_booking_by_id.php?id=$id');
    final res = await http.get(url);
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final json = jsonDecode(res.body);
      if (json['success'] == true && json['data'] != null) {
        return Booking.fromJson(json['data']);
      }
    }
    throw Exception('Không tải được chi tiết lịch hẹn');
  }

  static Future<bool> updateBookingStatus(int id, String status) async {
    final url = Uri.parse('$baseUrl/employees/admin_update_booking.php');
    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({'id': id, 'status': status}),
    );

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final json = jsonDecode(res.body);
      return json['success'] == true;
    }
    return false;
  }


  // -------------------- REVIEWS --------------------

  static Future<List<Map<String, dynamic>>> fetchReviews(int serviceId) async {
    final url = Uri.parse("$baseUrl/reviews/get_reviews_by_service.php?service_id=$serviceId");
    final response = await http.get(url);
    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        return List<Map<String, dynamic>>.from(json['data']);
      }
    }
    throw Exception('Lỗi khi tải đánh giá');
  }

  static Future<Map<String, dynamic>?> fetchReviewByBooking(int bookingId) async {
    final url = Uri.parse("$baseUrl/reviews/get_review_by_booking.php?booking_id=$bookingId");
    final response = await http.get(url);
    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        return Map<String, dynamic>.from(json['data']);
      }
    }
    return null;
  }


}
