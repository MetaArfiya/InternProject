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

class _CustomerSettingScreenState
    extends State<CustomerSettingScreen> {

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
        debugPrint("Gagal mengambil profil. Status: ${response.statusCode}");
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

        // VALIDASI IMAGE
        if (!file.type.startsWith('image/')) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("File yang dipilih harus berupa gambar."),
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
              const SnackBar(content: Text("Gagal membaca foto.")),
            );
          }
        });
      });
    } catch (e) {
      debugPrint("Error pilih foto: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal memilih foto.")),
      );
    }
  }

  // =========================================================
  // UPLOAD FOTO PROFILE
  // =========================================================

  Future<void> uploadProfilePhoto() async {
    if (selectedPhotoBytes == null || selectedPhotoName == null) {
      debugPrint("Foto belum tersedia untuk diupload.");
      return;
    }

    try {
      if (!mounted) return;
      setState(() => isUploadingPhoto = true);

      final token = await getToken();
      debugPrint("Token tersedia: ${token.isNotEmpty}");

      if (token.isEmpty) {
        if (!mounted) return;
        setState(() => isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Token login tidak ditemukan.")),
        );
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
      } else if (lowerName.endsWith('.jpg') ||
          lowerName.endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      }

      final blob = html.Blob([selectedPhotoBytes!], mimeType);
      formData.appendBlob('photo_profile', blob, selectedPhotoName!);

      debugPrint("====================================");
      debugPrint("UPLOAD FOTO PROFIL");
      debugPrint("Nama file: $selectedPhotoName");
      debugPrint("Ukuran: ${selectedPhotoBytes!.length} bytes");
      debugPrint("MIME: $mimeType");
      debugPrint("Endpoint: POST /api/user/profile/photo");
      debugPrint("====================================");

      request.onLoad.listen((event) async {
        debugPrint("====================================");
        debugPrint("UPLOAD SELESAI");
        debugPrint("STATUS: ${request.status}");
        debugPrint("RESPONSE: ${request.responseText}");
        debugPrint("====================================");

        if (request.status == 200) {
          try {
            final responseData = jsonDecode(request.responseText ?? '{}');
            debugPrint("UPLOAD JSON: $responseData");

            String? returnedPhotoUrl;

            if (responseData['photo_url'] != null) {
              returnedPhotoUrl = responseData['photo_url'].toString();
            }

            final responseUser = responseData['user'];
            if (responseUser is Map && responseUser['photo_url'] != null) {
              returnedPhotoUrl = responseUser['photo_url'].toString();
            }

            debugPrint("PHOTO URL DARI BACKEND: $returnedPhotoUrl");

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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Foto profil berhasil diperbarui."),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            debugPrint("Error membaca response upload: $e");
            if (!mounted) return;
            setState(() => isUploadingPhoto = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Foto berhasil diupload, tetapi response server tidak dapat dibaca.",
                ),
              ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal upload foto. Status: ${request.status}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      });

      request.onError.listen((event) {
        debugPrint("Network error saat upload foto.");
        if (!mounted) return;
        setState(() => isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Tidak dapat terhubung ke server."),
            backgroundColor: Colors.red,
          ),
        );
      });

      request.send(formData);
    } catch (e) {
      debugPrint("Exception upload foto: $e");
      if (!mounted) return;
      setState(() => isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Terjadi kesalahan saat upload foto."),
          backgroundColor: Colors.red,
        ),
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
      _showMessage('Nama wajib diisi.', error: true);
      return;
    }
    if (trimmedName.length < 3) {
      if (!mounted) return;
      _showMessage('Nama minimal 3 karakter.', error: true);
      return;
    }

    if (trimmedEmail.isEmpty) {
      if (!mounted) return;
      _showMessage('Email wajib diisi.', error: true);
      return;
    }
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(trimmedEmail)) {
      if (!mounted) return;
      _showMessage('Format email tidak valid.', error: true);
      return;
    }

    if (trimmedPhone.isNotEmpty) {
      if (!RegExp(r'^[0-9]+$').hasMatch(trimmedPhone)) {
        if (!mounted) return;
        _showMessage('Nomor HP hanya boleh berisi angka.', error: true);
        return;
      }
      if (trimmedPhone.length < 10 || trimmedPhone.length > 15) {
        if (!mounted) return;
        _showMessage('Nomor HP harus 10-15 digit.', error: true);
        return;
      }
    }

    if (trimmedAddress.isNotEmpty && trimmedAddress.length < 5) {
      if (!mounted) return;
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
        if (!mounted) return;
        _showMessage(message, error: true);
      }
    } catch (e) {
      debugPrint("Error update profile: $e");
      if (!mounted) return;
      _showMessage('Terjadi kesalahan saat memperbarui profil.', error: true);
    }
  }

  // =========================================================
  // UPDATE NOTIFICATION
  // =========================================================

  Future<void> updateNotificationStatus(bool value) async {
    try {
      await ApiService.put(
        '/user/notification-setting',
        {
          'is_notification_enabled': value ? 1 : 0,
        },
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
          content: Text(message),
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
          child: CircularProgressIndicator(
            color: Color(0xffF97316),
          ),
        ),
      );
    }

    final fullPhotoUrl = getFullPhotoUrl();

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            const Text(
              "Pengaturan",
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Kelola profil, notifikasi, dan keamanan akun.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 35),

            // PROFILE HEADER
            Center(
              child: Column(
                children: [
                  // PROFILE PHOTO
                  GestureDetector(
                    onTap: () {
                      if (selectedPhotoBytes != null) {
                        _showImageDialog(
                            context, MemoryImage(selectedPhotoBytes!));
                      } else if (fullPhotoUrl != null) {
                        _showImageDialog(context, NetworkImage(fullPhotoUrl!));
                      }
                    },
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: const Color(0xffFFF3E8),
                          backgroundImage: selectedPhotoBytes != null
                              ? MemoryImage(selectedPhotoBytes!)
                              : fullPhotoUrl != null
                                  ? NetworkImage(fullPhotoUrl!)
                                  : null,
                          child: selectedPhotoBytes == null &&
                                  fullPhotoUrl == null
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Color(0xffF97316),
                                )
                              : null,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xffF97316),
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                            onPressed: isUploadingPhoto
                                ? null
                                : pickProfilePhoto,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),

                  // EDIT PROFILE BUTTON
                  SizedBox(
                    width: 170,
                    height: 45,
                    child: ElevatedButton.icon(
                      onPressed: () => _showEditProfileDialog(fullPhotoUrl),
                      icon: const Icon(Icons.edit),
                      label: const Text("Edit Profil"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffF97316),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // INFORMASI AKUN
            const Text(
              "Informasi Akun",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 15),

            _buildCard(
              icon: Icons.person_outline,
              title: "Nama",
              subtitle: name,
            ),
            _buildCard(
              icon: Icons.email_outlined,
              title: "Email",
              subtitle: email,
            ),
            _buildCard(
              icon: Icons.phone_outlined,
              title: "Nomor HP",
              subtitle: phone.isEmpty ? "-" : phone,
            ),
            _buildCard(
              icon: Icons.location_on_outlined,
              title: "Alamat",
              subtitle: address.isEmpty ? "-" : address,
            ),

            const SizedBox(height: 35),

            // NOTIFIKASI
            const Text(
              "Notifikasi",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 15),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xffE5E7EB)),
              ),
              child: SwitchListTile(
                value: jobNotification,
                activeColor: const Color(0xffF97316),
                secondary: const Icon(
                  Icons.notifications_active_outlined,
                  color: Color(0xffF97316),
                ),
                title: const Text("Notifikasi Penawaran"),
                subtitle: const Text(
                  "Terima notifikasi ketika "
                  "mitra mengirim penawaran "
                  "pada pekerjaan Anda.",
                ),
                onChanged: (value) async {
                  setState(() => jobNotification = value);
                  await updateNotificationStatus(value);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? "Notifikasi penawaran diaktifkan."
                            : "Notifikasi penawaran dinonaktifkan.",
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 35),

            // KEAMANAN
            const Text(
              "Keamanan",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 15),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xffE5E7EB)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      "Logout",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLogoutDialog(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // EDIT PROFILE DIALOG (dipisah biar rapi)
  // =========================================================
  void _showEditProfileDialog(String? fullPhotoUrl) {
    // ✅ Formatters
    final nameFmts = nameFormatters;
    final digitsFmts = digitsOnly;

    final nameController = TextEditingController(text: name);
    final emailController = TextEditingController(text: email);
    final phoneController = TextEditingController(text: phone);
    final addressController = TextEditingController(text: address);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Edit Profil"),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // FOTO
                  GestureDetector(
                    onTap: () {
                      if (selectedPhotoBytes != null) {
                        _showImageDialog(
                            dialogContext, MemoryImage(selectedPhotoBytes!));
                      } else if (fullPhotoUrl != null) {
                        _showImageDialog(
                            dialogContext, NetworkImage(fullPhotoUrl));
                      }
                    },
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xffFFF3E8),
                          backgroundImage: selectedPhotoBytes != null
                              ? MemoryImage(selectedPhotoBytes!)
                              : fullPhotoUrl != null
                                  ? NetworkImage(fullPhotoUrl)
                                  : null,
                          child: selectedPhotoBytes == null &&
                                  fullPhotoUrl == null
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Color(0xffF97316),
                                )
                              : null,
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xffF97316),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: () async {
                              Navigator.pop(dialogContext);
                              await pickProfilePhoto();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // NAMA — hanya huruf, max 100
                  // ==================================================
                  TextField(
                    controller: nameController,
                    maxLength: 100,
                    inputFormatters: nameFmts,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: "Nama",
                      prefixIcon: Icon(Icons.person_outline),
                      counterText: '',
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ==================================================
                  // EMAIL — max 100
                  // ==================================================
                  TextField(
                    controller: emailController,
                    maxLength: 100,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email_outlined),
                      counterText: '',
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ==================================================
                  // NOMOR HP — hanya angka, max 15
                  // ==================================================
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 15,
                    inputFormatters: digitsFmts,
                    decoration: const InputDecoration(
                      labelText: "Nomor HP",
                      prefixIcon: Icon(Icons.phone_outlined),
                      counterText: '',
                      hintText: '10-15 digit angka',
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ==================================================
                  // ALAMAT — max 500
                  // ==================================================
                  TextField(
                    controller: addressController,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: "Alamat",
                      prefixIcon: Icon(Icons.location_on_outlined),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
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
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffF97316),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newName = nameController.text.trim();
                final newEmail = emailController.text.trim();
                final newPhone = phoneController.text.trim();
                final newAddress = addressController.text.trim();

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
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    ).then((_) {
      // Fallback dispose kalau tidak terpanggil
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
  // LOGOUT DIALOG
  // =========================================================
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text(
            "Apakah Anda yakin ingin keluar dari akun ini?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                if (!mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LandingPage(),
                  ),
                  (route) => false,
                );
              },
              child: const Text("Logout"),
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