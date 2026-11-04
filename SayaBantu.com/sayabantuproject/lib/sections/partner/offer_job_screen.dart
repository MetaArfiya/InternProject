import 'dart:convert';

import 'package:flutter/material.dart';

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

  // ============================================================
  // STATE
  // ============================================================

  int get _parsedPrice => widget.job.initialBudget.round();
  bool _isSubmitting = false;

  // ============================================================
  // DESIGN TOKENS
  // ============================================================

  static const Color _accent = AppColors.primaryTeal;
  static const Color _tableDivider = AppColors.grey100;
  static const Color _cellText = AppColors.grey900;

  static const double _commissionPercent = 15.0;
  static const double _gapBetweenSections = 16;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
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
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
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
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    final day = wibDateTime.day.toString().padLeft(2, '0');
    final month = bulan[wibDateTime.month - 1];
    final year = wibDateTime.year;
    final hour = wibDateTime.hour.toString().padLeft(2, '0');
    final minute = wibDateTime.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute';
  }

  // ============================================================
  // SUBMIT OFFER
  // ============================================================

  Future<void> _submitOfferToApi() async {
    if (_isSubmitting) return;
    if (widget.job.preferredStartAt == null || widget.job.duration == '-') {
      _showSnack(
        'Jadwal atau durasi dari pelanggan belum tersedia.',
        error: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await ApiService.post('/jobs/${widget.job.id}/apply', {
        'expected_initial_budget': widget.job.initialBudget,
        'expected_tittle': widget.job.title,
        'expected_description': widget.job.description,
      });

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnack('Pekerjaan berhasil diterima!', success: true);

        widget.onSubmit();
        return;
      }

      // HANDLE ERROR RESPONSE
      String errorMessage = 'Gagal menerima pekerjaan.';

      try {
        final errorData = jsonDecode(response.body);

        if (errorData is Map<String, dynamic>) {
          errorMessage = errorData['message']?.toString() ?? errorMessage;

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
          errorMessage = 'Sesi login berakhir. Silakan login ulang.';
        } else if (response.statusCode == 403) {
          errorMessage = 'Anda tidak memiliki akses untuk menerima pekerjaan.';
        } else if (response.statusCode == 404) {
          errorMessage = 'Pekerjaan tidak ditemukan.';
        } else if (response.statusCode == 422) {
          errorMessage = 'Data pekerjaan tidak valid.';
        } else if (response.statusCode >= 500) {
          errorMessage = 'Terjadi kesalahan pada server.';
        }
      }

      _showSnack(errorMessage, error: true);
    } catch (e) {
      if (!mounted) return;

      _showSnack('Terjadi kesalahan koneksi: $e', error: true);
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

          final horizontalPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 28.0);

          final verticalPadding = isMobile ? 16.0 : 28.0;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: isMobile ? _buildMobileLayout() : _buildWebLayout(),
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
            Expanded(flex: 5, child: _buildJobInfoCard(isMobile: false)),
            const SizedBox(width: 24),
            Expanded(flex: 4, child: _buildOfferForm(isMobile: false)),
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
              value: _formatRupiah(widget.job.initialBudget.round()),
              color: AppColors.success,
              isCompact: isMobile,
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: _buildSummaryBox(
              icon: Icons.percent,
              label: isMobile ? 'Komisi' : 'Komisi Platform',
              value: _formatRupiah(_commissionAmount),
              color: AppColors.primaryTeal,
              isCompact: isMobile,
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: _buildSummaryBox(
              icon: Icons.account_balance_wallet_outlined,
              label: isMobile ? 'Pendapatan' : 'Estimasi Pendapatan',
              value: _formatRupiah(_parsedPrice - _commissionAmount),
              color: _accent,
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
            child: Icon(icon, color: color, size: isCompact ? 15 : 18),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
    final startAt = widget.job.preferredStartAt;

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
                  Icons.handshake_outlined,
                  color: _accent,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tawaran Pelanggan',
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
          _infoItem(
            Icons.payments_outlined,
            'Harga tetap: ${_formatRupiah(widget.job.initialBudget.round())}',
          ),
          const SizedBox(height: 14),
          _infoItem(
            Icons.calendar_month_outlined,
            startAt == null
                ? 'Jadwal mulai tidak tersedia'
                : _formatDateTime(startAt),
          ),
          const SizedBox(height: 14),
          _infoItem(Icons.timelapse_outlined, 'Durasi: ${widget.job.duration}'),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.sectionAltLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Dengan menerima pekerjaan, Anda menyetujui harga dan jadwal yang ditentukan pelanggan.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.grey700,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitOfferToApi,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline, size: 18),
              label: Text(
                _isSubmitting ? 'Memproses...' : 'Ambil Pekerjaan',
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
  // INFO ITEM
  // ============================================================

  Widget _infoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.grey400, size: 18),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, color: AppColors.grey600),
          ),
        ),
      ],
    );
  }
}
