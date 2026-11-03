
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../models/job_model.dart';
import '../../screens/Screens_Customer/map_picker_screen.dart';
import '../../services/api_service.dart';
import '../../utils/indonesia_time.dart';
import '../../services/auth_storage.dart';
import '../../theme/app_colors.dart';

class PostingJasaDialog extends StatefulWidget {
  const PostingJasaDialog({super.key});

  @override
  State<PostingJasaDialog> createState() => _PostingJasaDialogState();
}

class _PostingJasaDialogState extends State<PostingJasaDialog> {
  // =========================================================
  // CONTROLLERS
  // =========================================================

  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _budgetController = TextEditingController();
  final _kategoriLainnyaController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _detailAlamatController = TextEditingController();
  final _pinController = TextEditingController();

  // =========================================================
  // FOTO
  // =========================================================

  XFile? _pickedFile;
  Uint8List? _imageBytes;

  static const int _maxImageSizeInBytes = 2097152;

  // =========================================================
  // STATE
  // =========================================================

  bool _isSubmitting = false;
  bool _isLoadingCity = false;

  // Kategori
  String _kategori = 'Perbaikan & Perawatan Rumah';

  final List<String> kategoriList = [
    'Perbaikan & Perawatan Rumah',
    'Kebersihan',
    'Konstruksi & Renovasi',
    'Instalasi & Teknisi',
    'Jasa Rumah Tangga',
    'Jasa Umum',
    'Lainnya',
  ];

  // Waktu pengerjaan umum
  String _waktuPengerjaan = '1–2 Jam';

  final List<String> waktuPengerjaanList = [
    '1–2 Jam',
    '3–5 Jam',
    '1 Hari',
    '2–3 Hari',
    '1 Minggu',
    '> 1 Minggu',
  ];

  // Lokasi
  double? _latitude;
  double? _longitude;
  String? _selectedCityName;

  // Waktu mulai yang diinginkan Pelanggan
  DateTime? _preferredStartAt;

  // =========================================================
  // DESIGN TOKENS
  // =========================================================

  static const Color _accent = AppColors.primaryTeal;
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
    _pinController.dispose();

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

      const allowedExtensions = [
        '.jpg',
        '.jpeg',
        '.png',
        '.webp',
      ];

      final hasValidExtension = allowedExtensions.any(
        (extension) => lowerName.endsWith(extension),
      );

      if (!hasValidExtension) {
        if (!mounted) return;

        _showMessage(
          'Format foto harus JPG, JPEG, PNG, atau WEBP.',
          backgroundColor: Colors.red,
        );
        return;
      }

      final bytes = await image.readAsBytes();

