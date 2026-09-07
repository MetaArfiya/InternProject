import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';

class AdminProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;

  const AdminProfileScreen({
    super.key,
    this.onProfileUpdated,
  });

  @override
  State<AdminProfileScreen> createState() =>
      _AdminProfileScreenState();
}

class _AdminProfileScreenState
    extends State<AdminProfileScreen> {
  String adminName = 'Memuat...';
  String adminEmail = 'Memuat...';
  String adminRole = 'Memuat...';

  // =========================================================
  // FOTO PROFIL
  // =========================================================

  String? photoUrl;

  Uint8List? selectedPhotoBytes;
  String? selectedPhotoName;

  bool isUploadingPhoto = false;

  // =========================================================
  // STATE
  // =========================================================

  bool isLoading = true;
  bool isSaving = false;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
  }

  // =========================================================
  // LOAD PROFILE DARI DATABASE
  // =========================================================

  Future<void> _loadAdminProfile() async {
    try {
      final response = await ApiService.get('/user');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        final user =
            decodedData['data'] ??
            decodedData['user'] ??
            decodedData;

        if (user is Map) {
          final apiName =
              user['name']?.toString();

          final apiEmail =
              user['email']?.toString();

          final apiRole =
              user['role']?.toString() ??
              user['role_name']?.toString();

          final apiPhotoUrl =
              user['photo_url']?.toString();

          setState(() {
            adminName =
                apiName != null &&
                        apiName.isNotEmpty
                    ? apiName
                    : 'Admin';

            adminEmail =
                apiEmail != null &&
                        apiEmail.isNotEmpty
                    ? apiEmail
                    : '-';

            adminRole =
                apiRole != null &&
                        apiRole.isNotEmpty
                    ? apiRole
                    : 'Admin';

            if (apiPhotoUrl != null &&
                apiPhotoUrl.isNotEmpty &&
                apiPhotoUrl != 'null') {
              photoUrl = apiPhotoUrl;
            } else {
              photoUrl = null;
            }

            isLoading = false;
          });

          debugPrint(
            'ADMIN PROFILE: $user',
          );

          debugPrint(
            'ADMIN PHOTO URL: $photoUrl',
          );
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });

        debugPrint(
          'GET /user ERROR: '
          '${response.statusCode} '
          '${response.body}',
        );

        _showMessage(
          'Gagal mengambil data profil.',
          error: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      debugPrint(
        'LOAD ADMIN PROFILE ERROR: $e',
      );

      _showMessage(
        'Terjadi kesalahan saat mengambil profil.',
        error: true,
      );
    }
  }

  // =========================================================
  // GET FULL PHOTO URL
  // =========================================================

  String? _getFullPhotoUrl() {
    if (photoUrl == null ||
        photoUrl!.trim().isEmpty ||
        photoUrl == 'null') {
      return null;
    }

    String path = photoUrl!.trim();

    // Jika API sudah memberikan URL lengkap
    if (path.startsWith('http://') ||
        path.startsWith('https://')) {
      return path;
    }

    // Hilangkan "/" di awal
    if (path.startsWith('/')) {
      path = path.substring(1);
    }

    /*
     * Contoh dari database:
     *
     * profile_photos/abc123.jpg
     *
     * Diubah menjadi:
     *
     * http://127.0.0.1:8000/api/images/profile/abc123.jpg
     */

    final filename =
        path.split('/').last;

    if (filename.isEmpty) {
      return null;
    }

    return
        'http://127.0.0.1:8000/api/images/profile/$filename';
  }

  // =========================================================
  // GET INITIALS
  // =========================================================

  String _getInitials(String text) {
    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      return 'A';
    }

    final words =
        trimmed.split(RegExp(r'\s+'));

    if (words.length >= 2) {
      return (
        '${words.first[0]}'
        '${words.last[0]}'
      ).toUpperCase();
    }

    return words.first[0].toUpperCase();
  }

  // =========================================================
  // PICK PROFILE PHOTO
  // =========================================================

  Future<void> _pickProfilePhoto() async {
    if (isUploadingPhoto) {
      return;
    }

    final input =
        html.FileUploadInputElement();

    input.accept = 'image/*';

    input.click();

    input.onChange.listen((event) async {
      final files = input.files;

      if (files == null ||
          files.isEmpty) {
        return;
      }

      final file = files.first;

      // Pastikan file adalah gambar
      if (!file.type.startsWith('image/')) {
        if (!mounted) return;

        _showMessage(
          'File yang dipilih harus berupa gambar.',
          error: true,
        );

        return;
      }

      final reader =
          html.FileReader();

      reader.readAsArrayBuffer(file);

      await reader.onLoad.first;

      if (!mounted) return;

      try {
        /*
         * Flutter Web:
         *
         * reader.result berupa Uint8List.
         *
         * Jangan menggunakan:
         *
         * ByteBuffer
         *
         * karena bisa menyebabkan error:
         *
         * NativeUint8List is not a subtype of ByteBuffer
         */

        final Uint8List bytes =
            reader.result as Uint8List;

        setState(() {
          selectedPhotoBytes = bytes;
          selectedPhotoName = file.name;
        });

        // Langsung upload
        await _uploadProfilePhoto();
      } catch (e) {
        debugPrint(
          'READ PHOTO ERROR: $e',
        );

        if (!mounted) return;

        _showMessage(
          'Gagal membaca foto.',
          error: true,
        );
      }
    });
  }

  // =========================================================
  // UPLOAD PROFILE PHOTO
  // =========================================================

  Future<void> _uploadProfilePhoto() async {
    if (selectedPhotoBytes == null ||
        selectedPhotoName == null) {
      return;
    }

    if (isUploadingPhoto) {
      return;
    }

    setState(() {
      isUploadingPhoto = true;
    });

    try {
      final prefs =
          await SharedPreferences.getInstance();

      final token =
          prefs.getString('token');

      if (token == null ||
          token.isEmpty) {
        if (!mounted) return;

        setState(() {
          isUploadingPhoto = false;
        });

        _showMessage(
          'Token login tidak ditemukan.',
          error: true,
        );

        return;
      }

      final request =
          html.HttpRequest();

      request.open(
        'POST',
        'http://127.0.0.1:8000/api/user/profile/photo',
      );

      request.setRequestHeader(
        'Authorization',
        'Bearer $token',
      );

      final formData =
          html.FormData();

      final extension =
          selectedPhotoName!
              .split('.')
              .last
              .toLowerCase();

      String mimeType =
          'image/jpeg';

      if (extension == 'png') {
        mimeType = 'image/png';
      } else if (extension == 'webp') {
        mimeType = 'image/webp';
      } else if (extension == 'jpg' ||
          extension == 'jpeg') {
        mimeType = 'image/jpeg';
      }

      final blob = html.Blob(
        [
          selectedPhotoBytes!,
        ],
        mimeType,
      );

      formData.appendBlob(
        'photo_profile',
        blob,
        selectedPhotoName!,
      );

      request.send(formData);

      await request.onLoad.first;

      if (!mounted) return;

      debugPrint(
        'UPLOAD PHOTO STATUS: '
        '${request.status}',
      );

      debugPrint(
        'UPLOAD PHOTO RESPONSE: '
        '${request.responseText}',
      );

      if (request.status == 200) {
        try {
          final decoded =
              jsonDecode(
            request.responseText ?? '{}',
          );

          final returnedPhotoUrl =
              decoded['photo_url'] ??
              decoded['user']?['photo_url'];

          setState(() {
            if (returnedPhotoUrl != null &&
                returnedPhotoUrl
                    .toString()
                    .isNotEmpty &&
                returnedPhotoUrl
                    .toString() !=
                    'null') {
              photoUrl =
                  returnedPhotoUrl
                      .toString();
            }

            isUploadingPhoto = false;
          });
        } catch (e) {
          setState(() {
            isUploadingPhoto = false;
          });

          debugPrint(
            'PARSE UPLOAD RESPONSE ERROR: $e',
          );
        }

        /*
         * Jangan memanggil:
         *
         * _loadAdminProfile();
         *
         * di sini.
         *
         * Karena selectedPhotoBytes sudah digunakan
         * untuk menampilkan foto baru secara langsung.
         */

        widget.onProfileUpdated?.call();

        _showMessage(
          'Foto profil berhasil diperbarui.',
        );
      } else {
        setState(() {
          isUploadingPhoto = false;
        });

        String message =
            'Gagal mengunggah foto profil.';

        try {
          final decoded =
              jsonDecode(
            request.responseText ?? '{}',
          );

          if (decoded['message'] != null) {
            message =
                decoded['message']
                    .toString();
          }
        } catch (_) {}

        _showMessage(
          message,
          error: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isUploadingPhoto = false;
      });

      debugPrint(
        'UPLOAD PROFILE PHOTO ERROR: $e',
      );

      _showMessage(
        'Terjadi kesalahan saat mengunggah foto.',
        error: true,
      );
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth =
            constraints.maxWidth;

        final isMobile =
            screenWidth < 700;

        final isTablet =
            screenWidth >= 700 &&
            screenWidth < 1100;

        return _buildContent(
          context,
          isMobile,
          isTablet,
        );
      },
    );
  }

  // =========================================================
  // CONTENT
  // =========================================================

  Widget _buildContent(
    BuildContext context,
    bool isMobile,
    bool isTablet,
  ) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF4F7FB),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 26,
          isMobile ? 18 : 28,
          isMobile ? 16 : 26,
          30,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Profil Admin',
              style: TextStyle(
                fontSize:
                    isMobile ? 23 : 27,
                fontWeight:
                    FontWeight.w700,
                color:
                    const Color(0xFF0F172A),
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Kelola informasi dan keamanan akun admin',
              style: TextStyle(
                fontSize:
                    isMobile ? 12 : 13,
                color:
                    const Color(0xFF64748B),
              ),
            ),

            const SizedBox(height: 22),

            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child:
                      CircularProgressIndicator(),
                ),
              )
            else ...[
              _buildProfileCard(
                context,
                isMobile,
              ),

              const SizedBox(height: 18),

              _buildAccountCard(
                isMobile,
              ),

              const SizedBox(height: 18),

              _buildSecurityCard(
                context,
                isMobile,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================
  // PROFILE CARD
  // =========================================================

  Widget _buildProfileCard(
    BuildContext context,
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile ? 16 : 22,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(9),
        border: Border.all(
          color:
              const Color(0xFFDCE3EC),
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _profileInfo(),

                const SizedBox(height: 16),

                _editButton(context),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _profileInfo(),
                ),

                _editButton(context),
              ],
            ),
    );
  }

  // =========================================================
  // PROFILE INFO
  // =========================================================

  Widget _profileInfo() {
    final fullPhotoUrl =
        _getFullPhotoUrl();

    return Row(
      children: [
        Stack(
          clipBehavior:
              Clip.none,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor:
                  const Color(0xFFF0E9FF),
              backgroundImage:
                  selectedPhotoBytes != null
                      ? MemoryImage(
                          selectedPhotoBytes!,
                        )
                      : fullPhotoUrl != null
                          ? NetworkImage(
                              fullPhotoUrl,
                            )
                          : null,
              child:
                  selectedPhotoBytes == null &&
                          fullPhotoUrl == null
                      ? const Icon(
                          Icons
                              .shield_outlined,
                          color:
                              Color(0xFF7C3AED),
                          size: 32,
                        )
                      : null,
            ),

            Positioned(
              right: -3,
              bottom: -3,
              child: InkWell(
                onTap:
                    isUploadingPhoto
                        ? null
                        : _pickProfilePhoto,
                borderRadius:
                    BorderRadius.circular(
                        20),
                child: Container(
                  width: 25,
                  height: 25,
                  decoration:
                      const BoxDecoration(
                    color:
                        Color(0xFF7C3AED),
                    shape:
                        BoxShape.circle,
                  ),
                  child:
                      isUploadingPhoto
                          ? const Padding(
                              padding:
                                  EdgeInsets.all(
                                      6),
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons
                                  .camera_alt_outlined,
                              color:
                                  Colors.white,
                              size: 13,
                            ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(width: 15),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                adminName,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 5),

              Text(
                adminEmail,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color:
                      Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 7),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                          0xFFDCFCE7),
                  borderRadius:
                      BorderRadius.circular(
                          20),
                ),
                child: Text(
                  adminRole,
                  style:
                      const TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // EDIT BUTTON
  // =========================================================

  Widget _editButton(
    BuildContext context,
  ) {
    return ElevatedButton.icon(
      onPressed: isSaving
          ? null
          : () {
              _showEditProfileDialog(
                context,
              );
            },
      icon: const Icon(
        Icons.edit_outlined,
        size: 15,
      ),
      label: const Text(
        'Edit Profil',
        style: TextStyle(
          fontSize: 11,
          fontWeight:
              FontWeight.w600,
        ),
      ),
      style:
          ElevatedButton.styleFrom(
        backgroundColor:
            const Color(0xFF7C3AED),
        foregroundColor:
            Colors.white,
        elevation: 0,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 12,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(7),
        ),
      ),
    );
  }

  // =========================================================
  // EDIT PROFILE DIALOG
  // =========================================================

  void _showEditProfileDialog(
    BuildContext context,
  ) {
    final nameController =
        TextEditingController(
      text: adminName,
    );

    final emailController =
        TextEditingController(
      text: adminEmail,
    );

    final formKey =
        GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final fullPhotoUrl =
            _getFullPhotoUrl();

        return AlertDialog(
          backgroundColor:
              Colors.white,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
          title: const Text(
            'Edit Profil',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF111827),
            ),
          ),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  // =========================================
                  // FOTO PROFIL DI DIALOG
                  // =========================================

                  Stack(
                    clipBehavior:
                        Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor:
                            const Color(
                                0xFFF0E9FF),
                        backgroundImage:
                            selectedPhotoBytes !=
                                    null
                                ? MemoryImage(
                                    selectedPhotoBytes!,
                                  )
                                : fullPhotoUrl !=
                                        null
                                    ? NetworkImage(
                                        fullPhotoUrl,
                                      )
                                    : null,
                        child:
                            selectedPhotoBytes ==
                                        null &&
                                    fullPhotoUrl ==
                                        null
                                ? const Icon(
                                    Icons
                                        .shield_outlined,
                                    color:
                                        Color(
                                            0xFF7C3AED),
                                    size: 42,
                                  )
                                : null,
                      ),

                      Positioned(
                        right: -2,
                        bottom: 0,
                        child: InkWell(
                          onTap:
                              isUploadingPhoto
                                  ? null
                                  : () async {
                                      Navigator.of(
                                        dialogContext,
                                      ).pop();

                                      await _pickProfilePhoto();
                                    },
                          borderRadius:
                              BorderRadius.circular(
                                  20),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration:
                                const BoxDecoration(
                              color:
                                  Color(
                                      0xFF7C3AED),
                              shape:
                                  BoxShape.circle,
                            ),
                            child:
                                isUploadingPhoto
                                    ? const Padding(
                                        padding:
                                            EdgeInsets.all(
                                                7),
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth:
                                              2,
                                          color:
                                              Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons
                                            .camera_alt_outlined,
                                        color:
                                            Colors.white,
                                        size: 15,
                                      ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Klik ikon kamera untuk mengganti foto',
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          Color(0xFF94A3B8),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =========================================
                  // NAMA
                  // =========================================

                  TextFormField(
                    controller:
                        nameController,
                    decoration:
                        InputDecoration(
                      labelText:
                          'Nama Lengkap',
                      prefixIcon:
                          const Icon(
                        Icons
                            .person_outline,
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(8),
                      ),
                    ),
                    validator:
                        (value) {
                      if (value == null ||
                          value
                              .trim()
                              .isEmpty) {
                        return 'Nama tidak boleh kosong';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // =========================================
                  // EMAIL
                  // =========================================

                  TextFormField(
                    controller:
                        emailController,
                    keyboardType:
                        TextInputType
                            .emailAddress,
                    decoration:
                        InputDecoration(
                      labelText: 'Email',
                      prefixIcon:
                          const Icon(
                        Icons
                            .email_outlined,
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(8),
                      ),
                    ),
                    validator:
                        (value) {
                      if (value == null ||
                          value
                              .trim()
                              .isEmpty) {
                        return 'Email tidak boleh kosong';
                      }

                      if (!value
                          .contains('@')) {
                        return 'Format email tidak valid';
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                'Batal',
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                if (!formKey
                    .currentState!
                    .validate()) {
                  return;
                }

                final newName =
                    nameController.text
                        .trim();

                final newEmail =
                    emailController.text
                        .trim();

                await _updateProfile(
                  dialogContext,
                  newName,
                  newEmail,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                        0xFF7C3AED),
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text('Simpan'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      emailController.dispose();
    });
  }

  // =========================================================
  // UPDATE PROFILE KE DATABASE
  // =========================================================

  Future<void> _updateProfile(
    BuildContext dialogContext,
    String newName,
    String newEmail,
  ) async {
    if (isSaving) return;

    setState(() {
      isSaving = true;
    });

    try {
      final response =
          await ApiService.put(
        '/user/profile',
        {
          'name': newName,
          'email': newEmail,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          adminName = newName;
          adminEmail = newEmail;
          isSaving = false;
        });

        // Simpan nama/email ke SharedPreferences
        final prefs =
            await SharedPreferences
                .getInstance();

        await prefs.setString(
          'name',
          newName,
        );

        await prefs.setString(
          'email',
          newEmail,
        );

        if (dialogContext.mounted) {
          Navigator.of(
            dialogContext,
          ).pop();
        }

        widget.onProfileUpdated
            ?.call();

        _showMessage(
          'Profil berhasil diperbarui.',
        );
      } else {
        setState(() {
          isSaving = false;
        });

        debugPrint(
          'UPDATE PROFILE ERROR: '
          '${response.statusCode} '
          '${response.body}',
        );

        _showMessage(
          'Gagal memperbarui profil.',
          error: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      debugPrint(
        'UPDATE PROFILE ERROR: $e',
      );

      _showMessage(
        'Terjadi kesalahan saat memperbarui profil.',
        error: true,
      );
    }
  }

  // =========================================================
  // ACCOUNT CARD
  // =========================================================

  Widget _buildAccountCard(
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile ? 16 : 22,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(9),
        border: Border.all(
          color:
              const Color(0xFFDCE3EC),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Akun',
            style: TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Informasi dasar akun administrator',
            style: TextStyle(
              fontSize: 11,
              color:
                  Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 20),

          if (isMobile)
            Column(
              children: [
                _infoItem(
                  Icons.person_outline,
                  'Nama Lengkap',
                  adminName,
                ),

                const SizedBox(
                  height: 15,
                ),

                _infoItem(
                  Icons.email_outlined,
                  'Email',
                  adminEmail,
                ),

                const SizedBox(
                  height: 15,
                ),

                _infoItem(
                  Icons
                      .admin_panel_settings_outlined,
                  'Level Akses',
                  adminRole,
                ),

                const SizedBox(
                  height: 15,
                ),

                _infoItem(
                  Icons
                      .check_circle_outline,
                  'Status Akun',
                  'Aktif',
                  valueColor:
                      const Color(
                          0xFF16A34A),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _infoItem(
                        Icons.person_outline,
                        'Nama Lengkap',
                        adminName,
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      _infoItem(
                        Icons
                            .admin_panel_settings_outlined,
                        'Level Akses',
                        adminRole,
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 40,
                ),

                Expanded(
                  child: Column(
                    children: [
                      _infoItem(
                        Icons.email_outlined,
                        'Email',
                        adminEmail,
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      _infoItem(
                        Icons
                            .check_circle_outline,
                        'Status Akun',
                        'Aktif',
                        valueColor:
                            const Color(
                                0xFF16A34A),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // =========================================================
  // INFO ITEM
  // =========================================================

  Widget _infoItem(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration:
              BoxDecoration(
            color:
                const Color(0xFFF8FAFC),
            borderRadius:
                BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color:
                const Color(0xFF64748B),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style:
                    const TextStyle(
                  fontSize: 10,
                  color:
                      Color(0xFF94A3B8),
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                  color: valueColor ??
                      const Color(
                          0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // SECURITY CARD
  // =========================================================

  Widget _buildSecurityCard(
    BuildContext context,
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile ? 16 : 22,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(9),
        border: Border.all(
          color:
              const Color(0xFFDCE3EC),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Keamanan Akun',
            style: TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Pengaturan keamanan akun administrator',
            style: TextStyle(
              fontSize: 11,
              color:
                  Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 18),

          _securityItem(
            context,
            Icons.lock_outline,
            'Kata Sandi',
            'Kata sandi dapat diperbarui',
            'Ubah',
            const Color(0xFF7C3AED),
          ),

          const Divider(
            height: 1,
            color:
                Color(0xFFE2E8F0),
          ),

          _securityItem(
            context,
            Icons
                .verified_user_outlined,
            'Verifikasi Akun',
            'Akun administrator telah terverifikasi',
            'Terverifikasi',
            const Color(0xFF16A34A),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SECURITY ITEM
  // =========================================================

  Widget _securityItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    String action,
    Color actionColor,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFF8FAFC),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color:
                  const Color(0xFF64748B),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(0xFF334155),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  description,
                  style:
                      const TextStyle(
                    fontSize: 10,
                    color:
                        Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          OutlinedButton(
            onPressed:
                title == 'Kata Sandi'
                    ? () {
                        _showChangePasswordDialog(
                          context,
                        );
                      }
                    : null,
            style:
                OutlinedButton.styleFrom(
              foregroundColor:
                  actionColor,
              side: BorderSide(
                color: actionColor,
              ),
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              minimumSize:
                  Size.zero,
              tapTargetSize:
                  MaterialTapTargetSize
                      .shrinkWrap,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                        7),
              ),
            ),
            child: Text(
              action,
              style:
                  const TextStyle(
                fontSize: 10,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CHANGE PASSWORD
  // =========================================================

  void _showChangePasswordDialog(
    BuildContext context,
  ) {
    final formKey =
        GlobalKey<FormState>();

    final oldPasswordController =
        TextEditingController();

    final newPasswordController =
        TextEditingController();

    final confirmPasswordController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              Colors.white,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
          title: const Text(
            'Ubah Kata Sandi',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  TextFormField(
                    controller:
                        oldPasswordController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Kata Sandi Lama',
                      prefixIcon:
                          Icon(
                        Icons.lock_outline,
                      ),
                    ),
                    validator:
                        (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return 'Masukkan kata sandi lama';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  TextFormField(
                    controller:
                        newPasswordController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Kata Sandi Baru',
                      prefixIcon:
                          Icon(
                        Icons.lock_outline,
                      ),
                    ),
                    validator:
                        (value) {
                      if (value == null ||
                          value.length < 6) {
                        return 'Minimal 6 karakter';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  TextFormField(
                    controller:
                        confirmPasswordController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Konfirmasi Kata Sandi',
                      prefixIcon:
                          Icon(
                        Icons.lock_outline,
                      ),
                    ),
                    validator:
                        (value) {
                      if (value !=
                          newPasswordController
                              .text) {
                        return 'Kata sandi tidak sama';
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child:
                  const Text('Batal'),
            ),

            ElevatedButton(
              onPressed: () async {
                if (!formKey
                    .currentState!
                    .validate()) {
                  return;
                }

                await _changePassword(
                  dialogContext,
                  oldPasswordController
                      .text,
                  newPasswordController
                      .text,
                  confirmPasswordController
                      .text,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                        0xFF7C3AED),
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text('Simpan'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      oldPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    });
  }

  // =========================================================
  // CHANGE PASSWORD KE DATABASE
  // =========================================================

  Future<void> _changePassword(
    BuildContext dialogContext,
    String oldPassword,
    String newPassword,
    String confirmation,
  ) async {
    try {
      final response =
          await ApiService.post(
        '/change-password',
        {
          'current_password':
              oldPassword,
          'new_password':
              newPassword,
          'new_password_confirmation':
              confirmation,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        if (dialogContext.mounted) {
          Navigator.of(
            dialogContext,
          ).pop();
        }

        _showMessage(
          'Kata sandi berhasil diubah.',
        );
      } else {
        _showMessage(
          'Gagal mengubah kata sandi.',
          error: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint(
        'CHANGE PASSWORD ERROR: $e',
      );

      _showMessage(
        'Terjadi kesalahan saat mengubah kata sandi.',
        error: true,
      );
    }
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error
            ? const Color(0xFFEF4444)
            : const Color(0xFF16A34A),
      ),
    );
  }
}