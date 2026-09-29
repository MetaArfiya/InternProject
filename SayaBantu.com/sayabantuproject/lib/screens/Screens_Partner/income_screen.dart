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
  // DESIGN TOKENS
  // ============================================================

  static const Color _accent = Color(0xFFF97316);
  static const Color _bg = Color(0xFFF5F7FB);
  static const Color _border = Color(0xFFE5E7EB);

  static const double _mobileBreakpoint = 700;
  static const double _tabletBreakpoint = 1100;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: _accent,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isMobile = width < _mobileBreakpoint;
              final isTablet =
                  width >= _mobileBreakpoint && width < _tabletBreakpoint;

              final horizontalPadding =
                  isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
              final verticalPadding = isMobile ? 16.0 : 28.0;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(isMobile),
                        SizedBox(height: isMobile ? 18 : 24),

                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 80),
                              child: CircularProgressIndicator(color: _accent),
                            ),
                          )
                        else if (_error != null)
                          _buildError()
                        else if (_monthly.isEmpty)
                          _buildEmptyState()
                        else ...[
                          _buildSummaryCards(isMobile: isMobile),
                          SizedBox(height: isMobile ? 20 : 24),
                          _buildChartCard(isMobile: isMobile),
                          SizedBox(height: isMobile ? 20 : 24),
                          _buildRecentIncomeCard(isMobile: isMobile),
                          const SizedBox(height: 28),
                        ],
                      ],
                    ),
                  ),
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

  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Penghasilan',
          style: TextStyle(
            fontSize: isMobile ? 22 : 26,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pantau pendapatan dari pekerjaan yang telah selesai.',
          style: TextStyle(
            fontSize: isMobile ? 12.5 : 13,
            color: const Color(0xFF64748B),
            height: 1.4,
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

    return SizedBox(
      height: isMobile ? 110 : 130,
      child: Row(
        children: [
          Expanded(
            child: _summaryCard(
              title: isMobile ? 'Total' : 'Total Penghasilan',
              value: formatRupiah(s?.totalPendapatan ?? 0),
              subtitle: isMobile ? 'Akumulasi' : 'Akumulasi $_monthsCount bulan',
              icon: Icons.account_balance_wallet_outlined,
              iconColor: _accent,
              isCompact: isMobile,
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: _summaryCard(
              title: isMobile ? 'Selesai' : 'Pekerjaan Selesai',
              value: '${s?.totalPekerjaan ?? 0}',
              subtitle: isMobile ? 'Pekerjaan' : 'Total pekerjaan',
              icon: Icons.check_circle_outline,
              iconColor: const Color(0xFF16A34A),
              isCompact: isMobile,
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: _summaryCard(
              title: isMobile ? 'Rata-rata' : 'Rata-rata Penghasilan',
              value: formatRupiah(s?.rataRataPerBulan ?? 0),
              subtitle: isMobile ? 'Per bulan' : 'Per bulan',
              icon: Icons.trending_up,
              iconColor: const Color(0xFF2563EB),
              isCompact: isMobile,
            ),
          ),
        ],
      ),
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
      padding: EdgeInsets.all(isCompact ? 10 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: isCompact ? 28 : 38,
            height: isCompact ? 28 : 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(isCompact ? 7 : 10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: isCompact ? 15 : 20,
            ),
          ),
          SizedBox(height: isCompact ? 6 : 10),

          // Value
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isCompact ? 13 : 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              height: 1.1,
            ),
          ),
          SizedBox(height: isCompact ? 2 : 4),

          // Title
          Text(
            title,
            maxLines: 1,
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
  // CHART CARD
  // ============================================================

  Widget _buildChartCard({required bool isMobile}) {
    final incomeData = _monthly.map((m) => m.totalPendapatan).toList();
    final maxIncome = incomeData.isEmpty
        ? 1000000.0
        : incomeData.reduce((a, b) => a > b ? a : b);

    final maxY = (maxIncome / 500000).ceil() * 500000.0;
    final safeMaxY = maxY <= 0 ? 1000000.0 : maxY;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
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
                      style: TextStyle(
                        fontSize: isMobile ? 15 : 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isMobile
                          ? 'Perkembangan per bulan'
                          : 'Perkembangan penghasilan setiap bulan',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
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
                  border: Border.all(color: _border),
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
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
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
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: const Color(0xFFF3F4F6),
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

  Widget _buildRecentIncomeCard({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Penghasilan Bulanan',
            style: TextStyle(
              fontSize: isMobile ? 15 : 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Rincian per bulan',
            style: TextStyle(
              fontSize: 12,
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
                    child: Divider(height: 1, color: Color(0xFFF3F4F6)),
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
              borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
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
                    color: const Color(0xFF111827),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 48),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
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
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ],
      ),
    );
  }
}