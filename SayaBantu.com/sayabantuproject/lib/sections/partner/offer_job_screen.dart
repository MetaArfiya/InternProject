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
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  int _parsedPrice = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
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

      // Waktu di masa depan
      if (diff.isNegative) return 'Baru saja';

      // < 1 menit
      if (diff.inMinutes < 1) return 'Baru saja';

      // < 1 jam
      if (diff.inMinutes < 60) {
        return '${diff.inMinutes} menit lalu';
      }

      // < 1 hari
      if (diff.inHours < 24) {
        return '${diff.inHours} jam lalu';
      }

      // < 7 hari
      if (diff.inDays < 7) {
        return '${diff.inDays} hari lalu';
      }

      // >= 7 hari
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

      return '${dateTime.day} ${bulan[dateTime.month - 1]} ${dateTime.year}';
    } catch (_) {
      // Jika bukan format DateTime
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
  // SUBMIT OFFER
  // ============================================================

  Future<void> _submitOfferToApi() async {
    final String rawPrice = _priceController.text.trim();
    final String trimmedMessage = _messageController.text.trim();

    // ==========================================================
    // VALIDASI HARGA
    // ==========================================================

    if (rawPrice.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Harap masukkan harga penawaran."),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    // Pastikan tanda negatif tidak bisa dikirim
    if (rawPrice.contains('-')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Harga penawaran tidak boleh bernilai negatif."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _parsedPrice = _getCleanPrice(rawPrice);

    // Harga harus lebih dari 0
    if (_parsedPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Harap masukkan harga penawaran (minimal Rp 1)."),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    // ==========================================================
    // VALIDASI PESAN
    // ==========================================================

    if (trimmedMessage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Harap isi pesan untuk pelanggan terlebih dahulu."),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Penawaran berhasil dikirim!"),
            backgroundColor: Colors.green,
          ),
        );

        widget.onSubmit();
      } else {
        if (!mounted) return;

        String errorMessage = "Gagal mengirim penawaran.";

        try {
          final errorData = jsonDecode(response.body);

          if (errorData is Map<String, dynamic>) {
            errorMessage = errorData['message']?.toString() ??
                "Gagal mengirim penawaran.";
          }
        } catch (_) {
          errorMessage = "Gagal mengirim penawaran.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Terjadi kesalahan koneksi: $e"),
          backgroundColor: Colors.red,
        ),
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final padding = isMobile ? 16.0 : 30.0;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBack,
            ),
            title: const Text("Ambil & Nego"),
            centerTitle: true,
            backgroundColor: Theme.of(context).cardColor,
            foregroundColor:
                Theme.of(context).textTheme.bodyLarge?.color,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildJobInfo(context, isMobile),

                const SizedBox(height: 25),

                // ==================================================
                // FORM HARGA
                // ==================================================

                Text(
                  "Harga Penawaran",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 15 : 16,
                  ),
                ),

                const SizedBox(height: 10),

              TextField(
                controller: _priceController,
                enabled: !_isSubmitting,

                keyboardType: const TextInputType.numberWithOptions(
                  signed: false,
                  decimal: false,
                ),

                onChanged: (value) {
                  // Ambil hanya angka
                  final String cleanDigits =
                      value.replaceAll(RegExp(r'[^\d]'), '');

                  // Maksimal 8 digit
                  if (cleanDigits.length > 8) {
                    final String limitedDigits = cleanDigits.substring(0, 8);

                    final int limitedPrice =
                        int.tryParse(limitedDigits) ?? 0;

                    final String formattedPrice =
                        toCurrencyString(
                      limitedPrice.toString(),
                      leadingSymbol: 'Rp ',
                      thousandSeparator: ThousandSeparator.Period,
                      mantissaLength: 0,
                    );

                    _priceController.value = TextEditingValue(
                      text: formattedPrice,
                      selection: TextSelection.collapsed(
                        offset: formattedPrice.length,
                      ),
                    );

                    setState(() {
                      _parsedPrice = limitedPrice;
                    });

                    return;
                  }

                  // Tolak tanda minus
                  if (value.contains('-')) {
                    final String formattedPrice =
                        cleanDigits.isEmpty
                            ? ''
                            : toCurrencyString(
                                cleanDigits,
                                leadingSymbol: 'Rp ',
                                thousandSeparator: ThousandSeparator.Period,
                                mantissaLength: 0,
                              );

                    _priceController.value = TextEditingValue(
                      text: formattedPrice,
                      selection: TextSelection.collapsed(
                        offset: formattedPrice.length,
                      ),
                    );

                    setState(() {
                      _parsedPrice = int.tryParse(cleanDigits) ?? 0;
                    });

                    return;
                  }

                  setState(() {
                    _parsedPrice = int.tryParse(cleanDigits) ?? 0;
                  });
                },

                inputFormatters: [
                  CurrencyInputFormatter(
                    leadingSymbol: "Rp ",
                    thousandSeparator: ThousandSeparator.Period,
                    mantissaLength: 0,
                  ),

                  TextInputFormatter.withFunction(
                    (oldValue, newValue) {
                      // Tidak boleh ada minus
                      if (newValue.text.contains('-')) {
                        return oldValue;
                      }

                      // Hitung jumlah digit saja
                      final String digits =
                          newValue.text.replaceAll(RegExp(r'[^\d]'), '');

                      // Maksimal 8 digit
                      if (digits.length > 8) {
                        return oldValue;
                      }

                      return newValue;
                    },
                  ),
                ],

                decoration: InputDecoration(
                  hintText: "Rp 0",
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

                const SizedBox(height: 22),

                // ==================================================
                // FORM PESAN
                // ==================================================

                Text(
                  "Pesan untuk Pelanggan",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 15 : 16,
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: _messageController,
                  enabled: !_isSubmitting,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText:
                        "Contoh: Saya siap mengerjakan hari ini dengan garansi servis.",
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ==================================================
                // TOMBOL SUBMIT
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed:
                        _isSubmitting ? null : _submitOfferToApi,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                      _isSubmitting
                          ? "Mengirim..."
                          : "Kirim Penawaran",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
        );
      },
    );
  }

  // ============================================================
  // JOB INFO
  // ============================================================

  Widget _buildJobInfo(
    BuildContext context,
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.job.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isMobile ? 22 : 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            widget.job.category,
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            widget.job.description,
            style: const TextStyle(
              height: 1.6,
            ),
          ),

          const SizedBox(height: 22),

          // ============================================
          // INFO: LOKASI + WAKTU RELATIF
          // ============================================

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

          const Divider(height: 35),

          const Text(
            "Budget Pelanggan",
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            widget.job.price,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isMobile ? 24 : 28,
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO ITEM
  // ============================================================

  Widget _infoItem(
    IconData icon,
    String text,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.grey,
          size: 20,
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
          ),
        ),
      ],
    );
  }
}