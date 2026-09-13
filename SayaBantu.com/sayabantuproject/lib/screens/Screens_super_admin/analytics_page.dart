import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class SuperAdminAnalyticsPage extends StatefulWidget {
  const SuperAdminAnalyticsPage({super.key});

  @override
  State<SuperAdminAnalyticsPage> createState() =>
      _SuperAdminAnalyticsPageState();
}

class _SuperAdminAnalyticsPageState extends State<SuperAdminAnalyticsPage> {
  // ================================================================
  // STATE - ANALYTICS
  // ================================================================
  bool _isLoading = true;
  String? _errorMessage;

  double _totalTransaksi = 0;
  int _jobSelesai = 0;
  int _penggunaBaru = 0;
  int _pelangganBaru = 0;
  int _mitraBaru = 0;
  int _mitraAktif = 0;
  int _mitraMenunggu = 0;

  Map<String, dynamic> _jobSelesaiPerHari = {};
  Map<String, dynamic> _pendapatanHarian = {};
  Map<String, dynamic> _pertumbuhanPengguna = {};

  String _periode = '7 hari terakhir';

  // ================================================================
  // STATE - PAYMENT
  // ================================================================
  double _paymentTotalPembayaran = 0;
  double _paymentTotalKomisi = 0;
  double _paymentTotalMitraEarning = 0;
  double _paymentPendingAmount = 0;
  double _paymentSettledAmount = 0;
  int _paymentTotalTransaksi = 0;
  Map<String, dynamic> _paymentPerStatus = {};
  List<dynamic> _paymentChart = [];
  List<dynamic> _paymentTopMitra = [];

  // ================================================================
  // LIFECYCLE
  // ================================================================
  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ================================================================
  // LOAD SEMUA DATA (PARALEL)
  // ================================================================
  Future<void> _loadAll() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final responses = await Future.wait([
        ApiService.get('/superadmin/analytics'),
        ApiService.get('/superadmin/payments/overview'),
        ApiService.get('/superadmin/payments/chart'),
        ApiService.get('/superadmin/payments/top-mitra?limit=5'),
      ]);

      debugPrint('================================================');
      debugPrint('SUPER ADMIN ANALYTICS BUNDLE');
      debugPrint('analytics:  ${responses[0].statusCode}');
      debugPrint('overview:   ${responses[1].statusCode}');
      debugPrint('chart:      ${responses[2].statusCode}');
      debugPrint('top-mitra:  ${responses[3].statusCode}');
      debugPrint('================================================');

      if (responses[0].statusCode != 200) {
        throw Exception('Analytics gagal (${responses[0].statusCode})');
      }

      // Parse analytics
      final analyticsBody = jsonDecode(responses[0].body);
      if (analyticsBody['success'] != true) {
        throw Exception(
          analyticsBody['message']?.toString() ?? 'Analytics gagal diambil.',
        );
      }

      // Parse payment (toleran)
      Map<String, dynamic>? overviewData;
      List<dynamic>? chartData;
      List<dynamic>? topMitraData;

      if (responses[1].statusCode == 200) {
        try {
          final body = jsonDecode(responses[1].body);
          if (body['success'] == true) {
            final data = body['data'];
            if (data is Map) {
              overviewData = Map<String, dynamic>.from(data);
            } else {
              overviewData = <String, dynamic>{};
            }
          }
        } catch (_) {}
      }

      if (responses[2].statusCode == 200) {
        try {
          final body = jsonDecode(responses[2].body);
          if (body['success'] == true) {
            chartData = (body['data'] is List) ? (body['data'] as List) : [];
          }
        } catch (_) {}
      }

      if (responses[3].statusCode == 200) {
        try {
          final body = jsonDecode(responses[3].body);
          if (body['success'] == true) {
            topMitraData = (body['data'] is List) ? (body['data'] as List) : [];
          }
        } catch (_) {}
      }

      if (!mounted) return;

