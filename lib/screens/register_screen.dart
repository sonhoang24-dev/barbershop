import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

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
  bool _agreedToTerms = false;
  String? _error;

  bool get _isFilled =>
      _nameController.text.trim().isNotEmpty &&
          _emailController.text.trim().isNotEmpty &&
          _phoneController.text.trim().isNotEmpty &&
          _passwordController.text.trim().isNotEmpty &&
          _confirmPasswordController.text.trim().isNotEmpty;

  bool get _isValid => _isFilled && _agreedToTerms;

  Future<void> _register() async {
    if (!_isFilled) {
      String errorMessage = "Vui lòng điền đầy đủ: ";
      if (_nameController.text.trim().isEmpty) errorMessage += "Họ tên, ";
      if (_emailController.text.trim().isEmpty) errorMessage += "Email, ";
      if (_phoneController.text.trim().isEmpty) errorMessage += "Số điện thoại, ";
      if (_passwordController.text.trim().isEmpty) errorMessage += "Mật khẩu, ";
      if (_confirmPasswordController.text.trim().isEmpty) errorMessage += "Xác nhận mật khẩu, ";
      errorMessage = errorMessage.substring(0, errorMessage.length - 2);
      setState(() => _error = errorMessage);
      return;
    }

    final email = _emailController.text.trim();
    if (!RegExp(r'^[\w-\.]+@gmail\.com$').hasMatch(email)) {
      setState(() => _error = "Email phải có định dạng hợp lệ và kết thúc bằng @gmail.com");
      return;
    }

    final phone = _phoneController.text.trim();
    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      setState(() => _error = "Số điện thoại phải có đúng 10 số");
      return;
    }

    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      setState(() => _error = "Mật khẩu và xác nhận mật khẩu không khớp");
      return;
    }

    if (_passwordController.text.trim().length < 6) {
      setState(() => _error = "Mật khẩu phải có ít nhất 6 ký tự");
      return;
    }

    if (!_agreedToTerms) {
      setState(() => _error = "Vui lòng đồng ý với điều khoản và điều kiện");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final res = await http.post(
        Uri.parse('https://htdvapple.site/barbershop/backend/auth/register.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'gender': _gender,
          'phone': phone,
        }),
      );

      print('API Response Status: ${res.statusCode}');
      print('API Response Body: ${res.body}');

      final data = jsonDecode(res.body);
      setState(() => _loading = false);

      if (data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đăng ký thành công"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        setState(() => _error = data['message'] ?? 'Đăng ký thất bại, không có thông tin lỗi');
      }
    } catch (e) {
      print('Error during registration: $e');
      setState(() {
        _loading = false;
        _error = "Lỗi kết nối: $e";
      });
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
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        obscuringCharacter: '*',
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        onChanged: (value) {
          setState(() {
            _error = null;
          });
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: Colors.teal[600]) : null,
          suffixIcon: enableToggle
              ? IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.teal[600]),
            onPressed: onToggle,
          )
              : null,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.teal[600]!, width: 2),
          ),
        ),
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Điều khoản & Điều kiện",
            style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text("1. Chấp nhận dịch vụ: Khi sử dụng ứng dụng, bạn đồng ý tuân thủ các quy định của Barbershop App."),
              SizedBox(height: 8),
              Text("2. Đặt lịch: Bạn phải đặt lịch trước ít nhất 2 giờ và chịu trách nhiệm hủy lịch đúng thời gian nếu cần."),
              SizedBox(height: 8),
              Text("3. Thanh toán: Tất cả các dịch vụ phải được thanh toán trước hoặc tại cửa hàng theo quy định."),
              SizedBox(height: 8),
              Text("4. Quyền riêng tư: Thông tin cá nhân của bạn sẽ được bảo mật theo chính sách bảo mật của chúng tôi."),
              SizedBox(height: 8),
              Text("5. Hủy dịch vụ: Hủy lịch không đúng giờ có thể bị tính phí 50% giá dịch vụ."),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng", style: TextStyle(color: Colors.teal)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: const Text("Tạo tài khoản", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.teal[600],
        elevation: 4,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: Text(
                      "Đăng ký tài khoản",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildTextField(label: "Họ tên", controller: _nameController, icon: Icons.person),
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
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: InputDecoration(
                        labelText: "Giới tính",
                        prefixIcon: const Icon(Icons.transgender, color: Colors.teal),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.teal[600]!, width: 2),
                        ),
                      ),
                      items: ['Nam', 'Nữ'].map((gender) {
                        return DropdownMenuItem(value: gender, child: Text(gender));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _gender = value);
                      },
                    ),
                  ),
                  _buildTextField(
                    label: "Mật khẩu",
                    controller: _passwordController,
                    obscure: _obscurePassword,
                    enableToggle: true,
                    onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icons.lock,
                  ),
                  _buildTextField(
                    label: "Nhập lại mật khẩu",
                    controller: _confirmPasswordController,
                    obscure: _obscureConfirmPassword,
                    enableToggle: true,
                    onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    icon: Icons.lock_outline,
                  ),
                  const SizedBox(height: 15),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        children: [
                          const TextSpan(text: "Tôi đồng ý với "),
                          TextSpan(
                            text: "Điều khoản & điều kiện",
                            style: const TextStyle(
                              color: Colors.teal,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()..onTap = _showTermsDialog,
                          ),
                        ],
                      ),
                    ),
                    value: _agreedToTerms,
                    onChanged: (value) {
                      if (value != null) setState(() => _agreedToTerms = value);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.teal[600],
                    checkColor: Colors.white,
                    tileColor: Colors.grey[50],
                  ),
                  const SizedBox(height: 15),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  _loading
                      ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                      : ElevatedButton(
                    onPressed: _isValid ? _register : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isValid ? Colors.teal[600] : Colors.grey[400],
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 5,
                    ),
                    child: const Text(
                      "Đăng ký",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
