import 'package:barbershop_app/screens/customer/customer_home.dart';
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    service = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final rawPrice = service['price'];
    final parsedPrice = double.tryParse(rawPrice.toString()) ?? 0.0;
    print("Service price raw: $rawPrice, parsed: $parsedPrice"); // Debug: Kiểm tra giá thô và sau parse
    _loadEmployees();
    _loadExtras();
    _loadImages();
  }

  Future<void> _loadEmployees() async {
    final res = await http.get(Uri.parse("http://10.0.2.2/barbershop/backend/employees/get_by_service.php?service_id=${service['id'] ?? 0}"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        employees = List<Map<String, dynamic>>.from(data);
      });
    }
  }

  Future<void> _loadExtras() async {
    final res = await http.get(Uri.parse("http://10.0.2.2/barbershop/backend/services/get_extras.php?service_id=${service['id'] ?? 0}"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        extraServices = data.map<Map<String, dynamic>>((e) => {
          "id": e['id'],
          "name": e['name'] ?? '',
          "price": (double.tryParse(e['price'].toString()) ?? 0).round(),
          "selected": false,
        }).toList();
      });
    }
  }

  Future<void> _loadImages() async {
    final res = await http.get(Uri.parse("http://10.0.2.2/barbershop/backend/services/get_images.php?service_id=${service['id'] ?? 0}"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        serviceImages = List<String>.from(data.map((e) => e['image'].toString()));
      });
    }
  }

  Future<void> _loadBookedTimes(int employeeId) async {
    final res = await http.get(Uri.parse("http://10.0.2.2/barbershop/backend/employees/get_booked_times.php?employee_id=$employeeId"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        bookedTimes = List<String>.from(data);
      });
    }
  }

  List<String> _generateTimeSlots(String workingHours) {
    final parts = workingHours.split('-');
    if (parts.length != 2) return [];

    final start = TimeOfDay(
      hour: int.parse(parts[0].split(':')[0]),
      minute: int.parse(parts[0].split(':')[1]),
    );
    final end = TimeOfDay(
      hour: int.parse(parts[1].split(':')[0]),
      minute: int.parse(parts[1].split(':')[1]),
    );

    final slots = <String>[];
    int hour = start.hour;

    while (hour < end.hour) {
      if (hour < 12 || hour >= 13) {
        final time = '${hour.toString().padLeft(2, '0')}:00';
        if (!bookedTimes.contains(time)) {
          slots.add(time);
        }
      }
      hour++;
    }
    return slots;
  }

  int _calculateTotal() {
    // Parse giá từ service['price'] thành số thực, sau đó làm tròn
    double basePrice = double.tryParse(service['price'].toString()) ?? 0.0;
    int total = basePrice.round();
    print("Base price raw: ${service['price']}, parsed: $basePrice, total: $total"); // Debug: Kiểm tra giá
    for (var extra in extraServices) {
      if (extra['selected'] == true) {
        total += (extra['price'] as int);
        print("Added extra: ${extra['name']} - ${extra['price']}"); // Debug: Kiểm tra giá dịch vụ thêm
      }
    }
    return total < 0 ? 0 : total; // Tránh giá trị âm
  }

  String _formatCurrency(dynamic amount) {
    // Parse thành số thực, làm tròn và định dạng chỉ số nguyên
    double parsedAmount = double.tryParse(amount.toString()) ?? 0.0;
    print("Formatted amount raw: $amount, parsed: $parsedAmount"); // Debug: Kiểm tra giá trị
    return NumberFormat("#,##0", "vi_VN").format(parsedAmount.round());
  }

  Future<void> _saveBookingToServer() async {
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
    };

    final response = await http.post(
      Uri.parse("http://10.0.2.2/barbershop/backend/services/save_booking.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (data['success'] == true) {
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
      appBar: AppBar(title: const Text('Đặt lịch'), backgroundColor: Colors.teal),
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
                      "http://10.0.2.2/barbershop/backend/${serviceImages[index]}",
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
            const Text("Thông tin khách hàng", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Họ và tên", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Số điện thoại", border: OutlineInputBorder()),
            ),
            const Divider(height: 32),
            const Text("Chọn dịch vụ đi kèm", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...extraServices.map((item) => CheckboxListTile(
              title: Text("${item['name']} (+${_formatCurrency(item['price'])}đ)"),
              value: item['selected'],
              onChanged: (val) {
                setState(() => item['selected'] = val ?? false);
              },
            )),
            const SizedBox(height: 12),
            Text("Tổng cộng: ${_formatCurrency(_calculateTotal())} đ",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            const Divider(height: 32),
            const Text("Chọn nhân viên", style: TextStyle(fontWeight: FontWeight.bold)),
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
                  orElse: () => {'full_name': '', 'working_hours': '08:00-17:00'},
                );
                selectedEmployeeName = selectedEmp['full_name'];
                await _loadBookedTimes(value!);
                timeSlots = _generateTimeSlots(selectedEmp['working_hours'] ?? '08:00-17:00');
                selectedTime = null;
                setState(() {});
              },
            ),
            if (selectedEmployeeId != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Chọn thời gian", style: TextStyle(fontWeight: FontWeight.bold)),
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
                hintText: "Ví dụ: Giữ kiểu tóc cũ, muốn massage lâu...",
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
              icon: const Icon(Icons.check_circle),
              label: const Text("Xác nhận đặt lịch"),
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