import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _gender = 'Nam';

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _error;

  bool get _isFilled =>
      _nameController.text.trim().isNotEmpty &&
          _emailController.text.trim().isNotEmpty &&
          _phoneController.text.trim().isNotEmpty &&
          _passwordController.text.trim().isNotEmpty &&
          _confirmPasswordController.text.trim().isNotEmpty;

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (!_isFilled) {
      setState(() => _error = "Vui lòng nhập đầy đủ thông tin");
      return;
    }

    if (password != confirmPassword) {
      setState(() => _error = "Mật khẩu không khớp");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await http.post(
      Uri.parse('http://10.0.2.2/barbershop/backend/auth/register.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'gender': _gender,
        'phone': phone,
      }),
    );

    final data = jsonDecode(res.body);
    setState(() => _loading = false);

    if (data['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đăng ký thành công")),
      );
      Navigator.pop(context);
    } else {
      setState(() => _error = data['message']);
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool obscure = false,
    bool enableToggle = false,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
    VoidCallback? onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        obscuringCharacter: '*',
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: Colors.teal[700]) : null,
          suffixIcon: enableToggle
              ? IconButton(
            icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.teal),
            onPressed: onToggle,
          )
              : null,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB2DFDB), // teal nhạt
      appBar: AppBar(
        title: const Text("Tạo tài khoản", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.teal[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text(
                    "Đăng ký tài khoản mới",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal),
                  ),
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  label: "Họ tên",
                  controller: _nameController,
                  icon: Icons.person,
                ),
                _buildTextField(
                  label: "Email",
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  icon: Icons.email,
                ),
                _buildTextField(
                  label: "Số điện thoại",
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  icon: Icons.phone,
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: InputDecoration(
                    labelText: "Giới tính",
                    prefixIcon: const Icon(Icons.transgender, color: Colors.teal),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ['Nam', 'Nữ'].map((gender) {
                    return DropdownMenuItem(
                        value: gender, child: Text(gender));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _gender = value);
                  },
                ),
                _buildTextField(
                  label: "Mật khẩu",
                  controller: _passwordController,
                  obscure: _obscurePassword,
                  enableToggle: true,
                  onToggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icons.lock,
                ),
                _buildTextField(
                  label: "Nhập lại mật khẩu",
                  controller: _confirmPasswordController,
                  obscure: _obscureConfirmPassword,
                  enableToggle: true,
                  onToggle: () => setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword),
                  icon: Icons.lock_outline,
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.w500),
                  ),
                const SizedBox(height: 12),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                  icon: const Icon(Icons.person_add_alt_1,
                      color: Colors.white),
                  label: const Text(
                    "Đăng ký",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFilled
                        ? Colors.teal[800]
                        : Colors.teal[300],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isFilled ? _register : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
