import 'package:flutter/material.dart';
import '../models/partner_job_model.dart';
import '../theme/app_colors.dart';

class PartnerJobCard extends StatelessWidget {
  final PartnerJobModel job;
  final VoidCallback onTakeOffer;

  const PartnerJobCard({
    super.key,
    required this.job,
    required this.onTakeOffer,
  });

  // ============================================================
  // FORMAT WAKTU
  // ============================================================
  String _formatLocalTime(String timeString) {
    try {
      final parsedDate = DateTime.parse(timeString);
      final localDate = parsedDate.toLocal();

      return "${localDate.day.toString().padLeft(2, '0')}-"
          "${localDate.month.toString().padLeft(2, '0')}-"
          "${localDate.year} "
          "${localDate.hour.toString().padLeft(2, '0')}:"
          "${localDate.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return timeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha:0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkTeal.withValues(alpha:0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================================
            // GAMBAR + INFORMASI JOB
            // ============================================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // GAMBAR
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

                // INFORMASI JOB
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // JUDUL
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

                      // KATEGORI — dari orange → teal
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

                      // DESKRIPSI
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
            if (job.location.isNotEmpty)
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

            if (job.location.isNotEmpty) const SizedBox(height: 8),

            // ============================================================
            // WAKTU
            // ============================================================
            if (job.time.isNotEmpty)
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 18,
                    color: AppColors.grey500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatLocalTime(job.time),
                    style: const TextStyle(
                      color: AppColors.grey600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 14),

            // ============================================================
            // HARGA + TOMBOL
            // ============================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // HARGA — tetap hijau? Atau teal?
                // ✅ Pakai teal biar konsisten
                Expanded(
                  child: Text(
                    job.price,
                    style: const TextStyle(
                      color: AppColors.primaryTeal, // ← dari hijau
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // TOMBOL AMBIL & NEGO
                ElevatedButton(
                  onPressed: onTakeOffer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal, // ← dari orange
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
                    "Ambil & Nego",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
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
        loadingBuilder: (
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
                color: AppColors.primaryTeal, // ← teal
              ),
            ),
          );
        },
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
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
      child: Icon(
        Icons.handyman,
        size: 38,
        color: AppColors.primaryTeal, // ← teal
      ),
    );
  }
}