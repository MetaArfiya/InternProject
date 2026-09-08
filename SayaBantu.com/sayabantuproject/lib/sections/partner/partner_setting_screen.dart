import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';

class PartnerSettingScreen extends StatefulWidget {
  final VoidCallback onProfileUpdate;

  const PartnerSettingScreen({
    super.key,
    required this.onProfileUpdate,
  });

  @override
  State<PartnerSettingScreen> createState() =>
      _PartnerSettingScreenState();
}

class _PartnerSettingScreenState extends State<PartnerSettingScreen> {
  // ============================================================
  // BASIC PROFILE
  // ============================================================

  bool isLoading = true;
  bool isUploadingPhoto = false;
  bool jobNotification = true;

  String name = '';
  String email = '';
  String phone = '';
  String address = '';
  String photoUrl = '';

  Uint8List? selectedPhotoBytes;
  String? selectedPhotoName;

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController addressController =
      TextEditingController();

  // ============================================================
  // IDENTITAS MITRA
  // ============================================================

  String gender = '';
  String birthDate = '';
  String city = '';
  String description = '';

  final TextEditingController fullNameController =
      TextEditingController();

  final TextEditingController cityController =
      TextEditingController();

  final TextEditingController descriptionController =
      TextEditingController();

  final TextEditingController birthDateController =
      TextEditingController();

  // ============================================================
  // VERIFIKASI
  // ============================================================

  Uint8List? ktpBytes;
  String? ktpFileName;

  Uint8List? selfieBytes;
  String? selfieFileName;

  String verificationStatus = 'Belum Diverifikasi';

  // ============================================================
  // KEAHLIAN
  // ============================================================

  String selectedCategory = '';

  final List<String> categories = [
    'Service AC',
    'Plumbing',
    'Listrik',
    'Cat Rumah',
    'Kebersihan',
    'Pertukangan',
    'Tukang Kebun',
    'Lainnya',
  ];

  final List<Uint8List> skillPhotoBytes = [];
  final List<String> skillPhotoNames = [];

  // ============================================================
  // DATA MITRA
  // ============================================================

  int totalPoint = 0;
  bool isVerified = false;

  // ============================================================
  // PASSWORD
  // ============================================================

  final TextEditingController currentPasswordController =
      TextEditingController();

  final TextEditingController newPasswordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool obscureCurrentPassword = true;
  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    loadProfileFromApi();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();

    fullNameController.dispose();
    cityController.dispose();
    descriptionController.dispose();
    birthDateController.dispose();

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> loadProfileFromApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final localName = prefs.getString('name') ?? '';
      final localEmail = prefs.getString('email') ?? '';
      final localPhone = prefs.getString('phone') ?? '';
      final localAddress = prefs.getString('address') ?? '';

      final localNotification =
          prefs.getBool('job_notification');

      if (mounted) {
        setState(() {
          name = localName;
          email = localEmail;
          phone = localPhone;
          address = localAddress;

          nameController.text = localName;
          emailController.text = localEmail;
          phoneController.text = localPhone;
          addressController.text = localAddress;

          if (localNotification != null) {
            jobNotification = localNotification;
          }
        });
      }

      // ==========================================================
      // USER
      // ==========================================================

      final userResponse = await ApiService.get('/user');

      if (userResponse.statusCode == 200) {
        final data = jsonDecode(userResponse.body);
        final user = data['user'] ?? data;

        if (user is Map) {
          final loadedName =
              user['name']?.toString() ?? name;

          final loadedEmail =
              user['email']?.toString() ?? email;

          final loadedPhone =
              user['phone']?.toString() ?? phone;

          final loadedAddress =
              user['address']?.toString() ?? address;

          if (mounted) {
            setState(() {
              name = loadedName;
              email = loadedEmail;
              phone = loadedPhone;
              address = loadedAddress;

              nameController.text = loadedName;
              emailController.text = loadedEmail;
              phoneController.text = loadedPhone;
              addressController.text = loadedAddress;
            });
          }

          await prefs.setString('name', loadedName);
          await prefs.setString('email', loadedEmail);
          await prefs.setString('phone', loadedPhone);
          await prefs.setString('address', loadedAddress);
        }
      }

      // ==========================================================
      // MITRA PROFILE
      // ==========================================================

