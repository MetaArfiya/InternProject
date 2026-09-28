import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class AdminDailyReportScreen extends StatefulWidget {
  const AdminDailyReportScreen({super.key});

  @override
  State<AdminDailyReportScreen> createState() =>
      _AdminDailyReportScreenState();
}

class _AdminDailyReportScreenState extends State<AdminDailyReportScreen> {
  // ============================================================
  // STATE
  // ============================================================

  String _periodKey = 'week'; // today | week | month

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _dailyData = [];

  int _totalTransactions = 0;
  int _totalJobs = 0;
  double _totalIncome = 0;
  double _averageIncome = 0;

  final List<Map<String, String>> _periodOptions = [
    {'label': 'Hari Ini', 'value': 'today'},
    {'label': 'Minggu Ini', 'value': 'week'},
    {'label': 'Bulan Ini', 'value': 'month'},
  ];

  // ============================================================
  // PAGINATION STATE
  // ============================================================

  int _currentPage = 1;
  int _itemsPerPage = 10;

  static const List<int> _itemsPerPageOptions = [5, 10, 25, 50];

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  // ============================================================
  // LOAD REPORT
  // ============================================================

  Future<void> _loadReport() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.get(
        '/admin/daily-report?period=$_periodKey',
      );

      debugPrint('📊 DAILY REPORT: ${response.statusCode}');
      debugPrint('📊 BODY: ${response.body}');

