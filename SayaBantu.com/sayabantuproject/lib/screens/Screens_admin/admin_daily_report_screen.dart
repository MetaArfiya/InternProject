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
  String _selectedPeriod = 'Minggu Ini';
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

      final s = decoded['summary'] ?? {};
      final list = (decoded['data'] is List) ? decoded['data'] as List : [];

      setState(() {
        _dailyData = list
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();

        _totalTransactions = int.tryParse(s['total_transaksi']?.toString() ?? '0') ?? 0;
        _totalJobs = int.tryParse(s['total_pekerjaan']?.toString() ?? '0') ?? 0;
        _totalIncome = double.tryParse(s['total_komisi']?.toString() ?? '0') ?? 0;
        _averageIncome = double.tryParse(s['rata_harian']?.toString() ?? '0') ?? 0;

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
    final num value = amount is num ? amount : (num.tryParse(amount.toString()) ?? 0);
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
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return RefreshIndicator(
          onRefresh: _loadReport,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================================
                // HEADER
                // ==========================================
                const Text(
                  'Laporan Harian',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pantau aktivitas transaksi, pekerjaan, dan pendapatan komisi admin.',
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),

                // ==========================================
                // LOADING / ERROR / CONTENT
                // ==========================================
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: CircularProgressIndicator(color: Colors.orange),
                    ),
                  )
                else if (_errorMessage != null)
                  _buildError()
                else ...[
                  _buildSummarySection(isMobile),
                  const SizedBox(height: 24),
                  _buildPeriodFilter(),
                  const SizedBox(height: 24),
                  if (_dailyData.isEmpty)
                    _buildEmptyState()
                  else ...[
                    _buildBarChart(
                      title: 'Grafik Transaksi',
                      subtitle: 'Jumlah transaksi berdasarkan hari',
                      values: _dailyData
                          .map<double>((d) => (d['transactions'] as num).toDouble())
                          .toList(),
                      labels: _dailyData.map<String>((d) => d['day'].toString()).toList(),
                      valueSuffix: 'transaksi',
                    ),
                    const SizedBox(height: 20),
                    _buildBarChart(
                      title: 'Grafik Komisi Admin',
                      subtitle: 'Total komisi admin sebesar 15%',
                      values: _dailyData
                          .map<double>((d) => (d['income'] as num).toDouble())
                          .toList(),
                      labels: _dailyData.map<String>((d) => d['day'].toString()).toList(),
                      valueSuffix: 'Rp',
                    ),
                    const SizedBox(height: 20),
                    _buildBarChart(
                      title: 'Grafik Pekerjaan',
                      subtitle: 'Jumlah pekerjaan yang diselesaikan',
                      values: _dailyData
                          .map<double>((d) => (d['jobs'] as num).toDouble())
                          .toList(),
                      labels: _dailyData.map<String>((d) => d['day'].toString()).toList(),
                      valueSuffix: 'pekerjaan',
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Rincian Laporan',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildReportTable(),
                  ],
                ],
              ],
            ),
          ),
        );
      },
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
        color: Colors.blue,
      ),
      _summaryCard(
        title: 'Total Pekerjaan',
        value: '$_totalJobs',
        icon: Icons.work_outline,
        color: Colors.orange,
      ),
      _summaryCard(
        title: 'Total Komisi Admin',
        value: _formatRupiah(_totalIncome),
        icon: Icons.account_balance_wallet_outlined,
        color: Colors.green,
      ),
      _summaryCard(
        title: 'Rata-rata Harian',
        value: _formatRupiah(_averageIncome),
        icon: Icons.analytics_outlined,
        color: Colors.purple,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          for (final c in cards) ...[c, const SizedBox(height: 12)],
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 12),
        Expanded(child: cards[1]),
        const SizedBox(width: 12),
        Expanded(child: cards[2]),
        const SizedBox(width: 12),
        Expanded(child: cards[3]),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 27),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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
  // PERIOD FILTER
  // ============================================================
  Widget _buildPeriodFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range_outlined),
          const SizedBox(width: 10),
          const Text(
            'Periode Laporan:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 15),
          SizedBox(
            width: 170,
            child: DropdownButtonFormField<String>(
              value: _periodKey,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
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
                  _selectedPeriod = _periodOptions
                      .firstWhere((e) => e['value'] == value)['label']!;
                });
                _loadReport();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BAR CHART
  // ============================================================
  Widget _buildBarChart({
    required String title,
    required String subtitle,
    required List<double> values,
    required List<String> labels,
    required String valueSuffix,
  }) {
    if (values.isEmpty) return const SizedBox.shrink();

    final maxValue = values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.65),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 25),
          SizedBox(
            height: 250,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (index) {
                final value = values[index];
                final height = maxValue == 0 ? 0.0 : (value / maxValue) * 185;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          valueSuffix == 'Rp'
                              ? _formatRupiah(value)
                              : value.toInt().toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          height: height,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.75),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          labels[index],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REPORT TABLE
  // ============================================================
  Widget _buildReportTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.4),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 35,
          headingRowColor: MaterialStateProperty.all(
            Theme.of(context).colorScheme.surface,
          ),
          columns: const [
            DataColumn(label: Text('Hari')),
            DataColumn(label: Text('Transaksi')),
            DataColumn(label: Text('Pekerjaan')),
            DataColumn(label: Text('Komisi Admin')),
          ],
          rows: _dailyData.map((d) {
            return DataRow(
              cells: [
                DataCell(Text(d['day']?.toString() ?? '-')),
                DataCell(Text('${d['transactions'] ?? 0}')),
                DataCell(Text('${d['jobs'] ?? 0}')),
                DataCell(Text(_formatRupiah(d['income'] ?? 0))),
              ],
            );
          }).toList(),
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
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadReport,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.bar_chart_outlined, size: 55, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'Belum ada transaksi pada periode ini.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}