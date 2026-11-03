import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/job_model.dart';
import '../../models/offer_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/offer_card.dart';

class OfferScreen extends StatelessWidget {
  final JobModel job;
  final Function(OfferModel) onAccept;
  final VoidCallback onBack;
  final Function(OfferModel) onOpenProfile;
  final Function(OfferModel) onReject;

  const OfferScreen({
    super.key,
    required this.job,
    required this.onAccept,
    required this.onBack,
    required this.onOpenProfile,
    required this.onReject,
  });

  static const Color _green = Color(0xFF16A34A);
  static const Color _red = Color(0xFFDC2626);

  bool get _canRespond {
    return job.status.toLowerCase().trim() == 'mencari mitra';
  }

  // ============================================================
  // FETCH PENAWARAN
  // ============================================================

  Future<List<OfferModel>> _fetchBids() async {
    final response = await ApiService.get('/jobs/${job.id}');

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal memuat penawaran (Kode: ${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);

    List<dynamic> bidsJson = [];

    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];

      if (data is Map) {
        final bids = data['bids'] ?? data['offers'];
        if (bids is List) {
          bidsJson = bids;
        }
      } else if (data is List) {
        bidsJson = data;
      }

      if (bidsJson.isEmpty) {
        final bids = decoded['bids'] ?? decoded['offers'];
        if (bids is List) {
          bidsJson = bids;
        }
      }
    }

