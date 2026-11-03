
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

import '../../models/partner_job_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/indonesia_time.dart';

class OfferJobScreen extends StatefulWidget {
  final PartnerJobModel job;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const OfferJobScreen({
    super.key,
    required this.job,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  State<OfferJobScreen> createState() => _OfferJobScreenState();
}

class _OfferJobScreenState extends State<OfferJobScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  int _parsedPrice = 0;
  bool _isSubmitting = false;

  DateTime? _proposedStartAt;

  String? _selectedEstimatedDuration;

  // ============================================================
  // ESTIMASI DURASI
  // ============================================================

  // Nilai menit menggunakan batas atas setiap rentang.
  static const Map<String, int> _durationOptions = {
    '1–2 Jam': 120,
    '3–5 Jam': 300,
    '1 Hari': 1440,
    '2–3 Hari': 4320,
    '1 Minggu': 10080,
    'Lebih dari 1 Minggu': 20160,
  };

  int? get _estimatedDurationMinutes {
    if (_selectedEstimatedDuration == null) return null;

    return _durationOptions[_selectedEstimatedDuration!];
  }

  // ============================================================
  // DESIGN TOKENS
  // ============================================================

  static const Color _accent = AppColors.primaryTeal;
  static const Color _tableBorder = AppColors.grey200;
  static const Color _tableDivider = AppColors.grey100;
  static const Color _cellText = AppColors.grey900;

  static const double _commissionPercent = 15.0;
  static const int _maxPrice = 99999999;
  static const int _maxMessageLength = 500;

  static const double _gapBetweenSections = 16;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // ============================================================
  // FORMAT RUPIAH
  // ============================================================

  String _formatRupiah(int amount) {
    if (amount <= 0) return 'Rp 0';

    final str = amount.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(str[i]);
    }

    return 'Rp $buffer';
  }

  // ============================================================
  // KOMISI PLATFORM
  // ============================================================

  int get _commissionAmount {
    return (_parsedPrice * _commissionPercent / 100).round();
  }

  // ============================================================
  // PARSE HARGA
  // ============================================================

  int _getCleanPrice(String value) {
    final cleanDigits = value.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(cleanDigits) ?? 0;
  }

  // ============================================================
  // FORMAT WAKTU RELATIF
  // ============================================================

  String _formatRelativeTime(String rawTime) {
    if (rawTime.isEmpty) return 'Waktu fleksibel';

    try {
      final dateTime = IndonesiaTime.parseApiTimestamp(rawTime);
      final now = DateTime.now().toUtc();
      final diff = now.difference(dateTime);

      if (diff.isNegative) return 'Baru saja';
      if (diff.inMinutes < 1) return 'Baru saja';

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes} menit lalu';
      }

      if (diff.inHours < 24) {
        return '${diff.inHours} jam lalu';
      }

      if (diff.inDays < 7) {
        return '${diff.inDays} hari lalu';
      }

