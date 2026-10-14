import 'package:flutter/material.dart';

import 'app_colors.dart';

/// ============================================================
/// AdminTheme
/// ------------------------------------------------------------
/// SEMUA ROLE (Admin & Super Admin) pakai TEAL.
/// Hanya `danger` yang tetap merah untuk aksi destruktif.
/// ============================================================
class AdminTheme {
  final String role; // 'admin' | 'super_admin'

  const AdminTheme._(this.role);

  factory AdminTheme.of(String? role) {
    final normalized = (role ?? '')
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');

    return AdminTheme._(
      normalized.contains('super') ? 'super_admin' : 'admin',
    );
  }

  bool get isSuperAdmin => role == 'super_admin';

  // ============================================================
  // BRAND / ACCENT — semua Teal (Admin & Super Admin)
  // ============================================================

  Color get accent => AppColors.adminPrimary;      // #0F766E

  Color get accentLight => AppColors.adminAccent;  // #2DD4BF (mint)

  Color get accentText => AppColors.adminBadgeText; // #134E4A

  // ============================================================
  // SIDEBAR — sama untuk kedua role
  // ============================================================

  Color get sidebarBg => AppColors.darkTeal;       // #134E4A
  Color get sidebarText => AppColors.sidebarText;
  Color get sidebarMuted => AppColors.sidebarMuted;
  Color get sidebarActiveBg => accent.withValues(alpha: 0.14);
  Color get sidebarActiveBorder => accent.withValues(alpha: 0.35);

  // ============================================================
  // BACKGROUND & SURFACE
  // ============================================================

  Color get bg => AppColors.bgPage;
  Color get cardBg => AppColors.white;
  Color get border => AppColors.grey200;
  Color get divider => AppColors.grey100;

  // ============================================================
  // TEXT
  // ============================================================

  Color get headerText => AppColors.grey500;
  Color get cellText => AppColors.grey900;
  Color get mutedText => AppColors.grey500;

  // ============================================================
  // STATUS — semua TEAL (kecuali danger)
  // ============================================================

  /// ✅ Sukses → Teal
  Color get success => AppColors.adminPrimary;     // #0F766E

  /// 🔴 Bahaya → TETAP MERAH (biar tidak salah klik reject/hapus)
  Color get danger => AppColors.danger;            // #DC2626

  /// ⚠️ Warning → Teal
  Color get warning => AppColors.adminPrimary;     // #0F766E

  /// ℹ️ Info → Teal
  Color get info => AppColors.adminPrimary;        // #0F766E

  // ============================================================
  // BADGE ROLE — sama untuk kedua role
  // ============================================================

  String get roleLabel => isSuperAdmin ? 'SUPER ADMIN' : 'ADMIN';

  Color get badgeBg => AppColors.adminBadgeBg;     // #CCFBF1
  Color get badgeText => AppColors.adminBadgeText; // #134E4A

  // ============================================================
  // RADIUS
  // ============================================================

  double get radius => 10;
}