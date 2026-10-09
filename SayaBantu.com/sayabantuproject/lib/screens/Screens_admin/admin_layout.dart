import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/auth_storage.dart';

import 'admin_verification_screen.dart';
import 'admin_complaint_screen.dart';
import 'admin_daily_report_screen.dart';
import 'admin_rating_screen.dart';
import 'admin_payment_screen.dart';
import 'admin_profile_screen.dart';

import '../../screens/Screens_Landing/landing_page.dart';

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
  // DESIGN TOKENS — disamakan dgn screenshot & template
  // ============================================================

  static const Color _accent = Color(0xFFF97316);       // orange
  static const Color _accentLight = Color(0xFFFB923C);  // orange muda
  static const Color _successColor = Color(0xFF16A34A);
  static const Color _dangerColor = Color(0xFFDC2626);
  static const Color _tableBorder = Color(0xFFE5E7EB);
  static const Color _tableDivider = Color(0xFFF3F4F6);
  static const Color _headerText = Color(0xFF6B7280);
  static const Color _cellText = Color(0xFF111827);
  static const Color _mutedText = Color(0xFF64748B);

  static const Color _bg = Color(0xFFF4F7FB);

  // Tokens khusus sidebar gelap
  static const Color _sidebarBg = Color(0xFF0F172A);      // navy gelap
  static const Color _sidebarText = Color(0xFFE2E8F0);    // abu terang
  static const Color _sidebarMuted = Color(0xFF94A3B8);   // abu redup

  static const double _radius = 10;

  late String activeMenu;

  int _reportRefreshKey = 0;

  // =========================================================
  // DATA ADMIN
  // =========================================================

  String adminName = 'Admin Operator';
  String adminEmail = 'admin@sayabantu.com';
  String adminRole = 'Admin Harian';
  String adminToken = '';

  String? adminPhotoUrl;

  @override
  void initState() {
    super.initState();

    activeMenu = widget.activeMenu;

    _restoreActiveMenu();
    _loadAdminProfile();
  }

  // =========================================================
  // RESTORE ACTIVE MENU
  // =========================================================

  void _restoreActiveMenu() {
    if (widget.activeMenu != 'verification') return;

    final savedMenu = AuthStorage.getString('admin_active_menu');

    if (savedMenu != null && savedMenu.isNotEmpty && mounted) {
      setState(() {
        activeMenu = savedMenu;
      });
    }
  }

  // =========================================================
  // SAVE ACTIVE MENU
  // =========================================================

  void _saveActiveMenu(String menu) {
    AuthStorage.setString('admin_active_menu', menu);
  }

  // =========================================================
  // LOAD ADMIN PROFILE
  // =========================================================

  Future<void> _loadAdminProfile() async {
    final savedName = AuthStorage.getString('name') ?? 'Admin Operator';
    final savedEmail =
        AuthStorage.getString('email') ?? 'admin@sayabantu.com';
    final savedRole = AuthStorage.getString('role') ?? 'Admin Harian';
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

          if (!mounted) return;

          setState(() {
            if (apiName != null && apiName.trim().isNotEmpty) {
              adminName = apiName.trim();
            }
            if (apiEmail != null && apiEmail.trim().isNotEmpty) {
              adminEmail = apiEmail.trim();
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

  // =========================================================
  // FULL PHOTO URL
  // =========================================================

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

  // =========================================================
  // INITIALS
  // =========================================================

  String _getInitials() {
    final text = adminName.trim();
    if (text.isEmpty) return 'A';

    final words = text.split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words.first[0]}${words.last[0]}'.toUpperCase();
    }
    return words.first[0].toUpperCase();
  }

  // =========================================================
  // PROFILE IMAGE
  // =========================================================

  Widget _buildAdminProfileImage({double size = 40}) {
    final fullPhotoUrl = _getFullPhotoUrl();

    if (fullPhotoUrl == null) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: _accentLight,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          _getInitials(),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: _accentLight,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
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
              color: _accentLight,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: size,
              height: size,
              color: _accentLight,
              alignment: Alignment.center,
              child: Text(
                _getInitials(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // =========================================================
  // MENU INDEX
  // =========================================================

  int _getMenuIndex() {
    switch (activeMenu) {
      case 'verification':
        return 0;
      case 'complaint':
        return 1;
      case 'report':
        return 2;
      case 'rating':
        return 3;
      case 'payment':
        return 4;
      case 'profile':
        return 5;
      default:
        return 0;
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final isTablet = screenWidth >= 700 && screenWidth < 1100;

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: _bg,

      appBar: isMobile
          ? AppBar(
              backgroundColor: _sidebarBg,
              surfaceTintColor: _sidebarBg,
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
                        color: _sidebarText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,

      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isMobile)
            SizedBox(
              width: isTablet ? 240 : 260,
              child: _buildSidebar(context),
            ),

          Expanded(
            child: IndexedStack(
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
            ),
          ),
        ],
      ),

      bottomNavigationBar: isMobile ? _buildBottomNavigationBar() : null,
    );
  }

  // =========================================================
  // BOTTOM NAVIGATION BAR
  // =========================================================

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _tableBorder, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _getMenuIndex(),
          onTap: (index) {
            String menu = 'verification';
            switch (index) {
              case 0:
                menu = 'verification';
                break;
              case 1:
                menu = 'complaint';
                break;
              case 2:
                menu = 'report';
                break;
              case 3:
                menu = 'rating';
                break;
              case 4:
                menu = 'payment';
                break;
              case 5:
                menu = 'profile';
                break;
            }
            _changePage(context, menu);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: _accent,
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.verified_outlined, size: 22),
              activeIcon: Icon(Icons.verified, size: 22),
              label: 'Verifikasi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report_problem_outlined, size: 22),
              activeIcon: Icon(Icons.report_problem, size: 22),
              label: 'Pengaduan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined, size: 22),
              activeIcon: Icon(Icons.bar_chart, size: 22),
              label: 'Laporan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star_outline, size: 22),
              activeIcon: Icon(Icons.star, size: 22),
              label: 'Rating',
            ),
            BottomNavigationBarItem(
              icon:
                  Icon(Icons.account_balance_wallet_outlined, size: 22),
              activeIcon:
                  Icon(Icons.account_balance_wallet, size: 22),
              label: 'Bayar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 22),
              activeIcon: Icon(Icons.person, size: 22),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // SIDEBAR — navy gelap, disamakan dgn screenshot
  // =========================================================

  Widget _buildSidebar(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: _sidebarBg,
      child: Column(
        children: [
          const SizedBox(height: 22),

          // ==========================================
          // PROFIL ADMIN
          // ==========================================
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
                          color: _sidebarText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Admin',  // label role
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: _sidebarMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ==========================================
          // MENU
          // ==========================================
          _menuItem(
            context: context,
            icon: Icons.verified_outlined,
            activeIcon: Icons.verified,
            title: 'Verifikasi Mitra',
            active: activeMenu == 'verification',
            onTap: () => _changePage(context, 'verification'),
          ),
          _menuItem(
            context: context,
            icon: Icons.report_problem_outlined,
            activeIcon: Icons.report_problem,
            title: 'Pengaduan',
            active: activeMenu == 'complaint',
            onTap: () => _changePage(context, 'complaint'),
          ),
          _menuItem(
            context: context,
            icon: Icons.bar_chart_outlined,
            activeIcon: Icons.bar_chart,
            title: 'Laporan Harian',
            active: activeMenu == 'report',
            onTap: () => _changePage(context, 'report'),
          ),
          _menuItem(
            context: context,
            icon: Icons.star_outline,
            activeIcon: Icons.star,
            title: 'Kelola Rating Mitra',
            active: activeMenu == 'rating',
            onTap: () => _changePage(context, 'rating'),
          ),
          _menuItem(
            context: context,
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet,
            title: 'Pembayaran',
            active: activeMenu == 'payment',
            onTap: () => _changePage(context, 'payment'),
          ),
          _menuItem(
            context: context,
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            title: 'Profil Admin',
            active: activeMenu == 'profile',
            onTap: () => _changePage(context, 'profile'),
          ),

          const Spacer(),

          // ==========================================
          // LOGOUT
          // ==========================================
          _logoutButton(context),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // =========================================================
  // CHANGE PAGE — dengan save menu
  // =========================================================

  void _changePage(BuildContext context, String menu) {
    setState(() {
      activeMenu = menu;
      if (menu == 'report') _reportRefreshKey++;
    });

    _saveActiveMenu(menu);
  }

  // =========================================================
  // MENU ITEM — sidebar gelap
  // =========================================================

  Widget _menuItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required bool active,
    required VoidCallback onTap,
    String? badge,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: active
                ? _accent.withOpacity(0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                active ? activeIcon : icon,
                size: 20,
                color: active ? _accent : _sidebarText,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? _accent : _sidebarText,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: _dangerColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge,
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.white,
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

  // =========================================================
  // LOGOUT BUTTON — sidebar gelap
  // =========================================================

  Widget _logoutButton(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: () => _showLogoutDialog(context),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _dangerColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.logout_outlined,
                size: 20,
                color: _dangerColor,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  'Keluar',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _dangerColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // LOGOUT DIALOG
  // =========================================================

  void _showLogoutDialog(BuildContext context) {
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
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _dangerColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(_radius),
                        ),
                        child: const Icon(
                          Icons.logout_outlined,
                          color: _dangerColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Keluar',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _cellText,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(false),
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: _headerText,
                        ),
                        splashRadius: 22,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  Text(
                    'Apakah kamu yakin ingin keluar dari akun admin?',
                    style: textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF374151),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 46),
                            foregroundColor:
                                const Color(0xFF374151),
                            side: const BorderSide(
                              color: Color(0xFFD1D5DB),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_radius),
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
                            backgroundColor: _dangerColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 46),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_radius),
                            ),
                          ),
                          child: Text(
                            'Keluar',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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
        if (!mounted) return;
        _logout(context);
      }
    });
  }

  // =========================================================
  // LOGOUT PROCESS
  // =========================================================

  void _logout(BuildContext context) {
    AuthStorage.clear();

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LandingPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (route) => false,
    );
  }
}