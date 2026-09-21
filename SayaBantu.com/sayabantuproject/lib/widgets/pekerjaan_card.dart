import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/job_model.dart';
import '../services/api_service.dart';
import 'rating_dialog.dart';

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

  // ============================================================
  // STANDARD UI
  // Mengikuti PaymentScreen + CustomerComplaintScreen
  // ============================================================

  static const double _bodyFontSize = 13;
  static const double _buttonFontSize = 13;
  static const double _cardRadius = 16;
  static const double _smallRadius = 12;

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

  // ============================================================
  // PREVIEW GAMBAR
  // ============================================================

  void _showImageDialog(
    BuildContext context,
    ImageProvider imageProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) {
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
                      size: 22,
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

  // ============================================================
  // VERIFY PROOF
  // ============================================================

  Future<void> _verifyProof(String status) async {
    if (_isVerifying) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            status == 'approved'
                ? 'Setujui Pekerjaan'
                : 'Tolak Pekerjaan',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            status == 'approved'
                ? 'Yakin pekerjaan ini sudah selesai dengan benar?'
                : 'Yakin ingin menolak bukti ini? Mitra harus memperbaiki.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontSize: _buttonFontSize,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    status == 'approved'
                        ? Colors.green
                        : Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(
                status == 'approved'
                    ? 'Setujui'
                    : 'Tolak',
                style: const TextStyle(
                  fontSize: _buttonFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      final response = await ApiService.post(
        '/jobs/${widget.job.id}/verify-proof',
        {'status': status},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ??
                  (status == 'approved'
                      ? 'Pekerjaan disetujui!'
                      : 'Pekerjaan ditolak.'),
              style: const TextStyle(
                fontSize: _bodyFontSize,
              ),
            ),
            backgroundColor:
                status == 'approved'
                    ? Colors.green
                    : Colors.orange,
          ),
        );

        widget.onRefresh?.call();
      } else {
        final decoded = jsonDecode(response.body);
        final error =
            decoded['message'] ?? 'Gagal verifikasi.';

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error,
              style: const TextStyle(
                fontSize: _bodyFontSize,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
            style: const TextStyle(
              fontSize: _bodyFontSize,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
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
        final isMobile = constraints.maxWidth < 700;

        final isWaitingConfirmation =
            widget.job.status ==
                'Menunggu Konfirmasi Selesai';

        final isCompleted =
            widget.job.status == 'Selesai';

        final isInProgress =
            widget.job.status ==
                'Sedang Dikerjakan';

        final isSearching =
            widget.job.status == 'Mencari Mitra';

        final hasProof =
            widget.job.completionPhotoUrl != null;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(
              _cardRadius,
            ),
            border: Border.all(
              color: isWaitingConfirmation
                  ? Colors.orange.shade300
                  : Theme.of(context).dividerColor,
              width: isWaitingConfirmation ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // GAMBAR + JUDUL + DESKRIPSI
              // ==================================================

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (widget.job.imageUrl != null &&
                          widget.job.imageUrl!.isNotEmpty) {
                        _showImageDialog(
                          context,
                          NetworkImage(
                            widget.job.imageUrl!,
                          ),
                        );
                      } else if (
                          widget.job.imageBytes != null) {
                        _showImageDialog(
                          context,
                          MemoryImage(
                            widget.job.imageBytes!,
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: isMobile ? 72 : 84,
                      height: isMobile ? 72 : 84,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      clipBehavior:
                          Clip.antiAlias,
                      child: _buildJobImage(context),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.job.title,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          widget.job.description,
                          maxLines: 3,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: _bodyFontSize,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ==================================================
              // INFORMASI MITRA
              // ==================================================

              if (widget.job.partnerName != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 18,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Mitra: ${widget.job.partnerName}',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize:
                              _bodyFontSize,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              // ==================================================
              // INFORMASI HARGA & WAKTU
              // ==================================================

              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _info(
                    Icons.attach_money,
                    'Harga Awal: ${widget.job.price}',
                  ),

                  if (widget.job.acceptedPrice !=
                          null &&
                      widget.job.acceptedPrice!
                          .isNotEmpty)
                    _info(
                      Icons.payments,
                      'Harga Deal: ${widget.job.acceptedPrice}',
                    ),

                  if (isSearching)
                    _info(
                      Icons.people_alt_outlined,
                      '${widget.job.offerCount} Penawar',
                    ),

                  _info(
                    Icons.access_time,
                    'Dibuat: ${_formatLocalTime(widget.job.time)}',
                  ),

                  if (widget.job.startedAt != null)
                    _info(
                      Icons.play_circle_outline,
                      'Mulai: ${_formatLocalTime(widget.job.startedAt!)}',
                    ),

                  if (widget.job.completedAt != null)
                    _info(
                      Icons.check_circle_outline,
                      'Selesai: ${_formatLocalTime(widget.job.completedAt!)}',
                    ),
                ],
              ),

              const SizedBox(height: 14),

              // ==================================================
              // STATUS
              // ==================================================

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.shade100
                      : isInProgress
                          ? Colors.blue.shade100
                          : Colors.orange.shade100,
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(
                  widget.job.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

              // ==================================================
              // BUKTI PEKERJAAN
              // ==================================================

              if (hasProof) ...[
                const Divider(height: 28),

                const Text(
                  '📸 Bukti Pekerjaan',
                  style: TextStyle(
                    fontSize: _bodyFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                GestureDetector(
                  onTap: () {
                    if (widget.job
                            .completionPhotoUrl !=
                        null) {
                      _showImageDialog(
                        context,
                        NetworkImage(
                          widget.job
                              .completionPhotoUrl!,
                        ),
                      );
                    }
                  },
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(10),
                    child: Image.network(
                      widget.job
                          .completionPhotoUrl!,
                      height:
                          isMobile ? 160 : 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stack) {
                        return SizedBox(
                          height:
                              isMobile ? 160 : 200,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 42,
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (
                        context,
                        child,
                        progress,
                      ) {
                        if (progress == null) {
                          return child;
                        }

                        return SizedBox(
                          height:
                              isMobile ? 160 : 200,
                          child: const Center(
                            child:
                                CircularProgressIndicator(
                              color: Colors.orange,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                if (widget.job
                        .completionAdminNote !=
                    null) ...[
                  const SizedBox(height: 8),

                  Text(
                    '📝 Catatan Mitra: '
                    '${widget.job.completionAdminNote}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle:
                          FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ],

                // ==============================================
                // SETUJUI / TOLAK
                // ==============================================

                if (isWaitingConfirmation) ...[
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child:
                            ElevatedButton.icon(
                          onPressed:
                              _isVerifying
                                  ? null
                                  : () =>
                                      _verifyProof(
                                        'approved',
                                      ),
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.green,
                            foregroundColor:
                                Colors.white,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 14,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(12),
                            ),
                          ),
                          icon: _isVerifying
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.check,
                                  size: 18,
                                ),
                          label: const Text(
                            'Setujui',
                            style: TextStyle(
                              fontSize:
                                  _buttonFontSize,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child:
                            ElevatedButton.icon(
                          onPressed:
                              _isVerifying
                                  ? null
                                  : () =>
                                      _verifyProof(
                                        'rejected',
                                      ),
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.red,
                            foregroundColor:
                                Colors.white,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 14,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(12),
                            ),
                          ),
                          icon: _isVerifying
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.close,
                                  size: 18,
                                ),
                          label: const Text(
                            'Tolak',
                            style: TextStyle(
                              fontSize:
                                  _buttonFontSize,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],

              const SizedBox(height: 14),

              // ==================================================
              // TOMBOL UTAMA
              // ==================================================

              SizedBox(
                width: double.infinity,
                child: _buildMainButton(
                  isSearching: isSearching,
                  isInProgress: isInProgress,
                  isCompleted: isCompleted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // MAIN BUTTON
  // ============================================================

  Widget _buildMainButton({
    required bool isSearching,
    required bool isInProgress,
    required bool isCompleted,
  }) {
    // ==========================================================
    // MENCARI MITRA
    // ==========================================================

    if (isSearching) {
      return ElevatedButton(
        onPressed: () {
          widget.onOpenOffer(widget.job);
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Lihat Penawaran',
          style: TextStyle(
            fontSize: _buttonFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // ==========================================================
    // SEDANG DIKERJAKAN
    // ==========================================================

    if (isInProgress) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text(
                  'Konfirmasi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                content: const Text(
                  'Apakah pekerjaan ini benar-benar telah selesai?',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(
                        dialogContext,
                      );
                    },
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontSize:
                            _buttonFontSize,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        dialogContext,
                      );
                      widget.onComplete(
                        widget.job,
                      );
                    },
                    style:
                        ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(12),
                      ),
                    ),
                    child: const Text(
                      'Ya',
                      style: TextStyle(
                        fontSize:
                            _buttonFontSize,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
        child: const Text(
          'Selesaikan',
          style: TextStyle(
            fontSize: _buttonFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // ==========================================================
    // SELESAI
    // ==========================================================

    if (isCompleted) {
      // ========================================================
      // SUDAH MEMBERI RATING
      // ========================================================

      if (widget.job.hasRated) {
        return Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius:
                BorderRadius.circular(
              _smallRadius,
            ),
            border: Border.all(
              color: Colors.amber.shade200,
            ),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star_rounded,
                color: Colors.amber,
                size: 19,
              ),
              const SizedBox(width: 7),
              Text(
                'Rating Anda: '
                '${widget.job.myRating ?? 0}/5',
                style: const TextStyle(
                  fontSize: _bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        );
      }

      // ========================================================
      // BELUM UPLOAD BUKTI PEMBAYARAN
      // ========================================================

      if (!widget.job.customerProofUploaded &&
          !widget.job.canRate) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius:
                BorderRadius.circular(
              _smallRadius,
            ),
            border: Border.all(
              color: Colors.orange.shade200,
            ),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.orange,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Upload bukti pembayaran di menu '
                  'Pembayaran untuk memberi rating.',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Colors.orange.shade800,
                    fontWeight:
                        FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      // ========================================================
      // BISA MEMBERI RATING
      // ========================================================

      if (widget.job.canRate) {
        return ElevatedButton.icon(
          onPressed: () async {
            final result =
                await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (_) => RatingDialog(
                jobId: widget.job.id,
                jobTitle: widget.job.title,
                mitraName:
                    widget.job.partnerName ??
                        'Mitra',
              ),
            );

            if (result == true) {
              widget.onRefresh?.call();
            }
          },
          icon: const Icon(
            Icons.star_rate_rounded,
            size: 18,
          ),
          label: const Text(
            'Beri Rating',
            style: TextStyle(
              fontSize: _buttonFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(
              vertical: 14,
            ),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(12),
            ),
          ),
        );
      }

      return const SizedBox.shrink();
    }

    return const SizedBox.shrink();
  }

  // ============================================================
  // BUILD JOB IMAGE
  // ============================================================

  Widget _buildJobImage(
    BuildContext context,
  ) {
    if (widget.job.imageUrl != null &&
        widget.job.imageUrl!.isNotEmpty) {
      return Image.network(
        widget.job.imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (
          context,
          child,
          progress,
        ) {
          if (progress == null) {
            return child;
          }

          return const Center(
            child: CircularProgressIndicator(
              color: Colors.orange,
            ),
          );
        },
        errorBuilder: (
          context,
          error,
          stack,
        ) {
          return _defaultImage(context);
        },
      );
    }

    if (widget.job.imageBytes != null) {
      return Image.memory(
        widget.job.imageBytes!,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stack,
        ) {
          return _defaultImage(context);
        },
      );
    }

    return _defaultImage(context);
  }

  // ============================================================
  // DEFAULT IMAGE
  // ============================================================

  Widget _defaultImage(
    BuildContext context,
  ) {
    return Center(
      child: Icon(
        Icons.handyman,
        size: 32,
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
        const SizedBox(width: 0),
        Icon(
          icon,
          size: 16,
          color: Colors.grey,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: _bodyFontSize,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}