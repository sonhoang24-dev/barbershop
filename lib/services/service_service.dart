import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service.dart';

class ServiceService {
  static const String _baseUrl = "http://10.0.2.2/barbershop/backend";

  static Future<List<Service>> fetchServices() async {
    final response = await http.get(Uri.parse("$_baseUrl/services/get_all.php"));

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body['success'] == true) {
        return (body['data'] as List)
            .map((e) => Service.fromJson(e))
            .toList();
      } else {
        throw Exception(body['message'] ?? "Không lấy được dữ liệu");
      }
    } else {
      throw Exception("Lỗi kết nối server");
    }
  }
  static Future<List<Map<String, dynamic>>> fetchReviews(int serviceId) async {
    final url = Uri.parse("$_baseUrl/reviews/get_reviews_by_service.php?service_id=$serviceId");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null) {
        return List<Map<String, dynamic>>.from(json['data']);
      }
    }

    throw Exception('Lỗi khi tải đánh giá');
  }
  static Future<Map<String, dynamic>?> fetchReviewByBooking(int bookingId) async {
    final url = Uri.parse("$_baseUrl/reviews/get_review_by_booking.php?booking_id=$bookingId");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null) {
        return Map<String, dynamic>.from(json['data']);
      }
    }
    return null;
  }


// Đăng xuất người dùng
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Xóa toàn bộ dữ liệu người dùng đã lưu
    print('Đã đăng xuất và xoá dữ liệu SharedPreferences');
  }


}
