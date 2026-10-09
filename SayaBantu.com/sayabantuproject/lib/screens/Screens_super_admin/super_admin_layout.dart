import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/auth_storage.dart';

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
  // NAVIGATION
  // =========================================================

  /// Index halaman yang aktif:
  /// 0 = Analytics
  /// 1 = Kelola Admin
  /// 2 = Mitra Aktif
  /// 3 = Pengaturan Sistem
  /// 4 = Profil
  /// 5 = Log Aktivitas (hanya via AppBar di mobile)
  int _selectedIndex = 0;

  static const Color _accent = Color(0xFFEF476F);
  static const Color _sidebarBg = Color(0xFF0E172A);
  static const Color _sidebarSelected = Color(0xFF1E2A40);

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
  // FULL PHOTO URL
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
  // INITIALS
  // =========================================================

  String _getInitials() {
    final text = superAdminName.trim();
    if (text.isEmpty) return 'SA';

    final words = text.split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return ('${words.first[0]}${words.last[0]}').toUpperCase();
    }
    return words.first[0].toUpperCase();
  }

  // =========================================================
  // PREVIEW IMAGE DIALOG
  // =========================================================

  void _showImageDialog(BuildContext context, ImageProvider imageProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
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
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
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
  // PROFILE IMAGE
  // =========================================================

  Widget _buildSuperAdminProfileImage({double size = 42}) {
    final fullPhotoUrl = _getFullPhotoUrl();

    if (fullPhotoUrl == null) {
      return GestureDetector(
        onTap: _showEditProfileDialog,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: _accent,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            _getInitials(),
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.35,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showImageDialog(context, NetworkImage(fullPhotoUrl)),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: _accent,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.network(
            fullPhotoUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: size,
                height: size,
                color: _accent,
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: size,
                height: size,
                color: _accent,
                alignment: Alignment.center,
                child: Text(
                  _getInitials(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.35,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // =========================================================
  // DIALOG PROFILE IMAGE
  // =========================================================

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
            errorBuilder: (context, error, stackTrace) {
              return _buildDialogInitials();
            },
          ),
        ),
      );
    }

    return _buildDialogInitials();
  }

  Widget _buildDialogInitials() {
    return GestureDetector(
      onTap: _showEditProfileDialog,
      child: Container(
        width: 100,
        height: 100,
        decoration: const BoxDecoration(
          color: _accent,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          _getInitials(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // PICK PHOTO
  // =========================================================

  Future<void> _pickProfilePhoto() async {
    // Gunakan Completer agar fungsi ini menunggu sampai file selesai dibaca
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal membaca foto.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } finally {
          // Tandai bahwa proses sudah selesai, apapun hasilnya
          completer.complete();
        }
      });
    });

    // Kembalikan Future yang akan selesai ketika completer.complete() dipanggil
    return completer.future;
  }

  // =========================================================
  // UPLOAD PHOTO
  // =========================================================

  Future<bool> _uploadProfilePhoto() async {
    if (selectedPhotoBytes == null || selectedPhotoName == null) {
      return true;
    }

    if (mounted) {
      setState(() {
        isUploadingPhoto = true;
      });
    }

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
      } else if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengupload foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          isUploadingPhoto = false;
        });
      }
    }
  }

  // =========================================================
  // EDIT PROFILE DIALOG
  // =========================================================

  Future<void> _showEditProfileDialog() async {
    final nameController = TextEditingController(text: superAdminName);

    setState(() {
      selectedPhotoBytes = null;
      selectedPhotoName = null;
    });

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Edit Profil Super Admin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
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
                        Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: _buildDialogProfileImage(),
                        ),
                        Material(
                          color: _accent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: isSavingProfile || isUploadingPhoto
                                ? null
                                : () async {
                                    // Tunggu proses pemilihan dan pembacaan foto selesai
                                    await _pickProfilePhoto();
                                    // Setelah selesai, perbarui tampilan dialog
                                    if (mounted) {
                                      setDialogState(() {});
                                    }
                                  },
                            child: const Padding(
                              padding: EdgeInsets.all(9),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Klik ikon kamera untuk mengganti foto',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                    if (selectedPhotoName != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        selectedPhotoName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
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
                          borderSide: const BorderSide(color: _accent),
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
                        prefixIcon:
                            const Icon(Icons.admin_panel_settings_outlined),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Nama tidak boleh kosong.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setState(() {
                            isSavingProfile = true;
                          });

                          try {
                            bool nameUpdated = false;
                            bool photoUpdated = false;

                            if (newName != superAdminName) {
                              final response = await ApiService.put(
                                '/user/profile',
                                {'name': newName},
                              );

                              if (response.statusCode != 200) {
                                String message = 'Gagal memperbarui nama.';
                                try {
                                  final data = jsonDecode(response.body);
                                  if (data is Map<String, dynamic>) {
                                    message = data['message']?.toString() ??
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
                                throw Exception('Foto gagal diperbarui.');
                              }
                            }

                            AuthStorage.setString('name', newName);

                            if (!mounted) return;

                            setState(() {
                              superAdminName = newName;
                              selectedPhotoBytes = null;
                              selectedPhotoName = null;
                            });

                            if (Navigator.of(dialogContext).canPop()) {
                              Navigator.of(dialogContext).pop();
                            }

                            String message = 'Profil berhasil diperbarui.';
                            if (nameUpdated && photoUpdated) {
                              message =
                                  'Nama dan foto profil berhasil diperbarui.';
                            } else if (photoUpdated) {
                              message = 'Foto profil berhasil diperbarui.';
                            } else if (nameUpdated) {
                              message = 'Nama berhasil diperbarui.';
                            }

                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(message),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            debugPrint('ERROR UPDATE SUPER ADMIN: $e');
                            if (!mounted) return;

                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Gagal memperbarui profil: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() {
                                isSavingProfile = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
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
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Simpan',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ],
            );
          },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 700;
        if (isDesktop) return _buildDesktopLayout();
        return _buildMobileLayout();
      },
    );
  }

  // =========================================================
  // DESKTOP LAYOUT — Sidebar kiri
  // =========================================================

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FB),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSidebar(),
          Expanded(child: _buildContentArea()),
        ],
      ),
    );
  }

  // =========================================================
  // MOBILE LAYOUT — Bottom Nav + AppBar icon
  // =========================================================

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FB),

      // APPBAR — tanpa title, dengan ikon Log Aktivitas
      appBar: AppBar(
        toolbarHeight: 56,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0E172A),
        automaticallyImplyLeading: false,

        // Avatar + nama
        title: Row(
          children: [
            _buildSuperAdminProfileImage(size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: _showEditProfileDialog,
                child: Text(
                  superAdminName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0E172A),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Ikon: Log Aktivitas
        actions: [
          IconButton(
            tooltip: 'Log Aktivitas',
            icon: Icon(
              _selectedIndex == 5
                  ? Icons.folder_rounded
                  : Icons.folder_outlined,
              color: _selectedIndex == 5
                  ? _accent
                  : const Color(0xFF0E172A),
            ),
            onPressed: () {
              setState(() {
                _selectedIndex = 5;
              });
            },
          ),
          const SizedBox(width: 4),
        ],
      ),

      // BODY
      body: _buildContentArea(),

      // BOTTOM NAVIGATION — 5 tab
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _selectedIndex >= 0 && _selectedIndex <= 4
                ? _selectedIndex
                : 0,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: _accent,
            unselectedItemColor: const Color(0xFF94A3B8),
            selectedFontSize: 10.5,
            unselectedFontSize: 10.5,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined, size: 22),
                activeIcon: Icon(Icons.bar_chart_rounded, size: 22),
                label: 'Analytics',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 22,
                ),
                activeIcon: Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 22,
                ),
                label: 'Admin',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.engineering_outlined, size: 22),
                activeIcon: Icon(Icons.engineering_rounded, size: 22),
                label: 'Mitra',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined, size: 22),
                activeIcon: Icon(Icons.settings_rounded, size: 22),
                label: 'Sistem',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline, size: 22),
                activeIcon: Icon(Icons.person_rounded, size: 22),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
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
  // SIDEBAR — hanya untuk desktop
  // =========================================================

  Widget _buildSidebar() {
    return Container(
      width: 220,
      height: double.infinity,
      color: _sidebarBg,
      child: Column(
        children: [
          // HEADER SUPER ADMIN
          Container(
            height: 85,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF243047)),
              ),
            ),
            child: Row(
              children: [
                _buildSuperAdminProfileImage(size: 42),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: _showEditProfileDialog,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          superAdminName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Full Control Access',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFFF4F4F),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // MENU — 6 item (Profil sebelum Log)
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
            icon: Icons.engineering_rounded,
            title: 'Mitra Aktif',
          ),
          _buildMenuItem(
            index: 3,
            icon: Icons.settings_rounded,
            title: 'Pengaturan Sistem',
          ),
          _buildMenuItem(
            index: 4,
            icon: Icons.person_rounded,
            title: 'Profil',
          ),
          _buildMenuItem(
            index: 5,
            icon: Icons.folder_rounded,
            title: 'Log Aktivitas',
          ),

          const Spacer(),

          _buildLogoutButton(),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  // =========================================================
  // MENU ITEM
  // =========================================================

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
          color: selected ? _sidebarSelected : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: selected ? const Color(0xFFFF4848) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 17),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : const Color(0xFF91A0B9),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF91A0B9),
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // LOGOUT BUTTON (desktop sidebar)
  // =========================================================

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: _logout,
      child: Container(
        height: 48,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 17),
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

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari akun Super Admin?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
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
  // HALAMAN PROFIL
  // =========================================================

  Widget _buildProfilePage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final horizontalPadding = isMobile ? 16.0 : 32.0;
        final verticalPadding = isMobile ? 16.0 : 28.0;

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFFF5F7FB),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    Text(
                      'Profil Super Admin',
                      style: TextStyle(
                        fontSize: isMobile ? 22 : 26,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kelola informasi profil akun Super Admin.',
                      style: TextStyle(
                        fontSize: isMobile ? 12.5 : 13,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),

                    SizedBox(height: isMobile ? 20 : 24),

                    // PROFILE CARD
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isMobile ? 20 : 26),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: [
                          _buildSuperAdminProfileImage(size: 100),
                          const SizedBox(height: 18),

                          Text(
                            superAdminName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE4E4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.admin_panel_settings,
                                  size: 13,
                                  color: Color(0xFFDC2626),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Super Admin',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                          const Divider(
                            height: 1,
                            color: Color(0xFFF3F4F6),
                          ),
                          const SizedBox(height: 20),

                          // ============================
                          // TOMBOL EDIT PROFIL
                          // ============================
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _showEditProfileDialog,
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 18,
                              ),
                              label: const Text(
                                'Edit Profil',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),

                          // ============================
                          // TOMBOL LOGOUT (TAMBAHAN)
                          // ============================
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _logout,
                              icon: const Icon(
                                Icons.logout_rounded,
                                size: 18,
                                color: Color(0xFFDC2626),
                              ),
                              label: const Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFFCA5A5),
                                ),
                                backgroundColor: const Color(0xFFFEF2F2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // INFO NOTE
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFBFDBFE),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Color(0xFF2563EB),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Foto profil akan tampil di sidebar dan AppBar. Klik foto untuk memperbesar.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1E40AF),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}