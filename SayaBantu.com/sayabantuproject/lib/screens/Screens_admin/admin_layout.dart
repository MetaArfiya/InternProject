import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/auth_storage.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_colors.dart';
import '../../theme/admin_theme_provider.dart';

import 'admin_verification_screen.dart';
import 'admin_complaint_screen.dart';
import 'admin_daily_report_screen.dart';
import 'admin_rating_screen.dart';
import 'admin_payment_screen.dart';
import 'admin_profile_screen.dart';

import '../../screens/Screens_Landing/landing_page.dart';

/// ============================================================
/// AdminLayout
/// ------------------------------------------------------------
/// Layout utama untuk role Admin & Super Admin.
/// Tema otomatis menyesuaikan role:
///   - Admin       → Teal
///   - Super Admin → Teal + Gold accent
///
/// Semua warna diambil dari [AppColors] via [AdminTheme].
/// ============================================================
class AdminLayout extends StatefulWidget {
  final String activeMenu;

  const AdminLayout({
    super.key,
    this.activeMenu = 'verification',
  });

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  // ============================================================
  // THEME
  // ============================================================

  AdminTheme get theme => AdminTheme.of(adminRole);

  // ============================================================
  // STATE
  // ============================================================

  late String activeMenu;
  int _reportRefreshKey = 0;

  String adminName = 'Admin Operator';
  String adminEmail = 'admin@sayabantu.com';
  String adminRole = 'Admin';
  String adminToken = '';
  String? adminPhotoUrl;

