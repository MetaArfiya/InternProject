import 'package:flutter/material.dart';
import '../models/partner_job_model.dart';
import '../theme/app_colors.dart';
import '../utils/indonesia_time.dart';

class PartnerJobCard extends StatelessWidget {
  final PartnerJobModel job;
  final VoidCallback onTakeOffer;

  const PartnerJobCard({
    super.key,
    required this.job,
    required this.onTakeOffer,
  });

  // ============================================================
  // FORMAT TANGGAL DAN WAKTU (TANPA KONVERSI)
  // ============================================================
  String _formatLocalTime(String timeString) {
    try {
      final parsedDate = IndonesiaTime.toWall(
        IndonesiaTime.parseApiTimestamp(timeString),
      );
      return '${parsedDate.day.toString().padLeft(2, '0')}-'
          '${parsedDate.month.toString().padLeft(2, '0')}-'
          '${parsedDate.year} '
          '${parsedDate.hour.toString().padLeft(2, '0')}:'
          '${parsedDate.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timeString;
    }
  }

  String _formatPreferredStart(DateTime dateTime) {
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

    final wibDate = IndonesiaTime.toWall(dateTime);
    final day = wibDate.day.toString().padLeft(2, '0');
    final month = months[wibDate.month - 1];
    final year = wibDate.year;
    final hour = wibDate.hour.toString().padLeft(2, '0');
    final minute = wibDate.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkTeal.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================================
            // GAMBAR + INFORMASI JOB
            // ============================================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildJobImage(context),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey900,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        job.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        job.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.grey600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ============================================================
            // LOKASI
            // ============================================================
            if (job.location.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: AppColors.grey500,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      job.location,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.grey600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // ============================================================
            // WAKTU PEMBUATAN PEKERJAAN
            // ============================================================
            if (job.time.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 18,
                    color: AppColors.grey500,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Diposting: ${_formatLocalTime(job.time)}',
                      style: const TextStyle(
                        color: AppColors.grey500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // ============================================================
            // WAKTU MULAI YANG DIINGINKAN PELANGGAN
            // ============================================================
            if (job.preferredStartAt != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primaryTeal.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 17,
                          color: AppColors.primaryTeal,
                        ),
                        SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Waktu Mulai yang Diinginkan Pelanggan',
                            style: TextStyle(
                              color: AppColors.primaryTeal,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.event_outlined,
                          size: 17,
                          color: AppColors.grey700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatPreferredStart(job.preferredStartAt!),
                            style: const TextStyle(
                              color: AppColors.grey900,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Jadwal ini merupakan permintaan Pelanggan. '
                      'Mitra dapat mengajukan waktu alternatif.',
                      style: TextStyle(
                        color: AppColors.grey600,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 17,
                      color: AppColors.grey500,
                    ),
                    SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Informasi waktu mulai belum tersedia.',
                        style: TextStyle(
                          color: AppColors.grey600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 14),

            // ============================================================
            // HARGA + TOMBOL
            // ============================================================
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.price,
                    style: const TextStyle(
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: onTakeOffer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Ambil & Nego',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD GAMBAR JOB
  // ============================================================
  Widget _buildJobImage(BuildContext context) {
    if (job.imageUrl != null && job.imageUrl!.isNotEmpty) {
      return Image.network(
        job.imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder:
            (
              BuildContext context,
              Widget child,
              ImageChunkEvent? loadingProgress,
            ) {
              if (loadingProgress == null) return child;

              return const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryTeal,
                  ),
                ),
              );
            },
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
              debugPrint('❌ PARTNER JOB ${job.id} - GAMBAR GAGAL DIMUAT');
              debugPrint('❌ URL: ${job.imageUrl}');
              debugPrint('❌ ERROR: $error');
              return _defaultImage(context);
            },
      );
    }

    return _defaultImage(context);
  }

  // ============================================================
  // GAMBAR DEFAULT
  // ============================================================
  Widget _defaultImage(BuildContext context) {
    return const Center(
      child: Icon(Icons.handyman, size: 38, color: AppColors.primaryTeal),
    );
  }
}
