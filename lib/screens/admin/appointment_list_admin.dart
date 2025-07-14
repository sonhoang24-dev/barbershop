import 'dart:async';
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
  Future<List<Booking>>? _futureBookings;
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'Tất cả';
  Timer? _debounce;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
    _searchController.addListener(() => _onSearchChanged(_searchController.text));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookings() async {
    setState(() {
      isLoading = true;
      _futureBookings = ApiService.getBookings(
        search: _searchController.text.trim(),
        status: _selectedStatus == 'Tất cả' ? '' : _selectedStatus,
      );
    });
    await _futureBookings; // Ensure the Future completes
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _fetchBookings());
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Chờ xác nhận':
        return Colors.orange[700]!;
      case 'Đã xác nhận':
        return Colors.blue[700]!;
      case 'Đang thực hiện':
        return Colors.purple[700]!;
      case 'Đã hoàn thành':
        return Colors.green[700]!;
      case 'Đã huỷ':
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  Widget _buildBookingCard(Booking booking, ThemeData theme) {
    final numberFormat = NumberFormat.decimalPattern('vi_VN');
    final statusColor = _getStatusColor(booking.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      elevation: 4,
      shadowColor: Colors.grey.withOpacity(0.3),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final updated = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AppointmentDetailAdminScreen(bookingId: booking.id)),
          );
          if (updated == true) _fetchBookings();
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 140),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.person, color: theme.primaryColor, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking.customerName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.teal[900],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.cut, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.serviceName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd/MM/yyyy').format(booking.date),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    booking.time,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.fiber_manual_record, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Trạng thái: ${booking.status}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              if (booking.total > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.monetization_on, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Tổng: ${numberFormat.format(booking.total)}đ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Tìm tên hoặc SĐT khách hàng',
            hintStyle: const TextStyle(color: Colors.white70, fontSize: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.2),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            prefixIcon: const Icon(Icons.search, color: Colors.white, size: 24),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 24),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            )
                : null,
          ),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          onChanged: _onSearchChanged,
        ),
        backgroundColor: Colors.teal,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedStatus = value;
                _fetchBookings();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Tất cả', child: Text('Tất cả')),
              const PopupMenuItem(
                value: 'Chờ xác nhận',
                child: Text('Chờ xác nhận', style: TextStyle(color: Colors.orange)),
              ),
              const PopupMenuItem(
                value: 'Đã xác nhận',
                child: Text('Đã xác nhận', style: TextStyle(color: Colors.blue)),
              ),
              const PopupMenuItem(
                value: 'Đang thực hiện',
                child: Text('Đang thực hiện', style: TextStyle(color: Colors.purple)),
              ),
              const PopupMenuItem(
                value: 'Đã hoàn thành',
                child: Text('Đã hoàn thành', style: TextStyle(color: Colors.green)),
              ),
              const PopupMenuItem(
                value: 'Đã huỷ',
                child: Text('Đã huỷ', style: TextStyle(color: Colors.red)),
              ),
            ],
            icon: const Icon(Icons.filter_list, color: Colors.white, size: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
            onPressed: _fetchBookings,
          ),
        ],
      ),
      body: FutureBuilder<List<Booking>>(
        future: _futureBookings,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || isLoading) {
            return Center(child: CircularProgressIndicator(color: theme.primaryColor));
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Lỗi: ${snapshot.error}',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _fetchBookings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Thử lại',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          final bookings = snapshot.data ?? [];
          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, color: Colors.grey[500], size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Không có lịch hẹn nào',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _fetchBookings,
            color: theme.primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: bookings.length,
              itemBuilder: (context, index) => _buildBookingCard(bookings[index], theme),
            ),
          );
        },
      ),
    );
  }
}