  /// Daftar menu utama — dipakai untuk bottom nav & sidebar.
  static const List<Map<String, dynamic>> _menus = [
    {
      'key': 'verification',
      'title': 'Verifikasi Mitra',
      'icon': Icons.verified_outlined,
      'activeIcon': Icons.verified,
      'shortLabel': 'Verifikasi',
    },
    {
      'key': 'complaint',
      'title': 'Pengaduan',
      'icon': Icons.report_problem_outlined,
      'activeIcon': Icons.report_problem,
      'shortLabel': 'Pengaduan',
    },
    {
      'key': 'report',
      'title': 'Laporan Harian',
      'icon': Icons.bar_chart_outlined,
      'activeIcon': Icons.bar_chart,
      'shortLabel': 'Laporan',
    },
    {
      'key': 'rating',
      'title': 'Kelola Rating Mitra',
      'icon': Icons.star_outline,
      'activeIcon': Icons.star,
      'shortLabel': 'Rating',
    },
    {
      'key': 'payment',
      'title': 'Pembayaran',
      'icon': Icons.account_balance_wallet_outlined,
      'activeIcon': Icons.account_balance_wallet,
      'shortLabel': 'Bayar',
    },
    {
      'key': 'profile',
      'title': 'Profil Admin',
      'icon': Icons.person_outline,
      'activeIcon': Icons.person,
      'shortLabel': 'Profil',
    },
  ];

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();
    activeMenu = widget.activeMenu;
    _restoreActiveMenu();
    _loadAdminProfile();
  }

  // ============================================================
  // RESTORE / SAVE ACTIVE MENU
  // ============================================================

  void _restoreActiveMenu() {
    if (widget.activeMenu != 'verification') return;

    final savedMenu = AuthStorage.getString('admin_active_menu');

    if (savedMenu != null && savedMenu.isNotEmpty && mounted) {
      setState(() => activeMenu = savedMenu);
    }
  }

  void _saveActiveMenu(String menu) {
    AuthStorage.setString('admin_active_menu', menu);
  }

  // ============================================================
  // LOAD ADMIN PROFILE
  // ============================================================

  Future<void> _loadAdminProfile() async {
    final savedName = AuthStorage.getString('name') ?? 'Admin Operator';
    final savedEmail =
        AuthStorage.getString('email') ?? 'admin@sayabantu.com';
    final savedRole = AuthStorage.getString('role') ?? 'Admin';
    final savedToken = AuthStorage.getString('token') ?? '';

    if (!mounted) return;

    setState(() {
      adminName = savedName;
      adminEmail = savedEmail;
      adminRole = savedRole;
      adminToken = savedToken;
    });

    try {
      final response = await ApiService.get('/user');

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        dynamic userData;

        if (decodedData is Map<String, dynamic>) {
          userData = decodedData['user'] ?? decodedData;
        }

        if (userData is Map<String, dynamic>) {
          final apiName = userData['name']?.toString();
          final apiEmail = userData['email']?.toString();
          final apiPhoto = userData['photo_url']?.toString();
          final apiRole = userData['role']?.toString();

          if (!mounted) return;

          setState(() {
            if (apiName != null && apiName.trim().isNotEmpty) {
              adminName = apiName.trim();
            }
            if (apiEmail != null && apiEmail.trim().isNotEmpty) {
              adminEmail = apiEmail.trim();
            }
            if (apiRole != null && apiRole.trim().isNotEmpty) {
              adminRole = apiRole.trim();
            }
            if (apiPhoto != null &&
                apiPhoto.trim().isNotEmpty &&
                apiPhoto != 'null') {
              adminPhotoUrl = apiPhoto.trim();
            } else {
              adminPhotoUrl = null;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('ERROR LOAD USER ADMIN: $e');
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String? _getFullPhotoUrl() {
    if (adminPhotoUrl == null ||
        adminPhotoUrl!.trim().isEmpty ||
        adminPhotoUrl == 'null') {
      return null;
    }

    String path = adminPhotoUrl!.trim();

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    if (path.startsWith('/')) path = path.substring(1);

    final filename = path.split('/').last;
    if (filename.isEmpty) return null;

    return 'http://127.0.0.1:8000/api/images/profile/$filename';
  }

  String _getInitials() {
    final text = adminName.trim();
    if (text.isEmpty) return 'A';

    final words = text.split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words.first[0]}${words.last[0]}'.toUpperCase();
    }
    return words.first[0].toUpperCase();
  }

  int _getMenuIndex() {
    final idx = _menus.indexWhere((m) => m['key'] == activeMenu);
    return idx < 0 ? 0 : idx;
  }

  // ============================================================
  // PROFILE IMAGE
  // ============================================================

  Widget _buildAdminProfileImage({double size = 40}) {
    final fullPhotoUrl = _getFullPhotoUrl();
    final bgColor = theme.accentLight;
    final initials = _getInitials();

    Widget fallback() => Container(
          width: size,
          height: size,
          color: bgColor,
          alignment: Alignment.center,
          child: Text(
            initials,
            style: TextStyle(
              color: AppColors.white,
              fontSize: size * 0.38,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: fullPhotoUrl == null
          ? fallback()
          : ClipOval(
              child: Image.network(
                fullPhotoUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: size,
                    height: size,
                    color: bgColor,
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => fallback(),
              ),
            ),
    );
  }

  // ============================================================
  // ROLE CHIP
  // ============================================================

  Widget _roleChip({bool small = false}) {
    final t = theme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: t.badgeBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        t.roleLabel,
        style: TextStyle(
          color: t.badgeText,
          fontSize: small ? 9 : 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final isTablet = screenWidth >= 700 && screenWidth < 1100;
    final textTheme = Theme.of(context).textTheme;

    return AdminThemeProvider(
      theme: t,
      child: Scaffold(
        backgroundColor: t.bg,
        appBar: isMobile ? _buildMobileAppBar(textTheme, t) : null,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isMobile)
              SizedBox(
                width: isTablet ? 240 : 260,
                child: _buildSidebar(context),
              ),
            Expanded(child: _buildBody()),
          ],
        ),
        bottomNavigationBar:
            isMobile ? _buildBottomNavigationBar() : null,
      ),
    );
  }

  // ============================================================
  // BODY (IndexedStack)
  // ============================================================

  Widget _buildBody() {
    return IndexedStack(
      index: _getMenuIndex(),
      children: [
        const AdminVerificationScreen(),
        const AdminComplaintScreen(),
        AdminDailyReportScreen(
          key: ValueKey('report_$_reportRefreshKey'),
        ),
        const AdminRatingScreen(),
        const AdminPaymentScreen(),
        AdminProfileScreen(
          onProfileUpdated: _loadAdminProfile,
          onLogout: () => _showLogoutDialog(context),
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE APP BAR
  // ============================================================

  AppBar _buildMobileAppBar(TextTheme textTheme, AdminTheme t) {
    return AppBar(
      backgroundColor: t.sidebarBg,
      surfaceTintColor: t.sidebarBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          _buildAdminProfileImage(size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              adminName,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                color: t.sidebarText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _roleChip(small: true),
        ],
      ),
    );
  }

  // ============================================================
  // SIDEBAR
  // ============================================================

  Widget _buildSidebar(BuildContext context) {
    final t = theme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: t.sidebarBg,
      child: Column(
        children: [
          const SizedBox(height: 22),

          // Profil admin
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildAdminProfileImage(size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        adminName,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: t.sidebarText,
                        ),
                      ),
                      const SizedBox(height: 5),
                      _roleChip(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Menu
          ..._menus.map(
            (menu) => _menuItem(
              context: context,
              icon: menu['icon'] as IconData,
              activeIcon: menu['activeIcon'] as IconData,
              title: menu['title'] as String,
              active: activeMenu == menu['key'],
              onTap: () => _changePage(context, menu['key'] as String),
            ),
          ),

          const Spacer(),

          // Logout
          _logoutButton(context),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ============================================================
  // MENU ITEM
  // ============================================================

  Widget _menuItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required bool active,
    required VoidCallback onTap,
    String? badge,
  }) {
    final t = theme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(t.radius),
        child: Container(
          width: double.infinity,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: active ? t.sidebarActiveBg : AppColors.transparent,
            borderRadius: BorderRadius.circular(t.radius),
            border: active && t.isSuperAdmin
                ? Border.all(color: t.sidebarActiveBorder, width: 1)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                active ? activeIcon : icon,
                size: 20,
                color: active ? t.accent : t.sidebarText,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? t.accent : t.sidebarText,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t.danger,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGOUT BUTTON
  // ============================================================

  Widget _logoutButton(BuildContext context) {
    final t = theme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: () => _showLogoutDialog(context),
        borderRadius: BorderRadius.circular(t.radius),
        child: Container(
          width: double.infinity,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: t.danger.withValues(alpha:0.15),
            borderRadius: BorderRadius.circular(t.radius),
          ),
          child: Row(
            children: [
              Icon(Icons.logout_outlined, size: 20, color: t.danger),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  'Keluar',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: t.danger,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION BAR
  // ============================================================

  Widget _buildBottomNavigationBar() {
    final t = theme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: t.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _getMenuIndex(),
          onTap: (index) {
            if (index >= 0 && index < _menus.length) {
              _changePage(context, _menus[index]['key'] as String);
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.white,
          selectedItemColor: t.accent,
          unselectedItemColor: t.sidebarMuted,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          elevation: 0,
          items: _menus
              .map(
                (m) => BottomNavigationBarItem(
                  icon: Icon(m['icon'] as IconData, size: 22),
                  activeIcon: Icon(m['activeIcon'] as IconData, size: 22),
                  label: m['shortLabel'] as String,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  // ============================================================
  // CHANGE PAGE
  // ============================================================

  void _changePage(BuildContext context, String menu) {
    if (activeMenu == menu) return;

    setState(() {
      activeMenu = menu;
      if (menu == 'report') _reportRefreshKey++;
    });

    _saveActiveMenu(menu);
  }

  // ============================================================
  // LOGOUT DIALOG
  // ============================================================

  void _showLogoutDialog(BuildContext context) {
    final t = theme;

    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final textTheme = Theme.of(dialogContext).textTheme;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: t.danger.withValues(alpha:0.12),
                          borderRadius: BorderRadius.circular(t.radius),
                        ),
                        child: Icon(
                          Icons.logout_outlined,
                          color: t.danger,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Keluar',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: t.cellText,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(false),
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: t.headerText,
                        ),
                        splashRadius: 22,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Divider(height: 1, color: t.divider),
                  const SizedBox(height: 16),

                  // Body
                  Text(
                    'Apakah kamu yakin ingin keluar dari akun admin?',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.grey700,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 46),
                            foregroundColor: AppColors.grey700,
                            side: const BorderSide(
                              color: AppColors.grey300,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(t.radius),
                            ),
                          ),
                          child: Text(
                            'Batal',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: t.danger,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size(0, 46),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(t.radius),
                            ),
                          ),
                          child: Text(
                            'Keluar',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((shouldLogout) {
      if (shouldLogout == true) {
        if (!context.mounted) return;
        _logout(context);
      }
    });
  }

  // ============================================================
  // LOGOUT PROCESS
  // ============================================================

  void _logout(BuildContext context) {
    AuthStorage.clear();

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LandingPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (route) => false,
    );
  }
}