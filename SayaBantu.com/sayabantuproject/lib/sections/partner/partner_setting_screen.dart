import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:sayabantu_project/screens/Screens_Landing/landing_page.dart';
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

class _PartnerSettingScreenState
    extends State<PartnerSettingScreen> {

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

  // Data mitra
  int totalPoint = 0;
  bool isVerified = false;

  @override
  void initState() {
    super.initState();

    loadProfileFromApi();
  }

  // =========================================================
  // LOAD PROFILE
  // =========================================================

  Future<void> loadProfileFromApi() async {
    try {

      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      // =======================================================
      // GET USER
      // =======================================================

      final response =
          await ApiService.get('/user');

      debugPrint(
        "====================================",
      );

      debugPrint(
        "GET /user PARTNER",
      );

      debugPrint(
        "STATUS: ${response.statusCode}",
      );

      debugPrint(
        "BODY: ${response.body}",
      );

      debugPrint(
        "====================================",
      );

      if (response.statusCode == 200) {

        final data =
            jsonDecode(response.body);

        final userData =
            data['user'] ?? data;

        if (!mounted) return;

        setState(() {

          name =
              userData['name']?.toString() ?? "";

          email =
              userData['email']?.toString() ?? "";

          phone =
              userData['phone']?.toString() ?? "";

          address =
              userData['address']?.toString() ?? "";

          // =================================================
          // PHOTO
          // =================================================

          final apiPhoto =
              userData['photo_url'];

          if (apiPhoto != null &&
              apiPhoto
                  .toString()
                  .trim()
                  .isNotEmpty &&
              apiPhoto.toString() != 'null') {

            photoUrl =
                apiPhoto.toString();
          } else {

            photoUrl = null;
          }

          // =================================================
          // NOTIFICATION
          // =================================================

          final notifValue =
              userData[
                  'is_notification_enabled'];

          if (notifValue is bool) {

            jobNotification =
                notifValue;

          } else if (notifValue is int) {

            jobNotification =
                notifValue == 1;

          } else if (notifValue is String) {

            jobNotification =
                notifValue == '1' ||
                notifValue.toLowerCase() ==
                    'true';

          } else {

            jobNotification = true;
          }

          isLoading = false;
        });

      } else {

        debugPrint(
          "Gagal mengambil profil user. "
          "Status: ${response.statusCode}",
        );

        if (!mounted) return;

        setState(() {
          isLoading = false;
        });
      }

      // =======================================================
      // GET PROFILE MITRA
      // =======================================================

      try {

        final mitraResponse =
            await ApiService.get('/mitra/profile');

        debugPrint(
          "====================================",
        );

        debugPrint(
          "GET /mitra/profile",
        );

        debugPrint(
          "STATUS: ${mitraResponse.statusCode}",
        );

        debugPrint(
          "BODY: ${mitraResponse.body}",
        );

        debugPrint(
          "====================================",
        );

        if (mitraResponse.statusCode == 200) {

          final mitraDecoded =
              jsonDecode(
            mitraResponse.body,
          );

          final mitraData =
              mitraDecoded['data'];

          if (mitraData != null &&
              mounted) {

            setState(() {

              totalPoint =
                  int.tryParse(
                    mitraData['point']
                            ?.toString() ??
                        '0',
                  ) ??
                  0;

              final verified =
                  mitraData['is_verified'];

              isVerified =
                  verified == true ||
                  verified == 1 ||
                  verified
                          ?.toString() ==
                      '1' ||
                  verified
                          ?.toString()
                          .toLowerCase() ==
                      'true';
            });
          }
        }

      } catch (e) {

        debugPrint(
          "Gagal mengambil profil mitra: $e",
        );
      }

    } catch (e) {

      debugPrint(
        "Error load profile: $e",
      );

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

    String path =
        photoUrl!.trim();

    // =======================================================
    // JIKA SUDAH URL LENGKAP
    // =======================================================

    if (path.startsWith('http://') ||
        path.startsWith('https://')) {

      return path;
    }

    // =======================================================
    // HAPUS SLASH DI DEPAN
    // =======================================================

    if (path.startsWith('/')) {

      path =
          path.substring(1);
    }

    // =======================================================
    // AMBIL NAMA FILE
    //
    // profile_photos/xxx.jpg
    //
    // menjadi:
    //
    // xxx.jpg
    // =======================================================

    final filename =
        path.split('/').last;

    if (filename.isEmpty) {
      return null;
    }

    // =======================================================
    // ENDPOINT GAMBAR PROFILE
    // =======================================================

    return
        'http://127.0.0.1:8000/api/images/profile/$filename';
  }

  // =========================================================
  // PILIH FOTO
  // =========================================================

  Future<void> pickProfilePhoto() async {

    try {

      final html.FileUploadInputElement
          uploadInput =
          html.FileUploadInputElement();

      uploadInput.accept =
          'image/*';

      uploadInput.click();

      uploadInput.onChange.listen(
        (event) async {

          final files =
              uploadInput.files;

          if (files == null ||
              files.isEmpty) {

            debugPrint(
              "Tidak ada file yang dipilih.",
            );

            return;
          }

          final file =
              files.first;

          debugPrint(
            "====================================",
          );

          debugPrint(
            "FILE FOTO MITRA DIPILIH",
          );

          debugPrint(
            "Nama: ${file.name}",
          );

          debugPrint(
            "Type: ${file.type}",
          );

          debugPrint(
            "Size: ${file.size}",
          );

          debugPrint(
            "====================================",
          );

          // =================================================
          // VALIDASI IMAGE
          // =================================================

          if (!file.type.startsWith('image/')) {

            if (!mounted) return;

            ScaffoldMessenger.of(context)
                .showSnackBar(
              const SnackBar(
                content: Text(
                  "File yang dipilih harus berupa gambar.",
                ),
              ),
            );

            return;
          }

          // =================================================
          // BACA FILE
          // =================================================

          final reader =
              html.FileReader();

          reader.readAsArrayBuffer(file);

          reader.onLoadEnd.listen(
            (event) async {

              try {

                if (reader.result == null) {

                  debugPrint(
                    "FileReader result kosong.",
                  );

                  return;
                }

                // =================================================
                // FLUTTER WEB
                // =================================================

                final Uint8List bytes =
                    reader.result as Uint8List;

                debugPrint(
                  "====================================",
                );

                debugPrint(
                  "FILE BERHASIL DIBACA",
                );

                debugPrint(
                  "Nama: ${file.name}",
                );

                debugPrint(
                  "Bytes: ${bytes.length}",
                );

                debugPrint(
                  "====================================",
                );

                if (!mounted) return;

                // =================================================
                // PREVIEW
                // =================================================

                setState(() {

                  selectedPhotoBytes =
                      bytes;

                  selectedPhotoName =
                      file.name;
                });

                // =================================================
                // UPLOAD
                // =================================================

                await uploadProfilePhoto();

              } catch (e) {

                debugPrint(
                  "Gagal membaca file: $e",
                );

                if (!mounted) return;

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Gagal membaca foto.",
                    ),
                  ),
                );
              }
            },
          );
        },
      );

    } catch (e) {

      debugPrint(
        "Error pilih foto: $e",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Gagal memilih foto.",
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

      debugPrint(
        "Foto belum tersedia untuk diupload.",
      );

      return;
    }

    try {

      if (!mounted) return;

      setState(() {
        isUploadingPhoto = true;
      });

      // =======================================================
      // TOKEN
      // =======================================================

      final token =
          await getToken();

      debugPrint(
        "Token tersedia: ${token.isNotEmpty}",
      );

      if (token.isEmpty) {

        if (!mounted) return;

        setState(() {
          isUploadingPhoto = false;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Token login tidak ditemukan.",
            ),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      // =======================================================
      // REQUEST
      // =======================================================

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

      // =======================================================
      // FORM DATA
      // =======================================================

      final formData =
          html.FormData();

      String mimeType =
          'image/jpeg';

      final lowerName =
          selectedPhotoName!
              .toLowerCase();

      if (lowerName.endsWith('.png')) {

        mimeType =
            'image/png';

      } else if (lowerName.endsWith('.webp')) {

        mimeType =
            'image/webp';

      } else if (lowerName.endsWith('.jpg') ||
          lowerName.endsWith('.jpeg')) {

        mimeType =
            'image/jpeg';
      }

      final blob =
          html.Blob(
        [selectedPhotoBytes!],
        mimeType,
      );

      formData.appendBlob(
        'photo_profile',
        blob,
        selectedPhotoName!,
      );

      // =======================================================
      // DEBUG
      // =======================================================

      debugPrint(
        "====================================",
      );

      debugPrint(
        "UPLOAD FOTO PROFIL MITRA",
      );

      debugPrint(
        "Nama file: $selectedPhotoName",
      );

      debugPrint(
        "Ukuran: ${selectedPhotoBytes!.length} bytes",
      );

      debugPrint(
        "MIME: $mimeType",
      );

      debugPrint(
        "Endpoint: POST /api/user/profile/photo",
      );

      debugPrint(
        "====================================",
      );

      // =======================================================
      // RESPONSE
      // =======================================================

      request.onLoad.listen(
        (event) async {

          debugPrint(
            "====================================",
          );

          debugPrint(
            "UPLOAD SELESAI",
          );

          debugPrint(
            "STATUS: ${request.status}",
          );

          debugPrint(
            "RESPONSE: ${request.responseText}",
          );

          debugPrint(
            "====================================",
          );

          // ===================================================
          // BERHASIL
          // ===================================================

          if (request.status == 200) {

            try {

              final responseData =
                  jsonDecode(
                request.responseText ??
                    '{}',
              );

              debugPrint(
                "UPLOAD JSON: $responseData",
              );

              // =================================================
              // PHOTO URL
              // =================================================

              String? returnedPhotoUrl;

              if (responseData['photo_url'] !=
                  null) {

                returnedPhotoUrl =
                    responseData[
                            'photo_url']
                        .toString();
              }

              // =================================================
              // PHOTO URL DARI USER
              // =================================================

              final responseUser =
                  responseData['user'];

              if (responseUser is Map &&
                  responseUser[
                          'photo_url'] !=
                      null) {

                returnedPhotoUrl =
                    responseUser[
                            'photo_url']
                        .toString();
              }

              debugPrint(
                "PHOTO URL DARI BACKEND: "
                "$returnedPhotoUrl",
              );

              if (!mounted) return;

              // =================================================
              // UPDATE STATE
              // =================================================

              setState(() {

                if (returnedPhotoUrl !=
                        null &&
                    returnedPhotoUrl
                        .trim()
                        .isNotEmpty &&
                    returnedPhotoUrl !=
                        'null') {

                  photoUrl =
                      returnedPhotoUrl;
                }

                // Jangan hapus selectedPhotoBytes.
                //
                // Foto baru langsung tampil
                // menggunakan MemoryImage.

                isUploadingPhoto =
                    false;
              });

              // =================================================
              // UPDATE SIDEBAR / PARENT
              // =================================================

              widget.onProfileUpdate();

              if (!mounted) return;

              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text(
                    "Foto profil berhasil diperbarui.",
                  ),
                  backgroundColor:
                      Colors.green,
                ),
              );

            } catch (e) {

              debugPrint(
                "Error membaca response upload: $e",
              );

              if (!mounted) return;

              setState(() {
                isUploadingPhoto =
                    false;
              });

              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text(
                    "Foto berhasil diupload, tetapi response server tidak dapat dibaca.",
                  ),
                ),
              );
            }

          } else {

            // =================================================
            // UPLOAD GAGAL
            // =================================================

            debugPrint(
              "====================================",
            );

            debugPrint(
              "UPLOAD FOTO GAGAL",
            );

            debugPrint(
              "STATUS: ${request.status}",
            );

            debugPrint(
              "RESPONSE: ${request.responseText}",
            );

            debugPrint(
              "====================================",
            );

            if (!mounted) return;

            setState(() {
              isUploadingPhoto =
                  false;
            });

            ScaffoldMessenger.of(context)
                .showSnackBar(
              SnackBar(
                content: Text(
                  "Gagal upload foto. Status: ${request.status}",
                ),
                backgroundColor:
                    Colors.red,
              ),
            );
          }
        },
      );

      // =======================================================
      // NETWORK ERROR
      // =======================================================

      request.onError.listen(
        (event) {

          debugPrint(
            "Network error saat upload foto.",
          );

          if (!mounted) return;

          setState(() {
            isUploadingPhoto =
                false;
          });

          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                "Tidak dapat terhubung ke server.",
              ),
              backgroundColor:
                  Colors.red,
            ),
          );
        },
      );

      // =======================================================
      // SEND
      // =======================================================

      request.send(formData);

    } catch (e) {

      debugPrint(
        "Exception upload foto: $e",
      );

      if (!mounted) return;

      setState(() {
        isUploadingPhoto =
            false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Terjadi kesalahan saat upload foto.",
          ),
          backgroundColor:
              Colors.red,
          ),
      );
    }
  }

  // =========================================================
  // TOKEN
  // =========================================================

  Future<String> getToken() async {

    final prefs =
        await SharedPreferences
            .getInstance();

    return prefs.getString('token') ??
        '';
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

    try {

      final response =
          await ApiService.put(
        '/user/profile',
        {
          'name': newName,
          'email': newEmail,
          'phone': newPhone,
          'address': newAddress,
        },
      );

      if (response.statusCode == 200) {

        await loadProfileFromApi();

        widget.onProfileUpdate();

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Profil berhasil diperbarui.",
            ),
            backgroundColor:
                Colors.green,
          ),
        );

      } else {

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Gagal memperbarui profil.",
            ),
            backgroundColor:
                Colors.red,
          ),
        );
      }

    } catch (e) {

      debugPrint(
        "Error update profile: $e",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Terjadi kesalahan saat memperbarui profil.",
          ),
          backgroundColor:
              Colors.red,
        ),
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
          'is_notification_enabled':
              value ? 1 : 0,
        },
      );

    } catch (e) {

      debugPrint(
        "Error update notification: $e",
      );
    }
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
            color:
                Color(0xffF97316),
          ),
        ),
      );
    }

    final fullPhotoUrl =
        getFullPhotoUrl();

    return Scaffold(
      backgroundColor:
          const Color(0xffF8FAFC),

      body:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(30),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // =================================================
            // HEADER
            // =================================================

            const Text(
              "Pengaturan",

              style: TextStyle(
                fontSize: 34,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              "Kelola profil, notifikasi, dan keamanan akun.",

              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(
              height: 35,
            ),

            // =================================================
            // PROFILE HEADER
            // =================================================

            Center(
              child: Column(
                children: [

                  // =================================================
                  // PROFILE PHOTO
                  // =================================================

                  Stack(
                    alignment:
                        Alignment.bottomRight,

                    children: [

                      CircleAvatar(
                        radius: 55,

                        backgroundColor:
                            const Color(
                          0xffFFF3E8,
                        ),

                        // =================================================
                        // FOTO BARU PRIORITAS
                        // DATABASE FALLBACK
                        // =================================================

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
                                    size: 60,
                                    color:
                                        Color(
                                      0xffF97316,
                                    ),
                                  )
                                : null,
                      ),

                      // =================================================
                      // CAMERA
                      // =================================================

                      Container(
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xffF97316,
                          ),

                          shape:
                              BoxShape.circle,

                          border:
                              Border.all(
                            color:
                                Colors.white,
                            width: 3,
                          ),
                        ),

                        child:
                            IconButton(
                          icon:
                              isUploadingPhoto
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
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
                                          .camera_alt,
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

                  const SizedBox(
                    height: 18,
                  ),

                  // =================================================
                  // NAME
                  // =================================================

                  Text(
                    name,

                    style:
                        const TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  // =================================================
                  // EMAIL
                  // =================================================

                  Text(
                    email,

                    style:
                        TextStyle(
                      color:
                          Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // =================================================
                  // EDIT PROFILE
                  // =================================================

                  SizedBox(
                    width: 170,
                    height: 45,

                    child:
                        ElevatedButton.icon(
                      onPressed: () {

                        final nameController =
                            TextEditingController(
                          text: name,
                        );

                        final emailController =
                            TextEditingController(
                          text: email,
                        );

                        final phoneController =
                            TextEditingController(
                          text: phone,
                        );

                        final addressController =
                            TextEditingController(
                          text: address,
                        );

                        showDialog(
                          context:
                              context,

                          builder:
                              (dialogContext) {

                            return AlertDialog(

                              title:
                                  const Text(
                                "Edit Profil",
                              ),

                              content:
                                  SizedBox(
                                width: 450,

                                child:
                                    SingleChildScrollView(
                                  child:
                                      Column(
                                    mainAxisSize:
                                        MainAxisSize.min,

                                    children: [

                                      // =================================
                                      // FOTO PROFILE DI DIALOG
                                      // =================================

                                      Stack(
                                        alignment:
                                            Alignment.bottomRight,

                                        children: [

                                          CircleAvatar(
                                            radius: 50,

                                            backgroundColor:
                                                const Color(
                                              0xffFFF3E8,
                                            ),

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
                                                            Color(
                                                          0xffF97316,
                                                        ),
                                                      )
                                                    : null,
                                          ),

                                          Container(
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
                                                IconButton(
                                              icon:
                                                  const Icon(
                                                Icons
                                                    .camera_alt,
                                                color:
                                                    Colors.white,
                                                size: 18,
                                              ),

                                              onPressed:
                                                  () async {

                                                Navigator
                                                    .pop(
                                                  dialogContext,
                                                );

                                                await pickProfilePhoto();
                                              },
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(
                                        height: 20,
                                      ),

                                      // =================================
                                      // NAMA
                                      // =================================

                                      TextField(
                                        controller:
                                            nameController,

                                        decoration:
                                            const InputDecoration(
                                          labelText:
                                              "Nama",

                                          prefixIcon:
                                              Icon(
                                            Icons
                                                .person_outline,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 15,
                                      ),

                                      // =================================
                                      // EMAIL
                                      // =================================

                                      TextField(
                                        controller:
                                            emailController,

                                        decoration:
                                            const InputDecoration(
                                          labelText:
                                              "Email",

                                          prefixIcon:
                                              Icon(
                                            Icons
                                                .email_outlined,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 15,
                                      ),

                                      // =================================
                                      // PHONE
                                      // =================================

                                      TextField(
                                        controller:
                                            phoneController,

                                        decoration:
                                            const InputDecoration(
                                          labelText:
                                              "Nomor HP",

                                          prefixIcon:
                                              Icon(
                                            Icons
                                                .phone_outlined,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 15,
                                      ),

                                      // =================================
                                      // ADDRESS
                                      // =================================

                                      TextField(
                                        controller:
                                            addressController,

                                        maxLines: 2,

                                        decoration:
                                            const InputDecoration(
                                          labelText:
                                              "Alamat",

                                          prefixIcon:
                                              Icon(
                                            Icons
                                                .location_on_outlined,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              actions: [

                                // =================================
                                // BATAL
                                // =================================

                                TextButton(
                                  onPressed: () {

                                    Navigator
                                        .pop(
                                      dialogContext,
                                    );
                                  },

                                  child:
                                      const Text(
                                    "Batal",
                                  ),
                                ),

                                // =================================
                                // SIMPAN
                                // =================================

                                ElevatedButton(
                                  style:
                                      ElevatedButton
                                          .styleFrom(
                                    backgroundColor:
                                        const Color(
                                      0xffF97316,
                                    ),

                                    foregroundColor:
                                        Colors.white,
                                  ),

                                  onPressed:
                                      () async {

                                    Navigator
                                        .pop(
                                      dialogContext,
                                    );

                                    await updateProfileToApi(
                                      nameController
                                          .text,

                                      emailController
                                          .text,

                                      phoneController
                                          .text,

                                      addressController
                                          .text,
                                    );
                                  },

                                  child:
                                      const Text(
                                    "Simpan",
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },

                      icon:
                          const Icon(
                        Icons.edit,
                      ),

                      label:
                          const Text(
                        "Edit Profil",
                      ),

                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            const Color(
                          0xffF97316,
                        ),

                        foregroundColor:
                            Colors.white,

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 40,
            ),

            // =================================================
            // INFORMASI AKUN
            // =================================================

            const Text(
              "Informasi Akun",

              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 20,
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            _buildCard(
              icon:
                  Icons.person_outline,
              title:
                  "Nama",
              subtitle:
                  name,
            ),

            _buildCard(
              icon:
                  Icons.email_outlined,
              title:
                  "Email",
              subtitle:
                  email,
            ),

            _buildCard(
              icon:
                  Icons.phone_outlined,
              title:
                  "Nomor HP",
              subtitle:
                  phone.isEmpty
                      ? "-"
                      : phone,
            ),

            _buildCard(
              icon:
                  Icons.location_on_outlined,
              title:
                  "Alamat",
              subtitle:
                  address.isEmpty
                      ? "-"
                      : address,
            ),

            const SizedBox(
              height: 35,
            ),

            // =================================================
            // NOTIFIKASI
            // =================================================

            const Text(
              "Notifikasi",

              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 20,
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            Card(
              elevation: 0,

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),

                side:
                    const BorderSide(
                  color:
                      Color(0xffE5E7EB),
                ),
              ),

              child:
                  SwitchListTile(
                value:
                    jobNotification,

                activeColor:
                    const Color(
                  0xffF97316,
                ),

                secondary:
                    const Icon(
                  Icons
                      .notifications_active_outlined,

                  color:
                      Color(
                    0xffF97316,
                  ),
                ),

                title:
                    const Text(
                  "Notifikasi Penawaran",
                ),

                subtitle:
                    const Text(
                  "Terima notifikasi ketika "
                  "mitra mengirim penawaran "
                  "pada pekerjaan Anda.",
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

                  if (!mounted) return;

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    SnackBar(
                      content:
                          Text(
                        value
                            ? "Notifikasi penawaran diaktifkan."
                            : "Notifikasi penawaran dinonaktifkan.",
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(
              height: 35,
            ),

            // =================================================
            // KEAMANAN
            // =================================================

            const Text(
              "Keamanan",

              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 20,
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            Card(
              elevation: 0,

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),

                side:
                    const BorderSide(
                  color:
                      Color(0xffE5E7EB),
                ),
              ),

              child:
                  Column(
                children: [

                  ListTile(

                    leading:
                        const Icon(
                      Icons.logout,
                      color:
                          Colors.red,
                    ),

                    title:
                        const Text(
                      "Logout",

                      style:
                          TextStyle(
                        color:
                            Colors.red,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    trailing:
                        const Icon(
                      Icons
                          .chevron_right,
                    ),

                    onTap: () {

                      showDialog(
                        context:
                            context,

                        builder:
                            (dialogContext) {

                          return AlertDialog(

                            title:
                                const Text(
                              "Logout",
                            ),

                            content:
                                const Text(
                              "Apakah Anda yakin "
                              "ingin keluar dari "
                              "akun ini?",
                            ),

                            actions: [

                              TextButton(
                                onPressed: () {

                                  Navigator
                                      .pop(
                                    dialogContext,
                                  );
                                },

                                child:
                                    const Text(
                                  "Batal",
                                ),
                              ),

                              ElevatedButton(
                                style:
                                    ElevatedButton
                                        .styleFrom(
                                  backgroundColor:
                                      Colors.red,

                                  foregroundColor:
                                      Colors.white,
                                ),

                                onPressed:
                                    () async {

                                  final prefs =
                                      await SharedPreferences
                                          .getInstance();

                                  await prefs.clear();

                                  if (!mounted)
                                    return;

                                  Navigator
                                      .pushAndRemoveUntil(
                                    context,

                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                              const LandingPage(),
                                    ),

                                    (route) =>
                                        false,
                                  );
                                },

                                child:
                                    const Text(
                                  "Logout",
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 40,
            ),
          ],
        ),
      ),
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
      padding:
          const EdgeInsets.only(
        bottom: 15,
      ),

      child: Card(
        elevation: 0,

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),

          side:
              const BorderSide(
            color:
                Color(0xffE5E7EB),
          ),
        ),

        child:
            ListTile(

          leading:
              Icon(
            icon,

            color:
                const Color(
              0xffF97316,
            ),
          ),

          title:
              Text(
            title,
          ),

          subtitle:
              Text(
            subtitle,
          ),
        ),
      ),
    );
  }
}