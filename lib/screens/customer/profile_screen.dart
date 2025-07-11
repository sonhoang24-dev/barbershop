import 'dart:convert';
import 'package:barbershop_app/screens/customer/update_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _email = '';
  String _phone = '';
  String _gender = '';
  String? _avatarBase64;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('name') ?? '';
      _email = prefs.getString('email') ?? '';
      _phone = prefs.getString('phone') ?? '';
      _gender = prefs.getString('gender') ?? '';
      _avatarBase64 = prefs.getString('avatar');
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Widget _buildAvatar() {
    try {
      if (_avatarBase64 != null && _avatarBase64!.isNotEmpty) {
        final bytes = base64Decode(_avatarBase64!);
        return CircleAvatar(
          radius: 65,
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: 60,
            backgroundImage: MemoryImage(bytes),
          ),
        );
      }
    } catch (_) {
      // nếu lỗi giải mã ảnh
      return const CircleAvatar(
        radius: 65,
        backgroundColor: Colors.white,
        child: CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey,
          child: Icon(Icons.error, color: Colors.red),
        ),
      );
    }

    // fallback khi không có avatar
    return const CircleAvatar(
      radius: 65,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: 60,
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, size: 60, color: Colors.white),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w400)),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : 'Chưa cập nhật',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Thông tin cá nhân',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff0f2027), Color(0xff203a43), Color(0xff2c5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                _buildAvatar(),
                const SizedBox(height: 15),
                Text(
                  _name.isNotEmpty ? _name : "Tên người dùng",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                _buildInfoTile(Icons.phone, 'Số điện thoại', _phone),
                _buildInfoTile(Icons.email, 'Email', _email),
                _buildInfoTile(Icons.wc, 'Giới tính', _gender),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const UpdateProfileScreen()),
                    );
                    if (result == true) _loadProfile();
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("Chỉnh sửa thông tin"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    backgroundColor: Colors.lightBlueAccent.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
