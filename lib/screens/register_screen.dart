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
  String? _error;

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
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

  Widget _buildTextField(
      {required String label,
        required TextEditingController controller,
        bool obscure = false,
        TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Tạo tài khoản"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    "Đăng ký tài khoản mới",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(label: "Họ tên", controller: _nameController),
                  _buildTextField(label: "Email", controller: _emailController, keyboardType: TextInputType.emailAddress),
                  _buildTextField(label: "Số điện thoại", controller: _phoneController, keyboardType: TextInputType.phone),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: InputDecoration(
                        labelText: "Giới tính",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['Nam', 'Nữ'].map((gender) {
                        return DropdownMenuItem(value: gender, child: Text(gender));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _gender = value);
                      },
                    ),
                  ),
                  _buildTextField(label: "Mật khẩu", controller: _passwordController, obscure: true),
                  _buildTextField(label: "Nhập lại mật khẩu", controller: _confirmPasswordController, obscure: true),
                  const SizedBox(height: 12),
                  if (_error != null)
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                    ),
                  const SizedBox(height: 12),
                  _loading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.person_add_alt, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      label: const Text("Đăng ký", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      onPressed: _register,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
