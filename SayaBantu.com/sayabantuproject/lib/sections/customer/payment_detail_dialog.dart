import 'package:flutter/material.dart';
import '../../models/payment_model.dart';
import '../../models/payment_detail_model.dart';

class PaymentDetailDialog extends StatelessWidget {
  final PaymentDetailModel detail;

  const PaymentDetailDialog({super.key, required this.detail});

  static const Color _accent = Color(0xFF14B8A6); // Warna Teal

  @override
  Widget build(BuildContext context) {
    final p = detail.payment;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.receipt_long, color: _accent),
          const SizedBox(width: 8),
          Text('Detail Pembayaran'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('ID Pembayaran', 'PAY-${p.id.toString().padLeft(3, '0')}'),
            _infoRow('Pekerjaan', p.jobTitle ?? '-'),
            _infoRow('Mitra', p.mitraName ?? '-'),
            _infoRow('Tanggal', p.formattedDate),
            const Divider(height: 24),
            _infoRow('Harga Jasa', PaymentModel.formatRupiah(p.jobAmount)),
            _infoRow('Komisi Aplikasi', PaymentModel.formatRupiah(p.commissionAmount)),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Bayar', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  PaymentModel.formatRupiah(p.totalPaid),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: _accent, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Pembayaran telah diproses menggunakan Saldo Dompet Anda.',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}