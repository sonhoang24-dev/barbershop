import 'package:flutter/material.dart';
import 'manage_employees.dart';
import 'manage_services.dart';
import 'appointment_list_admin.dart';
import 'statistics_dashboard.dart';
import 'update_profile.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Quản Trị'),
        centerTitle: true,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildTile(
            context,
            icon: Icons.people,
            label: 'Quản lý nhân viên',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const ManageEmployeesScreen(),
              ));
            },
          ),
          _buildTile(
            context,
            icon: Icons.design_services,
            label: 'Quản lý dịch vụ',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const ManageServicesScreen(),
              ));
            },
          ),
          _buildTile(
            context,
            icon: Icons.calendar_today,
            label: 'Lịch đặt hẹn',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const AppointmentListAdminScreen(),
              ));
            },
          ),
          _buildTile(
            context,
            icon: Icons.bar_chart,
            label: 'Thống kê - báo cáo',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const StatisticsDashboardScreen(),
              ));
            },
          ),
          _buildTile(
            context,
            icon: Icons.person,
            label: 'Hồ sơ của tôi',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const UpdateProfileScreen(),
              ));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: Theme.of(context).primaryColor),
              const SizedBox(height: 12),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
