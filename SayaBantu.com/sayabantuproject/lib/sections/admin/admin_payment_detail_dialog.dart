import 'package:flutter/material.dart';

import '../../models/payment_model.dart';
import '../../theme/admin_theme.dart';
import '../../theme/admin_theme_provider.dart';
import '../../theme/app_colors.dart';

class AdminPaymentDetailDialog extends StatefulWidget {
  final PaymentModel payment;

  const AdminPaymentDetailDialog({super.key, required this.payment});

  @override
  State<AdminPaymentDetailDialog> createState() =>
      _AdminPaymentDetailDialogState();
}

class _AdminPaymentDetailDialogState extends State<AdminPaymentDetailDialog> {
  static const double _radius = 10;

  AdminTheme _themeOf(BuildContext context) => AdminThemeProvider.of(context);

  @override
  Widget build(BuildContext context) {
    final t = _themeOf(context);
    final p = widget.payment;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: t.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(_radius),
                    ),
                    child: Icon(Icons.receipt_long, color: t.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'PAY-${p.id.toString().padLeft(3, '0')}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: t.cellText,
                          ),
                    ),
                  ),
                  _statusBadge(p, t),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: t.headerText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: t.divider),
              const SizedBox(height: 16),

              // CONTENT
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _infoRow('Pekerjaan', p.jobTitle ?? '-', t),
                      _infoRow('Pelanggan', p.pelangganName ?? '-', t),
                      _infoRow('Mitra', p.mitraName ?? '-', t),
                      _infoRow('Tanggal', p.formattedDate, t),

                      Divider(height: 25, color: t.divider),

                      _infoRow('Nilai Pekerjaan', PaymentModel.formatRupiah(p.jobAmount), t),
                      _infoRow('Komisi Platform', PaymentModel.formatRupiah(p.commissionAmount), t),
                      _infoRow('Mitra Terima', PaymentModel.formatRupiah(p.mitraEarning), t, isBold: true),

                      // INFO BANNER JIKA MASIH ESCROW (HELD)
                      if (p.status == 'held') ...[
                        Divider(height: 25, color: t.divider),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: t.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(_radius),
                            border: Border.all(color: t.info.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.hourglass_top, color: t.info, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Menunggu Pelanggan (ACC)',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: t.cellText),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Dana saat ini berada di Escrow. Sistem akan OTOMATIS memindahkannya ke Saldo Mitra & Kas Platform begitu pelanggan menekan tombol "Selesai / ACC" di aplikasi mereka.',
                                style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // INFO BANNER JIKA SUDAH SELESAI (RELEASED)
                      if (p.status == 'released' || p.status == 'settled') ...[
                        Divider(height: 25, color: t.divider),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: t.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(_radius),
                            border: Border.all(color: t.success.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: t.success, size: 24),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Transaksi Selesai. Dana sudah masuk ke Saldo Mitra dan Kas Platform.',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ACTIONS (Hanya Tombol Tutup)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      foregroundColor: AppColors.grey700,
                      side: const BorderSide(color: AppColors.grey300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_radius),
                      ),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, AdminTheme t, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: TextStyle(color: t.headerText, fontSize: 12.5)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isBold ? 13.5 : 13,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: t.cellText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(PaymentModel p, AdminTheme t) {
    final color = _getStatusColor(p.status, t);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(p.statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Color _getStatusColor(String status, AdminTheme t) {
    switch (status) {
      case 'released':
      case 'settled':
        return t.success;
      case 'held':
        return AppColors.infoBlue;
      case 'pending':
        return t.accent;
      case 'refunded':
      case 'failed':
        return t.danger;
      default:
        return t.headerText;
    }
  }
}