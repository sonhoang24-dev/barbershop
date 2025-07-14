import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class StatisticsDashboardScreen extends StatefulWidget {
  const StatisticsDashboardScreen({super.key});

  @override
  State<StatisticsDashboardScreen> createState() => _StatisticsDashboardScreenState();
}

class _StatisticsDashboardScreenState extends State<StatisticsDashboardScreen> {
  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = false;

  int totalBookings = 0;
  double totalRevenue = 0;
  int totalCustomers = 0;
  List<Map<String, dynamic>> topServices = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, now.day - 7);
    endDate = DateTime(now.year, now.month, now.day);
    fetchStats();
  }

  Future<void> fetchStats() async {
    setState(() => isLoading = true);

    final url = Uri.parse('http://10.0.2.2/barbershop/backend/auth/get_dashboard_stats.php?start_date=${startDate!.toIso8601String().substring(0, 10)}&end_date=${endDate!.toIso8601String().substring(0, 10)}');

    try {
      final res = await http.get(url);
      final jsonData = json.decode(res.body);

      if (jsonData['success']) {
        final data = jsonData['data'];
        setState(() {
          totalBookings = data['total_bookings'];
          totalRevenue = double.tryParse(data['total_revenue'].toString()) ?? 0;
          totalCustomers = data['total_customers'];
          topServices = List<Map<String, dynamic>>.from(data['top_services']);
        });
      }
    } catch (e) {
      print("Lỗi khi lấy dữ liệu: $e");
    }

    setState(() => isLoading = false);
  }

  Future<void> pickDate({required bool isStart}) async {
    final initial = isStart ? startDate : endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
      fetchStats();
    }
  }

  String formatCurrency(dynamic value) {
    final parsed = double.tryParse(value.toString()) ?? 0;
    final formatted = NumberFormat("#,##0", "vi_VN").format(parsed);
    return formatted.replaceAll(',', '.');
  }

  Widget buildSummaryCard({required IconData icon, required String title, required String value, required Color color}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo & Thống kê'),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => pickDate(isStart: true),
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      startDate != null
                          ? DateFormat('dd/MM/yyyy').format(startDate!)
                          : 'Từ ngày',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => pickDate(isStart: false),
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      endDate != null
                          ? DateFormat('dd/MM/yyyy').format(endDate!)
                          : 'Đến ngày',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            buildSummaryCard(
              icon: Icons.person,
              title: 'Khách hàng mới',
              value: '$totalCustomers',
              color: Colors.teal,
            ),
            buildSummaryCard(
              icon: Icons.attach_money,
              title: 'Tổng doanh thu',
              value: '${formatCurrency(totalRevenue)} đ',
              color: Colors.green,
            ),
            buildSummaryCard(
              icon: Icons.calendar_today,
              title: 'Tổng đơn đặt',
              value: '$totalBookings',
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 20),
            const Text(
              'Top dịch vụ phổ biến',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            ...topServices.map((s) {
              final rating = s['average_rating'];
              final avgRating = rating != null ? double.tryParse(rating.toString()) ?? 0.0 : 0.0;
              return ListTile(
                leading: const Icon(Icons.star, color: Colors.orange),
                title: Text(s['name']),
                subtitle: Text('Trung bình: ${avgRating.toStringAsFixed(1)} ⭐'),
                trailing: Text('${s['count']} lượt'),
              );
            }),
          ],
        ),
      ),
    );
  }
}