import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    scaffoldBackgroundColor: const Color(0xFFF6F7FB),

    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFF97316),
      brightness: Brightness.light,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}