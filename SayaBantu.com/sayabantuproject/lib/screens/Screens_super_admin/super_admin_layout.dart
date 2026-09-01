import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_page.dart';
import 'manage_admin_page.dart';
import 'system_setting_page.dart';
import 'activity_log_page.dart';
import '../Screens_auth/login_page.dart';
import '../Screens_Landing/landing_page.dart';

class SuperAdminLayout extends StatefulWidget {
  const SuperAdminLayout({super.key});

  @override
  State<SuperAdminLayout> createState() => _SuperAdminLayoutState();
}

class _SuperAdminLayoutState extends State<SuperAdminLayout> {
  int _selectedIndex = 0;

  final List<String> _menuItems = [
    'Analytics',
    'Kelola Admin',
    'Pengaturan Sistem',
    'Log Aktivitas',
  ];

  @override
    Widget build(BuildContext context) {
      final screenWidth = MediaQuery.of(context).size.width;
      final isMobile = screenWidth < 700;

      return Scaffold(
        backgroundColor: const Color(0xFFF3F7FB),

        // ==========================================================
        // DRAWER KHUSUS MOBILE
        // ==========================================================

        drawer: isMobile
            ? Drawer(
                width: 220,
                backgroundColor: const Color(0xFF0E172A),
                child: _buildSidebar(),
              )
            : null,

        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ======================================================
            // SIDEBAR DESKTOP
            // ======================================================

            if (!isMobile) _buildSidebar(),

            // ======================================================
            // CONTENT
            // ======================================================

            Expanded(
              child: Column(
                children: [
                  // ==================================================
                  // MOBILE HEADER
                  // ==================================================

                  if (isMobile)
                    Container(
                      height: 60,
                      width: double.infinity,
                      color: Colors.white,
                      child: Row(
                        children: [
                          Builder(
                            builder: (context) {
                              return IconButton(
                                icon: const Icon(
                                  Icons.menu_rounded,
                                  color: Color(0xFF0E172A),
                                ),
                                onPressed: () {
                                  Scaffold.of(context).openDrawer();
                                },
                              );
                            },
                          ),

                          const SizedBox(width: 4),

                          const Text(
                            'Super Admin',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0E172A),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ==================================================
                  // CONTENT AREA
                  // ==================================================

                  Expanded(
                    child: _buildContentArea(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  // ============================================================
  // CONTENT AREA
  // ============================================================

  Widget _buildContentArea() {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: double.infinity,
          child: _buildContent(),
        ),
      ),
    );
  }

  // ============================================================
  // SIDEBAR
  // ============================================================

  Widget _buildSidebar() {
    return Container(
      width: 220,
      height: double.infinity,
      color: const Color(0xFF0E172A),
      child: Column(
        children: [
          // ======================================================
          // HEADER SUPER ADMIN
          // ======================================================

          Container(
            height: 85,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFF243047),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF476F),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '⚡',
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Super Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Full Control Access',
                      style: TextStyle(
                        color: Color(0xFFFF4F4F),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ======================================================
          // MENU
          // ======================================================

          _buildMenuItem(
            index: 0,
            icon: Icons.bar_chart_rounded,
            title: 'Analytics',
          ),

          _buildMenuItem(
            index: 1,
            icon: Icons.admin_panel_settings_rounded,
            title: 'Kelola Admin',
          ),

          _buildMenuItem(
            index: 2,
            icon: Icons.settings_rounded,
            title: 'Pengaturan Sistem',
          ),

          _buildMenuItem(
            index: 3,
            icon: Icons.folder_rounded,
            title: 'Log Aktivitas',
          ),

          // ======================================================
          // SPACER
          // ======================================================

          const Spacer(),

          // ======================================================
          // LOGOUT
          // ======================================================

          _buildLogoutButton(),

          const SizedBox(height: 15),
        ],
      ),
    );
  }

  // ============================================================
  // MENU ITEM
  // ============================================================

  Widget _buildMenuItem({
    required int index,
    required IconData icon,
    required String title,
  }) {
    final bool selected = _selectedIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        height: 43,
        width: double.infinity,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1E2A40)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: selected
                  ? const Color(0xFFFF4848)
                  : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 17,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? Colors.white
                  : const Color(0xFF91A0B9),
            ),

            const SizedBox(width: 11),

            Text(
              title,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : const Color(0xFF91A0B9),
                fontSize: 12,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOGOUT BUTTON
  // ============================================================

    Widget _buildLogoutButton() {
    return InkWell(
      onTap: _logout,
      child: Container(
        height: 48,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 17,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.logout_rounded,
              size: 17,
              color: Color(0xFFFF6B6B),
            ),
            const SizedBox(width: 11),
            const Text(
              'Logout',
              style: TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOGOUT FUNCTION
  // ============================================================

    Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari akun Super Admin?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4848),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;
    if (!mounted) return;

    // Tunggu sampai dialog benar-benar selesai ditutup.
    await Future<void>.delayed(Duration.zero);

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (
          context,
          animation,
          secondaryAnimation,
        ) =>
            const LandingPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (route) => false,
    );
  }
  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const SuperAdminAnalyticsPage();

      case 1:
        return const ManageAdminPage();

      case 2:
        return const SystemSettingsPage();

      case 3:
        return const ActivityLogPage();

      default:
        return const SizedBox.shrink();
    }
  }
}