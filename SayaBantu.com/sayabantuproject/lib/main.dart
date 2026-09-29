import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/Screens_Landing/landing_page.dart';
import 'theme/app_theme.dart';

import 'screens/Screens_Partner/partner_main_dashboard.dart';
import 'screens/Screens_super_admin/super_admin_layout.dart';
import 'screens/Screens_admin/admin_layout.dart';
import 'sections/customer/customer_main_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Nilai default dulu — supaya TIDAK PERNAH null
  Widget homePage = const LandingPage();

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final role = (prefs.getString('role') ?? '').trim();

    if (token.isNotEmpty) {
      switch (role) {
        case 'Super Admin':
          homePage = const SuperAdminLayout();
          break;
        case 'Admin':
          homePage = const AdminLayout();
          break;
        case 'Pelanggan':
          homePage = const CustomerMainDashboard();
          break;
        case 'Mitra':
          homePage = const PartnerMainDashboard();
          break;
        default:
          homePage = const LandingPage();
      }
    }
  } catch (e) {
    debugPrint('ERROR DI MAIN: $e');
    // Kalau error apapun → tetap LandingPage
    homePage = const LandingPage();
  }

  runApp(MyApp(homePage: homePage));
}

class MyApp extends StatelessWidget {
  final Widget homePage;

  const MyApp({super.key, required this.homePage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SayaBantu.Com',
      theme: AppTheme.lightTheme,
      home: homePage,
    );
  }
}