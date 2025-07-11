import 'package:flutter/material.dart';

class ManageEmployeesScreen extends StatelessWidget {
  const ManageEmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý nhân viên')),
      body: const Center(child: Text('Hiển thị danh sách nhân viên tại đây.')),
    );
  }
}