      setState(() {
        // ============================================================
        // ANALYTICS
        // ============================================================
        final summary = _safeMap(analyticsBody['summary']);
        final charts = _safeMap(analyticsBody['charts']);
        final period = _safeMap(analyticsBody['period']);

        _totalTransaksi = _toDouble(summary['total_transaksi']);
        _jobSelesai = _toInt(summary['job_selesai']);
        _penggunaBaru = _toInt(summary['pengguna_baru']);
        _pelangganBaru = _toInt(summary['pelanggan_baru']);
        _mitraBaru = _toInt(summary['mitra_baru']);
        _mitraAktif = _toInt(summary['mitra_aktif']);
        _mitraMenunggu = _toInt(summary['mitra_menunggu']);

        _jobSelesaiPerHari = _safeMap(charts['job_selesai_per_hari']);
        _pendapatanHarian = _safeMap(charts['pendapatan_harian']);
        _pertumbuhanPengguna = _safeMap(charts['pertumbuhan_pengguna']);

        final start = period['start']?.toString();
        final end = period['end']?.toString();
        if (start != null && end != null) {
          _periode = _formatPeriod(start, end);
        }

        // ============================================================
        // PAYMENT
        // ============================================================
        if (overviewData != null) {
          _paymentTotalPembayaran = _toDouble(overviewData['total_pembayaran']);
          _paymentTotalKomisi = _toDouble(overviewData['total_komisi']);
          _paymentTotalMitraEarning =
              _toDouble(overviewData['total_mitra_earning']);
          _paymentPendingAmount = _toDouble(overviewData['pending_amount']);
          _paymentSettledAmount = _toDouble(overviewData['settled_amount']);
          _paymentTotalTransaksi = _toInt(overviewData['total_transaksi']);
          _paymentPerStatus = _safeMap(overviewData['per_status']);
        }

        _paymentChart = chartData ?? [];
        _paymentTopMitra = topMitraData ?? [];

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('ERROR SUPER ADMIN ANALYTICS: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ================================================================
  // SAFE MAP PARSER
  // ================================================================
  /// Ubah value apapun jadi Map<String, dynamic>.
  /// Kalau bukan Map, return empty Map (tidak error).
  Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  // ================================================================
  // HELPER KONVERSI
  // ================================================================
  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  // ================================================================
  // FORMAT RUPIAH
  // ================================================================
  String _formatRupiah(double value) {
    final int roundedValue = value.round();
    final String number = roundedValue.toString();
    final String formatted = number.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return 'Rp $formatted';
  }

  // ================================================================
  // FORMAT PERIODE
  // ================================================================
  String _formatPeriod(String start, String end) {
    try {
      final startDate = DateTime.parse(start);
      final endDate = DateTime.parse(end);
      return '${_formatDate(startDate)} — ${_formatDate(endDate)}';
    } catch (_) {
      return '$start — $end';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ================================================================
  // BUILD
  // ================================================================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              const Text(
                'Gagal mengambil data analytics',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF10213A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6D8099)),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _loadAll,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final int columns = width >= 1100
                ? 4
                : width >= 650
                    ? 2
                    : 1;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // HEADER
                // ==================================================
                const Text(
                  'Analytics Platform',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10213A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ringkasan performa SiapBantu.com — $_periode',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6D8099)),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // GENERAL STATS
                // ==================================================
                GridView.count(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: width < 650 ? 2.7 : 2.3,
                  children: [
                    _StatisticCard(
                      title: 'TOTAL TRANSAKSI',
                      value: _formatRupiah(_totalTransaksi),
                      description: '7 hari terakhir',
                      icon: Icons.payments_rounded,
                      backgroundColor: const Color(0xFFF0FFF7),
                      borderColor: const Color(0xFFC9F0DB),
                      valueColor: const Color(0xFF00A86B),
                    ),
                    _StatisticCard(
                      title: 'JOB SELESAI',
                      value: '$_jobSelesai',
                      description: '7 hari terakhir',
                      icon: Icons.check_circle_rounded,
                      backgroundColor: const Color(0xFFF0F8FF),
                      borderColor: const Color(0xFFC7E6FA),
                      valueColor: const Color(0xFF159DDD),
                    ),
                    _StatisticCard(
                      title: 'PENGGUNA BARU',
                      value: '$_penggunaBaru',
                      description: '$_pelangganBaru pelanggan · $_mitraBaru mitra',
                      icon: Icons.people_alt_rounded,
                      backgroundColor: const Color(0xFFFBF3FF),
                      borderColor: const Color(0xFFE6D5F8),
                      valueColor: const Color(0xFF8454E8),
                    ),
                    _StatisticCard(
                      title: 'MITRA AKTIF',
                      value: '$_mitraAktif',
                      description: '$_mitraMenunggu menunggu verifikasi',
                      icon: Icons.handyman_rounded,
                      backgroundColor: const Color(0xFFFFF8EE),
                      borderColor: const Color(0xFFFFD9B5),
                      valueColor: const Color(0xFFE95D00),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // ==================================================
                // JOB CHART
                // ==================================================
                _JobChartCard(data: _jobSelesaiPerHari),

                const SizedBox(height: 22),

                // ==================================================
                // PEMBAYARAN - SECTION HEADER
                // ==================================================
                const Text(
                  'Analytics Pembayaran',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10213A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ringkasan transaksi dan pencairan dana platform',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6D8099)),
                ),

                const SizedBox(height: 16),

                // ==================================================
                // PAYMENT STAT CARDS
                // ==================================================
                GridView.count(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: width < 650 ? 2.7 : 2.3,
                  children: [
                    _StatisticCard(
                      title: 'TOTAL PEMBAYARAN',
                      value: _formatRupiah(_paymentTotalPembayaran),
                      description: '$_paymentTotalTransaksi transaksi',
                      icon: Icons.account_balance_wallet_rounded,
                      backgroundColor: const Color(0xFFF0FFF7),
                      borderColor: const Color(0xFFC9F0DB),
                      valueColor: const Color(0xFF00A86B),
                    ),
                    _StatisticCard(
                      title: 'KOMISI PLATFORM',
                      value: _formatRupiah(_paymentTotalKomisi),
                      description: 'Pendapatan aplikasi',
                      icon: Icons.percent_rounded,
                      backgroundColor: const Color(0xFFFFF8EE),
                      borderColor: const Color(0xFFFFD9B5),
                      valueColor: const Color(0xFFE95D00),
                    ),
                    _StatisticCard(
                      title: 'TOTAL KE MITRA',
                      value: _formatRupiah(_paymentTotalMitraEarning),
                      description: 'Sudah dibayarkan',
                      icon: Icons.handshake_rounded,
                      backgroundColor: const Color(0xFFF0F8FF),
                      borderColor: const Color(0xFFC7E6FA),
                      valueColor: const Color(0xFF159DDD),
                    ),
                    _StatisticCard(
                      title: 'PENDING CAIR',
                      value: _formatRupiah(_paymentPendingAmount),
                      description: 'Belum ditransfer',
                      icon: Icons.hourglass_top_rounded,
                      backgroundColor: const Color(0xFFFFF4F4),
                      borderColor: const Color(0xFFFFD5D5),
                      valueColor: const Color(0xFFE53935),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // ==================================================
                // PAYMENT CHART + TOP MITRA
                // ==================================================
                if (width >= 850)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _PaymentChartCard(data: _paymentChart),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _TopMitraCard(data: _paymentTopMitra),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _PaymentChartCard(data: _paymentChart),
                      const SizedBox(height: 16),
                      _TopMitraCard(data: _paymentTopMitra),
                    ],
                  ),

                const SizedBox(height: 18),

                // ==================================================
                // BOTTOM ROW (INCOME + USER GROWTH + STATUS)
                // ==================================================
                if (width >= 850)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _DailyIncomeCard(data: _pendapatanHarian)),
                      const SizedBox(width: 16),
                      Expanded(child: _UserGrowthCard(data: _pertumbuhanPengguna)),
                      const SizedBox(width: 16),
                      Expanded(child: _PaymentStatusCard(data: _paymentPerStatus)),
                    ],
                  )
                else
                  Column(
                    children: [
                      _DailyIncomeCard(data: _pendapatanHarian),
                      const SizedBox(height: 16),
                      _UserGrowthCard(data: _pertumbuhanPengguna),
                      const SizedBox(height: 16),
                      _PaymentStatusCard(data: _paymentPerStatus),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ====================================================================
// STATISTIC CARD
// ====================================================================

class _StatisticCard extends StatelessWidget {
  final String title;
  final String value;
  final String description;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color valueColor;

  const _StatisticCard({
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF60748E),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF8092A9)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 25, color: valueColor),
        ],
      ),
    );
  }
}

// ====================================================================
// JOB CHART
// ====================================================================

class _JobChartCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _JobChartCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final values = entries.map((e) => _toInt(e.value)).toList();
    final int maxValue = values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCE5EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Job Selesai per Hari',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF10213A),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Data berdasarkan job yang berstatus Selesai',
            style: TextStyle(fontSize: 10, color: Color(0xFF8092A9)),
          ),
          const SizedBox(height: 20),
          if (entries.isEmpty)
            const SizedBox(
              height: 190,
              child: Center(
                child: Text(
                  'Belum ada data job selesai.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8092A9)),
                ),
              ),
            )
          else
            SizedBox(
              height: 190,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: entries.map((item) {
                  final int value = _toInt(item.value);
                  final double heightFactor = maxValue == 0 ? 0 : value / maxValue;
                  final bool weekend = item.key == 'Sab' || item.key == 'Min';

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '$value',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF52677F),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: heightFactor,
                                widthFactor: 0.7,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: weekend
                                        ? const Color(0xFFEE5B00)
                                        : const Color(0xFFB9D4F7),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            item.key,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF63758C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 14),
          const Row(
            children: [
              _Legend(color: Color(0xFFB9D4F7), text: 'Hari Kerja'),
              SizedBox(width: 20),
              _Legend(color: Color(0xFFEE5B00), text: 'Weekend'),
            ],
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// PAYMENT CHART
// ====================================================================

class _PaymentChartCard extends StatelessWidget {
  final List<dynamic> data;

  const _PaymentChartCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCE5EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pendapatan Bulanan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF10213A),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Total pembayaran 12 bulan terakhir',
            style: TextStyle(fontSize: 10, color: Color(0xFF8092A9)),
          ),
          const SizedBox(height: 18),
          if (data.isEmpty)
            const SizedBox(
              height: 150,
              child: Center(
                child: Text(
                  'Belum ada data pembayaran.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8092A9)),
                ),
              ),
            )
          else
            Column(
              children: data.take(6).map<Widget>((item) {
                if (item is! Map) return const SizedBox.shrink();

                final total = _toDouble(item['total_pembayaran']);
                final max = data
                    .whereType<Map>()
                    .map<double>((e) => _toDouble(e['total_pembayaran']))
                    .fold<double>(1, (a, b) => a > b ? a : b);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 45,
                        child: Text(
                          item['bulan']?.toString() ?? '-',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF52677F),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 16,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F4F8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: (total / max).clamp(0.0, 1.0),
                              child: Container(
                                height: 16,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF20ABE0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 90,
                        child: Text(
                          _formatRupiahShort(total),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ====================================================================
// TOP MITRA CARD
// ====================================================================

class _TopMitraCard extends StatelessWidget {
  final List<dynamic> data;

  const _TopMitraCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCE5EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Mitra',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF10213A),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Berdasarkan pendapatan tertinggi',
            style: TextStyle(fontSize: 10, color: Color(0xFF8092A9)),
          ),
          const SizedBox(height: 16),
          if (data.isEmpty)
            const Text(
              'Belum ada data mitra.',
              style: TextStyle(fontSize: 11, color: Color(0xFF8092A9)),
            )
          else
            ...data.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final m = entry.value;

              String name = 'Mitra';
              double total = 0;

              if (m is Map) {
                final mitra = m['mitra'];
                if (mitra is Map) {
                  name = mitra['name']?.toString() ?? 'Mitra';
                }
                total = _toDouble(m['total_pendapatan']);
              }

              final colors = [
                const Color(0xFFFFC107),
                const Color(0xFF9E9E9E),
                const Color(0xFFBC8A5F),
              ];
              final color = idx <= 3 ? colors[idx - 1] : Colors.grey.shade300;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: color,
                      child: Text(
                        '$idx',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatRupiahShort(total),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF00A86B),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ====================================================================
// PAYMENT STATUS CARD
// ====================================================================

class _PaymentStatusCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _PaymentStatusCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final labels = {
      'pending': 'Menunggu',
      'paid': 'Dibayar',
      'settled': 'Selesai',
      'refunded': 'Refund',
      'failed': 'Gagal',
    };

    final colors = {
      'pending': const Color(0xFFE95D00),
      'paid': const Color(0xFF159DDD),
      'settled': const Color(0xFF00A86B),
      'refunded': const Color(0xFF8454E8),
      'failed': const Color(0xFFE53935),
    };

    return _ListCard(
      title: 'Status Pembayaran',
      children: labels.entries.map((e) {
        final count = _toInt(data[e.key]);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colors[e.key],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  e.value,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF5E7188),
                  ),
                ),
              ),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ====================================================================
// LEGEND
// ====================================================================

class _Legend extends StatelessWidget {
  final Color color;
  final String text;

  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(fontSize: 9, color: Color(0xFF71839A)),
        ),
      ],
    );
  }
}

// ====================================================================
// DAILY INCOME
// ====================================================================

class _DailyIncomeCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _DailyIncomeCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final values = entries.map((e) => _toDouble(e.value)).toList();
    final double maxValue =
        values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);

    return _ListCard(
      title: 'Pendapatan Harian',
      children: entries.map((item) {
        final double value = _toDouble(item.value);
        final double progress = maxValue == 0 ? 0 : value / maxValue;

        return _ProgressRow(
          label: item.key,
          value: _formatRupiahShort(value),
          progress: progress.clamp(0.0, 1.0),
          color: const Color(0xFF20ABE0),
        );
      }).toList(),
    );
  }
}

