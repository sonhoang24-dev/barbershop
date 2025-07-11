import 'package:flutter/material.dart';

class StatisticsDashboardScreen extends StatelessWidget {
  const StatisticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Báo cáo & Thống kê')),
      body: const Center(child: Text('Biểu đồ thống kê doanh thu, hiệu suất.')),
    );
  }
}