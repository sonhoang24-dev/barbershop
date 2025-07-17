import 'dart:convert';
import 'package:http/http.dart' as http;

class ReviewService {
  static const baseUrl = "http://192.168.1.210/barbershop/backend/reviews";
  static Future<void> submitReview({
    required int bookingId,
    required int userId,
    required double rating,
    required String feedback,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/submit_review.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "booking_id": bookingId,
        "user_id": userId,
        "rating": rating,
        "feedback": feedback,
      }),
    );

    print("Server response: ${response.body}");
    final json = jsonDecode(response.body);
    if (json['success'] != true) throw Exception(json['message'] ?? "Gửi đánh giá thất bại");
  }

  static Future<Map<String, dynamic>?> getReviewByBooking(int bookingId) async {
    final response = await http.get(Uri.parse("$baseUrl/get_review_by_booking.php?booking_id=$bookingId"));
    print("API RESPONSE: ${response.body}");
    final json = jsonDecode(response.body);
    if (json['success'] == true) return json['data'];
    return null;
  }
}