    return bidsJson
        .whereType<Map>()
        .map(
          (item) => OfferModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  // ============================================================
  // TERIMA PENAWARAN (DENGAN PIN)
  // ============================================================

  Future<void> _handleAccept(BuildContext context, OfferModel offer, String pin) async {
    if (!_canRespond) {
      _showMessage(
        context,
        'Pekerjaan ini sudah tidak menerima penawaran baru.',
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryTeal,
        ),
      ),
    );

    try {
      final response = await ApiService.post(
        '/jobs/accept-bid/${offer.id}',
        {
          'pin': pin, // Mengirim PIN ke Backend Laravel
        },
      );

      if (!context.mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showMessage(
          context,
          'Penawaran berhasil diterima.',
        );
        onAccept(offer);
      } else {
        String message =
            'Gagal menerima penawaran (Kode: ${response.statusCode})';

        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['message'] != null) {
            message = decoded['message'].toString();
          }
        } catch (_) {}

        _showMessage(context, message, isError: true);
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showMessage(
        context,
        'Kesalahan jaringan: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showMessage(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _red : AppColors.primaryTeal,
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
          onPressed: onBack,
        ),
        elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.grey900,
        title: const Text(
          'Penawaran Mitra',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.grey900,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Pada layar split/tablet, tabel terlalu sempit untuk kolom aksi
          // Terima, Tolak, dan Profil. Gunakan kartu sampai ruang cukup.
          final isMobile = constraints.maxWidth < 1100;

          return Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Budget: ${job.price}',
                  style: const TextStyle(
                    color: AppColors.grey500,
                  ),
                ),
                const SizedBox(height: 14),

                if (!_canRespond) ...[
                  _buildStatusBanner(),
                  const SizedBox(height: 20),
                ],

                Expanded(
                  child: FutureBuilder<List<OfferModel>>(
                    future: _fetchBids(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryTeal,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return _buildError(snapshot.error.toString());
                      }

                      final bids = snapshot.data ?? [];

                      if (bids.isEmpty) {
                        return const Center(
                          child: Text(
                            'Belum ada mitra yang mengajukan penawaran.',
                            style: TextStyle(
                              color: AppColors.grey500,
                            ),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${bids.length} Mitra Mengirim Penawaran',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.grey900,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: isMobile
                                ? _buildMobileList(context, bids)
                                : _buildWebTable(context, bids),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: _red,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'Terjadi kesalahan:\n$message',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _red),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE
  // ============================================================

  Widget _buildMobileList(BuildContext context, List<OfferModel> bids) {
    return ListView.separated(
      itemCount: bids.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final offer = bids[index];

        return OfferCard(
          job: job,
          offer: offer,
          canRespond: _canRespond,
          onAccept: (item) => _showAcceptDialog(context, item), // Mengarah ke dialog konfirmasi dulu
          onOpenProfile: onOpenProfile,
          onReject: onReject,
        );
      },
    );
  }

  // ============================================================
  // DESKTOP TABLE (MENGGUNAKAN DATATABLE AGAR RAPI)
  // ============================================================

  Widget _buildWebTable(BuildContext context, List<OfferModel> bids) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.10),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Kurangi padding horizontal header/baris sebelum membagi kolom,
              // agar total lebar isi Row tidak melebihi lebar layar.
              final double contentWidth =
                  (constraints.maxWidth - 40)
                      .clamp(0.0, double.infinity)
                      .toDouble();
              final double wMitra = contentWidth * 0.20;
              final double wJadwal = contentWidth * 0.15;
              final double wDurasi = contentWidth * 0.10;
              final double wJob = contentWidth * 0.10;
              final double wHarga = contentWidth * 0.12;
              final double wStatus = contentWidth * 0.13;
              final double wAksi = contentWidth * 0.20;

              return Column(
                children: [
                  // HEADER
                  Container(
                    color: AppColors.grey50,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        SizedBox(width: wMitra, child: const _TableHeader('Mitra')),
                        SizedBox(width: wJadwal, child: const _TableHeader('Jadwal Mulai')),
                        SizedBox(width: wDurasi, child: const _TableHeader('Durasi')),
                        SizedBox(width: wJob, child: const _TableHeader('Job Selesai')),
                        SizedBox(width: wHarga, child: const _TableHeader('Harga')),
                        SizedBox(width: wStatus, child: const _TableHeader('Status')),
                        SizedBox(width: wAksi, child: const _TableHeader('Aksi')),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.grey100),

                  // ROWS
                  ...bids.map((offer) {
                    final rowColor = offer.isAccepted
                        ? const Color(0xFFF0FDF4)
                        : offer.isRejected
                            ? const Color(0xFFFEF2F2)
                            : Colors.transparent;

                    return Container(
                      color: rowColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          // 1. Mitra
                          SizedBox(
                            width: wMitra,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.mint.withValues(alpha: 0.20),
                                  child: const Icon(
                                    Icons.person,
                                    color: AppColors.primaryTeal,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        offer.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.grey900,
                                        ),
                                      ),
                                      if (offer.verified)
                                        const Text(
                                          'Terverifikasi',
                                          style: TextStyle(
                                            color: _green,
                                            fontSize: 11,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 2. Jadwal
                          SizedBox(
                            width: wJadwal,
                            child: Text(
                              offer.proposedStartAtText,
                              style: const TextStyle(fontSize: 12, color: AppColors.grey900),
                            ),
                          ),

                          // 3. Durasi
                          SizedBox(
                            width: wDurasi,
                            child: Text(
                              offer.estimatedDurationText,
                              style: const TextStyle(fontSize: 12, color: AppColors.grey900),
                            ),
                          ),

                          // 4. Job Selesai
                          SizedBox(
                            width: wJob,
                            child: Text(
                              '${offer.jobsCompleted} Job',
                              style: const TextStyle(fontSize: 12, color: AppColors.grey900),
                            ),
                          ),

                          // 5. Harga
                          SizedBox(
                            width: wHarga,
                            child: Text(
                              offer.price,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryTeal,
                              ),
                            ),
                          ),

                          // 6. Status
                          SizedBox(
                            width: wStatus,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _buildStatusBadge(offer),
                            ),
                          ),

                          // 7. Aksi
                          SizedBox(
                            width: wAksi,
                            child: _buildTableActions(context, offer),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  
                  const Divider(height: 1, color: AppColors.grey100),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(OfferModel offer) {
    final Color color;
    final Color background;
    final IconData icon;
    final String label;

    if (offer.isAccepted) {
      color = _green;
      background = const Color(0xFFDCFCE7);
      icon = Icons.check_circle;
      label = 'Terpilih';
    } else if (offer.isRejected) {
      color = _red;
      background = const Color(0xFFFEE2E2);
      icon = Icons.cancel;
      label = 'Ditolak';
    } else {
      color = AppColors.primaryTeal;
      background = AppColors.mint.withValues(alpha: 0.20);
      icon = Icons.hourglass_top;
      label = 'Menunggu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABEL ACTIONS
  // ============================================================

  Widget _buildTableActions(BuildContext context, OfferModel offer) {
    if (!offer.isPending) {
      return TextButton.icon(
        onPressed: () => onOpenProfile(offer),
        icon: const Icon(Icons.person_outline, size: 16),
        label: const Text('Lihat Profil'),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: _canRespond ? () => _showAcceptDialog(context, offer) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryTeal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: const Text('Terima', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 6),
        OutlinedButton(
          onPressed: _canRespond ? () => onReject(offer) : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: _red,
            side: const BorderSide(color: _red),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: const Text('Tolak', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: () => onOpenProfile(offer),
          icon: const Icon(Icons.person_search, size: 20, color: AppColors.grey600),
          tooltip: 'Lihat Profil',
        ),
      ],
    );
  }

  // ============================================================
  // KONFIRMASI TERIMA & FORM PIN
  // ============================================================

  void _showAcceptDialog(BuildContext context, OfferModel offer) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: const Text(
          'Konfirmasi Penawaran',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apakah Anda yakin ingin memilih ${offer.name}?',
              ),
              const SizedBox(height: 16),
              _detailRow('Harga', offer.price),
              const SizedBox(height: 10),
              _detailRow('Jadwal mulai', offer.proposedStartAtText),
              const SizedBox(height: 10),
              _detailRow('Estimasi durasi', offer.estimatedDurationText),
              const SizedBox(height: 14),
              const Text(
                'Dengan menerima penawaran, Anda menyetujui '
                'harga, jadwal mulai, dan estimasi durasi '
                'yang diajukan Mitra.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.grey600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Tutup dialog konfirmasi
              _showPinDialog(context, offer); // Lanjut ke form PIN
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Pilih'),
          ),
        ],
      ),
    );
  }

  void _showPinDialog(BuildContext context, OfferModel offer) {
    final TextEditingController pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (pinContext) => AlertDialog(
        title: const Text('Konfirmasi PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukkan PIN Anda untuk menyetujui penawaran ini dan menahan saldo.'),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'PIN',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(pinContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final pin = pinController.text;
              if (pin.isEmpty) return;
              
              Navigator.pop(pinContext); // Tutup form PIN
              _handleAccept(context, offer, pin); // Kirim data ke backend
            },
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.grey500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.grey900,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BANNER STATUS PEKERJAAN
  // ============================================================

  Widget _buildStatusBanner() {
    final status = job.status.toLowerCase().trim();

    String message;
    Color color;
    Color background;
    IconData icon;

    if (status.contains('selesai')) {
      message = 'Pekerjaan sudah selesai.';
      color = _green;
      background = const Color(0xFFDCFCE7);
      icon = Icons.check_circle;
    } else if (status.contains('konfirmasi')) {
      message = 'Pekerjaan sedang menunggu konfirmasi.';
      color = AppColors.primaryTeal;
      background = AppColors.mint.withValues(alpha: 0.20);
      icon = Icons.hourglass_top;
    } else if (status.contains('dikerjakan') || status.contains('proses')) {
      message = 'Pekerjaan sedang dikerjakan.';
      color = AppColors.primaryTeal;
      background = AppColors.mint.withValues(alpha: 0.20);
      icon = Icons.engineering;
    } else if (status.contains('batal') || status.contains('cancel')) {
      message = 'Pekerjaan telah dibatalkan.';
      color = _red;
      background = const Color(0xFFFEE2E2);
      icon = Icons.cancel;
    } else {
      message = 'Penawaran untuk pekerjaan ini sudah ditutup.';
      color = AppColors.grey700;
      background = AppColors.grey200;
      icon = Icons.info_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HELPER WIDGET — Header Tabel
// ============================================================

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.grey500,
      ),
    );
  }
}
