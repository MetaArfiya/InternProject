import 'dart:convert';
import 'package:flutter/material.dart';

import '../../models/payment_model.dart';
import '../../models/payment_summary_model.dart';
import '../../services/api_service.dart';
import '../../services/payment_service.dart';
import '../../sections/admin/admin_payment_detail_dialog.dart';
import '../../theme/app_colors.dart';

class AdminPaymentScreen extends StatefulWidget {
  const AdminPaymentScreen({super.key});

  @override
  State<AdminPaymentScreen> createState() => _AdminPaymentScreenState();
}

class _AdminPaymentScreenState extends State<AdminPaymentScreen> {
  // ============================================================
  // LOKAL WARNA
  // ============================================================
  static const Color _danger = Color(0xFFDC2626);
  static const Color _dangerSoft = Color(0xFFFEF2F2);
  static const Color _dangerBorder = Color(0xFFFCA5A5);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _warningSoft = Color(0xFFFFF7ED);
  static const Color _info = Color(0xFF2563EB);
  static const Color _infoSoft = Color(0xFFEFF6FF);

  // ============================================================
  // STATE
  // ============================================================

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

  // ============================================================
  // PAGINATION STATE
  // ============================================================

  int _currentPage = 1;
  int _itemsPerPage = 10;
  final List<int> _itemsPerPageOptions = [5, 10, 25, 50];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final response = await ApiService.get('/admin/payments');

      debugPrint('💰 ADMIN PAYMENTS: ${response.statusCode}');
      debugPrint('💰 BODY: ${response.body}');

