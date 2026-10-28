import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/auth_storage.dart';
import '../../theme/admin_theme.dart';
import '../../theme/admin_theme_provider.dart';
import '../../theme/app_colors.dart';

import 'analytics_page.dart';
import 'manage_admin_page.dart';
import 'system_setting_page.dart';
import 'activity_log_page.dart';
import 'active_partner_page.dart';

import '../Screens_Landing/landing_page.dart';

class SuperAdminLayout extends StatefulWidget {
  const SuperAdminLayout({super.key});

  @override
  State<SuperAdminLayout> createState() => _SuperAdminLayoutState();
}

class _SuperAdminLayoutState extends State<SuperAdminLayout> {
  // =========================================================
  // THEME
  // =========================================================

  AdminTheme get theme => AdminTheme.of('admin');

  // =========================================================
  // NAVIGATION
  // =========================================================

  int _selectedIndex = 0;

  // =========================================================
  // MENUS
  // =========================================================

  static const List<Map<String, dynamic>> _menus = [
    {
      'key': 'analytics',
      'title': 'Analytics',
      'icon': Icons.bar_chart_outlined,
      'activeIcon': Icons.bar_chart_rounded,
      'shortLabel': 'Analytics',
    },
    {
      'key': 'manage_admin',
      'title': 'Kelola Admin',
      'icon': Icons.admin_panel_settings_outlined,
      'activeIcon': Icons.admin_panel_settings_rounded,
      'shortLabel': 'Admin',
    },
    {
      'key': 'active_partner',
      'title': 'Mitra Aktif',
      'icon': Icons.engineering_outlined,
      'activeIcon': Icons.engineering_rounded,
      'shortLabel': 'Mitra',
    },
    {
      'key': 'system',
      'title': 'Pengaturan Sistem',
      'icon': Icons.settings_outlined,
      'activeIcon': Icons.settings_rounded,
      'shortLabel': 'Sistem',
    },
    {
      'key': 'profile',
      'title': 'Profil',
      'icon': Icons.person_outline,
      'activeIcon': Icons.person_rounded,
      'shortLabel': 'Profil',
    },
    {
      'key': 'activity_log',
      'title': 'Log Aktivitas',
      'icon': Icons.folder_outlined,
      'activeIcon': Icons.folder_rounded,
      'shortLabel': 'Log',
    },
  ];

  // =========================================================
  // SUPER ADMIN DATA
  // =========================================================

  String superAdminName = 'Super Admin';
  String? superAdminPhotoUrl;

  // =========================================================
  // PHOTO DATA
  // =========================================================

