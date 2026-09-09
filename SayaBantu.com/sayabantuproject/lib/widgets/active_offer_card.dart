import 'package:flutter/material.dart';

import '../models/active_offer_model.dart';
import '../sections/partner/completion_proof_dialog.dart';

class ActiveOfferCard extends StatelessWidget {
  final ActiveOfferModel offer;

  const ActiveOfferCard({
    super.key,
    required this.offer,
  });

  @override
  Widget build(BuildContext context) {
    final bool accepted = offer.status == 'Diterima Pelanggan';
    final bool waitingConfirmation = offer.status == 'Menunggu Konfirmasi';
    final bool completed = offer.status == 'Selesai';

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accepted
              ? const Color(0xff16A34A)
              : waitingConfirmation
                  ? const Color(0xffF59E0B)
                  : completed
                      ? const Color(0xff2563EB)
                      : const Color(0xffE5E7EB),
          width: accepted || waitingConfirmation || completed ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul
          Text(
            offer.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 20),

          // Info
          Row(
            children: [
              const Icon(Icons.attach_money, color: Colors.orange),
              const SizedBox(width: 6),
              Text(
                offer.price,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(width: 35),
              const Icon(Icons.groups_outlined, color: Colors.blue),
              const SizedBox(width: 6),
              Text(
                'Posisi #${offer.queuePosition}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (offer.queuePosition == 1 || offer.isTop) ...[
                const SizedBox(width: 10),
                const Text(
                  'TERATAS!',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const Spacer(),
              _buildStatusBadge(
                accepted: accepted,
                waitingConfirmation: waitingConfirmation,
                completed: completed,
              ),
            ],
          ),

          // Diterima → tampilkan tombol kirim bukti
          if (accepted) ...[
            const SizedBox(height: 24),
            const Divider(color: Color(0xffE5E7EB)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xffF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffBBF7D0)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Color(0xff16A34A), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pekerjaan kamu telah diterima pelanggan. Setelah pekerjaan selesai, kirimkan bukti pekerjaan.',
                      style: TextStyle(
                        color: Color(0xff166534),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tombol Kirim Bukti
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCompletionProofDialog(context),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text(
                  'Pekerjaan Selesai',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff16A34A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],

          // Menunggu Konfirmasi
          if (waitingConfirmation) ...[
            const SizedBox(height: 20),
            _buildWaitingConfirmation(),
          ],

          // Selesai
          if (completed) ...[
            const SizedBox(height: 20),
            _buildCompleted(),
          ],
        ],
      ),
    );
  }

  // --------------------------------------------------------------
  // Status Badge
  // --------------------------------------------------------------
  Widget _buildStatusBadge({
    required bool accepted,
    required bool waitingConfirmation,
    required bool completed,
  }) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    if (completed) {
      backgroundColor = const Color(0xffDBEAFE);
      textColor = const Color(0xff2563EB);
      icon = Icons.check_circle;
    } else if (waitingConfirmation) {
      backgroundColor = const Color(0xffFFF7ED);
      textColor = const Color(0xffEA580C);
      icon = Icons.hourglass_top_rounded;
    } else if (accepted) {
      backgroundColor = const Color(0xffDCFCE7);
      textColor = const Color(0xff16A34A);
      icon = Icons.check_circle;
    } else {
      backgroundColor = const Color(0xffFFF7ED);
      textColor = const Color(0xffEA580C);
      icon = Icons.access_time;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 6),
          Text(
            offer.status,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------
  // Menunggu Konfirmasi
  // --------------------------------------------------------------
  Widget _buildWaitingConfirmation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xffFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffFED7AA)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hourglass_top_rounded, color: Color(0xffEA580C)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bukti pekerjaan telah dikirim dan sedang menunggu konfirmasi pelanggan.',
              style: TextStyle(
                color: Color(0xff9A3412),
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------
  // Selesai
  // --------------------------------------------------------------
  Widget _buildCompleted() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xffEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffBFDBFE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, color: Color(0xff2563EB)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pekerjaan telah selesai dan dikonfirmasi pelanggan.',
              style: TextStyle(
                color: Color(0xff1D4ED8),
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------
  // Dialog Bukti Pekerjaan (dengan jobId)
  // --------------------------------------------------------------
  Future<void> _showCompletionProofDialog(BuildContext context) async {
    // Validasi jobId tersedia
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
        return CompletionProofDialog(
          jobId: offer.jobId, // <-- kirim job ID, bukan bid ID
        );
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
}