// lib/screens/AdminPaymentScreen.dart

import 'dart:convert';
import 'package:flutter/material.dart';

import '../../models/payment_model.dart';
import '../../models/payment_summary_model.dart';
import '../../services/api_service.dart';
import '../../services/payment_service.dart';
import '../../sections/admin/admin_payment_detail_dialog.dart';

class AdminPaymentScreen extends StatefulWidget {
  const AdminPaymentScreen({super.key});

  @override
  State<AdminPaymentScreen> createState() => _AdminPaymentScreenState();
}

class _AdminPaymentScreenState extends State<AdminPaymentScreen> {
  bool _isLoading = true;
  String? _error;

  List<PaymentModel> _payments = [];
  PaymentSummary? _summary;

  String _selectedStatus = 'Semua';
  final List<String> _statusOptions = [
    'Semua',
    'Menunggu Bayar',
    'Menunggu Verifikasi',
    'Siap Transfer',
    'Selesai',
    'Refund',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.get('/admin/payments');

      debugPrint('💰 ADMIN PAYMENTS: ${response.statusCode}');
      debugPrint('💰 BODY: ${response.body}');

      if (response.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _error = 'Gagal memuat (${response.statusCode})';
        });
        return;
      }

      final decoded = jsonDecode(response.body);

      if (decoded['success'] != true) {
        setState(() {
          _isLoading = false;
          _error = decoded['message']?.toString() ?? 'Gagal memuat.';
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
        _error = 'Terjadi kesalahan: $e';
      });
    }
  }

  // ============================================================
  // FILTER DATA
  // ============================================================
  List<PaymentModel> get _filteredPayments {
    if (_selectedStatus == 'Semua') {
      return _payments;
    }

    String? targetStatus;
    switch (_selectedStatus) {
      case 'Menunggu Bayar':
        targetStatus = 'pending';
        break;
      case 'Menunggu Verifikasi':
        targetStatus = 'waiting_verification';
        break;
      case 'Siap Transfer':
        targetStatus = 'paid';
        break;
      case 'Selesai':
        targetStatus = 'settled';
        break;
      case 'Refund':
        targetStatus = 'refunded';
        break;
    }

    if (targetStatus == null) return _payments;

    return _payments.where((p) => p.status == targetStatus).toList();
  }

  // ============================================================
  // BUKA DIALOG DETAIL PEMBAYARAN
  // ============================================================
  Future<void> _openPaymentDetail(PaymentModel p) async {
    // Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      ),
    );

    // Fetch detail dari API
    final detailData = await PaymentService.getAdminPaymentDetail(p.id);

    if (!mounted) return;
    Navigator.pop(context); // tutup loading

    PaymentModel paymentToUse = p;

    if (detailData != null && detailData['payment'] is Map) {
      // 1. Parse payment dari detail
      final parsed = PaymentModel.fromJson(
        Map<String, dynamic>.from(detailData['payment']),
      );

      // 2. Siapkan mitraBank (kalau ada)
      Map<String, dynamic>? bankMap;
      if (detailData['transfer_to'] is Map) {
        bankMap = Map<String, dynamic>.from(detailData['transfer_to']);
      }

      // 3. Bikin PaymentModel baru dengan mitraBank
      paymentToUse = PaymentModel(
        id: parsed.id,
        jobId: parsed.jobId,
        pelangganId: parsed.pelangganId,
        mitraId: parsed.mitraId,
        jobAmount: parsed.jobAmount,
        commissionPercent: parsed.commissionPercent,
        commissionAmount: parsed.commissionAmount,
        totalPaid: parsed.totalPaid,
        mitraEarning: parsed.mitraEarning,
        status: parsed.status,
        paymentMethod: parsed.paymentMethod,
        referenceCode: parsed.referenceCode,
        customerProofUrl: parsed.customerProofUrl,
        customerProofUploadedAt: parsed.customerProofUploadedAt,
        customerBankName: parsed.customerBankName,
        customerAccountName: parsed.customerAccountName,
        mitraProofUrl: parsed.mitraProofUrl,
        mitraProofUploadedAt: parsed.mitraProofUploadedAt,
        adminNote: parsed.adminNote,
        mitraBank: bankMap ?? parsed.mitraBank,
        paidAt: parsed.paidAt,
        settledAt: parsed.settledAt,
        createdAt: parsed.createdAt,
        jobTitle: parsed.jobTitle,
        mitraName: parsed.mitraName,
        pelangganName: parsed.pelangganName,
      );
    }

    // Buka dialog admin
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminPaymentDetailDialog(payment: paymentToUse),
    );

    // Kalau ada aksi (verify/settle/refund), reload data
    if (result == true && mounted) {
      _loadData();
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================
  Color _getStatusColor(String status) {
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'settled':
        return Icons.check_circle_outline;
      case 'paid':
        return Icons.sync;
      case 'waiting_verification':
        return Icons.fact_check_outlined;
      case 'pending':
        return Icons.access_time;
      case 'refunded':
        return Icons.undo;
      case 'failed':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu Bayar';
      case 'waiting_verification':
        return 'Menunggu Verifikasi';
      case 'paid':
        return 'Siap Transfer';
      case 'settled':
        return 'Selesai';
      case 'refunded':
        return 'Refund';
      case 'failed':
        return 'Gagal';
      default:
        return 'Tidak Diketahui';
    }
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pembayaran',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kelola dan pantau seluruh transaksi pembayaran pelanggan dan mitra.',
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),

                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: CircularProgressIndicator(color: Colors.orange),
                    ),
                  )
                else if (_error != null)
                  _buildError()
                else ...[
                  _buildSummarySection(),
                  const SizedBox(height: 24),
                  _buildFilterSection(),
                  const SizedBox(height: 18),
                  if (_filteredPayments.isEmpty)
                    _buildEmptyState()
                  else if (isMobile)
                    _buildMobileList()
                  else
                    _buildDesktopTable(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================
  Widget _buildSummarySection() {
    final s = _summary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;

        final cards = [
          _summaryCard(
            title: 'Total Transaksi',
            value: PaymentModel.formatRupiah(s?.totalPembayaran ?? 0),
            icon: Icons.account_balance_wallet_outlined,
            color: Colors.blue,
          ),
          _summaryCard(
            title: 'Komisi Platform',
            value: PaymentModel.formatRupiah(s?.totalKomisi ?? 0),
            icon: Icons.account_balance,
            color: Colors.green,
          ),
          _summaryCard(
            title: 'Total ke Mitra',
            value: PaymentModel.formatRupiah(s?.totalMitraEarning ?? 0),
            icon: Icons.handshake_outlined,
            color: Colors.orange,
          ),
        ];

        if (isMobile) {
          return Column(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i != cards.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 14),
            Expanded(child: cards[1]),
            const SizedBox(width: 14),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 27),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  value,
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
  // FILTER — FIXED RESPONSIVE + ANTI OVERFLOW
  // ============================================================
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.4),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Kalau layar sempit, stack vertikal
          final isNarrow = constraints.maxWidth < 550;

          // Widget dropdown (dipakai di kedua layout)
          final dropdown = DropdownButtonFormField<String>(
            value: _selectedStatus,
            isExpanded: true, // ✅ KUNCI FIX — supaya tidak overflow
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            items: _statusOptions.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(
                  status,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedStatus = value);
            },
          );

          // ============================================
          // LAYOUT NARROW: judul + counter di atas, dropdown di bawah
          // ============================================
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.filter_list, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Filter Status',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      '${_filteredPayments.length} transaksi',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                dropdown,
              ],
            );
          }

          // ============================================
          // LAYOUT WIDE: semua dalam satu baris
          // ============================================
          return Row(
            children: [
              const Icon(Icons.filter_list, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Filter Status:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 15),
              SizedBox(
                width: 220,
                child: dropdown,
              ),
              const Spacer(),
              Text(
                '${_filteredPayments.length} transaksi',
                style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // DESKTOP TABLE
  // ============================================================
  Widget _buildDesktopTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.4),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          headingRowColor: MaterialStateProperty.all(
            Theme.of(context).colorScheme.surface,
          ),
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Pekerjaan')),
            DataColumn(label: Text('Pelanggan')),
            DataColumn(label: Text('Mitra')),
            DataColumn(label: Text('Total')),
            DataColumn(label: Text('Komisi')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Aksi')),
          ],
          rows: _filteredPayments.map((p) {
            return DataRow(
              cells: [
                DataCell(Text(
                  'PAY-${p.id.toString().padLeft(3, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                )),
                DataCell(Text(p.jobTitle ?? '-')),
                DataCell(Text(p.pelangganName ?? '-')),
                DataCell(Text(p.mitraName ?? '-')),
                DataCell(Text(PaymentModel.formatRupiah(p.jobAmount))),
                DataCell(Text(PaymentModel.formatRupiah(p.commissionAmount))),
                DataCell(_statusBadge(p.status)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Lihat Detail',
                        icon: const Icon(Icons.visibility_outlined),
                        onPressed: () => _openPaymentDetail(p),
                      ),
                      // Quick action badge
                      if (p.canVerifyCustomerProof)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.fiber_new,
                              color: Colors.purple, size: 20),
                        ),
                      if (p.canSettleToMitra)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.priority_high,
                              color: Colors.blue, size: 20),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE LIST
  // ============================================================
  Widget _buildMobileList() {
    return Column(
      children: _filteredPayments.map((p) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'PAY-${p.id.toString().padLeft(3, '0')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _statusBadge(p.status),
                ],
              ),
              const SizedBox(height: 12),
              _mobileInfoRow(Icons.work_outline, 'Pekerjaan', p.jobTitle ?? '-'),
              _mobileInfoRow(Icons.person_outline, 'Pelanggan',
                  p.pelangganName ?? '-'),
              _mobileInfoRow(
                  Icons.handshake_outlined, 'Mitra', p.mitraName ?? '-'),
              _mobileInfoRow(Icons.calendar_today_outlined, 'Tanggal',
                  p.formattedDate),
              const Divider(height: 22),
              _mobileInfoRow(
                Icons.payments_outlined,
                'Nilai Pekerjaan',
                PaymentModel.formatRupiah(p.jobAmount),
              ),
              _mobileInfoRow(
                Icons.account_balance_outlined,
                'Komisi',
                PaymentModel.formatRupiah(p.commissionAmount),
              ),
              _mobileInfoRow(
                Icons.wallet_outlined,
                'Mitra Terima',
                PaymentModel.formatRupiah(p.mitraEarning),
                isBold: true,
              ),
              const SizedBox(height: 12),

              // Banner quick action
              if (p.canVerifyCustomerProof)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.fact_check_outlined,
                          color: Colors.purple, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Perlu verifikasi bukti transfer pelanggan',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (p.canSettleToMitra)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.priority_high, color: Colors.blue, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Siap ditransfer ke mitra',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openPaymentDetail(p),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Lihat Detail'),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _mobileInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.color
                ?.withOpacity(0.6),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================
  Widget _statusBadge(String status) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(status), size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            _getStatusLabel(status),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR & EMPTY
  // ============================================================
  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(35),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
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
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 55, color: Colors.grey),
          SizedBox(height: 12),
          Text('Tidak ada data pembayaran.',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}