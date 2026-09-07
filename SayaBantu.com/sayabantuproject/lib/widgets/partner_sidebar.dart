import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/partner_sidebar_menu.dart';
import '../services/api_service.dart';
import '../../screens/Screens_auth/login_page.dart';

class PartnerSidebar extends StatefulWidget {
  final PartnerSidebarMenu activeMenu;
  final Function(PartnerSidebarMenu) onMenuSelected;

  const PartnerSidebar({
    super.key,
    required this.activeMenu,
    required this.onMenuSelected,
  });

  @override
  State<PartnerSidebar> createState() => _PartnerSidebarState();
}

class _PartnerSidebarState extends State<PartnerSidebar> {
  String username = "Partner";
  Uint8List? profileImage;
  String initials = "P";

  int totalPoint = 0;
  bool isVerified = false;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  // ============================================================
  // LOAD USER
  // ============================================================

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    final savedName = prefs.getString("name") ?? "Partner";
    final image = prefs.getString("profile_image");

    Uint8List? decodedImage;

    if (image != null && image.isNotEmpty) {
      try {
        decodedImage = base64Decode(image);
      } catch (e) {
        debugPrint("Gagal membaca profile image: $e");
      }
    }

    if (!mounted) return;

    setState(() {
      username = savedName;
      profileImage = decodedImage;

      final words = savedName.trim().split(RegExp(r'\s+'));

      if (words.length >= 2) {
        initials =
            "${words.first[0]}${words.last[0]}".toUpperCase();
      } else if (savedName.isNotEmpty) {
        initials = savedName[0].toUpperCase();
      } else {
        initials = "P";
      }
    });

    // ==========================================================
    // LOAD DATA PROFIL MITRA DARI API
    // ==========================================================

    try {
      final response = await ApiService.get('/mitra/profile');

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        final data = decodedData['data'];

        if (!mounted) return;

        setState(() {
          totalPoint =
              int.tryParse(
                data['point']?.toString() ?? '0',
              ) ??
              0;

          isVerified =
              data['is_verified'] == true ||
              data['is_verified'] == 1;
        });
      }
    } catch (e) {
      debugPrint(
        "GAGAL MEMUAT PROFIL MITRA: $e",
      );
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    final bool? confirm = await showDialog<bool>(
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
                color: Colors.orange,
              ),
              SizedBox(width: 10),
              Text(
                "Logout",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            "Apakah kamu yakin ingin keluar dari akun?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                "Batal",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // ========================================================
      // UBAH STATUS LOGIN MENJADI FALSE
      // ========================================================

      await prefs.setBool("isLoggedIn", false);

      // ========================================================
      // HAPUS TOKEN
      // ========================================================

      await prefs.remove("token");
      await prefs.remove("access_token");

      // ========================================================
      // HAPUS DATA USER
      // ========================================================

      await prefs.remove("name");
      await prefs.remove("email");
      await prefs.remove("phone");
      await prefs.remove("address");
      await prefs.remove("profile_image");

      if (!mounted) return;

      // ========================================================
      // KEMBALI KE LOGIN
      //
      // PENTING:
      // Gunakan ROOT NAVIGATOR agar semua halaman dashboard
      // yang mungkin bertumpuk ikut dibersihkan.
      // ========================================================

      Navigator.of(
        context,
        rootNavigator: true,
      ).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint(
        "GAGAL LOGOUT: $e",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Terjadi kesalahan saat logout.",
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: double.infinity,
      color: const Color(0xff111827),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ==================================================
            // PROFILE
            // ==================================================

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.orange,
                    backgroundImage: profileImage != null
                        ? MemoryImage(profileImage!)
                        : null,
                    child: profileImage == null
                        ? Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
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

                        const Text(
                          "Mitra Aktif",
                          style: TextStyle(
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

            // ==================================================
            // TOTAL POIN
            // ==================================================

            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xffFF8A00),
                    Color(0xffF97316),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
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
                        color: Colors.amber,
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

            // ==================================================
            // AKUN TERVERIFIKASI
            // ==================================================

            if (isVerified)
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffE8F7EE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check,
                      color: Colors.green,
                      size: 18,
                    ),

                    SizedBox(width: 6),

                    Text(
                      "Akun Terverifikasi",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 25),

            // ==================================================
            // CARI PEKERJAAN
            // ==================================================

            _menu(
              context,
              icon: Icons.home_outlined,
              title: "Cari Pekerjaan",
              menu: PartnerSidebarMenu.cariPekerjaan,
            ),

            // ==================================================
            // PENAWARAN AKTIF
            // ==================================================

            _menu(
              context,
              icon: Icons.assignment_outlined,
              title: "Penawaran Aktif",
              menu: PartnerSidebarMenu.penawaranAktif,
            ),

            // ==================================================
            // PENGATURAN
            // ==================================================

            _menu(
              context,
              icon: Icons.settings,
              title: "Pengaturan",
              menu: PartnerSidebarMenu.pengaturan,
            ),

            // ==================================================
            // DORONG LOGOUT KE BAGIAN BAWAH
            // ==================================================

            const Spacer(),

            // ==================================================
            // LOGOUT
            // ==================================================

            _logoutMenu(),

            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MENU SIDEBAR
  // ============================================================

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
            ? Colors.orange.withOpacity(0.2)
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

  // ============================================================
  // LOGOUT MENU
  // ============================================================

  Widget _logoutMenu() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _logout,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
          child: Row(
            children: [
              Icon(
                Icons.logout,
                color: Colors.red.shade400,
              ),

              const SizedBox(width: 15),

              const Expanded(
                child: Text(
                  "Keluar",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
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