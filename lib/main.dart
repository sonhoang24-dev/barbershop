import 'package:barbershop_app/screens/customer/booking_form_screen.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/customer/customer_home.dart';

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
          '/': (context) => const LoginScreen(),
          '/login': (context) => const LoginScreen(), // <- thêm dòng này
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const CustomerHome(),
          '/booking_form': (context) => BookingFormScreen(),
          '/admin': (context) =>
          const Scaffold(body: Center(child: Text("Dashboard Admin"))),
        }

    );
  }
}
