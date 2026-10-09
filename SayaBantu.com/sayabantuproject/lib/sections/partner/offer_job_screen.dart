import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

import '../../models/partner_job_model.dart';
import '../../services/api_service.dart';

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

  int _parsedPrice = 0;
  bool _isSubmitting = false;

  // ============================================================
  // DESIGN TOKENS — disamakan dengan DashboardHeader / PaymentScreen
  // ============================================================

  static const Color _accent = Color(0xFFF97316);
  static const Color _tableBorder = Color(0xFFE5E7EB);
  static const Color _tableDivider = Color(0xFFF3F4F6);
  static const Color _headerText = Color(0xFF6B7280);
  static const Color _cellText = Color(0xFF111827);

  static const double _commissionPercent = 15.0;

  // Spacing — mengikuti pola DashboardHeader
  static const double _gapAfterHeader = 16;
  static const double _gapBetweenSections = 16;

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // ============================================================
  // HELPER — FORMAT RUPIAH
  // ============================================================

  String _formatRupiah(int amount) {
    if (amount <= 0) return 'Rp 0';
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp $buffer';
  }

  int get _commissionAmount {
    return (_parsedPrice * _commissionPercent / 100).round();
  }

  // ============================================================
  // FORMAT WAKTU RELATIF
  // ============================================================

  String _formatRelativeTime(String rawTime) {
    if (rawTime.isEmpty) return 'Waktu fleksibel';

    try {
      final DateTime dateTime = DateTime.parse(rawTime);
      final DateTime now = DateTime.now();
      final Duration diff = now.difference(dateTime);

      if (diff.isNegative) return 'Baru saja';
      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      if (diff.inDays < 7) return '${diff.inDays} hari lalu';

      const bulan = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];

      return '${dateTime.day} ${bulan[dateTime.month - 1]} ${dateTime.year}';
    } catch (_) {
      return rawTime;
    }
  }

  // ============================================================
  // PARSE HARGA
  // ============================================================

  int _getCleanPrice(String value) {
    final String cleanDigits = value.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(cleanDigits) ?? 0;
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _submitOfferToApi() async {
    final String rawPrice = _priceController.text.trim();
    final String trimmedMessage = _messageController.text.trim();

    if (rawPrice.isEmpty) {
      _showSnack("Harap masukkan harga penawaran.", warning: true);
      return;
    }

    if (rawPrice.contains('-')) {
      _showSnack("Harga penawaran tidak boleh bernilai negatif.", error: true);
      return;
    }

    _parsedPrice = _getCleanPrice(rawPrice);

    if (_parsedPrice <= 0) {
      _showSnack(
        "Harap masukkan harga penawaran (minimal Rp 1).",
        warning: true,
      );
      return;
    }

    if (trimmedMessage.isEmpty) {
      _showSnack(
        "Harap isi pesan untuk pelanggan terlebih dahulu.",
        warning: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await ApiService.post(
        '/jobs/${widget.job.id}/apply',
        {
          'offered_price': _parsedPrice,
          'message': trimmedMessage,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        _showSnack("Penawaran berhasil dikirim!", success: true);
        widget.onSubmit();
      } else {
        if (!mounted) return;

        String errorMessage = "Gagal mengirim penawaran.";
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map<String, dynamic>) {
            errorMessage =
                errorData['message']?.toString() ?? errorMessage;
          }
        } catch (_) {}

        _showSnack(errorMessage, error: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack("Terjadi kesalahan koneksi: $e", error: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
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

    Color bg = Colors.grey;
    if (success) bg = Colors.green;
    if (warning) bg = Colors.amber;
    if (error) bg = Colors.red;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: bg,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================
  // ✅ Padding horizontal disamakan dgn CustomerDashboard
  //    mobile 16 / tablet 24 / desktop 28  (bukan 32)
  // ✅ TIDAK ada Center + ConstrainedBox — konten nempel kiri
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: const Text(
          "Ambil & Nego",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
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
  // MOBILE
  // ============================================================

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 3 kotak sejajar (budget / harga / komisi)
        _buildSummaryBoxes(isMobile: true),

        const SizedBox(height: _gapBetweenSections),

        _buildJobInfoCard(isMobile: true),

        const SizedBox(height: _gapBetweenSections),

        _buildOfferForm(isMobile: true),
      ],
    );
  }

  // ============================================================
  // WEB
  // ============================================================

  Widget _buildWebLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 3 kotak sejajar (budget / harga / komisi)
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
  // 3 KOTAK SEJAJAR — TANPA SCROLL
  // ============================================================

  Widget _buildSummaryBoxes({required bool isMobile}) {
    final gap = isMobile ? 8.0 : 14.0;

    return SizedBox(
      height: isMobile ? 100 : 110,
      child: Row(
        children: [
          // KOTAK 1 — Budget Pelanggan
          Expanded(
            child: _buildSummaryBox(
              icon: Icons.account_balance_wallet_outlined,
              label: isMobile ? 'Budget' : 'Budget Pelanggan',
              value: widget.job.price,
              color: const Color(0xFF16A34A),
              isCompact: isMobile,
            ),
          ),

          SizedBox(width: gap),

          // KOTAK 2 — Harga Anda (live)
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

          // KOTAK 3 — Komisi (live)
          Expanded(
            child: _buildSummaryBox(
              icon: Icons.percent,
              label: isMobile
                  ? 'Komisi 15%'
                  : 'Komisi Platform (15%)',
              value: _formatRupiah(_commissionAmount),
              color: const Color(0xFF7C3AED),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
        border: Border.all(color: _tableBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: isCompact ? 28 : 34,
            height: isCompact ? 28 : 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: isCompact ? 15 : 18,
            ),
          ),
          SizedBox(height: isCompact ? 6 : 8),

          // Value
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isCompact ? 13 : 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              height: 1.1,
            ),
          ),
          SizedBox(height: isCompact ? 2 : 3),

          // Label
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isCompact ? 9.5 : 11.5,
              color: const Color(0xFF64748B),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _tableBorder),
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
              color: _accent.withOpacity(0.1),
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
              color: Color(0xFF374151),
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
                    : "Lokasi tidak ditentukan",
              ),
              _infoItem(
                Icons.access_time,
                _formatRelativeTime(widget.job.time),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _tableBorder),
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
                  color: _accent.withOpacity(0.12),
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
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(height: 1, color: _tableDivider),
          const SizedBox(height: 18),

          // HARGA
          const Text(
            "Harga Penawaran",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF374151),
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
                leadingSymbol: "Rp ",
                thousandSeparator: ThousandSeparator.Period,
                mantissaLength: 0,
              ),
              TextInputFormatter.withFunction(
                (oldValue, newValue) {
                  if (newValue.text.contains('-')) return oldValue;

                  final digits =
                      newValue.text.replaceAll(RegExp(r'[^\d]'), '');
                  if (digits.length > 8) return oldValue;

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
              hintText: "Rp 0",
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 13,
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
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
                borderSide: const BorderSide(color: _accent, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // PESAN
          const Text(
            "Pesan untuk Pelanggan",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _messageController,
            enabled: !_isSubmitting,
            maxLines: 4,
            maxLength: 500,
            style: const TextStyle(fontSize: 13, height: 1.5),
            decoration: InputDecoration(
              hintText:
                  "Contoh: Saya siap mengerjakan hari ini dengan garansi servis.",
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 13,
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
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
                borderSide: const BorderSide(color: _accent, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // TOMBOL SUBMIT
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
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send, size: 18),
              label: Text(
                _isSubmitting ? "Mengirim..." : "Kirim Penawaran",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
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
        Icon(icon, color: const Color(0xFF94A3B8), size: 18),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }
}