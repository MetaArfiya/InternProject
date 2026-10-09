import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../models/payment_model.dart';
import '../../../models/payment_summary_model.dart';
import '../../../models/payment_detail_model.dart';
import '../../../services/api_service.dart';
import '../../../services/payment_service.dart';
import '../../../sections/customer/payment_detail_dialog.dart' as customer;
import '../../../sections/partner/payment_detail_dialog.dart' as partner;
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

  String _selectedStatus = 'Semua';
  final Map<int, Map<String, dynamic>?> _ratingCache = {};

  // Pagination (web tabel)
  int _currentPage = 1;
  int _rowsPerPage = 10;
  static const List<int> _rowsPerPageOptions = [10, 25, 50, 100];

  // ============================================================
  // DESIGN TOKENS — disamakan dengan DashboardHeader
  // ============================================================

  static const Color _accent = Color(0xFFF97316);
  static const Color _tableBorder = Color(0xFFE5E7EB);
  static const Color _tableDivider = Color(0xFFF3F4F6);
  static const Color _headerText = Color(0xFF6B7280);
  static const Color _cellText = Color(0xFF111827);
  static const double _buttonRadius = 12;

  // Spacing — mengikuti pola DashboardHeader
  static const double _gapAfterHeader = 16;
  static const double _gapBetweenSections = 16;
  static const double _gapTitleToContent = 16;

  bool get _isMitra => widget.role.toLowerCase() == 'mitra';

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
  // FILTER
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
  // PAGINATION
  // ============================================================

  int get _totalPages {
    if (_filteredPayments.isEmpty) return 1;
    return (_filteredPayments.length / _rowsPerPage).ceil();
  }

  List<PaymentModel> get _pagedPayments {
    final list = _filteredPayments;
    final start = (_currentPage - 1) * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, list.length);
    if (start >= list.length) return [];
    return list.sublist(start, end);
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() => _currentPage = page);
  }

  void _changeRowsPerPage(int value) {
    setState(() {
      _rowsPerPage = value;
      _currentPage = 1;
    });
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _ratingCache.clear();
      _currentPage = 1;
    });

    try {
      final endpoint = _isMitra ? '/mitra/earnings' : '/pelanggan/payments';
      final response = await ApiService.get(endpoint);

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
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  // ============================================================
  // OPEN DETAIL
  // ============================================================

  Future<void> _openPaymentDetail(PaymentModel p) async {
    if (_isMitra) {
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => partner.PaymentDetailMitraDialog(payment: p),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: _accent),
      ),
    );

    final detailData = await PaymentService.getPelangganPaymentDetail(p.id);

    if (!mounted) return;
    Navigator.pop(context);

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
      builder: (_) => customer.PaymentDetailDialog(detail: detail),
    );

    if (result == true && mounted) {
      _loadPayments();
    }
  }

  // ============================================================
  // RATING
  // ============================================================

  Future<Map<String, dynamic>?> _checkRating(int jobId) async {
    if (_ratingCache.containsKey(jobId)) return _ratingCache[jobId];
    final result = await PaymentService.checkJobRating(jobId);
    _ratingCache[jobId] = result;
    return result;
  }

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
  // ✅ Padding horizontal disamakan dengan CustomerDashboard
  //    mobile 16 / tablet 24 / desktop 28  (bukan 32)
  // ✅ TIDAK ada `Center` + `ConstrainedBox` — konten nempel kiri
  //    biar jarak dari sidebar sama dengan halaman lain
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPayments,
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
                    else if (_errorMessage != null)
                      _buildErrorState(context)
                    else ...[
                      _buildSummary(isMobile),
                      const SizedBox(height: _gapBetweenSections),
                      _buildFilterBar(context, isMobile),
                      const SizedBox(height: _gapBetweenSections),
                      _buildListTitle(context),
                      const SizedBox(height: _gapTitleToContent),

                      if (_filteredPayments.isEmpty)
                        _buildEmptyState(context)
                      else if (isMobile)
                        _buildMobileList(context)
                      else
                        _buildWebTable(context),
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
          _isMitra
              ? 'Lihat riwayat pendapatan dari pekerjaan yang telah selesai.'
              : 'Lihat riwayat transaksi dan pembayaran pekerjaan.',
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary(bool isMobile) {
    final s = _summary;
    if (s == null) return const SizedBox.shrink();

    final cards = <_SummaryData>[];

    if (_isMitra) {
      cards.add(_SummaryData(
        title: 'Total Pendapatan',
        shortTitle: 'Pendapatan',
        value: PaymentModel.formatRupiah(s.totalMitraEarning),
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF16A34A),
      ));
      cards.add(_SummaryData(
        title: 'Menunggu Cair',
        shortTitle: 'Pending',
        value: PaymentModel.formatRupiah(s.totalPending),
        icon: Icons.hourglass_top,
        color: _accent,
      ));
      cards.add(_SummaryData(
        title: 'Transaksi',
        shortTitle: 'Transaksi',
        value: '${s.totalTransaksi}',
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF2563EB),
      ));
    } else {
      cards.add(_SummaryData(
        title: 'Total Pembayaran',
        shortTitle: 'Total',
        value: PaymentModel.formatRupiah(s.totalPembayaran),
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF2563EB),
      ));
      cards.add(_SummaryData(
        title: 'Transaksi',
        shortTitle: 'Transaksi',
        value: '${s.totalTransaksi}',
        icon: Icons.receipt_long_outlined,
        color: _accent,
      ));
      cards.add(_SummaryData(
        title: 'Komisi Aplikasi',
        shortTitle: 'Komisi',
        value: PaymentModel.formatRupiah(s.totalKomisi),
        icon: Icons.percent,
        color: const Color(0xFF16A34A),
      ));
    }

    final gap = isMobile ? 8.0 : 16.0;

    return SizedBox(
      height: isMobile ? 118 : 128,
      child: Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            Expanded(
              child: _buildSummaryCard(
                cards[i],
                isCompact: isMobile,
              ),
            ),
            if (i != cards.length - 1) SizedBox(width: gap),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(_SummaryData data, {required bool isCompact}) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isCompact ? 30 : 36,
            height: isCompact ? 30 : 36,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(isCompact ? 8 : 10),
            ),
            child: Icon(
              data.icon,
              color: data.color,
              size: isCompact ? 16 : 20,
            ),
          ),
          SizedBox(height: isCompact ? 6 : 8),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isCompact ? 13.5 : 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              height: 1.1,
            ),
          ),
          SizedBox(height: isCompact ? 2 : 3),
          Text(
            isCompact ? data.shortTitle : data.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isCompact ? 9.5 : 12,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER BAR
  // ============================================================

  Widget _buildFilterBar(BuildContext context, bool isMobile) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_buttonRadius),
        border: Border.all(color: _tableBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 18, color: Color(0xFF6B7280)),
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
                    color: Color(0xFF6B7280),
                  ),
                ),
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF111827),
                ),
                items: _filterOptions.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
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
              color: _accent.withOpacity(0.1),
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
  // LIST TITLE — sama persis dgn judul "Pembayaran" (tanpa bar)
  // ============================================================

  Widget _buildListTitle(BuildContext context) {
    return Text(
      _isMitra ? 'Riwayat Pendapatan' : 'Riwayat Pembayaran',
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  // ============================================================
  // MOBILE — LIST CARD
  // ============================================================

  Widget _buildMobileList(BuildContext context) {
    return Column(
      children: _filteredPayments.map((p) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMobilePaymentCard(context, p),
        );
      }).toList(),
    );
  }

  Widget _buildMobilePaymentCard(BuildContext context, PaymentModel p) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _tableBorder),
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
                  color: _accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long,
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
                      p.jobTitle ?? 'Pekerjaan',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _cellText,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isMitra
                          ? 'Pelanggan: ${p.pelangganName ?? "-"}'
                          : 'Mitra: ${p.mitraName ?? "-"}',
                      style: textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.formattedDate,
                      style: textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(context, p),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _tableDivider),
          const SizedBox(height: 12),

          _detailRow(
            'Nilai pekerjaan',
            PaymentModel.formatRupiah(p.jobAmount),
          ),
          const SizedBox(height: 8),

          if (_isMitra) ...[
            _detailRow(
              'Komisi (${p.commissionPercent.toStringAsFixed(0)}%)',
              '- ${PaymentModel.formatRupiah(p.commissionAmount)}',
            ),
            const SizedBox(height: 8),
            _detailRow(
              'Pendapatan',
              PaymentModel.formatRupiah(p.mitraEarning),
              isBold: true,
              valueColor: const Color(0xFF16A34A),
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
              valueColor: _accent,
            ),
          ],

          if (p.customerProofUploadedAt != null) ...[
            const SizedBox(height: 12),
            _buildUploadInfo(
              icon: Icons.upload_file,
              color: const Color(0xFF2563EB),
              label: 'Bukti diupload',
              date: p.customerProofUploadedAt!,
            ),
          ],
          if (p.mitraProofUploadedAt != null) ...[
            const SizedBox(height: 8),
            _buildUploadInfo(
              icon: Icons.check_circle_outline,
              color: const Color(0xFF16A34A),
              label: 'Dana ditransfer',
              date: p.mitraProofUploadedAt!,
            ),
          ],

          ..._buildActionButtonsMobile(context, p),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtonsMobile(
    BuildContext context,
    PaymentModel p,
  ) {
    final widgets = <Widget>[];

    if (!_isMitra && p.canUploadCustomerProof) {
      widgets.add(const SizedBox(height: 14));
      widgets.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _openPaymentDetail(p),
            icon: const Icon(Icons.upload_file, size: 16),
            label: const Text(
              'Bayar & Upload Bukti',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 42),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      );
    }

    widgets.addAll(_buildStatusInfoBlock(context, p));

    if (!_isMitra && p.customerProofUploadedAt != null) {
      widgets.add(const SizedBox(height: 12));
      widgets.add(
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _accent,
                    ),
                  ),
                ),
              );
            }
            return _buildRatingSection(context, p, snapshot.data);
          },
        ),
      );
    }

    widgets.add(const SizedBox(height: 6));
    widgets.add(
      TextButton.icon(
        onPressed: () => _openPaymentDetail(p),
        icon: const Icon(Icons.visibility_outlined, size: 15),
        label: const Text(
          'Lihat Detail',
          style: TextStyle(fontSize: 12.5),
        ),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF7C3AED),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );

    return widgets;
  }

  // ============================================================
  // WEB — TABEL
  // ============================================================

  Widget _buildWebTable(BuildContext context) {
    final rows = _pagedPayments;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _tableBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTableHeaderRow(context),
          const Divider(height: 1, thickness: 1, color: _tableDivider),

          for (int i = 0; i < rows.length; i++) ...[
            _buildTableDataRow(context, rows[i]),
            if (i != rows.length - 1)
              const Divider(height: 1, thickness: 1, color: _tableDivider),
          ],

          const Divider(height: 1, thickness: 1, color: _tableDivider),
          _buildTableFooter(context),
        ],
      ),
    );
  }

  Widget _buildTableHeaderRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(flex: 4, child: _headerCell(context, 'Pekerjaan')),
          Expanded(
            flex: 3,
            child: _headerCell(context, _isMitra ? 'Pelanggan' : 'Mitra'),
          ),
          Expanded(flex: 2, child: _headerCell(context, 'Tanggal')),
          Expanded(
            flex: 3,
            child: _headerCell(context, _isMitra ? 'Pendapatan' : 'Total'),
          ),
          Expanded(flex: 3, child: _headerCell(context, 'Status')),
          Expanded(flex: 4, child: _headerCell(context, 'Aksi')),
        ],
      ),
    );
  }

  Widget _headerCell(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: _headerText,
          ),
    );
  }

  Widget _buildTableDataRow(BuildContext context, PaymentModel p) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: _accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        p.jobTitle ?? 'Pekerjaan',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _cellText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '#PAY-${p.id.toString().padLeft(3, '0')}',
                        style: textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 3,
            child: Text(
              _isMitra
                  ? (p.pelangganName ?? '-')
                  : (p.mitraName ?? '-'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: _cellText,
                height: 1.3,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              p.formattedDate,
              style: textTheme.bodyMedium?.copyWith(color: _cellText),
            ),
          ),

          Expanded(
            flex: 3,
            child: Text(
              PaymentModel.formatRupiah(
                _isMitra ? p.mitraEarning : p.totalPaid,
              ),
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: _isMitra ? const Color(0xFF16A34A) : _accent,
              ),
            ),
          ),

          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _statusBadge(context, p),
            ),
          ),

          Expanded(
            flex: 4,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _pillButton(
                  context: context,
                  icon: Icons.visibility_outlined,
                  label: 'Detail',
                  bgColor: const Color(0xFFF1F5F9),
                  fgColor: const Color(0xFF334155),
                  onTap: () => _openPaymentDetail(p),
                ),

                if (!_isMitra && p.canUploadCustomerProof)
                  _pillButton(
                    context: context,
                    icon: Icons.upload_file,
                    label: 'Upload Bukti',
                    bgColor: _accent,
                    fgColor: Colors.white,
                    onTap: () => _openPaymentDetail(p),
                  ),

                if (!_isMitra &&
                    p.customerProofUploadedAt != null &&
                    p.isSettled)
                  _pillButton(
                    context: context,
                    icon: Icons.star_rate_rounded,
                    label: 'Beri Rating',
                    bgColor: const Color(0xFFD97706),
                    fgColor: Colors.white,
                    onTap: () => _showRatingDialog(p),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillButton({
    required BuildContext context,
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
  // TABLE FOOTER
  // ============================================================

  Widget _buildTableFooter(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = _filteredPayments.length;
    final start = total == 0 ? 0 : ((_currentPage - 1) * _rowsPerPage) + 1;
    final end = (_currentPage * _rowsPerPage).clamp(0, total);
    final canPrev = _currentPage > 1;
    final canNext = _currentPage < _totalPages;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text(
            'Menampilkan $start–$end dari $total pembayaran',
            style: textTheme.bodySmall?.copyWith(color: _headerText),
          ),
          const Spacer(),
          Row(
            children: [
              _buildRowsPerPageDropdown(context),
              const SizedBox(width: 12),
              _navButton(
                icon: Icons.chevron_left,
                enabled: canPrev,
                onTap: () => _goToPage(_currentPage - 1),
              ),
              const SizedBox(width: 8),
              _pageIndicator(context),
              const SizedBox(width: 8),
              _navButton(
                icon: Icons.chevron_right,
                enabled: canNext,
                onTap: () => _goToPage(_currentPage + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRowsPerPageDropdown(BuildContext context) {
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
          value: _rowsPerPage,
          isDense: true,
          icon: const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
          items: _rowsPerPageOptions.map((value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text('$value / hal'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) _changeRowsPerPage(value);
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

  Widget _pageIndicator(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Hal $_currentPage / $_totalPages',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7C3AED),
            ),
      ),
    );
  }

  // ============================================================
  // STATUS INFO BLOCK
  // ============================================================

  List<Widget> _buildStatusInfoBlock(
    BuildContext context,
    PaymentModel p,
  ) {
    if (!_isMitra) {
      if (p.isWaitingVerification) {
        return [
          const SizedBox(height: 12),
          _buildStatusInfo(
            icon: Icons.hourglass_top,
            color: const Color(0xFF7C3AED),
            message: 'Bukti transfer sedang diverifikasi admin.',
          ),
        ];
      }
      if (p.isPaid) {
        return [
          const SizedBox(height: 12),
          _buildStatusInfo(
            icon: Icons.sync,
            color: const Color(0xFF2563EB),
            message:
                'Pembayaran terverifikasi. Menunggu admin transfer ke mitra.',
          ),
        ];
      }
      if (p.isSettled) {
        return [
          const SizedBox(height: 12),
          _buildStatusInfo(
            icon: Icons.check_circle,
            color: const Color(0xFF16A34A),
            message: 'Pembayaran selesai. Dana sudah diteruskan ke mitra.',
          ),
        ];
      }
    } else {
      if (p.isPending || p.isWaitingVerification) {
        return [
          const SizedBox(height: 12),
          _buildStatusInfo(
            icon: Icons.hourglass_top,
            color: _accent,
            message: 'Menunggu pelanggan menyelesaikan pembayaran.',
          ),
        ];
      }
      if (p.isPaid) {
        return [
          const SizedBox(height: 12),
          _buildStatusInfo(
            icon: Icons.sync,
            color: const Color(0xFF2563EB),
            message:
                'Pembayaran sudah diverifikasi. Menunggu admin transfer ke rekening Anda.',
          ),
        ];
      }
      if (p.isSettled) {
        return [
          const SizedBox(height: 12),
          _buildStatusInfo(
            icon: Icons.check_circle,
            color: const Color(0xFF16A34A),
            message: 'Dana sudah ditransfer ke rekening Anda.',
          ),
        ];
      }
    }
    return [];
  }

  // ============================================================
  // UPLOAD INFO
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
                fontSize: 11.5,
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
  // RATING SECTION
  // ============================================================

  Widget _buildRatingSection(
    BuildContext context,
    PaymentModel p,
    Map<String, dynamic>? ratingStatus,
  ) {
    final hasRated = ratingStatus?['has_rating'] == true;
    final existingRating = ratingStatus?['data'];

    if (hasRated && existingRating is Map) {
      final stars = (existingRating['stars'] ?? 0).toInt();
      final comment = existingRating['comment']?.toString() ?? '';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 16),
                SizedBox(width: 6),
                Text(
                  'Anda sudah memberi rating',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF16A34A),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) {
                return Icon(
                  i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                  color: const Color(0xFFF59E0B),
                  size: 20,
                );
              }),
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '"$comment"',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF92400E),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showRatingDialog(p),
        icon: const Icon(Icons.star_rate_rounded, size: 16),
        label: const Text(
          'Beri Rating Mitra',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD97706),
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 42),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(BuildContext context, PaymentModel p) {
    final color = _statusColor(p.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        p.statusLabel,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'settled':
        return const Color(0xFF16A34A);
      case 'paid':
        return const Color(0xFF2563EB);
      case 'waiting_verification':
        return const Color(0xFF7C3AED);
      case 'pending':
        return _accent;
      case 'refunded':
      case 'failed':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  // ============================================================
  // STATUS INFO WIDGET
  // ============================================================

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
          Icon(icon, color: color, size: 18),
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

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(
    String title,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12.5,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              fontSize: isBold ? 14 : 13,
              color: valueColor ?? const Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ERROR & EMPTY
  // ============================================================

  Widget _buildErrorState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 48),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadPayments,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isFiltered = _selectedStatus != 'Semua';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
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
              isFiltered ? Icons.filter_alt_off : Icons.receipt_long_outlined,
              size: 34,
              color: _accent.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isFiltered
                ? 'Tidak ada pembayaran dengan status "$_selectedStatus".'
                : (_isMitra
                    ? 'Belum ada pendapatan.'
                    : 'Belum ada transaksi pembayaran.'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DATA HELPER
// ============================================================

class _SummaryData {
  final String title;
  final String shortTitle;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryData({
    required this.title,
    required this.shortTitle,
    required this.value,
    required this.icon,
    required this.color,
  });
}