      if (bytes.length > _maxImageSizeInBytes) {
        if (!mounted) return;

        final sizeMb = (bytes.length / 1024 / 1024).toStringAsFixed(2);

        _showMessage(
          'Ukuran foto terlalu besar ($sizeMb MB). Maksimal 2 MB.',
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
        'Gagal memilih foto: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  // =========================================================
  // PILIH LOKASI
  // =========================================================

  Future<void> _pickLocation() async {
    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        _showMessage(
          'GPS/lokasi sedang tidak aktif. Silakan aktifkan lokasi.',
          backgroundColor: const Color(0xFFF59E0B),
        );
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;

        _showMessage(
          'Izin lokasi diperlukan untuk menentukan lokasi pekerjaan.',
          backgroundColor: const Color(0xFFF59E0B),
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        _showMessage(
          'Izin lokasi ditolak permanen. Silakan aktifkan izin lokasi dari pengaturan.',
          backgroundColor: const Color(0xFFF59E0B),
        );
        return;
      }

      final Position currentPosition =
          await Geolocator.getCurrentPosition(
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

      final positionData = result['position'];

      if (positionData is! LatLng) {
        if (!mounted) return;

        _showMessage(
          'Lokasi yang dipilih tidak valid.',
          backgroundColor: Colors.red,
        );
        return;
      }

      final selectedPosition = positionData;
      final address = result['address']?.toString() ?? '';
      final cityName = result['cityName']?.toString();

      if (!mounted) return;

      setState(() {
        _latitude = selectedPosition.latitude;
        _longitude = selectedPosition.longitude;

        _lokasiController.text = address;

        _selectedCityName =
            cityName != null && cityName.trim().isNotEmpty
                ? cityName.trim()
                : null;

        _isLoadingCity = false;
      });

      if (_selectedCityName == null) {
        _showMessage(
          'Kota/kabupaten belum berhasil dideteksi. Silakan pilih titik lokasi lainnya.',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      debugPrint('Gagal memilih lokasi: $e');

      if (!mounted) return;

      _showMessage(
        'Gagal mendapatkan lokasi saat ini: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  // =========================================================
  // DETEKSI KOTA
  // =========================================================


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

      _selectedCityName = null;
      _isLoadingCity = false;
    });
  }

  // =========================================================
  // PILIH WAKTU MULAI
  // =========================================================

  Future<void> _pickPreferredStartAt() async {
    final now = IndonesiaTime.nowWall();

    final existing = _preferredStartAt == null
        ? null
        : IndonesiaTime.toWall(_preferredStartAt!);

    final initialDate = existing != null && existing.isAfter(now)
        ? existing
        : now.add(const Duration(days: 1));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      helpText: 'Pilih tanggal mulai pekerjaan',
      cancelText: 'Batal',
      confirmText: 'Lanjut',
    );

    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: existing != null
          ? TimeOfDay.fromDateTime(existing)
          : const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Pilih jam mulai pekerjaan',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );

    if (selectedTime == null || !mounted) return;

    final selectedDateTime = DateTime.utc(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (!IndonesiaTime.wallToUtc(selectedDateTime)
        .isAfter(DateTime.now().toUtc())) {
      _showMessage(
        'Waktu mulai harus lebih dari waktu sekarang.',
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() {
      _preferredStartAt = IndonesiaTime.wallToUtc(selectedDateTime);
    });
  }

  // =========================================================
  // FORMAT TANGGAL DAN WAKTU
  // =========================================================

  String _formatPreferredStartAt(DateTime dateTime) {
    final wibDateTime = IndonesiaTime.toWall(dateTime);
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final day = wibDateTime.day.toString().padLeft(2, '0');
    final month = months[wibDateTime.month - 1];
    final year = wibDateTime.year;

    final hour = wibDateTime.hour.toString().padLeft(2, '0');
    final minute = wibDateTime.minute.toString().padLeft(2, '0');

    return '$day $month $year, pukul $hour:$minute';
  }

  // =========================================================
  // FORMAT BUDGET
  // =========================================================

  String _getRawBudget() {
    return _budgetController.text
        .replaceAll('Rp', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();
  }

  // =========================================================
  // POSTING JASA
  // =========================================================

  Future<void> _postingJasa() async {
    if (_isSubmitting) return;

    // ---------------------------------------------------------
    // VALIDASI JUDUL
    // ---------------------------------------------------------

    if (_judulController.text.trim().isEmpty) {
      _showMessage('Judul jasa wajib diisi.');
      return;
    }

    // ---------------------------------------------------------
    // VALIDASI KATEGORI
    // ---------------------------------------------------------

    if (_kategori == 'Lainnya' &&
        _kategoriLainnyaController.text.trim().isEmpty) {
      _showMessage('Kategori lainnya wajib diisi.');
      return;
    }

    // ---------------------------------------------------------
    // VALIDASI DESKRIPSI
    // ---------------------------------------------------------

    if (_deskripsiController.text.trim().isEmpty) {
      _showMessage('Deskripsi jasa wajib diisi.');
      return;
    }

    // ---------------------------------------------------------
    // VALIDASI BUDGET
    // ---------------------------------------------------------

    final rawBudget = _getRawBudget();
    final int? budget = int.tryParse(rawBudget);

    if (rawBudget.isEmpty) {
      _showMessage(
        'Budget wajib diisi.',
        backgroundColor: Colors.red,
      );
      return;
    }

    if (budget == null || budget <= 0) {
      _showMessage(
        'Budget harus berupa angka yang valid dan lebih dari Rp 0.',
        backgroundColor: Colors.red,
      );
      return;
    }

    if (rawBudget.length > 8 || budget > 99999999) {
      _showMessage(
        'Budget maksimal Rp99.999.999.',
        backgroundColor: Colors.red,
      );
      return;
    }

    // ---------------------------------------------------------
    // VALIDASI WAKTU MULAI
    // ---------------------------------------------------------

    if (_preferredStartAt == null) {
      _showMessage(
        'Silakan tentukan waktu mulai pekerjaan.',
        backgroundColor: Colors.red,
      );
      return;
    }

    if (!_preferredStartAt!.isAfter(DateTime.now().toUtc())) {
      _showMessage(
        'Waktu mulai harus lebih dari waktu sekarang.',
        backgroundColor: Colors.red,
      );
      return;
    }

    // ---------------------------------------------------------
    // VALIDASI LOKASI
    // ---------------------------------------------------------

    if (_latitude == null || _longitude == null) {
      _showMessage('Silakan pilih lokasi pekerjaan pada peta.');
      return;
    }

    if (_lokasiController.text.trim().isEmpty) {
      _showMessage('Alamat lokasi belum ditemukan.');
      return;
    }

    if (_detailAlamatController.text.trim().isEmpty) {
      _showMessage('Detail alamat wajib diisi.');
      return;
    }

    // ---------------------------------------------------------
    // VALIDASI KOTA
    // ---------------------------------------------------------

    if (_isLoadingCity) {
      _showMessage(
        'Mohon tunggu sampai deteksi kota selesai.',
        backgroundColor: const Color(0xFFF59E0B),
      );
      return;
    }

    if (_selectedCityName == null ||
        _selectedCityName!.trim().isEmpty) {
      _showMessage(
        'Kota lokasi pekerjaan belum terdeteksi. Pastikan lokasi yang dipilih valid.',
        backgroundColor: Colors.red,
      );
      return;
    }

    // ---------------------------------------------------------
    // VALIDASI PIN
    // ---------------------------------------------------------

    if (_pinController.text.trim().length != 6) {
      _showMessage(
        'PIN harus 6 digit.',
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // -------------------------------------------------------
      // TOKEN
      // -------------------------------------------------------

      final token = AuthStorage.getString('auth_token') ??
          AuthStorage.getString('token') ??
          '';

      if (token.isEmpty) {
        if (!mounted) return;

        setState(() {
          _isSubmitting = false;
        });

        _showMessage(
          'Sesi telah berakhir, silakan login kembali.',
          backgroundColor: const Color(0xFFF59E0B),
        );
        return;
      }

      // -------------------------------------------------------
      // REQUEST MULTIPART
      // -------------------------------------------------------

      final uri = Uri.parse('${ApiService.baseUrl}/jobs');

      final request = http.MultipartRequest('POST', uri);

      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['tittle'] = _judulController.text.trim();
      request.fields['description'] = _deskripsiController.text.trim();
      request.fields['initial_budget'] = rawBudget;

      request.fields['category'] = _kategori == 'Lainnya'
          ? _kategoriLainnyaController.text.trim()
          : _kategori;

      request.fields['duration'] = _waktuPengerjaan;

      // Waktu mulai yang diinginkan Pelanggan.
      // Simpan sebagai UTC agar konsisten dengan backend.
      request.fields['preferred_start_at'] =
          _preferredStartAt!.toUtc().toIso8601String();

      // Lokasi
      request.fields['location'] = _lokasiController.text.trim();
      request.fields['address_detail'] =
          _detailAlamatController.text.trim();

      request.fields['latitude'] = _latitude!.toString();
      request.fields['longitude'] = _longitude!.toString();

      request.fields['location_lat'] = _latitude!.toString();
      request.fields['location_lng'] = _longitude!.toString();

      request.fields['city_name'] = _selectedCityName!.trim();

      // PIN
      request.fields['pin'] = _pinController.text.trim();

      // Foto opsional
      if (_pickedFile != null && _imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            _imageBytes!,
            filename: _pickedFile!.name,
          ),
        );
      }

      // -------------------------------------------------------
      // KIRIM REQUEST
      // -------------------------------------------------------

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(
        streamedResponse,
      );

      if (!mounted) return;

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        try {
          final resData = jsonDecode(response.body);

          final jobJson = resData['data'] ?? resData;

          final JobModel createdJob = JobModel.fromJson(jobJson);

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Posting jasa berhasil dibuat! Saldo Anda telah ditahan.',
              ),
              backgroundColor: AppColors.primaryTeal,
              behavior: SnackBarBehavior.floating,
            ),
          );

          Navigator.pop(context, createdJob);
        } catch (e) {
          debugPrint('Gagal membaca data pekerjaan: $e');

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Posting berhasil, tetapi data pekerjaan gagal dibaca.',
              ),
              backgroundColor: Color(0xFFF59E0B),
              behavior: SnackBarBehavior.floating,
            ),
          );

          Navigator.pop(context);
        }

        return;
      }

