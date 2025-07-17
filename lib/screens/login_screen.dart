import 'dart:convert';
import 'dart:io';
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
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onInputChanged);
    _passwordController.addListener(_onInputChanged);
  }

  bool get _isFilled =>
      _emailController.text.trim().isNotEmpty &&
          _passwordController.text.trim().isNotEmpty;

  void _onInputChanged() => setState(() {});

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!_isFilled) {
      setState(() => _error = "Vui lòng nhập email và mật khẩu.");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final url =
    Uri.parse('http://192.168.1.210/barbershop/backend/auth/login.php');

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
        await prefs.setString('raw_password', password);
        await prefs.setString('name', user['name'] ?? '');
        await prefs.setString('email', user['email'] ?? '');
        await prefs.setString('role', user['role'] ?? 'customer');
        if (user['phone'] != null)
          await prefs.setString('phone', user['phone']);
        if (user['gender'] != null)
          await prefs.setString('gender', user['gender']);
        if (user['avatar'] != null)
          await prefs.setString('avatar', user['avatar']);

        if (user['role'] == 'admin') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const AdminDashboard()));
        } else {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const CustomerHome()));
        }
      } else {
        setState(() =>
        _error = data['message'] ?? "Đăng nhập thất bại, vui lòng thử lại.");
      }
    } catch (e) {
      setState(() => _error = "Không kết nối được máy chủ");

      if (e is SocketException) {
        debugPrint('Lỗi mạng: $e');
      } else {
        debugPrint('Lỗi không xác định: $e');
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB2DFDB), // màu teal nhạt
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(
                    'https://down-my.img.susercontent.com/file/e4ac35108840c7dd9ab48e25feb09ff4'),
                backgroundColor: Colors.transparent,
              ),
              const SizedBox(height: 20),
              const Text(
                "Đăng nhập hệ thống",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 32),
              _buildInputField(_emailController, Icons.email, "Email", false),
              const SizedBox(height: 16),
              _buildPasswordField(),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading || !_isFilled ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFilled
                        ? Colors.teal
                        : Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text("Đăng nhập",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    child: const Text("Đăng ký",
                        style: TextStyle(color: Colors.teal)),
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()));
                    },
                  ),
                  const Text("|", style: TextStyle(color: Colors.teal)),
                  TextButton(
                    child: const Text("Quên mật khẩu?",
                        style: TextStyle(color: Colors.teal)),
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, IconData icon,
      String hint, bool obscure) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      obscuringCharacter: '*',
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.teal),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black45),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      obscuringCharacter: '*',
      enableSuggestions: false,
      autocorrect: false,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.lock, color: Colors.teal),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.teal,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        hintText: "Mật khẩu",
        hintStyle: const TextStyle(color: Colors.black45),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }
}
