import 'dart:convert';
import 'package:flutter/material.dart';
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
  // 🆕 FORMAT WAKTU RELATIF
  // Hanya tampilkan yang perlu saja
  // ============================================================
  String _formatRelativeTime(String rawTime) {
    if (rawTime.isEmpty) return 'Waktu fleksibel';

    try {
      // Coba parse sebagai DateTime
      final DateTime dateTime = DateTime.parse(rawTime);
      final DateTime now = DateTime.now();
      final Duration diff = now.difference(dateTime);

      // Waktu di masa depan → anggap "Baru saja"
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

      // >= 7 hari → tampilkan tanggal saja
      const bulan = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      return '${dateTime.day} ${bulan[dateTime.month - 1]} ${dateTime.year}';
    } catch (_) {
      // Kalau bukan format DateTime (misal sudah "2 hari lalu" dari DB)
      // pakai apa adanya
      return rawTime;
    }
  }

  // ============================================================
  // SUBMIT OFFER
  // ============================================================
  Future<void> _submitOfferToApi() async {
    if (_parsedPrice <= 0 && _priceController.text.isNotEmpty) {
      final String cleanDigits =
          _priceController.text.replaceAll(RegExp(r'[^\d]'), '');
      _parsedPrice = int.tryParse(cleanDigits) ?? 0;
    }

    final String trimmedMessage = _messageController.text.trim();

    if (_parsedPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Harap masukkan harga penawaran (minimal Rp 1)."),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

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

        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? "Gagal mengirim penawaran.";

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
            foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildJobInfo(context, isMobile),
                const SizedBox(height: 25),

                // FORM HARGA
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
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final String cleanDigits =
                        value.replaceAll(RegExp(r'[^\d]'), '');
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

                // FORM PESAN
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

                // TOMBOL SUBMIT
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitOfferToApi,
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
                      _isSubmitting ? "Mengirim..." : "Kirim Penawaran",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
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
  Widget _buildJobInfo(BuildContext context, bool isMobile) {
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
            style: const TextStyle(height: 1.6),
          ),
          const SizedBox(height: 22),

          // ============================================
          // ✅ INFO: LOKASI + WAKTU RELATIF
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
              // ✅ Ganti timestamp penuh jadi waktu relatif
              _infoItem(
                Icons.access_time,
                _formatRelativeTime(widget.job.time),
              ),
            ],
          ),

          const Divider(height: 35),
          const Text(
            "Budget Pelanggan",
            style: TextStyle(color: Colors.grey),
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

  Widget _infoItem(IconData icon, String text) {
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
          constraints: const BoxConstraints(maxWidth: 220),
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