      try {
        final mitraResponse =
            await ApiService.get('/mitra/profile');

        if (mitraResponse.statusCode == 200) {
          final mitraData =
              jsonDecode(mitraResponse.body);

          final mitra =
              mitraData['mitra'] ??
              mitraData['data'] ??
              mitraData;

          if (mitra is Map && mounted) {
            setState(() {
              gender =
                  mitra['gender']?.toString() ?? '';

              birthDate =
                  mitra['birth_date']?.toString() ??
                  mitra['birthDate']?.toString() ??
                  '';

              city =
                  mitra['city']?.toString() ?? '';

              description =
                  mitra['description']?.toString() ??
                  mitra['bio']?.toString() ??
                  '';

              selectedCategory =
                  mitra['category']?.toString() ??
                  mitra['skill_category']?.toString() ??
                  '';

              verificationStatus =
                  mitra['verification_status']?.toString() ??
                  'Belum Diverifikasi';

              isVerified =
                  mitra['is_verified'] == true ||
                  mitra['is_verified'] == 1 ||
                  mitra['is_verified']
                          ?.toString()
                          .toLowerCase() ==
                      'true';

              totalPoint =
                  int.tryParse(
                        mitra['total_point']
                                ?.toString() ??
                            '0',
                      ) ??
                      0;

              fullNameController.text =
                  mitra['full_name']?.toString() ??
                  name;

              cityController.text = city;
              descriptionController.text = description;
              birthDateController.text = birthDate;
            });
          }
        }
      } catch (_) {}

      // ==========================================================
      // PROFILE PHOTO
      // ==========================================================

      final localPhoto =
          prefs.getString('profile_image_url');

      if (localPhoto != null &&
          localPhoto.isNotEmpty &&
          mounted) {
        setState(() {
          photoUrl = localPhoto;
        });
      }

      // ==========================================================
      // LOCAL IDENTITY DATA
      // ==========================================================

      final localFullName =
          prefs.getString('mitra_full_name');

      final localGender =
          prefs.getString('mitra_gender');

      final localBirthDate =
          prefs.getString('mitra_birth_date');

      final localCity =
          prefs.getString('mitra_city');

      final localDescription =
          prefs.getString('mitra_description');

      final localCategory =
          prefs.getString('mitra_category');

      final localVerification =
          prefs.getString('verification_status');

