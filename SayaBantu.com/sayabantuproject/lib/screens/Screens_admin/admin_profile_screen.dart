import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../services/auth_storage.dart';

class AdminProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;
  final VoidCallback? onLogout;

  const AdminProfileScreen({
    super.key,
    this.onProfileUpdated,
    this.onLogout,
  });

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  // ============================================================
  // DESIGN TOKENS — disamakan dgn DashboardHeader / PaymentScreen
  // ============================================================

  static const Color _accent = Color(0xFFF97316);
  static const Color _accentLight = Color(0xFFFB923C);
  static const Color _successColor = Color(0xFF16A34A);
  static const Color _dangerColor = Color(0xFFDC2626);
  static const Color _tableBorder = Color(0xFFE5E7EB);
  static const Color _tableDivider = Color(0xFFF3F4F6);
  static const Color _headerText = Color(0xFF6B7280);
  static const Color _cellText = Color(0xFF111827);
  static const Color _mutedText = Color(0xFF64748B);

  static const double _gapAfterHeader = 16;
  static const double _gapBetweenSections = 16;
  static const double _cardRadius = 14;
  static const double _radius = 10;

  // ============================================================
  // STATE
  // ============================================================

  String adminName = 'Memuat...';
  String adminEmail = 'Memuat...';
  String adminRole = 'Memuat...';

  String? photoUrl;

  Uint8List? selectedPhotoBytes;
  String? selectedPhotoName;

  bool isUploadingPhoto = false;

  bool isLoading = true;
  bool isSaving = false;

  // ============================================================
  // INPUT FORMATTERS
  // ============================================================

  static final List<TextInputFormatter> nameFormatters = [
    FilteringTextInputFormatter.allow(
      RegExp(r"[a-zA-Z\s.,'-]"),
    ),
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? _dangerColor : _successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // PREVIEW IMAGE DIALOG
  // ============================================================

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

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadAdminProfile() async {
    try {
      final response = await ApiService.get('/user');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        final user = decodedData['data'] ??
            decodedData['user'] ??
            decodedData;

        if (user is Map) {
          final apiName = user['name']?.toString();
          final apiEmail = user['email']?.toString();
          final apiRole =
              user['role']?.toString() ?? user['role_name']?.toString();
          final apiPhotoUrl = user['photo_url']?.toString();

          setState(() {
            adminName = apiName != null && apiName.isNotEmpty
                ? apiName
                : 'Admin';
            adminEmail = apiEmail != null && apiEmail.isNotEmpty
                ? apiEmail
                : '-';
            adminRole = apiRole != null && apiRole.isNotEmpty
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

          debugPrint('ADMIN PROFILE: $user');
          debugPrint('ADMIN PHOTO URL: $photoUrl');
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
        debugPrint('GET /user ERROR: ${response.statusCode} ${response.body}');
        _showMessage('Gagal mengambil data profil.', error: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      debugPrint('LOAD ADMIN PROFILE ERROR: $e');
      _showMessage('Terjadi kesalahan saat mengambil profil.', error: true);
    }
  }

  // ============================================================
  // GET FULL PHOTO URL
  // ============================================================

  String? _getFullPhotoUrl() {
    if (photoUrl == null ||
        photoUrl!.trim().isEmpty ||
        photoUrl == 'null') {
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

  // ============================================================
  // GET INITIALS
  // ============================================================

  String _getInitials(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'A';

    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return ('${words.first[0]}${words.last[0]}').toUpperCase();
    }
    return words.first[0].toUpperCase();
  }

  // ============================================================
  // PICK PROFILE PHOTO
  // ============================================================

  Future<void> _pickProfilePhoto() async {
    if (isUploadingPhoto) return;

    final input = html.FileUploadInputElement();
    input.accept = 'image/*';
    input.click();

    input.onChange.listen((event) async {
      final files = input.files;
      if (files == null || files.isEmpty) return;

      final file = files.first;

      if (!file.type.startsWith('image/')) {
        if (!mounted) return;
        _showMessage('File yang dipilih harus berupa gambar.', error: true);
        return;
      }

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;

      if (!mounted) return;

      try {
        final Uint8List bytes = reader.result as Uint8List;

        setState(() {
          selectedPhotoBytes = bytes;
          selectedPhotoName = file.name;
        });

        await _uploadProfilePhoto();
      } catch (e) {
        debugPrint('READ PHOTO ERROR: $e');
        if (!mounted) return;
        _showMessage('Gagal membaca foto.', error: true);
      }
    });
  }

  // ============================================================
  // UPLOAD PROFILE PHOTO
  // ============================================================

  Future<void> _uploadProfilePhoto() async {
    if (selectedPhotoBytes == null || selectedPhotoName == null) return;
    if (isUploadingPhoto) return;

    setState(() => isUploadingPhoto = true);

    try {
      final token = AuthStorage.getString('token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() => isUploadingPhoto = false);
        _showMessage('Token login tidak ditemukan.', error: true);
        return;
      }

      final request = html.HttpRequest();
      request.open('POST', 'http://127.0.0.1:8000/api/user/profile/photo');
      request.setRequestHeader('Authorization', 'Bearer $token');

      final formData = html.FormData();
      final extension = selectedPhotoName!.split('.').last.toLowerCase();

      String mimeType = 'image/jpeg';
      if (extension == 'png') {
        mimeType = 'image/png';
      } else if (extension == 'webp') {
        mimeType = 'image/webp';
      } else if (extension == 'jpg' || extension == 'jpeg') {
        mimeType = 'image/jpeg';
      }

      final blob = html.Blob([selectedPhotoBytes!], mimeType);
      formData.appendBlob('photo_profile', blob, selectedPhotoName!);

      request.send(formData);
      await request.onLoad.first;

      if (!mounted) return;

      debugPrint('UPLOAD PHOTO STATUS: ${request.status}');
      debugPrint('UPLOAD PHOTO RESPONSE: ${request.responseText}');

      if (request.status == 200) {
        try {
          final decoded = jsonDecode(request.responseText ?? '{}');
          final returnedPhotoUrl =
              decoded['photo_url'] ?? decoded['user']?['photo_url'];

          setState(() {
            if (returnedPhotoUrl != null &&
                returnedPhotoUrl.toString().isNotEmpty &&
                returnedPhotoUrl.toString() != 'null') {
              photoUrl = returnedPhotoUrl.toString();
            }
            isUploadingPhoto = false;
          });
        } catch (e) {
          setState(() => isUploadingPhoto = false);
          debugPrint('PARSE UPLOAD RESPONSE ERROR: $e');
        }

        widget.onProfileUpdated?.call();
        _showMessage('Foto profil berhasil diperbarui.');
      } else {
        setState(() => isUploadingPhoto = false);

        String message = 'Gagal mengunggah foto profil.';
        try {
          final decoded = jsonDecode(request.responseText ?? '{}');
          if (decoded['message'] != null) {
            message = decoded['message'].toString();
          }
        } catch (_) {}

        _showMessage(message, error: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isUploadingPhoto = false);
      debugPrint('UPLOAD PROFILE PHOTO ERROR: $e');
      _showMessage('Terjadi kesalahan saat mengunggah foto.', error: true);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 700;
          final isTablet = width >= 700 && width < 1100;

          final horizontalPadding =
              isMobile ? 16.0 : (isTablet ? 24.0 : 28.0);
          final verticalPadding = isMobile ? 16.0 : 28.0;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),

                const SizedBox(height: _gapAfterHeader),

                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: CircularProgressIndicator(color: _accent),
                    ),
                  )
                else ...[
                  _buildProfileCard(context, isMobile),
                  const SizedBox(height: _gapBetweenSections),
                  _buildAccountCard(context, isMobile),
                  const SizedBox(height: _gapBetweenSections),
                  _buildSecurityCard(context, isMobile),

                  if (isMobile && widget.onLogout != null) ...[
                    const SizedBox(height: _gapBetweenSections),
                    _buildLogoutCard(context),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // HEADER — sama persis dgn DashboardHeader
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profil Admin',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kelola informasi dan keamanan akun admin.',
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOGOUT CARD
  // ============================================================

  Widget _buildLogoutCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keluar dari Akun',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _cellText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kamu akan keluar dari sesi admin saat ini.',
            style: textTheme.bodySmall?.copyWith(color: _mutedText),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () {
                FocusScope.of(context).unfocus();
                widget.onLogout?.call();
              },
              icon: const Icon(
                Icons.logout_outlined,
                color: _dangerColor,
                size: 18,
              ),
              label: const Text(
                'Keluar Sekarang',
                style: TextStyle(
                  color: _dangerColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: _dangerColor,
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_radius),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE CARD
  // ============================================================

  Widget _buildProfileCard(BuildContext context, bool isMobile) {
    return _sectionCard(
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _profileInfo(context),
                const SizedBox(height: 16),
                _editButton(context),
              ],
            )
          : Row(
              children: [
                Expanded(child: _profileInfo(context)),
                _editButton(context),
              ],
            ),
    );
  }

  // ============================================================
  // PROFILE INFO
  // ============================================================

  Widget _profileInfo(BuildContext context) {
    final fullPhotoUrl = _getFullPhotoUrl();
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        GestureDetector(
          onTap: () {
            if (selectedPhotoBytes != null) {
              _showImageDialog(
                  context, MemoryImage(selectedPhotoBytes!));
            } else if (fullPhotoUrl != null) {
              _showImageDialog(context, NetworkImage(fullPhotoUrl));
            }
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: _accent.withOpacity(0.12),
                backgroundImage: selectedPhotoBytes != null
                    ? MemoryImage(selectedPhotoBytes!)
                    : fullPhotoUrl != null
                        ? NetworkImage(fullPhotoUrl)
                        : null,
                child: selectedPhotoBytes == null && fullPhotoUrl == null
                    ? const Icon(
                        Icons.shield_outlined,
                        color: _accent,
                        size: 32,
                      )
                    : null,
              ),
              Positioned(
                right: -3,
                bottom: -3,
                child: InkWell(
                  onTap: isUploadingPhoto ? null : _pickProfilePhoto,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: const BoxDecoration(
                      color: _accent,
                      shape: BoxShape.circle,
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
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 13,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                adminName,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _cellText,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                adminEmail,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(color: _mutedText),
              ),
              const SizedBox(height: 7),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _successColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  adminRole,
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _successColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EDIT BUTTON
  // ============================================================

  Widget _editButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isSaving ? null : () => _showEditProfileDialog(context),
      icon: const Icon(Icons.edit_outlined, size: 16),
      label: const Text(
        'Edit Profil',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
      ),
    );
  }

  // ============================================================
  // EDIT PROFILE DIALOG
  // ============================================================

  void _showEditProfileDialog(BuildContext context) {
    final nameController = TextEditingController(text: adminName);
    final emailController = TextEditingController(text: adminEmail);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final fullPhotoUrl = _getFullPhotoUrl();
        final textTheme = Theme.of(dialogContext).textTheme;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HEADER
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(_radius),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: _accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Edit Profil',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _cellText,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(),
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: _headerText,
                        ),
                        splashRadius: 22,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // CONTENT
                  Flexible(
                    child: SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // FOTO PROFIL
                            GestureDetector(
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
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CircleAvatar(
                                    radius: 45,
                                    backgroundColor:
                                        _accent.withOpacity(0.12),
                                    backgroundImage:
                                        selectedPhotoBytes != null
                                            ? MemoryImage(
                                                selectedPhotoBytes!)
                                            : fullPhotoUrl != null
                                                ? NetworkImage(fullPhotoUrl)
                                                : null,
                                    child: selectedPhotoBytes == null &&
                                            fullPhotoUrl == null
                                        ? const Icon(
                                            Icons.shield_outlined,
                                            color: _accent,
                                            size: 42,
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    right: -2,
                                    bottom: 0,
                                    child: InkWell(
                                      onTap: isUploadingPhoto
                                          ? null
                                          : () async {
                                              Navigator.of(dialogContext)
                                                  .pop();
                                              await _pickProfilePhoto();
                                            },
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: const BoxDecoration(
                                          color: _accent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: isUploadingPhoto
                                            ? const Padding(
                                                padding:
                                                    EdgeInsets.all(7),
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Icon(
                                                Icons
                                                    .camera_alt_outlined,
                                                color: Colors.white,
                                                size: 15,
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Klik ikon kamera untuk mengganti foto',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // NAMA
                            TextFormField(
                              controller: nameController,
                              maxLength: 100,
                              inputFormatters: nameFormatters,
                              textCapitalization:
                                  TextCapitalization.words,
                              style: const TextStyle(fontSize: 13),
                              decoration: _inputDecoration(
                                label: 'Nama Lengkap',
                                icon: Icons.person_outline,
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Nama tidak boleh kosong';
                                }
                                if (value.trim().length < 3) {
                                  return 'Nama minimal 3 karakter';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // EMAIL
                            TextFormField(
                              controller: emailController,
                              maxLength: 100,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(fontSize: 13),
                              decoration: _inputDecoration(
                                label: 'Email',
                                icon: Icons.email_outlined,
                              ),
                              validator: (value) {
                                final trimmed = value?.trim() ?? '';
                                if (trimmed.isEmpty) {
                                  return 'Email tidak boleh kosong';
                                }
                                if (!RegExp(
                                        r'^[\w\.-]+@[\w\.-]+\.\w+$')
                                    .hasMatch(trimmed)) {
                                  return 'Format email tidak valid';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ACTIONS
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 46),
                            foregroundColor:
                                const Color(0xFF374151),
                            side: const BorderSide(
                              color: Color(0xFFD1D5DB),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_radius),
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }
                            final newName = nameController.text.trim();
                            final newEmail =
                                emailController.text.trim();
                            await _updateProfile(
                              dialogContext,
                              newName,
                              newEmail,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 46),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_radius),
                            ),
                          ),
                          child: const Text(
                            'Simpan',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      emailController.dispose();
    });
  }

  // ============================================================
  // UPDATE PROFILE
  // ============================================================

  Future<void> _updateProfile(
    BuildContext dialogContext,
    String newName,
    String newEmail,
  ) async {
    if (isSaving) return;

    setState(() => isSaving = true);

    try {
      final response = await ApiService.put(
        '/user/profile',
        {'name': newName, 'email': newEmail},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          adminName = newName;
          adminEmail = newEmail;
          isSaving = false;
        });

        AuthStorage.setString('name', newName);
        AuthStorage.setString('email', newEmail);

        if (dialogContext.mounted) {
          Navigator.of(dialogContext).pop();
        }

        widget.onProfileUpdated?.call();
        _showMessage('Profil berhasil diperbarui.');
      } else {
        setState(() => isSaving = false);

        String message = 'Gagal memperbarui profil.';
        try {
          final decoded = jsonDecode(response.body);
          message = decoded['message']?.toString() ?? message;
        } catch (_) {}

        debugPrint(
          'UPDATE PROFILE ERROR: ${response.statusCode} ${response.body}',
        );
        _showMessage(message, error: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isSaving = false);
      debugPrint('UPDATE PROFILE ERROR: $e');
      _showMessage('Terjadi kesalahan saat memperbarui profil.',
          error: true);
    }
  }

  // ============================================================
  // ACCOUNT CARD
  // ============================================================

  Widget _buildAccountCard(BuildContext context, bool isMobile) {
    final textTheme = Theme.of(context).textTheme;

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Akun',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _cellText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Informasi dasar akun administrator.',
            style: textTheme.bodySmall?.copyWith(color: _mutedText),
          ),
          const SizedBox(height: 20),
          if (isMobile)
            Column(
              children: [
                _infoItem(context, Icons.person_outline, 'Nama Lengkap',
                    adminName),
                const SizedBox(height: 15),
                _infoItem(
                    context, Icons.email_outlined, 'Email', adminEmail),
                const SizedBox(height: 15),
                _infoItem(context, Icons.admin_panel_settings_outlined,
                    'Level Akses', adminRole),
                const SizedBox(height: 15),
                _infoItem(
                  context,
                  Icons.check_circle_outline,
                  'Status Akun',
                  'Aktif',
                  valueColor: _successColor,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _infoItem(context, Icons.person_outline,
                          'Nama Lengkap', adminName),
                      const SizedBox(height: 18),
                      _infoItem(
                        context,
                        Icons.admin_panel_settings_outlined,
                        'Level Akses',
                        adminRole,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
                Expanded(
                  child: Column(
                    children: [
                      _infoItem(context, Icons.email_outlined, 'Email',
                          adminEmail),
                      const SizedBox(height: 18),
                      _infoItem(
                        context,
                        Icons.check_circle_outline,
                        'Status Akun',
                        'Aktif',
                        valueColor: _successColor,
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

  // ============================================================
  // INFO ITEM
  // ============================================================

  Widget _infoItem(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(_radius),
          ),
          child: Icon(icon, size: 18, color: _mutedText),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECURITY CARD
  // ============================================================

  Widget _buildSecurityCard(BuildContext context, bool isMobile) {
    final textTheme = Theme.of(context).textTheme;

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keamanan Akun',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _cellText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pengaturan keamanan akun administrator.',
            style: textTheme.bodySmall?.copyWith(color: _mutedText),
          ),
          const SizedBox(height: 18),
          _securityItem(
            context,
            Icons.lock_outline,
            'Kata Sandi',
            'Kata sandi dapat diperbarui',
            'Ubah',
            _accent,
          ),
          const Divider(height: 1, color: _tableDivider),
          _securityItem(
            context,
            Icons.verified_user_outlined,
            'Verifikasi Akun',
            'Akun administrator telah terverifikasi',
            'Terverifikasi',
            _successColor,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECURITY ITEM
  // ============================================================

  Widget _securityItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    String action,
    Color actionColor,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(_radius),
            ),
            child: Icon(icon, size: 18, color: _mutedText),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: title == 'Kata Sandi'
                ? () => _showChangePasswordDialog(context)
                : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: actionColor,
              side: BorderSide(color: actionColor),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            child: Text(
              action,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHANGE PASSWORD DIALOG
  // ============================================================

  void _showChangePasswordDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final textTheme = Theme.of(dialogContext).textTheme;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // HEADER
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _accent.withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(_radius),
                            ),
                            child: const Icon(
                              Icons.lock_outline,
                              color: _accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ubah Kata Sandi',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _cellText,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(),
                            icon: const Icon(
                              Icons.close,
                              size: 20,
                              color: _headerText,
                            ),
                            splashRadius: 22,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      // CONTENT
                      Flexible(
                        child: SingleChildScrollView(
                          child: Form(
                            key: formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _passwordField(
                                  controller: oldPasswordController,
                                  label: 'Kata Sandi Lama',
                                  obscureText: obscureOld,
                                  onToggle: () => setDialogState(
                                      () => obscureOld = !obscureOld),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Masukkan kata sandi lama';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                _passwordField(
                                  controller: newPasswordController,
                                  label: 'Kata Sandi Baru',
                                  obscureText: obscureNew,
                                  onToggle: () => setDialogState(
                                      () => obscureNew = !obscureNew),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Masukkan kata sandi baru';
                                    }
                                    if (value.length < 8) {
                                      return 'Minimal 8 karakter';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                _passwordField(
                                  controller: confirmPasswordController,
                                  label: 'Konfirmasi Kata Sandi',
                                  obscureText: obscureConfirm,
                                  onToggle: () => setDialogState(
                                      () =>
                                          obscureConfirm = !obscureConfirm),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Konfirmasi kata sandi baru';
                                    }
                                    if (value !=
                                        newPasswordController.text) {
                                      return 'Kata sandi tidak sama';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ACTIONS
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 46),
                                foregroundColor:
                                    const Color(0xFF374151),
                                side: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(_radius),
                                ),
                              ),
                              child: const Text(
                                'Batal',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }
                                await _changePassword(
                                  dialogContext,
                                  oldPasswordController.text,
                                  newPasswordController.text,
                                  confirmPasswordController.text,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 46),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(_radius),
                                ),
                              ),
                              child: const Text(
                                'Simpan',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      oldPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    });
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  Future<void> _changePassword(
    BuildContext dialogContext,
    String oldPassword,
    String newPassword,
    String confirmation,
  ) async {
    try {
      final response = await ApiService.post(
        '/change-password',
        {
          'current_password': oldPassword,
          'new_password': newPassword,
          'new_password_confirmation': confirmation,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        if (dialogContext.mounted) {
          Navigator.of(dialogContext).pop();
        }
        _showMessage('Kata sandi berhasil diubah.');
      } else {
        String message = 'Gagal mengubah kata sandi.';
        try {
          final decoded = jsonDecode(response.body);
          message = decoded['message']?.toString() ?? message;
        } catch (_) {}
        _showMessage(message, error: true);
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('CHANGE PASSWORD ERROR: $e');
      _showMessage('Terjadi kesalahan saat mengubah kata sandi.',
          error: true);
    }
  }

  // ============================================================
  // SHARED WIDGETS
  // ============================================================

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _tableBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18),
      counterText: '',
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      labelStyle: const TextStyle(fontSize: 13, color: _headerText),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: _tableBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: _tableBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLength: 100,
      style: const TextStyle(fontSize: 13),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, size: 18),
        counterText: '',
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        labelStyle: const TextStyle(fontSize: 13, color: _headerText),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: _tableBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: _tableBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
      ),
    );
  }
}