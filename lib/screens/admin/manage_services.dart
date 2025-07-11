import 'package:flutter/material.dart';

class ManageServicesScreen extends StatelessWidget {
  const ManageServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý dịch vụ')),
      body: const Center(child: Text('Hiển thị danh sách dịch vụ tại đây.')),
    );
  }
}
