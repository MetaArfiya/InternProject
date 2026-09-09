import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/Screens_Landing/landing_page.dart';
import '../models/sidebar_menu.dart';
import '../services/api_service.dart';

// ════════════════════════════════════════════════════════════
// ⚠️ UBAH: State class sekarang public (tanpa underscore)
// ════════════════════════════════════════════════════════════
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

  String name = "Pengguna";
  String role = "Pelanggan";
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  // =========================================================
  // 🔄 METHOD REFRESH – dipanggil dari parent setelah update foto
  // =========================================================
  void refreshProfile() {
    loadUser(); // akan memuat ulang data dari API dan setState
  }

  // =========================================================
  // LOAD USER
  // =========================================================
  Future<void> loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String savedName = prefs.getString("name") ?? "Pengguna";
      String savedRole = prefs.getString("role") ?? "Pelanggan";

      // Ambil data terbaru dari API
      try {
        final response = await ApiService.get('/user');
        debugPrint("====================================");
        debugPrint("CUSTOMER SIDEBAR - GET /user");
        debugPrint("STATUS: ${response.statusCode}");
        debugPrint("BODY: ${response.body}");
        debugPrint("====================================");

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final userData = data['user'] ?? data;

          savedName = userData['name']?.toString() ?? savedName;

          final apiPhoto = userData['photo_url'];
          if (apiPhoto != null &&
              apiPhoto.toString().trim().isNotEmpty &&
              apiPhoto.toString() != 'null') {
            photoUrl = apiPhoto.toString();
          } else {
            photoUrl = null;
          }
        }
      } catch (e) {
        debugPrint("Gagal mengambil data user dari API: $e");
      }

      if (!mounted) return;
      setState(() {
        name = savedName;
        role = savedRole;
      });
    } catch (e) {
      debugPrint("ERROR LOAD USER SIDEBAR: $e");
    }
  }

  // =========================================================
  // DETEKSI URL FOTO
  // =========================================================
  String? getFullPhotoUrl() {
    if (photoUrl == null ||
        photoUrl!.trim().isEmpty ||
        photoUrl == 'null') {
      return null;
    }

    String path = photoUrl!.trim();
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    if (path.startsWith('/')) {
      path = path.substring(1);
    }

    final filename = path.split('/').last;
    if (filename.isEmpty) return null;

    return 'http://127.0.0.1:8000/api/images/profile/$filename';
  }

  // =========================================================
  // INITIAL NAMA
  // =========================================================
  String getInitials(String text) {
    final words = text.trim().split(" ");
    if (words.isEmpty || words.first.isEmpty) return "P";
    if (words.length == 1) return words.first[0].toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  // =========================================================
  // LOGOUT
  // =========================================================
  Future<void> _logout() async {
    final confirmLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Keluar", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("Apakah Anda yakin ingin keluar dari akun?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Keluar"),
            ),
          ],
        );
      },
    );

    if (confirmLogout != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("auth_token");
      await prefs.remove("token");
      await prefs.remove("access_token");
      await prefs.remove("name");
      await prefs.remove("email");
      await prefs.remove("phone");
      await prefs.remove("address");
      await prefs.remove("profile_image");
      await prefs.remove("role");
      await prefs.remove("user_id");
      await prefs.remove("userId");
      await prefs.setBool("isLoggedIn", false);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingPage()),
        (route) => false,
      );
    } catch (e) {
      debugPrint("ERROR LOGOUT: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal keluar dari akun: $e"),
          backgroundColor: Colors.red,
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
    final isMobile = MediaQuery.of(context).size.width < 700;
    final fullPhotoUrl = getFullPhotoUrl();

    return SafeArea(
      child: Container(
        width: isMobile ? 240 : 260,
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: isMobile ? 22 : 24,
                    backgroundColor: const Color(0xff2196F3),
                    backgroundImage: fullPhotoUrl != null ? NetworkImage(fullPhotoUrl) : null,
                    child: fullPhotoUrl == null
                        ? Text(
                            getInitials(name),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 14 : 15,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          role,
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    _menu(context,
                        icon: Icons.home_outlined, title: "Beranda", menu: SidebarMenu.beranda),
                    _menu(context,
                        icon: Icons.notifications_none_outlined, title: "Notifikasi", menu: SidebarMenu.notifikasi),
                    _menu(context,
                        icon: Icons.settings_outlined, title: "Pengaturan", menu: SidebarMenu.pengaturan),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: InkWell(
                onTap: _logout,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: isMobile ? 52 : 56,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        size: isMobile ? 22 : 24,
                        color: Colors.red.shade600,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          "Keluar",
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 2, bottom: MediaQuery.of(context).padding.bottom + 16),
              child: Text(
                "SayaBantu v1.0",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
  Widget _menu(BuildContext context, {required IconData icon, required String title, required SidebarMenu menu}) {
    final isMobile = MediaQuery.of(context).size.width < 700;
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
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: active ? Theme.of(context).colorScheme.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: isMobile ? 22 : 24,
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  fontWeight: active ? FontWeight.bold : FontWeight.w600,
                  color: active
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}