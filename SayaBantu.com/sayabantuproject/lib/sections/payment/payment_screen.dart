import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../models/payment_model.dart';
import '../../../models/payment_summary_model.dart';
import '../../../models/payment_detail_model.dart';
import '../../../services/api_service.dart';
import '../../../services/payment_service.dart';
import '../../../sections/customer/payment_detail_dialog.dart';

class PaymentScreen extends StatefulWidget {
  final String role; // 'mitra' atau 'pelanggan'

  const PaymentScreen({
    super.key,
    required this.role,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  List<PaymentModel> _payments = [];
  PaymentSummary? _summary;

  bool get _isMitra => widget.role.toLowerCase() == 'mitra';

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  // ============================================================
  // LOAD DARI API
  // ============================================================
  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final endpoint = _isMitra
          ? '/mitra/earnings'
          : '/pelanggan/payments';

      final response = await ApiService.get(endpoint);

      debugPrint('💰 [$endpoint] ${response.statusCode}');
      debugPrint('💰 BODY: ${response.body}');

      if (response.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat (${response.statusCode})';
        });
        return;
      }

      final decoded = jsonDecode(response.body);

      if (decoded['success'] != true) {
        setState(() {
          _isLoading = false;
          _errorMessage = decoded['message']?.toString() ?? 'Gagal memuat.';
        });
        return;
      }

      if (!mounted) return;

