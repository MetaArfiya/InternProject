import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sayabantu_project/screens/Screens_Landing/landing_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';

class CustomerSettingScreen extends StatefulWidget {
  final VoidCallback onProfileUpdate;

  const CustomerSettingScreen({
    super.key,
    required this.onProfileUpdate,
  });

  @override
  State<CustomerSettingScreen> createState() =>
      _CustomerSettingScreenState();
}

class _CustomerSettingScreenState extends State<CustomerSettingScreen> {
  // =========================================================
  // STANDARD UI
  // =========================================================

  static const double _bodyFontSize = 13;
  static const double _buttonFontSize = 13;
  static const double _smallRadius = 12;
  static const double _cardRadius = 16;
  static const double _dialogTitleFontSize = 18;

  static const Color _primaryColor = Color(0xffF97316);
  static const Color _borderColor = Color(0xffE5E7EB);

  // =========================================================
  // INPUT FORMATTERS
  // =========================================================

  /// Hanya huruf, spasi, titik, koma, apostrof, dan strip
  static final List<TextInputFormatter> nameFormatters = [
    FilteringTextInputFormatter.allow(
      RegExp(r"[a-zA-Z\s.,'-]"),
    ),
  ];

  /// Hanya angka
  static final List<TextInputFormatter> digitsOnly = [
    FilteringTextInputFormatter.digitsOnly,
  ];

  // =========================================================
  // STATE
  // =========================================================

  bool jobNotification = true;
  bool isLoading = true;
  bool isUploadingPhoto = false;

  String name = "";
  String email = "";
  String phone = "";
  String address = "";

  // Foto dari database
  String? photoUrl;

  // Foto baru yang dipilih
  Uint8List? selectedPhotoBytes;
  String? selectedPhotoName;

  @override
  void initState() {
    super.initState();
    loadProfileFromApi();
  }

  // =========================================================
  // PREVIEW IMAGE DIALOG
  // =========================================================

