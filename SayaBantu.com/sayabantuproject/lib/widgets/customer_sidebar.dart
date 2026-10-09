import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:sayabantu_project/screens/Screens_Landing/landing_page.dart';

import '../models/sidebar_menu.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../theme/app_colors.dart';

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
    final savedName = AuthStorage.getString("name") ?? "Pengguna";
    final savedRole = AuthStorage.getString("role") ?? "Pelanggan";

    if (!mounted) return;

    setState(() {
      name = savedName;
      role = savedRole;
    });

    try {
      final response = await ApiService.get('/user');

      debugPrint("===== CUSTOMER SIDEBAR USER =====");
      debugPrint("STATUS : ${response.statusCode}");
      debugPrint("BODY   : ${response.body}");

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        final dynamic userData = decodedData is Map<String, dynamic>
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
        }
      } else {
        debugPrint("GAGAL MEMUAT USER: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("ERROR LOAD USER CUSTOMER SIDEBAR: $e");
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

    if (path.startsWith('http://') || path.startsWith('https://')) {
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
          color: AppColors.mint, // ← dari orange → mint
        ),
        alignment: Alignment.center,
        child: Text(
          getInitials(name),
          style: const TextStyle(
            color: AppColors.darkTeal, // ← text dark teal di atas mint
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
        color: AppColors.mint,
      ),
      child: ClipOval(
        child: Image.network(
          fullPhotoUrl,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          cacheWidth: 120,
          cacheHeight: 120,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }

            return Container(
              width: 52,
              height: 52,
              color: AppColors.mint,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.darkTeal,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint("GAGAL MENAMPILKAN FOTO CUSTOMER SIDEBAR");
            debugPrint("URL FOTO: $fullPhotoUrl");
            debugPrint("ERROR: $error");

            return Container(
              width: 52,
              height: 52,
              color: AppColors.mint,
              alignment: Alignment.center,
              child: Text(
                getInitials(name),
                style: const TextStyle(
                  color: AppColors.darkTeal,
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
                    color: AppColors.primaryTeal,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Keluar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey900,
                    ),
                  ),
                ],
              ),
              content: const Text(
                'Apakah kamu yakin ingin keluar dari akun?',
                style: TextStyle(
                  color: AppColors.grey700,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      color: AppColors.grey600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal, // ← teal
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Keluar',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
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
      // ✅ Clear sessionStorage — hapus semua key auth untuk tab ini
      AuthStorage.clear();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LandingPage()),
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
            content: Text('Gagal keluar dari akun: $e'),
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

      // ✅ dari #111827 (hitam) → dark teal
      color: AppColors.darkTeal,

      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // =================================================
            // PROFILE USER
            // =================================================

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  _buildProfileImage(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          role,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.white.withOpacity(0.65),
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
            ? AppColors.mint.withOpacity(0.15) // ← dari orange soft → mint soft
            : Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              color: active
                  ? AppColors.mint // ← aktif → mint
                  : AppColors.white.withOpacity(0.70),
              size: 22,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active
                      ? AppColors.mint // ← aktif → mint
                      : AppColors.white.withOpacity(0.85),
                  fontWeight: active
                      ? FontWeight.bold
                      : FontWeight.w500,
                  fontSize: 14.5,
                ),
              ),
            ),

            // ✅ Aksen bar kecil di kanan menu aktif
            if (active)
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(2),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
            // ✅ dari merah → soft white/transparent (muted)
            color: AppColors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.white.withOpacity(0.15),
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
                    color: AppColors.mint,
                  ),
                )
              else
                const Icon(
                  Icons.logout,
                  color: AppColors.mint, // ← ikon keluar mint
                  size: 20,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isLoggingOut ? 'Keluar...' : 'Keluar',
                  style: const TextStyle(
                    color: AppColors.white, // ← text putih
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