// ====================================================================
// USER GROWTH
// ====================================================================

class _UserGrowthCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _UserGrowthCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final values = entries.map((e) => _toInt(e.value)).toList();
    final int maxValue =
        values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);

    return _ListCard(
      title: 'Pertumbuhan Pengguna',
      children: entries.map((item) {
        final int value = _toInt(item.value);
        final double progress = maxValue == 0 ? 0 : value / maxValue;

        return _ProgressRow(
          label: item.key,
          value: '+$value',
          progress: progress.clamp(0.0, 1.0),
          color: const Color(0xFF9061E9),
        );
      }).toList(),
    );
  }
}

// ====================================================================
// LIST CARD
// ====================================================================

class _ListCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ListCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCE5EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF10213A),
            ),
          ),
          const SizedBox(height: 15),
          if (children.isEmpty)
            const Text(
              'Belum ada data.',
              style: TextStyle(fontSize: 11, color: Color(0xFF8092A9)),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

// ====================================================================
// PROGRESS ROW
// ====================================================================

class _ProgressRow extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF5E7188)),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 15,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 15,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// HELPER FUNCTIONS
// ====================================================================

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

String _formatRupiahShort(double value) {
  if (value >= 1000000000) {
    return 'Rp ${(value / 1000000000).toStringAsFixed(1)} M';
  }
  if (value >= 1000000) {
    return 'Rp ${(value / 1000000).toStringAsFixed(1)} Jt';
  }
  if (value >= 1000) {
    return 'Rp ${(value / 1000).toStringAsFixed(1)} Rb';
  }
  return 'Rp ${value.round()}';
}