      if (response.statusCode != 200) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _error = 'Gagal memuat data (${response.statusCode})';
        });

        return;
      }

      final decoded = jsonDecode(response.body);

      if (decoded['success'] != true) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _error =
              decoded['message']?.toString() ?? 'Gagal memuat pembayaran.';
        });

        return;
      }

      if (!mounted) return;

      setState(() {
        _summary = decoded['summary'] is Map
            ? PaymentSummary.fromJson(
                Map<String, dynamic>.from(decoded['summary']),
              )
            : null;

        _payments = decoded['data'] is List
            ? (decoded['data'] as List)
                .map(
                  (e) => PaymentModel.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
            : [];

        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ ERROR ADMIN PAYMENT: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'Terjadi kesalahan: $e';
      });
    }
  }

  // ============================================================
  // FILTER & PAGINATION HELPERS
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

    if (targetStatus == null) {
      return _payments;
    }

    return _payments
        .where((payment) => payment.status == targetStatus)
        .toList();
  }

  List<PaymentModel> get _paginatedPayments {
    final filtered = _filteredPayments;
    if (filtered.isEmpty) return [];

    final start = (_currentPage - 1) * _itemsPerPage;
    if (start >= filtered.length) return [];

    final end = (start + _itemsPerPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  int get _totalPages {
    final total = _filteredPayments.length;
    if (total == 0) return 1;
    return ((total - 1) ~/ _itemsPerPage) + 1;
  }

  // ============================================================
  // OPEN PAYMENT DETAIL
  // ============================================================

  Future<void> _openPaymentDetail(PaymentModel payment) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryTeal,
          ),
        );
      },
    );

    final detailData =
        await PaymentService.getAdminPaymentDetail(payment.id);

    if (!mounted) return;

    Navigator.pop(context);

    PaymentModel paymentToUse = payment;

    if (detailData != null && detailData['payment'] is Map) {
      final parsed = PaymentModel.fromJson(
        Map<String, dynamic>.from(
          detailData['payment'],
        ),
      );

      Map<String, dynamic>? bankMap;

      if (detailData['transfer_to'] is Map) {
        bankMap = Map<String, dynamic>.from(
          detailData['transfer_to'],
        );
      }

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

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AdminPaymentDetailDialog(
          payment: paymentToUse,
        );
      },
    );

    if (result == true && mounted) {
      _loadData();
    }
  }

  // ============================================================
  // STATUS COLOR, ICON, LABEL
  // ============================================================

  Color _getStatusColor(String status) {
    switch (status) {
      case 'settled':
        return AppColors.darkTeal;
      case 'paid':
        return AppColors.primaryTeal;
      case 'waiting_verification':
        return _info;
      case 'pending':
        return _warning;
      case 'refunded':
      case 'failed':
        return _danger;
      default:
        return AppColors.grey500;
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
    return Container(
      color: AppColors.sectionAltLight,
      width: double.infinity,
      height: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          final isMobile = width < 700;
          final isTablet = width >= 700 && width < 1100;

          return RefreshIndicator(
            color: AppColors.primaryTeal,
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : isTablet ? 20 : 28,
                vertical: isMobile ? 18 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isMobile),

                  SizedBox(height: isMobile ? 20 : 26),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 80),
                        child: CircularProgressIndicator(
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    )
                  else if (_error != null)
                    _buildError()
                  else ...[
                    _buildSummarySection(),

                    SizedBox(height: isMobile ? 18 : 24),

                    _buildFilterSection(),

                    SizedBox(height: isMobile ? 14 : 18),

                    if (_filteredPayments.isEmpty)
                      _buildEmptyState()
                    else ...[
                      isMobile ? _buildMobileList() : _buildDesktopTable(),
                      _buildPagination(),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pembayaran',
          style: TextStyle(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.bold,
            color: AppColors.darkTeal,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Kelola dan pantau seluruh transaksi pembayaran pelanggan dan mitra.',
          style: TextStyle(
            fontSize: isMobile ? 13 : 14,
            height: 1.5,
            color: AppColors.grey600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY SECTION (3 KOTAK SEJAJAR)
  // ============================================================

  Widget _buildSummarySection() {
    final summary = _summary;

    final cards = [
      _summaryCard(
        title: 'Total Transaksi',
        subtitle: 'Semua Transaksi',
        value: PaymentModel.formatRupiah(
          summary?.totalPembayaran ?? 0,
        ),
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.primaryTeal,
      ),
      _summaryCard(
        title: 'Komisi Platform',
        subtitle: 'Pendapatan Admin',
        value: PaymentModel.formatRupiah(
          summary?.totalKomisi ?? 0,
        ),
        icon: Icons.account_balance_outlined,
        color: AppColors.darkTeal,
      ),
      _summaryCard(
        title: 'Total ke Mitra',
        subtitle: 'Pendapatan Mitra',
        value: PaymentModel.formatRupiah(
          summary?.totalMitraEarning ?? 0,
        ),
        icon: Icons.handshake_outlined,
        color: _warning,
      ),
    ];

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 8),
        Expanded(child: cards[1]),
        const SizedBox(width: 8),
        Expanded(child: cards[2]),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.sectionLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 2),

          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER
  // ============================================================

  Widget _buildFilterSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sectionLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey200),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;

          final dropdown = DropdownButtonFormField<String>(
            value: _selectedStatus,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            items: _statusOptions.map((status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(
                  status,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _selectedStatus = value;
                _currentPage = 1;
              });
            },
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.filter_list,
                      size: 20,
                      color: AppColors.primaryTeal,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Filter Status',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey900,
                        ),
                      ),
                    ),
                    Text(
                      '${_filteredPayments.length} transaksi',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                dropdown,
              ],
            );
          }

          return Row(
            children: [
              const Icon(
                Icons.filter_list,
                size: 20,
                color: AppColors.primaryTeal,
              ),
              const SizedBox(width: 9),
              const Text(
                'Filter Status',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 230,
                child: dropdown,
              ),
              const Spacer(),
              Text(
                '${_filteredPayments.length} transaksi',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.grey500,
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
        color: AppColors.sectionLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            horizontalMargin: 20,
            columnSpacing: 28,
            headingRowHeight: 52,
            dataRowMinHeight: 64,
            dataRowMaxHeight: 82,
            headingTextStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.darkTeal,
            ),
            headingRowColor:
                WidgetStateProperty.all(AppColors.sectionAltLight),
            columns: const [
              DataColumn(label: Text('ID TRANSAKSI')),
              DataColumn(label: Text('PEKERJAAN')),
              DataColumn(label: Text('PELANGGAN')),
              DataColumn(label: Text('MITRA')),
              DataColumn(label: Text('TOTAL')),
              DataColumn(label: Text('KOMISI')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('AKSI')),
            ],
            rows: _paginatedPayments.map((payment) {
              return DataRow(
                cells: [
                  DataCell(_desktopTransactionId(payment)),
                  DataCell(
                    SizedBox(
                      width: 190,
                      child: Text(
                        payment.jobTitle ?? '-',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.grey700,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 145,
                      child: Text(
                        payment.pelangganName ?? '-',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.grey700),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 145,
                      child: Text(
                        payment.mitraName ?? '-',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.grey700),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      PaymentModel.formatRupiah(payment.jobAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey900,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      PaymentModel.formatRupiah(payment.commissionAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkTeal,
                      ),
                    ),
                  ),
                  DataCell(_statusBadge(payment.status)),
                  DataCell(_desktopAction(payment)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _desktopTransactionId(PaymentModel payment) {
    final reference = payment.referenceCode?.trim();

    final idText = reference != null && reference.isNotEmpty
        ? reference
        : 'PAY-${payment.id.toString().padLeft(3, '0')}';

    return SizedBox(
      width: 145,
      child: Text(
        idText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: AppColors.grey900,
        ),
      ),
    );
  }

  Widget _desktopAction(PaymentModel payment) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Lihat Detail',
          icon: const Icon(
            Icons.visibility_outlined,
            size: 20,
          ),
          color: AppColors.primaryTeal,
          onPressed: () => _openPaymentDetail(payment),
        ),
        if (payment.canVerifyCustomerProof)
          const Padding(
            padding: EdgeInsets.only(left: 3),
            child: Icon(
              Icons.fiber_new,
              color: _info,
              size: 20,
            ),
          ),
        if (payment.canSettleToMitra)
          const Padding(
            padding: EdgeInsets.only(left: 3),
            child: Icon(
              Icons.priority_high,
              color: AppColors.primaryTeal,
              size: 20,
            ),
          ),
      ],
    );
  }

  // ============================================================
  // MOBILE LIST
  // ============================================================

  Widget _buildMobileList() {
    return Column(
      children: _paginatedPayments.map((payment) {
        return _mobilePaymentCard(payment);
      }).toList(),
    );
  }

  Widget _mobilePaymentCard(PaymentModel payment) {
    final reference = payment.referenceCode?.trim();

    final transactionId =
        reference != null && reference.isNotEmpty
            ? reference
            : 'PAY-${payment.id.toString().padLeft(3, '0')}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sectionLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.lightMint,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.primaryTeal,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ID Transaksi',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.grey500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      transactionId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Align(
                  alignment: Alignment.topRight,
                  child: _statusBadge(payment.status),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _mobileInfoCard(
            icon: Icons.work_outline,
            label: 'Pekerjaan',
            value: payment.jobTitle ?? '-',
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.sectionAltLight,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              children: [
                _mobileInfoRow(
                  Icons.person_outline,
                  'Pelanggan',
                  payment.pelangganName ?? '-',
                ),
                _mobileInfoRow(
                  Icons.handshake_outlined,
                  'Mitra',
                  payment.mitraName ?? '-',
                ),
                _mobileInfoRow(
                  Icons.calendar_today_outlined,
                  'Tanggal',
                  payment.formattedDate,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.sectionAltLight,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              children: [
                _mobileMoneyRow(
                  'Nilai Pekerjaan',
                  PaymentModel.formatRupiah(payment.jobAmount),
                ),
                _mobileMoneyRow(
                  'Komisi',
                  PaymentModel.formatRupiah(payment.commissionAmount),
                ),
                _mobileMoneyRow(
                  'Mitra Terima',
                  PaymentModel.formatRupiah(payment.mitraEarning),
                  isBold: true,
                  isLast: true,
                ),
              ],
            ),
          ),
          if (payment.canVerifyCustomerProof) ...[
            const SizedBox(height: 12),
            _quickActionBanner(
              icon: Icons.fact_check_outlined,
              color: _info,
              text: 'Perlu verifikasi bukti transfer pelanggan',
            ),
          ],
          if (payment.canSettleToMitra) ...[
            const SizedBox(height: 10),
            _quickActionBanner(
              icon: Icons.priority_high,
              color: AppColors.primaryTeal,
              text: 'Siap ditransfer ke mitra',
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => _openPaymentDetail(payment),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Lihat Detail Pembayaran'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryTeal,
                side: const BorderSide(color: AppColors.primaryTeal),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: AppColors.sectionAltLight,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: AppColors.primaryTeal,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.grey500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
            color: AppColors.grey500,
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.grey600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.grey900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileMoneyRow(
    String label,
    String value, {
    bool isBold = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.grey600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? AppColors.darkTeal : AppColors.grey900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionBanner({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status),
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              _getStatusLabel(status),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAGINATION UI
  // ============================================================

  Widget _buildPagination() {
    final total = _filteredPayments.length;
    if (total == 0) return const SizedBox.shrink();

    final totalPages = _totalPages;
    final startItem = (_currentPage - 1) * _itemsPerPage + 1;
    final endItem = (startItem + _itemsPerPage - 1).clamp(0, total);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        final itemsPerPageDropdown = Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.grey200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _itemsPerPage,
              isDense: true,
              borderRadius: BorderRadius.circular(8),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.grey700,
                fontWeight: FontWeight.w600,
              ),
              items: _itemsPerPageOptions.map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value / hal'),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _itemsPerPage = value;
                  _currentPage = 1;
                });
              },
            ),
          ),
        );

        final navigationButtons = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              color: AppColors.primaryTeal,
              onPressed: _currentPage > 1
                  ? () => setState(() => _currentPage--)
                  : null,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.grey50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.grey200),
                ),
              ),
            ),
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.lightMint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Hal $_currentPage / $totalPages',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkTeal,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              color: AppColors.primaryTeal,
              onPressed: _currentPage < totalPages
                  ? () => setState(() => _currentPage++)
                  : null,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.grey50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.grey200),
                ),
              ),
            ),
          ],
        );

        return Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.sectionLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.grey200),
          ),
          child: isMobile
              ? Column(
                  children: [
                    Text(
                      'Menampilkan $startItem–$endItem dari $total pembayaran',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        itemsPerPageDropdown,
                        navigationButtons,
                      ],
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Menampilkan $startItem–$endItem dari $total pembayaran',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.grey600,
                      ),
                    ),
                    Row(
                      children: [
                        itemsPerPageDropdown,
                        const SizedBox(width: 16),
                        navigationButtons,
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }

  // ============================================================
  // ERROR & EMPTY
  // ============================================================

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 45,
      ),
      decoration: BoxDecoration(
        color: AppColors.sectionLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _dangerBorder),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: _danger,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _danger,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 45,
      ),
      decoration: BoxDecoration(
        color: AppColors.sectionLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey200),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 52,
            color: AppColors.grey400,
          ),
          SizedBox(height: 12),
          Text(
            'Tidak ada data pembayaran.',
            style: TextStyle(
              color: AppColors.grey500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}