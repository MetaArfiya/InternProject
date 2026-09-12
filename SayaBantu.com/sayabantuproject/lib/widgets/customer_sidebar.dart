import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/Screens_Landing/landing_page.dart';
import '../models/sidebar_menu.dart';
import '../services/api_service.dart';

class CustomerSidebar extends StatefulWidget {
  final SidebarMenu activeMenu;
  final Function(SidebarMenu) onMenuSelected;

  const CustomerSidebar({
    super.key,
    required this.activeMenu,
    required this.onMenuSelected,
  });

  @override
  CustomerSidebarState createState() => CustomerSidebarState();
}

class CustomerSidebarState extends State<CustomerSidebar> {
  // =========================================================
  // STATE
  // =========================================================

  String name = 'Pengguna';
  String role = 'Pelanggan';
  String? photoUrl;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  // =========================================================
  // REFRESH PROFILE
  // =========================================================

  /// Dipanggil dari parent setelah data/foto profil diperbarui.
  void refreshProfile() {
    loadUser();
  }

  // =========================================================
  // LOAD USER
  // =========================================================

  Future<void> loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      String savedName = prefs.getString('name') ?? 'Pengguna';
      String savedRole = prefs.getString('role') ?? 'Pelanggan';

      // Ambil data terbaru dari API
      try {
        final response = await ApiService.get('/user');

        debugPrint('====================================');
        debugPrint('CUSTOMER SIDEBAR - GET /user');
        debugPrint('STATUS: ${response.statusCode}');
        debugPrint('BODY: ${response.body}');
        debugPrint('====================================');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          final userData = data is Map<String, dynamic>
              ? (data['user'] is Map<String, dynamic>
                  ? data['user'] as Map<String, dynamic>
                  : data)
              : <String, dynamic>{};

          savedName = userData['name']?.toString().trim().isNotEmpty == true
              ? userData['name'].toString()
              : savedName;

          final apiPhoto = userData['photo_url'];

          if (apiPhoto != null &&
              apiPhoto.toString().trim().isNotEmpty &&
              apiPhoto.toString() != 'null') {
            photoUrl = apiPhoto.toString().trim();
          } else {
            photoUrl = null;
          }
        }
      } catch (e) {
        debugPrint('Gagal mengambil data user dari API: $e');
      }

      if (!mounted) return;

      setState(() {
        name = savedName;
        role = savedRole;
      });
    } catch (e) {
      debugPrint('ERROR LOAD USER SIDEBAR: $e');
    }
  }

  // =========================================================
  // FULL PHOTO URL
  // =========================================================

  String? getFullPhotoUrl() {
    if (photoUrl == null ||
        photoUrl!.trim().isEmpty ||
        photoUrl!.trim() == 'null') {
      return null;
    }

    String path = photoUrl!.trim();

    // Jika API sudah memberikan URL lengkap
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // Hapus "/" di awal jika ada
    if (path.startsWith('/')) {
      path = path.substring(1);
    }

    // Ambil nama file saja
    final filename = path.split('/').last.trim();

    if (filename.isEmpty) {
      return null;
    }

    return 'http://127.0.0.1:8000/api/images/profile/$filename';
  }

  // =========================================================
  // INITIAL NAMA
  // =========================================================

  String getInitials(String text) {
    final cleanedText = text.trim();

    if (cleanedText.isEmpty) {
      return 'P';
    }

    final words = cleanedText
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return 'P';
    }

    if (words.length == 1) {
      return words.first[0].toUpperCase();
    }

    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> _logout() async {
    final confirmLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          title: const Text(
            'Keluar',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari akun?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(
                'Batal',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );

    if (confirmLogout != true) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // Hapus seluruh data sesi login
      await prefs.remove('auth_token');
      await prefs.remove('token');
      await prefs.remove('access_token');

      // Hapus data user
      await prefs.remove('name');
      await prefs.remove('email');
      await prefs.remove('phone');
      await prefs.remove('address');
      await prefs.remove('profile_image');
      await prefs.remove('role');
      await prefs.remove('user_id');
      await prefs.remove('userId');

      await prefs.setBool('isLoggedIn', false);

      if (!mounted) return;

      // Kembali ke landing dan membersihkan route sebelumnya
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LandingPage(),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint('ERROR LOGOUT: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal keluar dari akun: $e',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final fullPhotoUrl = getFullPhotoUrl();

    return SafeArea(
      child: Container(
        width: isMobile ? 240 : 260,
        color: colorScheme.surface,
        child: Column(
          children: [
            // =================================================
            // PROFILE HEADER
            // =================================================

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: isMobile ? 22 : 24,
                    backgroundColor: colorScheme.primary,
                    backgroundImage: fullPhotoUrl != null
                        ? NetworkImage(fullPhotoUrl)
                        : null,
                    child: fullPhotoUrl == null
                        ? Text(
                            getInitials(name),
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : 16,
                            ),
                          )
                        : null,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 14 : 15,
                            color: colorScheme.onSurface,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          role,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Divider(
              height: 1,
              color: colorScheme.outlineVariant,
            ),

            // =================================================
            // MENU
            // =================================================

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    // -----------------------------------------
                    // BERANDA
                    // -----------------------------------------

                    _menu(
                      context,
                      icon: Icons.home_outlined,
                      title: 'Beranda',
                      menu: SidebarMenu.beranda,
                    ),

                    // -----------------------------------------
                    // PEMBAYARAN
                    // -----------------------------------------

                    _menu(
                      context,
                      icon: Icons.payment_outlined,
                      title: 'Pembayaran',
                      menu: SidebarMenu.pembayaran,
                    ),

                    // -----------------------------------------
                    // NOTIFIKASI
                    // -----------------------------------------

                    _menu(
                      context,
                      icon: Icons.notifications_none_outlined,
                      title: 'Notifikasi',
                      menu: SidebarMenu.notifikasi,
                    ),

                    // -----------------------------------------
                    // PENGATURAN
                    // -----------------------------------------

                    _menu(
                      context,
                      icon: Icons.settings_outlined,
                      title: 'Pengaturan',
                      menu: SidebarMenu.pengaturan,
                    ),
                  ],
                ),
              ),
            ),

            // =================================================
            // LOGOUT
            // =================================================

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
              ),
              child: InkWell(
                onTap: _logout,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: isMobile ? 52 : 56,
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        size: isMobile ? 22 : 24,
                        color: colorScheme.error,
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Text(
                          'Keluar',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 15,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // =================================================
            // VERSION
            // =================================================

            Padding(
              padding: EdgeInsets.only(
                top: 2,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Text(
                'SayaBantu v1.0',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // MENU WIDGET
  // =========================================================

  Widget _menu(
    BuildContext context, {
    required IconData icon,
    required String title,
    required SidebarMenu menu,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final active = widget.activeMenu == menu;

    return InkWell(
      onTap: () {
        if (!active) {
          widget.onMenuSelected(menu);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: isMobile ? 52 : 56,
        margin: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 4,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        decoration: BoxDecoration(
          color: active
              ? colorScheme.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // ICON
            Icon(
              icon,
              size: isMobile ? 22 : 24,
              color: active
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),

            const SizedBox(width: 14),

            // TITLE
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  fontWeight: active
                      ? FontWeight.bold
                      : FontWeight.w600,
                  color: active
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}