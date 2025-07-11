import 'dart:convert';
import 'package:barbershop_app/screens/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'customer/customer_home.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

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
      setState(() => _error = "Vui lòng nhập đầy đủ email và mật khẩu");
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

        // Lưu thông tin vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('id', user['id'] ?? 0);
        await prefs.setString('name', user['name'] ?? '');
        await prefs.setString('email', user['email'] ?? '');
        await prefs.setString('role', user['role'] ?? '');
        if (user['phone'] != null) await prefs.setString('phone', user['phone']);
        if (user['gender'] != null) await prefs.setString('gender', user['gender']);
        if (user['avatar'] != null) await prefs.setString('avatar', user['avatar']);

        // Điều hướng tới màn hình chính
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CustomerHome()),
        );
    } else {
        setState(() => _error = data['message'] ?? "Đăng nhập thất bại");
      }
    } catch (e) {
      setState(() => _error = "Lỗi kết nối đến máy chủ");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff0f2027), Color(0xff203a43), Color(0xff2c5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Icon(Icons.person_pin, size: 100, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  "Chào mừng trở lại!",
                  style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email, color: Colors.white),
                    hintText: "Email",
                    hintStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock, color: Colors.white),
                    hintText: "Mật khẩu",
                    hintStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),

                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.login),
                    label: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Đăng nhập", style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff00c6ff),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _loading ? null : _login,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
