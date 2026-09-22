import 'package:flutter/material.dart';

import '../models/active_offer_model.dart';
import '../sections/partner/completion_proof_dialog.dart';

/// Membuat satu baris tabel untuk penawaran aktif.
TableRow buildActiveOfferRow(
  BuildContext context,
  ActiveOfferModel offer,
  int number,
){
  return TableRow(
    decoration: const BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: Color(0xffE5E7EB),
          width: 1,
        ),
      ),
    ),
    children: [
      // ============================================================
      // NO
      // ============================================================
      _tableCell(
        Center(
          child: Text(
            '$number',
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),
      ),

      // ============================================================
      // NAMA PEKERJAAN
      // ============================================================
      _tableCell(
        Text(
          offer.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ============================================================
      // HARGA
      // ============================================================
      _tableCell(
        Text(
          offer.price,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ============================================================
      // PERINGKAT
      // ============================================================
      _tableCell(
        _buildRanking(offer),
      ),

      // ============================================================
      // STATUS
      // ============================================================
      _tableCell(
        _buildStatus(offer),
      ),

      // ============================================================
      // BUKTI PEKERJAAN
      // ============================================================
      _tableCell(
        _buildProofButton(
          context,
          offer,
        ),
      ),

      // ============================================================
      // ACC PELANGGAN
      // ============================================================
      _tableCell(
        _buildApproval(offer),
      ),

      // ============================================================
      // AKSI
      // ============================================================
      _tableCell(
        _buildAction(
          context,
          offer,
        ),
      ),
    ],
  );
}

// ================================================================
// CELL TABEL
// ================================================================

Widget _tableCell(Widget child) {
  return Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 18,
    ),
    child: child,
  );
}

// ================================================================
// PERINGKAT
// ================================================================

Widget _buildRanking(ActiveOfferModel offer) {
  final bool isTop =
      offer.queuePosition == 1 || offer.isTop;

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '#${offer.queuePosition}',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      if (isTop) ...[
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
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
  final bool isWorking =
      offer.status == 'Sedang Dikerjakan';

  final bool waiting =
      offer.status == 'Menunggu Konfirmasi Selesai';

  final bool completed =
      offer.status == 'Selesai';

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
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
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
// BUKTI PEKERJAAN
// ================================================================

Widget _buildProofButton(
  BuildContext context,
  ActiveOfferModel offer,
) {
  return InkWell(
    onTap: () => _showCompletionProofDialog(
      context,
      offer,
    ),
    borderRadius: BorderRadius.circular(8),
    child: Container(
      width: 130,
      height: 75,
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xffE5E7EB),
        ),
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
            'Lihat / Upload',
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
  } else if (offer.status ==
      'Menunggu Konfirmasi Selesai') {
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
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
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
  final bool isWorking =
      offer.status == 'Sedang Dikerjakan';

  if (isWorking) {
    return SizedBox(
      height: 38,
      child: ElevatedButton.icon(
        onPressed: () => _showCompletionProofDialog(
          context,
          offer,
        ),
        icon: const Icon(
          Icons.camera_alt_outlined,
          size: 17,
        ),
        label: const Text(
          'Pekerjaan Selesai',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff16A34A),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  return OutlinedButton(
    onPressed: null,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 10,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    child: const Text(
      'Detail',
      style: TextStyle(
        fontSize: 12,
      ),
    ),
  );
}

// ================================================================
// DIALOG BUKTI PEKERJAAN
// ================================================================

Future<void> _showCompletionProofDialog(
  BuildContext context,
  ActiveOfferModel offer,
) async {
  if (offer.jobId == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'ID pekerjaan tidak ditemukan.',
        ),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final result =
      await showDialog<CompletionProofResult>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return CompletionProofDialog(
        jobId: offer.jobId,
      );
    },
  );

  if (result == null) return;

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Bukti pekerjaan berhasil dikirim.',
      ),
      backgroundColor: Color(0xff16A34A),
      behavior: SnackBarBehavior.floating,
    ),
  );
}