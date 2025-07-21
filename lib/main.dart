import 'dart:async';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:Barbershopdht/screens/admin/admin_dashboard.dart';
import 'package:Barbershopdht/screens/customer/booking_form_screen.dart';
import 'package:Barbershopdht/screens/login_screen.dart';
import 'package:Barbershopdht/screens/register_screen.dart';
import 'package:Barbershopdht/screens/customer/customer_home.dart';
import 'package:Barbershopdht/screens/splash_screen.dart';
import 'package:Barbershopdht/widgets/connectivity_wrapper.dart';
import 'package:Barbershopdht/services/notification_service.dart';
import 'package:workmanager/workmanager.dart';
import 'package:Barbershopdht/services/background_service.dart';




void main() async{
  WidgetsFlutterBinding.ensureInitialized();



  await requestNotificationPermission();// xin thông báo
  timeago.setLocaleMessages('vi', timeago.ViMessages());
  await initializeLocalNotifications();
  await initializeService(); // <-- chạy dịch vụ nền

  runApp(const BarbershopApp());
}

class BarbershopApp extends StatelessWidget {
  const BarbershopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barbershop App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const CustomerHome(),
        '/booking_form': (context) => BookingFormScreen(),
        '/admin': (context) => const AdminDashboard(),
      },

      builder: (context, child) {
        return ConnectivityWrapper(child: child!);
      },
    );
  }
}