      // -------------------------------------------------------
      // HANDLE ERROR RESPONSE
      // -------------------------------------------------------

      String errorMessage =
          'Gagal membuat pekerjaan. Status: ${response.statusCode}';

      try {
        final errorData = jsonDecode(response.body);

        if (errorData is Map && errorData['errors'] is Map) {
          final errors = errorData['errors'] as Map;

          if (errors.isNotEmpty) {
            final firstError = errors.values.first;

            if (firstError is List && firstError.isNotEmpty) {
              errorMessage = firstError.first.toString();
            } else {
              errorMessage = firstError.toString();
            }
          }
        } else if (errorData is Map &&
            errorData['message'] != null) {
          errorMessage = errorData['message'].toString();
        }
      } catch (_) {
        if (response.statusCode == 401) {
          errorMessage = 'Sesi login berakhir. Silakan login ulang.';
        } else if (response.statusCode == 413) {
          errorMessage = 'File terlalu besar untuk server.';
        } else if (response.statusCode == 422) {
          errorMessage = 'Data yang dikirim tidak valid.';
        } else if (response.statusCode == 500) {
          errorMessage = 'Terjadi kesalahan di server.';
        }
      }

      if (!mounted) return;

      _showMessage(
        errorMessage,
        backgroundColor: Colors.red,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Terjadi kesalahan: $e',
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isMobile = screenWidth < _mobileBreakpoint;

          final dialogWidth = isMobile
              ? screenWidth - 32
              : (screenWidth * 0.7).clamp(500.0, 750.0);

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
                    _buildHeader(isMobile),

                    SizedBox(height: isMobile ? 22 : 28),

                    // SECTION 1
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
                        initialValue: _kategori,
                        isExpanded: true,
                        decoration: _inputDecoration(
                          hint: 'Pilih kategori jasa',
                        ),
                        items: kategoriList.map((item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        onChanged: _isSubmitting
                            ? null
                            : (value) {
                                if (value == null) return;

                                setState(() {
                                  _kategori = value;

                                  if (value != 'Lainnya') {
                                    _kategoriLainnyaController.clear();
                                  }
                                });
                              },
                      ),
                    ),

                    if (_kategori == 'Lainnya') ...[
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

                    // SECTION 2
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

                    const SizedBox(height: 18),

                    _buildPreferredStartField(),

                    const SizedBox(height: 24),

                    // SECTION 3
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
                        'Koordinat: '
                        '${_latitude!.toStringAsFixed(6)}, '
                        '${_longitude!.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey600,
                        ),
                      ),

