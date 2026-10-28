import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/admin_theme_provider.dart';
import '../../theme/app_colors.dart';

class AdminDailyReportScreen extends StatefulWidget {
  const AdminDailyReportScreen({super.key});

  @override
  State<AdminDailyReportScreen> createState() =>
      _AdminDailyReportScreenState();
}

class _AdminDailyReportScreenState extends State<AdminDailyReportScreen> {
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

  String _periodKey = 'week'; // today | week | month
  String _chartKey = 'transactions'; // transactions | income | jobs

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
      final list = decoded['data'] is List ? decoded['data'] as List : [];

      setState(() {
        _dailyData = list
            .whereType<Map>()
            .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e),
            )
            .toList();

        _totalTransactions =
            int.tryParse(s['total_transaksi']?.toString() ?? '0') ?? 0;
        _totalJobs =
            int.tryParse(s['total_pekerjaan']?.toString() ?? '0') ?? 0;
        _totalIncome =
            double.tryParse(s['total_komisi']?.toString() ?? '0') ?? 0;
        _averageIncome =
            double.tryParse(s['rata_harian']?.toString() ?? '0') ?? 0;

        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ ERROR DAILY REPORT: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan saat memuat laporan.';
      });
    }
  }

  // ============================================================
  // FORMAT RUPIAH
  // ============================================================

  String _formatRupiah(dynamic amount) {
    final num value =
        amount is num ? amount : (num.tryParse(amount.toString()) ?? 0);
    final intValue = value.toInt();

    final reversed = intValue.toString().split('').reversed.toList();
    final chunks = <String>[];

    for (int i = 0; i < reversed.length; i += 3) {
      final chunk = reversed.skip(i).take(3).toList().reversed.join();
      chunks.add(chunk);
    }

    return 'Rp${chunks.reversed.join('.')}';
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  int get _totalPages {
    final total = _dailyData.length;
    if (total == 0) return 1;
    return ((total - 1) ~/ _itemsPerPage) + 1;
  }

  List<Map<String, dynamic>> get _paginatedData {
    final start = (_currentPage - 1) * _itemsPerPage;
    if (start >= _dailyData.length) return [];
    final end = (start + _itemsPerPage).clamp(0, _dailyData.length);
    return _dailyData.sublist(start, end);
  }

  List<Map<String, dynamic>> _getTransactionDetails(
    Map<String, dynamic> d,
  ) {
    final raw = d['transaction_details'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }

  List<Map<String, dynamic>> _getJobDetails(Map<String, dynamic> d) {
    final raw = d['job_details'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }

  String _xmlEscape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  String _excelColumn(int index) {
    var n = index + 1;
    var result = '';
    while (n > 0) {
      final remainder = (n - 1) % 26;
      result = String.fromCharCode(65 + remainder) + result;
      n = (n - remainder - 1) ~/ 26;
    }
    return result;
  }

  String _worksheetXml(List<List<Object?>> rows) {
    final buffer = StringBuffer('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>''');
    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      buffer.write('<row r="${rowIndex + 1}">');
      for (var colIndex = 0; colIndex < rows[rowIndex].length; colIndex++) {
        final value = rows[rowIndex][colIndex];
        final reference = '${_excelColumn(colIndex)}${rowIndex + 1}';
        if (value is num) {
          buffer.write('<c r="$reference"><v>$value</v></c>');
        } else {
          buffer.write('<c r="$reference" t="inlineStr"><is><t xml:space="preserve">${_xmlEscape(value?.toString() ?? '')}</t></is></c>');
        }
      }
      buffer.write('</row>');
    }
    buffer.write('</sheetData></worksheet>');
    return buffer.toString();
  }

  void _exportExcel() {
    if (_dailyData.isEmpty) return;
    final period = _periodOptions.firstWhere((item) => item['value'] == _periodKey)['label']!;
    final summaryRows = <List<Object?>>[
      ['Laporan Admin SayaBantu'],
      ['Periode', period],
      ['Tanggal Ekspor', DateTime.now().toLocal().toString().split('.').first],
      ['Total Transaksi', _totalTransactions],
      ['Total Pekerjaan', _totalJobs],
      ['Total Komisi Admin (Rp)', _totalIncome],
      ['Rata-rata Komisi Harian (Rp)', _averageIncome],
    ];
    final detailRows = <List<Object?>>[
      ['Tanggal', 'Jumlah Transaksi', 'Referensi Transaksi', 'Jumlah Pekerjaan', 'Rincian Pekerjaan', 'Komisi Admin (Rp)'],
    ];
    for (final day in _dailyData) {
      final transactions = _getTransactionDetails(day)
          .map((item) => item['reference_code']?.toString() ?? '-')
          .join(', ');
      final jobs = _getJobDetails(day)
          .map((item) => item['title']?.toString() ?? item['tittle']?.toString() ?? item['code']?.toString() ?? '-')
          .join(', ');
      detailRows.add([
        day['day']?.toString() ?? '-',
        (day['transactions'] as num?)?.toInt() ?? 0,
        transactions,
        (day['jobs'] as num?)?.toInt() ?? 0,
        jobs,
        (day['income'] as num?)?.toDouble() ?? 0,
      ]);
    }

    final archive = Archive()
      ..addFile(ArchiveFile.bytes('[Content_Types].xml', Uint8List.fromList(utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/><Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>'''))))
      ..addFile(ArchiveFile.bytes('_rels/.rels', Uint8List.fromList(utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>'''))))
      ..addFile(ArchiveFile.bytes('xl/workbook.xml', Uint8List.fromList(utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Ringkasan" sheetId="1" r:id="rId1"/><sheet name="Rincian Harian" sheetId="2" r:id="rId2"/></sheets></workbook>'''))))
      ..addFile(ArchiveFile.bytes('xl/_rels/workbook.xml.rels', Uint8List.fromList(utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/></Relationships>'''))))
      ..addFile(ArchiveFile.bytes('xl/worksheets/sheet1.xml', Uint8List.fromList(utf8.encode(_worksheetXml(summaryRows)))))
      ..addFile(ArchiveFile.bytes('xl/worksheets/sheet2.xml', Uint8List.fromList(utf8.encode(_worksheetXml(detailRows)))));

    final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
    final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final date = DateTime.now().toLocal().toIso8601String().substring(0, 10);
    html.AnchorElement(href: url)
      ..download = 'laporan_admin_${_periodKey}_$date.xlsx'
      ..click();
    html.Url.revokeObjectUrl(url);
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
        onRefresh: _loadReport,
        color: t.accent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < _mobileBreakpoint;
            final isTablet = width >= _mobileBreakpoint && width < 1100;

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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: CircularProgressIndicator(color: t.accent),
                      ),
                    )
                  else if (_errorMessage != null)
                    _buildError()
                  else ...[
                    _buildSummarySection(isMobile),
                    const SizedBox(height: _gapBetweenSections),
                    _buildPeriodFilter(isMobile),
                    const SizedBox(height: _gapBetweenSections),

                    if (_dailyData.isEmpty)
                      _buildEmptyState()
                    else ...[
                      // ── Mobile: 1 chart dengan selector
                      // ── Desktop: 3 chart sekaligus
                      if (isMobile)
                        _buildMobileChartSection()
                      else ...[
                        _buildBarChart(
                          isMobile: false,
                          title: 'Grafik Transaksi',
                          subtitle: 'Jumlah transaksi berdasarkan hari',
                          values: _dailyData
                              .map<double>((d) =>
                                  (d['transactions'] as num?)?.toDouble() ??
                                  0)
                              .toList(),
                          labels: _dailyData
                              .map<String>((d) => d['day'].toString())
                              .toList(),
                          valueSuffix: 'transaksi',
                          barColor: AppColors.infoBlue,
                        ),
                        const SizedBox(height: _gapBetweenSections),
                        _buildBarChart(
                          isMobile: false,
                          title: 'Grafik Komisi Admin',
                          subtitle: 'Total komisi admin sebesar 15%',
                          values: _dailyData
                              .map<double>((d) =>
                                  (d['income'] as num?)?.toDouble() ?? 0)
                              .toList(),
                          labels: _dailyData
                              .map<String>((d) => d['day'].toString())
                              .toList(),
                          valueSuffix: 'Rp',
                          barColor: t.success,
                        ),
                        const SizedBox(height: _gapBetweenSections),
                        _buildBarChart(
                          isMobile: false,
                          title: 'Grafik Pekerjaan',
                          subtitle:
                              'Jumlah pekerjaan yang diselesaikan',
                          values: _dailyData
                              .map<double>((d) =>
                                  (d['jobs'] as num?)?.toDouble() ?? 0)
                              .toList(),
                          labels: _dailyData
                              .map<String>((d) => d['day'].toString())
                              .toList(),
                          valueSuffix: 'pekerjaan',
                          barColor: t.warning,
                        ),
                        const SizedBox(height: _gapBetweenSections),
                      ],

                      _buildReportTable(isMobile),
                      const SizedBox(height: _gapBetweenSections),
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
          'Laporan Harian',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: t.cellText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pantau aktivitas transaksi, pekerjaan, dan pendapatan komisi admin.',
          style: textTheme.bodyMedium?.copyWith(color: t.mutedText),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY (Mobile: 2x2, Desktop: 1x4)
  // ============================================================

  Widget _buildSummarySection(bool isMobile) {
    final t = theme;
    final cards = [
      _summaryCard(
        title: 'Total Transaksi',
        value: '$_totalTransactions',
        icon: Icons.receipt_long_outlined,
        color: AppColors.infoBlue,
      ),
      _summaryCard(
        title: 'Total Pekerjaan',
        value: '$_totalJobs',
        icon: Icons.work_outline,
        color: t.warning,
      ),
      _summaryCard(
        title: 'Total Komisi',
        value: _formatRupiah(_totalIncome),
        icon: Icons.account_balance_wallet_outlined,
        color: t.success,
      ),
      _summaryCard(
        title: 'Rata-rata Harian',
        value: _formatRupiah(_averageIncome),
        icon: Icons.analytics_outlined,
        color: AppColors.purple,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 10),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 10),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i != cards.length - 1) const SizedBox(width: 16),
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
            child: Icon(icon, color: color, size: 19),
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
                    fontSize: 16,
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
  // PERIOD FILTER (Mobile: vertikal, Desktop: horizontal)
  // ============================================================

  Widget _buildPeriodFilter(bool isMobile) {
    final t = theme;

    if (isMobile) {
      // ── Mobile: label di atas, dropdown full-width
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(_cardRadius),
          border: Border.all(color: t.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  size: 16,
                  color: t.headerText,
                ),
                const SizedBox(width: 6),
                Text(
                  'Filter Periode',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: t.mutedText,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.infoBlue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_dailyData.length} hari',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.infoBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildPeriodDropdown(fullWidth: true),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: _buildExportButton()),
          ],
        ),
      );
    }

    // ── Desktop/Tablet: horizontal
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: t.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_list_rounded,
            size: 18,
            color: t.headerText,
          ),
          const SizedBox(width: 8),
          Text(
            'Filter Periode:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: t.mutedText,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 160,
            child: _buildPeriodDropdown(),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.infoBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_dailyData.length} hari',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.infoBlue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildExportButton(),
        ],
      ),
    );
  }

  Widget _buildExportButton() => FilledButton.icon(
        onPressed: _dailyData.isEmpty ? null : _exportExcel,
        icon: const Icon(Icons.download_outlined, size: 18),
        label: const Text('Export Excel'),
      );

  Widget _buildPeriodDropdown({bool fullWidth = false}) {
    final t = theme;

    final dropdown = DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _periodKey,
        isExpanded: true,
        borderRadius: BorderRadius.circular(_radius),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: t.headerText,
          size: 18,
        ),
        style: TextStyle(
          fontSize: 13,
          color: t.cellText,
          fontWeight: FontWeight.w500,
        ),
        items: _periodOptions.map((p) {
          return DropdownMenuItem<String>(
            value: p['value'],
            child: Text(p['label']!),
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
    );

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: t.border),
      ),
      child: fullWidth
          ? dropdown
          : Align(alignment: Alignment.centerLeft, child: dropdown),
    );
  }

  // ============================================================
  // MOBILE CHART — 1 chart dengan selector
  // ============================================================

  Widget _buildMobileChartSection() {
    final t = theme;

    // Map chart key → data
    List<double> values;
    List<String> labels;
    String valueSuffix;
    Color barColor;
    String title;
    String subtitle;

    switch (_chartKey) {
      case 'income':
        title = 'Komisi Admin';
        subtitle = 'Total komisi admin 15%';
        values = _dailyData
            .map<double>((d) => (d['income'] as num?)?.toDouble() ?? 0)
            .toList();
        labels =
            _dailyData.map<String>((d) => d['day'].toString()).toList();
        valueSuffix = 'Rp';
        barColor = t.success;
        break;
      case 'jobs':
        title = 'Pekerjaan';
        subtitle = 'Jumlah pekerjaan selesai';
        values = _dailyData
            .map<double>((d) => (d['jobs'] as num?)?.toDouble() ?? 0)
            .toList();
        labels =
            _dailyData.map<String>((d) => d['day'].toString()).toList();
        valueSuffix = 'pekerjaan';
        barColor = t.warning;
        break;
      default:
        title = 'Transaksi';
        subtitle = 'Jumlah transaksi berdasarkan hari';
        values = _dailyData
            .map<double>(
                (d) => (d['transactions'] as num?)?.toDouble() ?? 0)
            .toList();
        labels =
            _dailyData.map<String>((d) => d['day'].toString()).toList();
        valueSuffix = 'transaksi';
        barColor = AppColors.infoBlue;
    }

    return Column(
      children: [
        // ── Chart selector chips
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _chartChip(
                label: 'Transaksi',
                icon: Icons.receipt_long_outlined,
                color: AppColors.infoBlue,
                isActive: _chartKey == 'transactions',
                onTap: () => setState(() => _chartKey = 'transactions'),
              ),
              const SizedBox(width: 8),
              _chartChip(
                label: 'Komisi',
                icon: Icons.account_balance_wallet_outlined,
                color: t.success,
                isActive: _chartKey == 'income',
                onTap: () => setState(() => _chartKey = 'income'),
              ),
              const SizedBox(width: 8),
              _chartChip(
                label: 'Pekerjaan',
                icon: Icons.work_outline,
                color: t.warning,
                isActive: _chartKey == 'jobs',
                onTap: () => setState(() => _chartKey = 'jobs'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Chart
        _buildBarChart(
          isMobile: true,
          title: title,
          subtitle: subtitle,
          values: values,
          labels: labels,
          valueSuffix: valueSuffix,
          barColor: barColor,
        ),
      ],
    );
  }

  Widget _chartChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final t = theme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? color : t.border,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? AppColors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.white : t.cellText,
              ),
            ),
          ],
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
    final t = theme;
    if (values.isEmpty) return const SizedBox.shrink();

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final chartHeight = isMobile ? 200.0 : 240.0;
    final maxBarHeight = chartHeight - 60;
    final barWidth = isMobile ? 56.0 : 80.0;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: t.cellText,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: t.mutedText,
                ),
          ),
          const SizedBox(height: 16),

          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth > 36
                  ? constraints.maxWidth - 36
                  : 0.0;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: availableWidth),
                  child: SizedBox(
                    height: chartHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(values.length, (index) {
                        final value = values[index];
                        final height = maxValue == 0
                            ? 0.0
                            : (value / maxValue) * maxBarHeight;

                        return Container(
                          width: barWidth,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 6),
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
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: t.cellText,
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
                                      barColor.withValues(alpha: 0.6),
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
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: t.mutedText,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REPORT TABLE
  // ============================================================

  Widget _buildReportTable(bool isMobile) {
    final t = theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rincian Laporan',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: t.cellText,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_dailyData.length} hari ditampilkan',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: t.mutedText,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: t.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: isMobile
              ? Column(
                  children: _paginatedData.asMap().entries.map((entry) {
                    final isLast =
                        entry.key == _paginatedData.length - 1;
                    return _buildMobileReportCard(entry.value, isLast);
                  }).toList(),
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
    final t = theme;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(AppColors.grey50),
              headingRowHeight: 48,
              dataRowMinHeight: 82,
              dataRowMaxHeight: 150,
              columnSpacing: 24,
              horizontalMargin: 20,
              dividerThickness: 1,
              showBottomBorder: true,
              headingTextStyle:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: t.headerText,
                      ),
              columns: const [
                DataColumn(label: _TableHeader('HARI')),
                DataColumn(label: _TableHeader('TRANSAKSI')),
                DataColumn(label: _TableHeader('PEKERJAAN')),
                DataColumn(label: _TableHeader('KOMISI ADMIN')),
              ],
              rows: _paginatedData.map((d) {
                final transactionDetails = _getTransactionDetails(d);
                final jobDetails = _getJobDetails(d);

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        d['day']?.toString() ?? '-',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: t.cellText,
                        ),
                      ),
                    ),
                    DataCell(
                      _buildTransactionCell(
                        transactionDetails,
                        fallbackCount: d['transactions'] ?? 0,
                      ),
                    ),
                    DataCell(
                      _buildJobCell(
                        jobDetails,
                        fallbackCount: d['jobs'] ?? 0,
                      ),
                    ),
                    DataCell(
                      Text(
                        _formatRupiah(d['income'] ?? 0),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: t.success,
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

  Widget _buildTransactionCell(
    List<Map<String, dynamic>> details, {
    required dynamic fallbackCount,
  }) {
    final t = theme;
    if (details.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSmallIconBox(
            icon: Icons.receipt_long_outlined,
            background: AppColors.infoBlue.withValues(alpha: 0.12),
            iconColor: AppColors.infoBlue,
          ),
          const SizedBox(width: 8),
          Text(
            '$fallbackCount transaksi',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: t.cellText,
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
          background: AppColors.infoBlue.withValues(alpha: 0.12),
          iconColor: AppColors.infoBlue,
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 180,
          height: 72,
          child: Scrollbar(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: details.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = details[index];
                final reference = item['reference_code']?.toString();
                final id = item['id']?.toString();

                final displayReference =
                    reference != null && reference.isNotEmpty
                        ? reference
                        : id != null
                            ? 'PAY-$id'
                            : 'Transaksi';

                return Text(
                  displayReference,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: t.cellText,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJobCell(
    List<Map<String, dynamic>> details, {
    required dynamic fallbackCount,
  }) {
    final t = theme;
    if (details.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSmallIconBox(
            icon: Icons.work_outline,
            background: t.warning.withValues(alpha: 0.12),
            iconColor: t.warning,
          ),
          const SizedBox(width: 8),
          Text(
            '$fallbackCount pekerjaan',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: t.cellText,
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
          background: t.warning.withValues(alpha: 0.12),
          iconColor: t.warning,
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 260,
          height: 72,
          child: Scrollbar(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: details.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = details[index];
                final code = item['code']?.toString() ?? '';
                final title = item['title']?.toString() ??
                    item['tittle']?.toString() ??
                    'Pekerjaan tanpa judul';

                final displayText =
                    code.isNotEmpty ? '$code • $title' : title;

                return Text(
                  displayText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: t.cellText,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

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
      child: Icon(icon, size: 16, color: iconColor),
    );
  }

  // ============================================================
  // MOBILE REPORT CARD (dipadatkan)
  // ============================================================

  Widget _buildMobileReportCard(
    Map<String, dynamic> d,
    bool isLast,
  ) {
    final t = theme;
    final transactionDetails = _getTransactionDetails(d);
    final jobDetails = _getJobDetails(d);

    final transactions = d['transactions'] ?? 0;
    final jobs = d['jobs'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: t.divider),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tanggal + komisi
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: t.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  d['day']?.toString() ?? '-',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: t.accent,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatRupiah(d['income'] ?? 0),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: t.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Transaksi
          _buildMobileInfoRow(
            icon: Icons.receipt_long_outlined,
            iconColor: AppColors.infoBlue,
            label: 'Transaksi',
            value: transactionDetails.isEmpty
                ? '$transactions'
                : '${transactionDetails.length}',
            valueColor: AppColors.infoBlue,
          ),

          if (transactionDetails.isNotEmpty)
            _buildMobileListDetails(
              transactionDetails,
              (item) {
                final reference = item['reference_code']?.toString();
                final id = item['id']?.toString();
                return reference != null && reference.isNotEmpty
                    ? reference
                    : id != null
                        ? 'PAY-$id'
                        : 'Transaksi';
              },
              AppColors.infoBlue,
            ),

          const SizedBox(height: 8),

          // Pekerjaan
          _buildMobileInfoRow(
            icon: Icons.work_outline,
            iconColor: t.warning,
            label: 'Pekerjaan',
            value: jobDetails.isEmpty ? '$jobs' : '${jobDetails.length}',
            valueColor: t.warning,
          ),

          if (jobDetails.isNotEmpty)
            _buildMobileListDetails(
              jobDetails,
              (item) {
                final code = item['code']?.toString() ?? '';
                final title = item['title']?.toString() ??
                    item['tittle']?.toString() ??
                    'Pekerjaan';
                return code.isNotEmpty ? '$code • $title' : title;
              },
              t.warning,
            ),
        ],
      ),
    );
  }

  Widget _buildMobileInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    final t = theme;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: t.mutedText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileListDetails(
    List<Map<String, dynamic>> details,
    String Function(Map<String, dynamic>) formatter,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 38, top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: details.take(3).map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: [
                Icon(Icons.circle, size: 5, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    formatter(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList() +
            (details.length > 3
                ? [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '+ ${details.length - 3} lainnya',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
                          color: color.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ]
                : []),
      ),
    );
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  Widget _buildPagination(bool isMobile) {
    final t = theme;
    final total = _dailyData.length;
    final totalPages = _totalPages;

    final startItem =
        total == 0 ? 0 : (_currentPage - 1) * _itemsPerPage + 1;
    final endItem = (startItem + _itemsPerPage - 1).clamp(0, total);

    return Container(
      width: double.infinity,
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
                  'Menampilkan $startItem–$endItem dari $total hari',
                  style: TextStyle(
                    fontSize: 12,
                    color: t.headerText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Rows per page
                    Container(
                      height: 34,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10),
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
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: t.headerText,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: t.cellText,
                            fontWeight: FontWeight.w600,
                          ),
                          items: _itemsPerPageOptions
                              .map(
                                (n) => DropdownMenuItem<int>(
                                  value: n,
                                  child: Text('$n'),
                                ),
                              )
                              .toList(),
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
                    const Spacer(),
                    _paginationIconButton(
                      icon: Icons.chevron_left,
                      onTap: _currentPage > 1
                          ? () => setState(() => _currentPage--)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 32,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: t.accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_currentPage / $totalPages',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: t.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _paginationIconButton(
                      icon: Icons.chevron_right,
                      onTap: _currentPage < totalPages
                          ? () => setState(() => _currentPage++)
                          : null,
                    ),
                  ],
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'Menampilkan $startItem–$endItem dari $total hari',
                    style: TextStyle(
                      fontSize: 12,
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
                    Container(
                      height: 34,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10),
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
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: t.headerText,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: t.cellText,
                            fontWeight: FontWeight.w600,
                          ),
                          items: _itemsPerPageOptions
                              .map(
                                (n) => DropdownMenuItem<int>(
                                  value: n,
                                  child: Text('$n / hal'),
                                ),
                              )
                              .toList(),
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
                    _paginationIconButton(
                      icon: Icons.chevron_left,
                      onTap: _currentPage > 1
                          ? () => setState(() => _currentPage--)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 32,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: t.accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Hal $_currentPage / $totalPages',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: t.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _paginationIconButton(
                      icon: Icons.chevron_right,
                      onTap: _currentPage < totalPages
                          ? () => setState(() => _currentPage++)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _paginationIconButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final t = theme;
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: onTap == null ? t.border : AppColors.grey300,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: onTap == null ? AppColors.grey300 : AppColors.grey700,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    final t = theme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: t.danger.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: t.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: t.danger, size: 48),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: t.danger,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadReport,
            icon: const Icon(Icons.refresh, size: 18),
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

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final t = theme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
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
              Icons.bar_chart_outlined,
              size: 34,
              color: t.accent.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Belum ada transaksi',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: t.mutedText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Belum ada transaksi pada periode ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.grey400,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HELPER
// ============================================================

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = AdminThemeProvider.of(context);
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: t.headerText,
          ),
    );
  }
}
