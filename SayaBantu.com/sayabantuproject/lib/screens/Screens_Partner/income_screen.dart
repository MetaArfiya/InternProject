import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  String selectedPeriod = '6 Bulan';

  final List<String> monthNames = [
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
  ];

  final List<double> incomeData = [
    850000,
    1250000,
    980000,
    1750000,
    2100000,
    2450000,
  ];

  final List<int> completedJobs = [
    5,
    8,
    6,
    11,
    14,
    16,
  ];

  double get totalIncome {
    return incomeData.fold(
      0,
      (previousValue, element) => previousValue + element,
    );
  }

  int get totalJobs {
    return completedJobs.fold(
      0,
      (previousValue, element) => previousValue + element,
    );
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 28),

              _buildSummaryCards(),

              const SizedBox(height: 28),

              _buildChartCard(),

              const SizedBox(height: 28),

              _buildRecentIncomeCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),
        ),

        const SizedBox(width: 16),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Penghasilan',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff111827),
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Pantau pendapatan dari pekerjaan yang telah selesai.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.bar_chart,
                size: 18,
                color: Colors.orange,
              ),
              SizedBox(width: 6),
              Text(
                'Data Dummy',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 700;

        final cards = [
          _summaryCard(
            title: 'Total Penghasilan',
            value: formatRupiah(totalIncome),
            subtitle: 'Akumulasi 6 bulan',
            icon: Icons.account_balance_wallet_outlined,
            iconColor: Colors.orange,
          ),
          _summaryCard(
            title: 'Pekerjaan Selesai',
            value: '$totalJobs',
            subtitle: 'Total pekerjaan',
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
          ),
          _summaryCard(
            title: 'Rata-rata Penghasilan',
            value: formatRupiah(totalIncome / incomeData.length),
            subtitle: 'Per bulan',
            icon: Icons.trending_up,
            iconColor: Colors.blue,
          ),
        ];

        if (isSmall) {
          return Column(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i != cards.length - 1)
                  const SizedBox(height: 14),
              ],
            ],
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
      },
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xff111827),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grafik Penghasilan',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff111827),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Perkembangan penghasilan setiap bulan',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              DropdownButton<String>(
                value: selectedPeriod,
                underline: const SizedBox(),
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
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 30),

          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 5,
                minY: 0,
                maxY: 3000000,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 500000,
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 ||
                            index >= monthNames.length) {
                          return const SizedBox();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            monthNames[index],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 500000,
                      reservedSize: 55,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) {
                          return const Text(
                            '0',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          );
                        }

                        return Text(
                          '${(value / 1000000).toStringAsFixed(1)}jt',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < incomeData.length; i++)
                        FlSpot(
                          i.toDouble(),
                          incomeData[i],
                        ),
                    ],
                    isCurved: true,
                    barWidth: 4,
                    dotData: FlDotData(
                      show: true,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.orange.withValues(alpha: 0.12),
                    ),
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentIncomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Penghasilan Bulanan',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xff111827),
            ),
          ),

          const SizedBox(height: 18),

          ListView.separated(
            itemCount: monthNames.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (_, __) {
              return const Divider(height: 24);
            },
            itemBuilder: (context, index) {
              return Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.payments_outlined,
                      color: Colors.orange,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Penghasilan ${monthNames[index]}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xff111827),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${completedJobs[index]} pekerjaan selesai',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    formatRupiah(incomeData[index]),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}