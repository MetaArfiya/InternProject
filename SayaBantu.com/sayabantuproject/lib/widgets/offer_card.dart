import 'package:flutter/material.dart';

import '../models/job_model.dart';
import '../models/offer_model.dart';
import '../theme/app_colors.dart';

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
          // pending → border teal soft (dari gray)
          borderColor = AppColors.primaryTeal.withValues(alpha:0.15);
          bgColor = AppColors.white;
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
                if (!offer.isPending) ...[
                  _buildStateBanner(isAccepted: isAccepted),
                  SizedBox(height: isCompact ? 12 : 16),
                ],
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
  // ============================================================

  Widget _buildCompactContent(BuildContext context) {
    final isAccepted = offer.isAccepted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar + Nama + Verified
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: isAccepted
                  ? const Color(0xFFDCFCE7)
                  : AppColors.mint.withValues(alpha:0.20), // ← dari orange soft
              child: Icon(
                Icons.person,
                color: isAccepted
                    ? const Color(0xFF16A34A)
                    : AppColors.primaryTeal, // ← dari orange
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
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Verified badge — tetap hijau (konotasi)
                      if (offer.verified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified,
                                  color: Color(0xFF16A34A), size: 13),
                              SizedBox(width: 4),
                              Text(
                                "Terverifikasi",
                                style: TextStyle(
                                  color: Color(0xFF16A34A),
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
                              color: AppColors.grey500, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            "${offer.jobsCompleted} Job",
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.grey600,
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

        // Harga
        Text(
          offer.price,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isAccepted
                ? const Color(0xFF16A34A)
                : AppColors.primaryTeal, // ← dari orange
          ),
        ),

        const SizedBox(height: 14),

        _buildCompactActions(context),
      ],
    );
  }

  // ============================================================
  // LAYOUT WIDE (WEB)
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
              : AppColors.mint.withValues(alpha:0.20), // ← dari orange soft
          child: Icon(
            Icons.person,
            color: isAccepted
                ? const Color(0xFF16A34A)
                : AppColors.primaryTeal, // ← dari orange
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
                        color: AppColors.grey900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (offer.verified)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified,
                              color: Color(0xFF16A34A), size: 16),
                          SizedBox(width: 4),
                          Text(
                            "Terverifikasi",
                            style: TextStyle(
                              color: Color(0xFF16A34A),
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
              const Row(
                children: [
                  Icon(Icons.star, color: Color(0xFFF59E0B), size: 18),
                  SizedBox(width: 20),
                  Icon(Icons.work_outline,
                      color: AppColors.grey500, size: 18),
                  SizedBox(width: 5),
                  Text(
                    "Job",
                    style: TextStyle(color: AppColors.grey700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "${offer.jobsCompleted} Job",
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.grey600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                offer.price,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isAccepted
                      ? const Color(0xFF16A34A)
                      : AppColors.primaryTeal, // ← dari orange
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
    // Diterima
    if (offer.isAccepted) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A), // tetap hijau (success)
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
                foregroundColor: AppColors.primaryTeal, // ← dari ungu
                minimumSize: const Size(0, 42),
              ),
            ),
          ),
        ],
      );
    }

    // Ditolak
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
                foregroundColor: AppColors.primaryTeal, // ← dari ungu
                minimumSize: const Size(0, 42),
              ),
            ),
          ),
        ],
      );
    }

    // Pending
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canRespond
                ? () {
                    showDialog(
                      context: context,
                      builder: (_) => _confirmDialog(
                        context: context,
                        title: "Konfirmasi",
                        message:
                            "Apakah Anda yakin ingin memilih ${offer.name} sebagai mitra?",
                        confirmLabel: "Ya",
                        onConfirm: () => onAccept(offer),
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal, // ← dari green
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.grey200,
              disabledForegroundColor: AppColors.grey400,
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
                      builder: (_) => _confirmDialog(
                        context: context,
                        title: "Tolak Penawaran",
                        message:
                            "Yakin ingin menolak penawaran dari ${offer.name}?",
                        confirmLabel: "Tolak",
                        isDanger: true,
                        onConfirm: () => onReject(offer),
                      ),
                    );
                  }
                : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 42),
              foregroundColor: canRespond
                  ? const Color(0xFFDC2626)
                  : AppColors.grey400,
              disabledForegroundColor: AppColors.grey400,
              side: BorderSide(
                color: canRespond
                    ? const Color(0xFFDC2626)
                    : AppColors.grey200,
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
              foregroundColor: AppColors.primaryTeal, // ← dari ungu
              minimumSize: const Size(0, 42),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // AKSI WIDE — Row tombol di kanan
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
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryTeal,
            ),
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
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryTeal,
            ),
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
                    builder: (_) => _confirmDialog(
                      context: context,
                      title: "Konfirmasi",
                      message:
                          "Apakah Anda yakin ingin memilih ${offer.name} sebagai mitra?",
                      confirmLabel: "Ya",
                      onConfirm: () => onAccept(offer),
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryTeal, // ← dari green
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.grey200,
            disabledForegroundColor: AppColors.grey400,
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
                    builder: (_) => _confirmDialog(
                      context: context,
                      title: "Tolak Penawaran",
                      message:
                          "Yakin ingin menolak penawaran dari ${offer.name}?",
                      confirmLabel: "Tolak",
                      isDanger: true,
                      onConfirm: () => onReject(offer),
                    ),
                  );
                }
              : null,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(120, 45),
            foregroundColor: canRespond
                ? AppColors.grey900
                : AppColors.grey400,
            disabledForegroundColor: AppColors.grey400,
            side: BorderSide(
              color: canRespond
                  ? AppColors.grey300
                  : AppColors.grey200,
            ),
          ),
          child: const Text("Tolak"),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => onOpenProfile(offer),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryTeal,
          ),
          child: const Text("Lihat Profil"),
        ),
      ],
    );
  }

  // ============================================================
  // DIALOG KONFIRMASI (shared)
  // ============================================================

  Widget _confirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    required VoidCallback onConfirm,
    bool isDanger = false,
  }) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.grey900,
        ),
      ),
      content: Text(
        message,
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
            backgroundColor: isDanger
                ? const Color(0xFFDC2626)
                : AppColors.primaryTeal, // ← teal / red
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: Text(confirmLabel),
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
            ? const Color(0xFF16A34A).withValues(alpha:0.1)
            : const Color(0xFFDC2626).withValues(alpha:0.08),
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