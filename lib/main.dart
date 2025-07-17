import 'package:Barbershopdht/screens/admin/admin_dashboard.dart';
import 'package:Barbershopdht/screens/customer/booking_form_screen.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/customer/customer_home.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const BarbershopApp());
}

class BarbershopApp extends StatelessWidget {
  const BarbershopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Barbershop App',
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(), // Sử dụng SplashScreen
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const CustomerHome(),
          '/booking_form': (context) => BookingFormScreen(),
          '/admin': (context) => const AdminDashboard(),
        }

    );
  }
}