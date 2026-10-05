import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sayabantu_project/screens/Screens_Landing/landing_page.dart';

import '../../services/api_service.dart';
import '../../services/auth_storage.dart';

class CustomerSettingScreen extends StatefulWidget {
  final VoidCallback onProfileUpdate;

  const CustomerSettingScreen({
    super.key,
    required this.onProfileUpdate,
  });

  @override
  State<CustomerSettingScreen> createState() => _CustomerSettingScreenState();
}

class _CustomerSettingScreenState extends State<CustomerSettingScreen> {
  // =========================================================
  // DESIGN TOKENS
  // =========================================================

  static const double _bodyFontSize = 13;
  static const double _buttonFontSize = 13;
  static const double _smallRadius = 12;
  static const double _cardRadius = 16;
  static const double _dialogTitleFontSize = 18;

  static const Color _primaryColor = Color(0xFFF97316);
  static const Color _borderColor = Color(0xFFE5E7EB);

  static const double _mobileBreakpoint = 700;
  static const double _tabletBreakpoint = 1100;

  // =========================================================
  // INPUT FORMATTERS
  // =========================================================

  static final List<TextInputFormatter> nameFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s.,'-]")),
  ];

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

  String? photoUrl;
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userData = data['user'] ?? data;

        if (!mounted) return;

        setState(() {
          name = userData['name']?.toString() ?? "";
          email = userData['email']?.toString() ?? "";
          phone = userData['phone']?.toString() ?? "";
          address = userData['address']?.toString() ?? "";

          final apiPhoto = userData['photo_url'];
          if (apiPhoto != null &&
              apiPhoto.toString().trim().isNotEmpty &&
              apiPhoto.toString() != 'null') {
            photoUrl = apiPhoto.toString();
          }

          final notifValue = userData['is_notification_enabled'];
          if (notifValue is bool) {
            jobNotification = notifValue;
          } else if (notifValue is int) {
            jobNotification = notifValue == 1;
          } else if (notifValue is String) {
            jobNotification =
                notifValue == '1' || notifValue.toLowerCase() == 'true';
          } else {
            jobNotification = true;
          }

          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error load profile: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  // =========================================================
  // URL FOTO PROFILE
  // =========================================================

  String? getFullPhotoUrl() {
    if (photoUrl == null || photoUrl!.trim().isEmpty || photoUrl == 'null') {
      return null;
    }

    String path = photoUrl!.trim();

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    if (path.startsWith('/')) path = path.substring(1);

    final filename = path.split('/').last;
    if (filename.isEmpty) return null;

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
        if (files == null || files.isEmpty) return;

        final file = files.first;

        if (!file.type.startsWith('image/')) {
          if (!mounted) return;
          _showMessage("File yang dipilih harus berupa gambar.", error: true);
          return;
        }

        final lowerName = file.name.toLowerCase();
        final allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
        final hasValidExtension =
            allowedExtensions.any((ext) => lowerName.endsWith(ext));

        if (!hasValidExtension) {
          if (!mounted) return;
          _showMessage(
            "Format foto harus JPG, JPEG, PNG, atau WEBP.",
            error: true,
          );
          return;
        }

        const int maxSizeInBytes = 5 * 1024 * 1024;
        if (file.size > maxSizeInBytes) {
          if (!mounted) return;
          final sizeMb = (file.size / 1024 / 1024).toStringAsFixed(2);
          _showMessage(
            "Ukuran foto terlalu besar ($sizeMb MB). Maksimal 5 MB.",
            error: true,
          );
          return;
        }

        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);

        reader.onLoadEnd.listen((event) async {
          try {
            if (reader.result == null) return;

            final Uint8List bytes = reader.result as Uint8List;

            if (!mounted) return;

            setState(() {
              selectedPhotoBytes = bytes;
              selectedPhotoName = file.name;
            });

            await uploadProfilePhoto();
          } catch (e) {
            if (!mounted) return;
            _showMessage("Gagal membaca foto.", error: true);
          }
        });
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage("Gagal memilih foto.", error: true);
    }
  }

  // =========================================================
  // UPLOAD FOTO
  // =========================================================

  Future<void> uploadProfilePhoto() async {
    if (selectedPhotoBytes == null || selectedPhotoName == null) return;

    try {
      if (!mounted) return;
      setState(() => isUploadingPhoto = true);

      final token = await getToken();
      if (token.isEmpty) {
        if (!mounted) return;
        setState(() => isUploadingPhoto = false);
        _showMessage("Token login tidak ditemukan.", error: true);
        return;
      }

      final request = html.HttpRequest();
      request.open('POST', 'http://127.0.0.1:8000/api/user/profile/photo');
      request.setRequestHeader('Authorization', 'Bearer $token');

      final formData = html.FormData();

      String mimeType = 'image/jpeg';
      final lowerName = selectedPhotoName!.toLowerCase();
      if (lowerName.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (lowerName.endsWith('.webp')) {
        mimeType = 'image/webp';
      }

      final blob = html.Blob([selectedPhotoBytes!], mimeType);
      formData.appendBlob('photo_profile', blob, selectedPhotoName!);

      request.onLoad.listen((event) async {
        if (request.status == 200) {
          try {
            final responseData = jsonDecode(request.responseText ?? '{}');
            String? returnedPhotoUrl;

            if (responseData['photo_url'] != null) {
              returnedPhotoUrl = responseData['photo_url'].toString();
            }

            final responseUser = responseData['user'];
            if (responseUser is Map && responseUser['photo_url'] != null) {
              returnedPhotoUrl = responseUser['photo_url'].toString();
            }

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
            _showMessage("Foto profil berhasil diperbarui.");
          } catch (e) {
            if (!mounted) return;
            setState(() => isUploadingPhoto = false);
            _showMessage("Foto berhasil diupload.");
          }
        } else {
          if (!mounted) return;
          setState(() => isUploadingPhoto = false);

          String errorMessage = "Gagal upload foto.";
          try {
            final errorData = jsonDecode(request.responseText ?? '{}');
            if (errorData['errors'] is Map) {
              final errors = errorData['errors'] as Map;
              if (errors['photo_profile'] is List &&
                  (errors['photo_profile'] as List).isNotEmpty) {
                errorMessage = errors['photo_profile'][0].toString();
              } else if (errors.isNotEmpty) {
                final firstKey = errors.keys.first;
                if (errors[firstKey] is List &&
                    (errors[firstKey] as List).isNotEmpty) {
                  errorMessage = (errors[firstKey] as List)[0].toString();
                }
              }
            } else if (errorData['message'] != null) {
              errorMessage = errorData['message'].toString();
            }
          } catch (_) {}

          _showMessage(errorMessage, error: true);
        }
      });

      request.onError.listen((event) {
        if (!mounted) return;
        setState(() => isUploadingPhoto = false);
        _showMessage("Tidak dapat terhubung ke server.", error: true);
      });

      request.send(formData);
    } catch (e) {
      if (!mounted) return;
      setState(() => isUploadingPhoto = false);
      _showMessage("Terjadi kesalahan saat upload foto.", error: true);
    }
  }

  // =========================================================
  // TOKEN
  // =========================================================

  Future<String> getToken() async {
    return AuthStorage.getString('token') ?? '';
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

    if (trimmedName.isEmpty) {
      _showMessage('Nama wajib diisi.', error: true);
      return;
    }
    if (trimmedName.length < 3) {
      _showMessage('Nama minimal 3 karakter.', error: true);
      return;
    }
    if (trimmedEmail.isEmpty) {
      _showMessage('Email wajib diisi.', error: true);
      return;
    }
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(trimmedEmail)) {
      _showMessage('Format email tidak valid.', error: true);
      return;
    }
    if (trimmedPhone.isNotEmpty) {
      if (!RegExp(r'^[0-9]+$').hasMatch(trimmedPhone)) {
        _showMessage('Nomor HP hanya boleh berisi angka.', error: true);
        return;
      }
      if (trimmedPhone.length < 10 || trimmedPhone.length > 15) {
        _showMessage('Nomor HP harus 10-15 digit.', error: true);
        return;
      }
    }
    if (trimmedAddress.isNotEmpty && trimmedAddress.length < 5) {
      _showMessage('Alamat minimal 5 karakter.', error: true);
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
        _showMessage('Profil berhasil diperbarui.');
      } else {
        String message = 'Gagal memperbarui profil.';
        try {
          final data = jsonDecode(response.body);
          message = data['message']?.toString() ?? message;
        } catch (_) {}
        _showMessage(message, error: true);
      }
    } catch (e) {
      _showMessage(
        'Terjadi kesalahan saat memperbarui profil.',
        error: true,
      );
    }
  }

  // =========================================================
  // UPDATE NOTIFICATION
  // =========================================================

  Future<void> updateNotificationStatus(bool value) async {
    try {
      await ApiService.put(
        '/user/notification-setting',
        {'is_notification_enabled': value ? 1 : 0},
      );
    } catch (e) {
      debugPrint("Error update notification: $e");
    }
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontSize: _bodyFontSize),
          ),
          backgroundColor: error ? Colors.red : Colors.green,
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
          child: CircularProgressIndicator(color: _primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < _mobileBreakpoint;
          final isTablet =
              width >= _mobileBreakpoint && width < _tabletBreakpoint;

          final horizontalPadding =
              isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
          final verticalPadding = isMobile ? 16.0 : 28.0;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isMobile),
                    SizedBox(height: isMobile ? 20 : 28),

                    if (isMobile)
                      _buildMobileLayout()
                    else
                      _buildWebLayout(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pengaturan',
          style: TextStyle(
            fontSize: isMobile ? 22 : 26,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kelola profil, notifikasi, dan keamanan akun.',
          style: TextStyle(
            fontSize: isMobile ? 12.5 : 13,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // MOBILE LAYOUT
  // =========================================================

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileHeader(isMobile: true),
        const SizedBox(height: 24),

        _sectionTitle('Informasi Akun'),
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
          subtitle: phone.isEmpty ? '-' : phone,
        ),
        _buildInfoCard(
          icon: Icons.location_on_outlined,
          title: 'Alamat',
          subtitle: address.isEmpty ? '-' : address,
        ),

        const SizedBox(height: 20),
        _sectionTitle('Notifikasi'),
        const SizedBox(height: 12),
        _buildNotificationCard(isMobile: true),

        const SizedBox(height: 20),
        _sectionTitle('Keamanan'),
        const SizedBox(height: 12),
        _buildSecurityCard(),

        const SizedBox(height: 28),
      ],
    );
  }

  // =========================================================
  // WEB LAYOUT
  // =========================================================

  Widget _buildWebLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileHeader(isMobile: false),
              const SizedBox(height: 20),
              _sectionTitle('Informasi Akun'),
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
                subtitle: phone.isEmpty ? '-' : phone,
              ),
              _buildInfoCard(
                icon: Icons.location_on_outlined,
                title: 'Alamat',
                subtitle: address.isEmpty ? '-' : address,
              ),
            ],
          ),
        ),

        const SizedBox(width: 24),

        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionTitle('Notifikasi'),
              const SizedBox(height: 12),
              _buildNotificationCard(isMobile: false),
              const SizedBox(height: 20),
              _sectionTitle('Keamanan'),
              const SizedBox(height: 12),
              _buildSecurityCard(),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // SECTION TITLE
  // =========================================================

  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: _primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // PROFILE HEADER (FIXED WITH LAYOUT BUILDER)
  // =========================================================

  Widget _buildProfileHeader({required bool isMobile}) {
    final fullPhotoUrl = getFullPhotoUrl();

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Jika lebar kolom kurang dari 450px, gunakan layout vertikal (Column)
          // untuk menghindari teks menumpuk dan error overflow.
          final isNarrow = constraints.maxWidth < 450;

          if (isMobile || isNarrow) {
            return Column(
              children: [
                _buildAvatar(fullPhotoUrl, radius: 48),
                const SizedBox(height: 16),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                _buildEditProfileButton(),
              ],
            );
          }

          // Layout Horizontal (Row) untuk layar lebar
          return Row(
            children: [
              _buildAvatar(fullPhotoUrl, radius: 44),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (phone.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            phone,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildEditProfileButton(),
            ],
          );
        },
      ),
    );
  }

  // =========================================================
  // AVATAR — selalu center
  // =========================================================

  Widget _buildAvatar(String? fullPhotoUrl, {required double radius}) {
    final size = radius * 2;

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Avatar mengisi penuh SizedBox — pasti center
            GestureDetector(
              onTap: () {
                if (selectedPhotoBytes != null) {
                  _showImageDialog(
                    context,
                    MemoryImage(selectedPhotoBytes!),
                  );
                } else if (fullPhotoUrl != null) {
                  _showImageDialog(context, NetworkImage(fullPhotoUrl));
                }
              },
              child: CircleAvatar(
                radius: radius,
                backgroundColor: const Color(0xFFFFF3E8),
                backgroundImage: selectedPhotoBytes != null
                    ? MemoryImage(selectedPhotoBytes!)
                    : fullPhotoUrl != null
                        ? NetworkImage(fullPhotoUrl)
                        : null,
                child: selectedPhotoBytes == null && fullPhotoUrl == null
                    ? Icon(
                        Icons.person,
                        size: radius * 1.05,
                        color: _primaryColor,
                      )
                    : null,
              ),
            ),

            // Tombol camera — Positioned absolut
            Positioned(
              right: -2,
              bottom: -2,
              child: Material(
                color: _primaryColor,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  onTap: isUploadingPhoto ? null : pickProfilePhoto,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: isUploadingPhoto
                        ? const Padding(
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 15,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // EDIT PROFILE BUTTON
  // =========================================================

  Widget _buildEditProfileButton() {
    return ElevatedButton.icon(
      onPressed: () => _showEditProfileDialog(getFullPhotoUrl()),
      icon: const Icon(Icons.edit, size: 16),
      label: const Text(
        'Edit Profil',
        style: TextStyle(
          fontSize: _buttonFontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_smallRadius),
        ),
      ),
    );
  }

  // =========================================================
  // INFO CARD
  // =========================================================

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: _primaryColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                    height: 1.35,
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

  Widget _buildNotificationCard({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: _primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notifikasi Penawaran',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isMobile
                      ? 'Terima notifikasi ketika mitra mengirim penawaran.'
                      : 'Terima notifikasi ketika mitra mengirim penawaran pada pekerjaan Anda.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: jobNotification,
            activeColor: _primaryColor,
            onChanged: (value) async {
              setState(() => jobNotification = value);
              await updateNotificationStatus(value);
              if (!mounted) return;
              _showMessage(
                value
                    ? 'Notifikasi penawaran diaktifkan.'
                    : 'Notifikasi penawaran dinonaktifkan.',
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(_cardRadius),
          onTap: _showLogoutDialog,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keluar dari Akun',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Keluar dari akun SayaBantu.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 22,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // EDIT PROFILE DIALOG — TANPA DISPOSE MANUAL
  // =========================================================

  void _showEditProfileDialog(String? fullPhotoUrl) {
    final nameController = TextEditingController(text: name);
    final emailController = TextEditingController(text: email);
    final phoneController = TextEditingController(text: phone);
    final addressController = TextEditingController(text: address);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // HEADER
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: _primaryColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Edit Profil',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(
                            Icons.close,
                            size: 20,
                            color: Color(0xFF6B7280),
                          ),
                          splashRadius: 22,
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFE5E7EB)),

                  // BODY
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // FOTO
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                if (selectedPhotoBytes != null) {
                                  _showImageDialog(
                                    dialogContext,
                                    MemoryImage(selectedPhotoBytes!),
                                  );
                                } else if (fullPhotoUrl != null) {
                                  _showImageDialog(
                                    dialogContext,
                                    NetworkImage(fullPhotoUrl),
                                  );
                                }
                              },
                              child: SizedBox(
                                width: 90,
                                height: 90,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    CircleAvatar(
                                      radius: 45,
                                      backgroundColor:
                                          const Color(0xFFFFF3E8),
                                      backgroundImage:
                                          selectedPhotoBytes != null
                                              ? MemoryImage(
                                                  selectedPhotoBytes!)
                                              : fullPhotoUrl != null
                                                  ? NetworkImage(
                                                      fullPhotoUrl)
                                                  : null,
                                      child: selectedPhotoBytes == null &&
                                              fullPhotoUrl == null
                                          ? const Icon(
                                              Icons.person,
                                              size: 46,
                                              color: _primaryColor,
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      right: -2,
                                      bottom: -2,
                                      child: Material(
                                        color: _primaryColor,
                                        shape: const CircleBorder(),
                                        elevation: 2,
                                        child: InkWell(
                                          onTap: () async {
                                            Navigator.pop(dialogContext);
                                            await pickProfilePhoto();
                                          },
                                          customBorder:
                                              const CircleBorder(),
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: _primaryColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt,
                                              color: Colors.white,
                                              size: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),
                          const Text(
                            'Ketuk foto untuk mengganti',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF94A3B8),
                            ),
                          ),

                          const SizedBox(height: 20),

                          _buildEditField(
                            controller: nameController,
                            label: 'Nama',
                            icon: Icons.person_outline,
                            maxLength: 100,
                            inputFormatters: nameFormatters,
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 12),
                          _buildEditField(
                            controller: emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            maxLength: 100,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          _buildEditField(
                            controller: phoneController,
                            label: 'Nomor HP',
                            icon: Icons.phone_outlined,
                            maxLength: 15,
                            keyboardType: TextInputType.phone,
                            inputFormatters: digitsOnly,
                            hintText: '10-15 digit angka',
                          ),
                          const SizedBox(height: 12),
                          _buildEditField(
                            controller: addressController,
                            label: 'Alamat',
                            icon: Icons.location_on_outlined,
                            maxLength: 500,
                            maxLines: 3,
                            alignLabelWithHint: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFE5E7EB)),

                  // ACTIONS
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 46),
                              foregroundColor: const Color(0xFF374151),
                              side: const BorderSide(
                                color: Color(0xFFD1D5DB),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Batal',
                              style: TextStyle(
                                fontSize: _buttonFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 46),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              final newName = nameController.text.trim();
                              final newEmail =
                                  emailController.text.trim();
                              final newPhone =
                                  phoneController.text.trim();
                              final newAddress =
                                  addressController.text.trim();

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
                                fontWeight: FontWeight.w700,
                              ),
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
        );
      },
    );
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
    TextCapitalization textCapitalization = TextCapitalization.none,
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
      style: const TextStyle(fontSize: _bodyFontSize),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, size: 19),
        counterText: '',
        alignLabelWithHint: alignLabelWithHint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
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
            borderRadius: BorderRadius.circular(16),
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
            style: TextStyle(fontSize: _bodyFontSize, height: 1.4),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Batal',
                style: TextStyle(fontSize: _buttonFontSize),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_smallRadius),
                ),
              ),
              onPressed: () {
                AuthStorage.clear();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LandingPage()),
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
}