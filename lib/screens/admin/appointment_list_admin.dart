import 'package:flutter/material.dart';

class AppointmentListAdminScreen extends StatelessWidget {
  const AppointmentListAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch hẹn khách hàng')),
      body: const Center(child: Text('Hiển thị các lịch hẹn theo ngày.')),
    );
  }
}