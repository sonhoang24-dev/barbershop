import 'package:flutter/material.dart';

class UpdateProfileScreen extends StatelessWidget {
  const UpdateProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cập nhật hồ sơ quản lý')),
      body: const Center(child: Text('Form cập nhật thông tin cá nhân.')),
    );
  }
}
