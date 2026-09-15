import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../models/payment_model.dart';
import '../../../models/payment_summary_model.dart';
import '../../../models/payment_detail_model.dart';
import '../../../services/api_service.dart';
import '../../../services/payment_service.dart';
import '../../../sections/customer/payment_detail_dialog.dart';
import '../../../sections/customer/rating_dialog.dart';

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

  // 🆕 Filter status
  String _selectedStatus = 'Semua';

  // 🆕 Cache status rating per job_id (biar tidak fetch berulang)
  final Map<int, Map<String, dynamic>?> _ratingCache = {};

  bool get _isMitra => widget.role.toLowerCase() == 'mitra';

  // ============================================================
  // 🆕 FILTER OPTIONS — beda per role
  // ============================================================
  List<String> get _filterOptions {
    if (_isMitra) {
      return ['Semua', 'Menunggu Bayar', 'Diverifikasi', 'Selesai'];
    }
    return ['Semua', 'Menunggu Bayar', 'Menunggu Verifikasi', 'Selesai'];
  }

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  // ============================================================
  // 🆕 FILTERED PAYMENTS
  // ============================================================
  List<PaymentModel> get _filteredPayments {
    if (_selectedStatus == 'Semua') return _payments;

    return _payments.where((p) {
      switch (_selectedStatus) {
        case 'Menunggu Bayar':
          return p.status == 'pending';
        case 'Menunggu Verifikasi':
          return p.status == 'waiting_verification';
        case 'Diverifikasi':
          return p.status == 'paid';
        case 'Selesai':
          return p.status == 'settled';
        default:
          return true;
      }
    }).toList();
  }

  // ============================================================
  // LOAD DARI API
  // ============================================================
  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _ratingCache.clear(); // 🆕 bersihkan cache biar fresh
    });

    try {
      final endpoint =
          _isMitra ? '/mitra/earnings' : '/pelanggan/payments';

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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      ),
    );

    final detailData = await PaymentService.getPelangganPaymentDetail(p.id);

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

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentDetailDialog(detail: detail),
    );

    if (result == true && mounted) {
      _loadPayments();
    }
  }

  // ============================================================
  // 🆕 CEK STATUS RATING
  // ============================================================
  Future<Map<String, dynamic>?> _checkRating(int jobId) async {
    if (_ratingCache.containsKey(jobId)) {
      return _ratingCache[jobId];
    }

    final result = await PaymentService.checkJobRating(jobId);
    _ratingCache[jobId] = result;
    return result;
  }

  // ============================================================
  // 🆕 DIALOG BERI RATING
  // ============================================================
  Future<void> _showRatingDialog(PaymentModel p) async {
    final submitted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        jobId: p.jobId,
        jobTitle: p.jobTitle ?? 'Pekerjaan',
        mitraName: p.mitraName ?? 'Mitra',
      ),
    );

    if (submitted == true && mounted) {
      _ratingCache.clear();
      _loadPayments();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terima kasih! Rating berhasil dikirim.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
                          child: CircularProgressIndicator(
                              color: Colors.orange),
                        ),
                      )
                    else if (_errorMessage != null)
                      _buildErrorState()
                    else ...[
                      _buildSummary(context, isMobile),
                      const SizedBox(height: 20),

                      // 🆕 Filter status
                      _buildFilterBar(),

                      const SizedBox(height: 20),
                      Text(
                        _isMitra
                            ? 'Riwayat Pendapatan'
                            : 'Riwayat Pembayaran',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // 🆕 Pakai filtered payments
                      if (_filteredPayments.isEmpty)
                        _buildEmptyState()
                      else
                        ..._filteredPayments.map((p) => Padding(
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
  // 🆕 FILTER BAR
  // ============================================================
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 20, color: Colors.grey),
          const SizedBox(width: 10),
          const Text(
            'Filter:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedStatus,
              isExpanded: true,
              underline: const SizedBox(),
              borderRadius: BorderRadius.circular(10),
              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
              ),
              items: _filterOptions.map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text(s, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _selectedStatus = v);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_filteredPayments.length}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.orange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
          // 🆕 INFO KAPAN UPLOAD BUKTI
          // ======================================================
          if (p.customerProofUploadedAt != null) ...[
            const SizedBox(height: 12),
            _buildUploadInfo(
              icon: Icons.upload_file,
              color: Colors.blue,
              label: 'Bukti transfer diupload',
              date: p.customerProofUploadedAt!,
            ),
          ],

          if (p.mitraProofUploadedAt != null) ...[
            const SizedBox(height: 8),
            _buildUploadInfo(
              icon: Icons.check_circle_outline,
              color: Colors.green,
              label: 'Dana ditransfer ke mitra',
              date: p.mitraProofUploadedAt!,
            ),
          ],

          // ======================================================
          // TOMBOL AKSI PELANGGAN
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
          // STATUS INFO PELANGGAN
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
          // STATUS INFO MITRA
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
              message:
                  'Pembayaran sudah diverifikasi. Menunggu admin transfer ke rekening Anda.',
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
          // 🆕 TOMBOL RATING — hanya pelanggan & sudah upload bukti
          // ======================================================
          if (!_isMitra && p.customerProofUploadedAt != null) ...[
            const SizedBox(height: 12),
            FutureBuilder<Map<String, dynamic>?>(
              future: _checkRating(p.jobId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                return _buildRatingSection(p, snapshot.data);
              },
            ),
          ],

          // ======================================================
          // LIHAT DETAIL (untuk pelanggan)
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
  // 🆕 UPLOAD INFO WIDGET
  // ============================================================
  Widget _buildUploadInfo({
    required IconData icon,
    required Color color,
    required String label,
    required DateTime date,
  }) {
    final local = date.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final formatted =
        '${local.day.toString().padLeft(2, '0')} '
        '${months[local.month - 1]} ${local.year}, '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $formatted',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🆕 RATING SECTION
  // ============================================================
  Widget _buildRatingSection(PaymentModel p, Map<String, dynamic>? ratingStatus) {
    final hasRated = ratingStatus?['has_rating'] == true;
    final existingRating = ratingStatus?['data'];

    // Sudah pernah rating → tampilkan bintang + komentar
    if (hasRated && existingRating is Map) {
      final stars = (existingRating['stars'] ?? 0).toInt();
      final comment = existingRating['comment']?.toString() ?? '';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amber.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle,
                    color: Colors.green, size: 16),
                const SizedBox(width: 6),
                const Text(
                  'Anda sudah memberi rating',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) {
                return Icon(
                  i < stars
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: Colors.amber,
                  size: 20,
                );
              }),
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '"$comment"',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Belum rating → tombol
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showRatingDialog(p),
        icon: const Icon(Icons.star_rate_rounded, size: 18),
        label: const Text(
          'Beri Rating Mitra',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
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
    final isFiltered = _selectedStatus != 'Semua';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(
            isFiltered ? Icons.filter_alt_off : Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered
                ? 'Tidak ada pembayaran dengan status "$_selectedStatus".'
                : (_isMitra
                    ? 'Belum ada pendapatan.'
                    : 'Belum ada transaksi pembayaran.'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}