      if (response.statusCode != 200) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat (${response.statusCode})';
        });

        return;
      }

      final decoded = jsonDecode(response.body);

      if (decoded['success'] != true) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage =
              decoded['message']?.toString() ?? 'Gagal memuat laporan.';
        });

        return;
      }

      if (!mounted) return;

      final s = decoded['summary'] ?? {};

      final list = decoded['data'] is List
          ? decoded['data'] as List
          : [];

      setState(() {
        _dailyData = list
            .whereType<Map>()
            .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e),
            )
            .toList();

        _totalTransactions =
            int.tryParse(
              s['total_transaksi']?.toString() ?? '0',
            ) ??
            0;

        _totalJobs =
            int.tryParse(
              s['total_pekerjaan']?.toString() ?? '0',
            ) ??
            0;

        _totalIncome =
            double.tryParse(
              s['total_komisi']?.toString() ?? '0',
            ) ??
            0;

        _averageIncome =
            double.tryParse(
              s['rata_harian']?.toString() ?? '0',
            ) ??
            0;

        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ ERROR DAILY REPORT: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  // ============================================================
  // FORMAT RUPIAH
  // ============================================================

  String _formatRupiah(dynamic amount) {
    final num value = amount is num
        ? amount
        : (num.tryParse(amount.toString()) ?? 0);

    final intValue = value.toInt();

    final reversed = intValue.toString().split('').reversed.toList();

    final chunks = <String>[];

    for (int i = 0; i < reversed.length; i += 3) {
      final chunk = reversed
          .skip(i)
          .take(3)
          .toList()
          .reversed
          .join();

      chunks.add(chunk);
    }

    return 'Rp${chunks.reversed.join('.')}';
  }

  // ============================================================
  // PERIOD LABEL
  // ============================================================

  String get _currentPeriodLabel {
    return _periodOptions.firstWhere(
      (e) => e['value'] == _periodKey,
    )['label']!;
  }

  // ============================================================
  // PAGINATION HELPERS
  // ============================================================

  int get _totalPages {
    final total = _dailyData.length;

    if (total == 0) return 1;

    return ((total - 1) ~/ _itemsPerPage) + 1;
  }

  List<Map<String, dynamic>> get _paginatedData {
    final start = (_currentPage - 1) * _itemsPerPage;

    if (start >= _dailyData.length) {
      return [];
    }

    final end = (start + _itemsPerPage).clamp(
      0,
      _dailyData.length,
    );

    return _dailyData.sublist(start, end);
  }

  // ============================================================
  // TRANSACTION DETAILS
  // ============================================================

  List<Map<String, dynamic>> _getTransactionDetails(
    Map<String, dynamic> d,
  ) {
    final raw = d['transaction_details'];

    if (raw is! List) {
      return [];
    }

    return raw
        .whereType<Map>()
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }

  // ============================================================
  // JOB DETAILS
  // ============================================================

  List<Map<String, dynamic>> _getJobDetails(
    Map<String, dynamic> d,
  ) {
    final raw = d['job_details'];

    if (raw is! List) {
      return [];
    }

    return raw
        .whereType<Map>()
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        final double hPad = isMobile ? 16 : 24;

        return RefreshIndicator(
          onRefresh: _loadReport,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    hPad,
                    hPad,
                    hPad,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isMobile),

                      const SizedBox(height: 24),

                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 80,
                            ),
                            child: CircularProgressIndicator(
                              color: Colors.orange,
                            ),
                          ),
                        )
                      else if (_errorMessage != null)
                        _buildError()
                      else ...[
                        _buildSummarySection(isMobile),

                        const SizedBox(height: 20),

                        _buildPeriodFilter(isMobile),

                        const SizedBox(height: 20),

                        if (_dailyData.isEmpty)
                          _buildEmptyState()
                        else ...[
                          _buildBarChart(
                            isMobile: isMobile,
                            title: 'Grafik Transaksi',
                            subtitle:
                                'Jumlah transaksi berdasarkan hari',
                            values: _dailyData.map<double>(
                              (d) =>
                                  (d['transactions'] as num?)
                                      ?.toDouble() ??
                                  0,
                            ).toList(),
                            labels: _dailyData.map<String>(
                              (d) => d['day'].toString(),
                            ).toList(),
                            valueSuffix: 'transaksi',
                            barColor: const Color(0xFF3B82F6),
                          ),

                          const SizedBox(height: 16),

                          _buildBarChart(
                            isMobile: isMobile,
                            title: 'Grafik Komisi Admin',
                            subtitle:
                                'Total komisi admin sebesar 15%',
                            values: _dailyData.map<double>(
                              (d) =>
                                  (d['income'] as num?)
                                      ?.toDouble() ??
                                  0,
                            ).toList(),
                            labels: _dailyData.map<String>(
                              (d) => d['day'].toString(),
                            ).toList(),
                            valueSuffix: 'Rp',
                            barColor: const Color(0xFF10B981),
                          ),

                          const SizedBox(height: 16),

                          _buildBarChart(
                            isMobile: isMobile,
                            title: 'Grafik Pekerjaan',
                            subtitle:
                                'Jumlah pekerjaan yang diselesaikan',
                            values: _dailyData.map<double>(
                              (d) =>
                                  (d['jobs'] as num?)
                                      ?.toDouble() ??
                                  0,
                            ).toList(),
                            labels: _dailyData.map<String>(
                              (d) => d['day'].toString(),
                            ).toList(),
                            valueSuffix: 'pekerjaan',
                            barColor: const Color(0xFFF59E0B),
                          ),

                          const SizedBox(height: 20),

                          _buildReportTable(isMobile),
                        ],
                      ],

                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // ==================================================
                // PAGINATION FULL WIDTH
                // ==================================================

                if (!_isLoading &&
                    _errorMessage == null &&
                    _dailyData.isNotEmpty)
                  _buildPaginationFullWidth(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
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
          'Laporan Harian',
          style: TextStyle(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Pantau aktivitas transaksi, pekerjaan, dan pendapatan komisi admin.',
          style: TextStyle(
            fontSize: isMobile ? 12 : 13,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummarySection(bool isMobile) {
    final cards = [
      _summaryCard(
        title: 'Total Transaksi',
        value: '$_totalTransactions',
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF3B82F6),
        background: const Color(0xFFEFF6FF),
      ),

      _summaryCard(
        title: 'Total Pekerjaan',
        value: '$_totalJobs',
        icon: Icons.work_outline,
        color: const Color(0xFFF59E0B),
        background: const Color(0xFFFFF7ED),
      ),

      _summaryCard(
        title: 'Total Komisi',
        value: _formatRupiah(_totalIncome),
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF10B981),
        background: const Color(0xFFECFDF5),
      ),

      _summaryCard(
        title: 'Rata-rata Harian',
        value: _formatRupiah(_averageIncome),
        icon: Icons.analytics_outlined,
        color: const Color(0xFF7C3AED),
        background: const Color(0xFFF3E8FF),
      ),
    ];

    // ==========================================================
    // MOBILE
    // ==========================================================

    if (isMobile) {
      return Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 10),
                Expanded(child: cards[1]),
              ],
            ),
          ),

          const SizedBox(height: 10),

          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[2]),
                const SizedBox(width: 10),
                Expanded(child: cards[3]),
              ],
            ),
          ),
        ],
      );
    }

    // ==========================================================
    // DESKTOP
    // ==========================================================

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 12),
          Expanded(child: cards[1]),
          const SizedBox(width: 12),
          Expanded(child: cards[2]),
          const SizedBox(width: 12),
          Expanded(child: cards[3]),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
              height: 1.1,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PERIOD FILTER
  // ============================================================

  Widget _buildPeriodFilter(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPeriodLabel(),

                const SizedBox(height: 12),

                _buildPeriodDropdown(),
              ],
            )
          : Row(
              children: [
                _buildPeriodLabel(),

                const Spacer(),

                SizedBox(
                  width: 200,
                  child: _buildPeriodDropdown(),
                ),
              ],
            ),
    );
  }

  // ============================================================
  // PERIOD LABEL
  // ============================================================

  Widget _buildPeriodLabel() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.date_range_outlined,
            size: 18,
            color: Color(0xFF2563EB),
          ),
        ),

        const SizedBox(width: 12),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Periode Laporan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),

            const SizedBox(height: 2),

            Text(
              'Menampilkan: $_currentPeriodLabel',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // PERIOD DROPDOWN
  // ============================================================

  Widget _buildPeriodDropdown() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _periodKey,
          isExpanded: true,
          borderRadius: BorderRadius.circular(10),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFF64748B),
            size: 21,
          ),
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF334155),
            fontWeight: FontWeight.w600,
          ),
          items: _periodOptions.map((p) {
            return DropdownMenuItem<String>(
              value: p['value'],
              child: Text(
                p['label']!,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _periodKey = value;
              _currentPage = 1;
            });

            _loadReport();
          },
        ),
      ),
    );
  }

  // ============================================================
  // BAR CHART
  // ============================================================

  Widget _buildBarChart({
    required bool isMobile,
    required String title,
    required String subtitle,
    required List<double> values,
    required List<String> labels,
    required String valueSuffix,
    required Color barColor,
  }) {
    if (values.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue = values.reduce(
      (a, b) => a > b ? a : b,
    );

    final chartHeight = isMobile ? 200.0 : 240.0;

    final maxBarHeight = chartHeight - 60;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 4),

          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 20),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 80,
              ),
              child: SizedBox(
                height: chartHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(
                    values.length,
                    (index) {
                      final value = values[index];

                      final height = maxValue == 0
                          ? 0.0
                          : (value / maxValue) * maxBarHeight;

                      return Container(
                        width: isMobile ? 60 : 80,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              valueSuffix == 'Rp'
                                  ? _formatRupiah(value)
                                  : value.toInt().toString(),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),

                            const SizedBox(height: 6),

                            Container(
                              height: height < 4 ? 4 : height,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    barColor,
                                    barColor.withValues(
                                      alpha: 0.6,
                                    ),
                                  ],
                                ),
                                borderRadius:
                                    const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              labels[index],
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REPORT TABLE
  // ============================================================

  Widget _buildReportTable(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rincian Laporan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),

        const SizedBox(height: 4),

        Text(
          '${_dailyData.length} hari ditampilkan',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),

        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: isMobile
              ? Column(
                  children: _paginatedData.asMap().entries.map(
                    (entry) {
                      final isLast =
                          entry.key == _paginatedData.length - 1;

                      return _buildMobileReportCard(
                        entry.value,
                        isLast,
                      );
                    },
                  ).toList(),
                )
              : _buildDesktopReportTable(),
        ),
      ],
    );
  }

  // ============================================================
  // DESKTOP REPORT TABLE
  // ============================================================

  Widget _buildDesktopReportTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                const Color(0xFFF8FAFC),
              ),

              headingRowHeight: 48,

              // Tinggi minimum dibuat lebih besar karena
              // sekarang transaksi dan pekerjaan bisa terdiri
              // dari beberapa baris.
              dataRowMinHeight: 82,

              dataRowMaxHeight: 150,

              columnSpacing: 24,

              horizontalMargin: 20,

              dividerThickness: 1,

              showBottomBorder: true,

              columns: const [
                DataColumn(
                  label: _TableHeader('HARI'),
                ),
                DataColumn(
                  label: _TableHeader('TRANSAKSI'),
                ),
                DataColumn(
                  label: _TableHeader('PEKERJAAN'),
                ),
                DataColumn(
                  label: _TableHeader('KOMISI ADMIN'),
                ),
              ],

              rows: _paginatedData.map((d) {
                final transactionDetails =
                    _getTransactionDetails(d);

                final jobDetails =
                    _getJobDetails(d);

                return DataRow(
                  cells: [
                    // ==================================================
                    // HARI
                    // ==================================================

                    DataCell(
                      Text(
                        d['day']?.toString() ?? '-',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),

                    // ==================================================
                    // TRANSAKSI
                    // ==================================================

                    DataCell(
                      _buildTransactionCell(
                        transactionDetails,
                        fallbackCount: d['transactions'] ?? 0,
                      ),
                    ),

                    // ==================================================
                    // PEKERJAAN
                    // ==================================================

                    DataCell(
                      _buildJobCell(
                        jobDetails,
                        fallbackCount: d['jobs'] ?? 0,
                      ),
                    ),

                    // ==================================================
                    // KOMISI
                    // ==================================================

                    DataCell(
                      Text(
                        _formatRupiah(
                          d['income'] ?? 0,
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // TRANSACTION CELL
  // ============================================================

  Widget _buildTransactionCell(
    List<Map<String, dynamic>> details, {
    required dynamic fallbackCount,
  }) {
    // Kalau backend belum mengirim detail,
    // tetap tampilkan jumlah agar tidak kosong.
    if (details.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSmallIconBox(
            icon: Icons.receipt_long_outlined,
            background: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF3B82F6),
          ),

          const SizedBox(width: 8),

          Text(
            '$fallbackCount transaksi',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSmallIconBox(
          icon: Icons.receipt_long_outlined,
          background: const Color(0xFFEFF6FF),
          iconColor: const Color(0xFF3B82F6),
        ),

        const SizedBox(width: 8),

        SizedBox(
          width: 180,
          height: 72,
          child: Scrollbar(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: details.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = details[index];

                final reference =
                    item['reference_code']?.toString();

                final id =
                    item['id']?.toString();

                final displayReference =
                    reference != null &&
                            reference.isNotEmpty
                        ? reference
                        : id != null
                            ? 'PAY-$id'
                            : 'Transaksi';

                return Text(
                  displayReference,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // JOB CELL
  // ============================================================

  Widget _buildJobCell(
    List<Map<String, dynamic>> details, {
    required dynamic fallbackCount,
  }) {
    // Kalau backend belum mengirim detail,
    // tetap tampilkan jumlah pekerjaan.
    if (details.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSmallIconBox(
            icon: Icons.work_outline,
            background: const Color(0xFFFFF7ED),
            iconColor: const Color(0xFFF59E0B),
          ),

          const SizedBox(width: 8),

          Text(
            '$fallbackCount pekerjaan',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSmallIconBox(
          icon: Icons.work_outline,
          background: const Color(0xFFFFF7ED),
          iconColor: const Color(0xFFF59E0B),
        ),

        const SizedBox(width: 8),

        SizedBox(
          width: 260,
          height: 72,
          child: Scrollbar(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: details.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = details[index];

                final code =
                    item['code']?.toString() ?? '';

                final title =
                    item['title']?.toString() ??
                    item['tittle']?.toString() ??
                    'Pekerjaan tanpa judul';

                String displayText;

                if (code.isNotEmpty) {
                  displayText = '$code • $title';
                } else {
                  displayText = title;
                }

                return Text(
                  displayText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SMALL ICON BOX
  // ============================================================

  Widget _buildSmallIconBox({
    required IconData icon,
    required Color background,
    required Color iconColor,
  }) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 16,
        color: iconColor,
      ),
    );
  }

  // ============================================================
  // MOBILE REPORT CARD
  // ============================================================

  Widget _buildMobileReportCard(
    Map<String, dynamic> d,
    bool isLast,
  ) {
    final transactionDetails =
        _getTransactionDetails(d);

    final jobDetails =
        _getJobDetails(d);

    final transactions =
        d['transactions'] ?? 0;

    final jobs =
        d['jobs'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(
                  color: Color(0xFFE2E8F0),
                ),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // HARI
          // ======================================================

          Text(
            d['day']?.toString() ?? '-',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),

          const SizedBox(height: 12),

          // ======================================================
          // TRANSAKSI
          // ======================================================

          _buildMobileDetailRow(
            icon: Icons.receipt_long_outlined,
            label: 'Transaksi',
            iconColor: const Color(0xFF2563EB),
            background: const Color(0xFFEFF6FF),
            child: transactionDetails.isEmpty
                ? Text(
                    '$transactions transaksi',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  )
                : _buildMobileTransactionDetails(
                    transactionDetails,
                  ),
          ),

          const SizedBox(height: 10),

          // ======================================================
          // PEKERJAAN
          // ======================================================

          _buildMobileDetailRow(
            icon: Icons.work_outline,
            label: 'Pekerjaan',
            iconColor: const Color(0xFFD97706),
            background: const Color(0xFFFFF7ED),
            child: jobDetails.isEmpty
                ? Text(
                    '$jobs pekerjaan',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD97706),
                    ),
                  )
                : _buildMobileJobDetails(
                    jobDetails,
                  ),
          ),

          const SizedBox(height: 10),

          // ======================================================
          // KOMISI
          // ======================================================

          _buildMobileDetailRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Komisi Admin',
            iconColor: const Color(0xFF059669),
            background: const Color(0xFFECFDF5),
            child: Text(
              _formatRupiah(
                d['income'] ?? 0,
              ),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF059669),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE DETAIL ROW
  // ============================================================

  Widget _buildMobileDetailRow({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color background,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
        ),

        const SizedBox(width: 10),

        SizedBox(
          width: 90,
          child: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: child,
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE TRANSACTION DETAILS
  // ============================================================

  Widget _buildMobileTransactionDetails(
    List<Map<String, dynamic>> details,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: details.map((item) {
        final reference =
            item['reference_code']?.toString();

        final id =
            item['id']?.toString();

        final displayReference =
            reference != null &&
                    reference.isNotEmpty
                ? reference
                : id != null
                    ? 'PAY-$id'
                    : 'Transaksi';

        return Padding(
          padding: const EdgeInsets.only(
            bottom: 4,
          ),
          child: Text(
            displayReference,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2563EB),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // MOBILE JOB DETAILS
  // ============================================================

  Widget _buildMobileJobDetails(
    List<Map<String, dynamic>> details,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: details.map((item) {
        final code =
            item['code']?.toString() ?? '';

        final title =
            item['title']?.toString() ??
            item['tittle']?.toString() ??
            'Pekerjaan tanpa judul';

        final displayText =
            code.isNotEmpty
                ? '$code • $title'
                : title;

        return Padding(
          padding: const EdgeInsets.only(
            bottom: 4,
          ),
          child: Text(
            displayText,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFD97706),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // PAGINATION FULL WIDTH
  // ============================================================

  Widget _buildPaginationFullWidth() {
    final total = _dailyData.length;

    final totalPages = _totalPages;

    final startItem =
        (_currentPage - 1) * _itemsPerPage + 1;

    final endItem = (startItem + _itemsPerPage - 1).clamp(
      0,
      total,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE2E8F0),
          ),
          bottom: BorderSide(
            color: Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ========================================================
          // KIRI
          // ========================================================

          Flexible(
            child: Text(
              'Menampilkan '
              '$startItem–$endItem '
              'dari $total hari',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 16),

          // ========================================================
          // KANAN
          // ========================================================

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ====================================================
              // ITEMS PER PAGE
              // ====================================================

              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _itemsPerPage,
                    isDense: true,
                    borderRadius: BorderRadius.circular(8),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w600,
                    ),
                    items: _itemsPerPageOptions.map(
                      (n) => DropdownMenuItem<int>(
                        value: n,
                        child: Text('$n / hal'),
                      ),
                    ).toList(),
                    onChanged: (v) {
                      if (v == null) return;

                      setState(() {
                        _itemsPerPage = v;
                        _currentPage = 1;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // ====================================================
              // PREVIOUS
              // ====================================================

              _paginationIconButton(
                icon: Icons.chevron_left,
                onTap: _currentPage > 1
                    ? () => setState(
                          () => _currentPage--,
                        )
                    : null,
              ),

              const SizedBox(width: 6),

              // ====================================================
              // CURRENT PAGE
              // ====================================================

              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Hal $_currentPage / $totalPages',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // ====================================================
              // NEXT
              // ====================================================

              _paginationIconButton(
                icon: Icons.chevron_right,
                onTap: _currentPage < totalPages
                    ? () => setState(
                          () => _currentPage++,
                        )
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAGINATION BUTTON
  // ============================================================

  Widget _paginationIconButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap == null
              ? const Color(0xFFF1F5F9)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null
              ? const Color(0xFFCBD5E1)
              : const Color(0xFF334155),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFECACA),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Color(0xFFDC2626),
          ),

          const SizedBox(height: 12),

          Text(
            _errorMessage ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFDC2626),
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _loadReport,
            icon: const Icon(
              Icons.refresh,
              size: 18,
            ),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 60,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 52,
            color: Color(0xFFCBD5E1),
          ),

          SizedBox(height: 12),

          Text(
            'Belum ada transaksi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),

          SizedBox(height: 5),

          Text(
            'Belum ada transaksi pada periode ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HELPER WIDGET — HEADER TABEL
// ============================================================

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: Color(0xFF64748B),
      ),
    );
  }
}