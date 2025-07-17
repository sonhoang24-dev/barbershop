import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'booking_list_screen.dart';
import 'shop_info_screen.dart';
import 'profile_screen.dart';

class CustomerHome extends StatefulWidget {
  final int initialTab;
  const CustomerHome({super.key, this.initialTab = 0});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  late int _currentIndex;
  String _userName = "customer";
  bool _hasNewNotifications = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _loadUserName();
    _loadNotificationStatus();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('name') ?? 'customer';
    });
  }

  Future<void> _loadNotificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationStrings = prefs.getStringList('notifications') ?? [];
    final viewedNotifications = prefs.getStringList('viewed_notifications') ?? [];
    setState(() {
      _hasNewNotifications = notificationStrings
          .map((n) => jsonDecode(n) as Map<String, dynamic>)
          .any((n) => !viewedNotifications.contains(n['timestamp']));
    });
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 1) {
      _loadNotificationStatus();
    }
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return BookingListScreen(
          onNotificationChanged: _loadNotificationStatus, // Sử dụng đúng tên tham số
        );
      case 2:
        return const ShopInfoScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildScreen(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: _onTabSelected,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Trang chủ",
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.history),
                if (_hasNewNotifications)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            label: "Lịch sử",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: "Cửa hàng",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Tài khoản",
          ),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}