import 'package:flutter/material.dart';
import '../models/job_model.dart';

class JobCard extends StatelessWidget {
  final JobModel job;
  final Function(JobModel) onOpenOffer;
  final Function(JobModel) onComplete;
  final VoidCallback? onRefresh;

  const JobCard({
    super.key,
    required this.job,
    required this.onOpenOffer,
    required this.onComplete,
    this.onRefresh,
  });

  // ============================================================
  // FORMAT WAKTU LOKAL
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return Container(
          padding: const EdgeInsets.all(20),
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
              // ==================================================
              // GAMBAR + JUDUL + DESKRIPSI
              // ==================================================

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =================================================
                  // IMAGE
                  // =================================================

                  Container(
                    width: isMobile ? 80 : 100,
                    height: isMobile ? 80 : 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,

                    child: _buildJobImage(context),
                  ),

                  const SizedBox(width: 16),

                  // =================================================
                  // JUDUL + DESKRIPSI
                  // =================================================

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          job.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==================================================
              // INFORMASI MITRA
              // ==================================================

              if (job.partnerName != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 18,
                      color: Colors.green,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      "Mitra: ${job.partnerName}",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(
                      Icons.payments,
                      size: 18,
                      color: Colors.orange,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      "Harga Deal: ${job.acceptedPrice}",
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
              ],

              // ==================================================
              // INFORMASI PEKERJAAN
              // ==================================================

              Wrap(
                spacing: 20,
                runSpacing: 8,
                children: [
                  if (job.status == "Mencari Mitra") ...[
                    Text(job.price),

                    _info(
                      Icons.people_alt_outlined,
                      "${job.offerCount} Penawar",
                    ),
                  ],

                  _info(
                    Icons.access_time,
                    _formatLocalTime(job.time),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ==================================================
              // STATUS
              // ==================================================

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: job.status == "Selesai"
                      ? Colors.green.shade100
                      : job.status == "Sedang Dikerjakan"
                          ? Colors.blue.shade100
                          : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  job.status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: job.status == "Selesai"
                        ? Colors.green
                        : job.status == "Sedang Dikerjakan"
                            ? Colors.blue
                            : Colors.orange,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // BUTTON
              // ==================================================

              SizedBox(
                width: double.infinity,

                child: job.status == "Mencari Mitra"
                    ? ElevatedButton(
                        onPressed: () => onOpenOffer(job),
                        child: const Text(
                          "Lihat Penawaran",
                        ),
                      )

                    : job.status == "Sedang Dikerjakan"
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),

                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text(
                                    "Konfirmasi",
                                  ),

                                  content: const Text(
                                    "Apakah pekerjaan ini benar-benar telah selesai?",
                                  ),

                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text(
                                        "Batal",
                                      ),
                                    ),

                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        onComplete(job);
                                      },
                                      child: const Text(
                                        "Ya",
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },

                            child: const Text(
                              "Selesaikan",
                            ),
                          )

                        : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD IMAGE
  // ============================================================

  Widget _buildJobImage(BuildContext context) {
    // ------------------------------------------------------------
    // 1. Jika ada URL dari Laravel
    // ------------------------------------------------------------

    if (job.imageUrl != null &&
        job.imageUrl!.isNotEmpty) {
      debugPrint(
        '🖼️ JOB ${job.id} - MENAMPILKAN IMAGE NETWORK',
      );

      debugPrint(
        '🌐 URL: ${job.imageUrl}',
      );

      return Image.network(
        job.imageUrl!,
        fit: BoxFit.cover,

        // --------------------------------------------------------
        // Loading
        // --------------------------------------------------------

        loadingBuilder: (
          BuildContext context,
          Widget child,
          ImageChunkEvent? loadingProgress,
        ) {
          if (loadingProgress == null) {
            debugPrint(
              '✅ JOB ${job.id} - GAMBAR BERHASIL DIMUAT',
            );

            debugPrint(
              '✅ URL: ${job.imageUrl}',
            );

            return child;
          }

          debugPrint(
            '⏳ JOB ${job.id} - GAMBAR SEDANG LOADING',
          );

          return const Center(
            child: CircularProgressIndicator(),
          );
        },

        // --------------------------------------------------------
        // Error
        // --------------------------------------------------------

        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          debugPrint(
            '❌ JOB ${job.id} - GAMBAR GAGAL DIMUAT',
          );

          debugPrint(
            '❌ URL: ${job.imageUrl}',
          );

          debugPrint(
            '❌ ERROR: $error',
          );

          debugPrint(
            '❌ STACK: $stackTrace',
          );

          return Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 38,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
          );
        },
      );
    }

    // ------------------------------------------------------------
    // 2. Jika tidak ada URL tetapi ada imageBytes
    // ------------------------------------------------------------

    if (job.imageBytes != null) {
      debugPrint(
        '🖼️ JOB ${job.id} - MENAMPILKAN IMAGE MEMORY',
      );

      return Image.memory(
        job.imageBytes!,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          debugPrint(
            '❌ JOB ${job.id} - IMAGE MEMORY GAGAL',
          );

          debugPrint(
            '❌ ERROR: $error',
          );

          return _defaultImage(context);
        },
      );
    }

    // ------------------------------------------------------------
    // 3. Tidak ada gambar
    // ------------------------------------------------------------

    debugPrint(
      'ℹ️ JOB ${job.id} - TIDAK ADA GAMBAR',
    );

    return _defaultImage(context);
  }

  // ============================================================
  // DEFAULT IMAGE
  // ============================================================

  Widget _defaultImage(BuildContext context) {
    return Center(
      child: Icon(
        Icons.handyman,
        size: 38,
        color: Theme.of(context)
            .colorScheme
            .primary,
      ),
    );
  }

  // ============================================================
  // INFO ITEM
  // ============================================================

  Widget _info(
    IconData icon,
    String text,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey,
        ),

        const SizedBox(width: 6),

        Text(
          text,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}