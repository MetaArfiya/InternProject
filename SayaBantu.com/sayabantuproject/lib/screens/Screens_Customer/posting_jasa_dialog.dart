import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/job_model.dart';
import '../../services/api_service.dart';
import '../../screens/Screens_Customer/map_picker_screen.dart';

class PostingJasaDialog extends StatefulWidget {
  const PostingJasaDialog({super.key});

  @override
  State<PostingJasaDialog> createState() => _PostingJasaDialogState();
}

class _PostingJasaDialogState extends State<PostingJasaDialog> {
  // =========================================================
  // CONTROLLER
  // =========================================================

  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _budgetController = TextEditingController();

  // Alamat otomatis dari MapPicker / OpenStreetMap
  final _lokasiController = TextEditingController();

  // Detail alamat yang ditulis manual
  final _detailAlamatController = TextEditingController();

  // =========================================================
  // FOTO
  // =========================================================

  XFile? _pickedFile;
  Uint8List? _imageBytes;

  // =========================================================
  // STATE
  // =========================================================

  bool _isSubmitting = false;

  // =========================================================
  // KATEGORI
  // =========================================================

  String _kategori = "Perbaikan & Perawatan Rumah";

  final List<String> kategoriList = [
    "Perbaikan & Perawatan Rumah",
    "Kebersihan",
    "Konstruksi & Renovasi",
    "Instalasi & Teknisi",
    "Jasa Rumah Tangga",
    "Jasa Umum",
    "Lainnya",
  ];

  // =========================================================
  // KOORDINAT
  // =========================================================

  double? _latitude;
  double? _longitude;

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _budgetController.dispose();
    _lokasiController.dispose();
    _detailAlamatController.dispose();