      const bulan = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];

      final wibDateTime = IndonesiaTime.toWall(dateTime);
      return '${wibDateTime.day} '
          '${bulan[wibDateTime.month - 1]} '
          '${wibDateTime.year}';
    } catch (_) {
      return rawTime;
    }
  }

  // ============================================================
  // FORMAT JADWAL
  // ============================================================

  String _formatStartDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty || rawDate == 'null') {
      return 'Waktu fleksibel / Segera';
    }

    try {
      final date = IndonesiaTime.toWall(
        IndonesiaTime.parseApiTimestamp(rawDate),
      );

      const bulan = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];

      final day = date.day.toString().padLeft(2, '0');
      final month = bulan[date.month - 1];
      final year = date.year;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$day $month $year, $hour:$minute WIB';
    } catch (_) {
      return rawDate;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final wibDateTime = IndonesiaTime.toWall(dateTime);
    const bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];

    final day = wibDateTime.day.toString().padLeft(2, '0');
    final month = bulan[wibDateTime.month - 1];
    final year = wibDateTime.year;
    final hour = wibDateTime.hour.toString().padLeft(2, '0');
    final minute = wibDateTime.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute';
  }

  // ============================================================
  // PILIH WAKTU MULAI KERJA
  // ============================================================

  Future<void> _pickProposedStartAt() async {
    final now = IndonesiaTime.nowWall();
    final existing = _proposedStartAt == null
        ? null
        : IndonesiaTime.toWall(_proposedStartAt!);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: existing ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      helpText: 'Pilih tanggal mulai kerja',
      cancelText: 'Batal',
      confirmText: 'Lanjut',
    );

    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: existing != null
          ? TimeOfDay.fromDateTime(existing)
          : const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Pilih jam mulai kerja',
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
      _showSnack(
        'Waktu mulai harus lebih dari waktu sekarang.',
        warning: true,
      );
      return;
    }

    setState(() {
      _proposedStartAt = IndonesiaTime.wallToUtc(selectedDateTime);
    });
  }

  // ============================================================
  // PILIH ESTIMASI DURASI
  // ============================================================

  Future<void> _pickEstimatedDuration() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Pilih Estimasi Durasi',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Berapa lama waktu yang Anda butuhkan untuk '
                  'menyelesaikan pekerjaan ini?',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.grey500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                ..._durationOptions.keys.map((duration) {
                  final isSelected =
                      _selectedEstimatedDuration == duration;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.pop(context, duration);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _accent.withValues(alpha: 0.08)
                              : AppColors.grey50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? _accent
                                : _tableBorder,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 19,
                              color: isSelected
                                  ? _accent
                                  : AppColors.grey500,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                duration,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: AppColors.grey900,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: _accent,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) return;

    setState(() {
      _selectedEstimatedDuration = selected;
    });
  }

  // ============================================================
  // SUBMIT OFFER
  // ============================================================

  Future<void> _submitOfferToApi() async {
    if (_isSubmitting) return;

    final rawPrice = _priceController.text.trim();
    final trimmedMessage = _messageController.text.trim();

    // VALIDASI HARGA
    if (rawPrice.isEmpty) {
      _showSnack(
        'Harap masukkan harga penawaran.',
        warning: true,
      );
      return;
    }

    if (rawPrice.contains('-')) {
      _showSnack(
        'Harga penawaran tidak boleh bernilai negatif.',
        error: true,
      );
      return;
    }

    final parsedPrice = _getCleanPrice(rawPrice);

    if (parsedPrice <= 0) {
      _showSnack(
        'Harga penawaran minimal Rp 1.',
        warning: true,
      );
      return;
    }

    if (parsedPrice > _maxPrice) {
      _showSnack(
        'Harga penawaran maksimal Rp99.999.999.',
        warning: true,
      );
      return;
    }

    // VALIDASI PESAN
    if (trimmedMessage.isEmpty) {
      _showSnack(
        'Harap isi pesan untuk pelanggan terlebih dahulu.',
        warning: true,
      );
      return;
    }

    if (trimmedMessage.length > _maxMessageLength) {
      _showSnack(
        'Pesan maksimal $_maxMessageLength karakter.',
        warning: true,
      );
      return;
    }

    // VALIDASI WAKTU MULAI
    if (_proposedStartAt == null) {
      _showSnack(
        'Harap tentukan usulan waktu mulai kerja.',
        warning: true,
      );
      return;
    }

    // VALIDASI ESTIMASI DURASI
    if (_selectedEstimatedDuration == null ||
        _estimatedDurationMinutes == null) {
      _showSnack(
        'Harap pilih estimasi durasi pekerjaan.',
        warning: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _parsedPrice = parsedPrice;
    });

    try {
      final response = await ApiService.post(
        '/jobs/${widget.job.id}/apply',
        {
          'offered_price': parsedPrice,
          'message': trimmedMessage,
          'proposed_start_at':
              _proposedStartAt!.toUtc().toIso8601String(),

          // ESTIMASI DURASI
          'estimated_duration': _selectedEstimatedDuration,
          'estimated_duration_minutes': _estimatedDurationMinutes,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        _showSnack(
          'Penawaran berhasil dikirim!',
          success: true,
        );

        widget.onSubmit();
        return;
      }

      // HANDLE ERROR RESPONSE
      String errorMessage = 'Gagal mengirim penawaran.';

      try {
        final errorData = jsonDecode(response.body);

        if (errorData is Map<String, dynamic>) {
          errorMessage =
              errorData['message']?.toString() ?? errorMessage;

          if (errorData['errors'] is Map) {
            final errors = errorData['errors'] as Map;

            if (errors.isNotEmpty) {
              final firstError = errors.values.first;

              if (firstError is List && firstError.isNotEmpty) {
                errorMessage = firstError.first.toString();
              } else {
                errorMessage = firstError.toString();
              }
            }
          }
        }
      } catch (_) {
        if (response.statusCode == 401) {
          errorMessage =
              'Sesi login berakhir. Silakan login ulang.';
        } else if (response.statusCode == 403) {
          errorMessage =
              'Anda tidak memiliki akses untuk mengajukan penawaran.';
        } else if (response.statusCode == 404) {
          errorMessage = 'Pekerjaan tidak ditemukan.';
        } else if (response.statusCode == 422) {
          errorMessage = 'Data penawaran tidak valid.';
        } else if (response.statusCode >= 500) {
          errorMessage = 'Terjadi kesalahan pada server.';
        }
      }

      _showSnack(errorMessage, error: true);
    } catch (e) {
      if (!mounted) return;

      _showSnack(
        'Terjadi kesalahan koneksi: $e',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnack(
    String message, {
    bool error = false,
    bool warning = false,
    bool success = false,
  }) {
    if (!mounted) return;

    Color backgroundColor = AppColors.primaryTeal;

    if (success) {
      backgroundColor = AppColors.primaryTeal;
    } else if (warning) {
      backgroundColor = AppColors.amber;
    } else if (error) {
      backgroundColor = AppColors.danger;
    }

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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sectionAltLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isSubmitting ? null : widget.onBack,
        ),
        title: const Text(
          'Ambil & Nego',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppColors.grey900,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.grey900,
        elevation: 0,
      ),
      body: LayoutBuilder(
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
            child: isMobile
                ? _buildMobileLayout()
                : _buildWebLayout(),
          );
        },
      ),
    );
  }

  // ============================================================
  // MOBILE LAYOUT
  // ============================================================

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryBoxes(isMobile: true),
        const SizedBox(height: _gapBetweenSections),
        _buildJobInfoCard(isMobile: true),
        const SizedBox(height: _gapBetweenSections),
        _buildOfferForm(isMobile: true),
      ],
    );
  }

  // ============================================================
  // WEB LAYOUT
  // ============================================================

  Widget _buildWebLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryBoxes(isMobile: false),
        const SizedBox(height: _gapBetweenSections),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: _buildJobInfoCard(isMobile: false),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 4,
              child: _buildOfferForm(isMobile: false),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY BOXES
  // ============================================================

  Widget _buildSummaryBoxes({required bool isMobile}) {
    final gap = isMobile ? 8.0 : 14.0;

    return SizedBox(
      height: isMobile ? 100 : 110,
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryBox(
              icon: Icons.account_balance_wallet_outlined,
              label: isMobile ? 'Budget' : 'Budget Pelanggan',
              value: widget.job.price,
              color: AppColors.success,
              isCompact: isMobile,
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: _buildSummaryBox(
              icon: Icons.local_offer_outlined,
              label: isMobile ? 'Harga Anda' : 'Harga Penawaran',
              value: _formatRupiah(_parsedPrice),
              color: _accent,
              isCompact: isMobile,
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: _buildSummaryBox(
              icon: Icons.percent,
              label: isMobile ? 'Komisi 15%' : 'Komisi Platform (15%)',
              value: _formatRupiah(_commissionAmount),
              color: AppColors.primaryTeal,
              isCompact: isMobile,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 10 : 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isCompact ? 28 : 34,
            height: isCompact ? 28 : 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: isCompact ? 15 : 18,
            ),
          ),
          SizedBox(height: isCompact ? 6 : 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isCompact ? 13 : 15,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
              height: 1.1,
            ),
          ),
          SizedBox(height: isCompact ? 2 : 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isCompact ? 9.5 : 11.5,
              color: AppColors.grey500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // JOB INFO CARD
  // ============================================================

  Widget _buildJobInfoCard({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.job.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isMobile ? 20 : 22,
              fontWeight: FontWeight.w700,
              color: _cellText,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.job.category,
              style: const TextStyle(
                color: _accent,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.job.description,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.grey700,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: _tableDivider),
          const SizedBox(height: 16),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              _infoItem(
                Icons.location_on_outlined,
                widget.job.location.isNotEmpty
                    ? widget.job.location
                    : 'Lokasi tidak ditentukan',
              ),
              _infoItem(
                Icons.access_time,
                _formatRelativeTime(widget.job.time),
              ),
              _infoItem(
                Icons.calendar_month_outlined,
                'Mulai: ${_formatStartDate(widget.job.preferredStartAt?.toIso8601String())}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OFFER FORM
  // ============================================================

  Widget _buildOfferForm({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_offer_outlined,
                  color: _accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Kirim Penawaran',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: _tableDivider),
          const SizedBox(height: 18),

          // HARGA PENAWARAN
          const Text(
            'Harga Penawaran',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.grey700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _priceController,
            enabled: !_isSubmitting,
            keyboardType: const TextInputType.numberWithOptions(
              signed: false,
              decimal: false,
            ),
            inputFormatters: [
              CurrencyInputFormatter(
                leadingSymbol: 'Rp ',
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
            onChanged: (value) {
              setState(() {
                _parsedPrice = _getCleanPrice(value);
              });
            },
            decoration: InputDecoration(
              hintText: 'Rp 0',
              hintStyle: const TextStyle(
                color: AppColors.grey400,
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppColors.grey50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _tableBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _tableBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: _accent,
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // PESAN UNTUK PELANGGAN
          const Text(
            'Pesan untuk Pelanggan',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.grey700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            enabled: !_isSubmitting,
            maxLines: 4,
            maxLength: _maxMessageLength,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText:
                  'Contoh: Saya siap mengerjakan pekerjaan ini '
                  'sesuai jadwal yang disepakati.',
              hintStyle: const TextStyle(
                color: AppColors.grey400,
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppColors.grey50,
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _tableBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _tableBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: _accent,
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // USULAN WAKTU MULAI KERJA
          const Text(
            'Usulan Waktu Mulai Kerja',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.grey700,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _isSubmitting ? null : _pickProposedStartAt,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _proposedStartAt != null
                      ? _accent
                      : _tableBorder,
                  width: _proposedStartAt != null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    color: _proposedStartAt != null
                        ? _accent
                        : AppColors.grey500,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _proposedStartAt != null
                          ? _formatDateTime(_proposedStartAt!)
                          : 'Pilih tanggal dan jam',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _proposedStartAt != null
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _proposedStartAt != null
                            ? AppColors.grey900
                            : AppColors.grey400,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.grey400,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ESTIMASI DURASI
          const Text(
            'Estimasi Durasi',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.grey700,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _isSubmitting ? null : _pickEstimatedDuration,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedEstimatedDuration != null
                      ? _accent
                      : _tableBorder,
                  width: _selectedEstimatedDuration != null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timelapse_outlined,
                    color: _selectedEstimatedDuration != null
                        ? _accent
                        : AppColors.grey500,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedEstimatedDuration ??
                          'Pilih estimasi durasi pekerjaan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _selectedEstimatedDuration != null
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _selectedEstimatedDuration != null
                            ? AppColors.grey900
                            : AppColors.grey400,
                      ),
                    ),
                  ),
                  Icon(
                    _selectedEstimatedDuration != null
                        ? Icons.check_circle
                        : Icons.chevron_right,
                    color: _selectedEstimatedDuration != null
                        ? _accent
                        : AppColors.grey400,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
          const Text(
            'Pilih perkiraan waktu yang Anda butuhkan untuk '
            'menyelesaikan pekerjaan.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.grey500,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 20),

          // TOMBOL SUBMIT
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed:
                  _isSubmitting ? null : _submitOfferToApi,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      size: 18,
                    ),
              label: Text(
                _isSubmitting
                    ? 'Mengirim...'
                    : 'Kirim Penawaran',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO ITEM
  // ============================================================

  Widget _infoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: AppColors.grey400,
          size: 18,
        ),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 220,
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.grey600,
            ),
          ),
        ),
      ],
    );
  }
}
