import 'package:flutter/material.dart';

import '../models/job_model.dart';
import '../models/offer_model.dart';

class OfferCard extends StatelessWidget {
  final JobModel job;
  final OfferModel offer;
  final bool canRespond;
  final Function(OfferModel) onReject;
  final Function(OfferModel) onAccept;
  final Function(OfferModel) onOpenProfile;

  const OfferCard({
    super.key,
    required this.job,
    required this.offer,
    this.canRespond = true,
    required this.onReject,
    required this.onAccept,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mobile: < 500px → layout Column
        final isCompact = constraints.maxWidth < 500;

        final isAccepted = offer.isAccepted;
        final isRejected = offer.isRejected;

        Color borderColor;
        Color bgColor;
        double borderWidth;

        if (isAccepted) {
          borderColor = const Color(0xFF16A34A);
          bgColor = const Color(0xFFF0FDF4);
          borderWidth = 1.5;
        } else if (isRejected) {
          borderColor = const Color(0xFFFCA5A5);
          bgColor = const Color(0xFFFEF2F2);
          borderWidth = 1;
        } else {
          borderColor = const Color(0xFFE5E7EB);
          bgColor = Colors.white;
          borderWidth = 1;
        }

        return Opacity(
          opacity: isRejected ? 0.85 : 1,
          child: Container(
            padding: EdgeInsets.all(isCompact ? 14 : 22),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==============================================
                // BANNER STATUS (kalau bukan pending)
                // ==============================================
                if (!offer.isPending) ...[
                  _buildStateBanner(isAccepted: isAccepted),
                  SizedBox(height: isCompact ? 12 : 16),
                ],

                // ==============================================
                // KONTEN
                // ==============================================
                if (isCompact)
                  _buildCompactContent(context)
                else
                  _buildWideContent(context),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // LAYOUT COMPACT (MOBILE)
  // Avatar + info di atas, tombol di bawah
  // ============================================================

  Widget _buildCompactContent(BuildContext context) {
    final isAccepted = offer.isAccepted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---------------- Avatar + Nama + Verified ----------------
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: isAccepted
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFFF3E8),
              child: Icon(
                Icons.person,
                color: isAccepted
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFF97316),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (offer.verified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified,
                                  color: Colors.green, size: 13),
                              SizedBox(width: 4),
                              Text(
                                "Terverifikasi",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.work_outline,
                              color: Colors.grey, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            "${offer.jobsCompleted} Job",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ---------------- Harga ----------------
        Text(
          offer.price,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isAccepted
                ? const Color(0xFF16A34A)
                : const Color(0xFFF97316),
          ),
        ),

        const SizedBox(height: 14),

        // ---------------- Tombol ----------------
        _buildCompactActions(context),
      ],
    );
  }

  // ============================================================
  // LAYOUT WIDE (WEB)
  // Avatar kiri, tombol kanan — seperti semula
  // ============================================================

  Widget _buildWideContent(BuildContext context) {
    final isAccepted = offer.isAccepted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: isAccepted
              ? const Color(0xFFDCFCE7)
              : const Color(0xFFFFF3E8),
          child: Icon(
            Icons.person,
            color: isAccepted
                ? const Color(0xFF16A34A)
                : const Color(0xFFF97316),
            size: 38,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      offer.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (offer.verified)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified,
                              color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text(
                            "Terverifikasi",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 20),
                  const Icon(Icons.work_outline,
                      color: Colors.grey, size: 18),
                  const SizedBox(width: 5),
                  Text("${offer.jobsCompleted} Job"),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                offer.price,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isAccepted
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFF97316),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        _buildWideActions(context),
      ],
    );
  }

  // ============================================================
  // AKSI COMPACT — tombol full-width vertikal
  // ============================================================

  Widget _buildCompactActions(BuildContext context) {
    // Sudah diterima → label + tombol profil
    if (offer.isAccepted) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  "TERPILIH",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => onOpenProfile(offer),
              icon: const Icon(Icons.person_outline, size: 16),
              label: const Text("Lihat Profil"),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF7C3AED),
                minimumSize: const Size(0, 42),
              ),
            ),
          ),
        ],
      );
    }

    // Sudah ditolak → label + tombol profil
    if (offer.isRejected) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel, color: Color(0xFFDC2626), size: 18),
                SizedBox(width: 6),
                Text(
                  "DITOLAK",
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => onOpenProfile(offer),
              icon: const Icon(Icons.person_outline, size: 16),
              label: const Text("Lihat Profil"),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF7C3AED),
                minimumSize: const Size(0, 42),
              ),
            ),
          ),
        ],
      );
    }

    // Pending → Terima + Tolak + Lihat Profil (full-width vertikal)
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canRespond
                ? () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Konfirmasi"),
                        content: Text(
                          "Apakah Anda yakin ingin memilih ${offer.name} sebagai mitra?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Batal"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onAccept(offer);
                            },
                            child: const Text("Ya"),
                          ),
                        ],
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE5E7EB),
              disabledForegroundColor: const Color(0xFF9CA3AF),
              minimumSize: const Size(0, 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Terima",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: canRespond
                ? () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Tolak Penawaran"),
                        content: Text(
                          "Yakin ingin menolak penawaran dari ${offer.name}?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Batal"),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              onReject(offer);
                            },
                            child: const Text("Tolak"),
                          ),
                        ],
                      ),
                    );
                  }
                : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 42),
              foregroundColor: canRespond
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF9CA3AF),
              disabledForegroundColor: const Color(0xFF9CA3AF),
              side: BorderSide(
                color: canRespond
                    ? const Color(0xFFDC2626)
                    : const Color(0xFFE5E7EB),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Tolak",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => onOpenProfile(offer),
            icon: const Icon(Icons.person_outline, size: 16),
            label: const Text("Lihat Profil"),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF7C3AED),
              minimumSize: const Size(0, 42),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // AKSI WIDE — seperti semula (Row tombol di kanan)
  // ============================================================

  Widget _buildWideActions(BuildContext context) {
    if (offer.isAccepted) {
      return Column(
        children: [
          Container(
            width: 130,
            height: 45,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  "TERPILIH",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => onOpenProfile(offer),
            child: const Text("Lihat Profil"),
          ),
        ],
      );
    }

    if (offer.isRejected) {
      return Column(
        children: [
          Container(
            width: 130,
            height: 45,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel, color: Color(0xFFDC2626), size: 18),
                SizedBox(width: 6),
                Text(
                  "DITOLAK",
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => onOpenProfile(offer),
            child: const Text("Lihat Profil"),
          ),
        ],
      );
    }

    return Column(
      children: [
        ElevatedButton(
          onPressed: canRespond
              ? () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Konfirmasi"),
                      content: Text(
                        "Apakah Anda yakin ingin memilih ${offer.name} sebagai mitra?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Batal"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onAccept(offer);
                          },
                          child: const Text("Ya"),
                        ),
                      ],
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFE5E7EB),
            disabledForegroundColor: const Color(0xFF9CA3AF),
            minimumSize: const Size(120, 45),
          ),
          child: const Text("Terima"),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: canRespond
              ? () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Tolak Penawaran"),
                      content: Text(
                        "Yakin ingin menolak penawaran dari ${offer.name}?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Batal"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            onReject(offer);
                          },
                          child: const Text("Tolak"),
                        ),
                      ],
                    ),
                  );
                }
              : null,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(120, 45),
            foregroundColor: canRespond
                ? const Color(0xFF111827)
                : const Color(0xFF9CA3AF),
            disabledForegroundColor: const Color(0xFF9CA3AF),
            side: BorderSide(
              color: canRespond
                  ? const Color(0xFFD1D5DB)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: const Text("Tolak"),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => onOpenProfile(offer),
          child: const Text("Lihat Profil"),
        ),
      ],
    );
  }

  // ============================================================
  // BANNER STATUS
  // ============================================================

  Widget _buildStateBanner({required bool isAccepted}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isAccepted
            ? const Color(0xFF16A34A).withOpacity(0.1)
            : const Color(0xFFDC2626).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isAccepted ? Icons.check_circle : Icons.cancel,
            color: isAccepted
                ? const Color(0xFF16A34A)
                : const Color(0xFFDC2626),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isAccepted
                  ? 'Mitra ini sudah Anda pilih untuk mengerjakan pekerjaan.'
                  : 'Penawaran ini sudah ditolak.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isAccepted
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );
  }
}