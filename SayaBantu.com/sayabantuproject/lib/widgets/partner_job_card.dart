import 'package:flutter/material.dart';
import '../models/partner_job_model.dart';

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
  // Contoh:
  // 2026-09-03T03:14:36.000000Z
  // menjadi:
  // 03-09-2026 10:14
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
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

                // =========================
                // GAMBAR
                // =========================
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildJobImage(context),
                ),

                const SizedBox(width: 14),

                // =========================
                // INFORMASI JOB
                // =========================
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
                        ),
                      ),

                      const SizedBox(height: 6),

                      // KATEGORI
                      Text(
                        job.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // DESKRIPSI
                      Text(
                        job.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                    color: Colors.grey,
                  ),

                  const SizedBox(width: 6),

                  Expanded(
                    child: Text(
                      job.location,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),

            if (job.location.isNotEmpty)
              const SizedBox(height: 8),

            // ============================================================
            // WAKTU
            // ============================================================
            if (job.time.isNotEmpty)
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 18,
                    color: Colors.grey,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    _formatLocalTime(job.time),
                    style: const TextStyle(
                      color: Colors.grey,
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

                // HARGA
                Expanded(
                  child: Text(
                    job.price,
                    style: const TextStyle(
                      color: Colors.green,
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
                    backgroundColor: const Color(0xffF97316),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Ambil & Nego"),
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
      debugPrint(
        '🖼️ PARTNER JOB ${job.id} - MENAMPILKAN IMAGE NETWORK',
      );

      debugPrint(
        '🌐 URL: ${job.imageUrl}',
      );

      return Image.network(
        job.imageUrl!,
        fit: BoxFit.cover,

        // =========================
        // LOADING
        // =========================
        loadingBuilder: (
          BuildContext context,
          Widget child,
          ImageChunkEvent? loadingProgress,
        ) {
          if (loadingProgress == null) {
            debugPrint(
              '✅ PARTNER JOB ${job.id} - GAMBAR BERHASIL DIMUAT',
            );

            debugPrint(
              '✅ URL: ${job.imageUrl}',
            );

            return child;
          }

          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          );
        },

        // =========================
        // ERROR
        // =========================
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          debugPrint(
            '❌ PARTNER JOB ${job.id} - GAMBAR GAGAL DIMUAT',
          );

          debugPrint(
            '❌ URL: ${job.imageUrl}',
          );

          debugPrint(
            '❌ ERROR: $error',
          );

          return _defaultImage(context);
        },
      );
    }

    debugPrint(
      'ℹ️ PARTNER JOB ${job.id} - TIDAK ADA GAMBAR',
    );

    return _defaultImage(context);
  }

  // ============================================================
  // GAMBAR DEFAULT
  // ============================================================
  Widget _defaultImage(BuildContext context) {
    return Center(
      child: Icon(
        Icons.handyman,
        size: 38,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}