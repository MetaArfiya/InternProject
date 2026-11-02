import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as xl;
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../models/payment_model.dart';
import '../../../models/payment_summary_model.dart';
import '../../../models/payment_detail_model.dart';
import '../../../services/api_service.dart';
import '../../../services/payment_service.dart';
import '../../../sections/customer/payment_detail_dialog.dart' as customer;
import '../../../sections/partner/payment_detail_dialog.dart' as partner;
import '../../../theme/app_colors.dart';

class PaymentScreen extends StatefulWidget {
  final String role;

  const PaymentScreen({super.key, required this.role});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  List<PaymentModel> _payments = [];
  PaymentSummary? _summary;

  String _selectedStatus = 'Semua';
  DateTimeRange? _dateRange;

  bool _isExporting = false;

  int _currentPage = 1;
  int _rowsPerPage = 10;
  static const List<int> _rowsPerPageOptions = [10, 25, 50, 100];

  // ============================================================
  // DESIGN TOKENS
  // ============================================================
  static const Color _accent = AppColors.primaryTeal;
  static const Color _tableBorder = Color(0xFFE5E7EB);
  static const Color _tableDivider = Color(0xFFF3F4F6);
  static const Color _headerText = AppColors.grey500;
  static const Color _cellText = AppColors.grey900;

  static const double _gapAfterHeader = 16;
  static const double _gapBetweenSections = 16;
  static const double _gapTitleToContent = 16;

  bool get _isMitra => widget.role.toLowerCase() == 'mitra';

  List<String> get _filterOptions => [
    'Semua',
    'Menunggu Pembayaran',
    'Ditahan (Escrow)',
    'Selesai',
  ];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  // ============================================================
  // FILTER & PAGINATION LOGIC
  // ============================================================
  List<PaymentModel> get _filteredPayments {
    return _payments.where((p) {
      bool statusMatch = true;
      if (_selectedStatus == 'Menunggu Pembayaran') {
        statusMatch = p.status == 'pending';
      } else if (_selectedStatus == 'Ditahan (Escrow)') {
        statusMatch = p.status == 'held';
      } else if (_selectedStatus == 'Selesai') {
        statusMatch = p.status == 'released' || p.status == 'settled';
      }

      bool dateMatch = true;
      if (_dateRange != null && p.createdAt != null) {
        final paymentDate = p.createdAt!;
        final start = DateTime(
          _dateRange!.start.year,
          _dateRange!.start.month,
          _dateRange!.start.day,
        );
        final end = DateTime(
          _dateRange!.end.year,
          _dateRange!.end.month,
          _dateRange!.end.day,
          23,
          59,
          59,
        );
        dateMatch = paymentDate.isAfter(start) && paymentDate.isBefore(end);
      }

      return statusMatch && dateMatch;
    }).toList();
  }

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
  // HELPER LABEL STATUS
  // ============================================================
  String _getCleanStatusLabel(PaymentModel p) {
    if (p.status == 'pending') return 'Menunggu Pembayaran';
    if (p.status == 'held') {
      return 'Ditahan (Escrow)';
    }
    if (p.status == 'released' || p.status == 'settled') return 'Selesai';
    if (p.status == 'refunded') return 'Dikembalikan';
    if (p.status == 'failed') return 'Gagal';
    return p.statusLabel.isNotEmpty ? p.statusLabel : p.status;
  }

  // ============================================================
  // LOAD DATA
  // ============================================================
  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
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
  // DATE PICKER OVERLAY
  // ============================================================
  Future<void> _pickDateRange() async {
    final now = DateTime.now();

    DateTime tempStart =
        _dateRange?.start ?? now.subtract(const Duration(days: 7));
    DateTime tempEnd = _dateRange?.end ?? now;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Pilih Rentang Tanggal',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              content: SizedBox(
                width: 380,
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min, // <-- KUNCI AGAR TIDAK MEMANJANG
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tanggal Mulai
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tempStart,
                            firstDate: DateTime(now.year - 5),
                            lastDate: tempEnd,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: AppColors.primaryTeal,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setDialogState(() => tempStart = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.grey50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.grey300),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize
                                .min, // <-- KUNCI AGAR TIDAK MEMANJANG
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mulai',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.grey500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${tempStart.day.toString().padLeft(2, '0')}/${tempStart.month.toString().padLeft(2, '0')}/${tempStart.year}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.grey900,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Tanggal Selesai
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tempEnd,
                            firstDate: tempStart,
                            lastDate: now,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: AppColors.primaryTeal,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setDialogState(() => tempEnd = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.grey50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.grey300),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize
                                .min, // <-- KUNCI AGAR TIDAK MEMANJANG
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selesai',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.grey500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${tempEnd.day.toString().padLeft(2, '0')}/${tempEnd.month.toString().padLeft(2, '0')}/${tempEnd.year}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.grey900,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      color: AppColors.grey600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _dateRange = DateTimeRange(
                        start: tempStart,
                        end: tempEnd,
                      );
                      _currentPage = 1;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Terapkan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _clearDateRange() {
    setState(() {
      _dateRange = null;
      _currentPage = 1;
    });
  }

