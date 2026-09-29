import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';

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
  final _kategoriLainnyaController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _detailAlamatController = TextEditingController();

  // =========================================================
  // FOTO
  // =========================================================

  XFile? _pickedFile;
  Uint8List? _imageBytes;

  static const int _maxImageSizeInBytes = 2097152; // 2 MB

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
  ];

  // =========================================================
  // WAKTU PENGERJAAN
  // =========================================================

  String _waktuPengerjaan = "1–2 Jam";
  final List<String> waktuPengerjaanList = [
    "1–2 Jam",
    "3–5 Jam",
    "1 Hari",
    "2–3 Hari",
    "1 Minggu",
    "> 1 Minggu",
  ];

  // =========================================================
  // KOORDINAT
  // =========================================================

  double? _latitude;
  double? _longitude;

  // =========================================================
  // DESIGN TOKENS
  // =========================================================

  static const Color _accent = Color(0xFFF97316);
  static const double _mobileBreakpoint = 700;

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _budgetController.dispose();
    _kategoriLainnyaController.dispose();
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

      final lowerName = image.name.toLowerCase();
      final allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
      final hasValidExtension =
          allowedExtensions.any((ext) => lowerName.endsWith(ext));

      if (!hasValidExtension) {
        if (!mounted) return;
        _showMessage(
          "Format foto harus JPG, JPEG, PNG, atau WEBP.",
          backgroundColor: Colors.red,
        );
        return;
      }

      final bytes = await image.readAsBytes();

      if (bytes.length > _maxImageSizeInBytes) {
        if (!mounted) return;
        final sizeMb = (bytes.length / 1024 / 1024).toStringAsFixed(2);
        _showMessage(
          "Ukuran foto terlalu besar ($sizeMb MB). Maksimal 2 MB.",
          backgroundColor: Colors.red,
        );
        return;
      }

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
  // PILIH LOKASI
  // =========================================================

  Future<void> _pickLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        _showMessage(
          "GPS/lokasi sedang tidak aktif. Silakan aktifkan lokasi.",
          backgroundColor: Colors.orange,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        _showMessage(
          "Izin lokasi diperlukan untuk menentukan lokasi pekerjaan.",
          backgroundColor: Colors.orange,
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        _showMessage(
          "Izin lokasi ditolak permanen. Silakan aktifkan izin lokasi dari pengaturan.",
          backgroundColor: Colors.orange,
        );
        return;
      }

      final Position currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final LatLng initialPosition = LatLng(
        currentPosition.latitude,
        currentPosition.longitude,
      );

      if (!mounted) return;
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) {
          return MapPickerDialog(
            initialPosition: initialPosition,
          );
        },
      );

      if (result == null) return;

      final dynamic positionData = result["position"];
      if (positionData is! LatLng) {
        if (!mounted) return;
        _showMessage(
          "Lokasi yang dipilih tidak valid.",
          backgroundColor: Colors.red,
        );
        return;
      }
      final LatLng selectedPosition = positionData;
      final String address = result["address"]?.toString() ?? "";

      if (!mounted) return;
      setState(() {
        _latitude = selectedPosition.latitude;
        _longitude = selectedPosition.longitude;
        _lokasiController.text = address;
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        "Gagal mendapatkan lokasi saat ini: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  // =========================================================
  // RESET LOKASI
  // =========================================================

  void _resetLocation() {
    if (!mounted) return;
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
    // VALIDASI JUDUL
    if (_judulController.text.trim().isEmpty) {
      _showMessage("Judul jasa wajib diisi.");
      return;
    }

    // VALIDASI KATEGORI
    if (_kategori == "Lainnya" &&
        _kategoriLainnyaController.text.trim().isEmpty) {
      _showMessage("Kategori lainnya wajib diisi.");
      return;
    }

    // VALIDASI DESKRIPSI
    if (_deskripsiController.text.trim().isEmpty) {
      _showMessage("Deskripsi jasa wajib diisi.");
      return;
    }

    // VALIDASI BUDGET
    if (_budgetController.text.trim().isEmpty) {
      _showMessage("Budget wajib diisi.", backgroundColor: Colors.red);
      return;
    }

    final rawBudget = _budgetController.text
        .replaceAll('Rp', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();

    final int? budget = int.tryParse(rawBudget);

    if (budget == null) {
      _showMessage(
        "Budget harus berupa angka yang valid.",
        backgroundColor: Colors.red,
      );
      return;
    }

    if (budget <= 0) {
      _showMessage(
        "Budget harus lebih dari Rp 0.",
        backgroundColor: Colors.red,
      );
      return;
    }

    if (rawBudget.length > 8 || budget > 99999999) {
      _showMessage(
        "Budget maksimal Rp99.999.999.",
        backgroundColor: Colors.red,
      );
      return;
    }

    // VALIDASI LOKASI
    if (_latitude == null || _longitude == null) {
      _showMessage("Silakan pilih lokasi pekerjaan pada peta.");
      return;
    }

    if (_lokasiController.text.trim().isEmpty) {
      _showMessage("Alamat lokasi belum ditemukan.");
      return;
    }

    if (_detailAlamatController.text.trim().isEmpty) {
      _showMessage("Detail alamat wajib diisi.");
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ??
          prefs.getString('token') ??
          '';

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

      final uri = Uri.parse('${ApiService.baseUrl}/jobs');

      final request = http.MultipartRequest('POST', uri);
      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['tittle'] = _judulController.text.trim();
      request.fields['description'] = _deskripsiController.text.trim();
      request.fields['initial_budget'] = rawBudget;
      request.fields['category'] = _kategori == "Lainnya"
          ? _kategoriLainnyaController.text.trim()
          : _kategori;
      request.fields['duration'] = _waktuPengerjaan;
      request.fields['location'] = _lokasiController.text.trim();
      request.fields['address_detail'] = _detailAlamatController.text.trim();
      request.fields['latitude'] = _latitude!.toString();
      request.fields['longitude'] = _longitude!.toString();

      if (_pickedFile != null && _imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            _imageBytes!,
            filename: _pickedFile!.name,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final resData = jsonDecode(response.body);
          final jobJson = resData['data'] ?? resData;
          final JobModel createdJob = JobModel.fromJson(jobJson);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Posting jasa berhasil dibuat."),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, createdJob);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Posting berhasil, tetapi data pekerjaan gagal dibaca.",
              ),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      if (!mounted) return;
      String errorMessage =
          "Gagal membuat pekerjaan. Status: ${response.statusCode}";

      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map && errorData['errors'] is Map) {
          final errors = errorData['errors'] as Map;
          if (errors.isNotEmpty) {
            final firstKey = errors.keys.first;
            if (errors[firstKey] is List &&
                (errors[firstKey] as List).isNotEmpty) {
              errorMessage = (errors[firstKey] as List)[0].toString();
            }
          }
        } else if (errorData is Map && errorData['message'] != null) {
          errorMessage = errorData['message'].toString();
        }
      } catch (_) {
        if (response.statusCode == 422) {
          errorMessage = "Data yang dikirim tidak valid.";
        } else if (response.statusCode == 401) {
          errorMessage = "Sesi login berakhir. Silakan login ulang.";
        } else if (response.statusCode == 413) {
          errorMessage = "File terlalu besar untuk server.";
        } else if (response.statusCode == 500) {
          errorMessage = "Terjadi kesalahan di server.";
        }
      }
      _showMessage(errorMessage, backgroundColor: Colors.red);
    } catch (e) {
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

  void _showMessage(String message, {Color? backgroundColor}) {
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isMobile = screenWidth < _mobileBreakpoint;

          final dialogWidth =
              isMobile ? screenWidth - 32 : (screenWidth * 0.7).clamp(500.0, 750.0);

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 18 : 28),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =================================================
                    // HEADER
                    // =================================================
                    _buildHeader(isMobile),

                    SizedBox(height: isMobile ? 22 : 28),

                    // =================================================
                    // SECTION 1: INFO JASA
                    // =================================================
                    _buildSectionLabel('Informasi Jasa', isMobile),
                    const SizedBox(height: 14),

                    _buildField(
                      label: 'Judul Jasa',
                      child: TextField(
                        controller: _judulController,
                        enabled: !_isSubmitting,
                        decoration: _inputDecoration(
                          hint: 'Contoh: Perbaikan AC Bocor',
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildField(
                      label: 'Kategori',
                      child: DropdownButtonFormField<String>(
                        value: _kategori,
                        isExpanded: true,
                        decoration: _inputDecoration(
                          hint: 'Pilih kategori jasa',
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
                                if (value == null) return;
                                setState(() {
                                  _kategori = value;
                                  if (value != "Lainnya") {
                                    _kategoriLainnyaController.clear();
                                  }
                                });
                              },
                      ),
                    ),

                    if (_kategori == "Lainnya") ...[
                      const SizedBox(height: 16),
                      _buildField(
                        label: 'Kategori Lainnya',
                        child: TextField(
                          controller: _kategoriLainnyaController,
                          enabled: !_isSubmitting,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            hint: 'Contoh: Jasa Pindahan',
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    _buildField(
                      label: 'Deskripsi',
                      child: TextField(
                        controller: _deskripsiController,
                        enabled: !_isSubmitting,
                        maxLines: 4,
                        decoration: _inputDecoration(
                          hint:
                              'Jelaskan masalah atau kebutuhan jasa secara detail...',
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =================================================
                    // SECTION 2: BUDGET & DURASI
                    // =================================================
                    _buildSectionLabel('Anggaran & Waktu', isMobile),
                    const SizedBox(height: 14),

                    if (isMobile) ...[
                      _buildBudgetField(),
                      const SizedBox(height: 16),
                      _buildDurasiField(),
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildBudgetField()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildDurasiField()),
                        ],
                      ),

                    const SizedBox(height: 24),

                    // =================================================
                    // SECTION 3: LOKASI
                    // =================================================
                    _buildSectionLabel('Lokasi Pekerjaan', isMobile),
                    const SizedBox(height: 14),

                    _buildLocationPicker(),

                    if (_latitude != null) ...[
                      const SizedBox(height: 14),
                      _buildField(
                        label: 'Alamat',
                        child: TextField(
                          controller: _lokasiController,
                          readOnly: true,
                          maxLines: 2,
                          decoration: _inputDecoration(
                            prefixIcon: const Icon(Icons.map_outlined),
                            filled: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Koordinat: "
                        "${_latitude!.toStringAsFixed(6)}, "
                        "${_longitude!.toStringAsFixed(6)}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed:
                                _isSubmitting ? null : _pickLocation,
                            icon: const Icon(
                              Icons.edit_location_alt_outlined,
                              size: 18,
                            ),
                            label: const Text("Ubah lokasi"),
                            style: TextButton.styleFrom(
                              foregroundColor: _accent,
                            ),
                          ),
                          const SizedBox(width: 4),
                          TextButton.icon(
                            onPressed:
                                _isSubmitting ? null : _resetLocation,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text("Reset"),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildField(
                        label: 'Detail Alamat',
                        child: TextField(
                          controller: _detailAlamatController,
                          enabled: !_isSubmitting,
                          maxLines: 3,
                          decoration: _inputDecoration(
                            hint:
                                'Contoh: Rumah nomor 10, pagar hitam, sebelah minimarket...',
                            prefixIcon: const Icon(Icons.home_outlined),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // =================================================
                    // SECTION 4: FOTO
                    // =================================================
                    _buildSectionLabel('Foto Kendala (Opsional)', isMobile),
                    const SizedBox(height: 6),
                    Text(
                      'Format: JPG, PNG, WEBP. Maksimal 2 MB.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildPhotoPicker(isMobile),

                    const SizedBox(height: 28),

                    // =================================================
                    // BUTTONS
                    // =================================================
                    _buildActions(isMobile),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isMobile ? 42 : 48,
          height: isMobile ? 42 : 48,
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.rocket_launch_outlined,
            color: _accent,
            size: isMobile ? 22 : 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Posting Jasa Baru',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Isi detail pekerjaan yang ingin kamu posting',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // SECTION LABEL
  // =========================================================

  Widget _buildSectionLabel(String text, bool isMobile) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: isMobile ? 13.5 : 14.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // FIELD WRAPPER — Label di atas, input di bawah
  // =========================================================

  Widget _buildField({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  // =========================================================
  // INPUT DECORATION STANDARD
  // =========================================================

  InputDecoration _inputDecoration({
    String? hint,
    Widget? prefixIcon,
    bool filled = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 13,
        color: Color(0xFF9CA3AF),
      ),
      prefixIcon: prefixIcon,
      filled: filled,
      fillColor: filled ? const Color(0xFFF9FAFB) : null,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
    );
  }

  // =========================================================
  // BUDGET FIELD — ✅ FIX: "Rp" jadi prefixText, formatter murni angka
  // =========================================================

  Widget _buildBudgetField() {
    return _buildField(
      label: 'Budget',
      child: TextField(
        controller: _budgetController,
        enabled: !_isSubmitting,
        keyboardType: const TextInputType.numberWithOptions(
          signed: false,
          decimal: false,
        ),
        inputFormatters: [
          // ✅ Formatter: thousand separator saja, TANPA leading symbol
          CurrencyInputFormatter(
            leadingSymbol: '', // kosong — biar "Rp" tidak bisa dihapus user
            thousandSeparator: ThousandSeparator.Period,
            mantissaLength: 0,
          ),
          // Batasi maksimal 8 digit
          TextInputFormatter.withFunction(
            (oldValue, newValue) {
              if (newValue.text.contains('-')) return oldValue;
              final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
              if (digits.length > 8) return oldValue;
              return newValue;
            },
          ),
        ],
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: const TextStyle(
            fontSize: 13,
            color: Color(0xFF9CA3AF),
          ),
          // ✅ "Rp" muncul sebagai prefix yang tidak bisa dihapus
          prefixText: 'Rp ',
          prefixStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _accent, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // DURASI FIELD
  // =========================================================

  Widget _buildDurasiField() {
    return _buildField(
      label: 'Waktu Pengerjaan',
      child: DropdownButtonFormField<String>(
        value: _waktuPengerjaan,
        isExpanded: true,
        decoration: _inputDecoration(
          hint: 'Pilih perkiraan waktu',
          prefixIcon: const Icon(Icons.schedule_outlined, size: 20),
        ),
        items: waktuPengerjaanList.map((e) {
          return DropdownMenuItem<String>(
            value: e,
            child: Text(e),
          );
        }).toList(),
        onChanged: _isSubmitting
            ? null
            : (value) {
                if (value == null) return;
                setState(() {
                  _waktuPengerjaan = value;
                });
              },
      ),
    );
  }

  // =========================================================
  // LOCATION PICKER BOX
  // =========================================================

  Widget _buildLocationPicker() {
    final hasLocation = _latitude != null;

    return InkWell(
      onTap: _isSubmitting ? null : _pickLocation,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: hasLocation
              ? Colors.green.withOpacity(0.05)
              : Colors.transparent,
          border: Border.all(
            color: hasLocation ? Colors.green : const Color(0xFFD1D5DB),
            width: hasLocation ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              hasLocation
                  ? Icons.check_circle_outline
                  : Icons.location_on_outlined,
              color: hasLocation ? Colors.green : const Color(0xFF6B7280),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasLocation
                        ? "Lokasi berhasil dipilih"
                        : "Pilih lokasi dari peta",
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: hasLocation
                          ? Colors.green.shade700
                          : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasLocation
                        ? "OpenStreetMap"
                        : "Tentukan titik lokasi pekerjaan",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // PHOTO PICKER
  // =========================================================

  Widget _buildPhotoPicker(bool isMobile) {
    return InkWell(
      onTap: _isSubmitting ? null : _pickImage,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: isMobile ? 160 : 180,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD1D5DB)),
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFFF9FAFB),
        ),
        child: _imageBytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 40,
                    color: Color(0xFF9CA3AF),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Klik untuk upload foto",
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      _imageBytes!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _pickedFile = null;
                              _imageBytes = null;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // =========================================================
  // ACTIONS — Batal + Posting
  // =========================================================

  Widget _buildActions(bool isMobile) {
    final cancelButton = OutlinedButton(
      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        foregroundColor: const Color(0xFF374151),
        side: const BorderSide(color: Color(0xFFD1D5DB)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: const Text(
        'Batal',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );

    final submitButton = ElevatedButton.icon(
      onPressed: _isSubmitting ? null : _postingJasa,
      icon: _isSubmitting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.rocket_launch, size: 18),
      label: Text(
        _isSubmitting ? 'Memproses...' : 'Posting Sekarang',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
      ),
    );

    if (isMobile) {
      return Column(
        children: [
          SizedBox(width: double.infinity, child: submitButton),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: cancelButton),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: cancelButton),
        const SizedBox(width: 14),
        Expanded(flex: 2, child: submitButton),
      ],
    );
  }
}