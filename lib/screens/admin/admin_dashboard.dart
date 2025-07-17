import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barbershop_app/screens/admin/review_list_admin.dart';
import 'manage_employees.dart';
import 'manage_services.dart';
import 'appointment_list_admin.dart';
import 'statistics_dashboard.dart';
import 'update_profile.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Trang Quản Trị', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.teal.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildTile(
              context,
              icon: Icons.people_alt_rounded,
              label: 'Nhân viên',
              color: Colors.blueAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageEmployeesScreen()),
              ),
            ),
            _buildTile(
              context,
              icon: Icons.design_services,
              label: 'Dịch vụ',
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageServicesScreen()),
              ),
            ),
            _buildTile(
              context,
              icon: Icons.calendar_month,
              label: 'Lịch đặt hẹn',
              color: Colors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppointmentListAdminScreen()),
              ),
            ),
            _buildTile(
              context,
              icon: Icons.reviews,
              label: 'Xem đánh giá',
              color: Colors.pinkAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReviewListAdminScreen()),
              ),
            ),
            _buildTile(
              context,
              icon: Icons.bar_chart,
              label: 'Thống kê',
              color: Colors.deepPurple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatisticsDashboardScreen()),
              ),
            ),
            _buildTile(
              context,
              icon: Icons.account_circle,
              label: 'Hồ sơ của tôi',
              color: Colors.teal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UpdateProfileAdminScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
      BuildContext context, {
        required IconData icon,
        required String label,
        required Color color,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
