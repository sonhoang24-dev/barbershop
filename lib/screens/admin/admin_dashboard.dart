import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Barbershopdht/screens/admin/review_list_admin.dart';
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'Trang Quản Trị',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Đăng xuất',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
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
              color: Colors.orangeAccent,
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, size: 34, color: color),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
