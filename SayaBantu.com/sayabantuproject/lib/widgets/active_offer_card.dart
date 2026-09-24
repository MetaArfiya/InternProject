import 'package:flutter/material.dart';

import '../models/active_offer_model.dart';
import '../sections/partner/completion_proof_dialog.dart';

// ================================================================
// BASE URL API
// ================================================================
// Sesuaikan dengan platform:
//   - Web / iOS Simulator : http://localhost:8000/api
//   - Android Emulator    : http://10.0.2.2:8000/api
//   - HP fisik            : http://192.168.x.x:8000/api
const String _apiBaseUrl = 'http://localhost:8000/api';

/// Membuat satu baris tabel untuk penawaran aktif.
TableRow buildActiveOfferRow(
  BuildContext context,
  ActiveOfferModel offer,
  int number,
) {
  return TableRow(
    decoration: const BoxDecoration(
      border: Border(
        bottom: BorderSide(color: Color(0xffE5E7EB), width: 1),
      ),
    ),
    children: [
      _tableCell(
        Center(
          child: Text('$number', style: const TextStyle(fontSize: 14)),
        ),
      ),
      _tableCell(
        Text(
          offer.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      _tableCell(
        Text(
          offer.price,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      _tableCell(_buildRanking(offer)),
      _tableCell(_buildStatus(offer)),
      _tableCell(_buildProofButton(context, offer)),
      _tableCell(_buildApproval(offer)),
      _tableCell(_buildAction(context, offer)),
    ],
  );
}

// ================================================================
// CELL TABEL
// ================================================================
Widget _tableCell(Widget child) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    child: child,
  );
}

// ================================================================
// PERINGKAT
// ================================================================
Widget _buildRanking(ActiveOfferModel offer) {
  final bool isTop = offer.queuePosition == 1 || offer.isTop;

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '#${offer.queuePosition}',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      if (isTop) ...[
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xffDCFCE7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Teratas',
            style: TextStyle(
              color: Color(0xff15803D),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ],
  );
}

// ================================================================
// STATUS PEKERJAAN
// ================================================================
Widget _buildStatus(ActiveOfferModel offer) {
  final bool isWorking = offer.status == 'Sedang Dikerjakan';
  final bool waiting = offer.status == 'Menunggu Konfirmasi Selesai';
  final bool completed = offer.status == 'Selesai';

  Color backgroundColor;
  Color textColor;
  String text;

  if (completed) {
    backgroundColor = const Color(0xffDBEAFE);
    textColor = const Color(0xff2563EB);
    text = 'Selesai';
  } else if (waiting) {
    backgroundColor = const Color(0xffFEF3C7);
    textColor = const Color(0xffB45309);
    text = 'Menunggu Konfirmasi';
  } else if (isWorking) {
    backgroundColor = const Color(0xffDCFCE7);
    textColor = const Color(0xff15803D);
    text = 'Sedang Dikerjakan';
  } else {
    backgroundColor = const Color(0xffF3F4F6);
    textColor = const Color(0xff6B7280);
    text = 'Menunggu';
  }

  return Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

// ================================================================
// HELPER: KONVERSI PATH DB → URL API
// ================================================================
String? _buildProofImageUrl(String? rawPath) {
  if (rawPath == null || rawPath.isEmpty || rawPath == 'null') {
    return null;
  }
  if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
    return rawPath;
  }
  final String filename = rawPath.split('/').last;
  return '$_apiBaseUrl/images/completion_proofs/$filename';
}

// ================================================================
// BUKTI PEKERJAAN — Thumbnail Foto ATAU Tombol Upload
// ================================================================
Widget _buildProofButton(
  BuildContext context,
  ActiveOfferModel offer,
) {
  final String? rawPath = offer.completionPhotoUrl ?? offer.proofImage;
  final String? imageUrl = _buildProofImageUrl(rawPath);

  if (imageUrl != null) {
    return InkWell(
      onTap: () => _showFullProofImage(context, imageUrl, offer.title),
      borderRadius: BorderRadius.circular(8),
      child: Tooltip(
        message: 'Klik untuk lihat bukti',
        child: Container(
          width: 130,
          height: 75,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xffE5E7EB)),
            color: const Color(0xffF8FAFC),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 24,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  return InkWell(
    onTap: () => _showCompletionProofDialog(context, offer),
    borderRadius: BorderRadius.circular(8),
    child: Container(
      width: 130,
      height: 75,
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 26,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 4),
          Text(
            'Upload Bukti',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

// ================================================================
// DIALOG LIHAT FOTO BUKTI (Full screen + zoom)
// ================================================================
Future<void> _showFullProofImage(
  BuildContext context,
  String imageUrl,
  String title,
) async {
  return showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.image_outlined, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bukti: $title',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Padding(
                          padding: EdgeInsets.all(60),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Padding(
                          padding: EdgeInsets.all(60),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                size: 60,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 12),
                              Text('Gagal memuat gambar'),
                            ],
                          ),
                        );
                      },
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

// ================================================================
// ACC PELANGGAN
// ================================================================
Widget _buildApproval(ActiveOfferModel offer) {
  String text;
  Color backgroundColor;
  Color textColor;

  if (offer.status == 'Selesai') {
    text = 'Sudah ACC';
    backgroundColor = const Color(0xffDCFCE7);
    textColor = const Color(0xff15803D);
  } else if (offer.status == 'Menunggu Konfirmasi Selesai') {
    text = 'Menunggu ACC';
    backgroundColor = const Color(0xffFEF3C7);
    textColor = const Color(0xffB45309);
  } else {
    text = 'Belum ACC';
    backgroundColor = const Color(0xffF3F4F6);
    textColor = const Color(0xff6B7280);
  }

  return Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

// ================================================================
// AKSI
// ================================================================
Widget _buildAction(
  BuildContext context,
  ActiveOfferModel offer,
) {
  final bool isWorking = offer.status == 'Sedang Dikerjakan';
  final String? rawPath = offer.completionPhotoUrl ?? offer.proofImage;
  final bool hasProof = rawPath != null && rawPath.isNotEmpty;

  // Sedang dikerjakan & belum ada bukti → tombol Upload Bukti
  if (isWorking && !hasProof) {
    return SizedBox(
      height: 38,
      child: ElevatedButton.icon(
        onPressed: () => _showCompletionProofDialog(context, offer),
        icon: const Icon(Icons.camera_alt_outlined, size: 17),
        label: const Text(
          'Pekerjaan Selesai',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff16A34A),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // Selain itu → tombol Detail (buka timeline)
  return SizedBox(
    height: 38,
    child: OutlinedButton.icon(
      onPressed: () => _showDetailTimeline(context, offer),
      icon: const Icon(Icons.info_outline, size: 17),
      label: const Text('Detail', style: TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}

// ================================================================
// DIALOG DETAIL — TIMELINE PEKERJAAN
// ================================================================
Future<void> _showDetailTimeline(
  BuildContext context,
  ActiveOfferModel offer,
) async {
  showDialog(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 8, 18),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xffE5E7EB)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timeline, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detail Pekerjaan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          offer.title,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
            ),

            // BODY
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Harga Deal', offer.price),
                    _infoRow('Status', offer.status),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 20),

                    const Text(
                      'Timeline Pekerjaan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _timelineItem(
                      icon: Icons.check_circle_outline,
                      iconColor: const Color(0xff16A34A),
                      title: 'Pekerjaan Dimulai',
                      subtitle: 'Pelanggan menyetujui penawaran mitra',
                      time: _formatDateTime(offer.startedAt),
                      isActive: offer.startedAt != null,
                    ),

                    _timelineItem(
                      icon: Icons.construction_outlined,
                      iconColor: const Color(0xffF59E0B),
                      title: 'Sedang Dikerjakan',
                      subtitle: 'Mitra mengerjakan pekerjaan',
                      time: offer.startedAt != null &&
                              offer.completionSubmittedAt == null
                          ? 'Dalam proses'
                          : null,
                      isActive: offer.startedAt != null &&
                          offer.completionSubmittedAt == null,
                    ),

                    _timelineItem(
                      icon: Icons.upload_file_outlined,
                      iconColor: const Color(0xff2563EB),
                      title: 'Bukti Diupload',
                      subtitle: 'Mitra upload bukti penyelesaian',
                      time: _formatDateTime(offer.completionSubmittedAt),
                      isActive: offer.completionSubmittedAt != null,
                    ),

                    _timelineItem(
                      icon: Icons.verified_outlined,
                      iconColor: const Color(0xff9333EA),
                      title: 'Diverifikasi Pelanggan',
                      subtitle: 'Pelanggan menyetujui bukti (ACC)',
                      time: _formatDateTime(offer.completionVerifiedAt),
                      isActive: offer.completionVerifiedAt != null,
                      isLast: true,
                    ),

                    if (offer.proofDescription != null &&
                        offer.proofDescription!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      const Text(
                        'Catatan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xffF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xffE5E7EB),
                          ),
                        ),
                        child: Text(
                          offer.proofDescription!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // FOOTER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Tutup'),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ================================================================
// HELPER — Row info
// ================================================================
Widget _infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

// ================================================================
// HELPER — Item Timeline
// ================================================================
Widget _timelineItem({
  required IconData icon,
  required Color iconColor,
  required String title,
  required String subtitle,
  String? time,
  required bool isActive,
  bool isLast = false,
}) {
  final Color finalColor = isActive ? iconColor : Colors.grey.shade400;
  final Color bgColor = isActive
      ? iconColor.withOpacity(0.12)
      : const Color(0xffF3F4F6);

  return IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: finalColor),
            ),
            if (!isLast)
              Expanded(
                child: Container(
                  width: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: isActive
                      ? iconColor.withOpacity(0.4)
                      : const Color(0xffE5E7EB),
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.black87 : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (time != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: isActive ? iconColor : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isActive ? iconColor : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// ================================================================
// HELPER — Format tanggal & waktu Indonesia
// ================================================================
String _formatDateTime(DateTime? dt) {
  if (dt == null) return '-';

  const bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  final local = dt.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = bulan[local.month - 1];
  final year = local.year;
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '$day $month $year • $hour:$minute';
}

// ================================================================
// DIALOG UPLOAD BUKTI PEKERJAAN
// ================================================================
Future<void> _showCompletionProofDialog(
  BuildContext context,
  ActiveOfferModel offer,
) async {
  if (offer.jobId == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ID pekerjaan tidak ditemukan.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final result = await showDialog<CompletionProofResult>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return CompletionProofDialog(jobId: offer.jobId);
    },
  );

  if (result == null) return;
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Bukti pekerjaan berhasil dikirim.'),
      backgroundColor: Color(0xff16A34A),
      behavior: SnackBarBehavior.floating,
    ),
  );
}