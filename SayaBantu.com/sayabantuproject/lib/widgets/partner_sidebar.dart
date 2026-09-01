import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/partner_sidebar_menu.dart';
import '../services/api_service.dart'; // Pastikan path import api_service benar

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
  
  // Variabel state untuk menampung data dari database
  int totalPoint = 0;
  bool isVerified = false;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString("name") ?? "Partner";
    final image = prefs.getString("profile_image");

    if (!mounted) return;

    setState(() {
      username = savedName;
      profileImage = image != null ? base64Decode(image) : null;

      final words = savedName.trim().split(" ");
      if (words.length >= 2) {
        initials = "${words.first[0]}${words.last[0]}".toUpperCase();
      } else if (savedName.isNotEmpty) {
        initials = savedName[0].toUpperCase();
      } else {
        initials = "P";
      }
    });

    // Mengambil data Poin dan Status Verifikasi dari API Backend (/mitra/profile)
    try {
      final response = await ApiService.get('/mitra/profile');

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        final data = decodedData['data'];

        if (!mounted) return;

        setState(() {
          totalPoint = int.tryParse(data['point']?.toString() ?? '0') ?? 0;
          isVerified = data['is_verified'] == true || data['is_verified'] == 1;
        });
      }
    } catch (e) {
      debugPrint("GAGAL MEMUAT PROFIL MITRA: $e");
    }
  }

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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
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

            // Kotak Total Poin (Dinamis dari database)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                        color: Colors.amber,
                        size: 32,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "$totalPoint", // Menampilkan poin asli dari database
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

            // Widget Akun Terverifikasi (Hanya muncul jika is_verified bernilai 1 di database)
            if (isVerified)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xffE8F7EE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
              icon: Icons.settings,
              title: "Pengaturan",
              menu: PartnerSidebarMenu.pengaturan,
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _menu(
    BuildContext context, {
    required IconData icon,
    required String title,
    required PartnerSidebarMenu menu,
  }) {
    final active = widget.activeMenu == menu;

    return InkWell(
      onTap: () => widget.onMenuSelected(menu),
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
              color: active ? Colors.orange : Colors.white70,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? Colors.orange : Colors.white,
                  fontWeight:
                      active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}