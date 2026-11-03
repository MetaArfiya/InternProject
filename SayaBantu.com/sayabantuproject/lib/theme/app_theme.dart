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
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStatePropertyAll(Color(0xFFF8FAFC)),
      headingTextStyle: TextStyle(
        color: Color(0xFF475569),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
      dataTextStyle: TextStyle(
        color: Color(0xFF334155),
        fontSize: 13,
      ),
      headingRowHeight: 48,
      dataRowMinHeight: 56,
      dataRowMaxHeight: 88,
      horizontalMargin: 20,
      columnSpacing: 24,
      dividerThickness: 0.6,
    ),
  );
}
