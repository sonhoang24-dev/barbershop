import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';

class UpdateProfileAdminScreen extends StatefulWidget {
  const UpdateProfileAdminScreen({super.key});

  @override
  State<UpdateProfileAdminScreen> createState() => _UpdateProfileAdminScreenState();
}

class _UpdateProfileAdminScreenState extends State<UpdateProfileAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _gender;
  File? _avatarImage;
  int _userId = 0;
  String? _avatarBase64;
  String? _oldPassword;
  ImageProvider? _avatarProvider;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('id') ?? 0;
      _nameController.text = prefs.getString('name') ?? '';
      _emailController.text = prefs.getString('email') ?? '';
      _phoneController.text = prefs.getString('phone') ?? '';
      _gender = prefs.getString('gender');
      _avatarBase64 = prefs.getString('avatar');
      _oldPassword = prefs.getString('raw_password') ?? '';
      _updateAvatarProvider();
    });
  }

  void _updateAvatarProvider() {
    if (_avatarImage != null) {
      _avatarProvider = FileImage(_avatarImage!);
    } else if (_avatarBase64 != null && _avatarBase64!.isNotEmpty) {
      try {
        _avatarProvider = MemoryImage(base64Decode(_avatarBase64!));
      } catch (_) {
        _avatarProvider = null;
      }
    } else {
      _avatarProvider = null;
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _avatarImage = File(picked.path);
        _updateAvatarProvider();
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text.isNotEmpty && _passwordController.text == _oldPassword) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Mật khẩu mới không được giống mật khẩu cũ"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Mật khẩu mới và nhập lại không khớp"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        String? base64Avatar;

        if (_avatarImage != null) {
          final bytes = await _avatarImage!.readAsBytes();
          base64Avatar = base64Encode(bytes);
        }

        await ApiService.updateProfileBase64(
          id: _userId,
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          gender: _gender,
          newPassword: _passwordController.text.isNotEmpty ? _passwordController.text : null,
          avatarBase64: base64Avatar,
        );

        await prefs.setString('name', _nameController.text);
        await prefs.setString('email', _emailController.text);
        await prefs.setString('phone', _phoneController.text);
        if (_gender != null) await prefs.setString('gender', _gender!);
        if (base64Avatar != null) {
          await prefs.setString('avatar', base64Avatar);
          setState(() {
            _avatarBase64 = base64Avatar;
            _updateAvatarProvider();
          });
        }
        if (_passwordController.text.isNotEmpty) {
          await prefs.setString('raw_password', _passwordController.text);
          setState(() {
            _oldPassword = _passwordController.text;
          });
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật thành công"),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi khi cập nhật: $e")),
        );
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  Widget _buildAvatarPreview() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.white.withOpacity(0.1),
          backgroundImage: _avatarProvider,
          child: _avatarProvider == null
              ? const Icon(Icons.person, size: 60, color: Colors.white70)
              : null,
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: InkWell(
            onTap: _pickAvatar,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt, color: Colors.black, size: 18),
            ),
          ),
        )
      ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          "Cập nhật hồ sơ quản trị",
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Đăng xuất",
            onPressed: _logout,
          )
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.6), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff0f2027), Color(0xff203a43), Color(0xff2c5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            MediaQuery.of(context).padding.top + 80,
            24,
            20,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildAvatarPreview(),
                const SizedBox(height: 30),
                _buildPasswordField("Họ tên", _nameController, isPassword: false, validator: false),
                _buildPasswordField("Email", _emailController, isPassword: false, validator: true),
                _buildPasswordField("Số điện thoại", _phoneController, isPassword: false, validator: false),
                DropdownButtonFormField<String>(
                  value: _gender?.isNotEmpty == true ? _gender : null,
                  decoration: _inputDecoration("Giới tính"),
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: "Nam", child: Text("Nam")),
                    DropdownMenuItem(value: "Nữ", child: Text("Nữ")),
                    DropdownMenuItem(value: "Khác", child: Text("Khác")),
                  ],
                  onChanged: (value) => setState(() => _gender = value),
                ),
                const SizedBox(height: 16),
                _buildPasswordField("Mật khẩu mới (nếu đổi)", _passwordController, isPassword: true),
                _buildPasswordField("Nhập lại mật khẩu mới", _confirmPasswordController, isPassword: true, confirm: true),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.save),
                    label: const Text("Lưu thay đổi"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller,
      {bool isPassword = false, bool validator = false, bool confirm = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? (confirm ? !_isConfirmPasswordVisible : !_isPasswordVisible) : false,
        validator: (value) {
          if (validator && value!.isEmpty) return "Không được để trống";
          if (!isPassword && value!.isEmpty) return "Không được để trống";
          return null;
        },
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(label).copyWith(
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              confirm
                  ? (_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off)
                  : (_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
              color: Colors.white70,
            ),
            onPressed: () {
              setState(() {
                if (confirm) _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                else _isPasswordVisible = !_isPasswordVisible;
              });
            },
          )
              : null,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF64B5F6), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}