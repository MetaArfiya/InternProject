import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ============================================================
  // 1. BRAND
  // ============================================================
  static const Color primaryTeal = Color(0xFF0F766E);
  static const Color darkTeal = Color(0xFF134E4A);
  static const Color mint = Color(0xFF2DD4BF);
  static const Color lightMint = Color(0xFFCCFBF1);

  // ============================================================
  // 2. CARD / SURFACE
  // ============================================================
  static const Color cardBg = Color(0xFF104E49);
  static const Color cardBgSoft = Color(0xFF0D5B55);
  static const Color cardBgHover = Color(0xFF176B62);
  static const Color cardBgItem = Color(0xFF155B55);
  static const Color avatarBg = Color(0xFF23766D);

  // ============================================================
  // 3. FUNCTIONAL
  // ============================================================
  static const Color starYellow = Color(0xFFFBBF24);
  static const Color onlineGreen = Color(0xFF4ADE80);
  static const Color shadow = Color(0xFF042F2E);

  // ============================================================
  // 4. BASE
  // ============================================================
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // ============================================================
  // 5. GREY SCALE
  // ============================================================
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

  // ============================================================
  // 6. SECTION BACKGROUND
  // ============================================================
  static const Color sectionLight = Color(0xFFFFFFFF);
  static const Color sectionAltLight = Color(0xFFF0FDFA);
  static const Color sectionDark = darkTeal;
  static const Color sectionGradientStart = darkTeal;
  static const Color sectionGradientEnd = primaryTeal;

  // ============================================================
  // 7. STATUS
  // ============================================================
  static const Color success = Color(0xFF16A34A); // green-600
  static const Color danger = Color(0xFFDC2626);  // red-600
  static const Color warning = starYellow;
  static const Color info = Color(0xFF0EA5E9);    // sky-500

  // ============================================================
  // 8. SIDEBAR
  // ============================================================
  static const Color sidebarText = Color(0xFFE2E8F0);
  static const Color sidebarMuted = Color(0xFF94A3B8);

  // ============================================================
  // 9. ROLE — ADMIN (Teal)
  // ============================================================
  static const Color adminPrimary = primaryTeal;
  static const Color adminPrimaryDark = darkTeal;
  static const Color adminAccent = mint;
  static const Color adminBadgeBg = lightMint;
  static const Color adminBadgeText = darkTeal;

  // ============================================================
  // 10. ROLE — SUPER ADMIN (Teal + Gold)
  // ============================================================
  static const Color superPrimary = darkTeal;
  static const Color superPrimaryDark = shadow;
  static const Color superAccent = starYellow;
  static const Color superBadgeBg = Color(0xFFFEF3C7);
  static const Color superBadgeText = Color(0xFFB45309);

  // ============================================================
  // 11. BACKGROUND PAGE
  // ============================================================
  static const Color bgPage = Color(0xFFF4F7FB);

  // ============================================================
  // 12. EXTRA — badge, label, aksen sekunder
  // ============================================================

  /// Biru info → sekarang TEAL
  static const Color infoBlue = primaryTeal;       // #0F766E

  /// Ungu → sekarang TEAL
  static const Color purple = primaryTeal;         // #0F766E

  /// Amber → sekarang TEAL
  static const Color amber = primaryTeal;          // #0F766E

  // ============================================================
  // 13. ALIAS
  // ============================================================
  static const Color primary = primaryTeal;
  static const Color grey = grey500;
}