  // ============================================================
  // EXPORT EXCEL (MITRA)
  // ============================================================
  Future<void> _exportMitraExcel() async {
    if (_filteredPayments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak ada data untuk diexport pada rentang tanggal ini.',
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final excel = xl.Excel.createExcel();

      // Gunakan sheet default agar data langsung muncul
      // ketika file Excel dibuka.
      final sheetObject = excel['Riwayat_Pendapatan'];

      // Isi header
      sheetObject.appendRow([
        xl.TextCellValue('ID'),
        xl.TextCellValue('Tanggal'),
        xl.TextCellValue('Pekerjaan'),
        xl.TextCellValue('Pelanggan'),
        xl.TextCellValue('Pendapatan Bersih (Rp)'),
        xl.TextCellValue('Status'),
      ]);

      // Isi data transaksi
      for (final p in _filteredPayments) {
        sheetObject.appendRow([
          xl.TextCellValue('#PAY-${p.id}'),
          xl.TextCellValue(p.formattedDate),
          xl.TextCellValue(p.jobTitle ?? '-'),
          xl.TextCellValue(p.pelangganName ?? '-'),
          xl.DoubleCellValue(p.mitraEarning.toDouble()),
          xl.TextCellValue(_getCleanStatusLabel(p)),
        ]);
      }

      // Jadikan sheet laporan sebagai sheet default
      excel.setDefaultSheet('Riwayat_Pendapatan');

      final fileName =
          'Laporan_Pendapatan_Mitra_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      if (kIsWeb) {
        excel.save(fileName: fileName);
      } else {
        final bytes = excel.save();

        if (bytes == null) {
          throw Exception('Gagal membuat file Excel.');
        }

        final fileBytes = Uint8List.fromList(bytes);

        final params = ShareParams(
          files: [
            XFile.fromData(
              fileBytes,
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ),
          ],
          fileNameOverrides: [fileName],
          text: 'Laporan Pendapatan Mitra',
        );

        await SharePlus.instance.share(params);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan Excel berhasil dibuat.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal export Excel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ============================================================
  // EXPORT PDF (PELANGGAN)
  // ============================================================
  Future<void> _exportPelangganPdf() async {
    if (_filteredPayments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak ada data untuk diexport pada rentang tanggal ini.',
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => [
            pw.Header(level: 0, text: 'Riwayat Pembayaran - Sayabantu'),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: [
                'Tanggal',
                'Pekerjaan',
                'Mitra',
                'Total (Rp)',
                'Status',
              ],
              data: _filteredPayments
                  .map(
                    (p) => [
                      p.formattedDate,
                      p.jobTitle ?? '-',
                      p.mitraName ?? '-',
                      p.totalPaid.toStringAsFixed(0),
                      _getCleanStatusLabel(p),
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(8),
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      final fileName =
          'Riwayat_Pembayaran_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // ============================================================
      // PRINT PREVIEW DULU (semua platform)
      // Di dialog print, user bisa pilih "Save as PDF" untuk download.
      // ============================================================
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: fileName,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal export PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
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
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: _accent)),
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

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => customer.PaymentDetailDialog(detail: detail),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sectionAltLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPayments,
          color: _accent,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isMobile = width < 700;
              final isTablet = width >= 700 && width < 1100;

              final horizontalPadding = isMobile
                  ? 16.0
                  : (isTablet ? 24.0 : 28.0);
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
  // HEADER
  // ============================================================
  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pembayaran',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.grey900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isMitra
              ? 'Lihat riwayat pendapatan dari pekerjaan yang telah selesai.'
              : 'Lihat riwayat transaksi dan status escrow pekerjaan Anda.',
          style: const TextStyle(fontSize: 13, color: AppColors.grey500),
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
      cards.add(
        _SummaryData(
          title: 'Total Pendapatan',
          shortTitle: 'Pendapatan',
          value: PaymentModel.formatRupiah(s.totalMitraEarning),
          icon: Icons.account_balance_wallet_outlined,
          color: const Color(0xFF16A34A),
        ),
      );
      cards.add(
        _SummaryData(
          title: 'Sedang Ditahan',
          shortTitle: 'Escrow',
          value: PaymentModel.formatRupiah(s.totalPending),
          icon: Icons.hourglass_top,
          color: _accent,
        ),
      );
      cards.add(
        _SummaryData(
          title: 'Transaksi',
          shortTitle: 'Transaksi',
          value: '${s.totalTransaksi}',
          icon: Icons.receipt_long_outlined,
          color: const Color(0xFF2563EB),
        ),
      );
    } else {
      cards.add(
        _SummaryData(
          title: 'Total Pembayaran',
          shortTitle: 'Total',
          value: PaymentModel.formatRupiah(s.totalPembayaran),
          icon: Icons.account_balance_wallet_outlined,
          color: const Color(0xFF2563EB),
        ),
      );
      cards.add(
        _SummaryData(
          title: 'Transaksi',
          shortTitle: 'Transaksi',
          value: '${s.totalTransaksi}',
          icon: Icons.receipt_long_outlined,
          color: _accent,
        ),
      );
      cards.add(
        _SummaryData(
          title: 'Saldo Ditahan',
          shortTitle: 'Escrow',
          value: PaymentModel.formatRupiah(s.totalKomisi),
          icon: Icons.lock_outline,
          color: const Color(0xFF16A34A),
        ),
      );
    }

    final gap = isMobile ? 8.0 : 16.0;

    return SizedBox(
      height: isMobile ? 118 : 128,
      child: Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            Expanded(child: _buildSummaryCard(cards[i], isCompact: isMobile)),
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.10),
        ),
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
              color: data.color.withValues(alpha: 0.12),
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
              color: AppColors.grey900,
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
              color: AppColors.grey500,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _tableBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 18, color: AppColors.grey500),
          const SizedBox(width: 8),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.grey50,
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
                    color: AppColors.grey500,
                  ),
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey900,
                  fontSize: 13,
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: _pickDateRange,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _tableBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: AppColors.grey600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _dateRange == null
                            ? 'Pilih Tanggal'
                            : '${_dateRange!.start.day}/${_dateRange!.start.month}/${_dateRange!.start.year} - ${_dateRange!.end.day}/${_dateRange!.end.month}/${_dateRange!.end.year}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.grey900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_dateRange != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: _clearDateRange,
                  icon: const Icon(Icons.close, size: 16, color: Colors.red),
                  tooltip: 'Hapus Filter Tanggal',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
              ],
            ],
          ),
          const SizedBox(width: 12),
          if (_isExporting)
            const SizedBox(
              width: 80,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_isMitra)
            ElevatedButton.icon(
              onPressed: _exportMitraExcel,
              icon: const Icon(Icons.file_download_outlined, size: 16),
              label: const Text('Excel', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _exportPelangganPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
              label: const Text('PDF', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_filteredPayments.length} Data',
              style: const TextStyle(
                color: _accent,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LIST & TABEL WIDGETS
  // ============================================================
  Widget _buildListTitle(BuildContext context) {
    return Text(
      _isMitra ? 'Riwayat Pendapatan' : 'Riwayat Pembayaran',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.grey900,
      ),
    );
  }

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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.10),
        ),
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
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long, color: _accent, size: 20),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _cellText,
                        fontSize: 13.5,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isMitra
                          ? 'Pelanggan: ${p.pelangganName ?? "-"}'
                          : 'Mitra: ${p.mitraName ?? "-"}',
                      style: const TextStyle(
                        color: AppColors.grey600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.formattedDate,
                      style: const TextStyle(
                        color: AppColors.grey400,
                        fontSize: 11,
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
          _detailRow('Nilai pekerjaan', PaymentModel.formatRupiah(p.jobAmount)),
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openPaymentDetail(p),
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text(
                'Lihat Detail',
                style: TextStyle(fontSize: 12.5),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _accent,
                side: BorderSide(color: _accent.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebTable(BuildContext context) {
    final rows = _pagedPayments;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 820;

        return Table(
          columnWidths: {
            0: const FlexColumnWidth(3.2), // Pekerjaan
            1: const FlexColumnWidth(2.4), // Mitra/Pelanggan
            2: const FlexColumnWidth(1.6), // Tanggal
            3: const FlexColumnWidth(2.2), // Total/Pendapatan
            4: const FlexColumnWidth(2.0), // Status
            5: FixedColumnWidth(compact ? 52 : 84), // Aksi
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              children: [
                _headerCell(context, 'Pekerjaan', compact),
                _headerCell(context, _isMitra ? 'Pelanggan' : 'Mitra', compact),
                _headerCell(context, 'Tanggal', compact),
                _headerCell(
                  context,
                  _isMitra ? 'Pendapatan' : 'Total',
                  compact,
                ),
                _headerCell(context, 'Status', compact),
                _headerCell(context, 'Aksi', compact),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _headerCell(BuildContext context, String text, bool compact) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: _headerText,
          fontSize: compact ? 11.5 : 13,
        ),
      ),
    );
  }

  Widget _buildTableDataRow(BuildContext context, PaymentModel p) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 820;

        return Table(
          columnWidths: {
            0: const FlexColumnWidth(3.2),
            1: const FlexColumnWidth(2.4),
            2: const FlexColumnWidth(1.6),
            3: const FlexColumnWidth(2.2),
            4: const FlexColumnWidth(2.0),
            5: FixedColumnWidth(compact ? 52 : 84),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              children: [
                // Pekerjaan + ID
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: compact ? 32 : 38,
                        height: compact ? 32 : 38,
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.receipt_long,
                          color: _accent,
                          size: compact ? 15 : 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              p.jobTitle ?? 'Pekerjaan',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _cellText,
                                fontSize: compact ? 12 : 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '#PAY-${p.id.toString().padLeft(3, '0')}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.grey400,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Nama
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Text(
                    _isMitra ? (p.pelangganName ?? '-') : (p.mitraName ?? '-'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _cellText,
                      height: 1.25,
                      fontSize: compact ? 12 : 13,
                    ),
                  ),
                ),
                // Tanggal
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Text(
                    p.formattedDate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _cellText,
                      fontSize: compact ? 11.5 : 13,
                    ),
                  ),
                ),
                // Total
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Text(
                    PaymentModel.formatRupiah(
                      _isMitra ? p.mitraEarning : p.totalPaid,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _isMitra ? const Color(0xFF16A34A) : _accent,
                      fontSize: compact ? 12 : 13,
                    ),
                  ),
                ),
                // Status
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _statusBadge(context, p),
                  ),
                ),
                // Aksi
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: compact
                        ? Material(
                            color: AppColors.grey100,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              onTap: () => _openPaymentDetail(p),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(7),
                                child: Icon(
                                  Icons.visibility_outlined,
                                  size: 15,
                                  color: AppColors.grey700,
                                ),
                              ),
                            ),
                          )
                        : _pillButton(
                            context: context,
                            icon: Icons.visibility_outlined,
                            label: 'Detail',
                            bgColor: AppColors.grey100,
                            fgColor: AppColors.grey700,
                            onTap: () => _openPaymentDetail(p),
                          ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
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
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                  fontSize: 11,
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
            style: const TextStyle(color: _headerText, fontSize: 12),
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
        color: AppColors.white,
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
              color: AppColors.grey500,
            ),
          ),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.grey900,
            fontSize: 12,
          ),
          items: _rowsPerPageOptions
              .map(
                (value) => DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value / hal'),
                ),
              )
              .toList(),
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
      color: AppColors.white,
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
              color: enabled ? AppColors.grey300 : AppColors.grey200,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.grey700 : AppColors.grey300,
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
        color: AppColors.mint.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Hal $_currentPage / $_totalPages',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.primaryTeal,
          fontSize: 12,
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================
  Widget _statusBadge(BuildContext context, PaymentModel p) {
    final color = _statusColor(p.status);
    final label = _getCleanStatusLabel(p);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'released':
      case 'settled':
        return const Color(0xFF16A34A);
      case 'held':
        return const Color(0xFF2563EB);
      case 'pending':
        return _accent;
      case 'refunded':
      case 'failed':
        return const Color(0xFFDC2626);
      default:
        return AppColors.grey500;
    }
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
          style: const TextStyle(color: AppColors.grey600, fontSize: 12.5),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              fontSize: isBold ? 14 : 13,
              color: valueColor ?? AppColors.grey900,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ERROR & EMPTY STATE
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
    final isFiltered = _selectedStatus != 'Semua' || _dateRange != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFiltered ? Icons.filter_alt_off : Icons.receipt_long_outlined,
              size: 34,
              color: _accent.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isFiltered
                ? 'Tidak ada pembayaran dengan filter yang dipilih.'
                : (_isMitra
                      ? 'Belum ada pendapatan.'
                      : 'Belum ada transaksi pembayaran.'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.grey600, fontSize: 13),
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
