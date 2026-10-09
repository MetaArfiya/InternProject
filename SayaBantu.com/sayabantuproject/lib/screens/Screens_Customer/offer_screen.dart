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

  bool get _canRespond {
    final s = job.status.toLowerCase().trim();
    return s == 'mencari mitra';
  }

  // ============================================================
  // FETCH BIDS
  // ============================================================

  Future<List<OfferModel>> _fetchBids() async {
    final response = await ApiService.get('/jobs/${job.id}');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      List<dynamic> bidsJson = [];

      if (decoded is Map<String, dynamic>) {
        var target =
            decoded['data']?['bids'] ?? decoded['bids'] ?? decoded['data'];
        if (target is List) {
          bidsJson = target;
        }
      }

      return bidsJson.map((json) => OfferModel.fromJson(json)).toList();
    } else {
      throw Exception("Gagal memuat penawaran (Kode: ${response.statusCode})");
    }
  }

  // ============================================================
  // HANDLE ACCEPT
  // ============================================================

  Future<void> _handleAccept(BuildContext context, OfferModel offer) async {
    if (!_canRespond) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pekerjaan ini sudah tidak menerima penawaran baru."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryTeal),
      ),
    );

    try {
      final response =
          await ApiService.post('/jobs/accept-bid/${offer.id}', {});

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Penawaran berhasil diterima!"),
            backgroundColor: AppColors.primaryTeal, // ← teal
          ),
        );
        onAccept(offer);
      } else {
        String message =
            "Gagal menerima penawaran (Kode: ${response.statusCode})";
        try {
          final decoded = jsonDecode(response.body);
          if (decoded['message'] != null) {
            message = decoded['message'].toString();
          }
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Kesalahan jaringan: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sectionAltLight, // ← mint muda
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.grey900,
        title: const Text(
          "Penawaran Mitra",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.grey900,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;

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
                  "Budget : ${job.price}",
                  style: const TextStyle(color: AppColors.grey500),
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
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryTeal,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Terjadi kesalahan: ${snapshot.error}",
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      final bids = snapshot.data ?? [];

                      if (bids.isEmpty) {
                        return const Center(
                          child: Text(
                            "Belum ada mitra yang mengajukan penawaran.",
                            style: TextStyle(color: AppColors.grey500),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${bids.length} Mitra Mengirim Penawaran",
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
  // MOBILE — Card
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
          onAccept: (o) => _handleAccept(context, o),
          onOpenProfile: onOpenProfile,
          onReject: onReject,
        );
      },
    );
  }

  // ============================================================
  // WEB — Tabel
  // ============================================================

  Widget _buildWebTable(BuildContext context, List<OfferModel> bids) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryTeal.withOpacity(0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTableHeader(),
          const Divider(height: 1, color: AppColors.grey100),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (int i = 0; i < bids.length; i++) ...[
                    _buildTableRow(context, bids[i]),
                    if (i != bids.length - 1)
                      const Divider(height: 1, color: AppColors.grey100),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(flex: 4, child: _headerCell('Mitra')),
          Expanded(flex: 2, child: _headerCell('Job Selesai')),
          Expanded(flex: 3, child: _headerCell('Harga Penawaran')),
          Expanded(flex: 3, child: _headerCell('Status')),
          Expanded(flex: 5, child: _headerCell('Aksi')),
        ],
      ),
    );
  }

  Widget _headerCell(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.grey500,
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, OfferModel offer) {
    final isAccepted = offer.isAccepted;
    final isRejected = offer.isRejected;

    Color? rowBg;
    if (isAccepted) {
      rowBg = const Color(0xFFF0FDF4);
    } else if (isRejected) {
      rowBg = const Color(0xFFFEF2F2);
    }

    return Container(
      color: rowBg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Kolom 1: Mitra
          Expanded(
            flex: 4,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: isAccepted
                      ? const Color(0xFFDCFCE7)
                      : AppColors.mint.withOpacity(0.20), // ← dari orange soft
                  child: Icon(
                    Icons.person,
                    color: isAccepted
                        ? const Color(0xFF16A34A)
                        : AppColors.primaryTeal, // ← dari orange
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
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
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey900,
                        ),
                      ),
                      if (offer.verified) ...[
                        const SizedBox(height: 4),
                        const Row(
                          children: [
                            Icon(Icons.verified,
                                color: Color(0xFF16A34A), size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Terverifikasi',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Kolom 2: Job Selesai
          Expanded(
            flex: 2,
            child: Text(
              '${offer.jobsCompleted} Job',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.grey900,
              ),
            ),
          ),

          // Kolom 3: Harga
          Expanded(
            flex: 3,
            child: Text(
              offer.price,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isAccepted
                    ? const Color(0xFF16A34A)
                    : AppColors.primaryTeal, // ← dari orange
              ),
            ),
          ),

          // Kolom 4: Status
          Expanded(
            flex: 3,
            child: _buildStatusBadge(offer),
          ),

          // Kolom 5: Aksi
          Expanded(
            flex: 5,
            child: _buildTableActions(context, offer),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(OfferModel offer) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    if (offer.isAccepted) {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF16A34A);
      icon = Icons.check_circle;
      label = 'Terpilih';
    } else if (offer.isRejected) {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
      icon = Icons.cancel;
      label = 'Ditolak';
    } else {
      // pending → mint/teal (dari amber)
      bg = AppColors.mint.withOpacity(0.20);
      fg = AppColors.primaryTeal;
      icon = Icons.hourglass_top;
      label = 'Menunggu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AKSI DI TABEL
  // ============================================================

  Widget _buildTableActions(BuildContext context, OfferModel offer) {
    // Sudah diputuskan → cuma tombol "Lihat Profil"
    if (!offer.isPending) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () => onOpenProfile(offer),
          icon: const Icon(Icons.person_outline, size: 16),
          label: const Text('Lihat Profil'),
          style: OutlinedButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            foregroundColor: AppColors.grey700,
            side: const BorderSide(color: AppColors.grey300),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    // Pending → Terima + Tolak + Lihat Profil
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton(
          onPressed:
              _canRespond ? () => _showAcceptDialog(context, offer) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryTeal, // ← dari green
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.grey200,
            disabledForegroundColor: AppColors.grey400,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Terima',
              style:
                  TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
        ),
        OutlinedButton(
          onPressed: _canRespond ? () => onReject(offer) : null,
          style: OutlinedButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            foregroundColor: const Color(0xFFDC2626),
            disabledForegroundColor: AppColors.grey400,
            side: BorderSide(
              color: _canRespond
                  ? const Color(0xFFDC2626)
                  : AppColors.grey200,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Tolak',
              style:
                  TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
        ),
        TextButton.icon(
          onPressed: () => onOpenProfile(offer),
          icon: const Icon(Icons.person_outline, size: 15),
          label: const Text('Lihat Profil',
              style: TextStyle(fontSize: 12.5)),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryTeal, // ← dari ungu
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DIALOG KONFIRMASI TERIMA
  // ============================================================

  void _showAcceptDialog(BuildContext context, OfferModel offer) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: const Text(
          "Konfirmasi",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.grey900,
          ),
        ),
        content: Text(
          "Apakah Anda yakin ingin memilih ${offer.name} sebagai mitra?",
          style: const TextStyle(
            color: AppColors.grey700,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Batal",
              style: TextStyle(color: AppColors.grey600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal, // ← dari green
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _handleAccept(context, offer);
            },
            child: const Text("Ya, Pilih"),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BANNER STATUS JOB
  // ============================================================

  Widget _buildStatusBanner() {
    final status = job.status;
    final s = status.toLowerCase();

    Color bg;
    Color fg;
    IconData icon;
    String message;

    if (s.contains('selesai')) {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF16A34A);
      icon = Icons.check_circle_outline;
      message =
          'Pekerjaan ini sudah selesai. Tidak ada tindakan yang diperlukan.';
    } else if (s.contains('konfirmasi')) {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
      icon = Icons.hourglass_top_outlined;
      message =
          'Mitra sudah upload bukti pekerjaan. Cek di halaman utama untuk konfirmasi.';
    } else if (s.contains('dikerjakan') || s.contains('proses')) {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
      icon = Icons.construction_outlined;
      message =
          'Mitra sudah dipilih dan sedang mengerjakan. Penawaran lain tidak bisa diproses lagi.';
    } else if (s.contains('batal') || s.contains('cancel')) {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
      icon = Icons.cancel_outlined;
      message = 'Pekerjaan ini sudah dibatalkan.';
    } else {
      // default → mint/teal (dari ungu)
      bg = AppColors.mint.withOpacity(0.20);
      fg = AppColors.primaryTeal;
      icon = Icons.info_outline;
      message = 'Status pekerjaan: $status';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: $status',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: fg,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}