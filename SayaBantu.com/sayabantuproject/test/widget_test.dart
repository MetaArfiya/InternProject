import 'package:flutter/material.dart';
import 'package:sayabantu_project/screens/Screens_Landing/landing_page.dart';
import 'package:sayabantu_project/theme/app_theme.dart';

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
    );
  }
}