import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:latlong2/latlong.dart';

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

  // Alamat otomatis dari OpenStreetMap
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

  String _kategori = "Service AC";

  // =========================================================
  // KOORDINAT
  // =========================================================

  double? _latitude;
  double? _longitude;

  // =========================================================
  // KATEGORI
  // =========================================================

  final List<String> kategoriList = [
    "Service AC",
    "Plumbing",
    "Listrik",
    "Cat Rumah",
    "Kebersihan",
    "Lainnya",
  ];

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Gagal memilih foto: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // PILIH LOKASI
  // =========================================================

  Future<void> _pickLocation() async {
    // -------------------------------------------------------
    // Posisi awal
    // -------------------------------------------------------
    //
    // Kalau sebelumnya sudah memilih lokasi,
    // gunakan lokasi tersebut.
    //
    // Kalau belum ada lokasi, gunakan titik default.
    //
    // Indonesia berada di sekitar koordinat ini.
    //

    final LatLng initialPosition = LatLng(
      _latitude ?? -7.7956,
      _longitude ?? 110.3695,
    );

    // -------------------------------------------------------
    // Buka MapPickerDialog
    // -------------------------------------------------------

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return MapPickerDialog(
          initialPosition: initialPosition,
        );
      },
    );

    // User menutup dialog
    if (result == null) return;

    // -------------------------------------------------------
    // Ambil data dari MapPickerDialog
    // -------------------------------------------------------

    final dynamic positionData = result["position"];

    if (positionData is! LatLng) {
      return;
    }

    final LatLng selectedPosition = positionData;

    final String address =
        result["address"]?.toString() ?? "";

    // -------------------------------------------------------
    // Simpan lokasi
    // -------------------------------------------------------

    if (!mounted) return;

    setState(() {
      _latitude = selectedPosition.latitude;
      _longitude = selectedPosition.longitude;

      _lokasiController.text = address;
    });
  }

  // =========================================================
  // RESET LOKASI
  // =========================================================

  void _resetLocation() {
    setState(() {
      _latitude = null;
      _longitude = null;

      _lokasiController.clear();
    });
  }

  // =========================================================
  // POSTING JASA
  // =========================================================

  Future<void> _postingJasa() async {
    // -------------------------------------------------------
    // VALIDASI FORM
    // -------------------------------------------------------

    if (_judulController.text.trim().isEmpty) {
      _showMessage(
        "Judul jasa wajib diisi.",
      );

      return;
    }

    if (_deskripsiController.text.trim().isEmpty) {
      _showMessage(
        "Deskripsi jasa wajib diisi.",
      );

      return;
    }

    if (_budgetController.text.trim().isEmpty) {
      _showMessage(
        "Budget wajib diisi.",
      );

      return;
    }

    if (_latitude == null || _longitude == null) {
      _showMessage(
        "Silakan pilih lokasi pekerjaan pada peta.",
      );

      return;
    }

    if (_lokasiController.text.trim().isEmpty) {
      _showMessage(
        "Alamat lokasi belum ditemukan.",
      );

      return;
    }

    if (_detailAlamatController.text.trim().isEmpty) {
      _showMessage(
        "Detail alamat wajib diisi.",
      );

      return;
    }

    // -------------------------------------------------------
    // SUBMIT
    // -------------------------------------------------------

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

      debugPrint("----------------------------------------");
      debugPrint("TOKEN DIKIRIM: '$token'");
      debugPrint("----------------------------------------");

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
      // BUDGET
      // =====================================================

      final rawBudget = _budgetController.text
          .replaceAll('Rp', '')
          .replaceAll('.', '')
          .replaceAll(',', '')
          .replaceAll(' ', '')
          .trim();

      // =====================================================
      // REQUEST
      // =====================================================

      final uri = Uri.parse(
        '${ApiService.baseUrl}/jobs',
      );

      final request = http.MultipartRequest(
        'POST',
        uri,
      );

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

      // Koordinat OpenStreetMap
      request.fields['latitude'] =
          _latitude!.toString();

      request.fields['longitude'] =
          _longitude!.toString();

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

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Gagal membuat pekerjaan. "
            "Status: ${response.statusCode}",
          ),
          backgroundColor: Colors.red,
        ),
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

    final isMobile = screenWidth < 600;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
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
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              // =================================================
              // JUDUL
              // =================================================

              const Text(
                "Judul Jasa",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _judulController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  hintText:
                      "Contoh: Service AC Bocor",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // KATEGORI
              // =================================================

              const Text(
                "Kategori",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: _kategori,
                decoration:
                    const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: kategoriList.map((e) {
                  return DropdownMenuItem<String>(
                    value: e,
                    child: Text(e),
                  );
                }).toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _kategori = value;
                        });
                      },
              ),

              const SizedBox(height: 20),

              // =================================================
              // DESKRIPSI
              // =================================================

              const Text(
                "Deskripsi",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                    _deskripsiController,
                enabled: !_isSubmitting,
                maxLines: 4,
                decoration:
                    const InputDecoration(
                  hintText:
                      "Jelaskan masalah secara detail...",
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // BUDGET
              // =================================================

              const Text(
                "Budget",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                    _budgetController,
                enabled: !_isSubmitting,
                keyboardType:
                    TextInputType.number,
                inputFormatters: [
                  CurrencyInputFormatter(
                    leadingSymbol: "Rp ",
                    thousandSeparator:
                        ThousandSeparator.Period,
                    mantissaLength: 0,
                  ),
                ],
                decoration:
                    const InputDecoration(
                  hintText: "Rp 0",
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // LOKASI
              // =================================================

              const Text(
                "Lokasi Pekerjaan",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              InkWell(
                onTap: _isSubmitting
                    ? null
                    : _pickLocation,
                borderRadius:
                    BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: _latitude != null
                        ? Colors.green
                            .withOpacity(0.05)
                        : Colors.transparent,
                    border: Border.all(
                      color: _latitude != null
                          ? Colors.green
                          : Colors.grey.shade400,
                    ),
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _latitude != null
                            ? Icons
                                .check_circle_outline
                            : Icons
                                .location_on_outlined,
                        color: _latitude != null
                            ? Colors.green
                            : Colors.grey.shade700,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              _latitude != null
                                  ? "Lokasi berhasil dipilih"
                                  : "Pilih lokasi dari peta",
                              style: TextStyle(
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

                            const SizedBox(height: 3),

                            Text(
                              _latitude != null
                                  ? "OpenStreetMap"
                                  : "Tentukan titik lokasi pekerjaan",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors
                                    .grey
                                    .shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Icon(
                        Icons.chevron_right,
                      ),
                    ],
                  ),
                ),
              ),

              // =================================================
              // ALAMAT OTOMATIS
              // =================================================

              if (_latitude != null) ...[
                const SizedBox(height: 16),

                const Text(
                  "Alamat",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller:
                      _lokasiController,
                  readOnly: true,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(
                    prefixIcon: Icon(
                      Icons.map_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                    filled: true,
                  ),
                ),

                const SizedBox(height: 6),

                // =================================================
                // KOORDINAT
                // =================================================

                Text(
                  "Koordinat: "
                  "${_latitude!.toStringAsFixed(6)}, "
                  "${_longitude!.toStringAsFixed(6)}",
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 8),

                // =================================================
                // UBAH LOKASI
                // =================================================

                TextButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : _pickLocation,
                  icon: const Icon(
                    Icons.edit_location_alt_outlined,
                    size: 18,
                  ),
                  label: const Text(
                    "Ubah lokasi",
                  ),
                ),

                const SizedBox(height: 10),

                // =================================================
                // DETAIL ALAMAT MANUAL
                // =================================================

                const Text(
                  "Detail Alamat",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller:
                      _detailAlamatController,
                  enabled: !_isSubmitting,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(
                    hintText:
                        "Contoh: Rumah nomor 10, "
                        "pagar hitam, sebelah minimarket...",
                    prefixIcon:
                        Icon(Icons.home_outlined),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // =================================================
              // FOTO
              // =================================================

              const Text(
                "Foto Kendala (Opsional)",
              ),

              const SizedBox(height: 8),

              InkWell(
                onTap: _isSubmitting
                    ? null
                    : _pickImage,
                borderRadius:
                    BorderRadius.circular(14),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration:
                      BoxDecoration(
                    border: Border.all(
                      color:
                          Colors.grey.shade300,
                    ),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child:
                      _imageBytes == null
                          ? const Column(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                              children: [
                                Icon(
                                  Icons
                                      .cloud_upload_outlined,
                                  size: 40,
                                  color:
                                      Colors.grey,
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  "Klik untuk upload foto",
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.grey,
                                  ),
                                ),
                              ],
                            )
                          : ClipRRect(
                              borderRadius:
                                  BorderRadius
                                      .circular(14),
                              child:
                                  Image.memory(
                                _imageBytes!,
                                fit: BoxFit.cover,
                                width:
                                    double.infinity,
                              ),
                            ),
                ),
              ),

              const SizedBox(height: 30),

              // =================================================
              // BUTTON
              // =================================================

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSubmitting
                              ? null
                              : () {
                                  Navigator.pop(
                                    context,
                                  );
                                },
                      child:
                          const Text("Batal"),
                    ),
                  ),

                  const SizedBox(width: 18),

                  Expanded(
                    flex: 2,
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          _isSubmitting
                              ? null
                              : _postingJasa,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                color:
                                    Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons
                                  .rocket_launch,
                            ),
                      label: Text(
                        _isSubmitting
                            ? "Memproses..."
                            : "Posting Sekarang",
                      ),
                      style:
                          ElevatedButton.styleFrom(
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