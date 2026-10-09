import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/monthly_earning_model.dart';
import '../../services/api_service.dart';

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

  MonthlyEarningSummary? _summary;
  List<MonthlyEarningModel> _monthly = [];

  // ============================================================
  // DESIGN TOKENS — disamakan dengan DashboardHeader / PaymentScreen
  // ============================================================

  static const Color _accent = Color(0xFFF97316);
  static const Color _tableBorder = Color(0xFFE5E7EB);
  static const Color _tableDivider = Color(0xFFF3F4F6);
  static const Color _headerText = Color(0xFF6B7280);
  static const Color _cellText = Color(0xFF111827);

  static const double _gapAfterHeader = 16;
  static const double _gapBetweenSections = 16;
  static const double _cardRadius = 14;
  static const double _smallRadius = 12;

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

  // ============================================================
  // BUILD
  // ============================================================
  // ✅ Padding horizontal mobile 16 / tablet 24 / desktop 28
  // ✅ Header pakai textTheme
  // ✅ Tidak ada Center + ConstrainedBox — konten nempel kiri
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
  // HEADER — sama persis dgn DashboardHeader
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Penghasilan',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pantau pendapatan dari pekerjaan yang telah selesai.',
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY CARDS — 3 SEJAJAR (mobile & web)
  // ============================================================

  Widget _buildSummaryCards({required bool isMobile}) {
    final s = _summary;
    final gap = isMobile ? 8.0 : 16.0;

    final cards = [
      _summaryCard(
        title: isMobile ? 'Total' : 'Total Penghasilan',
        value: formatRupiah(s?.totalPendapatan ?? 0),
        subtitle:
            isMobile ? 'Akumulasi' : 'Akumulasi $_monthsCount bulan',
        icon: Icons.account_balance_wallet_outlined,
        iconColor: _accent,
        isCompact: isMobile,
      ),
      _summaryCard(
        title: isMobile ? 'Selesai' : 'Pekerjaan Selesai',
        value: '${s?.totalPekerjaan ?? 0}',
        subtitle: isMobile ? 'Pekerjaan' : 'Total pekerjaan',
        icon: Icons.check_circle_outline,
        iconColor: const Color(0xFF16A34A),
        isCompact: isMobile,
      ),
      _summaryCard(
        title: isMobile ? 'Rata-rata' : 'Rata-rata Penghasilan',
        value: formatRupiah(s?.rataRataPerBulan ?? 0),
        subtitle: 'Per bulan',
        icon: Icons.trending_up,
        iconColor: const Color(0xFF2563EB),
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
            width: isCompact ? 34 : 42,
            height: isCompact ? 34 : 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(isCompact ? 9 : 11),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: isCompact ? 17 : 21,
            ),
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
                    color: const Color(0xFF64748B),
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
                    color: const Color(0xFF0F172A),
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
                      color: Color(0xFF94A3B8),
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

  Widget _buildChartCard(
    BuildContext context, {
    required bool isMobile,
  }) {
    final incomeData = _monthly.map((m) => m.totalPendapatan).toList();
    final maxIncome = incomeData.isEmpty
        ? 1000000.0
        : incomeData.reduce((a, b) => a > b ? a : b);

    final maxY = (maxIncome / 500000).ceil() * 500000.0;
    final safeMaxY = maxY <= 0 ? 1000000.0 : maxY;

    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 22),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grafik Penghasilan',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _cellText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isMobile
                          ? 'Perkembangan per bulan'
                          : 'Perkembangan penghasilan setiap bulan',
                      style: textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
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
                  color: const Color(0xFFF9FAFB),
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
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _cellText,
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
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: _tableDivider,
                    strokeWidth: 1,
                  ),
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
                              color: Color(0xFF94A3B8),
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
                              color: Color(0xFF94A3B8),
                            ),
                          );
                        }
                        return Text(
                          '${(value / 1000000).toStringAsFixed(1)}jt',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
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
                          color: Colors.white,
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
                          _accent.withOpacity(0.2),
                          _accent.withOpacity(0.02),
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
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _tableBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Penghasilan Bulanan',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _cellText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Rincian per bulan',
            style: textTheme.bodySmall?.copyWith(
              color: const Color(0xFF64748B),
            ),
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
              color: _accent.withOpacity(0.12),
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
                    color: const Color(0xFF94A3B8),
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
              color: const Color(0xFF16A34A),
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
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFDC2626),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Error',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFDC2626),
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
              color: _accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bar_chart_outlined,
              size: 34,
              color: _accent.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum ada data penghasilan.',
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