  Uint8List? selectedPhotoBytes;
  String? selectedPhotoName;
  bool isUploadingPhoto = false;
  bool isSavingProfile = false;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();
    _loadSuperAdminProfile();
  }

  // =========================================================
  // LOAD SUPER ADMIN PROFILE
  // =========================================================

  Future<void> _loadSuperAdminProfile() async {
    try {
      final savedName = AuthStorage.getString('name');
      if (mounted && savedName != null && savedName.trim().isNotEmpty) {
        setState(() {
          superAdminName = savedName.trim();
        });
      }

      final response = await ApiService.get('/user');

      if (response.statusCode != 200) {
        debugPrint('GAGAL MEMUAT DATA SUPER ADMIN: ${response.statusCode}');
        return;
      }

      final decodedData = jsonDecode(response.body);
      dynamic userData;

      if (decodedData is Map<String, dynamic>) {
        userData = decodedData['user'] ?? decodedData['data'] ?? decodedData;
      }

      if (userData is Map<String, dynamic>) {
        final apiName = userData['name']?.toString();
        final apiPhoto = userData['photo_url']?.toString();

        if (!mounted) return;

        setState(() {
          if (apiName != null && apiName.trim().isNotEmpty) {
            superAdminName = apiName.trim();
          }

          if (apiPhoto != null &&
              apiPhoto.trim().isNotEmpty &&
              apiPhoto != 'null') {
            superAdminPhotoUrl = apiPhoto.trim();
          } else {
            superAdminPhotoUrl = null;
          }
        });

        if (apiName != null && apiName.trim().isNotEmpty) {
          AuthStorage.setString('name', apiName.trim());
        }
      }
    } catch (e) {
      debugPrint('ERROR LOAD SUPER ADMIN: $e');
    }
  }

  // =========================================================
  // HELPERS
  // =========================================================

  String? _getFullPhotoUrl() {
    if (superAdminPhotoUrl == null ||
        superAdminPhotoUrl!.trim().isEmpty ||
        superAdminPhotoUrl == 'null') {
      return null;
    }

    String path = superAdminPhotoUrl!.trim();

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    if (path.startsWith('/')) path = path.substring(1);

    final filename = path.split('/').last;
    if (filename.isEmpty) return null;

    return 'http://127.0.0.1:8000/api/images/profile/$filename';
  }

  String _getInitials() {
    final text = superAdminName.trim();
    if (text.isEmpty) return 'SA';

    final words = text.split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return ('${words.first[0]}${words.last[0]}').toUpperCase();
    }
    return words.first[0].toUpperCase();
  }

  int _getMenuIndex() {
    if (_selectedIndex < 0) return 0;
    if (_selectedIndex >= _menus.length) return 0;
    return _selectedIndex;
  }

  // =========================================================
  // PREVIEW IMAGE DIALOG
  // =========================================================

  void _showImageDialog(BuildContext context, ImageProvider imageProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Image(image: imageProvider, fit: BoxFit.contain),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================
  // PROFILE IMAGE — FIXED: SELALU BULAT
  // =========================================================

  Widget _buildSuperAdminProfileImage({double size = 40}) {
    final fullPhotoUrl = _getFullPhotoUrl();
    final t = theme;
    final bgColor = t.accentLight;
    final initials = _getInitials();

    return GestureDetector(
      onTap: _showEditProfileDialog,
      child: ClipOval(
        child: Container(
          width: size,
          height: size,
          color: bgColor,
          alignment: Alignment.center,
          child: fullPhotoUrl == null
              ? Text(
                  initials,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: size * 0.38,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Image.network(
                  fullPhotoUrl,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Text(
                    initials,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: size * 0.38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDialogProfileImage() {
    if (selectedPhotoBytes != null) {
      return GestureDetector(
        onTap: () =>
            _showImageDialog(context, MemoryImage(selectedPhotoBytes!)),
        child: ClipOval(
          child: Image.memory(
            selectedPhotoBytes!,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final fullPhotoUrl = _getFullPhotoUrl();
    if (fullPhotoUrl != null) {
      return GestureDetector(
        onTap: () => _showImageDialog(context, NetworkImage(fullPhotoUrl)),
        child: ClipOval(
          child: Image.network(
            fullPhotoUrl,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildDialogInitials(),
          ),
        ),
      );
    }

    return _buildDialogInitials();
  }

  Widget _buildDialogInitials() {
    final t = theme;
    return GestureDetector(
      onTap: _showEditProfileDialog,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: t.accent,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          _getInitials(),
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // ROLE CHIP
  // =========================================================

  Widget _roleChip({bool small = false, String label = 'Super Admin'}) {
    final t = theme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: t.badgeBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: t.badgeText,
          fontSize: small ? 9 : 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // =========================================================
  // PICK PHOTO
  // =========================================================

  Future<void> _pickProfilePhoto() async {
    final completer = Completer<void>();

    final input = html.FileUploadInputElement();
    input.accept = 'image/*';
    input.click();

    input.onChange.listen((event) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        completer.complete();
        return;
      }

      final file = files.first;
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);

      reader.onLoadEnd.listen((event) {
        if (reader.result == null) {
          completer.complete();
          return;
        }

        try {
          final Uint8List bytes = reader.result as Uint8List;

          if (mounted) {
            setState(() {
              selectedPhotoBytes = bytes;
              selectedPhotoName = file.name;
            });
          }
        } catch (e) {
          debugPrint('ERROR MEMBACA FOTO: $e');
          if (mounted) {
            _showSnack('Gagal membaca foto.', error: true);
          }
        } finally {
          completer.complete();
        }
      });
    });

    return completer.future;
  }

  // =========================================================
  // UPLOAD PHOTO
  // =========================================================

  Future<bool> _uploadProfilePhoto() async {
    if (selectedPhotoBytes == null || selectedPhotoName == null) {
      return true;
    }

    if (mounted) setState(() => isUploadingPhoto = true);

    try {
      final token = AuthStorage.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan.');
      }

      String mimeType = 'image/jpeg';
      final lowerName = selectedPhotoName!.toLowerCase();
      if (lowerName.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (lowerName.endsWith('.webp')) {
        mimeType = 'image/webp';
      }

      final blob = html.Blob([selectedPhotoBytes!], mimeType);
      final formData = html.FormData();
      formData.appendBlob('photo_profile', blob, selectedPhotoName!);

      final request = html.HttpRequest();
      request.open('POST', 'http://127.0.0.1:8000/api/user/profile/photo');
      request.setRequestHeader('Authorization', 'Bearer $token');

      request.send(formData);
      await request.onLoad.first;

      if (request.status == 200) {
        final responseText = request.responseText ?? '{}';
        final responseData = jsonDecode(responseText);

        dynamic userData;
        if (responseData is Map<String, dynamic>) {
          userData =
              responseData['user'] ?? responseData['data'] ?? responseData;
        }

        String? newPhotoUrl;
        if (userData is Map<String, dynamic>) {
          newPhotoUrl = userData['photo_url']?.toString();
        }

        if (mounted &&
            newPhotoUrl != null &&
            newPhotoUrl.trim().isNotEmpty &&
            newPhotoUrl != 'null') {
          setState(() {
            superAdminPhotoUrl = newPhotoUrl!.trim();
          });
        }

        if (newPhotoUrl == null ||
            newPhotoUrl.trim().isEmpty ||
            newPhotoUrl == 'null') {
          await _loadSuperAdminProfile();
        }

        return true;
      }

      String message = 'Gagal mengupload foto.';
      try {
        final errorData = jsonDecode(request.responseText ?? '{}');
        if (errorData is Map<String, dynamic>) {
          message = errorData['message']?.toString() ?? message;
        }
      } catch (_) {}

      throw Exception('$message (HTTP ${request.status})');
    } catch (e) {
      debugPrint('ERROR UPLOAD FOTO SUPER ADMIN: $e');
      if (mounted) _showSnack('Gagal mengupload foto: $e', error: true);
      return false;
    } finally {
      if (mounted) setState(() => isUploadingPhoto = false);
    }
  }

  // =========================================================
  // SNACKBAR
  // =========================================================

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    final t = theme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? t.danger : t.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================
  // EDIT PROFILE DIALOG
  // =========================================================

  Future<void> _showEditProfileDialog() async {
    final t = theme;
    final nameController = TextEditingController(text: superAdminName);

    setState(() {
      selectedPhotoBytes = null;
      selectedPhotoName = null;
    });

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AdminThemeProvider(
          theme: t,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                title: Text(
                  'Edit Profil Super Admin',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: t.cellText,
                  ),
                ),
                content: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          ClipOval(
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: _buildDialogProfileImage(),
                            ),
                          ),
                          Material(
                            color: t.accent,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: isSavingProfile || isUploadingPhoto
                                  ? null
                                  : () async {
                                      await _pickProfilePhoto();
                                      if (mounted) setDialogState(() {});
                                    },
                              child: const Padding(
                                padding: EdgeInsets.all(9),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  color: AppColors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Klik ikon kamera untuk mengganti foto',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: t.mutedText,
                          fontSize: 11,
                        ),
                      ),
                      if (selectedPhotoName != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          selectedPhotoName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: t.mutedText,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      TextField(
                        controller: nameController,
                        enabled: !isSavingProfile && !isUploadingPhoto,
                        decoration: InputDecoration(
                          labelText: 'Nama',
                          hintText: 'Masukkan nama',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: t.accent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        enabled: false,
                        controller:
                            TextEditingController(text: 'Super Admin'),
                        decoration: InputDecoration(
                          labelText: 'Role',
                          prefixIcon: const Icon(
                            Icons.admin_panel_settings_outlined,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSavingProfile || isUploadingPhoto
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: isSavingProfile || isUploadingPhoto
                        ? null
                        : () async {
                            final newName = nameController.text.trim();

                            if (newName.isEmpty) {
                              _showSnack(
                                'Nama tidak boleh kosong.',
                                error: true,
                              );
                              return;
                            }

                            setState(() => isSavingProfile = true);

                            try {
                              bool nameUpdated = false;
                              bool photoUpdated = false;

                              if (newName != superAdminName) {
                                final response = await ApiService.put(
                                  '/user/profile',
                                  {'name': newName},
                                );

                                if (response.statusCode != 200) {
                                  String message =
                                      'Gagal memperbarui nama.';
                                  try {
                                    final data =
                                        jsonDecode(response.body);
                                    if (data is Map<String, dynamic>) {
                                      message = data['message']
                                              ?.toString() ??
                                          message;
                                    }
                                  } catch (_) {}
                                  throw Exception(message);
                                }
                                nameUpdated = true;
                              }

                              if (selectedPhotoBytes != null) {
                                photoUpdated = await _uploadProfilePhoto();
                                if (!photoUpdated) {
                                  throw Exception(
                                    'Foto gagal diperbarui.',
                                  );
                                }
                              }

                              AuthStorage.setString('name', newName);

                              if (!dialogContext.mounted) return;

                              setState(() {
                                superAdminName = newName;
                                selectedPhotoBytes = null;
                                selectedPhotoName = null;
                              });

                              if (Navigator.of(dialogContext).canPop()) {
                                Navigator.of(dialogContext).pop();
                              }

                              String message =
                                  'Profil berhasil diperbarui.';
                              if (nameUpdated && photoUpdated) {
                                message =
                                    'Nama dan foto profil berhasil diperbarui.';
                              } else if (photoUpdated) {
                                message =
                                    'Foto profil berhasil diperbarui.';
                              } else if (nameUpdated) {
                                message = 'Nama berhasil diperbarui.';
                              }

                              _showSnack(message);
                            } catch (e) {
                              debugPrint(
                                  'ERROR UPDATE SUPER ADMIN: $e');
                              if (!mounted) return;
                              _showSnack(
                                'Gagal memperbarui profil: $e',
                                error: true,
                              );
                            } finally {
                              if (mounted) {
                                setState(() => isSavingProfile = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: t.accent,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: isSavingProfile || isUploadingPhoto
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Text(
                            'Simpan',
                            style:
                                TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    nameController.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return AdminThemeProvider(
      theme: t,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 700;
          if (isDesktop) {
            return _buildDesktopLayout(context);
          }
          return _buildMobileLayout();
        },
      ),
    );
  }

  // =========================================================
  // DESKTOP LAYOUT
  // =========================================================

  Widget _buildDesktopLayout(BuildContext context) {
    final t = theme;

    return Scaffold(
      backgroundColor: t.bg,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 250,
            child: _buildSidebar(context),
          ),
          Expanded(child: _buildContentArea()),
        ],
      ),
    );
  }

  // =========================================================
  // MOBILE LAYOUT
  // =========================================================

  Widget _buildMobileLayout() {
    final t = theme;
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.sidebarBg,
        surfaceTintColor: t.sidebarBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            _buildSuperAdminProfileImage(size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                superAdminName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: t.sidebarText,
                ),
              ),
            ),
            _roleChip(small: true),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Log Aktivitas',
            icon: Icon(
              _selectedIndex == 5
                  ? Icons.folder_rounded
                  : Icons.folder_outlined,
              color: _selectedIndex == 5 ? t.accent : t.sidebarText,
            ),
            onPressed: () => setState(() => _selectedIndex = 5),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildContentArea(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // =========================================================
  // CONTENT AREA
  // =========================================================

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

  // =========================================================
  // SIDEBAR
  // =========================================================

  Widget _buildSidebar(BuildContext context) {
    final t = theme;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: t.sidebarBg,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  _buildSuperAdminProfileImage(size: 52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          superAdminName,
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
                          'Super Admin',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                AppColors.white.withValues(alpha: 0.65),
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

            ..._menus.asMap().entries.map(
                  (entry) => _menuItem(
                    context: context,
                    index: entry.key,
                    icon: entry.value['icon'] as IconData,
                    title: entry.value['title'] as String,
                  ),
                ),

            const Spacer(),

            _logoutButton(context),

            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // MENU ITEM
  // =========================================================

  Widget _menuItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String title,
  }) {
    final bool active = _selectedIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
        color: active
            ? AppColors.mint.withValues(alpha: 0.15)
            : AppColors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              color: active
                  ? AppColors.mint
                  : AppColors.white.withValues(alpha: 0.70),
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
                      ? AppColors.mint
                      : AppColors.white.withValues(alpha: 0.85),
                  fontWeight:
                      active ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14.5,
                ),
              ),
            ),
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

  Widget _logoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: _logout,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.logout,
                color: AppColors.mint,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Keluar',
                  style: const TextStyle(
                    color: AppColors.white,
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

  // =========================================================
  // BOTTOM NAVIGATION BAR
  // =========================================================

  Widget _buildBottomNavigationBar() {
    final t = theme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: t.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _getMenuIndex() > 4 ? 0 : _getMenuIndex(),
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.white,
          selectedItemColor: t.accent,
          unselectedItemColor: t.sidebarMuted,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500),
          elevation: 0,
          items: _menus
              .take(5)
              .map(
                (m) => BottomNavigationBarItem(
                  icon: Icon(m['icon'] as IconData, size: 22),
                  activeIcon: Icon(m['activeIcon'] as IconData, size: 22),
                  label: m['shortLabel'] as String,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> _logout() async {
    final t = theme;
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AdminThemeProvider(
          theme: t,
          child: AlertDialog(
            title: Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: t.cellText,
              ),
            ),
            content: Text(
              'Apakah kamu yakin ingin keluar dari akun Super Admin?',
              style: TextStyle(color: t.mutedText),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.danger,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
        );
      },
    );

    if (shouldLogout != true) return;
    if (!mounted) return;

    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    AuthStorage.clear();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LandingPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (route) => false,
    );
  }

  // =========================================================
  // CONTENT
  // =========================================================

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const SuperAdminAnalyticsPage();
      case 1:
        return const ManageAdminPage();
      case 2:
        return const ActivePartnerPage();
      case 3:
        return const SystemSettingsPage();
      case 4:
        return _buildProfilePage();
      case 5:
        return const ActivityLogPage();
      default:
        return const SizedBox.shrink();
    }
  }

  // =========================================================
  // PROFILE PAGE (FONT & LAYOUT DISAMAKAN)
  // =========================================================

  Widget _buildProfilePage() {
    final t = theme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 700;
        final isTablet = width >= 700 && width < 1100;

        final horizontalPadding =
            isMobile ? 16.0 : (isTablet ? 24.0 : 28.0);
        final verticalPadding = isMobile ? 16.0 : 28.0;

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: t.bg,
          child: RefreshIndicator(
            onRefresh: _loadSuperAdminProfile,
            color: t.accent,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(t),
                  const SizedBox(height: 20),
                  _buildSectionLabel('Informasi Akun', t),
                  const SizedBox(height: 12),
                  _buildProfileCard(isMobile, t),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(AdminTheme t) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profil Super Admin',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: t.cellText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kelola informasi profil akun Super Admin.',
          style: textTheme.bodyMedium?.copyWith(color: t.mutedText),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text, AdminTheme t) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: t.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: t.cellText,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(bool isMobile, AdminTheme t) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          _buildSuperAdminProfileImage(size: 100),
          const SizedBox(height: 18),
          Text(
            superAdminName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: t.cellText,
            ),
          ),
          const SizedBox(height: 8),
          _roleChip(),
          const SizedBox(height: 20),
          Divider(height: 1, color: t.divider),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _showEditProfileDialog,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text(
                'Edit Profil',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: t.accent,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: Icon(
                Icons.logout_outlined,
                size: 18,
                color: t.danger,
              ),
              label: Text(
                'Keluar',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: t.danger,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: t.danger.withValues(alpha: 0.3),
                ),
                backgroundColor: t.danger.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}