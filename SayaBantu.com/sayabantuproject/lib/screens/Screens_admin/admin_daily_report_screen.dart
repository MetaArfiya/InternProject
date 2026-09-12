import 'package:flutter/material.dart';

class AdminDailyReportScreen extends StatefulWidget {
  const AdminDailyReportScreen({super.key});

  @override
  State<AdminDailyReportScreen> createState() =>
      _AdminDailyReportScreenState();
}

class _AdminDailyReportScreenState extends State<AdminDailyReportScreen> {
  String _selectedPeriod = 'Minggu Ini';

  final List<String> _periodOptions = [
    'Hari Ini',
    'Minggu Ini',
    'Bulan Ini',
  ];

  final List<Map<String, dynamic>> _dailyData = [
    {
      'day': 'Sen',
      'transactions': 8,
      'income': 175000,
      'jobs': 7,
    },
    {
      'day': 'Sel',
      'transactions': 12,
      'income': 260000,
      'jobs': 10,
    },
    {
      'day': 'Rab',
      'transactions': 10,
      'income': 220000,
      'jobs': 9,
    },
    {
      'day': 'Kam',
      'transactions': 15,
      'income': 325000,
      'jobs': 13,
    },
    {
      'day': 'Jum',
      'transactions': 18,
      'income': 390000,
      'jobs': 16,
    },
    {
      'day': 'Sab',
      'transactions': 22,
      'income': 480000,
      'jobs': 20,
    },
    {
      'day': 'Min',
      'transactions': 17,
      'income': 365000,
      'jobs': 15,
    },
  ];

  String _formatRupiah(double amount) {
    final value = amount.toInt().toString();
    final reversed = value.split('').reversed.toList();
    final chunks = <String>[];

    for (int i = 0; i < reversed.length; i += 3) {
      final chunk = reversed.skip(i).take(3).toList().reversed.join();
      chunks.add(chunk);
    }

    return 'Rp${chunks.reversed.join('.')}';
  }

  int get _totalTransactions {
    return _dailyData.fold(
      0,
      (total, item) => total + (item['transactions'] as int),
    );
  }

  int get _totalJobs {
    return _dailyData.fold(
      0,
      (total, item) => total + (item['jobs'] as int),
    );
  }

  double get _totalIncome {
    return _dailyData.fold(
      0,
      (total, item) => total + (item['income'] as int),
    );
  }

  double get _averageIncome {
    if (_dailyData.isEmpty) return 0;
    return _totalIncome / _dailyData.length;
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
            child: Icon(
              icon,
              color: color,
              size: 27,
            ),
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

  Widget _buildSummarySection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;

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
            value: _formatRupiah(_totalIncome.toDouble()),
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
              for (final card in cards) ...[
                card,
                const SizedBox(height: 12),
              ],
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
      },
    );
  }

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
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 15),
          SizedBox(
            width: 170,
            child: DropdownButtonFormField<String>(
              value: _selectedPeriod,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: _periodOptions.map((period) {
                return DropdownMenuItem<String>(
                  value: period,
                  child: Text(period),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedPeriod = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart({
    required String title,
    required String subtitle,
    required List<double> values,
    required List<String> labels,
    required String valueSuffix,
  }) {
    final maxValue = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b);

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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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
                final height = maxValue == 0
                    ? 0.0
                    : (value / maxValue) * 185;

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
          rows: _dailyData.map((data) {
            return DataRow(
              cells: [
                DataCell(Text(data['day'])),
                DataCell(Text('${data['transactions']}')),
                DataCell(Text('${data['jobs']}')),
                DataCell(
                  Text(
                    _formatRupiah(
                      (data['income'] as int).toDouble(),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionValues = _dailyData
        .map<double>((data) => (data['transactions'] as int).toDouble())
        .toList();

    final incomeValues = _dailyData
        .map<double>((data) => (data['income'] as int).toDouble())
        .toList();

    final jobValues = _dailyData
        .map<double>((data) => (data['jobs'] as int).toDouble())
        .toList();

    final labels = _dailyData
        .map<String>((data) => data['day'] as String)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Laporan Harian',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
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
              _buildSummarySection(),
              const SizedBox(height: 24),
              _buildPeriodFilter(),
              const SizedBox(height: 24),
              _buildBarChart(
                title: 'Grafik Transaksi',
                subtitle: 'Jumlah transaksi berdasarkan hari',
                values: transactionValues,
                labels: labels,
                valueSuffix: 'transaksi',
              ),
              const SizedBox(height: 20),
              _buildBarChart(
                title: 'Grafik Komisi Admin',
                subtitle: 'Total komisi admin sebesar 15%',
                values: incomeValues,
                labels: labels,
                valueSuffix: 'Rp',
              ),
              const SizedBox(height: 20),
              _buildBarChart(
                title: 'Grafik Pekerjaan',
                subtitle: 'Jumlah pekerjaan yang diselesaikan',
                values: jobValues,
                labels: labels,
                valueSuffix: 'pekerjaan',
              ),
              const SizedBox(height: 24),
              const Text(
                'Rincian Laporan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildReportTable(),
            ],
          ),
        );
      },
    );
  }
}