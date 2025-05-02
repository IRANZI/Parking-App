import 'package:flutter/material.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/home/home_screen.dart';
import 'features/booking/booking_vehicle_info.dart';
import 'features/booking/booking_datetime_picker.dart';
import 'features/booking/booking_payment_screen.dart';
import 'features/admin//admin.dart'; // ✅ Added import
import 'features/staff/staff.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Parking App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/booking/vehicle-info': (context) => const BookingVehicleInfoScreen(),
        '/booking/datetime': (context) => const BookingDateTimePickerScreen(),
        '/payment': (context) => const PaymentScreen(),
        '/admin': (context) => AdminHomePage(), // ✅ Admin route added
        '/staff': (context) => StaffDashboard(), // ✅ Admin route added
      },
    );
  }
}
