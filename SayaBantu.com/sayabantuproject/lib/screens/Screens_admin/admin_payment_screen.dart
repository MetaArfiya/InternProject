import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_saver/file_saver.dart';

import '../../models/payment_model.dart';
import '../../models/payment_summary_model.dart';
import '../../services/api_service.dart';
import '../../services/payment_service.dart';
import '../../sections/admin/admin_payment_detail_dialog.dart';
import '../../theme/admin_theme.dart';
import '../../theme/admin_theme_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/indonesia_time.dart';

class AdminPaymentScreen extends StatefulWidget {
  const AdminPaymentScreen({super.key});

  @override
  State<AdminPaymentScreen> createState() => _AdminPaymentScreenState();
}

class _AdminPaymentScreenState extends State<AdminPaymentScreen> {
  AdminTheme get theme => AdminThemeProvider.of(context);

  // ============================================================
  // TOKENS
  // ============================================================

  static const double _gapAfterHeader = 16;
  static const double _gapBetweenSections = 14;
  static const double _cardRadius = 14;
  static const double _radius = 10;
  static const double _mobileBreakpoint = 700;

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = true;
  String? _error;

  DateTimeRange? _selectedDateRange;

  bool _isExporting = false;

  List<PaymentModel> _payments = [];
  PaymentSummary? _summary;

  String _selectedStatus = 'Semua';

  final List<String> _statusOptions = [
    'Semua',
    'Menunggu Bayar (Pending)',
    'Ditahan (Escrow)',
    'Selesai (Released)',
    'Refund',
  ];

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
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String query = '';

      if (_selectedDateRange != null) {
        final start = _formatDateForApi(_selectedDateRange!.start);
        final end = _formatDateForApi(_selectedDateRange!.end);

        query = '?start_date=$start&end_date=$end';
      }

      final response = await ApiService.get(
        '/admin/payments$query',
      );

      debugPrint('ADMIN PAYMENTS: ${response.statusCode}');
      debugPrint('ADMIN PAYMENTS URL: /admin/payments$query');
      debugPrint('BODY: ${response.body}');