      if (mounted) {
        setState(() {
          if (localFullName != null &&
              localFullName.isNotEmpty) {
            fullNameController.text =
                localFullName;
          }

          if (localGender != null &&
              localGender.isNotEmpty) {
            gender = localGender;
          }

          if (localBirthDate != null &&
              localBirthDate.isNotEmpty) {
            birthDate = localBirthDate;
            birthDateController.text =
                localBirthDate;
          }

          if (localCity != null &&
              localCity.isNotEmpty) {
            city = localCity;
            cityController.text =
                localCity;
          }

          if (localDescription != null &&
              localDescription.isNotEmpty) {
            description = localDescription;
            descriptionController.text =
                localDescription;
          }

          if (localCategory != null &&
              localCategory.isNotEmpty) {
            selectedCategory = localCategory;
          }

          if (localVerification != null &&
              localVerification.isNotEmpty) {
            verificationStatus = localVerification;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Gagal memuat data profil: $e',
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // SAVE BASIC PROFILE
  // ============================================================

  Future<void> saveBasicProfile() async {
    final newName =
        nameController.text.trim();

    final newPhone =
        phoneController.text.trim();

    final newAddress =
        addressController.text.trim();

    if (newName.isEmpty) {
      _showMessage(
        'Nama lengkap wajib diisi.',
        error: true,
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final response = await ApiService.put(
        '/user/profile',
        {
          'name': newName,
          'phone': newPhone,
          'address': newAddress,
        },
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        final prefs =
            await SharedPreferences.getInstance();

        await prefs.setString(
          'name',
          newName,
        );

        await prefs.setString(
          'phone',
          newPhone,
        );

        await prefs.setString(
          'address',
          newAddress,
        );

        if (mounted) {
          setState(() {
            name = newName;
            phone = newPhone;
            address = newAddress;
          });
        }

        widget.onProfileUpdate();

        _showMessage(
          'Profil berhasil diperbarui.',
        );
      } else {
        String message =
            'Gagal memperbarui profil.';

        try {
          final data =
              jsonDecode(response.body);

          message =
              data['message']?.toString() ??
              message;
        } catch (_) {}

        _showMessage(
          message,
          error: true,
        );
      }
    } catch (e) {
      _showMessage(
        'Terjadi kesalahan: $e',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // PROFILE PHOTO
  // ============================================================

  Future<void> pickProfilePhoto() async {
    final image =
        await _pickImageFile();

    if (image == null) return;

    if (mounted) {
      setState(() {
        selectedPhotoBytes = image.bytes;
        selectedPhotoName = image.name;
      });
    }

    await uploadProfilePhoto(
      image.bytes,
      image.name,
    );
  }

  Future<void> uploadProfilePhoto(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      setState(() {
        isUploadingPhoto = true;
      });

      final request = html.HttpRequest();
      final formData = html.FormData();

      final blob = html.Blob(
        [bytes],
        'image/jpeg',
      );

      formData.appendBlob(
        'photo',
        blob,
        fileName,
      );

      request.open(
        'POST',
        'http://127.0.0.1:8000/api/user/profile/photo',
      );

      final prefs =
          await SharedPreferences.getInstance();

      final token =
          prefs.getString('token');

      if (token != null &&
          token.isNotEmpty) {
        request.setRequestHeader(
          'Authorization',
          'Bearer $token',
        );
      }

      final completer = Completer<bool>();

      request.onLoad.listen((_) {
        if (!completer.isCompleted) {
          completer.complete(
            request.status == 200 ||
                request.status == 201,
          );
        }
      });

      request.onError.listen((_) {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });

      request.send(formData);

      final success =
          await completer.future;

      if (success) {
        try {
          final responseData =
              jsonDecode(
            request.responseText ?? '',
          );

          final returnedUrl =
              responseData['photo_url'] ??
              responseData['url'] ??
              responseData['photo'];

          if (returnedUrl != null) {
            final url =
                returnedUrl.toString();

            if (mounted) {
              setState(() {
                photoUrl = url;
              });
            }

            await prefs.setString(
              'profile_image_url',
              url,
            );
          }
        } catch (_) {}

        widget.onProfileUpdate();

        _showMessage(
          'Foto profil berhasil diperbarui.',
        );
      } else {
        _showMessage(
          'Gagal mengunggah foto profil.',
          error: true,
        );
      }
    } catch (e) {
      _showMessage(
        'Gagal mengunggah foto: $e',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isUploadingPhoto = false;
        });
      }
    }
  }

  // ============================================================
  // IDENTITAS MITRA
  // ============================================================

  Future<void> saveIdentity() async {
    final fullName =
        fullNameController.text.trim();

    final selectedCity =
        cityController.text.trim();

    final selectedDescription =
        descriptionController.text.trim();

    final selectedAddress =
        addressController.text.trim();

    if (fullName.isEmpty) {
      _showMessage(
        'Nama lengkap wajib diisi.',
        error: true,
      );
      return;
    }

    if (gender.isEmpty) {
      _showMessage(
        'Silakan pilih jenis kelamin.',
        error: true,
      );
      return;
    }

    if (birthDate.isEmpty) {
      _showMessage(
        'Silakan pilih tanggal lahir.',
        error: true,
      );
      return;
    }

    if (selectedCity.isEmpty) {
      _showMessage(
        'Kota/Kabupaten wajib diisi.',
        error: true,
      );
      return;
    }

    if (selectedAddress.isEmpty) {
      _showMessage(
        'Alamat lengkap wajib diisi.',
        error: true,
      );
      return;
    }

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'mitra_full_name',
      fullName,
    );

    await prefs.setString(
      'mitra_gender',
      gender,
    );

    await prefs.setString(
      'mitra_birth_date',
      birthDate,
    );

    await prefs.setString(
      'mitra_city',
      selectedCity,
    );

    await prefs.setString(
      'mitra_description',
      selectedDescription,
    );

    await prefs.setString(
      'address',
      selectedAddress,
    );

    if (mounted) {
      setState(() {
        name = fullName;
        city = selectedCity;
        description = selectedDescription;
        address = selectedAddress;

        nameController.text = fullName;
        addressController.text = selectedAddress;
      });
    }

    widget.onProfileUpdate();

    _showMessage(
      'Identitas mitra berhasil disimpan.',
    );
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> selectBirthDate() async {
    DateTime initialDate =
        DateTime.now().subtract(
      const Duration(days: 365 * 20),
    );

    if (birthDate.isNotEmpty) {
      try {
        initialDate =
            DateTime.parse(birthDate);
      } catch (_) {}
    }

    final picked =
        await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      helpText: 'Pilih Tanggal Lahir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (picked == null) return;

    final formatted =
        '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';

    if (mounted) {
      setState(() {
        birthDate = formatted;
        birthDateController.text = formatted;
      });
    }
  }

  // ============================================================
  // KTP
  // ============================================================

  Future<void> pickKtp() async {
    final image =
        await _pickImageFile();

    if (image == null) return;

    if (mounted) {
      setState(() {
        ktpBytes = image.bytes;
        ktpFileName = image.name;
      });
    }

    _showMessage(
      'KTP berhasil dipilih.',
    );
  }

  // ============================================================
  // SELFIE
  // ============================================================

  Future<void> pickSelfie() async {
    final image =
        await _pickImageFile(
      capture: 'user',
    );

    if (image == null) return;

    if (mounted) {
      setState(() {
        selfieBytes = image.bytes;
        selfieFileName = image.name;
      });
    }

    _showMessage(
      'Foto verifikasi berhasil dipilih.',
    );
  }

  // ============================================================
  // SUBMIT VERIFICATION
  // ============================================================

  Future<void> submitVerification() async {
    if (ktpBytes == null) {
      _showMessage(
        'Silakan upload foto KTP terlebih dahulu.',
        error: true,
      );
      return;
    }

    if (selfieBytes == null) {
      _showMessage(
        'Silakan upload foto verifikasi diri terlebih dahulu.',
        error: true,
      );
      return;
    }

    if (fullNameController.text.trim().isEmpty) {
      _showMessage(
        'Lengkapi identitas terlebih dahulu.',
        error: true,
      );
      return;
    }

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'verification_status',
      'Menunggu Verifikasi',
    );

    if (mounted) {
      setState(() {
        verificationStatus =
            'Menunggu Verifikasi';
      });
    }

    _showMessage(
      'Data verifikasi berhasil dikirim dan menunggu pemeriksaan admin.',
    );
  }

  // ============================================================
  // SAVE SKILL
  // ============================================================

  Future<void> saveSkill() async {
    if (selectedCategory.isEmpty) {
      _showMessage(
        'Silakan pilih kategori keahlian.',
        error: true,
      );
      return;
    }

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'mitra_category',
      selectedCategory,
    );

    _showMessage(
      'Keahlian berhasil disimpan.',
    );
  }

  // ============================================================
  // SKILL PHOTO
  // ============================================================

  Future<void> pickSkillPhoto() async {
    if (skillPhotoBytes.length >= 6) {
      _showMessage(
        'Maksimal 6 foto keahlian.',
        error: true,
      );
      return;
    }

    final image =
        await _pickImageFile();

    if (image == null) return;

    if (mounted) {
      setState(() {
        skillPhotoBytes.add(image.bytes);
        skillPhotoNames.add(image.name);
      });
    }

    _showMessage(
      'Foto keahlian berhasil ditambahkan.',
    );
  }

  void removeSkillPhoto(int index) {
    if (index < 0 ||
        index >= skillPhotoBytes.length) {
      return;
    }

    setState(() {
      skillPhotoBytes.removeAt(index);
      skillPhotoNames.removeAt(index);
    });
  }

  // ============================================================
  // IMAGE PICKER WEB
  // ============================================================

  Future<_PickedImage?> _pickImageFile({
    String? capture,
  }) async {
    final input =
        html.FileUploadInputElement();

    input.accept = 'image/*';

    if (capture != null) {
      input.setAttribute(
        'capture',
        capture,
      );
    }

    final completer =
        Completer<_PickedImage?>();

    input.onChange.listen((event) {
      final files = input.files;

      if (files == null ||
          files.isEmpty) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
        return;
      }

      final file = files.first;

      if (!file.type.startsWith('image/')) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
        return;
      }

      final reader = html.FileReader();

      reader.readAsArrayBuffer(file);

      reader.onLoadEnd.listen((event) {
        if (reader.result == null) {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
          return;
        }

        final result = reader.result;

        Uint8List bytes;

        if (result is ByteBuffer) {
          bytes = Uint8List.view(result);
        } else if (result is Uint8List) {
          bytes = result;
        } else {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
          return;
        }

        if (!completer.isCompleted) {
          completer.complete(
            _PickedImage(
              bytes: bytes,
              name: file.name,
            ),
          );
        }
      });
    });

    input.click();

    return completer.future;
  }

  // ============================================================
  // NOTIFICATION
  // ============================================================

  Future<void> updateNotification(
    bool value,
  ) async {
    setState(() {
      jobNotification = value;
    });

    try {
      final response =
          await ApiService.put(
        '/user/notification-setting',
        {
          'is_notification_enabled':
              value ? 1 : 0,
        },
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        final prefs =
            await SharedPreferences.getInstance();

        await prefs.setBool(
          'job_notification',
          value,
        );
      }
    } catch (_) {
      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setBool(
        'job_notification',
        value,
      );
    }
  }

  // ============================================================
  // PASSWORD
  // ============================================================

  Future<void> changePassword() async {
    final current =
        currentPasswordController.text.trim();

    final newPassword =
        newPasswordController.text.trim();

    final confirm =
        confirmPasswordController.text.trim();

    if (current.isEmpty ||
        newPassword.isEmpty ||
        confirm.isEmpty) {
      _showMessage(
        'Semua kolom password wajib diisi.',
        error: true,
      );
      return;
    }

    if (newPassword.length < 8) {
      _showMessage(
        'Password baru minimal 8 karakter.',
        error: true,
      );
      return;
    }

    if (newPassword != confirm) {
      _showMessage(
        'Konfirmasi password tidak sesuai.',
        error: true,
      );
      return;
    }

    try {
      final prefs =
          await SharedPreferences.getInstance();

      final savedPassword =
          prefs.getString('password');

      if (savedPassword != null &&
          savedPassword.isNotEmpty &&
          savedPassword != current) {
        _showMessage(
          'Password lama tidak sesuai.',
          error: true,
        );
        return;
      }

      await prefs.setString(
        'password',
        newPassword,
      );

      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      _showMessage(
        'Password berhasil diubah.',
      );
    } catch (e) {
      _showMessage(
        'Gagal mengubah password: $e',
        error: true,
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              error ? Colors.red : Colors.green,
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile =
            constraints.maxWidth < 700;

        return Scaffold(
          backgroundColor:
              const Color(0xffF8FAFC),
          body: SafeArea(
            child: isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(
                      color: Colors.orange,
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 16 : 30,
                      24,
                      isMobile ? 16 : 30,
                      40,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        _buildPageHeader(),

                        const SizedBox(height: 24),

                        _buildProfileHeader(),

                        const SizedBox(height: 24),

                        _buildIdentitySection(),

                        const SizedBox(height: 24),

                        _buildVerificationSection(),

                        const SizedBox(height: 24),

                        _buildSkillSection(),

                        const SizedBox(height: 24),

                        _buildNotificationSection(),

                        const SizedBox(height: 24),

                        _buildSecuritySection(),

                        // =================================================
                        // TIDAK ADA _buildLogoutButton() DI SINI
                        // LOGOUT SEKARANG HANYA DI SIDEBAR
                        // =================================================
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PAGE HEADER
  // ============================================================

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Pengaturan',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xff111827),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kelola profil, identitas, verifikasi, dan pengaturan akun kamu.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _buildProfileHeader() {
    return _sectionCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap:
                    isUploadingPhoto
                        ? null
                        : pickProfilePhoto,
                child: Stack(
                  alignment:
                      Alignment.bottomRight,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration:
                          BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.orange.shade50,
                        border: Border.all(
                          color: Colors.orange.shade200,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child:
                            selectedPhotoBytes != null
                                ? Image.memory(
                                    selectedPhotoBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : photoUrl.isNotEmpty
                                    ? Image.network(
                                        photoUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return const Icon(
                                            Icons.person,
                                            size: 42,
                                            color: Colors.orange,
                                          );
                                        },
                                      )
                                    : const Icon(
                                        Icons.person,
                                        size: 42,
                                        color: Colors.orange,
                                      ),
                      ),
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration:
                          const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child:
                          isUploadingPhoto
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
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Mitra' : name,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      email.isEmpty
                          ? 'Email belum tersedia'
                          : email,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _badge(
                          icon: Icons.stars,
                          label: '$totalPoint Poin',
                          color: Colors.orange,
                        ),
                        _badge(
                          icon:
                              isVerified
                                  ? Icons.verified
                                  : Icons.verified_outlined,
                          label:
                              isVerified
                                  ? 'Terverifikasi'
                                  : 'Belum Terverifikasi',
                          color:
                              isVerified
                                  ? Colors.green
                                  : Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Divider(height: 1),
          const SizedBox(height: 20),
          _profileBasicForm(),
        ],
      ),
    );
  }

  // ============================================================
  // BASIC PROFILE FORM
  // ============================================================

  Widget _profileBasicForm() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Profil Dasar',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumn =
                constraints.maxWidth >= 650;

            if (!twoColumn) {
              return Column(
                children: [
                  _textField(
                    controller: nameController,
                    label: 'Nama Lengkap',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 14),
                  _textField(
                    controller: emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    readOnly: true,
                  ),
                  const SizedBox(height: 14),
                  _textField(
                    controller: phoneController,
                    label: 'Nomor HP',
                    icon: Icons.phone_outlined,
                    keyboardType:
                        TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  _textField(
                    controller: addressController,
                    label: 'Alamat',
                    icon:
                        Icons.location_on_outlined,
                    maxLines: 3,
                  ),
                ],
              );
            }

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        controller:
                            nameController,
                        label: 'Nama Lengkap',
                        icon:
                            Icons.person_outline,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _textField(
                        controller:
                            emailController,
                        label: 'Email',
                        icon:
                            Icons.email_outlined,
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _textField(
                        controller:
                            phoneController,
                        label: 'Nomor HP',
                        icon:
                            Icons.phone_outlined,
                        keyboardType:
                            TextInputType.phone,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _textField(
                        controller:
                            addressController,
                        label: 'Alamat',
                        icon:
                            Icons.location_on_outlined,
                        maxLines: 3,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed:
                isLoading
                    ? null
                    : saveBasicProfile,
            icon: const Icon(
              Icons.save_outlined,
              size: 18,
            ),
            label:
                const Text('Simpan Profil'),
            style:
                ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 13,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // IDENTITAS MITRA
  // ============================================================

  Widget _buildIdentitySection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.badge_outlined,
            title: 'Identitas Mitra',
            subtitle:
                'Lengkapi data identitas agar pelanggan dapat mengenal kamu.',
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumn =
                  constraints.maxWidth >= 650;

              if (!twoColumn) {
                return Column(
                  children: [
                    _textField(
                      controller:
                          fullNameController,
                      label: 'Nama Lengkap',
                      icon:
                          Icons.person_outline,
                    ),
                    const SizedBox(height: 14),
                    _genderDropdown(),
                    const SizedBox(height: 14),
                    _birthDateField(),
                    const SizedBox(height: 14),
                    _textField(
                      controller:
                          cityController,
                      label: 'Kota/Kabupaten',
                      icon: Icons.location_city_outlined,
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _textField(
                          controller:
                              fullNameController,
                          label: 'Nama Lengkap',
                          icon:
                              Icons.person_outline,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child:
                            _genderDropdown(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child:
                            _birthDateField(),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _textField(
                          controller:
                              cityController,
                          label: 'Kota/Kabupaten',
                          icon:
                              Icons.location_city_outlined,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          _textField(
            controller: addressController,
            label: 'Alamat Lengkap',
            icon: Icons.home_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          _textField(
            controller:
                descriptionController,
            label:
                'Deskripsi Singkat Tentang Diri',
            icon:
                Icons.description_outlined,
            maxLines: 5,
            hintText:
                'Ceritakan pengalaman, kemampuan, dan keunggulan kamu sebagai mitra.',
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: saveIdentity,
              icon: const Icon(
                Icons.save_outlined,
                size: 18,
              ),
              label:
                  const Text('Simpan Identitas'),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GENDER
  // ============================================================

  Widget _genderDropdown() {
    return DropdownButtonFormField<String>(
      value:
          gender.isEmpty ? null : gender,
      decoration: _inputDecoration(
        label: 'Jenis Kelamin',
        icon: Icons.wc_outlined,
      ),
      hint:
          const Text(
        'Pilih jenis kelamin',
      ),
      items: const [
        DropdownMenuItem(
          value: 'Laki-laki',
          child: Text('Laki-laki'),
        ),
        DropdownMenuItem(
          value: 'Perempuan',
          child: Text('Perempuan'),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          gender = value;
        });
      },
    );
  }

  // ============================================================
  // DATE FIELD
  // ============================================================

  Widget _birthDateField() {
    return TextField(
      controller: birthDateController,
      readOnly: true,
      onTap: selectBirthDate,
      decoration:
          _inputDecoration(
        label: 'Tanggal Lahir',
        icon:
            Icons.calendar_month_outlined,
      ).copyWith(
        suffixIcon: const Icon(
          Icons.calendar_today_outlined,
          size: 20,
        ),
      ),
    );
  }

  // ============================================================
  // VERIFICATION
  // ============================================================

  Widget _buildVerificationSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon:
                Icons.verified_user_outlined,
            title:
                'Verifikasi Mitra',
            subtitle:
                'Upload dokumen untuk memverifikasi identitas kamu.',
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumn =
                  constraints.maxWidth >= 650;

              if (!twoColumn) {
                return Column(
                  children: [
                    _documentUploadCard(
                      title: 'KTP / Identitas',
                      description:
                          'Upload foto KTP yang jelas dan dapat dibaca.',
                      bytes: ktpBytes,
                      fileName: ktpFileName,
                      icon:
                          Icons.credit_card_outlined,
                      onTap: pickKtp,
                    ),
                    const SizedBox(height: 16),
                    _documentUploadCard(
                      title:
                          'Foto Verifikasi Diri',
                      description:
                          'Gunakan foto wajah yang jelas untuk verifikasi.',
                      bytes: selfieBytes,
                      fileName: selfieFileName,
                      icon:
                          Icons.camera_front_outlined,
                      onTap: pickSelfie,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child:
                        _documentUploadCard(
                      title: 'KTP / Identitas',
                      description:
                          'Upload foto KTP yang jelas dan dapat dibaca.',
                      bytes: ktpBytes,
                      fileName: ktpFileName,
                      icon:
                          Icons.credit_card_outlined,
                      onTap: pickKtp,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child:
                        _documentUploadCard(
                      title:
                          'Foto Verifikasi Diri',
                      description:
                          'Gunakan foto wajah yang jelas untuk verifikasi.',
                      bytes: selfieBytes,
                      fileName: selfieFileName,
                      icon:
                          Icons.camera_front_outlined,
                      onTap: pickSelfie,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          _verificationStatusCard(),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed:
                  verificationStatus ==
                          'Menunggu Verifikasi'
                      ? null
                      : submitVerification,
              icon: const Icon(
                Icons.send_outlined,
                size: 18,
              ),
              label: const Text(
                'Kirim Untuk Verifikasi',
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DOCUMENT CARD
  // ============================================================

  Widget _documentUploadCard({
    required String title,
    required String description,
    required Uint8List? bytes,
    required String? fileName,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xffE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.orange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 14),
          if (bytes != null) ...[
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(10),
              child: Image.memory(
                bytes,
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              fileName ?? 'File dipilih',
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(
                bytes == null
                    ? Icons.cloud_upload_outlined
                    : Icons.refresh_outlined,
                size: 18,
              ),
              label: Text(
                bytes == null
                    ? 'Pilih Foto'
                    : 'Ganti Foto',
              ),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    Colors.orange,
                side:
                    const BorderSide(
                  color: Colors.orange,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VERIFICATION STATUS
  // ============================================================

  Widget _verificationStatusCard() {
    final waiting =
        verificationStatus ==
            'Menunggu Verifikasi';

    final verified =
        verificationStatus ==
            'Terverifikasi';

    final statusColor =
        verified
            ? Colors.green
            : waiting
                ? Colors.orange
                : Colors.grey;

    final statusIcon =
        verified
            ? Icons.verified
            : waiting
                ? Icons.hourglass_top
                : Icons.info_outline;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color:
            statusColor.withValues(alpha: 0.08),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color:
              statusColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Verifikasi',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  verificationStatus,
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SKILL
  // ============================================================

  Widget _buildSkillSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon:
                Icons.handyman_outlined,
            title:
                'Keahlian Mitra',
            subtitle:
                'Tambahkan kategori keahlian dan foto hasil pekerjaan kamu.',
          ),
          const SizedBox(height: 22),
          DropdownButtonFormField<String>(
            value:
                selectedCategory.isEmpty
                    ? null
                    : selectedCategory,
            decoration:
                _inputDecoration(
              label:
                  'Kategori Keahlian',
              icon:
                  Icons.category_outlined,
            ),
            hint: const Text(
              'Pilih kategori keahlian',
            ),
            items: categories
                .map(
                  (category) =>
                      DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                selectedCategory = value;
              });
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Foto Keahlian / Hasil Pekerjaan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Tambahkan foto hasil pekerjaan untuk meningkatkan kepercayaan pelanggan.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 15),
          if (skillPhotoBytes.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                int columns = 3;

                if (constraints.maxWidth < 500) {
                  columns = 2;
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  itemCount:
                      skillPhotoBytes.length,
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemBuilder:
                      (context, index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                          child: Image.memory(
                            skillPhotoBytes[index],
                            width:
                                double.infinity,
                            height:
                                double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 6,
                          top: 6,
                          child:
                              GestureDetector(
                            onTap: () =>
                                removeSkillPhoto(
                              index,
                            ),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration:
                                  const BoxDecoration(
                                color: Colors.red,
                                shape:
                                    BoxShape.circle,
                              ),
                              child:
                                  const Icon(
                                Icons.close,
                                size: 17,
                                color:
                                    Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          if (skillPhotoBytes.isNotEmpty)
            const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: pickSkillPhoto,
              icon: const Icon(
                Icons.add_photo_alternate_outlined,
                size: 19,
              ),
              label: const Text(
                'Tambah Foto Keahlian',
              ),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    Colors.orange,
                side:
                    const BorderSide(
                  color: Colors.orange,
                ),
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: saveSkill,
              icon: const Icon(
                Icons.save_outlined,
                size: 18,
              ),
              label:
                  const Text('Simpan Keahlian'),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NOTIFICATION
  // ============================================================

  Widget _buildNotificationSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.notifications_none,
            title: 'Notifikasi',
            subtitle:
                'Atur notifikasi pekerjaan yang ingin kamu terima.',
          ),
          const SizedBox(height: 15),
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color:
                  const Color(0xffF8FAFC),
              borderRadius:
                  BorderRadius.circular(12),
              border: Border.all(
                color:
                    const Color(0xffE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        Colors.orange.shade50,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                  child: const Icon(
                    Icons.work_outline,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifikasi Pekerjaan',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Terima pemberitahuan ketika ada pekerjaan baru yang sesuai.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: jobNotification,
                  activeColor: Colors.orange,
                  onChanged:
                      updateNotification,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECURITY
  // ============================================================

  Widget _buildSecuritySection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.lock_outline,
            title: 'Keamanan',
            subtitle:
                'Ubah password akun untuk menjaga keamanan akun kamu.',
          ),
          const SizedBox(height: 20),
          _passwordField(
            controller:
                currentPasswordController,
            label: 'Password Saat Ini',
            obscureText:
                obscureCurrentPassword,
            onToggle: () {
              setState(() {
                obscureCurrentPassword =
                    !obscureCurrentPassword;
              });
            },
          ),
          const SizedBox(height: 14),
          _passwordField(
            controller:
                newPasswordController,
            label: 'Password Baru',
            obscureText:
                obscureNewPassword,
            onToggle: () {
              setState(() {
                obscureNewPassword =
                    !obscureNewPassword;
              });
            },
          ),
          const SizedBox(height: 14),
          _passwordField(
            controller:
                confirmPasswordController,
            label: 'Konfirmasi Password Baru',
            obscureText:
                obscureConfirmPassword,
            onToggle: () {
              setState(() {
                obscureConfirmPassword =
                    !obscureConfirmPassword;
              });
            },
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: changePassword,
              icon: const Icon(
                Icons.lock_reset_outlined,
                size: 18,
              ),
              label:
                  const Text('Ubah Password'),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xffE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.025,
            ),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius:
                BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.orange,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    int maxLines = 1,
    String? hintText,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: _inputDecoration(
        label: label,
        icon: icon,
        hintText: hintText,
      ),
    );
  }

  // ============================================================
  // PASSWORD
  // ============================================================

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration:
          _inputDecoration(
        label: label,
        icon: Icons.lock_outline,
      ).copyWith(
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(
        icon,
        size: 20,
      ),
      filled: true,
      fillColor:
          const Color(0xffF8FAFC),
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xffE2E8F0),
        ),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xffE2E8F0),
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.orange,
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // BADGE
  // ============================================================

  Widget _badge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color:
            color.withValues(alpha: 0.08),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// PICKED IMAGE
// ================================================================

class _PickedImage {
  final Uint8List bytes;
  final String name;

  _PickedImage({
    required this.bytes,
    required this.name,
  });
}