                      if (_isLoadingCity)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Mendeteksi kota...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (_selectedCityName != null &&
                          !_isLoadingCity)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_city,
                                size: 14,
                                color: AppColors.primaryTeal,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Kota Terdeteksi: $_selectedCityName',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryTeal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 4),

                      Wrap(
                        spacing: 4,
                        children: [
                          TextButton.icon(
                            onPressed:
                                _isSubmitting ? null : _pickLocation,
                            icon: const Icon(
                              Icons.edit_location_alt_outlined,
                              size: 18,
                            ),
                            label: const Text('Ubah lokasi'),
                            style: TextButton.styleFrom(
                              foregroundColor: _accent,
                            ),
                          ),
                          TextButton.icon(
                            onPressed:
                                _isSubmitting ? null : _resetLocation,
                            icon: const Icon(
                              Icons.refresh,
                              size: 18,
                            ),
                            label: const Text('Reset'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.grey700,
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

                    // SECTION 4
                    _buildSectionLabel(
                      'Foto Kendala (Opsional)',
                      isMobile,
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Format: JPG, PNG, WEBP. Maksimal 2 MB.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.grey600,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildPhotoPicker(isMobile),

                    const SizedBox(height: 24),

                    // SECTION 5
                    _buildSectionLabel(
                      'Konfirmasi Pembayaran',
                      isMobile,
                    ),

                    const SizedBox(height: 10),

                    _buildEscrowConfirmation(),

                    const SizedBox(height: 28),

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
  // PREFERRED START FIELD
  // =========================================================

  Widget _buildPreferredStartField() {
    final hasSelectedTime = _preferredStartAt != null;

    return _buildField(
      label: 'Waktu Mulai yang Diinginkan',
      child: InkWell(
        onTap: _isSubmitting ? null : _pickPreferredStartAt,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: hasSelectedTime
                  ? AppColors.primaryTeal
                  : AppColors.grey300,
            ),
            borderRadius: BorderRadius.circular(10),
            color: hasSelectedTime
                ? AppColors.mint.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                color: hasSelectedTime
                    ? AppColors.primaryTeal
                    : AppColors.grey500,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasSelectedTime
                          ? _formatPreferredStartAt(_preferredStartAt!)
                          : 'Pilih tanggal dan jam mulai',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: hasSelectedTime
                            ? AppColors.primaryTeal
                            : AppColors.grey500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tentukan kapan Mitra diharapkan mulai bekerja.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                hasSelectedTime
                    ? Icons.edit_calendar_outlined
                    : Icons.chevron_right,
                color: AppColors.grey500,
              ),
            ],
          ),
        ),
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
            color: _accent.withValues(alpha: 0.12),
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
                  color: AppColors.grey900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Isi detail pekerjaan yang ingin kamu posting',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  color: AppColors.grey500,
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
            color: AppColors.grey800,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // FIELD WRAPPER
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
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  // =========================================================
  // INPUT DECORATION
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
        color: AppColors.grey400,
      ),
      prefixIcon: prefixIcon,
      filled: filled,
      fillColor: filled ? AppColors.grey50 : null,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.grey300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.grey300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: _accent,
          width: 1.5,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.grey200),
      ),
    );
  }

  // =========================================================
  // BUDGET FIELD
  // =========================================================

  Widget _buildBudgetField() {
    return _buildField(
      label: 'Budget',
      child: TextField(
        controller: _budgetController,
        enabled: !_isSubmitting,
        onChanged: (_) => setState(() {}),
        keyboardType: const TextInputType.numberWithOptions(
          signed: false,
          decimal: false,
        ),
        inputFormatters: [
          CurrencyInputFormatter(
            leadingSymbol: '',
            thousandSeparator: ThousandSeparator.Period,
            mantissaLength: 0,
          ),
          TextInputFormatter.withFunction(
            (oldValue, newValue) {
              if (newValue.text.contains('-')) {
                return oldValue;
              }

              final digits = newValue.text.replaceAll(
                RegExp(r'[^\d]'),
                '',
              );

              if (digits.length > 8) {
                return oldValue;
              }

              return newValue;
            },
          ),
        ],
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: const TextStyle(
            fontSize: 13,
            color: AppColors.grey400,
          ),
          prefixText: 'Rp ',
          prefixStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.grey900,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.grey300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.grey300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: _accent,
              width: 1.5,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.grey200),
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
        initialValue: _waktuPengerjaan,
        isExpanded: true,
        decoration: _inputDecoration(
          hint: 'Pilih perkiraan waktu',
          prefixIcon: const Icon(
            Icons.schedule_outlined,
            size: 20,
          ),
        ),
        items: waktuPengerjaanList.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
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
  // LOCATION PICKER
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
              ? AppColors.mint.withValues(alpha: 0.10)
              : Colors.transparent,
          border: Border.all(
            color: hasLocation
                ? AppColors.primaryTeal
                : AppColors.grey300,
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
              color: hasLocation
                  ? AppColors.primaryTeal
                  : AppColors.grey500,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasLocation
                        ? 'Lokasi berhasil dipilih'
                        : 'Pilih lokasi dari peta',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: hasLocation
                          ? AppColors.primaryTeal
                          : AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasLocation
                        ? 'OpenStreetMap'
                        : 'Tentukan titik lokasi pekerjaan',
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
              color: AppColors.grey400,
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
          border: Border.all(color: AppColors.grey300),
          borderRadius: BorderRadius.circular(14),
          color: AppColors.grey50,
        ),
        child: _imageBytes == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 40,
                    color: AppColors.grey400,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Klik untuk upload foto',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.grey600,
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
                          onTap: _isSubmitting
                              ? null
                              : () {
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
  // ESCROW CONFIRMATION
  // =========================================================

  Widget _buildEscrowConfirmation() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lock_outline,
                color: AppColors.primaryTeal,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dana sebesar ${_budgetController.text.isEmpty ? "Rp 0" : "Rp ${_budgetController.text}"} akan ditahan oleh sistem (Escrow).',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryTeal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 28),
            child: Text(
              'Catatan: Jika Mitra menawar lebih murah dari budget, sisa saldo otomatis kembali ke dompet Anda. Jika Mitra menawar lebih mahal, Anda wajib Topup sebelum ACC Mitra.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.grey700,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildField(
            label: 'Masukkan PIN Anda (6 Digit)',
            child: TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              enabled: !_isSubmitting,
              decoration: _inputDecoration(
                hint: '******',
                prefixIcon: const Icon(Icons.password),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ACTIONS
  // =========================================================

  Widget _buildActions(bool isMobile) {
    final cancelButton = OutlinedButton(
      onPressed: _isSubmitting
          ? null
          : () => Navigator.pop(context),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        foregroundColor: AppColors.grey700,
        side: const BorderSide(color: AppColors.grey300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: const Text(
        'Batal',
        style: TextStyle(
          fontWeight: FontWeight.w600,
        ),
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
          : const Icon(
              Icons.rocket_launch,
              size: 18,
            ),
      label: Text(
        _isSubmitting ? 'Memproses...' : 'Posting Sekarang',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
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
          SizedBox(
            width: double.infinity,
            child: submitButton,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: cancelButton,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: cancelButton),
        const SizedBox(width: 14),
        Expanded(
          flex: 2,
          child: submitButton,
        ),
      ],
    );
  }
}
