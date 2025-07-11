import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _message;
  bool _loading = false;

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _message = "Vui lòng nhập email");
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final res = await http.post(
        Uri.parse('http://10.0.2.2/barbershop/backend/auth/forgot_password.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(res.body);
      setState(() => _message = data['message']);
    } catch (e) {
      setState(() => _message = "Không kết nối được đến máy chủ");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Khôi phục mật khẩu")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text("Nhập email để nhận mật khẩu mới:"),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _sendResetEmail,
              child: const Text("Gửi"),
            ),
            const SizedBox(height: 16),
            if (_message != null)
              Text(_message!, style: const TextStyle(color: Colors.blue)),
          ],
        ),
      ),
    );
  }
}
