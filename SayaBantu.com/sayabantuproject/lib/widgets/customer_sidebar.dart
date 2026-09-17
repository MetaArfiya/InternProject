// lib/widgets/customer_sidebar.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sayabantu_project/screens/Screens_Landing/landing_page.dart';

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
  String name = 'Pengguna';
  String role = 'Pelanggan';
  String? photoUrl;

  bool isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  // =========================================================
  // REFRESH PROFILE
  // =========================================================

  void refreshProfile() {
    loadUser();
  }

  // =========================================================
  // LOAD DATA USER
  // =========================================================

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    final savedName = prefs.getString("name") ?? "Pengguna";
    final savedRole = prefs.getString("role") ?? "Pelanggan";

    if (!mounted) return;

    setState(() {
      name = savedName;
      role = savedRole;
    });

    // =======================================================
    // AMBIL DATA USER
    // =======================================================

    try {
      final response = await ApiService.get('/user');

      debugPrint("===== CUSTOMER SIDEBAR USER =====");
      debugPrint("STATUS : ${response.statusCode}");
      debugPrint("BODY   : ${response.body}");

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        final dynamic userData =
            decodedData is Map<String, dynamic>
                ? (decodedData['user'] ?? decodedData)
                : null;

        if (userData is Map<String, dynamic>) {
          final apiName = userData['name']?.toString();
          final dynamic apiPhoto = userData['photo_url'];
          final apiPhotoUrl = apiPhoto?.toString();

          if (!mounted) return;

          setState(() {
            if (apiName != null && apiName.trim().isNotEmpty) {
              name = apiName.trim();
            }

            if (apiPhotoUrl != null &&
                apiPhotoUrl.trim().isNotEmpty &&
                apiPhotoUrl != 'null') {
              photoUrl = apiPhotoUrl.trim();
            } else {
              photoUrl = null;
            }
          });

          debugPrint("NAMA USER        : $name");
          debugPrint("PHOTO URL STATE  : $photoUrl");
          debugPrint("FULL PHOTO URL   : ${getFullPhotoUrl()}");
        }
      } else {
        debugPrint(
          "GAGAL MEMUAT USER: ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint(
        "ERROR LOAD USER CUSTOMER SIDEBAR: $e",
      );
    }
  }

  // =========================================================
  // INITIAL
  // =========================================================

  String getInitials(String text) {
    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      return "P";
    }

    final words = trimmed.split(RegExp(r'\s+'));

    if (words.length >= 2) {
      return "${words.first[0]}${words.last[0]}".toUpperCase();
    }

    return words.first[0].toUpperCase();
  }

  // =========================================================
  // PHOTO URL
  // =========================================================

  String? getFullPhotoUrl() {
    if (photoUrl == null ||
        photoUrl!.trim().isEmpty ||
        photoUrl == 'null') {
      return null;
    }

    String path = photoUrl!.trim();

    if (path.startsWith('http://') ||
        path.startsWith('https://')) {
      return path;
    }

    if (path.startsWith('/')) {
      path = path.substring(1);
    }

    final filename = path.split('/').last;

    if (filename.isEmpty) {
      return null;
    }

    return 'http://127.0.0.1:8000/api/images/profile/$filename';
  }

  // =========================================================
  // PROFILE IMAGE
  // =========================================================

  Widget _buildProfileImage() {
    final fullPhotoUrl = getFullPhotoUrl();

    if (fullPhotoUrl == null) {
      return Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.orange,
        ),
        alignment: Alignment.center,
        child: Text(
          getInitials(name),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.orange,
      ),
      child: ClipOval(
        child: Image.network(
          fullPhotoUrl,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          cacheWidth: 120,
          cacheHeight: 120,
          loadingBuilder: (
            context,
            child,
            loadingProgress,
          ) {
            if (loadingProgress == null) {
              return child;
            }

            return Container(
              width: 52,
              height: 52,
              color: Colors.orange,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            );
          },
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            debugPrint(
              "GAGAL MENAMPILKAN FOTO CUSTOMER SIDEBAR",
            );

            debugPrint(
              "URL FOTO: $fullPhotoUrl",
            );

            debugPrint(
              "ERROR: $error",
            );

            return Container(
              width: 52,
              height: 52,
              color: Colors.orange,
              alignment: Alignment.center,
              child: Text(
                getInitials(name),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
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
  // LOGOUT
  // =========================================================

  Future<void> _logout() async {
    if (isLoggingOut) return;

    final confirm = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.logout,
                    color: Colors.red,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Keluar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: const Text(
                'Apakah kamu yakin ingin keluar dari akun?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      false,
                    );
                  },
                  child: const Text(
                    'Batal',
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      true,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Keluar',
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirm) return;

    if (mounted) {
      setState(() {
        isLoggingOut = true;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('token');

      await prefs.setBool(
        'isLoggedIn',
        false,
      );

      await prefs.remove('name');
      await prefs.remove('email');
      await prefs.remove('phone');
      await prefs.remove('address');
      await prefs.remove('profile_image_url');

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LandingPage(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoggingOut = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Gagal keluar dari akun: $e',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  // =========================================================
  // BUILD SIDEBAR
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: double.infinity,

      // SAMA DENGAN PARTNER
      color: const Color(0xff111827),

      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // =================================================
            // PROFILE USER
            // =================================================

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
              ),
              child: Row(
                children: [
                  _buildProfileImage(),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          role,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // =================================================
            // MENU
            // =================================================

            _menu(
              context,
              icon: Icons.home_outlined,
              title: "Beranda",
              menu: SidebarMenu.beranda,
            ),

            _menu(
              context,
              icon: Icons.payment_outlined,
              title: "Pembayaran",
              menu: SidebarMenu.pembayaran,
            ),

            _menu(
              context,
              icon: Icons.report_problem_outlined,
              title: "Pengaduan",
              menu: SidebarMenu.pengaduan,
            ),

            _menu(
              context,
              icon: Icons.notifications_none_outlined,
              title: "Notifikasi",
              menu: SidebarMenu.notifikasi,
            ),

            _menu(
              context,
              icon: Icons.settings_outlined,
              title: "Pengaturan",
              menu: SidebarMenu.pengaturan,
            ),

            const Spacer(),

            // =================================================
            // LOGOUT
            // =================================================

            _buildLogoutButton(),

            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // MENU ITEM
  // =========================================================

  Widget _menu(
    BuildContext context, {
    required IconData icon,
    required String title,
    required SidebarMenu menu,
  }) {
    final active = widget.activeMenu == menu;

    return InkWell(
      onTap: () {
        widget.onMenuSelected(menu);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
        color: active
            ? Colors.orange.withValues(alpha: 0.2)
            : Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              color: active
                  ? Colors.orange
                  : Colors.white70,
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active
                      ? Colors.orange
                      : Colors.white,
                  fontWeight: active
                      ? FontWeight.bold
                      : FontWeight.normal,
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

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: InkWell(
        onTap: isLoggingOut ? null : _logout,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              if (isLoggingOut)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.red,
                  ),
                )
              else
                const Icon(
                  Icons.logout,
                  color: Colors.red,
                  size: 20,
                ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  isLoggingOut ? 'Keluar...' : 'Keluar',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}