import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

/// Hàm khởi tạo service chạy nền
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: false,
      autoStart: true,
    ),
    iosConfiguration: IosConfiguration(),
  );

  service.startService();
}

/// Hàm chạy khi service bắt đầu
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Khởi tạo thông báo
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Kiểm tra đơn mới mỗi 5 giây
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    if (service is AndroidServiceInstance && !(await service.isForegroundService())) {
      return;
    }
    await checkNewBookingsAndNotify();
  });
}

/// Hàm kiểm tra đơn mới và hiển thị thông báo nếu có
Future<void> checkNewBookingsAndNotify() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final url = Uri.parse("https://htdvapple.site/barbershop/backend/services/get_bookings_by_user.php?user_id=0");

    final res = await http.get(url);
    if (res.statusCode != 200) return;

    final json = jsonDecode(res.body);
    if (json['success'] != true || json['data'] == null) return;

    final List bookings = json['data'];
    final newBookingIds = bookings.map((e) => e['id'].toString()).toList();

    final oldIds = prefs.getStringList('notified_booking_ids') ?? [];

    final newOnes = bookings.where((b) => !oldIds.contains(b['id'].toString())).toList();

    for (final booking in newOnes) {
      final customer = booking['customer_name'] ?? 'Khách hàng';
      final service = booking['service'] ?? 'dịch vụ';

      await flutterLocalNotificationsPlugin.show(
        0,
        'Đặt lịch mới',
        '$customer vừa đặt $service',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'booking_channel_id',
            'Booking Notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }

    await prefs.setStringList('notified_booking_ids', newBookingIds);
  } catch (e) {
    print('[Background] Lỗi khi kiểm tra đặt lịch: $e');
  }
}
