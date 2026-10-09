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
  // ============================================================
  // DESIGN TOKENS — disamakan dgn DashboardHeader / PaymentScreen
  // ============================================================

  static const Color _accent = Color(0xFFF97316);
  static const Color _successColor = Color(0xFF16A34A);
  static const Color _dangerColor = Color(0xFFDC2626);
  static const Color _infoColor = Color(0xFF2563EB);
  static const Color _purpleColor = Color(0xFF7C3AED);

  static const Color _tableBorder = Color(0xFFE5E7EB);
  static const Color _tableDivider = Color(0xFFF3F4F6);
  static const Color _headerText = Color(0xFF6B7280);
  static const Color _cellText = Color(0xFF111827);
  static const Color _mutedText = Color(0xFF64748B);

  static const double _gapAfterHeader = 16;
  static const double _gapBetweenSections = 16;
  static const double _cardRadius = 14;
  static const double _radius = 10;

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
    if (_selectedStatus == 'Semua') return _payments;

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
          child: CircularProgressIndicator(color: _accent),
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
        Map<String, dynamic>.from(detailData['payment']),
      );

      Map<String, dynamic>? bankMap;

      if (detailData['transfer_to'] is Map) {
        bankMap = Map<String, dynamic>.from(detailData['transfer_to']);
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
        return AdminPaymentDetailDialog(payment: paymentToUse);
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
        return _successColor;
      case 'paid':
        return _infoColor;
      case 'waiting_verification':
        return _purpleColor;
      case 'pending':
        return _accent;
      case 'refunded':
      case 'failed':
        return _dangerColor;
      default:
        return _headerText;
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
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: _accent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 700;
            final isTablet = width >= 700 && width < 1100;

            final horizontalPadding =
                isMobile ? 16.0 : (isTablet ? 24.0 : 28.0);
            final verticalPadding = isMobile ? 16.0 : 28.0;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),

                  const SizedBox(height: _gapAfterHeader),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: CircularProgressIndicator(color: _accent),
                      ),
                    )
                  else if (_error != null)
                    _buildError()
                  else ...[
                    _buildSummarySection(isMobile),
                    const SizedBox(height: _gapBetweenSections),
                    _buildFilterSection(isMobile),
                    const SizedBox(height: _gapBetweenSections),

                    if (_filteredPayments.isEmpty)
                      _buildEmptyState()
                    else ...[
                      isMobile ? _buildMobileList() : _buildDesktopTable(),
                      _buildPagination(),
                    ],
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // HEADER — sama persis dgn DashboardHeader
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pembayaran',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kelola dan pantau seluruh transaksi pembayaran pelanggan dan mitra.',
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY SECTION (3 KOTAK SEJAJAR)
  // ============================================================

  Widget _buildSummarySection(bool isMobile) {
    final summary = _summary;

    final cards = [
      _summaryCard(
        title: 'Total Transaksi',
        value: PaymentModel.formatRupiah(summary?.totalPembayaran ?? 0),
        icon: Icons.account_balance_wallet_outlined,
        color: _infoColor,
      ),
      _summaryCard(
        title: 'Komisi Platform',
        value: PaymentModel.formatRupiah(summary?.totalKomisi ?? 0),
        icon: Icons.account_balance_outlined,
        color: _successColor,
      ),
      _summaryCard(
        title: 'Total ke Mitra',
        value: PaymentModel.formatRupiah(summary?.totalMitraEarning ?? 0),
        icon: Icons.handshake_outlined,
        color: _accent,
      ),
    ];

    final gap = isMobile ? 8.0 : 16.0;

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i != cards.length - 1) SizedBox(width: gap),
        ],
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _tableBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.1,
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
  // FILTER
  // ============================================================

  Widget _buildFilterSection(bool isMobile) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _tableBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 18, color: _headerText),
          const SizedBox(width: 8),
          if (!isMobile) ...[
            Text(
              'Filter Status:',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _tableBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStatus,
                isDense: true,
                icon: const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: _headerText,
                  ),
                ),
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: _cellText,
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
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_filteredPayments.length}',
              style: textTheme.labelMedium?.copyWith(
                color: _accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DESKTOP TABLE
  // ============================================================

  Widget _buildDesktopTable() {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _tableBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            horizontalMargin: 20,
            columnSpacing: 28,
            headingRowHeight: 52,
            dataRowMinHeight: 64,
            dataRowMaxHeight: 82,
            headingTextStyle: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: _headerText,
            ),
            headingRowColor:
                WidgetStateProperty.all(const Color(0xFFF9FAFB)),
            dividerThickness: 0.6,
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
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _cellText,
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
                        style: const TextStyle(
                          fontSize: 13,
                          color: _cellText,
                        ),
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
                        style: const TextStyle(
                          fontSize: 13,
                          color: _cellText,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      PaymentModel.formatRupiah(payment.jobAmount),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _cellText,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      PaymentModel.formatRupiah(payment.commissionAmount),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _successColor,
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
          color: _cellText,
        ),
      ),
    );
  }

  Widget _desktopAction(PaymentModel payment) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _pillButton(
          icon: Icons.visibility_outlined,
          label: 'Detail',
          bgColor: const Color(0xFFF1F5F9),
          fgColor: const Color(0xFF334155),
          onTap: () => _openPaymentDetail(payment),
        ),
        if (payment.canVerifyCustomerProof) ...[
          const SizedBox(width: 6),
          const Icon(
            Icons.fiber_new,
            color: _purpleColor,
            size: 18,
          ),
        ],
        if (payment.canSettleToMitra) ...[
          const SizedBox(width: 6),
          const Icon(
            Icons.priority_high,
            color: _infoColor,
            size: 18,
          ),
        ],
      ],
    );
  }

  Widget _pillButton({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color fgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: fgColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: fgColor,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE LIST
  // ============================================================

  Widget _buildMobileList() {
    return Column(
      children: _paginatedPayments.map((payment) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _mobilePaymentCard(payment),
        );
      }).toList(),
    );
  }

  Widget _mobilePaymentCard(PaymentModel payment) {
    final textTheme = Theme.of(context).textTheme;
    final reference = payment.referenceCode?.trim();

    final transactionId = reference != null && reference.isNotEmpty
        ? reference
        : 'PAY-${payment.id.toString().padLeft(3, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _tableBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: _accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transactionId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _cellText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      payment.formattedDate,
                      style: textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(payment.status),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: _tableDivider),
          const SizedBox(height: 12),

          // PEKERJAAN
          _mobileInfoRow(
            Icons.work_outline,
            'Pekerjaan',
            payment.jobTitle ?? '-',
          ),
          _mobileInfoRow(
            Icons.person_outline,
            'Pelanggan',
            payment.pelangganName ?? '-',
          ),
          _mobileInfoRow(
            Icons.handshake_outlined,
            'Mitra',
            payment.mitraName ?? '-',
            isLast: true,
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: _tableDivider),
          const SizedBox(height: 12),

          // MONEY
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
            valueColor: _successColor,
            isLast: true,
          ),

          // QUICK ACTION
          if (payment.canVerifyCustomerProof) ...[
            const SizedBox(height: 12),
            _quickActionBanner(
              icon: Icons.fact_check_outlined,
              color: _purpleColor,
              text: 'Perlu verifikasi bukti transfer pelanggan',
            ),
          ],
          if (payment.canSettleToMitra) ...[
            const SizedBox(height: 10),
            _quickActionBanner(
              icon: Icons.priority_high,
              color: _infoColor,
              text: 'Siap ditransfer ke mitra',
            ),
          ],

          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: () => _openPaymentDetail(payment),
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text(
                'Lihat Detail',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7C3AED),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
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
          Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 8),
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: _mutedText,
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
                fontWeight: FontWeight.w600,
                color: _cellText,
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
    Color? valueColor,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: _mutedText,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: isBold ? 14 : 12.5,
                fontWeight:
                    isBold ? FontWeight.w700 : FontWeight.w600,
                color: valueColor ?? _cellText,
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
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

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(String status) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(status), size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              _getStatusLabel(status),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  Widget _buildPagination() {
    final total = _filteredPayments.length;
    if (total == 0) return const SizedBox.shrink();

    final totalPages = _totalPages;
    final startItem = (_currentPage - 1) * _itemsPerPage + 1;
    final endItem = (startItem + _itemsPerPage - 1).clamp(0, total);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _tableBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              'Menampilkan $startItem–$endItem dari $total pembayaran',
              style: const TextStyle(
                fontSize: 12.5,
                color: _headerText,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRowsPerPageDropdown(),
              const SizedBox(width: 12),
              _navButton(
                icon: Icons.chevron_left,
                enabled: _currentPage > 1,
                onTap: () => setState(() => _currentPage--),
              ),
              const SizedBox(width: 8),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Hal $_currentPage / $totalPages',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _navButton(
                icon: Icons.chevron_right,
                enabled: _currentPage < totalPages,
                onTap: () => setState(() => _currentPage++),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRowsPerPageDropdown() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _tableBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _itemsPerPage,
          isDense: true,
          icon: const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: _headerText,
            ),
          ),
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: _cellText,
          ),
          items: _itemsPerPageOptions.map((value) {
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
  }

  Widget _navButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled
                  ? const Color(0xFFD1D5DB)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? const Color(0xFF374151)
                : const Color(0xFFD1D5DB),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR & EMPTY
  // ============================================================

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: _dangerColor,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _dangerColor,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_radius),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 34,
              color: _accent.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Tidak ada data pembayaran.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}