      setState(() {
        _summary = decoded['summary'] is Map
            ? PaymentSummary.fromJson(decoded['summary'])
            : null;

        _payments = (decoded['data'] is List)
            ? (decoded['data'] as List)
                .map((e) => PaymentModel.fromJson(e))
                .toList()
            : [];

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ ERROR: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  // ============================================================
  // BUKA DIALOG DETAIL PEMBAYARAN (PELANGGAN)
  // ============================================================
  Future<void> _openPaymentDetail(PaymentModel p) async {
    // Loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      ),
    );

    // Fetch detail dari API
    final detailData =
        await PaymentService.getPelangganPaymentDetail(p.id);

    if (!mounted) return;
    Navigator.pop(context); // tutup loading

    if (detailData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memuat detail pembayaran.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final detail = PaymentDetailModel.fromJson(detailData);

    // Buka dialog detail
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentDetailDialog(detail: detail),
    );

    // Kalau user berhasil upload bukti, reload data
    if (result == true && mounted) {
      _loadPayments();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPayments,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isMobile ? 16 : 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 24),

                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child:
                              CircularProgressIndicator(color: Colors.orange),
                        ),
                      )
                    else if (_errorMessage != null)
                      _buildErrorState()
                    else ...[
                      _buildSummary(context, isMobile),
                      const SizedBox(height: 28),
                      Text(
                        _isMitra
                            ? 'Riwayat Pendapatan'
                            : 'Riwayat Pembayaran',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 16),
                      if (_payments.isEmpty)
                        _buildEmptyState()
                      else
                        ..._payments.map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildPaymentCard(context, p),
                            )),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================
  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pembayaran',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          _isMitra
              ? 'Lihat riwayat pendapatan dari pekerjaan yang telah selesai.'
              : 'Lihat riwayat transaksi dan pembayaran pekerjaan.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================
  Widget _buildSummary(BuildContext context, bool isMobile) {
    final s = _summary;
    if (s == null) return const SizedBox.shrink();

    final cards = <Widget>[];

    if (_isMitra) {
      cards.add(_summaryCard(
        context,
        title: 'Total Pendapatan',
        value: s.totalMitraEarning,
        icon: Icons.account_balance_wallet_outlined,
        color: Colors.green,
      ));
      cards.add(_summaryCard(
        context,
        title: 'Menunggu Cair',
        value: s.totalPending,
        icon: Icons.hourglass_top,
        color: Colors.orange,
      ));
      cards.add(_summaryCard(
        context,
        title: 'Transaksi',
        valueText: '${s.totalTransaksi} transaksi',
        icon: Icons.receipt_long_outlined,
        color: Colors.blue,
      ));
    } else {
      cards.add(_summaryCard(
        context,
        title: 'Total Pembayaran',
        value: s.totalPembayaran,
        icon: Icons.account_balance_wallet_outlined,
        color: Colors.blue,
      ));
      cards.add(_summaryCard(
        context,
        title: 'Transaksi',
        valueText: '${s.totalTransaksi} transaksi',
        icon: Icons.receipt_long_outlined,
        color: Colors.orange,
      ));
      cards.add(_summaryCard(
        context,
        title: 'Komisi Aplikasi',
        value: s.totalKomisi,
        icon: Icons.percent,
        color: Colors.green,
      ));
    }

    if (isMobile) {
      return Column(
        children: cards
            .expand((c) => [c, const SizedBox(height: 12)])
            .toList()
          ..removeLast(),
      );
    }

    return Row(
      children: cards
          .expand((c) => [Expanded(child: c), const SizedBox(width: 16)])
          .toList()
        ..removeLast(),
    );
  }

  Widget _summaryCard(
    BuildContext context, {
    required String title,
    double? value,
    String? valueText,
    required IconData icon,
    Color color = Colors.orange,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 5),
                Text(
                  valueText ?? PaymentModel.formatRupiah(value ?? 0),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAYMENT CARD
  // ============================================================
  Widget _buildPaymentCard(BuildContext context, PaymentModel p) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long, color: Colors.orange),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.jobTitle ?? 'Pekerjaan',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _isMitra
                          ? 'Pelanggan: ${p.pelangganName ?? "-"}'
                          : 'Mitra: ${p.mitraName ?? "-"}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      p.formattedDate,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _statusBadge(p),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 12),

          _detailRow('Nilai pekerjaan', PaymentModel.formatRupiah(p.jobAmount)),
          const SizedBox(height: 8),

          if (_isMitra) ...[
            _detailRow(
              'Komisi aplikasi (${p.commissionPercent.toStringAsFixed(0)}%)',
              '- ${PaymentModel.formatRupiah(p.commissionAmount)}',
            ),
            const SizedBox(height: 8),
            _detailRow(
              'Pendapatan Mitra',
              PaymentModel.formatRupiah(p.mitraEarning),
              isBold: true,
            ),
          ] else ...[
            _detailRow(
              'Komisi aplikasi',
              PaymentModel.formatRupiah(p.commissionAmount),
            ),
            const SizedBox(height: 8),
            _detailRow(
              'Total pembayaran',
              PaymentModel.formatRupiah(p.totalPaid),
              isBold: true,
            ),
          ],

          // ======================================================
          // TOMBOL AKSI PELANGGAN
          // Hanya muncul kalau status = pending (belum bayar)
          // ======================================================
          if (!_isMitra && p.canUploadCustomerProof) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openPaymentDetail(p),
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text(
                  'Bayar & Upload Bukti',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],

          // ======================================================
          // STATUS INFO UNTUK PELANGGAN (kalau bukan pending)
          // ======================================================
          if (!_isMitra && p.isWaitingVerification) ...[
            const SizedBox(height: 16),
            _buildStatusInfo(
              icon: Icons.hourglass_top,
              color: Colors.purple,
              message: 'Bukti transfer sedang diverifikasi admin.',
            ),
          ],

          if (!_isMitra && p.isPaid) ...[
            const SizedBox(height: 16),
            _buildStatusInfo(
              icon: Icons.sync,
              color: Colors.blue,
              message: 'Pembayaran terverifikasi. Menunggu admin transfer ke mitra.',
            ),
          ],

          if (!_isMitra && p.isSettled) ...[
            const SizedBox(height: 16),
            _buildStatusInfo(
              icon: Icons.check_circle,
              color: Colors.green,
              message: 'Pembayaran selesai. Dana sudah diteruskan ke mitra.',
            ),
          ],

          // ======================================================
          // STATUS INFO UNTUK MITRA
          // ======================================================
          if (_isMitra && (p.isPending || p.isWaitingVerification)) ...[
            const SizedBox(height: 16),
            _buildStatusInfo(
              icon: Icons.hourglass_top,
              color: Colors.orange,
              message: 'Menunggu pelanggan menyelesaikan pembayaran.',
            ),
          ],

          if (_isMitra && p.isPaid) ...[
            const SizedBox(height: 16),
            _buildStatusInfo(
              icon: Icons.sync,
              color: Colors.blue,
              message: 'Pembayaran sudah diverifikasi. Menunggu admin transfer ke rekening Anda.',
            ),
          ],

          if (_isMitra && p.isSettled) ...[
            const SizedBox(height: 16),
            _buildStatusInfo(
              icon: Icons.check_circle,
              color: Colors.green,
              message: 'Dana sudah ditransfer ke rekening Anda.',
            ),
          ],

          // ======================================================
          // LIHAT DETAIL (untuk pelanggan, selalu bisa)
          // ======================================================
          if (!_isMitra) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _openPaymentDetail(p),
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text('Lihat Detail Pembayaran'),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================
  Widget _statusBadge(PaymentModel p) {
    final color = _statusColor(p.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        p.statusLabel,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'settled':
        return Colors.green;
      case 'paid':
        return Colors.blue;
      case 'waiting_verification':
        return Colors.purple;
      case 'pending':
        return Colors.orange;
      case 'refunded':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusInfo({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String title, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ERROR & EMPTY
  // ============================================================
  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadPayments,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _isMitra
                ? 'Belum ada pendapatan.'
                : 'Belum ada transaksi pembayaran.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}