    super.dispose();
  }

  // =========================================================
  // PILIH FOTO
  // =========================================================

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();

      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _pickedFile = image;
        _imageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        "Gagal memilih foto: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  // =========================================================
  // CEK DAN AMBIL GPS
  // =========================================================

  Future<LatLng?> _getCurrentLocation() async {
    try {
      // -------------------------------------------------------
      // CEK SERVICE GPS
      // -------------------------------------------------------

      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return null;

        _showMessage(
          "GPS/lokasi sedang tidak aktif. Silakan aktifkan lokasi.",
          backgroundColor: Colors.orange,
        );

        return null;
      }

      // -------------------------------------------------------
      // CEK PERMISSION
      // -------------------------------------------------------

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return null;

        _showMessage(
          "Izin lokasi diperlukan untuk menentukan lokasi pekerjaan.",
          backgroundColor: Colors.orange,
        );

        return null;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return null;

        _showMessage(
          "Izin lokasi ditolak permanen. Silakan aktifkan izin lokasi dari pengaturan perangkat.",
          backgroundColor: Colors.orange,
        );

        return null;
      }

      // -------------------------------------------------------
      // AMBIL POSISI GPS
      // -------------------------------------------------------

      final Position currentPosition =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      debugPrint(
        "========================================",
      );

      debugPrint(
        "GPS SAAT INI:",
      );

      debugPrint(
        "Latitude : ${currentPosition.latitude}",
      );

      debugPrint(
        "Longitude: ${currentPosition.longitude}",
      );

      debugPrint(
        "========================================",
      );

      return LatLng(
        currentPosition.latitude,
        currentPosition.longitude,
      );
    } catch (e) {
      debugPrint(
        "ERROR GPS: $e",
      );

      if (!mounted) return null;

      _showMessage(
        "Gagal mendapatkan lokasi GPS: $e",
        backgroundColor: Colors.red,
      );

      return null;
    }
  }

  // =========================================================
  // PILIH LOKASI
  // =========================================================

  Future<void> _pickLocation() async {
    try {
      LatLng initialPosition;

      // =====================================================
      // 1. JIKA SUDAH PERNAH PILIH LOKASI
      // =====================================================

      if (_latitude != null && _longitude != null) {
        initialPosition = LatLng(
          _latitude!,
          _longitude!,
        );

        debugPrint(
          "Membuka map menggunakan lokasi yang sebelumnya dipilih:",
        );

        debugPrint(
          "$_latitude, $_longitude",
        );
      }

      // =====================================================
      // 2. JIKA BELUM ADA LOKASI, AMBIL GPS
      // =====================================================

      else {
        final LatLng? currentLocation =
            await _getCurrentLocation();

        if (currentLocation == null) {
          return;
        }

        initialPosition = currentLocation;

        debugPrint(
          "Map menggunakan lokasi GPS saat ini:",
        );

        debugPrint(
          "${initialPosition.latitude}, "
          "${initialPosition.longitude}",
        );
      }

      // =====================================================
      // 3. CEK CONTEXT
      // =====================================================

      if (!mounted) return;

      // =====================================================
      // 4. BUKA MAP PICKER
      // =====================================================

      final result =
          await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) {
          return MapPickerDialog(
            initialPosition: initialPosition,
          );
        },
      );

      // =====================================================
      // 5. USER MENUTUP MAP
      // =====================================================

      if (result == null) {
        return;
      }

      // =====================================================
      // 6. AMBIL POSITION
      // =====================================================

      final dynamic positionData =
          result["position"];

      if (positionData is! LatLng) {
        debugPrint(
          "Position dari MapPicker bukan LatLng.",
        );

        return;
      }

      final LatLng selectedPosition =
          positionData;

      // =====================================================
      // 7. AMBIL ALAMAT
      // =====================================================

      final String address =
          result["address"]?.toString().trim() ?? "";

      // =====================================================
      // 8. SIMPAN HASIL
      // =====================================================

      if (!mounted) return;

      setState(() {
        _latitude =
            selectedPosition.latitude;

        _longitude =
            selectedPosition.longitude;

        _lokasiController.text =
            address;
      });

      // =====================================================
      // DEBUG
      // =====================================================

      debugPrint(
        "========================================",
      );

      debugPrint(
        "LOKASI DIPILIH USER",
      );

      debugPrint(
        "Latitude : ${selectedPosition.latitude}",
      );

      debugPrint(
        "Longitude: ${selectedPosition.longitude}",
      );

      debugPrint(
        "Alamat   : $address",
      );

      debugPrint(
        "========================================",
      );
    } catch (e) {
      debugPrint(
        "ERROR MEMILIH LOKASI: $e",
      );

      if (!mounted) return;

      _showMessage(
        "Gagal membuka peta: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  // =========================================================
  // RESET LOKASI
  // =========================================================

  void _resetLocation() {
    setState(() {
      _latitude = null;
      _longitude = null;

      _lokasiController.clear();
      _detailAlamatController.clear();
    });
  }

  // =========================================================
  // POSTING JASA
  // =========================================================

  Future<void> _postingJasa() async {
    // =======================================================
    // VALIDASI JUDUL
    // =======================================================

    if (_judulController.text.trim().isEmpty) {
      _showMessage(
        "Judul jasa wajib diisi.",
      );

      return;
    }

    // =======================================================
    // VALIDASI DESKRIPSI
    // =======================================================

    if (_deskripsiController.text.trim().isEmpty) {
      _showMessage(
        "Deskripsi jasa wajib diisi.",
      );

      return;
    }

    // =======================================================
    // VALIDASI BUDGET
    // =======================================================

    if (_budgetController.text.trim().isEmpty) {
      _showMessage(
        "Budget wajib diisi.",
      );

      return;
    }

    // =======================================================
    // VALIDASI LOKASI
    // =======================================================

    if (_latitude == null ||
        _longitude == null) {
      _showMessage(
        "Silakan pilih lokasi pekerjaan pada peta.",
      );

      return;
    }

    // =======================================================
    // VALIDASI ALAMAT
    // =======================================================

    if (_lokasiController.text.trim().isEmpty) {
      _showMessage(
        "Alamat lokasi belum ditemukan.",
      );

      return;
    }

    // =======================================================
    // VALIDASI DETAIL ALAMAT
    // =======================================================

    if (_detailAlamatController.text.trim().isEmpty) {
      _showMessage(
        "Detail alamat wajib diisi.",
      );

      return;
    }

    // =======================================================
    // MULAI SUBMIT
    // =======================================================

    setState(() {
      _isSubmitting = true;
    });

    try {
      // =====================================================
      // TOKEN
      // =====================================================

      final prefs =
          await SharedPreferences.getInstance();

      final token =
          prefs.getString('auth_token') ??
          prefs.getString('token') ??
          '';

      debugPrint(
        "----------------------------------------",
      );

      debugPrint(
        "TOKEN DIKIRIM: '$token'",
      );

      debugPrint(
        "----------------------------------------",
      );

      // =====================================================
      // CEK TOKEN
      // =====================================================

      if (token.isEmpty) {
        if (!mounted) return;

        setState(() {
          _isSubmitting = false;
        });

        _showMessage(
          "Sesi telah berakhir, silakan login kembali.",
          backgroundColor: Colors.orange,
        );

        return;
      }

      // =====================================================
      // FORMAT BUDGET
      // =====================================================

      final rawBudget = _budgetController.text
          .replaceAll('Rp', '')
          .replaceAll('.', '')
          .replaceAll(',', '')
          .replaceAll(' ', '')
          .trim();

      // =====================================================
      // URL API
      // =====================================================

      final uri = Uri.parse(
        '${ApiService.baseUrl}/jobs',
      );

      // =====================================================
      // MULTIPART REQUEST
      // =====================================================

      final request = http.MultipartRequest(
        'POST',
        uri,
      );

      // =====================================================
      // HEADER
      // =====================================================

      request.headers['Accept'] =
          'application/json';

      request.headers['Authorization'] =
          'Bearer $token';

      // =====================================================
      // DATA PEKERJAAN
      // =====================================================

      request.fields['tittle'] =
          _judulController.text.trim();

      request.fields['description'] =
          _deskripsiController.text.trim();

      request.fields['initial_budget'] =
          rawBudget;

      // Alamat hasil reverse geocoding
      request.fields['location'] =
          _lokasiController.text.trim();

      // Detail alamat manual
      request.fields['address_detail'] =
          _detailAlamatController.text.trim();

      // =====================================================
      // KOORDINAT
      // =====================================================

      request.fields['latitude'] =
          _latitude!.toString();

      request.fields['longitude'] =
          _longitude!.toString();

      // =====================================================
      // KATEGORI
      // =====================================================

      request.fields['category'] =
          _kategori;

      // =====================================================
      // FOTO
      // =====================================================

      if (_pickedFile != null &&
          _imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            _imageBytes!,
            filename: _pickedFile!.name,
          ),
        );
      }

      // =====================================================
      // DEBUG DATA
      // =====================================================

      debugPrint(
        "========================================",
      );

      debugPrint(
        "DATA POSTING JASA",
      );

      debugPrint(
        "Judul      : ${_judulController.text.trim()}",
      );

      debugPrint(
        "Kategori   : $_kategori",
      );

      debugPrint(
        "Budget     : $rawBudget",
      );

      debugPrint(
        "Alamat     : ${_lokasiController.text.trim()}",
      );

      debugPrint(
        "Detail     : ${_detailAlamatController.text.trim()}",
      );

      debugPrint(
        "Latitude   : $_latitude",
      );

      debugPrint(
        "Longitude  : $_longitude",
      );

      debugPrint(
        "========================================",
      );

      // =====================================================
      // KIRIM REQUEST
      // =====================================================

      final streamedResponse =
          await request.send();

      final response =
          await http.Response.fromStream(
        streamedResponse,
      );

      debugPrint(
        "RESPONSE STATUS: ${response.statusCode}",
      );

      debugPrint(
        "RESPONSE BODY: ${response.body}",
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      // =====================================================
      // BERHASIL
      // =====================================================

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        try {
          final resData =
              jsonDecode(response.body);

          final jobJson =
              resData['data'] ?? resData;

          final JobModel createdJob =
              JobModel.fromJson(jobJson);

          if (!mounted) return;

          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                "Posting jasa berhasil dibuat.",
              ),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(
            context,
            createdJob,
          );
        } catch (e) {
          debugPrint(
            "Gagal parsing JobModel: $e",
          );

          if (!mounted) return;

          Navigator.pop(context);
        }

        return;
      }

      // =====================================================
      // GAGAL
      // =====================================================

      if (!mounted) return;

      _showMessage(
        "Gagal membuat pekerjaan. "
        "Status: ${response.statusCode}",
        backgroundColor: Colors.red,
      );
    } catch (e) {
      debugPrint(
        "ERROR POSTING JASA: $e",
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      _showMessage(
        "Terjadi kesalahan: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  // =========================================================
  // SNACKBAR
  // =========================================================

  void _showMessage(
    String message, {
    Color? backgroundColor,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.of(context).size.width;

    final isMobile =
        screenWidth < 600;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Container(
        width: isMobile
            ? screenWidth - 30
            : 650,
        padding: EdgeInsets.all(
          isMobile ? 18 : 28,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // =================================================
              // TITLE
              // =================================================

              const Text(
                "Posting Jasa Baru",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              // =================================================
              // JUDUL
              // =================================================

              const Text(
                "Judul Jasa",
                style: TextStyle(
                  fontWeight:
                      FontWeight.w500,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              TextField(
                controller:
                    _judulController,
                enabled:
                    !_isSubmitting,
                decoration:
                    const InputDecoration(
                  hintText:
                      "Contoh: Perbaikan AC Bocor",
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // =================================================
              // KATEGORI
              // =================================================

              const Text(
                "Kategori",
                style: TextStyle(
                  fontWeight:
                      FontWeight.w500,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              DropdownButtonFormField<String>(
                value: _kategori,
                isExpanded: true,
                decoration:
                    const InputDecoration(
                  border:
                      OutlineInputBorder(),
                  hintText:
                      "Pilih kategori jasa",
                ),
                items:
                    kategoriList.map(
                  (e) {
                    return DropdownMenuItem<
                        String>(
                      value: e,
                      child:
                          Text(e),
                    );
                  },
                ).toList(),
                onChanged:
                    _isSubmitting
                        ? null
                        : (value) {
                            if (value ==
                                null) {
                              return;
                            }

                            setState(() {
                              _kategori =
                                  value;
                            });
                          },
              ),

              const SizedBox(
                height: 20,
              ),

              // =================================================
              // DESKRIPSI
              // =================================================

              const Text(
                "Deskripsi",
                style: TextStyle(
                  fontWeight:
                      FontWeight.w500,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              TextField(
                controller:
                    _deskripsiController,
                enabled:
                    !_isSubmitting,
                maxLines: 4,
                decoration:
                    const InputDecoration(
                  hintText:
                      "Jelaskan masalah atau kebutuhan jasa secara detail...",
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // =================================================
              // BUDGET
              // =================================================

              const Text(
                "Budget",
                style: TextStyle(
                  fontWeight:
                      FontWeight.w500,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              TextField(
                controller:
                    _budgetController,
                enabled:
                    !_isSubmitting,
                keyboardType:
                    TextInputType.number,
                inputFormatters: [
                  CurrencyInputFormatter(
                    leadingSymbol:
                        "Rp ",
                    thousandSeparator:
                        ThousandSeparator
                            .Period,
                    mantissaLength:
                        0,
                  ),
                ],
                decoration:
                    const InputDecoration(
                  hintText:
                      "Rp 0",
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // =================================================
              // LOKASI
              // =================================================

              const Text(
                "Lokasi Pekerjaan",
                style: TextStyle(
                  fontWeight:
                      FontWeight.w500,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              InkWell(
                onTap:
                    _isSubmitting
                        ? null
                        : _pickLocation,
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
                child: Container(
                  width:
                      double.infinity,
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 14,
                    vertical: 15,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        _latitude !=
                                null
                            ? Colors
                                .green
                                .withOpacity(
                                0.05,
                              )
                            : Colors
                                .transparent,
                    border:
                        Border.all(
                      color:
                          _latitude !=
                                  null
                              ? Colors
                                  .green
                              : Colors
                                  .grey
                                  .shade400,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      10,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _latitude !=
                                null
                            ? Icons
                                .check_circle_outline
                            : Icons
                                .location_on_outlined,
                        color:
                            _latitude !=
                                    null
                                ? Colors
                                    .green
                                : Colors
                                    .grey
                                    .shade700,
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      Expanded(
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              _latitude !=
                                      null
                                  ? "Lokasi berhasil dipilih"
                                  : "Pilih lokasi dari peta",
                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight.w600,
                                color:
                                    _latitude !=
                                            null
                                        ? Colors
                                            .green
                                            .shade700
                                        : Colors
                                            .grey
                                            .shade800,
                              ),
                            ),

                            const SizedBox(
                              height: 3,
                            ),

                            Text(
                              _latitude !=
                                      null
                                  ? "OpenStreetMap"
                                  : "Tentukan titik lokasi pekerjaan",
                              style:
                                  TextStyle(
                                fontSize:
                                    12,
                                color: Colors
                                    .grey
                                    .shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Icon(
                        Icons
                            .chevron_right,
                      ),
                    ],
                  ),
                ),
              ),

              // =================================================
              // ALAMAT OTOMATIS
              // =================================================

              if (_latitude != null) ...[
                const SizedBox(
                  height: 16,
                ),

                const Text(
                  "Alamat",
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                TextField(
                  controller:
                      _lokasiController,
                  readOnly: true,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(
                    prefixIcon:
                        Icon(
                      Icons
                          .map_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                    filled: true,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                // =================================================
                // KOORDINAT
                // =================================================

                Text(
                  "Koordinat: "
                  "${_latitude!.toStringAsFixed(6)}, "
                  "${_longitude!.toStringAsFixed(6)}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors
                        .grey
                        .shade600,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                // =================================================
                // UBAH LOKASI
                // =================================================

                TextButton.icon(
                  onPressed:
                      _isSubmitting
                          ? null
                          : _pickLocation,
                  icon:
                      const Icon(
                    Icons
                        .edit_location_alt_outlined,
                    size: 18,
                  ),
                  label:
                      const Text(
                    "Ubah lokasi",
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                // =================================================
                // DETAIL ALAMAT
                // =================================================

                const Text(
                  "Detail Alamat",
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                TextField(
                  controller:
                      _detailAlamatController,
                  enabled:
                      !_isSubmitting,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(
                    hintText:
                        "Contoh: Rumah nomor 10, pagar hitam, sebelah minimarket...",
                    prefixIcon:
                        Icon(
                      Icons
                          .home_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
              ],

              const SizedBox(
                height: 20,
              ),

              // =================================================
              // FOTO
              // =================================================

              const Text(
                "Foto Kendala (Opsional)",
                style: TextStyle(
                  fontWeight:
                      FontWeight.w500,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              InkWell(
                onTap:
                    _isSubmitting
                        ? null
                        : _pickImage,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                child: Container(
                  height: 180,
                  width:
                      double.infinity,
                  decoration:
                      BoxDecoration(
                    border:
                        Border.all(
                      color: Colors
                          .grey
                          .shade300,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child:
                      _imageBytes ==
                              null
                          ? const Column(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                              children: [
                                Icon(
                                  Icons
                                      .cloud_upload_outlined,
                                  size:
                                      40,
                                  color:
                                      Colors
                                          .grey,
                                ),
                                SizedBox(
                                  height:
                                      10,
                                ),
                                Text(
                                  "Klik untuk upload foto",
                                  style:
                                      TextStyle(
                                    color:
                                        Colors
                                            .grey,
                                  ),
                                ),
                              ],
                            )
                          : ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                14,
                              ),
                              child:
                                  Image.memory(
                                _imageBytes!,
                                fit: BoxFit
                                    .cover,
                                width:
                                    double.infinity,
                              ),
                            ),
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              // =================================================
              // BUTTON
              // =================================================

              Row(
                children: [
                  Expanded(
                    child:
                        OutlinedButton(
                      onPressed:
                          _isSubmitting
                              ? null
                              : () {
                                  Navigator
                                      .pop(
                                    context,
                                  );
                                },
                      child:
                          const Text(
                        "Batal",
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 18,
                  ),

                  Expanded(
                    flex: 2,
                    child:
                        ElevatedButton
                            .icon(
                      onPressed:
                          _isSubmitting
                              ? null
                              : _postingJasa,
                      icon:
                          _isSubmitting
                              ? const SizedBox(
                                  width:
                                      18,
                                  height:
                                      18,
                                  child:
                                      CircularProgressIndicator(
                                    color:
                                        Colors.white,
                                    strokeWidth:
                                        2,
                                  ),
                                )
                              : const Icon(
                                  Icons
                                      .rocket_launch,
                                ),
                      label:
                          Text(
                        _isSubmitting
                            ? "Memproses..."
                            : "Posting Sekarang",
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
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 18,
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
  }
}