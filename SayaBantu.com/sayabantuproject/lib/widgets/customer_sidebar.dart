import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sidebar_menu.dart';

class CustomerSidebar extends StatefulWidget {
  final SidebarMenu activeMenu;
  final Function(SidebarMenu) onMenuSelected;

  const CustomerSidebar({
    super.key,
    required this.activeMenu,
    required this.onMenuSelected,
  });

  @override
  State<CustomerSidebar> createState() => _CustomerSidebarState();
}

class _CustomerSidebarState extends State<CustomerSidebar> {
  String name = "Pengguna";
  String role = "Pelanggan";
  Uint8List? profileImage;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    final image = prefs.getString("profile_image");

    if (!mounted) return;

    setState(() {
      name = prefs.getString("name") ?? "Pengguna";
      role = prefs.getString("role") ?? "Pelanggan";

      if (image != null && image.isNotEmpty) {
        profileImage = base64Decode(image);
      } else {
        profileImage = null;
      }
    });
  }

  @override
  void didUpdateWidget(covariant CustomerSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    loadUser();
  }

  String getInitials(String text) {
    final words = text.trim().split(" ");

    if (words.isEmpty || words.first.isEmpty) return "P";

    if (words.length == 1) {
      return words.first[0].toUpperCase();
    }

    return (words[0][0] + words[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return SafeArea(
      child: Container(
        width: isMobile ? 240 : 260,
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            const SizedBox(height: 24),

            //==================== PROFILE ====================

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: isMobile ? 22 : 24,
                    backgroundColor: const Color(0xff2196F3),
                    backgroundImage:
                        profileImage != null ? MemoryImage(profileImage!) : null,
                    child: profileImage == null
                        ? Text(
                            getInitials(name),
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
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
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
                    _menu(
                      context,
                      icon: Icons.home_outlined,
                      title: "Beranda",
                      menu: SidebarMenu.beranda,
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
                  ],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Text(
                "SayaBantu v1.0",
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menu(
    BuildContext context, {
    required IconData icon,
    required String title,
    required SidebarMenu menu,
  }) {
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
        margin: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 4,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: active
              ? Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: isMobile ? 22 : 24,
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  fontWeight:
                      active ? FontWeight.bold : FontWeight.w600,
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