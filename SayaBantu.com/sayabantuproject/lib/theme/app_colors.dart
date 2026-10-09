import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primaryTeal = Color(0xFF0F766E);
  static const Color darkTeal = Color(0xFF134E4A);
  static const Color mint = Color(0xFF2DD4BF);
  static const Color lightMint = Color(0xFFCCFBF1);

  // Card
  static const Color cardBg = Color(0xFF104E49);
  static const Color cardBgSoft = Color(0xFF0D5B55);
  static const Color cardBgHover = Color(0xFF176B62);
  static const Color cardBgItem = Color(0xFF155B55);
  static const Color avatarBg = Color(0xFF23766D);

  // Functional
  static const Color starYellow = Color(0xFFFBBF24);
  static const Color onlineGreen = Color(0xFF4ADE80);
  static const Color shadow = Color(0xFF042F2E);

  // Base
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Grey
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);

  // Alias
  static const Color primary = primaryTeal;
  static const Color grey = grey500;

  // ============================================================
  // SECTION BACKGROUNDS — pola alternate terang/gelap
  // ============================================================
  static const Color sectionLight = Color(0xFFFFFFFF);     // putih
  static const Color sectionAltLight = Color(0xFFF0FDFA);
  static const Color sectionDark = darkTeal;               // teal solid
  static const Color sectionGradientStart = darkTeal;
  static const Color sectionGradientEnd = primaryTeal;
}