import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';

import 'analytics_page.dart';
import 'manage_admin_page.dart';
import 'system_setting_page.dart';
import 'activity_log_page.dart';

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

  int _selectedIndex = 0;

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
      final prefs = await SharedPreferences.getInstance();

      // Ambil nama dari SharedPreferences terlebih dahulu
      final savedName = prefs.getString('name');
      if (mounted && savedName != null && savedName.trim().isNotEmpty) {
        setState(() {
          superAdminName = savedName.trim();
        });
      }

      // Ambil data terbaru dari API
      final response = await ApiService.get('/user');

      debugPrint('===== SUPER ADMIN USER =====');
      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('BODY: ${response.body}');

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

        debugPrint('SUPER ADMIN NAME: $apiName');
        debugPrint('SUPER ADMIN PHOTO: $apiPhoto');

        if (!mounted) return;

        setState(() {
          if (apiName != null && apiName.trim().isNotEmpty) {
            superAdminName = apiName.trim();
          }

          if (apiPhoto != null && apiPhoto.trim().isNotEmpty && apiPhoto != 'null') {
            superAdminPhotoUrl = apiPhoto.trim();
          } else {
            superAdminPhotoUrl = null;
          }
        });

        if (apiName != null && apiName.trim().isNotEmpty) {
          await prefs.setString('name', apiName.trim());
        }

        debugPrint('FULL PHOTO URL: ${_getFullPhotoUrl()}');
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
  // PREVIEW IMAGE DIALOG (BARU)
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
                child: Image(
                  image: imageProvider,
                  fit: BoxFit.contain,
                ),
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
  // SIDEBAR PROFILE IMAGE (DENGAN PREVIEW)
  // =========================================================

  Widget _buildSuperAdminProfileImage({double size = 42}) {
    final fullPhotoUrl = _getFullPhotoUrl();

    // Tidak ada foto
    if (fullPhotoUrl == null) {
      return GestureDetector(
        onTap: _showEditProfileDialog,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Color(0xFFEF476F),
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

    // Ada foto – klik untuk preview
    return GestureDetector(
      onTap: () => _showImageDialog(context, NetworkImage(fullPhotoUrl)),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFEF476F),
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
                color: const Color(0xFFEF476F),
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
              debugPrint('GAGAL MENAMPILKAN FOTO SUPER ADMIN');
              debugPrint('URL: $fullPhotoUrl');
              debugPrint('ERROR: $error');

              return Container(
                width: size,
                height: size,
                color: const Color(0xFFEF476F),
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
  // DIALOG PROFILE IMAGE (DENGAN PREVIEW)
  // =========================================================

  Widget _buildDialogProfileImage() {
    // Jika user baru memilih foto
    if (selectedPhotoBytes != null) {
      return GestureDetector(
        onTap: () => _showImageDialog(context, MemoryImage(selectedPhotoBytes!)),
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

    // Foto dari server
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

    // Fallback
    return _buildDialogInitials();
  }

  // =========================================================
  // DIALOG INITIALS
  // =========================================================

  Widget _buildDialogInitials() {
    return GestureDetector(
      onTap: _showEditProfileDialog,
      child: Container(
        width: 100,
        height: 100,
        decoration: const BoxDecoration(
          color: Color(0xFFEF476F),
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
    final input = html.FileUploadInputElement();
    input.accept = 'image/*';
    input.click();

    input.onChange.listen((event) {
      final files = input.files;
      if (files == null || files.isEmpty) return;

      final file = files.first;
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);

      reader.onLoadEnd.listen((event) {
        if (reader.result == null) return;

        try {
          final Uint8List bytes = reader.result as Uint8List;

          if (!mounted) return;

          setState(() {
            selectedPhotoBytes = bytes;
            selectedPhotoName = file.name;
          });

          debugPrint('FOTO DIPILIH: ${file.name}');
          debugPrint('UKURAN FOTO: ${bytes.length} bytes');
        } catch (e) {
          debugPrint('ERROR MEMBACA FOTO: $e');
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal membaca foto.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    });
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan.');
      }

      // MIME type
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

      debugPrint('===== UPLOAD FOTO =====');
      debugPrint('STATUS: ${request.status}');
      debugPrint('RESPONSE: ${request.responseText}');

      if (request.status == 200) {
        final responseText = request.responseText ?? '{}';
        final responseData = jsonDecode(responseText);

        dynamic userData;
        if (responseData is Map<String, dynamic>) {
          userData = responseData['user'] ?? responseData['data'] ?? responseData;
        }

        String? newPhotoUrl;
        if (userData is Map<String, dynamic>) {
          newPhotoUrl = userData['photo_url']?.toString();
        }

        if (mounted && newPhotoUrl != null && newPhotoUrl.trim().isNotEmpty && newPhotoUrl != 'null') {
          setState(() {
            superAdminPhotoUrl = newPhotoUrl!.trim();
          });
        }

        // Jika response tidak memberikan photo_url, reload dari API
        if (newPhotoUrl == null || newPhotoUrl.trim().isEmpty || newPhotoUrl == 'null') {
          await _loadSuperAdminProfile();
        }

        debugPrint('UPLOAD FOTO SUPER ADMIN BERHASIL');
        return true;
      }

      // Error
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

    // Reset preview
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
                    // =======================================
                    // FOTO (klik untuk preview)
                    // =======================================
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
                          color: const Color(0xFFEF476F),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: isSavingProfile || isUploadingPhoto
                                ? null
                                : () async {
                                    await _pickProfilePhoto();
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

                    // =======================================
                    // NAMA
                    // =======================================
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
                          borderSide: const BorderSide(
                            color: Color(0xFFEF476F),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // =======================================
                    // ROLE
                    // =======================================
                    TextField(
                      enabled: false,
                      controller: TextEditingController(text: 'Super Admin'),
                      decoration: InputDecoration(
                        labelText: 'Role',
                        prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
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
                      : () {
                          Navigator.of(dialogContext).pop();
                        },
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

                            // UPDATE NAMA
                            if (newName != superAdminName) {
                              final response = await ApiService.put(
                                '/user/profile',
                                {'name': newName},
                              );

                              debugPrint('UPDATE NAME STATUS: ${response.statusCode}');
                              debugPrint('UPDATE NAME BODY: ${response.body}');

                              if (response.statusCode != 200) {
                                String message = 'Gagal memperbarui nama.';
                                try {
                                  final data = jsonDecode(response.body);
                                  if (data is Map<String, dynamic>) {
                                    message = data['message']?.toString() ?? message;
                                  }
                                } catch (_) {}
                                throw Exception(message);
                              }
                              nameUpdated = true;
                            }

                            // UPDATE FOTO
                            if (selectedPhotoBytes != null) {
                              photoUpdated = await _uploadProfilePhoto();
                              if (!photoUpdated) {
                                throw Exception('Foto gagal diperbarui.');
                              }
                            }

                            // SIMPAN NAMA KE PREFS
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('name', newName);

                            // UPDATE UI
                            if (!mounted) return;

                            setState(() {
                              superAdminName = newName;
                              selectedPhotoBytes = null;
                              selectedPhotoName = null;
                            });

                            // TUTUP DIALOG
                            if (Navigator.of(dialogContext).canPop()) {
                              Navigator.of(dialogContext).pop();
                            }

                            // PESAN
                            String message = 'Profil berhasil diperbarui.';
                            if (nameUpdated && photoUpdated) {
                              message = 'Nama dan foto profil berhasil diperbarui.';
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
                                content: Text('Gagal memperbarui profil: $e'),
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
                    backgroundColor: const Color(0xFFEF476F),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FB),

      drawer: isMobile
          ? Drawer(
              width: 220,
              backgroundColor: const Color(0xFF0E172A),
              child: _buildSidebar(),
            )
          : null,

      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isMobile) _buildSidebar(),

          Expanded(
            child: Column(
              children: [
                if (isMobile)
                  Container(
                    height: 60,
                    width: double.infinity,
                    color: Colors.white,
                    child: Row(
                      children: [
                        Builder(
                          builder: (context) {
                            return IconButton(
                              icon: const Icon(
                                Icons.menu_rounded,
                                color: Color(0xFF0E172A),
                              ),
                              onPressed: () {
                                Scaffold.of(context).openDrawer();
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        _buildSuperAdminProfileImage(size: 34),
                        const SizedBox(width: 9),
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
                  ),

                Expanded(
                  child: _buildContentArea(),
                ),
              ],
            ),
          ),
        ],
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
  // SIDEBAR
  // =========================================================

  Widget _buildSidebar() {
    return Container(
      width: 220,
      height: double.infinity,
      color: const Color(0xFF0E172A),
      child: Column(
        children: [
          // HEADER SUPER ADMIN
          Container(
            height: 85,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFF243047),
                ),
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

          // MENU
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
            icon: Icons.settings_rounded,
            title: 'Pengaturan Sistem',
          ),
          _buildMenuItem(
            index: 3,
            icon: Icons.folder_rounded,
            title: 'Log Aktivitas',
          ),

          const Spacer(),

          // LOGOUT
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
          color: selected ? const Color(0xFF1E2A40) : Colors.transparent,
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
  // LOGOUT BUTTON
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
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

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
        return const SystemSettingsPage();
      case 3:
        return const ActivityLogPage();
      default:
        return const SizedBox.shrink();
    }
  }
}