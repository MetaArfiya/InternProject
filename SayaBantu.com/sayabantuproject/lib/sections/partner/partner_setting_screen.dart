import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sayabantu_project/screens/Screens_Landing/landing_page.dart';
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

class _PartnerSettingScreenState
    extends State<PartnerSettingScreen> {
  // ============================================================
  // GENERAL
  // ============================================================

  bool isLoading = true;
  bool isSavingVerification = false;
  bool jobNotification = true;

  final ImagePicker picker = ImagePicker();

  // ============================================================
  // ACCOUNT
  // ============================================================

  String name = '';
  String email = '';

  Uint8List? profileImage;

  // ============================================================
  // IDENTITAS MITRA
  // ============================================================

  final TextEditingController fullNameController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController addressController =
      TextEditingController();

  final TextEditingController cityController =
      TextEditingController();

  final TextEditingController descriptionController =
      TextEditingController();

  String gender = '';
  DateTime? birthDate;

  // ============================================================
  // VERIFIKASI
  // ============================================================

  Uint8List? ktpImage;
  Uint8List? verificationImage;

  String verificationStatus = 'Belum Diverifikasi';

  // ============================================================
  // KEAHLIAN
  // ============================================================

  String selectedSkill = '';

  final List<String> skillCategories = [
    'Perbaikan & Perawatan Rumah',
    'Kebersihan',
    'Konstruksi & Renovasi',
    'Instalasi & Teknisi',
    'Jasa Rumah Tangga',
    'Jasa Umum',
    'Lainnya',
  ];

  final List<Uint8List> skillImages = [];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    cityController.dispose();
    descriptionController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> loadProfile() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await ApiService.get('/user');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final dynamic userData =
            decoded is Map &&
                    decoded['user'] != null
                ? decoded['user']
                : decoded;

        if (userData is Map) {
          final loadedName =
              userData['name']?.toString() ?? '';

          final loadedEmail =
              userData['email']?.toString() ?? '';

          final loadedFullName =
              userData['full_name']?.toString() ??
                  loadedName;

          final loadedPhone =
              userData['phone']?.toString() ?? '';

          final loadedAddress =
              userData['address']?.toString() ?? '';

          final loadedCity =
              userData['city']?.toString() ?? '';

          final loadedGender =
              userData['gender']?.toString() ?? '';

          final loadedDescription =
              userData['description']?.toString() ??
                  userData['bio']?.toString() ??
                  '';

          final loadedSkill =
              userData['skill_category']?.toString() ??
                  '';

          final birthDateValue =
              userData['birth_date'] ??
                  userData['date_of_birth'];

          DateTime? loadedBirthDate;

          if (birthDateValue != null &&
              birthDateValue
                  .toString()
                  .isNotEmpty) {
            loadedBirthDate = DateTime.tryParse(
              birthDateValue.toString(),
            );
          }

          bool loadedNotification = true;

          final notificationValue =
              userData[
                  'is_notification_enabled'];

          if (notificationValue is bool) {
            loadedNotification =
                notificationValue;
          } else if (notificationValue != null) {
            loadedNotification =
                notificationValue
                        .toString() ==
                    '1';
          }

          final loadedVerificationStatus =
              userData[
                          'verification_status']
                      ?.toString() ??
                  'Belum Diverifikasi';

          setState(() {
            name = loadedName;
            email = loadedEmail;

            fullNameController.text =
                loadedFullName;

            phoneController.text =
                loadedPhone;

            addressController.text =
                loadedAddress;

            cityController.text =
                loadedCity;

            descriptionController.text =
                loadedDescription;

            gender = loadedGender;
            birthDate = loadedBirthDate;

            selectedSkill = loadedSkill;

            jobNotification =
                loadedNotification;

            verificationStatus =
                loadedVerificationStatus;
          });
        }
      }
    } catch (e) {
      debugPrint(
        'Error load profile: $e',
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
  // UPDATE PROFILE
  // ============================================================

  Future<void> updateProfileToApi({
    required String newName,
    required String newEmail,
  }) async {
    try {
      final response = await ApiService.put(
        '/user/profile',
        {
          'name': newName,
          'email': newEmail,
          'phone': phoneController.text.trim(),
          'address': addressController.text.trim(),
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          name = newName;
          email = newEmail;
        });

        widget.onProfileUpdate();

        if (!mounted) return;

        showMessage(
          'Profil berhasil diperbarui.',
        );
      } else {
        if (!mounted) return;

        showMessage(
          'Gagal memperbarui profil.',
        );
      }
    } catch (e) {
      debugPrint(
        'Error update profile: $e',
      );

      if (!mounted) return;

      showMessage(
        'Terjadi kesalahan saat memperbarui profil.',
      );
    }
  }

  // ============================================================
  // NOTIFICATION
  // ============================================================

  Future<void> updateNotificationStatus(
    bool value,
  ) async {
    try {
      await ApiService.put(
        '/user/notification-setting',
        {
          'is_notification_enabled':
              value ? 1 : 0,
        },
      );
    } catch (e) {
      debugPrint(
        'Error notification: $e',
      );
    }
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> pickBirthDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate:
          birthDate ??
          DateTime(
            now.year - 25,
            now.month,
            now.day,
          ),
      firstDate: DateTime(1940),
      lastDate: now,
      helpText: 'Pilih tanggal lahir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (picked != null) {
      setState(() {
        birthDate = picked;
      });
    }
  }

  // ============================================================
  // PICK KTP
  // ============================================================

  Future<void> pickKtpImage() async {
    try {
      final XFile? image =
          await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (image == null) return;

      final bytes =
          await image.readAsBytes();

      setState(() {
        ktpImage = bytes;
      });
    } catch (e) {
      debugPrint(
        'Error KTP: $e',
      );

      showMessage(
        'Gagal memilih foto KTP.',
      );
    }
  }

  // ============================================================
  // PICK SELFIE
  // ============================================================

  Future<void> pickVerificationImage() async {
    try {
      final XFile? image =
          await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (image == null) return;

      final bytes =
          await image.readAsBytes();

      setState(() {
        verificationImage = bytes;
      });
    } catch (e) {
      debugPrint(
        'Error verification photo: $e',
      );

      showMessage(
        'Gagal mengambil foto verifikasi.',
      );
    }
  }

  // ============================================================
  // PICK SKILL IMAGES
  // ============================================================

  Future<void> pickSkillImages() async {
    try {
      final List<XFile> images =
          await picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1400,
      );

      if (images.isEmpty) return;

      final List<Uint8List> selectedImages = [];

      for (final image in images) {
        final bytes =
            await image.readAsBytes();

        selectedImages.add(bytes);
      }

      setState(() {
        skillImages.addAll(
          selectedImages,
        );
      });
    } catch (e) {
      debugPrint(
        'Error skill images: $e',
      );

      showMessage(
        'Gagal memilih foto keahlian.',
      );
    }
  }

  // ============================================================
  // REMOVE SKILL IMAGE
  // ============================================================

  void removeSkillImage(int index) {
    if (index < 0 ||
        index >= skillImages.length) {
      return;
    }

    setState(() {
      skillImages.removeAt(index);
    });
  }

  // ============================================================
  // SAVE VERIFICATION - FRONTEND ONLY
  // ============================================================

  Future<void> savePartnerVerification() async {
    if (fullNameController.text
        .trim()
        .isEmpty) {
      showMessage(
        'Nama lengkap wajib diisi.',
      );
      return;
    }

    if (phoneController.text
        .trim()
        .isEmpty) {
      showMessage(
        'Nomor HP wajib diisi.',
      );
      return;
    }

    if (addressController.text
        .trim()
        .isEmpty) {
      showMessage(
        'Alamat lengkap wajib diisi.',
      );
      return;
    }

    if (cityController.text
        .trim()
        .isEmpty) {
      showMessage(
        'Kota/Kabupaten wajib diisi.',
      );
      return;
    }

    if (gender.isEmpty) {
      showMessage(
        'Jenis kelamin wajib dipilih.',
      );
      return;
    }

    if (birthDate == null) {
      showMessage(
        'Tanggal lahir wajib dipilih.',
      );
      return;
    }

    if (descriptionController.text
        .trim()
        .isEmpty) {
      showMessage(
        'Deskripsi diri wajib diisi.',
      );
      return;
    }

    if (selectedSkill.isEmpty) {
      showMessage(
        'Kategori keahlian wajib dipilih.',
      );
      return;
    }

    if (ktpImage == null) {
      showMessage(
        'Silakan upload scan KTP.',
      );
      return;
    }

    if (verificationImage == null) {
      showMessage(
        'Silakan ambil foto verifikasi diri.',
      );
      return;
    }

    if (skillImages.isEmpty) {
      showMessage(
        'Silakan tambahkan minimal satu foto keahlian.',
      );
      return;
    }

    setState(() {
      isSavingVerification = true;
    });

    // ----------------------------------------------------------
    // FRONTEND ONLY
    // Backend belum digunakan.
    // ----------------------------------------------------------

    await Future.delayed(
      const Duration(seconds: 1),
    );

    if (!mounted) return;

    setState(() {
      isSavingVerification = false;
      verificationStatus =
          'Menunggu Verifikasi';
    });

    try {
      final prefs =
          await SharedPreferences
              .getInstance();

      await prefs.setString(
        'partner_full_name',
        fullNameController.text.trim(),
      );

      await prefs.setString(
        'partner_phone',
        phoneController.text.trim(),
      );

      await prefs.setString(
        'partner_address',
        addressController.text.trim(),
      );

      await prefs.setString(
        'partner_city',
        cityController.text.trim(),
      );

      await prefs.setString(
        'partner_gender',
        gender,
      );

      await prefs.setString(
        'partner_description',
        descriptionController.text.trim(),
      );

      await prefs.setString(
        'partner_skill',
        selectedSkill,
      );

      await prefs.setString(
        'partner_verification_status',
        verificationStatus,
      );

      if (birthDate != null) {
        await prefs.setString(
          'partner_birth_date',
          birthDate!
              .toIso8601String(),
        );
      }
    } catch (e) {
      debugPrint(
        'Error local storage: $e',
      );
    }

    widget.onProfileUpdate();

    showMessage(
      'Data berhasil disiapkan. Status: Menunggu Verifikasi.',
    );
  }

  // ============================================================
  // EDIT PROFILE
  // ============================================================

  void showEditProfileDialog() {
    final nameController =
        TextEditingController(
      text: name,
    );

    final emailController =
        TextEditingController(
      text: email,
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Edit Profil',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 430,
            child:
                SingleChildScrollView(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  TextField(
                    controller:
                        nameController,
                    decoration:
                        InputDecoration(
                      labelText:
                          'Nama',
                      prefixIcon:
                          const Icon(
                        Icons
                            .person_outline,
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  TextField(
                    controller:
                        emailController,
                    keyboardType:
                        TextInputType
                            .emailAddress,
                    decoration:
                        InputDecoration(
                      labelText:
                          'Email',
                      prefixIcon:
                          const Icon(
                        Icons
                            .email_outlined,
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text('Batal'),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xffF97316,
                ),
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () async {
                final newName =
                    nameController.text
                        .trim();

                final newEmail =
                    emailController.text
                        .trim();

                if (newName.isEmpty ||
                    newEmail.isEmpty) {
                  showMessage(
                    'Nama dan email wajib diisi.',
                  );
                  return;
                }

                Navigator.pop(
                  dialogContext,
                );

                await updateProfileToApi(
                  newName: newName,
                  newEmail: newEmail,
                );

                nameController.dispose();
                emailController.dispose();
              },
              child:
                  const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  void showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Logout',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar '
            'dari akun ini?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text('Batal'),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () async {
                final prefs =
                    await SharedPreferences
                        .getInstance();

                await prefs.clear();

                if (!mounted) return;

                Navigator.pop(
                  dialogContext,
                );

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const LandingPage(),
                  ),
                  (route) => false,
                );
              },
              child:
                  const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String get formattedBirthDate {
    if (birthDate == null) {
      return 'Pilih tanggal lahir';
    }

    return '${birthDate!.day.toString().padLeft(2, '0')}/'
        '${birthDate!.month.toString().padLeft(2, '0')}/'
        '${birthDate!.year}';
  }

  Color get verificationColor {
    switch (
        verificationStatus.toLowerCase()) {
      case 'terverifikasi':
        return Colors.green;

      case 'menunggu verifikasi':
        return Colors.orange;

      case 'ditolak':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  IconData get verificationIcon {
    switch (
        verificationStatus.toLowerCase()) {
      case 'terverifikasi':
        return Icons.verified;

      case 'menunggu verifikasi':
        return Icons.hourglass_top;

      case 'ditolak':
        return Icons.cancel_outlined;

      default:
        return Icons.info_outline;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor:
            Color(0xffF8FAFC),
        body: Center(
          child:
              CircularProgressIndicator(
            color:
                Color(0xffF97316),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          const Color(0xffF8FAFC),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 30,
          vertical: 25,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            const Text(
              'Pengaturan',
              style: TextStyle(
                fontSize: 32,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 7,
            ),

            Text(
              'Kelola profil dan informasi akun mitra Anda.',
              style: TextStyle(
                color:
                    Colors.grey.shade600,
                fontSize: 15,
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            // ==================================================
            // PROFILE
            // ==================================================

            _buildProfileCard(),

            const SizedBox(
              height: 35,
            ),

            // ==================================================
            // IDENTITAS
            // ==================================================

            _buildSectionTitle(
              'Identitas Mitra',
              'Lengkapi informasi pribadi Anda '
              'untuk melengkapi profil mitra.',
            ),

            const SizedBox(
              height: 15,
            ),

            _buildIdentityCard(),

            const SizedBox(
              height: 35,
            ),

            // ==================================================
            // VERIFIKASI
            // ==================================================

            _buildSectionTitle(
              'Verifikasi Mitra',
              'Verifikasi identitas Anda agar akun '
              'mitra dapat dipercaya oleh pelanggan.',
            ),

            const SizedBox(
              height: 15,
            ),

            _buildVerificationCard(),

            const SizedBox(
              height: 35,
            ),

            // ==================================================
            // KEAHLIAN
            // ==================================================

            _buildSectionTitle(
              'Keahlian Mitra',
              'Tambahkan bidang keahlian dan foto '
              'hasil pekerjaan Anda.',
            ),

            const SizedBox(
              height: 15,
            ),

            _buildSkillCard(),

            const SizedBox(
              height: 35,
            ),

            // ==================================================
            // NOTIFIKASI
            // ==================================================

            _buildSectionTitle(
              'Notifikasi',
              'Atur notifikasi pekerjaan yang ingin '
              'Anda terima.',
            ),

            const SizedBox(
              height: 15,
            ),

            _buildNotificationCard(),

            const SizedBox(
              height: 35,
            ),

            // ==================================================
            // KEAMANAN
            // ==================================================

            _buildSectionTitle(
              'Keamanan',
              'Kelola akses akun Anda.',
            ),

            const SizedBox(
              height: 15,
            ),

            _buildSecurityCard(),

            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE CARD
  // ============================================================

  Widget _buildProfileCard() {
    return Card(
      elevation: 0,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
        side:
            const BorderSide(
          color:
              Color(0xffE5E7EB),
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(22),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor:
                      const Color(
                    0xfffff1e7,
                  ),
                  backgroundImage:
                      profileImage !=
                              null
                          ? MemoryImage(
                              profileImage!,
                            )
                          : null,
                  child:
                      profileImage ==
                              null
                          ? const Icon(
                              Icons.person,
                              size: 45,
                              color:
                                  Color(
                                0xffF97316,
                              ),
                            )
                          : null,
                ),

                Positioned(
                  bottom: 0,
                  right: 0,
                  child:
                      Container(
                    padding:
                        const EdgeInsets
                            .all(
                      6,
                    ),
                    decoration:
                        const BoxDecoration(
                      color:
                          Color(
                        0xffF97316,
                      ),
                      shape:
                          BoxShape.circle,
                    ),
                    child:
                        const Icon(
                      Icons.edit,
                      color:
                          Colors.white,
                      size: 15,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              width: 18,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    name.isEmpty
                        ? 'Mitra'
                        : name,
                    style:
                        const TextStyle(
                      fontSize: 21,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    email.isEmpty
                        ? '-'
                        : email,
                    style: TextStyle(
                      color:
                          Colors.grey
                              .shade600,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xfffff1e7,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        20,
                      ),
                    ),
                    child:
                        const Text(
                      'Mitra',
                      style:
                          TextStyle(
                        color:
                            Color(
                          0xffF97316,
                        ),
                        fontWeight:
                            FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 15,
            ),

            OutlinedButton.icon(
              onPressed:
                  showEditProfileDialog,
              icon:
                  const Icon(
                Icons.edit_outlined,
                size: 18,
              ),
              label:
                  const Text(
                'Edit Profil',
              ),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    const Color(
                  0xffF97316,
                ),
                side:
                    const BorderSide(
                  color:
                      Color(
                    0xffF97316,
                  ),
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // IDENTITY CARD
  // ============================================================

  Widget _buildIdentityCard() {
    return Card(
      elevation: 0,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
        side:
            const BorderSide(
          color:
              Color(0xffE5E7EB),
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(22),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child:
                      _buildTextField(
                    controller:
                        fullNameController,
                    label:
                        'Nama Lengkap',
                    icon:
                        Icons.person_outline,
                  ),
                ),

                const SizedBox(
                  width: 15,
                ),

                Expanded(
                  child:
                      _buildTextField(
                    controller:
                        phoneController,
                    label:
                        'Nomor HP',
                    icon:
                        Icons.phone_outlined,
                    keyboardType:
                        TextInputType.phone,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),

            Row(
              children: [
                Expanded(
                  child:
                      DropdownButtonFormField<
                          String>(
                    value:
                        gender.isEmpty
                            ? null
                            : gender,
                    decoration:
                        InputDecoration(
                      labelText:
                          'Jenis Kelamin',
                      prefixIcon:
                          const Icon(
                        Icons
                            .wc_outlined,
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value:
                            'Laki-laki',
                        child: Text(
                          'Laki-laki',
                        ),
                      ),
                      DropdownMenuItem(
                        value:
                            'Perempuan',
                        child: Text(
                          'Perempuan',
                        ),
                      ),
                    ],
                    onChanged:
                        (value) {
                      setState(() {
                        gender =
                            value ?? '';
                      });
                    },
                  ),
                ),

                const SizedBox(
                  width: 15,
                ),

                Expanded(
                  child: InkWell(
                    onTap:
                        pickBirthDate,
                    borderRadius:
                        BorderRadius
                            .circular(
                      12,
                    ),
                    child:
                        InputDecorator(
                      decoration:
                          InputDecoration(
                        labelText:
                            'Tanggal Lahir',
                        prefixIcon:
                            const Icon(
                          Icons
                              .calendar_today_outlined,
                        ),
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),
                        ),
                      ),
                      child:
                          Text(
                        formattedBirthDate,
                        style:
                            TextStyle(
                          color:
                              birthDate ==
                                      null
                                  ? Colors
                                      .grey
                                  : Colors
                                      .black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),

            _buildTextField(
              controller:
                  cityController,
              label:
                  'Kota/Kabupaten',
              icon:
                  Icons.location_city_outlined,
            ),

            const SizedBox(
              height: 16,
            ),

            _buildTextField(
              controller:
                  addressController,
              label:
                  'Alamat Lengkap',
              icon:
                  Icons.location_on_outlined,
              maxLines: 3,
            ),

            const SizedBox(
              height: 16,
            ),

            _buildTextField(
              controller:
                  descriptionController,
              label:
                  'Deskripsi Diri',
              icon:
                  Icons.description_outlined,
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // VERIFICATION CARD
  // ============================================================

  Widget _buildVerificationCard() {
    return Card(
      elevation: 0,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
        side:
            const BorderSide(
          color:
              Color(0xffE5E7EB),
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(22),
        child: Column(
          children: [
            // STATUS
            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.all(
                15,
              ),
              decoration:
                  BoxDecoration(
                color:
                    verificationColor
                        .withOpacity(
                  0.08,
                ),
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets
                            .all(
                      8,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          verificationColor
                              .withOpacity(
                        0.12,
                      ),
                      shape:
                          BoxShape.circle,
                    ),
                    child:
                        Icon(
                      verificationIcon,
                      color:
                          verificationColor,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      const Text(
                        'Status Verifikasi',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        verificationStatus,
                        style:
                            TextStyle(
                          color:
                              verificationColor,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(
                  child:
                      _buildDocumentUpload(
                    title:
                        'Scan KTP',
                    subtitle:
                        'Upload foto KTP yang jelas dan tidak buram.',
                    image:
                        ktpImage,
                    icon:
                        Icons
                            .credit_card_outlined,
                    buttonText:
                        ktpImage == null
                            ? 'Upload KTP'
                            : 'Ganti KTP',
                    onPressed:
                        pickKtpImage,
                  ),
                ),

                const SizedBox(
                  width: 18,
                ),

                Expanded(
                  child:
                      _buildDocumentUpload(
                    title:
                        'Foto Verifikasi Diri',
                    subtitle:
                        'Ambil foto wajah secara langsung menggunakan kamera.',
                    image:
                        verificationImage,
                    icon:
                        Icons
                            .face_outlined,
                    buttonText:
                        verificationImage ==
                                null
                            ? 'Ambil Foto'
                            : 'Ganti Foto',
                    onPressed:
                        pickVerificationImage,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 22,
            ),

            SizedBox(
              width:
                  double.infinity,
              height: 50,
              child:
                  ElevatedButton.icon(
                onPressed:
                    isSavingVerification
                        ? null
                        : savePartnerVerification,
                icon:
                    isSavingVerification
                        ? const SizedBox(
                            width: 20,
                            height: 20,
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
                                .verified_user_outlined,
                          ),
                label: Text(
                  isSavingVerification
                      ? 'Menyimpan...'
                      : 'Kirim Untuk Verifikasi',
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xffF97316,
                  ),
                  foregroundColor:
                      Colors.white,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
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

  // ============================================================
  // DOCUMENT UPLOAD
  // ============================================================

  Widget _buildDocumentUpload({
    required String title,
    required String subtitle,
    required Uint8List? image,
    required IconData icon,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(15),
      decoration:
          BoxDecoration(
        border:
            Border.all(
          color:
              const Color(
            0xffE5E7EB,
          ),
        ),
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            height: 170,
            width:
                double.infinity,
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xffF8FAFC,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child:
                image == null
                    ? Icon(
                        icon,
                        size: 55,
                        color:
                            const Color(
                          0xffF97316,
                        ),
                      )
                    : ClipRRect(
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                        child:
                            Image.memory(
                          image,
                          width:
                              double.infinity,
                          height:
                              double.infinity,
                          fit:
                              BoxFit.cover,
                        ),
                      ),
          ),

          const SizedBox(
            height: 13,
          ),

          Text(
            title,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            subtitle,
            style:
                TextStyle(
              color:
                  Colors.grey.shade600,
              fontSize: 12,
              height: 1.4,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          SizedBox(
            width:
                double.infinity,
            height: 43,
            child:
                OutlinedButton.icon(
              onPressed:
                  onPressed,
              icon: Icon(
                image == null
                    ? Icons
                        .upload_outlined
                    : Icons.refresh,
                size: 18,
              ),
              label:
                  Text(buttonText),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    const Color(
                  0xffF97316,
                ),
                side:
                    const BorderSide(
                  color:
                      Color(
                    0xffF97316,
                  ),
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SKILL CARD
  // ============================================================

  Widget _buildSkillCard() {
    return Card(
      elevation: 0,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
        side:
            const BorderSide(
          color:
              Color(0xffE5E7EB),
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value:
                  selectedSkill.isEmpty
                      ? null
                      : selectedSkill,
              decoration:
                  InputDecoration(
                labelText:
                    'Kategori Keahlian',
                prefixIcon:
                    const Icon(
                  Icons
                      .handyman_outlined,
                ),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              items:
                  skillCategories
                      .map(
                        (skill) =>
                            DropdownMenuItem<
                                String>(
                          value:
                              skill,
                          child:
                              Text(skill),
                        ),
                      )
                      .toList(),
              onChanged:
                  (value) {
                setState(() {
                  selectedSkill =
                      value ?? '';
                });
              },
            ),

            const SizedBox(
              height: 22,
            ),

            const Text(
              'Foto Hasil Pekerjaan',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            Text(
              'Tambahkan beberapa foto hasil pekerjaan '
              'untuk menunjukkan pengalaman dan keahlian Anda.',
              style: TextStyle(
                color:
                    Colors.grey.shade600,
                fontSize: 13,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            if (skillImages.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount:
                    skillImages.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder:
                    (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                        child:
                            Image.memory(
                          skillImages[
                              index],
                          width:
                              double.infinity,
                          height:
                              double.infinity,
                          fit:
                              BoxFit.cover,
                        ),
                      ),

                      Positioned(
                        top: 6,
                        right: 6,
                        child:
                            GestureDetector(
                          onTap: () =>
                              removeSkillImage(
                            index,
                          ),
                          child:
                              Container(
                            width: 28,
                            height: 28,
                            decoration:
                                const BoxDecoration(
                              color:
                                  Colors.red,
                              shape:
                                  BoxShape
                                      .circle,
                            ),
                            child:
                                const Icon(
                              Icons.close,
                              color:
                                  Colors.white,
                              size: 17,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              )
            else
              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 35,
                  horizontal: 20,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xffF8FAFC,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                  border:
                      Border.all(
                    color:
                        const Color(
                      0xffE5E7EB,
                    ),
                  ),
                ),
                child:
                    Column(
                  children: [
                    Icon(
                      Icons
                          .photo_library_outlined,
                      size: 45,
                      color:
                          Colors.grey
                              .shade400,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      'Belum ada foto pekerjaan',
                      style:
                          TextStyle(
                        color:
                            Colors.grey
                                .shade600,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(
              height: 16,
            ),

            SizedBox(
              width:
                  double.infinity,
              height: 48,
              child:
                  OutlinedButton.icon(
                onPressed:
                    pickSkillImages,
                icon:
                    const Icon(
                  Icons
                      .add_photo_alternate_outlined,
                ),
                label:
                    const Text(
                  'Tambah Foto Keahlian',
                ),
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      const Color(
                    0xffF97316,
                  ),
                  side:
                      const BorderSide(
                    color:
                        Color(
                      0xffF97316,
                    ),
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
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

  // ============================================================
  // NOTIFICATION CARD
  // ============================================================

  Widget _buildNotificationCard() {
    return Card(
      elevation: 0,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
        side:
            const BorderSide(
          color:
              Color(0xffE5E7EB),
        ),
      ),
      child:
          SwitchListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 7,
        ),
        value:
            jobNotification,
        activeColor:
            const Color(
          0xffF97316,
        ),
        secondary:
            Container(
          padding:
              const EdgeInsets.all(
            10,
          ),
          decoration:
              BoxDecoration(
            color:
                const Color(
              0xfffff1e7,
            ),
            borderRadius:
                BorderRadius.circular(
              10,
            ),
          ),
          child:
              const Icon(
            Icons
                .notifications_active_outlined,
            color:
                Color(
              0xffF97316,
            ),
          ),
        ),
        title:
            const Text(
          'Notifikasi Pekerjaan',
          style: TextStyle(
            fontWeight:
                FontWeight.w600,
          ),
        ),
        subtitle:
            const Text(
          'Terima informasi pekerjaan '
          'yang sesuai dengan keahlian Anda.',
        ),
        onChanged:
            (value) async {
          setState(() {
            jobNotification =
                value;
          });

          await updateNotificationStatus(
            value,
          );
        },
      ),
    );
  }

  // ============================================================
  // SECURITY CARD
  // ============================================================

  Widget _buildSecurityCard() {
    return Card(
      elevation: 0,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
        side:
            const BorderSide(
          color:
              Color(0xffE5E7EB),
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 7,
        ),
        leading:
            Container(
          padding:
              const EdgeInsets.all(
            10,
          ),
          decoration:
              BoxDecoration(
            color:
                Colors.red.withOpacity(
              0.08,
            ),
            borderRadius:
                BorderRadius.circular(
              10,
            ),
          ),
          child:
              const Icon(
            Icons.logout,
            color: Colors.red,
          ),
        ),
        title:
            const Text(
          'Logout',
          style: TextStyle(
            fontWeight:
                FontWeight.w600,
            color: Colors.red,
          ),
        ),
        subtitle:
            const Text(
          'Keluar dari akun mitra ini.',
        ),
        trailing:
            const Icon(
          Icons.chevron_right,
        ),
        onTap:
            showLogoutDialog,
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType:
          keyboardType,
      maxLines: maxLines,
      decoration:
          InputDecoration(
        labelText: label,
        prefixIcon:
            Icon(icon),
        alignLabelWithHint:
            maxLines > 1,
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            12,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        Text(
          subtitle,
          style: TextStyle(
            color:
                Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}