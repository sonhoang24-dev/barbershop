import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking.dart';
import '../../services/api_service.dart';
import 'appointment_detail_admin_screen.dart';

class AppointmentListAdminScreen extends StatefulWidget {
  const AppointmentListAdminScreen({super.key});

  @override
  State<AppointmentListAdminScreen> createState() => _AppointmentListAdminScreenState();
}

class _AppointmentListAdminScreenState extends State<AppointmentListAdminScreen> {
  List<Booking> bookings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => isLoading = true);
    try {
      final results = await ApiService.getBookings();
      if (mounted) {
        setState(() {
          bookings = results;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải danh sách: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch hẹn khách hàng', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal[700],
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchBookings,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[100],
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.teal))
            : bookings.isEmpty
            ? const Center(
          child: Text(
            'Không có lịch hẹn nào',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        )
            : RefreshIndicator(
          onRefresh: _fetchBookings,
          color: Colors.teal,
          backgroundColor: Colors.white,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              // Xác định màu trạng thái
              Color statusColor = _getStatusColor(booking.status);
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AppointmentDetailAdminScreen(bookingId: booking.id),
                      ),
                    );
                    if (updated == true) _fetchBookings(); // reload nếu có thay đổi
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.schedule, color: statusColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${booking.customerName ?? 'Chưa có tên'} - ${booking.serviceName ?? 'Dịch vụ'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.teal[900],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ngày: ${DateFormat('dd/MM/yyyy').format(booking.date)}\n'
                                    'Giờ: ${booking.time}',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.circle, size: 12, color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    booking.status,
                                    style: TextStyle(fontSize: 14, color: statusColor, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
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
}