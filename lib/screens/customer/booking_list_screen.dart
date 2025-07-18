import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'booking_detail_screen.dart';

class BookingListScreen extends StatefulWidget {
  final VoidCallback? onNotificationChanged;
  const BookingListScreen({super.key, this.onNotificationChanged});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> bookings = [];
  List<Map<String, dynamic>> notifications = [];
  List<String> viewedNotifications = [];
  bool isLoading = true;
  bool hasNewStatus = false;
  Timer? _pollingTimer;
  DateTime? _lastLoadTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBookings();
    _loadNotifications();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadBookings());
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
      _loadNotifications();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadBookings() async {
    final now = DateTime.now();
    if (_lastLoadTime != null && now.difference(_lastLoadTime!).inSeconds < 60) {
      return;
    }
    _lastLoadTime = now;

    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('id') ?? 0;
    final url = Uri.parse("https://htdvapple.site/barbershop/backend/services/get_bookings_by_user.php?user_id=$userId");
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] == true && json['data'] is List) {
          final List<Map<String, dynamic>> newBookings = List<Map<String, dynamic>>.from(json['data']);
          newBookings.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));

          final oldStatusList = prefs.getStringList('booking_status_list') ?? [];
          final Map<String, String> oldStatusMap = {
            for (var status in oldStatusList) status.split(':')[0]: status.split(':')[1]
          };

          final newStatus = newBookings.map((e) => '${e['id']}:${e['status']}').toList();
          final Map<String, String> newStatusMap = {
            for (var status in newStatus) status.split(':')[0]: status.split(':')[1]
          };

          List<Map<String, dynamic>> tempNotifications = List.from(notifications);

          for (var booking in newBookings) {
            final bookingId = booking['id'].toString();
            final newBookingStatus = booking['status'];
            final oldBookingStatus = oldStatusMap[bookingId];

            if (oldBookingStatus != null && oldBookingStatus != newBookingStatus) {
              final serviceName = booking['service'] ?? 'Dịch vụ';
              final date = booking['date'] ?? 'N/A';
              final time = booking['time']?.substring(0, 5) ?? 'N/A';
              final formattedDateTime = _formatBookingDateTime(date, time);
              tempNotifications.add({
                'message': 'Lịch hẹn $serviceName vào $formattedDateTime đã được cập nhật thành: $newBookingStatus',
                'timestamp': DateTime.now().toIso8601String(),
              });
            }
          }

          await prefs.setStringList('booking_status_list', newStatus);
          await prefs.setStringList(
            'notifications',
            tempNotifications.map((n) => jsonEncode(n)).toList(),
          );

          setState(() {
            bookings = newBookings;
            notifications = tempNotifications;
            hasNewStatus = tempNotifications.any((n) => !viewedNotifications.contains(n['timestamp']));
            isLoading = false;
          });

          widget.onNotificationChanged?.call();
        } else {
          setState(() {
            bookings = [];
            isLoading = false;
          });
        }
      } else {
        setState(() => isLoading = false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể tải lịch đặt. Vui lòng kiểm tra kết nối.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e. Vui lòng thử lại sau.'), backgroundColor: Colors.red),
        );
      }
      print('Error: $e');
    }
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationStrings = prefs.getStringList('notifications') ?? [];
    final viewed = prefs.getStringList('viewed_notifications') ?? [];
    setState(() {
      notifications = notificationStrings.map((n) => jsonDecode(n) as Map<String, dynamic>).toList();
      notifications.sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
      viewedNotifications = viewed;
      hasNewStatus = notifications.any((n) => !viewedNotifications.contains(n['timestamp']));
    });
    widget.onNotificationChanged?.call();
  }

  Future<void> _markNotificationsAsViewed() async {
    final prefs = await SharedPreferences.getInstance();
    final viewed = notifications.map((n) => n['timestamp'].toString()).toList();
    await prefs.setStringList('viewed_notifications', viewed);
    setState(() {
      viewedNotifications = viewed;
      hasNewStatus = false;
    });
    widget.onNotificationChanged?.call();
  }

  String _formatBookingDateTime(String date, String time) {
    try {
      if (date.length != 10 || !date.contains('-') || time.length < 5) return 'N/A';
      final dateTime = DateTime.parse('$date $time');
      final formatter = DateFormat('yyyy-MM-dd HH:mm');
      return formatter.format(dateTime);
    } catch (_) {
      return 'N/A';
    }
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      final formatter = DateFormat('yyyy-MM-dd HH:mm');
      return formatter.format(dateTime);
    } catch (_) {
      return 'N/A';
    }
  }

  String _formatCurrency(dynamic amount) {
    try {
      final number = double.tryParse(amount.toString()) ?? 0;
      final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
      return formatter.format(number);
    } catch (_) {
      return '$amount đ';
    }
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'Chờ xác nhận':
        return {'color': Colors.orange, 'icon': Icons.schedule};
      case 'Đã xác nhận':
        return {'color': Colors.blueAccent, 'icon': Icons.verified};
      case 'Đang thực hiện':
        return {'color': Colors.deepPurple, 'icon': Icons.work_history};
      case 'Đã hoàn thành':
        return {'color': Colors.green, 'icon': Icons.task_alt};
      case 'Đã huỷ':
        return {'color': Colors.redAccent, 'icon': Icons.cancel_schedule_send};
      default:
        return {'color': Colors.grey, 'icon': Icons.help_outline};
    }
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông báo'),
        content: SizedBox(
          width: double.maxFinite,
          child: notifications.isEmpty
              ? const Text('Chưa có thông báo nào.')
              : ListView.builder(
            shrinkWrap: true,
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                title: Text(notification['message']),
                subtitle: Text(_formatDateTime(notification['timestamp'])),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Xóa tất cả'),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('notifications');
              await prefs.remove('viewed_notifications');
              setState(() {
                notifications = [];
                viewedNotifications = [];
                hasNewStatus = false;
              });
              if (context.mounted) {
                Navigator.pop(context);
                widget.onNotificationChanged?.call();
              }
            },
          ),
          TextButton(
            child: const Text('Đóng'),
            onPressed: () async {
              await _markNotificationsAsViewed();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch đã đặt'),
        backgroundColor: Colors.teal,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: _showNotificationsDialog,
              ),
              if (hasNewStatus)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${notifications.length - viewedNotifications.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : bookings.isEmpty
          ? const Center(child: Text('Chưa có lịch đặt nào'))
          : ListView.builder(
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          final extras = (booking['extras'] as List<dynamic>?)?.join(', ') ?? '';
          final createdAt = booking['created_at'] ?? '';
          final hasReview = booking['rating'] != null && booking['rating'] is num;
          final statusInfo = _getStatusInfo(booking['status'] ?? 'Không xác định');

          print('Booking $index - Rating: ${booking['rating']}, HasReview: $hasReview');

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              onTap: () async {
                final originalBooking = Map<String, dynamic>.from(booking);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingDetailScreen(
                      booking: Map<String, dynamic>.from(booking),
                      bookingIndex: index,
                    ),
                  ),
                );
                if (result != null && result is Map && result['updated'] == true) {
                  setState(() {
                    if (result['rating'] != null && result['rating'] is num) {
                      bookings[index]['rating'] = result['rating'];
                      print('Updated rating for booking $index: ${bookings[index]['rating']}');
                    }
                    if (result['new_status'] != null && result['new_status'] is String) {
                      bookings[index]['status'] = result['new_status'];
                    }
                  });
                  final date = booking['date'] ?? 'N/A';
                  final time = booking['time']?.substring(0, 5) ?? 'N/A';
                  final formattedDateTime = _formatBookingDateTime(date, time);
                  final newStatus = result['new_status'] ?? 'Không xác định';
                  final message = newStatus == 'Đã huỷ'
                      ? 'Bạn đã hủy lịch hẹn ${booking['service']} vào $formattedDateTime đã được cập nhật thành: $newStatus'
                      : 'Lịch hẹn ${booking['service']} vào $formattedDateTime đã được cập nhật thành: $newStatus';
                  final prefs = await SharedPreferences.getInstance();
                  final tempNotifications = List<Map<String, dynamic>>.from(notifications);
                  tempNotifications.add({
                    'message': message,
                    'timestamp': DateTime.now().toIso8601String(),
                  });
                  await prefs.setStringList(
                    'notifications',
                    tempNotifications.map((n) => jsonEncode(n)).toList(),
                  );
                  setState(() {
                    notifications = tempNotifications;
                    hasNewStatus = true;
                  });
                  widget.onNotificationChanged?.call();
                }
              },
              leading: Icon(
                Icons.event_available,
                color: statusInfo['color'] as Color,
              ),
              title: Text(
                booking['service'] ?? 'Dịch vụ',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ngày giờ: ${_formatBookingDateTime(booking['date'] ?? 'N/A', booking['time'] ?? 'N/A')}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Nhân viên: ${booking['employee'] ?? '---'}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (extras.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Dịch vụ thêm: $extras',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        if ((booking['note'] as String?)?.isNotEmpty ?? false)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Ghi chú: ${booking['note']}',
                              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          'Tổng tiền: ${_formatCurrency(booking['total'])}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (createdAt.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Thời gian đặt: ${_formatDateTime(createdAt)}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    statusInfo['icon'] as IconData,
                    size: 24,
                    color: statusInfo['color'] as Color,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    booking['status'] ?? 'Không xác định',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusInfo['color'] as Color,
                      fontWeight: FontWeight.w500,
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