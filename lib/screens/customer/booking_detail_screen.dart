import 'package:barbershop_app/screens/customer/ReviewService.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class BookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  final int bookingIndex;

  const BookingDetailScreen({
    super.key,
    required this.booking,
    required this.bookingIndex,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late Map<String, dynamic> booking;
  double? _rating;
  final TextEditingController _feedbackController = TextEditingController();
  List<String> serviceImages = [];
  bool _isReviewSubmitted = false;

  @override
  void initState() {
    super.initState();
    booking = Map<String, dynamic>.from(widget.booking);
    _loadReview();
    _loadServiceImages();
  }

  Future<void> _loadServiceImages() async {
    try {
      final res = await http.get(Uri.parse(
          "http://10.0.2.2/barbershop/backend/services/get_images.php?service_id=${booking['service_id']}"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          serviceImages = List<String>.from(data.map((e) => e['image'].toString()));
        });
      } else {
        print('Error loading images: Status ${res.statusCode}, Body: ${res.body}');
      }
    } catch (e) {
      print('Exception loading images: $e');
    }
  }

  Future<void> _loadReview() async {
    try {
      final review = await ReviewService.getReviewByBooking(booking['id']);
      if (review != null) {
        setState(() {
          final rawRating = review['rating'];
          if (rawRating is num && rawRating >= 0 && rawRating <= 5) {
            _rating = rawRating.toDouble();
          } else {
            _rating = 0.0;
          }
          _feedbackController.text = review['feedback'] ?? '';
          booking['rating'] = _rating;
          booking['feedback'] = review['feedback'];
          _isReviewSubmitted = true;
        });
      }
    } catch (e) {
      print('Error loading review: $e');
    }
  }

  Future<void> _cancelBooking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('id') ?? 0;
      if (userId == 0) throw Exception("Không tìm thấy user_id");

      final response = await http.post(
        Uri.parse("http://10.0.2.2/barbershop/backend/employees/update_booking_status.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "booking_id": booking['id'],
          "status": "Đã huỷ",
          "user_id": userId,
        }),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success'] == true) {
        setState(() {
          booking['status'] = "Đã huỷ";
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đã hủy lịch thành công.")),
          );
          Navigator.pop(context, {
            'updated': true,
            'new_status': 'Đã huỷ',
          });
        }
      } else {
        throw Exception(result['message'] ?? "Lỗi khi hủy lịch");
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi khi hủy lịch: $e")),
        );
      }
      print('Error cancelling booking: $e');
    }
  }

  Future<void> _saveReview() async {
    if (_rating == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng chọn số sao để đánh giá!")),
        );
      }
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('id');
      if (userId == null) throw Exception("Không tìm thấy user_id");

      await ReviewService.submitReview(
        bookingId: booking['id'],
        userId: userId,
        rating: _rating!,
        feedback: _feedbackController.text,
      );

      setState(() {
        booking['rating'] = _rating;
        booking['feedback'] = _feedbackController.text;
        _isReviewSubmitted = true;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã gửi đánh giá thành công.")),
        );
        Navigator.pop(context, {
          'updated': true,
          'new_status': booking['status'],
          'rating': _rating, // Truyền rating về
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi khi gửi đánh giá: $e")),
        );
      }
    }
  }

  bool get canReview =>
      booking['status'] == "Đã hoàn thành" &&
          (booking['rating'] == null || booking['rating'] is! num);

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label:", style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.teal)),
          const SizedBox(width: 6),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Chờ xác nhận':
        return Colors.orange;
      case 'Đã xác nhận':
        return Colors.blue;
      case 'Đang thực hiện':
        return Colors.purple;
      case 'Đã hoàn thành':
        return Colors.green;
      case 'Đã huỷ':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final extras = (booking['extras'] as List<dynamic>?)?.join(', ') ?? '';
    final canEdit = booking['status'] == "Chờ xác nhận";
    final safeRating = (_rating ?? 0).clamp(0, 5).toInt();

    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết lịch đặt"), backgroundColor: Colors.teal),
      body: Container(
        color: Colors.grey[100],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              if (serviceImages.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: serviceImages.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Image.network(
                        "http://10.0.2.2/barbershop/backend/${serviceImages[index]}",
                        width: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow("Dịch vụ", booking['service'] ?? 'Dịch vụ'),
                    _buildInfoRow("Ngày", booking['date'] ?? 'N/A'),
                    _buildInfoRow("Giờ", booking['time'] ?? 'N/A'),
                    _buildInfoRow("Nhân viên", booking['employee'] ?? '---'),
                    if (extras.isNotEmpty) _buildInfoRow("Dịch vụ thêm", extras),
                    _buildInfoRow("Tổng tiền", "${NumberFormat('#,###', 'vi_VN').format(double.tryParse(booking['total'].toString()) ?? 0)} đ"),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Text("Trạng thái:", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.teal)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              booking['status'] ?? 'Không xác định',
                              style: TextStyle(color: _getStatusColor(booking['status'] ?? ''), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (booking['rating'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow("Đánh giá", "${booking['rating']} / 5 sao"),
                          if (booking['feedback'] != null && booking['feedback'].isNotEmpty)
                            _buildInfoRow("Phản hồi", booking['feedback']),
                        ],
                      ),
                    const Divider(height: 24),
                    const Text("Thông tin khách hàng", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                    const SizedBox(height: 8),
                    _buildInfoRow("Họ tên", booking['customer_name'] ?? ""),
                    _buildInfoRow("SĐT", booking['customer_phone'] ?? ""),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (canEdit)
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: const Text("Huỷ lịch"),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Xác nhận huỷ lịch"),
                          content: const Text("Bạn có chắc muốn huỷ lịch này không?"),
                          actions: [
                            TextButton(
                              child: const Text("Không"),
                              onPressed: () => Navigator.pop(context),
                            ),
                            TextButton(
                              child: const Text("Huỷ lịch", style: TextStyle(color: Colors.red)),
                              onPressed: () {
                                Navigator.pop(context);
                                _cancelBooking();
                              },
                            ),
                          ],
                        )
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              if (canReview)
                _buildReviewForm(safeRating)
              else if (_isReviewSubmitted)
                _buildReviewResult(safeRating),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewForm(int safeRating) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Đánh giá dịch vụ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (i) => IconButton(
                  icon: Icon(i < safeRating ? Icons.star : Icons.star_border, color: Colors.amber),
                  onPressed: () => setState(() => _rating = (i + 1).toDouble()),
                )),
              ),
              TextField(
                controller: _feedbackController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Góp ý thêm", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text("Gửi đánh giá"),
                  onPressed: _saveReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewResult(int safeRating) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Đánh giá dịch vụ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
              const SizedBox(height: 8),
              Row(children: List.generate(5, (i) => Icon(i < safeRating ? Icons.star : Icons.star_border, color: Colors.amber))),
              if (_feedbackController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_feedbackController.text, style: const TextStyle(color: Colors.black87)),
                ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.center,
                child: Text("Đã đánh giá", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}