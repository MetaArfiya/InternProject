import 'package:flutter/material.dart';

import 'screens/Screens_Landing/landing_page.dart';
import 'theme/app_theme.dart';
//import 'sections/admin/admin_verification_screen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SayaBantu.Com',
      theme: AppTheme.lightTheme,
      home: const LandingPage(),
      //home: const AdminVerificationScreen(),
    );
  }
}