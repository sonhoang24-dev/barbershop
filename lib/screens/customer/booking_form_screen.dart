import 'package:Barbershopdht/screens/customer/customer_home.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({super.key});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  late Map<String, dynamic> service;
  int? selectedEmployeeId;
  String? selectedEmployeeName;
  String? selectedTime;
  final noteController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  List<Map<String, dynamic>> employees = [];
  List<Map<String, dynamic>> extraServices = [];
  List<String> timeSlots = [];
  List<String> serviceImages = [];
  List<String> bookedTimes = [];

  @override
  void initState() {
    super.initState();
    _loadCustomerInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    service = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _loadEmployees();
    _loadExtras();
    _loadImages();
  }

  Future<void> _loadCustomerInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final String? customerName = prefs.getString('name');
    final String? customerPhone = prefs.getString('phone');

    setState(() {
      if (customerName != null && customerName.isNotEmpty) {
        nameController.text = customerName;
      }
      if (customerPhone != null && customerPhone.isNotEmpty) {
        phoneController.text = customerPhone;
      }
    });
  }

  Future<void> _saveCustomerInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', nameController.text.trim());
    await prefs.setString('phone', phoneController.text.trim());
  }

  Future<void> _loadEmployees() async {
    final res = await http.get(Uri.parse("https://htdvapple.site/barbershop/backend/employees/get_by_service.php?service_id=${service['id'] ?? 0}"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        employees = List<Map<String, dynamic>>.from(data);
      });
    }
  }

  Future<void> _loadExtras() async {
    final res = await http.get(Uri.parse("https://htdvapple.site/barbershop/backend/services/get_extras.php?service_id=${service['id'] ?? 0}"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        final newExtras = data.map<Map<String, dynamic>>((e) {
          final existing = extraServices.firstWhere(
                (es) => es['id'] == e['id'],
            orElse: () => {'id': e['id'], 'selected': false},
          );
          return {
            "id": e['id'],
            "name": e['name'] ?? '',
            "price": (double.tryParse(e['price'].toString()) ?? 0).round(),
            "selected": existing['selected'] ?? false,
          };
        }).toList();
        extraServices = newExtras;
      });
    }
  }

  Future<void> _loadImages() async {
    final res = await http.get(Uri.parse("https://htdvapple.site/barbershop/backend/services/get_images.php?service_id=${service['id'] ?? 0}"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        serviceImages = List<String>.from(data.map((e) => e['image'].toString()));
      });
    }
  }

  Future<void> _loadBookedTimes(int employeeId) async {
    final res = await http.get(Uri.parse("https://htdvapple.site/barbershop/backend/employees/get_booked_times.php?employee_id=$employeeId"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        bookedTimes = List<String>.from(data);
        timeSlots = _generateTimeSlots('');
        selectedTime = null;
      });
    }
  }

  List<String> _generateTimeSlots(String workingHours) {
    // Các khung giờ cố định theo yêu cầu
    final List<Map<String, int>> timeRanges = [
      {'startHour': 8, 'startMinute': 0, 'endHour': 12, 'endMinute': 0}, // Sáng: 8:00-11:30
      {'startHour': 13, 'startMinute': 0, 'endHour': 17, 'endMinute': 0}, // Chiều: 13:00-16:30
      {'startHour': 18, 'startMinute': 0, 'endHour': 22, 'endMinute': 0}, // Tối: 18:00-21:30
    ];

    final slots = <String>[];

    for (var range in timeRanges) {
      int hour = range['startHour']!;
      int minute = range['startMinute']!;
      final endHour = range['endHour']!;
      final endMinute = range['endMinute']!;

      while (hour < endHour || (hour == endHour && minute < endMinute)) {
        final time = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        if (!bookedTimes.contains(time)) {
          slots.add(time);
        }
        minute += 30;
        if (minute >= 60) {
          minute -= 60;
          hour += 1;
        }
      }
    }

    return slots;
  }

  int _calculateTotal() {
    double basePrice = double.tryParse(service['price'].toString()) ?? 0.0;
    int total = basePrice.round();
    for (var extra in extraServices) {
      if (extra['selected'] == true) {
        total += (extra['price'] as int);
      }
    }
    return total < 0 ? 0 : total;
  }

  String _formatCurrency(dynamic amount) {
    double parsedAmount = double.tryParse(amount.toString()) ?? 0.0;
    return NumberFormat("#,##0", "vi_VN").format(parsedAmount.round());
  }

  Future<bool> _checkBookingConflict() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('id') ?? 0;
    final currentDate = DateTime.now().toIso8601String().split('T')[0];
    final selectedServiceId = service['id'] ?? 0;
    final selectedEmployeeId = this.selectedEmployeeId ?? 0;
    final selectedTimeSlot = selectedTime ?? '';

    final res = await http.get(
      Uri.parse("https://htdvapple.site/barbershop/backend/services/get_bookings_by_user.php?user_id=$userId"),
    );

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      if (json['success'] == true && json['data'] is List) {
        final List<Map<String, dynamic>> existingBookings = List<Map<String, dynamic>>.from(json['data']);

        for (var booking in existingBookings) {
          final bookingStatus = booking['status'] ?? '';
          final bookingDate = booking['date'] ?? '';
          final bookingTime = booking['time']?.substring(0, 5) ?? '';
          final bookingServiceId = booking['service_id'] ?? 0;
          final bookingEmployeeId = booking['employee_id'] ?? 0;

          if (bookingDate == currentDate) {
            if (bookingServiceId == selectedServiceId && bookingEmployeeId != selectedEmployeeId) {
              if (['Chờ xác nhận', 'Đã xác nhận', 'Đang thực hiện'].contains(bookingStatus)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Bạn đã có đơn dịch vụ này của nhân viên khác."),
                    backgroundColor: Colors.red,
                  ),
                );
                return false;
              }
            }
            if (bookingServiceId == selectedServiceId && bookingTime != selectedTimeSlot) {
              if (['Chờ xác nhận', 'Đã xác nhận', 'Đang thực hiện'].contains(bookingStatus)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Bạn đã đặt dịch vụ này với trạng thái chưa hoàn thành. Vui lòng chọn khung giờ khác."),
                    backgroundColor: Colors.red,
                  ),
                );
                return false;
              }
            }
            if (bookingServiceId != selectedServiceId && bookingTime == selectedTimeSlot) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Bạn đã có lịch hẹn khác vào khung giờ này. \n Vui lòng chọn khung giờ khác."),
                  backgroundColor: Colors.red,
                ),
              );
              return false;
            }
          }
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lỗi khi kiểm tra lịch hẹn. Vui lòng thử lại."),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _saveBookingToServer() async {
    final isValid = await _checkBookingConflict();
    if (!isValid) return;

    final extras = extraServices
        .where((e) => e['selected'])
        .map((e) => e['name'])
        .toList();
    final total = _calculateTotal();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('id') ?? 0;
    final body = {
      "user_id": userId,
      "customer_name": nameController.text,
      "customer_phone": phoneController.text,
      "service_id": service['id'] ?? 0,
      "employee_id": selectedEmployeeId,
      "time_slot": selectedTime ?? '',
      "note": noteController.text,
      "extras": extras,
      "total_price": total,
      "date": DateTime.now().toIso8601String().split('T')[0],
    };

    final response = await http.post(
      Uri.parse("https://htdvapple.site/barbershop/backend/services/save_booking.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (data['success'] == true) {
      await _saveCustomerInfo();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Thành công"),
          content: const Text("Đặt lịch thành công!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomerHome(initialTab: 1)),
                      (route) => false,
                );
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Lỗi: ${data['message'] ?? 'Không rõ lỗi'}"),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt lịch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
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
                      "https://htdvapple.site/barbershop/backend/${serviceImages[index]}",
                      width: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading image: $error');
                        return const Icon(Icons.error, color: Colors.red);
                      },
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Text(service['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(service['description'] ?? ''),
            const SizedBox(height: 12),
            Text("Giá gốc: ${_formatCurrency(service['price'])} đ",
                style: const TextStyle(fontSize: 16, color: Colors.teal)),
            const Divider(height: 32),
            const Text("Thông tin khách hàng", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF000000))),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Họ và tên",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Số điện thoại",
                border: OutlineInputBorder(),
              ),
            ),
            const Divider(height: 32),
            const Text("Chọn dịch vụ đi kèm", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF000000))),
            const SizedBox(height: 10),
            ...extraServices.map((item) => CheckboxListTile(
              title: Text(
                "${item['name']}\n+${_formatCurrency(item['price'])}đ",
                style: TextStyle(height: 1.3),
              ),
              value: item['selected'],
              onChanged: (val) {
                setState(() => item['selected'] = val ?? false);
              },
            )),
            const SizedBox(height: 12),
            Text("Tổng cộng: ${_formatCurrency(_calculateTotal())} đ",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C))),
            const Divider(height: 32),
            const Text("Chọn nhân viên", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF000000))),
            DropdownButton<int>(
              hint: const Text("Chọn nhân viên"),
              value: selectedEmployeeId,
              isExpanded: true,
              items: employees.map((e) => DropdownMenuItem<int>(
                value: int.tryParse(e['id'].toString()),
                child: Text(e['full_name'] ?? ''),
              )).toList(),
              onChanged: (value) async {
                selectedEmployeeId = value;
                final selectedEmp = employees.firstWhere(
                      (e) => int.tryParse(e['id'].toString()) == value,
                  orElse: () => {'full_name': ''},
                );
                selectedEmployeeName = selectedEmp['full_name'];
                await _loadBookedTimes(value!);
                setState(() {});
              },
            ),
            if (selectedEmployeeId != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Chọn thời gian", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF000000))),
                  const SizedBox(height: 8),
                  if (timeSlots.isEmpty)
                    const Text(
                      "Không còn thời gian trống trong hôm nay!",
                      style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      children: timeSlots.map((time) => ChoiceChip(
                        label: Text(time),
                        selected: selectedTime == time,
                        onSelected: (_) => setState(() => selectedTime = time),
                      )).toList(),
                    ),
                ],
              ),
            const SizedBox(height: 20),
            const Text("Ghi chú (nếu có)"),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () async {
                final phone = phoneController.text.trim();

                if (selectedEmployeeId == null || selectedTime == null ||
                    nameController.text.isEmpty || phone.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Vui lòng nhập đầy đủ thông tin khách hàng, nhân viên và thời gian!"),
                      backgroundColor: Colors.red,
                    ));
                  }
                  return;
                }
                if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Số điện thoại phải gồm đúng 10 chữ số!"),
                      backgroundColor: Colors.red,
                    ));
                  }
                  return;
                }
                await _saveBookingToServer();
              },
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text("Xác nhận đặt lịch", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            )
          ],
        ),
      ),
    );
  }
}