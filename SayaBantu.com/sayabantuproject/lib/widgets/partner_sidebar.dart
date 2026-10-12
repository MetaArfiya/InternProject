import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:sayabantu_project/screens/Screens_Landing/landing_page.dart';

import '../models/partner_sidebar_menu.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../theme/app_colors.dart';

class PartnerSidebar extends StatefulWidget {
  final PartnerSidebarMenu activeMenu;
  final Function(PartnerSidebarMenu) onMenuSelected;

  const PartnerSidebar({
    super.key,
    required this.activeMenu,
    required this.onMenuSelected,
  });

  @override
  PartnerSidebarState createState() => PartnerSidebarState();
}

class PartnerSidebarState extends State<PartnerSidebar> {
  String username = "Partner";
  String? photoUrl;
  String initials = "P";

  int totalPoint = 0;
  bool isVerified = false;

  bool isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  // =========================================================
  // REFRESH PROFILE DARI LUAR
  // =========================================================

  void refreshProfile() {
    loadUser();
  }

  // =========================================================
  // LOAD DATA USER
  // =========================================================

  Future<void> loadUser() async {
    final savedName = AuthStorage.getString("name") ?? "Partner";

    if (!mounted) return;

    setState(() {
      username = savedName;
      initials = getInitials(savedName);
    });

    // AMBIL DATA USER
    try {
      final response = await ApiService.get('/user');

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
              username = apiName.trim();
              initials = getInitials(apiName);
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
      debugPrint("ERROR LOAD USER PARTNER SIDEBAR: $e");
    }

    // AMBIL DATA PROFIL MITRA
    try {
      final response = await ApiService.get('/mitra/profile');

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        final data = decodedData['data'];

        if (data != null && data is Map) {
          if (!mounted) return;

          setState(() {
            totalPoint =
                int.tryParse(data['point']?.toString() ?? '0') ?? 0;

            isVerified = data['is_verified'] == true ||
                data['is_verified'] == 1 ||
                data['is_verified']?.toString() == '1' ||
                data['is_verified']?.toString().toLowerCase() == 'true';
          });
        }
      } else {
        debugPrint("GAGAL MEMUAT PROFIL MITRA: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("ERROR LOAD PROFIL MITRA: $e");
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
          color: AppColors.mint, // ← dari orange
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: const TextStyle(
            color: AppColors.darkTeal, // ← text dark teal
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
            debugPrint("GAGAL MENAMPILKAN FOTO SIDEBAR");
            debugPrint("URL FOTO: $fullPhotoUrl");
            debugPrint("ERROR: $error");

            return Container(
              width: 52,
              height: 52,
              color: AppColors.mint,
              alignment: Alignment.center,
              child: Text(
                initials,
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

  Future<void> logout() async {
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
                  Icon(Icons.logout, color: AppColors.primaryTeal),
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
                style: TextStyle(color: AppColors.grey700),
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
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Keluar',
                    style: TextStyle(fontWeight: FontWeight.w600),
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
      color: AppColors.darkTeal, // ← dari #111827 (hitam)
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
                          username,
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
                          "Mitra Aktif",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
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
            // TOTAL POIN
            // =================================================

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                // ✅ dari orange gradient → teal gradient
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primaryTeal,
                    AppColors.darkTeal,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "TOTAL POIN SAYA",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: AppColors.mint, // ← dari amber
                        size: 32,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "$totalPoint",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Peringkat mitra aktif",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // =================================================
            // AKUN TERVERIFIKASI
            // =================================================

            if (isVerified)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7), // tetap hijau
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check,
                      color: Color(0xFF16A34A),
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      "Akun Terverifikasi",
                      style: TextStyle(
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 25),

            // =================================================
            // MENU
            // =================================================

            _menu(
              context,
              icon: Icons.home_outlined,
              title: "Cari Pekerjaan",
              menu: PartnerSidebarMenu.cariPekerjaan,
            ),
            _menu(
              context,
              icon: Icons.assignment_outlined,
              title: "Penawaran Aktif",
              menu: PartnerSidebarMenu.penawaranAktif,
            ),
            _menu(
              context,
              icon: Icons.account_balance_wallet_outlined,
              title: "Penghasilan",
              menu: PartnerSidebarMenu.penghasilan,
            ),
            _menu(
              context,
              icon: Icons.payment_outlined,
              title: "Pembayaran",
              menu: PartnerSidebarMenu.pembayaran,
            ),
            _menu(
              context,
              icon: Icons.notifications_outlined,
              title: "Notifikasi",
              menu: PartnerSidebarMenu.notifikasi,
            ),
            _menu(
              context,
              icon: Icons.report_problem_outlined,
              title: "Pengaduan",
              menu: PartnerSidebarMenu.pengaduan,
            ),
            _menu(
              context,
              icon: Icons.settings_outlined,
              title: "Pengaturan",
              menu: PartnerSidebarMenu.pengaturan,
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
    required PartnerSidebarMenu menu,
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
            ? AppColors.mint.withOpacity(0.15) // ← dari orange soft
            : Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              color: active
                  ? AppColors.mint // ← aktif → mint
                  : Colors.white.withOpacity(0.70),
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
                      : Colors.white.withOpacity(0.85),
                  fontWeight:
                      active ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14.5,
                ),
              ),
            ),
            // Aksen bar kecil di kanan menu aktif
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
        onTap: isLoggingOut ? null : logout,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            // ✅ dari merah soft → putih soft (muted)
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
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
                  color: AppColors.mint, // ← dari merah
                  size: 20,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isLoggingOut ? 'Keluar...' : 'Keluar',
                  style: const TextStyle(
                    color: Colors.white, // ← dari merah
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