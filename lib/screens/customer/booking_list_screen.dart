import 'package:barbershop_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'booking_detail_screen.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> bookings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBookings();
  }

  @override
  void didUpdateWidget(BookingListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadBookings();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadBookings();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final userId = await ApiService.getUserId();
    final url = Uri.parse("http://10.0.2.2/barbershop/backend/services/get_bookings_by_user.php?user_id=$userId");
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      print('Status Code: ${res.statusCode}, Response Body: ${res.body}');
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] == true && json['data'] != null) {
          setState(() {
            bookings = List<Map<String, dynamic>>.from(json['data']);
            bookings.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
            print('Updated bookings at ${DateTime.now()}: $bookings');
          });
        } else {
          setState(() => bookings = []);
          print('No data or success false: $json');
        }
      } else {
        setState(() => bookings = []);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể tải lịch đặt. Vui lòng kiểm tra kết nối.')),
          );
        }
      }
    } catch (e) {
      setState(() => bookings = []);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e. Vui lòng thử lại sau.')),
        );
      }
      print('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      return "${dateTime.day.toString().padLeft(2, '0')}/"
          "${dateTime.month.toString().padLeft(2, '0')}/"
          "${dateTime.year} lúc "
          "${dateTime.hour.toString().padLeft(2, '0')}:"
          "${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "N/A";
    }
  }

  String _formatCurrency(dynamic amount) {
    try {
      final number = double.tryParse(amount.toString()) ?? 0;
      final formatter = NumberFormat('#,###', 'vi_VN');
      return "${formatter.format(number)} đ";
    } catch (_) {
      return "$amount đ";
    }
  }

  // Hàm lấy thông tin trạng thái (màu sắc và biểu tượng)
  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'Chờ xác nhận':
        return {'color': Colors.orange, 'icon': Icons.schedule};
      case 'Đã xác nhận':
        return {'color': Colors.blue, 'icon': Icons.check_circle};
      case 'Đang thực hiện':
        return {'color': Colors.purple, 'icon': Icons.hourglass_top};
      case 'Đã hoàn thành':
        return {'color': Colors.green, 'icon': Icons.done_all};
      case 'Đã huỷ':
        return {'color': Colors.red, 'icon': Icons.cancel};
      default:
        return {'color': Colors.grey, 'icon': Icons.help}; // Trạng thái không xác định
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch đã đặt'),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : bookings.isEmpty
          ? const Center(child: Text("Chưa có lịch đặt nào"))
          : ListView.builder(
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          final extras = (booking['extras'] as List<dynamic>?)?.join(', ') ?? '';
          final createdAt = booking['created_at'] ?? '';
          final hasReview = booking['rating'] != null;
          final statusInfo = _getStatusInfo(booking['status'] ?? 'Không xác định');

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingDetailScreen(
                      booking: booking,
                      bookingIndex: index,
                    ),
                  ),
                );
                if (result == true) {
                  _loadBookings();
                }
              },
              leading: const Icon(Icons.event_available, color: Colors.teal),
              title: Text(booking['service'] ?? "Dịch vụ"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Ngày: ${booking['date']} - Giờ: ${booking['time']}"),
                  Text("Nhân viên: ${booking['employee'] ?? '---'}"),
                  if (extras.isNotEmpty) Text("Dịch vụ thêm: $extras"),
                  if ((booking['note'] as String?)?.isNotEmpty ?? false)
                    Text("Ghi chú: ${booking['note']}",
                        style: const TextStyle(fontStyle: FontStyle.italic)),
                  const SizedBox(height: 4),
                  Text(
                      "Tổng tiền: ${_formatCurrency(booking['total'])}",
                      style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                  if (createdAt.isNotEmpty)
                    Text(
                      "Thời gian đặt: ${_formatDateTime(createdAt)}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  if (hasReview)
                    Text(
                      "Đánh giá: ${booking['rating']} / 5 sao",
                      style: const TextStyle(fontSize: 12, color: Colors.amber),
                    ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    statusInfo['icon'] as IconData,
                    size: 18,
                    color: statusInfo['color'] as Color,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    booking['status'] ?? 'Không xác định',
                    style: TextStyle(
                      fontSize: 12,
                      color: statusInfo['color'] as Color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}