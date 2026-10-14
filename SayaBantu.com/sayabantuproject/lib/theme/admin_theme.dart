import 'package:flutter/material.dart';

import 'app_colors.dart';

/// ============================================================
/// AdminTheme
/// ------------------------------------------------------------
/// Token warna per-role (Admin / Super Admin).
/// Semua warna diambil dari [AppColors] → konsisten dengan brand.
///
/// Pemakaian:
///   final theme = AdminTheme.of(adminRole);
///   Container(color: theme.accent)
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
  // BRAND / ACCENT
  // ============================================================

  Color get accent =>
      isSuperAdmin ? AppColors.superAccent : AppColors.adminPrimary;

  Color get accentLight =>
      isSuperAdmin ? AppColors.superBadgeBg : AppColors.adminAccent;

  Color get accentText =>
      isSuperAdmin ? AppColors.superBadgeText : AppColors.adminBadgeText;

  // ============================================================
  // SIDEBAR
  // ============================================================

  Color get sidebarBg =>
      isSuperAdmin ? AppColors.superPrimaryDark : AppColors.darkTeal;

  Color get sidebarText => AppColors.sidebarText;
  Color get sidebarMuted => AppColors.sidebarMuted;
  Color get sidebarActiveBg => accent.withOpacity(0.14);
  Color get sidebarActiveBorder => accent.withOpacity(0.35);

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
  // STATUS
  // ============================================================

  Color get success => AppColors.success;
  Color get danger => AppColors.danger;
  Color get warning => AppColors.warning;
  Color get info => AppColors.info;

  // ============================================================
  // BADGE ROLE
  // ============================================================

  String get roleLabel => isSuperAdmin ? 'SUPER ADMIN' : 'ADMIN';

  Color get badgeBg =>
      isSuperAdmin ? AppColors.superBadgeBg : AppColors.adminBadgeBg;

  Color get badgeText =>
      isSuperAdmin ? AppColors.superBadgeText : AppColors.adminBadgeText;

  // ============================================================
  // RADIUS
  // ============================================================

  double get radius => 10;
}