import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk platformViewRegistry
import 'dart:html' as html; // Untuk HtmlElementView

import '../../models/monthly_earning_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/indonesia_time.dart';
import '../../sections/payment/withdraw_dialog.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  String selectedPeriod = '6 Bulan';
  int _monthsCount = 6;

  bool _isLoading = true;
  String? _error;

  // State untuk Saldo Dompet
  double _walletBalance = 0;
  bool _isLoadingWallet = true;

  MonthlyEarningSummary? _summary;
  List<MonthlyEarningModel> _monthly = [];

  List<Map<String, dynamic>> _withdrawals = [];
  bool _isLoadingWithdrawals = true;
  String? _withdrawalError;

  int _currentPage = 1;
  int _rowsPerPage = 10;
  static const List<int> _rowsPerPageOptions = [5, 10, 25, 50];

  // ============================================================
  // DESIGN TOKENS
  // ============================================================

  static const Color _accent = AppColors.primaryTeal;
  static const Color _tableBorder = AppColors.grey200;
  static const Color _tableDivider = AppColors.grey100;
  static const Color _cellText = AppColors.grey900;

  static const double _gapAfterHeader = 16;
  static const double _gapBetweenSections = 16;
  static const double _cardRadius = 14;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _openProofDialog(String rawUrl) async {
    final fullUrl = _getFullImageUrl(rawUrl); // Pastikan pakai helper ini

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Bukti Transfer dari Admin',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.grey900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4,
                    child: Image.network(
                      fullUrl, // Pakai fullUrl
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: _accent),
                        );
                      },
                      errorBuilder: (context, error, stack) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                                color: AppColors.grey400,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Gagal memuat bukti transfer.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // LOAD DATA (GABUNGAN STATISTIK & DOMPET)
  // ============================================================

  Future<void> _loadAllData() async {
    await Future.wait([_loadData(), _loadWalletBalance(), _loadWithdrawals()]);
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final endpoint = '/mitra/earnings/monthly?months=$_monthsCount';
      final response = await ApiService.get(endpoint);

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
            ? MonthlyEarningSummary.fromJson(decoded['summary'])
            : null;

        _monthly = (decoded['monthly'] is List)
            ? (decoded['monthly'] as List)
                  .map((e) => MonthlyEarningModel.fromJson(e))
                  .toList()
            : [];

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error: $e';
      });
    }
  }

  Future<void> _loadWalletBalance() async {
    try {
      final response = await ApiService.get('/wallet');
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded['success'] == true) {
        if (!mounted) return;
        setState(() {
          _walletBalance =
              double.tryParse(decoded['data']['saldo_tersedia'].toString()) ??
              0;
          _isLoadingWallet = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoadingWallet = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingWallet = false);
    }
  }

  Future<void> _loadWithdrawals() async {
    try {
      final response = await ApiService.get('/mitra/withdrawals');

      final decoded = jsonDecode(response.body);

      print("=== DATA WITHDRAWAL DARI API ===");
      print(decoded['data']);
      print("================================");

      if (!mounted) return;

      if (response.statusCode == 200 && decoded['success'] == true) {
        setState(() {
          _withdrawals = (decoded['data'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

          _isLoadingWithdrawals = false;
          _withdrawalError = null;
          _currentPage = 1;
        });
      } else {
        setState(() {
          _isLoadingWithdrawals = false;
          _withdrawalError =
              decoded['message']?.toString() ??
              'Gagal memuat riwayat penarikan.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingWithdrawals = false;
        _withdrawalError = 'Terjadi kesalahan saat memuat riwayat penarikan.';
      });
    }
  }

  // ============================================================
  // FORMAT RUPIAH
  // ============================================================

  String formatRupiah(double value) {
    final number = value.toInt().toString();
    String result = '';
    int counter = 0;

    for (int i = number.length - 1; i >= 0; i--) {
      result = number[i] + result;
      counter++;
      if (counter % 3 == 0 && i != 0) {
        result = '.$result';
      }
    }
    return 'Rp$result';
  }

  // Menghitung total halaman
  int get _totalPages {
    if (_withdrawals.isEmpty) return 1;
    return (_withdrawals.length / _rowsPerPage).ceil();
  }

  // Mengambil data sesuai halaman saat ini
  List<Map<String, dynamic>> get _pagedWithdrawals {
    final start = (_currentPage - 1) * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, _withdrawals.length);
    if (start >= _withdrawals.length) return [];
    return _withdrawals.sublist(start, end);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.sectionAltLight,
      child: RefreshIndicator(
        onRefresh: _loadAllData,
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

                  // TAMPILKAN BANNER TARIK DANA JIKA TIDAK SEDANG LOADING
                  if (!_isLoadingWallet) ...[
                    _buildWalletBanner(isMobile),
                    const SizedBox(height: _gapBetweenSections),

                    _buildWithdrawalHistory(isMobile),
                    const SizedBox(height: _gapBetweenSections),
                  ],

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: CircularProgressIndicator(color: _accent),
                      ),
                    )
                  else if (_error != null)
                    _buildError()
                  else if (_monthly.isEmpty)
                    _buildEmptyState()
                  else ...[
                    _buildSummaryCards(isMobile: isMobile),
                    const SizedBox(height: _gapBetweenSections),
                    _buildChartCard(context, isMobile: isMobile),
                    const SizedBox(height: _gapBetweenSections),
                    _buildRecentIncomeCard(context, isMobile: isMobile),
                    const SizedBox(height: 28),
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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Penghasilan',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.grey900,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Pantau pendapatan dan tarik saldo Anda di sini.',
          style: TextStyle(fontSize: 13, color: AppColors.grey500),
        ),
      ],
    );
  }

  // ============================================================
  // WALLET BANNER (FITUR BARU)
  // ============================================================

  Widget _buildWalletBanner(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: _accent,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saldo Siap Ditarik',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  formatRupiah(_walletBalance),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Panggil Dialog Tarik Dana
              final res = await showDialog(
                context: context,
                builder: (_) =>
                    WithdrawDialog(role: 'mitra', maxAmount: _walletBalance),
              );

              // Jika berhasil tarik, refresh data
              if (res == true) {
                _loadAllData();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Tarik',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WITHDRAWAL HISTORY TABLE
  // ============================================================

  Widget _buildWithdrawalHistory(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riwayat Penarikan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Daftar pengajuan penarikan saldo Anda.',
            style: TextStyle(fontSize: 12, color: AppColors.grey500),
          ),
          const SizedBox(height: 16),

          if (_isLoadingWithdrawals)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: _accent),
              ),
            )
          else if (_withdrawalError != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  _withdrawalError!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ),
            )
          else if (_withdrawals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Column(
                  children: const [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 38,
                      color: AppColors.grey400,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Belum ada riwayat penarikan.',
                      style: TextStyle(fontSize: 13, color: AppColors.grey500),
                    ),
                  ],
                ),
              ),
            )
          else
            // ✅ Batasi lebar maksimal 800px agar tidak melar berjauhan di Web/Desktop
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.grey200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTableHeaderRow(isMobile),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.grey200,
                  ),
                  for (int i = 0; i < _pagedWithdrawals.length; i++) ...[
                    _buildTableDataRow(_pagedWithdrawals[i], isMobile),
                    if (i != _pagedWithdrawals.length - 1)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.grey100,
                      ),
                  ],
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.grey200,
                  ),
                  _buildTableFooter(isMobile), // <-- TAMBAHKAN INI
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderRow(bool isMobile) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.5), // Tanggal
        1: FlexColumnWidth(2.5), // Nominal
        2: FlexColumnWidth(3.5), // Bank
        3: FlexColumnWidth(2.0), // Status
        4: FlexColumnWidth(2.0), // Bukti
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          ),
          children: [
            _headerCell('Tanggal', isMobile),
            _headerCell('Nominal', isMobile),
            _headerCell('Bank / Rekening', isMobile),
            _headerCell('Status', isMobile),
            _headerCell('Bukti', isMobile),
          ],
        ),
      ],
    );
  }

  Widget _headerCell(String text, bool compact) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.grey700,
          fontSize: compact ? 11 : 12.5,
        ),
      ),
    );
  }

  Widget _buildTableDataRow(Map<String, dynamic> item, bool isMobile) {
    final amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
    final bank = item['bank_name']?.toString() ?? '-';
    final account = item['account_number']?.toString() ?? '-';

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.5), // Tanggal
        1: FlexColumnWidth(2.5), // Nominal
        2: FlexColumnWidth(3.5), // Bank
        3: FlexColumnWidth(2.0), // Status
        4: FlexColumnWidth(2.0), // Bukti
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            // Tanggal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Text(
                _formatWithdrawalDate(item['created_at']),
                style: TextStyle(
                  color: AppColors.grey900,
                  fontSize: isMobile ? 11.5 : 13,
                ),
              ),
            ),
            // Nominal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Text(
                formatRupiah(amount),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey900,
                  fontSize: isMobile ? 11.5 : 13,
                ),
              ),
            ),
            // Bank
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    bank,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 11.5 : 13,
                    ),
                  ),
                  Text(
                    _maskAccountNumber(account),
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
            // Status
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildWithdrawalStatus(item['status']?.toString()),
              ),
            ),
            // Bukti (Gambar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildProofCell(item), // Panggil widget gambar
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTableFooter(bool isMobile) {
    final total = _withdrawals.length;
    final start = total == 0 ? 0 : ((_currentPage - 1) * _rowsPerPage) + 1;
    final end = (_currentPage * _rowsPerPage).clamp(0, total);
    final canPrev = _currentPage > 1;
    final canNext = _currentPage < _totalPages;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Menampilkan $start–$end dari $total pembayaran',
              style: const TextStyle(color: AppColors.grey500, fontSize: 12),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRowsPerPageDropdown(),
              const SizedBox(width: 12),
              _navButton(
                icon: Icons.chevron_left,
                enabled: canPrev,
                onTap: () => setState(() => _currentPage--),
              ),
              const SizedBox(width: 8),
              Container(
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
              ),
              const SizedBox(width: 8),
              _navButton(
                icon: Icons.chevron_right,
                enabled: canNext,
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey200),
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
            if (value != null) {
              setState(() {
                _rowsPerPage = value;
                _currentPage = 1;
              });
            }
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

  // FORMAT TANGGAL
  String _formatWithdrawalDate(dynamic value) {
    if (value == null) return '-';

    final parsed = IndonesiaTime.tryParseApiTimestamp(value);
    final date = parsed == null ? null : IndonesiaTime.toWall(parsed);

    if (date == null) return '-';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // SAMARKAN NOMOR REKENING
  String _maskAccountNumber(String account) {
    if (account.length <= 4) return account;

    return '${'*' * (account.length - 4)}'
        '${account.substring(account.length - 4)}';
  }

  String _getFullImageUrl(String path) {
    if (path.isEmpty || path == 'null') return '';

    // Jika URL sudah lengkap
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // Ambil origin tanpa /api
    final origin = ApiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

    String normalizedPath = path;

    // Sesuaikan URL bukti withdraw dengan route khusus di api.php
    if (normalizedPath.startsWith('/storage/withdraw_proofs/')) {
      final filename = normalizedPath.split('/').last;

      normalizedPath = '/api/images/withdraw_proofs/$filename';
    }

    // Jika path relatif
    if (!normalizedPath.startsWith('/')) {
      normalizedPath = '/$normalizedPath';
    }

    return '$origin$normalizedPath';
  }

  Widget _buildProofCell(Map<String, dynamic> item) {
    final rawUrl =
        (item['transfer_proof_url'] ??
                item['proof_url'] ??
                item['admin_proof_url'])
            ?.toString();
    final status = (item['status']?.toString() ?? '').toLowerCase();

    // Jika tidak ada gambar
    if (rawUrl == null || rawUrl.isEmpty || rawUrl == 'null') {
      return Text(
        status == 'transferred' ? 'Tidak ada' : '-',
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.grey400,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final fullUrl = _getFullImageUrl(rawUrl);

    return GestureDetector(
      onTap: () => _openProofDialog(rawUrl),
      child: Container(
        width: 44, // Ukuran gambar di tabel
        height: 44,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.grey200),
          color: AppColors.grey50,
          // TRICK DARI KODE 2: Gunakan DecorationImage agar anti-crash di Web
          image: DecorationImage(
            image: NetworkImage(fullUrl),
            fit: BoxFit.cover,
            onError: (exception, stackTrace) {
              debugPrint("Gagal load gambar: $exception");
            },
          ),
        ),
        // Widget anak ini HANYA muncul jika gambar gagal dimuat
        child: Image.network(
          fullUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(
                Icons.broken_image,
                size: 18,
                color: AppColors.grey400,
              ),
            );
          },
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            // Sembunyikan widget Image jika gambar sudah tampil di background Container
            if (wasSynchronouslyLoaded || frame != null) {
              return const SizedBox.shrink();
            }
            // Tampilkan loading spinner saat mengunduh
            return const Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _accent,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // STATUS PENARIKAN
  Widget _buildWithdrawalStatus(String? status) {
    final normalized = status?.toLowerCase() ?? '';

    String label;
    Color color;
    Color background;

    switch (normalized) {
      case 'transferred':
        label = 'Berhasil';
        color = AppColors.success;
        background = AppColors.success.withValues(alpha: 0.10);
        break;

      case 'approved':
        label = 'Disetujui';
        color = Colors.blue;
        background = Colors.blue.withValues(alpha: 0.10);
        break;

      case 'rejected':
        label = 'Ditolak';
        color = AppColors.danger;
        background = AppColors.danger.withValues(alpha: 0.10);
        break;

      case 'pending':
      default:
        label = 'Diproses';
        color = Colors.orange.shade800;
        background = Colors.orange.withValues(alpha: 0.12);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY CARDS
  // ============================================================

  Widget _buildSummaryCards({required bool isMobile}) {
    final s = _summary;
    final gap = isMobile ? 8.0 : 16.0;

    final cards = [
      _summaryCard(
        title: isMobile ? 'Total' : 'Total Penghasilan',
        value: formatRupiah(s?.totalPendapatan ?? 0),
        subtitle: isMobile ? 'Akumulasi' : 'Akumulasi $_monthsCount bulan',
        icon: Icons.account_balance_wallet_outlined,
        iconColor: _accent,
        isCompact: isMobile,
      ),
      _summaryCard(
        title: isMobile ? 'Selesai' : 'Pekerjaan Selesai',
        value: '${s?.totalPekerjaan ?? 0}',
        subtitle: isMobile ? 'Pekerjaan' : 'Total pekerjaan',
        icon: Icons.check_circle_outline,
        iconColor: AppColors.success,
        isCompact: isMobile,
      ),
      _summaryCard(
        title: isMobile ? 'Rata-rata' : 'Rata-rata Penghasilan',
        value: formatRupiah(s?.rataRataPerBulan ?? 0),
        subtitle: 'Per bulan',
        icon: Icons.trending_up,
        iconColor: AppColors.primaryTeal,
        isCompact: isMobile,
      ),
    ];

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
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkTeal.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isCompact ? 34 : 42,
            height: isCompact ? 34 : 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(isCompact ? 9 : 11),
            ),
            child: Icon(icon, color: iconColor, size: isCompact ? 17 : 21),
          ),
          SizedBox(width: isCompact ? 10 : 12),
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
                    color: AppColors.grey500,
                    fontSize: isCompact ? 10.5 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: isCompact ? 2 : 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isCompact ? 13 : 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                    height: 1.1,
                  ),
                ),
                if (!isCompact) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.grey400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHART CARD
  // ============================================================

  Widget _buildChartCard(BuildContext context, {required bool isMobile}) {
    final incomeData = _monthly.map((m) => m.totalPendapatan).toList();
    final maxIncome = incomeData.isEmpty
        ? 1000000.0
        : incomeData.reduce((a, b) => a > b ? a : b);

    final maxY = (maxIncome / 500000).ceil() * 500000.0;
    final safeMaxY = maxY <= 0 ? 1000000.0 : maxY;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Grafik Penghasilan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isMobile
                          ? 'Perkembangan per bulan'
                          : 'Perkembangan penghasilan setiap bulan',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _tableBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedPeriod,
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
                    items: const [
                      DropdownMenuItem(
                        value: '6 Bulan',
                        child: Text('6 Bulan'),
                      ),
                      DropdownMenuItem(
                        value: '1 Tahun',
                        child: Text('1 Tahun'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedPeriod = value;
                        _monthsCount = value == '6 Bulan' ? 6 : 12;
                      });
                      _loadData();
                    },
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: isMobile ? 18 : 24),

          // CHART
          SizedBox(
            height: isMobile ? 220 : 280,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (_monthly.length - 1).toDouble(),
                minY: 0,
                maxY: safeMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: safeMaxY / 5,
                  getDrawingHorizontalLine: (value) =>
                      const FlLine(color: _tableDivider, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= _monthly.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _monthly[index].bulanLabel,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.grey400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: safeMaxY / 5,
                      reservedSize: isMobile ? 42 : 52,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) {
                          return const Text(
                            '0',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.grey400,
                            ),
                          );
                        }
                        return Text(
                          '${(value / 1000000).toStringAsFixed(1)}jt',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.grey400,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < _monthly.length; i++)
                        FlSpot(i.toDouble(), _monthly[i].totalPendapatan),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.3,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        return FlDotCirclePainter(
                          radius: 3.5,
                          color: AppColors.white,
                          strokeWidth: 2.5,
                          strokeColor: _accent,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _accent.withValues(alpha: 0.2),
                          _accent.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                    color: _accent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECENT INCOME CARD
  // ============================================================

  Widget _buildRecentIncomeCard(
    BuildContext context, {
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Penghasilan Bulanan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Rincian per bulan',
            style: TextStyle(fontSize: 12, color: AppColors.grey500),
          ),
          SizedBox(height: isMobile ? 14 : 18),

          ..._monthly.asMap().entries.map((entry) {
            final index = entry.key;
            final m = entry.value;

            return Column(
              children: [
                _buildIncomeRow(m, isMobile),
                if (index != _monthly.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Divider(height: 1, color: _tableDivider),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildIncomeRow(MonthlyEarningModel m, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: isMobile ? 38 : 44,
            height: isMobile ? 38 : 44,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(isMobile ? 10 : 11),
            ),
            child: Icon(
              Icons.payments_outlined,
              color: _accent,
              size: isMobile ? 18 : 20,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Penghasilan ${m.bulanLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 13.5,
                    fontWeight: FontWeight.w600,
                    color: _cellText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${m.jumlahPekerjaan} pekerjaan selesai',
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 11.5,
                    color: AppColors.grey400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatRupiah(m.totalPendapatan),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryTeal,
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
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Error',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.danger,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadAllData,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: AppColors.white,
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
              color: _accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bar_chart_outlined,
              size: 34,
              color: _accent.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum ada data penghasilan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
