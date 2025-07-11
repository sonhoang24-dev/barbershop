import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'customer/customer_home.dart';
import 'admin/admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = "Vui lòng nhập email và mật khẩu.");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final url = Uri.parse('http://10.0.2.2/barbershop/backend/auth/login.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);
      if (data['success']) {
        final user = data['user'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('id', user['id']);
        await prefs.setString('name', user['name'] ?? '');
        await prefs.setString('email', user['email'] ?? '');
        await prefs.setString('role', user['role'] ?? 'customer');
        if (user['phone'] != null) await prefs.setString('phone', user['phone']);
        if (user['gender'] != null) await prefs.setString('gender', user['gender']);
        if (user['avatar'] != null) await prefs.setString('avatar', user['avatar']);

        // Điều hướng theo phân quyền
        if (user['role'] == 'admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CustomerHome()));
        }
      } else {
        setState(() => _error = data['message'] ?? "Đăng nhập thất bại");
      }
    } catch (e) {
      setState(() => _error = "Không kết nối được máy chủ");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff1e1e2c),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle, size: 100, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                "Đăng nhập hệ thống",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 32),
              _buildInputField(_emailController, Icons.email, "Email", false),
              const SizedBox(height: 16),
              _buildInputField(_passwordController, Icons.lock, "Mật khẩu", true),
              const SizedBox(height: 16),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Đăng nhập", style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    child: const Text("Đăng ký", style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                    },
                  ),
                  const Text("|", style: TextStyle(color: Colors.white70)),
                  TextButton(
                    child: const Text("Quên mật khẩu?", style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, IconData icon, String hint, bool obscure) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
