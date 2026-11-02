import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sayabantu_project/screens/Screens_Landing/landing_page.dart';

import '../../services/api_service.dart';
import '../../services/auth_storage.dart';
import '../../theme/app_colors.dart';

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
  // DESIGN TOKENS
  // =========================================================

  static const double _buttonFontSize = 13;
  static const double _bodyFontSize = 13;
  static const double _smallRadius = 12;
  static const double _cardRadius = 16;

  static const Color _primaryColor = AppColors.primaryTeal;
  static const Color _borderColor = Color(0xFFE5E7EB);

  static const double _mobileBreakpoint = 700;
  static const double _tabletBreakpoint = 1100;

  static const double _gapAfterHeader = 16;
  static const double _gapBetweenSections = 20;
  static const double _gapTitleToContent = 12;

  // =========================================================
  // INPUT FORMATTERS
  // =========================================================

  static final List<TextInputFormatter> nameFormatters = [
    FilteringTextInputFormatter.allow(
      RegExp(r"[a-zA-Z\s.,'-]"),
    ),
  ];

  static final List<TextInputFormatter> digitsOnly = [
    FilteringTextInputFormatter.digitsOnly,
  ];

  // =========================================================
  // STATE
  // =========================================================

  List<Map<String, dynamic>> cities = [];

  int? cityId;
  String cityName = '';

  bool isLoadingCities = false;
  bool isLoading = true;
  bool isUploadingPhoto = false;
  bool _hasPin = false;
  bool jobNotification = true;

  String name = '';
  String email = '';
  String phone = '';
  String address = '';

  String bankName = '';
  String bankAccountNumber = '';
  String bankAccountName = '';

  String? photoUrl;

  Uint8List? selectedPhotoBytes;
  String? selectedPhotoName;

  @override
  void initState() {
    super.initState();
    loadProfileFromApi();
    loadCities();
  }

  // =========================================================
  // LOAD CITIES
  // =========================================================

  Future<void> loadCities() async {
    if (!mounted) return;

    setState(() => isLoadingCities = true);

    try {
      final response = await ApiService.get('/cities');

      if (response.statusCode != 200) {
        throw Exception('Gagal mengambil daftar kota.');
      }

      final decoded = jsonDecode(response.body);

      final List<dynamic> cityData = decoded is List
          ? decoded
          : decoded['data'] is List
              ? decoded['data']
              : [];

      final loadedCities = cityData
          .whereType<Map>()
          .map<Map<String, dynamic>>((city) {
        return {
          'id': int.tryParse(city['id'].toString()),
          'name': city['name']?.toString() ?? '',
        };
      }).where((city) {
        return city['id'] != null &&
            (city['name'] as String).isNotEmpty;
      }).toList();

      if (!mounted) return;

      setState(() {
        cities = loadedCities;
        isLoadingCities = false;
      });
    } catch (e) {
      debugPrint('Error load cities: $e');

      if (!mounted) return;

      setState(() => isLoadingCities = false);
      _showMessage('Gagal memuat daftar kota.', error: true);
    }
  }

  // =========================================================
  // LOAD PROFILE
  // =========================================================

  Future<void> loadProfileFromApi() async {
    try {
      final response = await ApiService.get('/user');

      if (response.statusCode != 200) {
        throw Exception('Gagal mengambil data profil.');
      }

      final decoded = jsonDecode(response.body);
      final userData = decoded['user'] ?? decoded;

      if (!mounted) return;

      setState(() {
        name = userData['name']?.toString() ?? '';
        email = userData['email']?.toString() ?? '';
        phone = userData['phone']?.toString() ?? '';
        address = userData['address']?.toString() ?? '';

        cityId = int.tryParse(
          userData['city_id']?.toString() ?? '',
        );

        final cityData = userData['city'];

        if (cityData is Map) {
          cityName = cityData['name']?.toString() ?? '';
        } else {
          cityName = userData['city_name']?.toString() ?? '';
        }

        _hasPin = userData['has_pin'] == true ||
            userData['has_pin'] == 1 ||
            userData['has_pin'] == '1';

        bankName = userData['bank_name']?.toString() ?? '';
        bankAccountNumber =
            userData['bank_account_number']?.toString() ?? '';
        bankAccountName =
            userData['bank_account_name']?.toString() ?? '';

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
          jobNotification = notifValue == '1' ||
              notifValue.toLowerCase() == 'true';
        } else {
          jobNotification = true;
        }

        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error load profile: $e');

      if (!mounted) return;

      setState(() => isLoading = false);
      _showMessage('Gagal memuat profil pengguna.', error: true);
    }
  }

  // =========================================================
  // FULL PHOTO URL
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

    if (filename.isEmpty) return null;

    return 'http://127.0.0.1:8000/api/images/profile/$filename';
  }

  // =========================================================
  // IMAGE PREVIEW
  // =========================================================

  void _showImageDialog(
    BuildContext context,
    ImageProvider imageProvider,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4,
                child: Image(
                  image: imageProvider,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => Navigator.pop(dialogContext),
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
  // PICK PROFILE PHOTO
  // =========================================================

  Future<void> pickProfilePhoto() async {
    try {
      final uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((event) async {
        final files = uploadInput.files;

        if (files == null || files.isEmpty) return;

        final file = files.first;

        if (!file.type.startsWith('image/')) {
          if (!mounted) return;

          _showMessage(
            'File yang dipilih harus berupa gambar.',
            error: true,
          );
          return;
        }

        final lowerName = file.name.toLowerCase();

        const allowedExtensions = [
          '.jpg',
          '.jpeg',
          '.png',
          '.webp',
        ];

        final validExtension = allowedExtensions.any(
          (ext) => lowerName.endsWith(ext),
        );

        if (!validExtension) {
          if (!mounted) return;

          _showMessage(
            'Format foto harus JPG, JPEG, PNG, atau WEBP.',
            error: true,
          );
          return;
        }

        const maxSize = 5 * 1024 * 1024;

        if (file.size > maxSize) {
          if (!mounted) return;

          final sizeMb =
              (file.size / 1024 / 1024).toStringAsFixed(2);

          _showMessage(
            'Ukuran foto terlalu besar ($sizeMb MB). Maksimal 5 MB.',
            error: true,
          );
          return;
        }

        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);

        reader.onLoadEnd.listen((event) async {
          try {
            if (reader.result == null) return;

            final bytes = reader.result as Uint8List;

            if (!mounted) return;

            setState(() {
              selectedPhotoBytes = bytes;
              selectedPhotoName = file.name;
            });

            await uploadProfilePhoto();
          } catch (e) {
            if (!mounted) return;

            _showMessage('Gagal membaca foto.', error: true);
          }
        });
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage('Gagal memilih foto.', error: true);
    }
  }

  // =========================================================
  // UPLOAD PROFILE PHOTO
  // =========================================================

  Future<void> uploadProfilePhoto() async {
    if (selectedPhotoBytes == null ||
        selectedPhotoName == null) {
      return;
    }

    try {
      if (!mounted) return;

      setState(() => isUploadingPhoto = true);

      final token = await getToken();

      if (token.isEmpty) {
        if (!mounted) return;

        setState(() => isUploadingPhoto = false);

        _showMessage(
          'Token login tidak ditemukan.',
          error: true,
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

      request.onLoad.listen((event) {
        if (request.status == 200) {
          try {
            final responseData =
                jsonDecode(request.responseText ?? '{}');

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

            _showMessage('Foto profil berhasil diperbarui.');
          } catch (e) {
            if (!mounted) return;

            setState(() => isUploadingPhoto = false);

            _showMessage('Foto berhasil diupload.');
          }
        } else {
          if (!mounted) return;

          setState(() => isUploadingPhoto = false);

          String errorMessage = 'Gagal upload foto.';

          try {
            final errorData =
                jsonDecode(request.responseText ?? '{}');

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
                      errors[firstKey][0].toString();
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

        _showMessage(
          'Tidak dapat terhubung ke server.',
          error: true,
        );
      });

      request.send(formData);
    } catch (e) {
      if (!mounted) return;

      setState(() => isUploadingPhoto = false);

      _showMessage(
        'Terjadi kesalahan saat upload foto.',
        error: true,
      );
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

  Future<bool> updateProfileToApi({
    required String newName,
    required String newEmail,
    required String newPhone,
    required String newAddress,
    required String newBankName,
    required String newBankAccountNumber,
    required String newBankAccountName,
    required int? newCityId,
  }) async {
    final trimmedName = newName.trim();
    final trimmedEmail = newEmail.trim();
    final trimmedPhone = newPhone.trim();
    final trimmedAddress = newAddress.trim();
    final trimmedBankName = newBankName.trim();
    final trimmedBankAccountNumber =
        newBankAccountNumber.trim();
    final trimmedBankAccountName =
        newBankAccountName.trim();

    if (trimmedName.isEmpty) {
      _showMessage('Nama wajib diisi.', error: true);
      return false;
    }

    if (trimmedName.length < 3) {
      _showMessage('Nama minimal 3 karakter.', error: true);
      return false;
    }

    if (trimmedEmail.isEmpty) {
      _showMessage('Email wajib diisi.', error: true);
      return false;
    }

    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$')
        .hasMatch(trimmedEmail)) {
      _showMessage('Format email tidak valid.', error: true);
      return false;
    }

    if (trimmedPhone.isNotEmpty) {
      if (!RegExp(r'^[0-9]+$').hasMatch(trimmedPhone)) {
        _showMessage(
          'Nomor HP hanya boleh berisi angka.',
          error: true,
        );
        return false;
      }

      if (trimmedPhone.length < 10 ||
          trimmedPhone.length > 15) {
        _showMessage(
          'Nomor HP harus 10-15 digit.',
          error: true,
        );
        return false;
      }
    }

    if (trimmedAddress.isNotEmpty &&
        trimmedAddress.length < 5) {
      _showMessage(
        'Alamat minimal 5 karakter.',
        error: true,
      );
      return false;
    }

    if (trimmedBankAccountNumber.isNotEmpty &&
        trimmedBankAccountNumber.length < 5) {
      _showMessage(
        'Nomor rekening minimal 5 digit.',
        error: true,
      );
      return false;
    }

    if (newCityId == null) {
      _showMessage(
        'Kota domisili wajib dipilih.',
        error: true,
      );
      return false;
    }

    try {
      final response = await ApiService.put(
        '/user/profile',
        {
          'name': trimmedName,
          'email': trimmedEmail,
          'phone': trimmedPhone,
          'address': trimmedAddress,
          'bank_name': trimmedBankName,
          'bank_account_number': trimmedBankAccountNumber,
          'bank_account_name': trimmedBankAccountName,
          'city_id': newCityId,
        },
      );

      if (response.statusCode == 200) {
        await loadProfileFromApi();

        if (!mounted) return true;

        widget.onProfileUpdate();

        _showMessage('Profil berhasil diperbarui.');

        return true;
      }

      String message = 'Gagal memperbarui profil.';

      try {
        final data = jsonDecode(response.body);
        message = data['message']?.toString() ?? message;

        if (data['errors'] is Map) {
          final errors = data['errors'] as Map;

          if (errors.isNotEmpty) {
            final firstKey = errors.keys.first;
            final firstError = errors[firstKey];

            if (firstError is List && firstError.isNotEmpty) {
              message = firstError.first.toString();
            }
          }
        }
      } catch (_) {}

      _showMessage(message, error: true);
      return false;
    } catch (e) {
      debugPrint('Update profile error: $e');

      _showMessage(
        'Terjadi kesalahan saat memperbarui profil.',
        error: true,
      );

      return false;
    }
  }

  // =========================================================
  // UPDATE NOTIFICATION
  // =========================================================

  Future<void> updateNotificationStatus(bool value) async {
    try {
      final response = await ApiService.put(
        '/user/notification-setting',
        {
          'is_notification_enabled': value ? 1 : 0,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal memperbarui notifikasi.');
      }
    } catch (e) {
      debugPrint('Error update notification: $e');
    }
  }

  // =========================================================
  // SET PIN DIALOG
  // =========================================================

  void _showSetPinDialog() {
    final oldPinController = TextEditingController();
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();

    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          18,
                          12,
                          14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _primaryColor.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _hasPin
                                    ? Icons.lock_reset
                                    : Icons.lock_outline,
                                color: _primaryColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _hasPin
                                    ? 'Ubah PIN Keamanan'
                                    : 'Buat PIN Keamanan',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.grey900,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: isSaving
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              icon: const Icon(
                                Icons.close,
                                size: 20,
                                color: AppColors.grey500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                        height: 1,
                        color: Color(0xFFE5E7EB),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'PIN 6 digit digunakan untuk mengonfirmasi setiap transaksi (seperti membuat Job).',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              if (_hasPin) ...[
                                _buildPinField(
                                  controller: oldPinController,
                                  label: 'PIN Lama',
                                  icon: Icons.lock_clock,
                                  enabled: !isSaving,
                                ),
                                const SizedBox(height: 12),
                              ],
                              _buildPinField(
                                controller: pinController,
                                label: 'PIN Baru (6 digit)',
                                icon: Icons.lock_outline,
                                enabled: !isSaving,
                              ),
                              const SizedBox(height: 12),
                              _buildPinField(
                                controller: confirmPinController,
                                label: 'Konfirmasi PIN Baru',
                                icon: Icons.check_circle_outline,
                                enabled: !isSaving,
                              ),
                              if (_hasPin) ...[
                                const SizedBox(height: 12),
                                const Text(
                                  'Lupa PIN? Silakan buat pengaduan di menu "Pengaduan" agar Admin dapat mereset PIN Anda.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.redAccent,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const Divider(
                        height: 1,
                        color: Color(0xFFE5E7EB),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isSaving
                                    ? null
                                    : () => Navigator.pop(dialogContext),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 46),
                                  foregroundColor: AppColors.grey700,
                                  side: const BorderSide(
                                    color: Color(0xFFD1D5DB),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Batal'),
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
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        if (_hasPin &&
                                            oldPinController.text.length != 6) {
                                          _showMessage(
                                            'PIN lama harus 6 digit.',
                                            error: true,
                                          );
                                          return;
                                        }

                                        if (pinController.text.length != 6) {
                                          _showMessage(
                                            'PIN baru harus 6 digit.',
                                            error: true,
                                          );
                                          return;
                                        }

                                        if (pinController.text !=
                                            confirmPinController.text) {
                                          _showMessage(
                                            'Konfirmasi PIN baru tidak cocok.',
                                            error: true,
                                          );
                                          return;
                                        }

                                        setDialogState(
                                          () => isSaving = true,
                                        );

                                        try {
                                          final response =
                                              await ApiService.post(
                                            '/user/set-pin',
                                            {
                                              'pin': pinController.text,
                                              if (_hasPin)
                                                'old_pin':
                                                    oldPinController.text,
                                            },
                                          );

                                          final data =
                                              jsonDecode(response.body);

                                          if (response.statusCode == 200 &&
                                              data['success'] == true) {
                                            if (!mounted) return;

                                            Navigator.pop(dialogContext);

                                            _showMessage(
                                              data['message']?.toString() ??
                                                  'PIN berhasil disimpan.',
                                            );

                                            await loadProfileFromApi();
                                          } else {
                                            setDialogState(
                                              () => isSaving = false,
                                            );

                                            _showMessage(
                                              data['message']?.toString() ??
                                                  'Gagal menyimpan PIN.',
                                              error: true,
                                            );
                                          }
                                        } catch (e) {
                                          setDialogState(
                                            () => isSaving = false,
                                          );

                                          _showMessage(
                                            'Terjadi kesalahan saat menyimpan PIN.',
                                            error: true,
                                          );
                                        }
                                      },
                                child: isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Simpan PIN',
                                        style: TextStyle(
                                          fontSize: _buttonFontSize,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
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
      },
    ).then((_) {
      oldPinController.dispose();
      pinController.dispose();
      confirmPinController.dispose();
    });
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
            style: const TextStyle(fontSize: 13),
          ),
          backgroundColor:
              error ? Colors.red : AppColors.primaryTeal,
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

    return Scaffold(
      backgroundColor: AppColors.sectionAltLight,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < _mobileBreakpoint;
          final isTablet =
              width >= _mobileBreakpoint &&
              width < _tabletBreakpoint;

          final horizontalPadding = isMobile
              ? 16.0
              : (isTablet ? 24.0 : 28.0);

          final verticalPadding = isMobile ? 16.0 : 28.0;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: _gapAfterHeader),
                if (isMobile)
                  _buildMobileLayout()
                else
                  _buildWebLayout(),
              ],
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pengaturan',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.grey900,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Kelola profil, notifikasi, dan keamanan akun.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.grey500,
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
        const SizedBox(height: _gapBetweenSections),

        _sectionTitle('Informasi Akun'),
        const SizedBox(height: _gapTitleToContent),

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
        _buildInfoCard(
          icon: Icons.location_city_outlined,
          title: 'Kota Domisili',
          subtitle: cityName.isEmpty ? '-' : cityName,
        ),

        const SizedBox(height: _gapBetweenSections),
        _sectionTitle('Notifikasi'),
        const SizedBox(height: _gapTitleToContent),
        _buildNotificationCard(isMobile: true),

        const SizedBox(height: _gapBetweenSections),
        _sectionTitle('Keamanan'),
        const SizedBox(height: _gapTitleToContent),
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
              const SizedBox(height: _gapBetweenSections),

              _sectionTitle('Informasi Akun'),
              const SizedBox(height: _gapTitleToContent),

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
              _buildInfoCard(
                icon: Icons.location_city_outlined,
                title: 'Kota Domisili',
                subtitle: cityName.isEmpty ? '-' : cityName,
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
              const SizedBox(height: _gapTitleToContent),
              _buildNotificationCard(isMobile: false),

              const SizedBox(height: _gapBetweenSections),
              _sectionTitle('Keamanan'),
              const SizedBox(height: _gapTitleToContent),
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
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.grey900,
      ),
    );
  }

  // =========================================================
  // PROFILE HEADER
  // =========================================================

  Widget _buildProfileHeader({
    required bool isMobile,
  }) {
    final fullPhotoUrl = getFullPhotoUrl();

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.10),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.grey600,
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
                        color: AppColors.grey500,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.grey600,
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
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.grey600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (phone.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: AppColors.grey500,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            phone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.grey600,
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
  // AVATAR
  // =========================================================

  Widget _buildAvatar(
    String? fullPhotoUrl, {
    required double radius,
  }) {
    final size = radius * 2;

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: () {
                if (selectedPhotoBytes != null) {
                  _showImageDialog(
                    context,
                    MemoryImage(selectedPhotoBytes!),
                  );
                } else if (fullPhotoUrl != null) {
                  _showImageDialog(
                    context,
                    NetworkImage(fullPhotoUrl),
                  );
                }
              },
              child: CircleAvatar(
                radius: radius,
                backgroundColor:
                    AppColors.mint.withValues(alpha: 0.25),
                backgroundImage: selectedPhotoBytes != null
                    ? MemoryImage(selectedPhotoBytes!)
                    : fullPhotoUrl != null
                        ? NetworkImage(fullPhotoUrl)
                        : null,
                child: selectedPhotoBytes == null &&
                        fullPhotoUrl == null
                    ? Icon(
                        Icons.person,
                        size: radius * 1.05,
                        color: _primaryColor,
                      )
                    : null,
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Material(
                color: _primaryColor,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  onTap: isUploadingPhoto
                      ? null
                      : pickProfilePhoto,
                  customBorder: const CircleBorder(),
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
      icon: const Icon(Icons.edit, size: 18),
      label: const Text(
        'Edit Profil',
        style: TextStyle(
          fontSize: _buttonFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        minimumSize: const Size(0, 48),
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: _primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.grey400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey900,
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

  Widget _buildNotificationCard({
    required bool isMobile,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.12),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isMobile
                      ? 'Terima notifikasi ketika mitra mengirim penawaran.'
                      : 'Terima notifikasi ketika mitra mengirim penawaran pada pekerjaan Anda.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: jobNotification,
            activeThumbColor: _primaryColor,
            onChanged: (value) async {
              final previousValue = jobNotification;

              setState(() => jobNotification = value);

              await updateNotificationStatus(value);

              if (!mounted) return;

              _showMessage(
                value
                    ? 'Notifikasi penawaran diaktifkan.'
                    : 'Notifikasi penawaran dinonaktifkan.',
              );

              // Catatan: endpoint saat ini tidak mengembalikan
              // status kegagalan secara eksplisit ke UI.
              // Jika ingin rollback otomatis, periksa status
              // response di updateNotificationStatus().
              if (previousValue == value) return;
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(_cardRadius),
                topRight: Radius.circular(_cardRadius),
              ),
              onTap: _showSetPinDialog,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        _hasPin
                            ? Icons.lock_reset
                            : Icons.lock_outline,
                        color: _primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _hasPin
                                ? 'Ubah PIN Keamanan'
                                : 'Atur PIN Keamanan',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.grey900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _hasPin
                                ? 'PIN sudah aktif. Anda bisa mengubahnya.'
                                : 'Buat PIN untuk konfirmasi transaksi.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 22,
                      color: AppColors.grey400,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(
            height: 1,
            color: Color(0xFFE5E7EB),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(_cardRadius),
              bottomRight: Radius.circular(_cardRadius),
            ),
            child: InkWell(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(_cardRadius),
                bottomRight: Radius.circular(_cardRadius),
              ),
              onTap: _showLogoutDialog,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.logout,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Keluar dari Akun',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Keluar dari akun SayaBantu.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 22,
                      color: AppColors.grey400,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // EDIT PROFILE DIALOG
  // =========================================================

  void _showEditProfileDialog(String? fullPhotoUrl) {
    final nameController = TextEditingController(text: name);
    final emailController = TextEditingController(text: email);
    final phoneController = TextEditingController(text: phone);
    final addressController = TextEditingController(text: address);

    final bankNameController =
        TextEditingController(text: bankName);
    final bankAccountNumberController =
        TextEditingController(text: bankAccountNumber);
    final bankAccountNameController =
        TextEditingController(text: bankAccountName);

    int? selectedCityId = cityId;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // HEADER
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          18,
                          12,
                          14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _primaryColor.withValues(
                                  alpha: 0.12,
                                ),
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
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.grey900,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: isSaving
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              icon: const Icon(
                                Icons.close,
                                size: 20,
                                color: AppColors.grey500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(
                        height: 1,
                        color: Color(0xFFE5E7EB),
                      ),

                      // BODY
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // FOTO PROFIL
                              Center(
                                child: GestureDetector(
                                  onTap: () {
                                    if (selectedPhotoBytes != null) {
                                      _showImageDialog(
                                        dialogContext,
                                        MemoryImage(
                                          selectedPhotoBytes!,
                                        ),
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
                                          backgroundColor: AppColors.mint
                                              .withValues(alpha: 0.25),
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
                                              onTap: isSaving
                                                  ? null
                                                  : () async {
                                                      Navigator.pop(
                                                        dialogContext,
                                                      );
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
                                  fontSize: 11,
                                  color: AppColors.grey400,
                                ),
                              ),

                              const SizedBox(height: 20),

                              _buildEditField(
                                controller: nameController,
                                label: 'Nama',
                                icon: Icons.person_outline,
                                maxLength: 100,
                                inputFormatters: nameFormatters,
                                textCapitalization:
                                    TextCapitalization.words,
                                enabled: !isSaving,
                              ),

                              const SizedBox(height: 12),

                              _buildEditField(
                                controller: emailController,
                                label: 'Email',
                                icon: Icons.email_outlined,
                                maxLength: 100,
                                keyboardType:
                                    TextInputType.emailAddress,
                                enabled: !isSaving,
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
                                enabled: !isSaving,
                              ),

                              const SizedBox(height: 12),

                              _buildEditField(
                                controller: addressController,
                                label: 'Alamat',
                                icon: Icons.location_on_outlined,
                                maxLength: 500,
                                maxLines: 3,
                                alignLabelWithHint: true,
                                enabled: !isSaving,
                              ),

                              const SizedBox(height: 12),

                              // DROPDOWN KOTA
                              DropdownButtonFormField<int>(
                                value: cities.any(
                                  (city) =>
                                      city['id'] == selectedCityId,
                                )
                                    ? selectedCityId
                                    : null,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Kota Domisili',
                                  prefixIcon: const Icon(
                                    Icons.location_city_outlined,
                                    size: 19,
                                  ),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: _borderColor,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: _primaryColor,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                hint: Text(
                                  isLoadingCities
                                      ? 'Memuat daftar kota...'
                                      : cities.isEmpty
                                          ? 'Daftar kota tidak tersedia'
                                          : 'Pilih kota domisili',
                                  style: const TextStyle(
                                    fontSize: _bodyFontSize,
                                  ),
                                ),
                                items: cities.map((city) {
                                  return DropdownMenuItem<int>(
                                    value: city['id'] as int,
                                    child: Text(
                                      city['name'].toString(),
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: _bodyFontSize,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: isSaving ||
                                        isLoadingCities ||
                                        cities.isEmpty
                                    ? null
                                    : (value) {
                                        setDialogState(() {
                                          selectedCityId = value;
                                        });
                                      },
                              ),

                              if (!isLoadingCities && cities.isEmpty) ...[
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      await loadCities();
                                      if (!mounted) return;
                                      setDialogState(() {});
                                    },
                                    icon: const Icon(
                                      Icons.refresh,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Muat ulang daftar kota',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 12),

                              _buildEditField(
                                controller: bankNameController,
                                label: 'Nama Bank (Contoh: BCA)',
                                icon: Icons.account_balance_outlined,
                                maxLength: 100,
                                enabled: !isSaving,
                              ),

                              const SizedBox(height: 12),

                              _buildEditField(
                                controller: bankAccountNumberController,
                                label: 'Nomor Rekening',
                                icon: Icons.numbers,
                                maxLength: 50,
                                keyboardType: TextInputType.number,
                                inputFormatters: digitsOnly,
                                enabled: !isSaving,
                              ),

                              const SizedBox(height: 12),

                              _buildEditField(
                                controller: bankAccountNameController,
                                label: 'Nama Pemilik Rekening',
                                icon: Icons.person_outline,
                                maxLength: 100,
                                enabled: !isSaving,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Divider(
                        height: 1,
                        color: Color(0xFFE5E7EB),
                      ),

                      // ACTIONS
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isSaving
                                    ? null
                                    : () => Navigator.pop(dialogContext),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 46),
                                  foregroundColor: AppColors.grey700,
                                  side: const BorderSide(
                                    color: Color(0xFFD1D5DB),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
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
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        if (selectedCityId == null) {
                                          _showMessage(
                                            'Kota domisili wajib dipilih.',
                                            error: true,
                                          );
                                          return;
                                        }

                                        setDialogState(
                                          () => isSaving = true,
                                        );

                                        final success =
                                            await updateProfileToApi(
                                          newName: nameController.text,
                                          newEmail: emailController.text,
                                          newPhone: phoneController.text,
                                          newAddress:
                                              addressController.text,
                                          newBankName:
                                              bankNameController.text,
                                          newBankAccountNumber:
                                              bankAccountNumberController
                                                  .text,
                                          newBankAccountName:
                                              bankAccountNameController
                                                  .text,
                                          newCityId: selectedCityId,
                                        );

                                        if (!dialogContext.mounted) {
                                          return;
                                        }

                                        if (success) {
                                          Navigator.pop(dialogContext);
                                        } else {
                                          setDialogState(
                                            () => isSaving = false,
                                          );
                                        }
                                      },
                                child: isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
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
      },
    ).then((_) {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      addressController.dispose();
      bankNameController.dispose();
      bankAccountNumberController.dispose();
      bankAccountNameController.dispose();
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
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
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
          borderSide: const BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: _primaryColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // PIN FIELD
  // =========================================================

  Widget _buildPinField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: true,
      keyboardType: TextInputType.number,
      inputFormatters: digitsOnly,
      maxLength: 6,
      style: const TextStyle(fontSize: _bodyFontSize),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19),
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
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
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.grey900,
            ),
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari akun ini?',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.grey700,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey600,
                ),
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
              onPressed: () async {
                AuthStorage.clear();

                if (!mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LandingPage(),
                  ),
                  (route) => false,
                );
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