  void _showImageDialog(
    BuildContext context,
    ImageProvider imageProvider,
  ) {
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
  // LOAD PROFILE
  // =========================================================

  Future<void> loadProfileFromApi() async {
    try {
      final response = await ApiService.get('/user');

      debugPrint("====================================");
      debugPrint("GET /user");
      debugPrint("STATUS: ${response.statusCode}");
      debugPrint("BODY: ${response.body}");
      debugPrint("====================================");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userData = data['user'] ?? data;

        if (!mounted) return;

        setState(() {
          name = userData['name']?.toString() ?? "";
          email = userData['email']?.toString() ?? "";
          phone = userData['phone']?.toString() ?? "";
          address = userData['address']?.toString() ?? "";

          // PHOTO
          final apiPhoto = userData['photo_url'];

          if (apiPhoto != null &&
              apiPhoto.toString().trim().isNotEmpty &&
              apiPhoto.toString() != 'null') {
            photoUrl = apiPhoto.toString();
          }

          // NOTIFICATION
          final notifValue = userData['is_notification_enabled'];

          if (notifValue is bool) {
            jobNotification = notifValue;
          } else if (notifValue is int) {
            jobNotification = notifValue == 1;
          } else if (notifValue is String) {
            jobNotification = notifValue == '1' ||
                notifValue.toLowerCase() == 'true';
          } else {
            jobNotification = true;
          }

          isLoading = false;
        });
      } else {
        debugPrint(
          "Gagal mengambil profil. Status: ${response.statusCode}",
        );

        if (!mounted) return;

        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error load profile: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // =========================================================
  // URL FOTO PROFILE
  // =========================================================

  String? getFullPhotoUrl() {
    if (photoUrl == null ||
        photoUrl!.trim().isEmpty ||
        photoUrl == 'null') {
      return null;
    }

    String path = photoUrl!.trim();

    if (path.startsWith('http://') ||
        path.startsWith('https://')) {
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
  // PILIH FOTO
  // =========================================================

  Future<void> pickProfilePhoto() async {
    try {
      final html.FileUploadInputElement uploadInput =
          html.FileUploadInputElement();

      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((event) async {
        final files = uploadInput.files;

        if (files == null || files.isEmpty) {
          debugPrint("Tidak ada file yang dipilih.");
          return;
        }

        final file = files.first;

        debugPrint("====================================");
        debugPrint("FILE DIPILIH");
        debugPrint("Nama: ${file.name}");
        debugPrint("Type: ${file.type}");
        debugPrint("Size: ${file.size}");
        debugPrint("====================================");

        // ===================================================
        // ✅ VALIDASI IMAGE
        // ===================================================
        if (!file.type.startsWith('image/')) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "File yang dipilih harus berupa gambar.",
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // ===================================================
        // ✅ VALIDASI EKSTENSI
        // ===================================================
        final lowerName = file.name.toLowerCase();
        final allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
        final hasValidExtension =
            allowedExtensions.any((ext) => lowerName.endsWith(ext));

        if (!hasValidExtension) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Format foto harus JPG, JPEG, PNG, atau WEBP.",
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // ===================================================
        // ✅ VALIDASI UKURAN (maks 5 MB, sesuai Laravel max:5120)
        // ===================================================
        const int maxSizeInBytes = 5 * 1024 * 1024;
        if (file.size > maxSizeInBytes) {
          if (!mounted) return;
          final sizeMb = (file.size / 1024 / 1024).toStringAsFixed(2);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Ukuran foto terlalu besar ($sizeMb MB).\nMaksimal 5 MB.",
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );

          return;
        }

        // BACA FILE
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);

        reader.onLoadEnd.listen((event) async {
          try {
            if (reader.result == null) {
              debugPrint("FileReader result kosong.");
              return;
            }

            final Uint8List bytes = reader.result as Uint8List;

            debugPrint("====================================");
            debugPrint("FILE BERHASIL DIBACA");
            debugPrint("Nama: ${file.name}");
            debugPrint("Bytes: ${bytes.length}");
            debugPrint("====================================");

            if (!mounted) return;

            // PREVIEW
            setState(() {
              selectedPhotoBytes = bytes;
              selectedPhotoName = file.name;
            });

            // UPLOAD
            await uploadProfilePhoto();
          } catch (e) {
            debugPrint("Gagal membaca file: $e");

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Gagal membaca foto.",
                  style: TextStyle(fontSize: _bodyFontSize),
                ),
              ),
            );
          }
        });
      });
    } catch (e) {
      debugPrint("Error pilih foto: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Gagal memilih foto.",
            style: TextStyle(fontSize: _bodyFontSize),
          ),
        ),
      );
    }
  }

  // =========================================================
  // UPLOAD FOTO PROFILE
  // =========================================================

  Future<void> uploadProfilePhoto() async {
    if (selectedPhotoBytes == null ||
        selectedPhotoName == null) {
      debugPrint("Foto belum tersedia untuk diupload.");
      return;
    }

    try {
      if (!mounted) return;

      setState(() {
        isUploadingPhoto = true;
      });

      final token = await getToken();

      debugPrint("Token tersedia: ${token.isNotEmpty}");

      if (token.isEmpty) {
        if (!mounted) return;

        setState(() {
          isUploadingPhoto = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Token login tidak ditemukan.",
              style: TextStyle(fontSize: _bodyFontSize),
            ),
          ),
        );

        return;
      }

      final request = html.HttpRequest();

      request.open(
        'POST',
        'http://127.0.0.1:8000/api/user/profile/photo',
      );

      request.setRequestHeader(
        'Authorization',
        'Bearer $token',
      );

      final formData = html.FormData();

      String mimeType = 'image/jpeg';

      final lowerName = selectedPhotoName!.toLowerCase();

      if (lowerName.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (lowerName.endsWith('.webp')) {
        mimeType = 'image/webp';
      } else if (lowerName.endsWith('.jpg') ||
          lowerName.endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      }

      final blob = html.Blob(
        [selectedPhotoBytes!],
        mimeType,
      );

      formData.appendBlob(
        'photo_profile',
        blob,
        selectedPhotoName!,
      );

      debugPrint("====================================");
      debugPrint("UPLOAD FOTO PROFIL");
      debugPrint("Nama file: $selectedPhotoName");
      debugPrint(
        "Ukuran: ${selectedPhotoBytes!.length} bytes",
      );
      debugPrint("MIME: $mimeType");
      debugPrint(
        "Endpoint: POST /api/user/profile/photo",
      );
      debugPrint("====================================");

      request.onLoad.listen((event) async {
        debugPrint("====================================");
        debugPrint("UPLOAD SELESAI");
        debugPrint("STATUS: ${request.status}");
        debugPrint("RESPONSE: ${request.responseText}");
        debugPrint("====================================");

        if (request.status == 200) {
          try {
            final responseData =
                jsonDecode(request.responseText ?? '{}');

            debugPrint("UPLOAD JSON: $responseData");

            String? returnedPhotoUrl;

            if (responseData['photo_url'] != null) {
              returnedPhotoUrl =
                  responseData['photo_url'].toString();
            }

            final responseUser = responseData['user'];

            if (responseUser is Map &&
                responseUser['photo_url'] != null) {
              returnedPhotoUrl =
                  responseUser['photo_url'].toString();
            }

            debugPrint(
              "PHOTO URL DARI BACKEND: $returnedPhotoUrl",
            );

            if (!mounted) return;

            setState(() {
              if (returnedPhotoUrl != null &&
                  returnedPhotoUrl.trim().isNotEmpty &&
                  returnedPhotoUrl != 'null') {
                photoUrl = returnedPhotoUrl;
              }

              isUploadingPhoto = false;
            });

            widget.onProfileUpdate();

            if (!mounted) return;

            _showMessage(
              "Foto profil berhasil diperbarui.",
            );
          } catch (e) {
            debugPrint(
              "Error membaca response upload: $e",
            );

            if (!mounted) return;

            setState(() {
              isUploadingPhoto = false;
            });

            _showMessage(
              "Foto berhasil diupload, tetapi response server tidak dapat dibaca.",
              error: true,
            );
          }
        } else {
          debugPrint("====================================");
          debugPrint("UPLOAD FOTO GAGAL");
          debugPrint("STATUS: ${request.status}");
          debugPrint("RESPONSE: ${request.responseText}");
          debugPrint("====================================");

          if (!mounted) return;

          setState(() => isUploadingPhoto = false);

          // ===================================================
          // ✅ PARSE PESAN ERROR DARI LARAVEL
          // ===================================================
          String errorMessage = "Gagal upload foto.";

          try {
            final errorData = jsonDecode(request.responseText ?? '{}');

            if (errorData['errors'] is Map) {
              final errors = errorData['errors'] as Map;

              if (errors['photo_profile'] is List &&
                  (errors['photo_profile'] as List).isNotEmpty) {
                errorMessage =
                    errors['photo_profile'][0].toString();
              } else if (errors.isNotEmpty) {
                final firstKey = errors.keys.first;
                if (errors[firstKey] is List &&
                    (errors[firstKey] as List).isNotEmpty) {
                  errorMessage =
                      (errors[firstKey] as List)[0].toString();
                }
              }
            } else if (errorData['message'] != null) {
              errorMessage = errorData['message'].toString();
            }
          } catch (e) {
            debugPrint("Gagal parse error response: $e");

            if (request.status == 422) {
              errorMessage =
                  "File tidak valid. Cek format & ukuran foto.";
            } else if (request.status == 401) {
              errorMessage =
                  "Sesi login berakhir. Silakan login ulang.";
            } else if (request.status == 413) {
              errorMessage = "File terlalu besar untuk server.";
            } else if (request.status == 500) {
              errorMessage = "Terjadi kesalahan di server.";
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });

      request.onError.listen((event) {
        debugPrint("Network error saat upload foto.");

        if (!mounted) return;

        setState(() {
          isUploadingPhoto = false;
        });

        _showMessage(
          "Tidak dapat terhubung ke server.",
          error: true,
        );
      });

      request.send(formData);
    } catch (e) {
      debugPrint("Exception upload foto: $e");

      if (!mounted) return;

      setState(() {
        isUploadingPhoto = false;
      });

      _showMessage(
        "Terjadi kesalahan saat upload foto.",
        error: true,
      );
    }
  }

  // =========================================================
  // TOKEN
  // =========================================================

  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('token') ?? '';
  }

  // =========================================================
  // UPDATE PROFILE
  // =========================================================

  Future<void> updateProfileToApi(
    String newName,
    String newEmail,
    String newPhone,
    String newAddress,
  ) async {
    final trimmedName = newName.trim();
    final trimmedEmail = newEmail.trim();
    final trimmedPhone = newPhone.trim();
    final trimmedAddress = newAddress.trim();

    // ========================================================
    // VALIDASI
    // ========================================================

    if (trimmedName.isEmpty) {
      if (!mounted) return;

      _showMessage(
        'Nama wajib diisi.',
        error: true,
      );

      return;
    }

    if (trimmedName.length < 3) {
      if (!mounted) return;

      _showMessage(
        'Nama minimal 3 karakter.',
        error: true,
      );

      return;
    }

    if (trimmedEmail.isEmpty) {
      if (!mounted) return;

      _showMessage(
        'Email wajib diisi.',
        error: true,
      );

      return;
    }

    if (!RegExp(
      r'^[\w\.-]+@[\w\.-]+\.\w+$',
    ).hasMatch(trimmedEmail)) {
      if (!mounted) return;

      _showMessage(
        'Format email tidak valid.',
        error: true,
      );

      return;
    }

    if (trimmedPhone.isNotEmpty) {
      if (!RegExp(
        r'^[0-9]+$',
      ).hasMatch(trimmedPhone)) {
        if (!mounted) return;

        _showMessage(
          'Nomor HP hanya boleh berisi angka.',
          error: true,
        );

        return;
      }

      if (trimmedPhone.length < 10 ||
          trimmedPhone.length > 15) {
        if (!mounted) return;

        _showMessage(
          'Nomor HP harus 10-15 digit.',
          error: true,
        );

        return;
      }
    }

    if (trimmedAddress.isNotEmpty &&
        trimmedAddress.length < 5) {
      if (!mounted) return;

      _showMessage(
        'Alamat minimal 5 karakter.',
        error: true,
      );

      return;
    }

    try {
      final response = await ApiService.put(
        '/user/profile',
        {
          'name': trimmedName,
          'email': trimmedEmail,
          'phone': trimmedPhone,
          'address': trimmedAddress,
        },
      );

      if (response.statusCode == 200) {
        await loadProfileFromApi();

        widget.onProfileUpdate();

        if (!mounted) return;

        _showMessage(
          'Profil berhasil diperbarui.',
        );
      } else {
        String message =
            'Gagal memperbarui profil.';

        try {
          final data = jsonDecode(response.body);

          message =
              data['message']?.toString() ?? message;
        } catch (_) {}

        if (!mounted) return;

        _showMessage(
          message,
          error: true,
        );
      }
    } catch (e) {
      debugPrint(
        "Error update profile: $e",
      );

      if (!mounted) return;

      _showMessage(
        'Terjadi kesalahan saat memperbarui profil.',
        error: true,
      );
    }
  }

  // =========================================================
  // UPDATE NOTIFICATION
  // =========================================================

  Future<void> updateNotificationStatus(
    bool value,
  ) async {
    try {
      await ApiService.put(
        '/user/notification-setting',
        {
          'is_notification_enabled': value ? 1 : 0,
        },
      );
    } catch (e) {
      debugPrint(
        "Error update notification: $e",
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

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontSize: _bodyFontSize,
            ),
          ),
          backgroundColor:
              error ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: _primaryColor,
          ),
        ),
      );
    }

    final fullPhotoUrl = getFullPhotoUrl();

    return Scaffold(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;

          return SingleChildScrollView(
            padding: EdgeInsets.all(
              isMobile ? 16 : 28,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // =================================================
                // HEADER
                // =================================================

                Text(
                  'Pengaturan',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Kelola profil, notifikasi, dan keamanan akun.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),

                const SizedBox(height: 28),

                // =================================================
                // PROFILE HEADER
                // =================================================

                Center(
                  child: Column(
                    children: [
                      // PROFILE PHOTO
                      GestureDetector(
                        onTap: () {
                          if (selectedPhotoBytes != null) {
                            _showImageDialog(
                              context,
                              MemoryImage(
                                selectedPhotoBytes!,
                              ),
                            );
                          } else if (fullPhotoUrl != null) {
                            _showImageDialog(
                              context,
                              NetworkImage(
                                fullPhotoUrl,
                              ),
                            );
                          }
                        },
                        child: Stack(
                          alignment:
                              Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 55,
                              backgroundColor:
                                  const Color(0xffFFF3E8),
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
                                  selectedPhotoBytes ==
                                              null &&
                                          fullPhotoUrl ==
                                              null
                                      ? const Icon(
                                          Icons.person,
                                          size: 60,
                                          color:
                                              _primaryColor,
                                        )
                                      : null,
                            ),

                            Container(
                              decoration:
                                  BoxDecoration(
                                color: _primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: IconButton(
                                icon: isUploadingPhoto
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color:
                                              Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt,
                                        color:
                                            Colors.white,
                                        size: 20,
                                      ),
                                onPressed:
                                    isUploadingPhoto
                                        ? null
                                        : pickProfilePhoto,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // EDIT PROFILE BUTTON
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showEditProfileDialog(
                            fullPhotoUrl,
                          ),
                          icon: const Icon(
                            Icons.edit,
                            size: 18,
                          ),
                          label: const Text(
                            'Edit Profil',
                            style: TextStyle(
                              fontSize:
                                  _buttonFontSize,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                _primaryColor,
                            foregroundColor:
                                Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                _smallRadius,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // =================================================
                // INFORMASI AKUN
                // =================================================

                Text(
                  'Informasi Akun',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 12),

                _buildInfoCard(
                  icon: Icons.person_outline,
                  title: 'Nama',
                  subtitle: name,
                ),

                _buildInfoCard(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  subtitle: email,
                ),

                _buildInfoCard(
                  icon: Icons.phone_outlined,
                  title: 'Nomor HP',
                  subtitle:
                      phone.isEmpty ? '-' : phone,
                ),

                _buildInfoCard(
                  icon: Icons.location_on_outlined,
                  title: 'Alamat',
                  subtitle:
                      address.isEmpty ? '-' : address,
                ),

                const SizedBox(height: 16),

                // =================================================
                // NOTIFIKASI
                // =================================================

                Text(
                  'Notifikasi',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 12),

                _buildNotificationCard(),

                const SizedBox(height: 28),

                // =================================================
                // KEAMANAN
                // =================================================

                Text(
                  'Keamanan',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 12),

                _buildSecurityCard(),

                const SizedBox(height: 28),
              ],
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // INFORMATION CARD
  // =========================================================

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius:
            BorderRadius.circular(_cardRadius),
        border: Border.all(
          color: _borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _primaryColor.withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: _primaryColor,
              size: 23,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  maxLines: 3,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // NOTIFICATION CARD
  // =========================================================

  Widget _buildNotificationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius:
            BorderRadius.circular(_cardRadius),
        border: Border.all(
          color: _borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          // ICON
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _primaryColor.withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: _primaryColor,
              size: 23,
            ),
          ),

          const SizedBox(width: 16),

          // TEXT
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notifikasi Penawaran',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Terima notifikasi ketika mitra '
                  'mengirim penawaran pada pekerjaan Anda.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // SWITCH
          Switch(
            value: jobNotification,
            activeColor: _primaryColor,
            onChanged: (value) async {
              setState(() {
                jobNotification = value;
              });

              await updateNotificationStatus(
                value,
              );

              if (!mounted) return;

              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? 'Notifikasi penawaran diaktifkan.'
                          : 'Notifikasi penawaran dinonaktifkan.',
                      style: const TextStyle(
                        fontSize: _bodyFontSize,
                      ),
                    ),
                    backgroundColor: Colors.green,
                    behavior:
                        SnackBarBehavior.floating,
                  ),
                );
            },
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SECURITY CARD
  // =========================================================

  Widget _buildSecurityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius:
            BorderRadius.circular(_cardRadius),
        border: Border.all(
          color: _borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(_cardRadius),
        onTap: _showLogoutDialog,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.red.withValues(
                  alpha: 0.10,
                ),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.logout,
                color: Colors.red,
                size: 23,
              ),
            ),

            const SizedBox(width: 16),

            const Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Keluar dari akun SayaBantu.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // EDIT PROFILE DIALOG
  // =========================================================

  void _showEditProfileDialog(
    String? fullPhotoUrl,
  ) {
    final nameFmts = nameFormatters;
    final digitsFmts = digitsOnly;

    final nameController =
        TextEditingController(text: name);

    final emailController =
        TextEditingController(text: email);

    final phoneController =
        TextEditingController(text: phone);

    final addressController =
        TextEditingController(text: address);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
          title: const Text(
            'Edit Profil',
            style: TextStyle(
              fontSize: _dialogTitleFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  // FOTO
                  GestureDetector(
                    onTap: () {
                      if (selectedPhotoBytes !=
                          null) {
                        _showImageDialog(
                          dialogContext,
                          MemoryImage(
                            selectedPhotoBytes!,
                          ),
                        );
                      } else if (fullPhotoUrl !=
                          null) {
                        _showImageDialog(
                          dialogContext,
                          NetworkImage(
                            fullPhotoUrl,
                          ),
                        );
                      }
                    },
                    child: Stack(
                      alignment:
                          Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor:
                              const Color(0xffFFF3E8),
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
                                      Icons.person,
                                      size: 50,
                                      color:
                                          _primaryColor,
                                    )
                                  : null,
                        ),
                        Container(
                          decoration:
                              const BoxDecoration(
                            color: _primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: () async {
                              Navigator.pop(
                                dialogContext,
                              );

                              await pickProfilePhoto();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // NAMA
                  _buildEditField(
                    controller:
                        nameController,
                    label: 'Nama',
                    icon:
                        Icons.person_outline,
                    maxLength: 100,
                    inputFormatters:
                        nameFmts,
                    textCapitalization:
                        TextCapitalization.words,
                  ),

                  const SizedBox(height: 12),

                  // EMAIL
                  _buildEditField(
                    controller:
                        emailController,
                    label: 'Email',
                    icon:
                        Icons.email_outlined,
                    maxLength: 100,
                    keyboardType:
                        TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 12),

                  // NOMOR HP
                  _buildEditField(
                    controller:
                        phoneController,
                    label: 'Nomor HP',
                    icon:
                        Icons.phone_outlined,
                    maxLength: 15,
                    keyboardType:
                        TextInputType.phone,
                    inputFormatters:
                        digitsFmts,
                    hintText:
                        '10-15 digit angka',
                  ),

                  const SizedBox(height: 12),

                  // ALAMAT
                  _buildEditField(
                    controller:
                        addressController,
                    label: 'Alamat',
                    icon: Icons
                        .location_on_outlined,
                    maxLength: 500,
                    maxLines: 3,
                    alignLabelWithHint: true,
                  ),
                ],
              ),
            ),
          ),
          actionsPadding:
              const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          actions: [
            TextButton(
              onPressed: () {
                nameController.dispose();
                emailController.dispose();
                phoneController.dispose();
                addressController.dispose();

                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontSize: _buttonFontSize,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    _smallRadius,
                  ),
                ),
              ),
              onPressed: () async {
                final newName =
                    nameController.text.trim();

                final newEmail =
                    emailController.text.trim();

                final newPhone =
                    phoneController.text.trim();

                final newAddress =
                    addressController.text.trim();

                nameController.dispose();
                emailController.dispose();
                phoneController.dispose();
                addressController.dispose();

                Navigator.pop(dialogContext);

                await updateProfileToApi(
                  newName,
                  newEmail,
                  newPhone,
                  newAddress,
                );
              },
              child: const Text(
                'Simpan',
                style: TextStyle(
                  fontSize: _buttonFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      try {
        nameController.dispose();
      } catch (_) {}

      try {
        emailController.dispose();
      } catch (_) {}

      try {
        phoneController.dispose();
      } catch (_) {}

      try {
        addressController.dispose();
      } catch (_) {}
    });
  }

  // =========================================================
  // EDIT FIELD
  // =========================================================

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int? maxLength,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization =
        TextCapitalization.none,
    String? hintText,
    bool alignLabelWithHint = false,
  }) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        fontSize: _bodyFontSize,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(
          icon,
          size: 20,
        ),
        counterText: '',
        alignLabelWithHint:
            alignLabelWithHint,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(6),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(6),
          borderSide: const BorderSide(
            color: _borderColor,
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(6),
          borderSide: const BorderSide(
            color: _primaryColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // LOGOUT DIALOG
  // =========================================================

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              fontSize: _dialogTitleFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari akun ini?',
            style: TextStyle(
              fontSize: _bodyFontSize,
              height: 1.4,
            ),
          ),
          actionsPadding:
              const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontSize: _buttonFontSize,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    _smallRadius,
                  ),
                ),
              ),
              onPressed: () async {
                final prefs =
                    await SharedPreferences
                        .getInstance();

                await prefs.clear();

                if (!mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const LandingPage(),
                  ),
                  (route) => false,
                );
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: _buttonFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // CARD INFORMASI
  // =========================================================

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xffE5E7EB)),
        ),
        child: ListTile(
          leading: Icon(icon, color: const Color(0xffF97316)),
          title: Text(title),
          subtitle: Text(subtitle),
        ),
      ),
    );
  }
}