      if (response.statusCode != 200) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _error = 'Gagal memuat data (${response.statusCode})';
        });

        return;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _error = 'Format respons server tidak valid.';
        });

        return;
      }

      if (decoded['success'] != true) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _error = decoded['message']?.toString() ??
              'Gagal memuat pembayaran.';
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
    } catch (e, stackTrace) {
      debugPrint('ERROR ADMIN PAYMENT: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'Terjadi kesalahan: $e';
      });
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  String _formatDateForApi(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<void> _pickDateRange() async {
    DateTime startDate = _selectedDateRange?.start ?? DateTime.now();
    DateTime endDate = _selectedDateRange?.end ?? DateTime.now();

    final result = await showDialog<DateTimeRange>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 470),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Rentang Tanggal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF292524),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _dateInput(
                              label: 'Mulai',
                              date: startDate,
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: dialogContext,
                                  initialDate: startDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );

                                if (picked != null) {
                                  setDialogState(() {
                                    startDate = picked;

                                    if (endDate.isBefore(startDate)) {
                                      endDate = startDate;
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dateInput(
                              label: 'Selesai',
                              date: endDate,
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: dialogContext,
                                  initialDate: endDate,
                                  firstDate: startDate,
                                  lastDate: DateTime(2100),
                                );

                                if (picked != null) {
                                  setDialogState(() {
                                    endDate = picked;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                            },
                            child: const Text(
                              'Batal',
                              style: TextStyle(
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF087F73),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(
                                dialogContext,
                                DateTimeRange(
                                  start: startDate,
                                  end: endDate,
                                ),
                              );
                            },
                            child: const Text(
                              'Terapkan',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedDateRange = result;
        _currentPage = 1;
      });

      await _loadData();
    }
  }

  Widget _dateInput({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    final t = theme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: t.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 17,
              color: t.accent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: t.mutedText,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatDate(date),
                    style: TextStyle(
                      color: t.cellText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit_calendar_outlined,
              size: 17,
              color: t.mutedText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeButton({bool fullWidth = false}) {
    final t = theme;
    final selected = _selectedDateRange != null;

    final label = selected
        ? '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}'
        : 'Pilih Tanggal';

    return SizedBox(
      height: 38,
      width: fullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: (_isLoading || _isExporting)
            ? null
            : selected
                ? () async {
                    setState(() {
                      _selectedDateRange = null;
                      _currentPage = 1;
                    });
                    await _loadData();
                  }
                : _pickDateRange,
        style: OutlinedButton.styleFrom(
          foregroundColor: t.cellText,
          disabledForegroundColor: t.mutedText,
          side: BorderSide(color: t.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment:
              fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Icon(Icons.close, size: 14, color: t.danger),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton({
    bool fullWidth = false,
  }) {
    return SizedBox(
      height: 40,
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: _isLoading ||
                _isExporting ||
                _filteredPayments.isEmpty
            ? null
            : _exportExcel,
        icon: _isExporting
            ? const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : const Icon(
                Icons.file_download_outlined,
                size: 17,
              ),
        label: Text(
          _isExporting ? 'Mengekspor...' : 'Export Excel',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.accent,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.grey300,
          disabledForegroundColor: AppColors.grey600,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentCount() {
    final t = theme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: t.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${_filteredPayments.length} Data',
        style: TextStyle(
          fontSize: 12,
          color: t.accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // FILTER & PAGINATION
  // ============================================================

  List<PaymentModel> get _filteredPayments {
    if (_selectedStatus == 'Semua') {
      return _payments;
    }

    String? targetStatus;

    switch (_selectedStatus) {
      case 'Menunggu Bayar (Pending)':
        targetStatus = 'pending';
        break;

      case 'Ditahan (Escrow)':
        targetStatus = 'held';
        break;

      case 'Selesai (Released)':
        targetStatus = 'released';
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

    if (filtered.isEmpty) {
      return [];
    }

    final start = (_currentPage - 1) * _itemsPerPage;

    if (start >= filtered.length) {
      return [];
    }

    final end = (start + _itemsPerPage).clamp(0, filtered.length);

    return filtered.sublist(start, end);
  }

  int get _totalPages {
    final total = _filteredPayments.length;

    if (total == 0) {
      return 1;
    }

    return ((total - 1) ~/ _itemsPerPage) + 1;
  }

  Future<void> _exportExcel() async {
    final paymentsToExport = List<PaymentModel>.from(_filteredPayments);

    if (paymentsToExport.isEmpty || _isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final excel = Excel.createExcel();
      final sheet = excel['Data Pembayaran'];

      // Header tabel
      final headers = [
        'ID Transaksi',
        'Pekerjaan',
        'Pelanggan',
        'Mitra',
        'Tanggal',
        'Nilai Pekerjaan',
        'Komisi Platform',
        'Pendapatan Mitra',
        'Status',
      ];

      for (int column = 0; column < headers.length; column++) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: column,
                rowIndex: 0,
              ),
            )
            .value = TextCellValue(headers[column]);
      }

      // Isi seluruh data hasil filter
      for (int i = 0; i < paymentsToExport.length; i++) {
        final payment = paymentsToExport[i];
        final row = i + 1;

        final reference = payment.referenceCode?.trim();

        final transactionId =
            reference != null && reference.isNotEmpty
                ? reference
                : 'PAY-${payment.id.toString().padLeft(3, '0')}';

        final values = [
          TextCellValue(transactionId),
          TextCellValue(payment.jobTitle ?? '-'),
          TextCellValue(payment.pelangganName ?? '-'),
          TextCellValue(payment.mitraName ?? '-'),
          TextCellValue(payment.formattedDate),
          DoubleCellValue(payment.jobAmount),
          DoubleCellValue(payment.commissionAmount),
          DoubleCellValue(payment.mitraEarning),
          TextCellValue(_getStatusLabel(payment.status, payment)),
        ];

        for (int column = 0; column < values.length; column++) {
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: column,
                  rowIndex: row,
                ),
              )
              .value = values[column];
        }
      }

      // Lebar kolom agar lebih mudah dibaca
      sheet.setColumnWidth(0, 20);
      sheet.setColumnWidth(1, 28);
      sheet.setColumnWidth(2, 22);
      sheet.setColumnWidth(3, 22);
      sheet.setColumnWidth(4, 18);
      sheet.setColumnWidth(5, 20);
      sheet.setColumnWidth(6, 20);
      sheet.setColumnWidth(7, 22);
      sheet.setColumnWidth(8, 25);

      excel.delete('Sheet1');

      final bytes = excel.encode();

      if (bytes == null) {
        throw Exception('Gagal membuat file Excel.');
      }

      final now = DateTime.now();

      final dateLabel = _selectedDateRange != null
          ? '${_formatDateForApi(_selectedDateRange!.start)}_sampai_${_formatDateForApi(_selectedDateRange!.end)}'
          : _formatDateForApi(now);

      final fileName = 'data_pembayaran_$dateLabel';

      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${paymentsToExport.length} transaksi berhasil diekspor.',
          ),
          backgroundColor: theme.success,
        ),
      );
    } catch (e) {
      debugPrint('ERROR EXPORT EXCEL: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengekspor Excel: $e'),
          backgroundColor: theme.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  // ============================================================
  // OPEN PAYMENT DETAIL
  // ============================================================

    // ============================================================
  // OPEN PAYMENT DETAIL
  // ============================================================

  Future<void> _openPaymentDetail(PaymentModel payment) async {
    final t = theme;

    // 1. Tampilkan loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Center(
          child: CircularProgressIndicator(color: t.accent),
        );
      },
    );

    Map<String, dynamic>? detailData;

    // 2. Tarik data dari API (dengan debugging log)
    try {
      final response = await PaymentService.getAdminPaymentDetail(payment.id);

      debugPrint('========== DETAIL PEMBAYARAN ==========');
      debugPrint('ID: ${payment.id}');
      debugPrint('TYPE: ${response.runtimeType}');
      debugPrint('DATA: $response');

      if (response != null) {
        detailData = response;
      }
    } catch (e, stackTrace) {
      debugPrint('ERROR: $e');
      debugPrint('$stackTrace');
    }

    if (!mounted) return;

    // 3. Tutup dialog loading
    Navigator.of(context, rootNavigator: true).pop();

    // 4. Cek jika data kosong
    if (detailData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gagal mengambil detail pembayaran.'),
          backgroundColor: t.danger,
        ),
      );
      return;
    }

    PaymentModel paymentToUse = payment;
    final actualData = detailData['data']; // Sesuaikan dengan format API Laravel

    // 5. Parsing data JSON
    if (actualData is Map && actualData['payment'] is Map) {
      try {
        final paymentJson = Map<String, dynamic>.from(actualData['payment']);

        // --------------------------------------------------------
        // DATA BANK MITRA
        // --------------------------------------------------------
        Map<String, dynamic>? bankMap;

        if (paymentJson['mitra'] is Map) {
          final mitraObj = Map<String, dynamic>.from(paymentJson['mitra']);

          if (mitraObj['mitra_profiles'] is Map) {
            bankMap = Map<String, dynamic>.from(mitraObj['mitra_profiles']);
          }
        }

        if (paymentJson['mitra_bank'] is Map) {
          bankMap = Map<String, dynamic>.from(paymentJson['mitra_bank']);
        }

        // --------------------------------------------------------
        // PARSING PAYMENT
        // --------------------------------------------------------
        final job = paymentJson['job'] is Map
            ? Map<String, dynamic>.from(paymentJson['job'])
            : null;

        final mitra = paymentJson['mitra'] is Map
            ? Map<String, dynamic>.from(paymentJson['mitra'])
            : null;

        final pelanggan = paymentJson['pelanggan'] is Map
            ? Map<String, dynamic>.from(paymentJson['pelanggan'])
            : null;

        final parsed = PaymentModel(
          id: int.tryParse(paymentJson['id']?.toString() ?? '0') ?? 0,
          jobId: int.tryParse(paymentJson['job_id']?.toString() ?? '0') ?? 0,
          pelangganId: int.tryParse(paymentJson['pelanggan_id']?.toString() ?? '0') ?? 0,
          mitraId: paymentJson['mitra_id'] != null
              ? int.tryParse(paymentJson['mitra_id'].toString())
              : null,
          jobAmount: double.tryParse(paymentJson['job_amount']?.toString() ?? '0') ?? 0,
          commissionPercent: double.tryParse(paymentJson['commission_percent']?.toString() ?? '0') ?? 0,
          commissionAmount: double.tryParse(paymentJson['commission_amount']?.toString() ?? '0') ?? 0,
          totalPaid: double.tryParse(paymentJson['total_paid']?.toString() ?? '0') ?? 0,
          mitraEarning: double.tryParse(paymentJson['mitra_earning']?.toString() ?? '0') ?? 0,
          status: paymentJson['status']?.toString() ?? 'pending',
          paymentMethod: paymentJson['payment_method']?.toString(),
          referenceCode: paymentJson['reference_code']?.toString(),
          customerProofUrl: paymentJson['customer_proof_url']?.toString(),
          customerProofUploadedAt: paymentJson['customer_proof_uploaded_at'] != null
              ? IndonesiaTime.tryParseApiTimestamp(paymentJson['customer_proof_uploaded_at'])
              : null,
          customerBankName: paymentJson['customer_bank_name']?.toString(),
          customerAccountName: paymentJson['customer_account_name']?.toString(),
          mitraProofUrl: paymentJson['mitra_proof_url']?.toString(),
          mitraProofUploadedAt: paymentJson['mitra_proof_uploaded_at'] != null
              ? IndonesiaTime.tryParseApiTimestamp(paymentJson['mitra_proof_uploaded_at'])
              : null,
          adminNote: paymentJson['admin_note']?.toString(),
          mitraBank: bankMap,
          paidAt: paymentJson['paid_at'] != null
              ? IndonesiaTime.tryParseApiTimestamp(paymentJson['paid_at'])
              : null,
          settledAt: paymentJson['settled_at'] != null
              ? IndonesiaTime.tryParseApiTimestamp(paymentJson['settled_at'])
              : null,
          createdAt: paymentJson['created_at'] != null
              ? IndonesiaTime.tryParseApiTimestamp(paymentJson['created_at'])
              : null,
          jobTitle: job?['tittle']?.toString() ?? job?['title']?.toString(),
          mitraName: mitra?['name']?.toString(),
          pelangganName: pelanggan?['name']?.toString(),
        );

        paymentToUse = parsed;
        debugPrint('BERHASIL PARSING PAYMENT: ${paymentToUse.mitraName}');

      } catch (e, stackTrace) {
        debugPrint('ERROR PARSING PAYMENT DETAIL: $e');
        debugPrint('STACK TRACE: $stackTrace');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal parsing data: $e'),
            backgroundColor: t.danger,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }

    // ------------------------------------------------------------
    // TAMPILKAN DIALOG DETAIL
    // ------------------------------------------------------------
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AdminThemeProvider(
          theme: t,
          child: AdminPaymentDetailDialog(
            payment: paymentToUse,
          ),
        );
      },
    );

    if (result == true && mounted) {
      _loadData();
    }
  }

  // ============================================================
  // STATUS HELPERS
  // ============================================================

  Color _getStatusColor(String status) {
    final t = theme;

    switch (status) {
      case 'released':
      case 'settled':
        return t.success;

      case 'held':
        return AppColors.infoBlue;

      case 'pending':
        return t.accent;

      case 'refunded':
        return t.danger;

      default:
        return t.headerText;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'released':
      case 'settled':
        return Icons.check_circle_outline;

      case 'held':
        return Icons.lock_outline;

      case 'paid':
        return Icons.send_rounded;

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

  String _getStatusLabel(String status, PaymentModel payment) {
    switch (status) {
      case 'pending':
        return 'Menunggu Bayar';

      case 'held':
        return 'Ditahan (Escrow)';

      case 'released':
      case 'settled':
        return 'Selesai (Masuk Saldo)';

      case 'refunded':
        return 'Refund';

      default:
        return 'Tidak Diketahui';
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final t = theme;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: t.bg,
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: t.accent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            final isMobile = width < _mobileBreakpoint;

            final isTablet =
                width >= _mobileBreakpoint && width < 1100;

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
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 60,
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: t.accent,
                        ),
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
                      isMobile
                          ? _buildMobileList()
                          : _buildDesktopTable(width),

                      _buildPagination(isMobile),
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
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    final t = theme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pembayaran',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: t.cellText,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Kelola dan pantau seluruh transaksi pembayaran pelanggan dan mitra.',
          style: textTheme.bodyMedium?.copyWith(
            color: t.mutedText,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummarySection(bool isMobile) {
    final t = theme;
    final summary = _summary;

    final cards = [
      _summaryCard(
        title: 'Total Transaksi',
        value: PaymentModel.formatRupiah(
          summary?.totalPembayaran ?? 0,
        ),
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.infoBlue,
      ),

      _summaryCard(
        title: 'Komisi Platform',
        value: PaymentModel.formatRupiah(
          summary?.totalKomisi ?? 0,
        ),
        icon: Icons.account_balance_outlined,
        color: t.success,
      ),

      _summaryCard(
        title: 'Total ke Mitra',
        value: PaymentModel.formatRupiah(
          summary?.totalMitraEarning ?? 0,
        ),
        icon: Icons.handshake_outlined,
        color: t.accent,
      ),
    ];

    if (isMobile) {
      return SizedBox(
        height: 92,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: cards.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            return SizedBox(
              width: 220,
              child: cards[i],
            );
          },
        ),
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),

          if (i != cards.length - 1)
            const SizedBox(width: 16),
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
    final t = theme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: t.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 19,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.mutedText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.cellText,
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
    final t = theme;

    if (isMobile) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: t.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.filter_list,
                  size: 16,
                  color: t.headerText,
                ),
                const SizedBox(width: 6),
                Text(
                  'Filter Pembayaran',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: t.mutedText,
                  ),
                ),
                const Spacer(),
                _buildPaymentCount(),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusDropdown(fullWidth: true),
            const SizedBox(height: 10),
            _buildDateRangeButton(fullWidth: true),
            const SizedBox(height: 10),
            _buildExportButton(fullWidth: true),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            size: 18,
            color: t.headerText,
          ),
          const SizedBox(width: 8),
          Text(
            'Filter Status:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.grey700,
            ),
          ),
          const SizedBox(width: 12),
          _buildStatusDropdown(),
          const Spacer(),
          _buildDateRangeButton(),
          const SizedBox(width: 10),
          _buildExportButton(),
          const SizedBox(width: 12),
          _buildPaymentCount(),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown({
    bool fullWidth = false,
  }) {
    final t = theme;

    final dropdown = DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _selectedStatus,
        isDense: true,
        isExpanded: fullWidth,
        borderRadius: BorderRadius.circular(_radius),
        icon: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: t.headerText,
          ),
        ),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: t.cellText,
        ),
        items: _statusOptions.map((status) {
          return DropdownMenuItem<String>(
            value: status,
            child: Text(
              status,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
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
    );

    return Container(
      height: 40,
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: dropdown,
    );
  }

  // ============================================================
  // DESKTOP TABLE
  // ============================================================

  Widget _buildDesktopTable(double maxWidth) {
    final t = theme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: t.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Tentukan padding & spacing berdasarkan lebar layar
            final isNarrow = constraints.maxWidth < 900;
            
            return SizedBox(
              width: double.infinity, // Memaksa tabel selebar container
              child: DataTable(
                horizontalMargin: isNarrow ? 12 : 20,
                columnSpacing: isNarrow ? 12 : 20, // Kurangi spasi antar kolom
                headingRowHeight: 48,
                dataRowMinHeight: 56,
                dataRowMaxHeight: 88,
                headingTextStyle: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: t.headerText,
                ),
                headingRowColor: WidgetStateProperty.all(AppColors.grey50),
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
                      DataCell(_desktopTransactionId(payment, isNarrow)),
                      DataCell(
                        // Gunakan Expanded di dalam SizedBox agar teks menyesuaikan
                        SizedBox(
                          width: isNarrow ? 120 : 160,
                          child: Text(
                            payment.jobTitle ?? '-',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: t.cellText,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: isNarrow ? 80 : 100,
                          child: Text(
                            payment.pelangganName ?? '-',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: t.cellText,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: isNarrow ? 80 : 100,
                          child: Text(
                            payment.mitraName ?? '-',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: t.cellText,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          PaymentModel.formatRupiah(payment.jobAmount),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: t.cellText,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          PaymentModel.formatRupiah(
                            payment.commissionAmount,
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: t.success,
                          ),
                        ),
                      ),
                      DataCell(_statusBadge(payment.status, payment)),
                      DataCell(_desktopAction(payment)),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _desktopTransactionId(PaymentModel payment, bool isNarrow) {
    final t = theme;
    final reference = payment.referenceCode?.trim();
    final idText = reference != null && reference.isNotEmpty
        ? reference
        : 'PAY-${payment.id.toString().padLeft(3, '0')}';

    return SizedBox(
      width: isNarrow ? 100 : 130, // Batasi lebar ID
      child: Text(
        idText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: t.cellText,
        ),
      ),
    );
  }

  // Hanya tombol Detail.
  // Admin tidak melakukan pencairan escrow secara manual.

  Widget _desktopAction(PaymentModel payment) {
    return _pillButton(
      icon: Icons.visibility_outlined,
      label: 'Detail',
      bgColor: AppColors.grey100,
      fgColor: AppColors.grey700,
      onTap: () => _openPaymentDetail(payment),
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
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: fgColor,
              ),

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
    final t = theme;

    final reference = payment.referenceCode?.trim();

    final transactionId =
        reference != null && reference.isNotEmpty
        ? reference
        : 'PAY-${payment.id.toString().padLeft(3, '0')}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: t.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ------------------------------------------------------
          // HEADER
          // ------------------------------------------------------

          Padding(
            padding: const EdgeInsets.fromLTRB(
              14,
              14,
              14,
              10,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: t.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: t.accent,
                    size: 19,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transactionId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: t.cellText,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        payment.formattedDate,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.grey400,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                _statusBadge(
                  payment.status,
                  payment,
                ),
              ],
            ),
          ),

          Divider(height: 1, color: t.divider),

          // ------------------------------------------------------
          // INFO
          // ------------------------------------------------------

          Padding(
            padding: const EdgeInsets.fromLTRB(
              14,
              12,
              14,
              12,
            ),
            child: Column(
              children: [
                _mobileInfoRow(
                  icon: Icons.work_outline,
                  label: 'Pekerjaan',
                  value: payment.jobTitle ?? '-',
                ),

                const SizedBox(height: 8),

                _mobileInfoRow(
                  icon: Icons.person_outline,
                  label: 'Pelanggan',
                  value: payment.pelangganName ?? '-',
                ),

                const SizedBox(height: 8),

                _mobileInfoRow(
                  icon: Icons.handshake_outlined,
                  label: 'Mitra',
                  value: payment.mitraName ?? '-',
                ),
              ],
            ),
          ),

          Divider(height: 1, color: t.divider),

          // ------------------------------------------------------
          // MONEY
          // ------------------------------------------------------

          Container(
            padding: const EdgeInsets.fromLTRB(
              14,
              12,
              14,
              12,
            ),
            decoration: BoxDecoration(
              color: AppColors.grey50.withValues(alpha: 0.5),
            ),
            child: Column(
              children: [
                _mobileMoneyRow(
                  'Nilai Pekerjaan',
                  PaymentModel.formatRupiah(
                    payment.jobAmount,
                  ),
                ),

                const SizedBox(height: 6),

                _mobileMoneyRow(
                  'Komisi Platform',
                  PaymentModel.formatRupiah(
                    payment.commissionAmount,
                  ),
                ),

                const SizedBox(height: 8),

                Divider(height: 1, color: t.divider),

                const SizedBox(height: 8),

                _mobileMoneyRow(
                  'Mitra Terima',
                  PaymentModel.formatRupiah(
                    payment.mitraEarning,
                  ),
                  isBold: true,
                  valueColor: t.success,
                ),
              ],
            ),
          ),

          // ------------------------------------------------------
          // QUICK BANNER + DETAIL
          // ------------------------------------------------------

          Padding(
            padding: const EdgeInsets.fromLTRB(
              14,
              10,
              14,
              14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (payment.canVerifyCustomerProof) ...[
                  _quickActionBanner(
                    icon: Icons.fact_check_outlined,
                    color: AppColors.purple,
                    text:
                        'Perlu verifikasi bukti transfer pelanggan',
                  ),

                  const SizedBox(height: 8),
                ],

                SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: () => _openPaymentDetail(payment),
                    icon: const Icon(
                      Icons.visibility_outlined,
                      size: 16,
                    ),
                    label: const Text(
                      'Detail',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.grey700,
                      side: BorderSide(color: t.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final t = theme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 15,
          color: AppColors.grey400,
        ),

        const SizedBox(width: 8),

        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: t.mutedText,
            ),
          ),
        ),

        const SizedBox(width: 6),

        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: t.cellText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _mobileMoneyRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    final t = theme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: t.mutedText,
          ),
        ),

        const SizedBox(width: 10),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: isBold ? 14 : 12.5,
              fontWeight: isBold
                  ? FontWeight.w700
                  : FontWeight.w600,
              color: valueColor ?? t.cellText,
            ),
          ),
        ),
      ],
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
                fontSize: 11.5,
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

  Widget _statusBadge(
    String status,
    PaymentModel payment,
  ) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status),
            size: 12,
            color: color,
          ),

          const SizedBox(width: 4),

          Text(
            _getStatusLabel(status, payment),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  Widget _buildPagination(bool isMobile) {
    final t = theme;

    final total = _filteredPayments.length;

    if (total == 0) {
      return const SizedBox.shrink();
    }

    final totalPages = _totalPages;

    final startItem =
        (_currentPage - 1) * _itemsPerPage + 1;

    final endItem =
        (startItem + _itemsPerPage - 1).clamp(0, total);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 20,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: t.border),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menampilkan $startItem–$endItem dari $total pekerjaan',
                  style: TextStyle(
                    fontSize: 12,
                    color: t.headerText,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    _buildRowsPerPageDropdown(),

                    const Spacer(),

                    _buildNavButtons(totalPages),
                  ],
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Menampilkan $startItem–$endItem dari $total pekerjaan',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: t.headerText,
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

                    _buildNavButtons(totalPages),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildNavButtons(int totalPages) {
    final t = theme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _navButton(
          icon: Icons.chevron_left,
          enabled: _currentPage > 1,
          onTap: () {
            setState(() => _currentPage--);
          },
        ),

        const SizedBox(width: 8),

        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Hal $_currentPage / $totalPages',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: t.accent,
            ),
          ),
        ),

        const SizedBox(width: 8),

        _navButton(
          icon: Icons.chevron_right,
          enabled: _currentPage < totalPages,
          onTap: () {
            setState(() => _currentPage++);
          },
        ),
      ],
    );
  }

  Widget _buildRowsPerPageDropdown() {
    final t = theme;

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _itemsPerPage,
          isDense: true,
          borderRadius: BorderRadius.circular(8),
          icon: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: t.cellText,
            ),
          ),
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: t.cellText,
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
    final t = theme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled
                  ? t.border
                  : t.border.withValues(alpha: 0.5),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? t.cellText : t.border,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR & EMPTY
  // ============================================================

  Widget _buildError() {
    final t = theme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: t.danger.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(
          color: t.danger.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: t.danger,
            size: 48,
          ),

          const SizedBox(height: 12),

          Text(
            _error ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: t.danger,
              fontSize: 13,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(
              Icons.refresh,
              size: 18,
            ),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: t.accent,
              foregroundColor: AppColors.white,
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
    final t = theme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 48,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: t.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 34,
              color: t.accent.withValues(alpha: 0.7),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'Tidak ada data pembayaran.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: t.mutedText,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
