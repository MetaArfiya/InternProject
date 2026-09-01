import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin_verification_screen.dart';
import 'admin_moderation_screen.dart';
import 'admin_daily_report_screen.dart';
import 'admin_profile_screen.dart';
import '../../screens/Screens_Landing/landing_page.dart';
//import '../../screens/Screens_auth/login_page.dart';

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
  late String activeMenu;

  int _reportRefreshKey = 0;

  String adminName = 'Admin Operator';
  String adminEmail = 'admin@sayabantu.com';
  String adminRole = 'Admin Harian';
  String adminToken = '';

  @override
  void initState() {
    super.initState();

    activeMenu = widget.activeMenu;

    _loadAdminProfile();
  }

  // =========================================================
  // LOAD ADMIN PROFILE
  // =========================================================

  Future<void> _loadAdminProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final savedName =
        prefs.getString('name') ?? 'Admin Operator';

    final savedEmail =
        prefs.getString('email') ??
            'admin@sayabantu.com';

    final savedRole =
        prefs.getString('role') ?? 'Admin Harian';

    final savedToken =
        prefs.getString('token') ?? '';

    if (!mounted) return;

    setState(() {
      adminName = savedName;
      adminEmail = savedEmail;
      adminRole = savedRole;
      adminToken = savedToken;
    });
  }

  // =========================================================
  // MENU INDEX
  // =========================================================

  int _getMenuIndex() {
    switch (activeMenu) {
      case 'verification':
        return 0;

      case 'moderation':
        return 1;

      case 'report':
        return 2;

      case 'profile':
        return 3;

      default:
        return 0;
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.of(context).size.width;

    final isMobile =
        screenWidth < 700;

    final isTablet =
        screenWidth >= 700 &&
        screenWidth < 1100;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F7FB),

      // =====================================================
      // MOBILE DRAWER
      // =====================================================

      drawer: isMobile
          ? Drawer(
              width: 270,
              child: SafeArea(
                child: _buildSidebar(context),
              ),
            )
          : null,

      // =====================================================
      // MOBILE APP BAR
      // =====================================================

      appBar: isMobile
          ? AppBar(
              backgroundColor:
                  Colors.white,
              surfaceTintColor:
                  Colors.white,
              elevation: 0,

              leading: Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(
                      Icons.menu,
                      color:
                          Color(0xFF334155),
                    ),
                    onPressed: () {
                      Scaffold.of(context)
                          .openDrawer();
                    },
                  );
                },
              ),

              title: Text(
                adminName,
                style:
                    const TextStyle(
                  color:
                      Color(0xFF111827),
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            )
          : null,

      // =====================================================
      // BODY
      // =====================================================

      body: Row(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          // ===================================================
          // SIDEBAR DESKTOP / TABLET
          // ===================================================

          if (!isMobile)
            SizedBox(
              width:
                  isTablet ? 210 : 230,
              child:
                  _buildSidebar(context),
            ),

          // ===================================================
          // CONTENT
          // ===================================================

          Expanded(
            child: IndexedStack(
              index: _getMenuIndex(),

              children: [
                // =============================================
                // VERIFIKASI
                // =============================================

                const AdminVerificationScreen(),

                // =============================================
                // MODERASI
                // =============================================

                const AdminModerationScreen(),

                // =============================================
                // LAPORAN HARIAN
                // =============================================
                //
                // TOKEN DARI SHARED PREFERENCES
                // DIKIRIM KE SCREEN
                // =============================================

                AdminDailyReportScreen(
                  key: ValueKey(
                    'report_${_reportRefreshKey}',
                  ),
                ),

                // =============================================
                // PROFIL
                // =============================================

                AdminProfileScreen(
                  onProfileUpdated:
                      _loadAdminProfile,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SIDEBAR
  // =========================================================

  Widget _buildSidebar(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,

      child: Column(
        children: [
          const SizedBox(height: 20),

          // =================================================
          // PROFILE ADMIN
          // =================================================

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
            ),

            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,

                  decoration:
                      const BoxDecoration(
                    color:
                        Color(0xFF8B5CF6),
                    shape:
                        BoxShape.circle,
                  ),

                  child:
                      const Icon(
                    Icons.shield_outlined,
                    color:
                        Colors.white,
                    size: 21,
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Text(
                        adminName,

                        overflow:
                            TextOverflow.ellipsis,

                        style:
                            const TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              Color(0xFF111827),
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        'Level: $adminRole',

                        overflow:
                            TextOverflow.ellipsis,

                        style:
                            const TextStyle(
                          fontSize: 10,
                          color:
                              Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 25,
          ),

          // =================================================
          // VERIFIKASI MITRA
          // =================================================

          _menuItem(
            context: context,
            icon:
                Icons.verified_outlined,
            title:
                'Verifikasi Mitra',
            active:
                activeMenu ==
                    'verification',
            onTap: () {
              _changePage(
                context,
                'verification',
              );
            },
          ),

          // =================================================
          // MODERASI
          // =================================================

          _menuItem(
            context: context,
            icon:
                Icons.flag_outlined,
            title:
                'Moderasi Konten',
            active:
                activeMenu ==
                    'moderation',
            onTap: () {
              _changePage(
                context,
                'moderation',
              );
            },
          ),

          // =================================================
          // LAPORAN
          // =================================================

          _menuItem(
            context: context,
            icon:
                Icons.bar_chart_outlined,
            title:
                'Laporan Harian',
            active:
                activeMenu ==
                    'report',
            onTap: () {
              _changePage(
                context,
                'report',
              );
            },
          ),

          // =================================================
          // PROFIL
          // =================================================

          _menuItem(
            context: context,
            icon:
                Icons.person_outline,
            title:
                'Profil Admin',
            active:
                activeMenu ==
                    'profile',
            onTap: () {
              _changePage(
                context,
                'profile',
              );
            },
          ),

          const Spacer(),

          // =================================================
          // PEMBATAS
          // =================================================

          const Padding(
            padding:
                EdgeInsets.symmetric(
              horizontal: 16,
            ),

            child: Divider(
              height: 1,
              color:
                  Color(0xFFE2E8F0),
            ),
          ),

          // =================================================
          // LOGOUT
          // =================================================

          _logoutButton(context),

          const SizedBox(
            height: 15,
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CHANGE PAGE
  // =========================================================

  void _changePage(
  BuildContext context,
  String menu,
) {
  setState(() {
    activeMenu = menu;

    if (menu == 'report') {
      _reportRefreshKey++;
    }
  });

  if (MediaQuery.of(context).size.width < 700) {
    Navigator.of(context).pop();
  }
}

  // =========================================================
  // MENU ITEM
  // =========================================================

  Widget _menuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool active,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,

      child: Container(
        width: double.infinity,
        height: 46,

        padding:
            const EdgeInsets.symmetric(
          horizontal: 17,
        ),

        decoration:
            BoxDecoration(
          color: active
              ? const Color(0xFFF3E8FF)
              : Colors.transparent,

          border: active
              ? const Border(
                  right: BorderSide(
                    color:
                        Color(0xFF8B5CF6),
                    width: 3,
                  ),
                )
              : null,
        ),

        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: active
                  ? const Color(
                      0xFF7C3AED,
                    )
                  : const Color(
                      0xFF475569,
                    ),
            ),

            const SizedBox(
              width: 11,
            ),

            Expanded(
              child: Text(
                title,

                overflow:
                    TextOverflow.ellipsis,

                style: TextStyle(
                  fontSize: 12,

                  fontWeight: active
                      ? FontWeight.w600
                      : FontWeight.w400,

                  color: active
                      ? const Color(
                          0xFF7C3AED,
                        )
                      : const Color(
                          0xFF475569,
                        ),
                ),
              ),
            ),

            if (badge != null)
              Container(
                width: 19,
                height: 19,

                alignment:
                    Alignment.center,

                decoration:
                    const BoxDecoration(
                  color:
                      Color(0xFFEF4444),
                  shape:
                      BoxShape.circle,
                ),

                child: Text(
                  badge,

                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // LOGOUT BUTTON
  // =========================================================

  Widget _logoutButton(
    BuildContext context,
  ) {
    return InkWell(
      onTap: () {
        _showLogoutDialog(
          context,
        );
      },

      borderRadius:
          BorderRadius.circular(8),

      child: Container(
        width: double.infinity,
        height: 48,

        margin:
            const EdgeInsets.symmetric(
          horizontal: 10,
        ),

        padding:
            const EdgeInsets.symmetric(
          horizontal: 17,
        ),

        child: Row(
          children: [
            const Icon(
              Icons.logout_outlined,
              size: 19,
              color:
                  Color(0xFFEF4444),
            ),

            const SizedBox(
              width: 11,
            ),

            const Expanded(
              child: Text(
                'Keluar',

                style:
                    TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w500,
                  color:
                      Color(0xFFEF4444),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // LOGOUT DIALOG
  // =========================================================

  void _showLogoutDialog(
    BuildContext context,
  ) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.logout_outlined,
                color: Color(0xFFEF4444),
              ),
              SizedBox(width: 10),
              Text(
                'Keluar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari akun admin?',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              child: const Text('Keluar'),
            ),
          ],
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

  Future<void> _logout(
    BuildContext context,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear(); // Membersihkan seluruh sesi dan token secara aman

    if (!mounted) return;

    // Navigasi langsung dengan menghapus seluruh stack rute sebelumnya
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (
          context,
          animation,
          secondaryAnimation,
        ) {
          return const LandingPage();
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (route) => false,
    );
  }
}