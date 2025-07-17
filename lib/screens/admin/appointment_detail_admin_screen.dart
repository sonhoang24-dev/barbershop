import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking.dart';
import '../../services/api_service.dart';

class AppointmentDetailAdminScreen extends StatefulWidget {
  final int bookingId;

  const AppointmentDetailAdminScreen({super.key, required this.bookingId});

  @override
  State<AppointmentDetailAdminScreen> createState() => _AppointmentDetailAdminScreenState();
}

class _AppointmentDetailAdminScreenState extends State<AppointmentDetailAdminScreen> {
  Booking? booking;
  bool isLoading = true;
  String? selectedStatus;

  final List<String> allStatuses = [
    'Chờ xác nhận',
    'Đã xác nhận',
    'Đang thực hiện',
    'Đã hoàn thành',
    'Đã huỷ',
  ];

  List<String> getAvailableStatuses(String? currentStatus) {
    if (currentStatus == null) return allStatuses;

    switch (currentStatus) {
      case 'Chờ xác nhận':
        return ['Đã xác nhận', 'Đang thực hiện', 'Đã hoàn thành', 'Đã huỷ'];
      case 'Đã xác nhận':
        return ['Đang thực hiện', 'Đã hoàn thành', 'Đã huỷ'];
      case 'Đang thực hiện':
        return ['Đã hoàn thành'];
      case 'Đã hoàn thành':
      case 'Đã huỷ':
      default:
        return [];
    }
  }

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    try {
      final result = await ApiService.getBookingById(widget.bookingId);
      if (!mounted) return;

      final available = getAvailableStatuses(result.status);
      setState(() {
        booking = result;
        selectedStatus = available.contains(result.status) ? result.status : null;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải chi tiết: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  Future<void> _updateStatus() async {
    if (selectedStatus == booking?.status || selectedStatus == null || booking == null) return;

    try {
      final success = await ApiService.updateBookingStatus(booking!.id, selectedStatus!);
      if (!mounted) return;

      if (success) {
        await _loadBooking();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật trạng thái thành công'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thất bại'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red[600]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết lịch hẹn', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal[700],
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadBooking,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[100],
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.teal))
            : booking == null
            ? const Center(child: Text('Không tìm thấy lịch hẹn', style: TextStyle(fontSize: 18, color: Colors.grey)))
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection('Thông tin khách hàng', [
                    _infoRow('Khách hàng:', booking!.customerName ?? ''),
                    _infoRow('Số điện thoại:', booking!.customerPhone ?? ''),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoSection('Thông tin lịch hẹn', [
                    _infoRow('Dịch vụ:', booking!.serviceName ?? ''),
                    _infoRow('Ngày:', DateFormat('dd/MM/yyyy').format(booking!.date ?? DateTime.now())),
                    _infoRow('Giờ:', booking!.time ?? ''),
                    _infoRow(
                        'Tổng tiền:',
                        booking!.total != null
                            ? '${NumberFormat('#,###', 'vi_VN').format(booking!.total)} VNĐ'
                            : 'Chưa rõ'),
                    _infoRow('Ghi chú:', (booking!.note ?? '').isEmpty ? 'Không có' : booking!.note!),
                    _infoRow(
                      'Tạo lúc:',
                      booking!.createdAt != null
                          ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(booking!.createdAt!))
                          : 'Không rõ',
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildStatusSection(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _updateStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[700],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cập nhật trạng thái', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
        const SizedBox(height: 8),
        ...rows,
      ],
    );
  }

  Widget _buildStatusSection() {
    final availableStatuses = getAvailableStatuses(booking?.status);
    if (!availableStatuses.contains(selectedStatus)) {
      selectedStatus = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Trạng thái lịch hẹn:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedStatus,
              isExpanded: true,
              items: availableStatuses
                  .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedStatus = value;
                  });
                }
              },
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
              dropdownColor: Colors.white,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
              hint: const Text('Chọn trạng thái'),
              disabledHint: Text(booking?.status ?? 'Không xác định'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: TextStyle(color: Colors.grey[800]))),
        ],
      ),
    );
  }
}
