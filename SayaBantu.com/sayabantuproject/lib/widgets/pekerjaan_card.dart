import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/job_model.dart';
import '../services/api_service.dart';

class JobCard extends StatefulWidget {
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

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  bool _isVerifying = false;

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
  // PREVIEW GAMBAR DIALOG
  // ============================================================
  void _showImageDialog(BuildContext context, ImageProvider imageProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Image(
                  image: imageProvider,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _verifyProof(String status) async {
    if (_isVerifying) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(status == 'approved' ? 'Setujui Pekerjaan' : 'Tolak Pekerjaan'),
        content: Text(
          status == 'approved'
              ? 'Yakin pekerjaan ini sudah selesai dengan benar?'
              : 'Yakin ingin menolak bukti ini? Mitra harus memperbaiki.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'approved' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(status == 'approved' ? 'Setujui' : 'Tolak'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isVerifying = true);

    try {
      final response = await ApiService.post(
        '/jobs/${widget.job.id}/verify-proof',
        {'status': status},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ??
                (status == 'approved' ? 'Pekerjaan disetujui!' : 'Pekerjaan ditolak.')),
            backgroundColor: status == 'approved' ? Colors.green : Colors.orange,
          ),
        );
        widget.onRefresh?.call();
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Gagal verifikasi.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final isWaitingConfirmation = widget.job.status == 'Menunggu Konfirmasi Selesai';
        final isCompleted = widget.job.status == 'Selesai';
        final isInProgress = widget.job.status == 'Sedang Dikerjakan';
        final isSearching = widget.job.status == 'Mencari Mitra';
        final hasProof = widget.job.completionPhotoUrl != null;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isWaitingConfirmation
                  ? Colors.orange.shade300
                  : Theme.of(context).dividerColor,
              width: isWaitingConfirmation ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Gambar + Judul + Deskripsi =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (widget.job.imageUrl != null && widget.job.imageUrl!.isNotEmpty) {
                        _showImageDialog(context, NetworkImage(widget.job.imageUrl!));
                      } else if (widget.job.imageBytes != null) {
                        _showImageDialog(context, MemoryImage(widget.job.imageBytes!));
                      }
                    },
                    child: Container(
                      width: isMobile ? 80 : 100,
                      height: isMobile ? 80 : 100,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildJobImage(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.job.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.job.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ===== Informasi Mitra =====
              if (widget.job.partnerName != null) ...[
                Row(
                  children: [
                    const Icon(Icons.person, size: 18, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(
                      "Mitra: ${widget.job.partnerName}",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // ===== Info Harga & Waktu =====
              Wrap(
                spacing: 20,
                runSpacing: 8,
                children: [
                  _info(Icons.attach_money, "Harga Awal: ${widget.job.price}"),

                  if (widget.job.acceptedPrice != null && widget.job.acceptedPrice!.isNotEmpty)
                    _info(Icons.payments, "Harga Deal: ${widget.job.acceptedPrice}"),

                  if (isSearching)
                    _info(Icons.people_alt_outlined, "${widget.job.offerCount} Penawar"),

                  _info(Icons.access_time, "Dibuat: ${_formatLocalTime(widget.job.time)}"),

                  if (widget.job.startedAt != null)
                    _info(Icons.play_circle_outline, "Mulai: ${_formatLocalTime(widget.job.startedAt!)}"),

                  if (widget.job.completedAt != null)
                    _info(Icons.check_circle_outline, "Selesai: ${_formatLocalTime(widget.job.completedAt!)}"),
                ],
              ),
              const SizedBox(height: 18),

              // ===== Status =====
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.shade100
                      : isInProgress
                          ? Colors.blue.shade100
                          : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  widget.job.status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? Colors.green
                        : isInProgress
                            ? Colors.blue
                            : isWaitingConfirmation
                                ? Colors.orange.shade800
                                : Colors.orange,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ===== Bukti Pekerjaan =====
              // Tampil di semua status (termasuk Selesai)
              if (hasProof) ...[
                const Divider(),
                const Text(
                  '📸 Bukti Pekerjaan:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    if (widget.job.completionPhotoUrl != null) {
                      _showImageDialog(context, NetworkImage(widget.job.completionPhotoUrl!));
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.job.completionPhotoUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) =>
                          const Icon(Icons.broken_image, size: 50),
                      loadingBuilder: (context, child, progress) =>
                          progress == null ? child : const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
                if (widget.job.completionAdminNote != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '📝 Catatan Mitra: ${widget.job.completionAdminNote}',
                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                  ),
                ],

                // Tombol Setujui/Tolak hanya saat masih menunggu konfirmasi
                if (isWaitingConfirmation) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isVerifying ? null : () => _verifyProof('approved'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          icon: _isVerifying
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check, size: 18),
                          label: const Text('Setujui'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isVerifying ? null : () => _verifyProof('rejected'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          icon: _isVerifying
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.close, size: 18),
                          label: const Text('Tolak'),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
              ],

              // ===== Tombol Utama =====
              SizedBox(
                width: double.infinity,
                child: isSearching
                    ? ElevatedButton(
                        onPressed: () => widget.onOpenOffer(widget.job),
                        child: const Text("Lihat Penawaran"),
                      )
                    : isInProgress
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text("Konfirmasi"),
                                  content: const Text(
                                    "Apakah pekerjaan ini benar-benar telah selesai?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext),
                                      child: const Text("Batal"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(dialogContext);
                                        widget.onComplete(widget.job);
                                      },
                                      child: const Text("Ya"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text("Selesaikan"),
                          )
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJobImage(BuildContext context) {
    if (widget.job.imageUrl != null && widget.job.imageUrl!.isNotEmpty) {
      return Image.network(
        widget.job.imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, error, stack) => _defaultImage(context),
      );
    }
    if (widget.job.imageBytes != null) {
      return Image.memory(
        widget.job.imageBytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _defaultImage(context),
      );
    }
    return _defaultImage(context);
  }

  Widget _defaultImage(BuildContext context) {
    return Center(
      child: Icon(
        Icons.handyman,
        size: 38,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}