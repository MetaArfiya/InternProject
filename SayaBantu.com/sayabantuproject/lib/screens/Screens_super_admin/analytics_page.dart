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
  // DESIGN TOKENS
  // ================================================================

  static const double _mobileBreakpoint = 700;
  static const double _tabletBreakpoint = 1100;

  static const Color _bg = Color(0xFFF5F7FB);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _darkText = Color(0xFF0F172A);
  static const Color _mutedText = Color(0xFF64748B);

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

      if (responses[0].statusCode != 200) {
        throw Exception('Analytics gagal (${responses[0].statusCode})');
      }

      final analyticsBody = jsonDecode(responses[0].body);
      if (analyticsBody['success'] != true) {
        throw Exception(
          analyticsBody['message']?.toString() ?? 'Analytics gagal diambil.',
        );
      }

      Map<String, dynamic>? overviewData;
      List<dynamic>? chartData;
      List<dynamic>? topMitraData;

      if (responses[1].statusCode == 200) {
        try {
          final body = jsonDecode(responses[1].body);
          if (body['success'] == true) {
            final data = body['data'];
            overviewData = data is Map
                ? Map<String, dynamic>.from(data)
                : <String, dynamic>{};
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
            topMitraData =
                (body['data'] is List) ? (body['data'] as List) : [];
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
  // HELPERS
  // ================================================================

  Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) {
      return value.isFinite ? value.toDouble() : 0;
    }
    final parsed = double.tryParse(value.toString()) ?? 0;
    return parsed.isFinite ? parsed : 0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  String _formatRupiah(double value) {
    final safe = value.isFinite ? value : 0.0;
    final int roundedValue = safe.round();
    final String number = roundedValue.toString();
    final String formatted = number.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return 'Rp $formatted';
  }

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < _mobileBreakpoint;
        final isTablet =
            width >= _mobileBreakpoint && width < _tabletBreakpoint;

        final horizontalPadding =
            isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
        final verticalPadding = isMobile ? 16.0 : 28.0;

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: _bg,
          child: RefreshIndicator(
            onRefresh: _loadAll,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1300),
                  child: _buildContent(width, isMobile),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(double width, bool isMobile) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 100),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFF97316)),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ==================================================
        // HEADER
        // ==================================================
        _buildHeader(isMobile),
        SizedBox(height: isMobile ? 20 : 26),

        // ==================================================
        // GENERAL STATS
        // ==================================================
        _buildSectionLabel('Ringkasan Platform', isMobile),
        const SizedBox(height: 12),
        _buildStatGrid(
          isMobile: isMobile,
          cards: [
            _StatData(
              title: 'TOTAL TRANSAKSI',
              value: _formatRupiah(_totalTransaksi),
              description: '7 hari terakhir',
              icon: Icons.payments_rounded,
              color: const Color(0xFF00A86B),
            ),
            _StatData(
              title: 'JOB SELESAI',
              value: '$_jobSelesai',
              description: '7 hari terakhir',
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF159DDD),
            ),
            _StatData(
              title: 'PENGGUNA BARU',
              value: '$_penggunaBaru',
              description: '$_pelangganBaru pelanggan · $_mitraBaru mitra',
              icon: Icons.people_alt_rounded,
              color: const Color(0xFF8454E8),
            ),
            _StatData(
              title: 'MITRA AKTIF',
              value: '$_mitraAktif',
              description: '$_mitraMenunggu menunggu verifikasi',
              icon: Icons.handyman_rounded,
              color: const Color(0xFFE95D00),
            ),
          ],
        ),

        SizedBox(height: isMobile ? 18 : 22),

        // ==================================================
        // JOB CHART
        // ==================================================
        _JobChartCard(data: _jobSelesaiPerHari),

        SizedBox(height: isMobile ? 22 : 28),

        // ==================================================
        // PEMBAYARAN
        // ==================================================
        _buildSectionLabel('Analytics Pembayaran', isMobile),
        const SizedBox(height: 4),
        const Text(
          'Ringkasan transaksi dan pencairan dana platform',
          style: TextStyle(fontSize: 12, color: _mutedText),
        ),
        const SizedBox(height: 14),

        _buildStatGrid(
          isMobile: isMobile,
          cards: [
            _StatData(
              title: 'TOTAL PEMBAYARAN',
              value: _formatRupiah(_paymentTotalPembayaran),
              description: '$_paymentTotalTransaksi transaksi',
              icon: Icons.account_balance_wallet_rounded,
              color: const Color(0xFF00A86B),
            ),
            _StatData(
              title: 'KOMISI PLATFORM',
              value: _formatRupiah(_paymentTotalKomisi),
              description: 'Pendapatan aplikasi',
              icon: Icons.percent_rounded,
              color: const Color(0xFFE95D00),
            ),
            _StatData(
              title: 'TOTAL KE MITRA',
              value: _formatRupiah(_paymentTotalMitraEarning),
              description: 'Sudah dibayarkan',
              icon: Icons.handshake_rounded,
              color: const Color(0xFF159DDD),
            ),
            _StatData(
              title: 'PENDING CAIR',
              value: _formatRupiah(_paymentPendingAmount),
              description: 'Belum ditransfer',
              icon: Icons.hourglass_top_rounded,
              color: const Color(0xFFE53935),
            ),
          ],
        ),

        SizedBox(height: isMobile ? 18 : 22),

        // ==================================================
        // PAYMENT CHART + TOP MITRA
        // ==================================================
        _buildTwoColumnRow(
          isMobile: isMobile,
          left: _PaymentChartCard(data: _paymentChart),
          right: _TopMitraCard(data: _paymentTopMitra),
        ),

        SizedBox(height: isMobile ? 18 : 22),

        // ==================================================
        // BOTTOM ROW
        // ==================================================
        _buildThreeColumnRow(
          isMobile: isMobile,
          first: _DailyIncomeCard(data: _pendapatanHarian),
          second: _UserGrowthCard(data: _pertumbuhanPengguna),
          third: _PaymentStatusCard(data: _paymentPerStatus),
        ),
      ],
    );
  }

  // ================================================================
  // HEADER
  // ================================================================

  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics Platform',
          style: TextStyle(
            fontSize: isMobile ? 22 : 26,
            fontWeight: FontWeight.w700,
            color: _darkText,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ringkasan performa SiapBantu.com — $_periode',
          style: TextStyle(
            fontSize: isMobile ? 12.5 : 13,
            color: _mutedText,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // SECTION LABEL
  // ================================================================

  Widget _buildSectionLabel(String text, bool isMobile) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFFF97316),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: isMobile ? 15 : 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // STAT GRID — MOBILE 2×2, WEB 4 KOLOM
  // ================================================================

  Widget _buildStatGrid({
    required bool isMobile,
    required List<_StatData> cards,
  }) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard(cards[0])),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard(cards[1])),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildStatCard(cards[2])),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard(cards[3])),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: _buildStatCard(cards[i])),
          if (i != cards.length - 1) const SizedBox(width: 14),
        ],
      ],
    );
  }

  Widget _buildStatCard(_StatData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8092A9),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: data.color,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, size: 20, color: data.color),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // 2-COLUMN & 3-COLUMN LAYOUT HELPERS
  // ================================================================

  Widget _buildTwoColumnRow({
    required bool isMobile,
    required Widget left,
    required Widget right,
  }) {
    if (isMobile) {
      return Column(
        children: [
          left,
          const SizedBox(height: 16),
          right,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: left),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: right),
      ],
    );
  }

  Widget _buildThreeColumnRow({
    required bool isMobile,
    required Widget first,
    required Widget second,
    required Widget third,
  }) {
    if (isMobile) {
      return Column(
        children: [
          first,
          const SizedBox(height: 16),
          second,
          const SizedBox(height: 16),
          third,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: 16),
        Expanded(child: second),
        const SizedBox(width: 16),
        Expanded(child: third),
      ],
    );
  }

  // ================================================================
  // ERROR STATE
  // ================================================================

  Widget _buildErrorState() {
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
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(height: 12),
          const Text(
            'Gagal mengambil data analytics',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7F1D1D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF991B1B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
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
}

// ====================================================================
// DATA CLASS
// ====================================================================

class _StatData {
  final String title;
  final String value;
  final String description;
  final IconData icon;
  final Color color;

  const _StatData({
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// ====================================================================
// JOB CHART CARD
// ====================================================================

class _JobChartCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _JobChartCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final values = entries.map((e) => _toInt(e.value)).toList();
    final int maxValue =
        values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Job Selesai per Hari',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Data berdasarkan job yang berstatus Selesai',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          if (entries.isEmpty)
            const SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  'Belum ada data job selesai.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: entries.map((item) {
                  final int value = _toInt(item.value);
                  final double heightFactor =
                      maxValue == 0 ? 0 : value / maxValue;
                  final bool weekend =
                      item.key == 'Sab' || item.key == 'Min';

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '$value',
                            style: const TextStyle(
                              fontSize: 10,
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
                                    borderRadius:
                                        const BorderRadius.vertical(
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
                              fontSize: 10.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
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
// PAYMENT CHART CARD
// ====================================================================

class _PaymentChartCard extends StatelessWidget {
  final List<dynamic> data;

  const _PaymentChartCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxValue = data
        .whereType<Map>()
        .map<double>((e) => _toDouble(e['total_pembayaran']))
        .fold<double>(1, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pendapatan Bulanan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Total pembayaran 12 bulan terakhir',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 18),
          if (data.isEmpty)
            const SizedBox(
              height: 150,
              child: Center(
                child: Text(
                  'Belum ada data pembayaran.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            Column(
              children: data.take(6).map<Widget>((item) {
                if (item is! Map) return const SizedBox.shrink();

                final total = _toDouble(item['total_pembayaran']);

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
                            fontWeight: FontWeight.w500,
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
                              widthFactor:
                                  (total / maxValue).clamp(0.0, 1.0),
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
                        width: 88,
                        child: Text(
                          _formatRupiahShort(total),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Mitra',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Berdasarkan pendapatan tertinggi',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          if (data.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Belum ada data mitra.',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
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
              final color =
                  idx <= 3 ? colors[idx - 1] : const Color(0xFFCBD5E1);

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
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
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
                    fontSize: 12,
                    color: Color(0xFF5E7188),
                  ),
                ),
              ),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(fontSize: 10, color: Color(0xFF71839A)),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 15),
          if (children.isEmpty)
            const Text(
              'Belum ada data.',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
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
            width: 32,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF5E7188),
                fontWeight: FontWeight.w500,
              ),
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
            width: 72,
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
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
  if (value is num) {
    return value.isFinite ? value.toDouble() : 0;
  }
  final parsed = double.tryParse(value.toString()) ?? 0;
  return parsed.isFinite ? parsed : 0;
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

String _formatRupiahShort(double value) {
  final safe = value.isFinite ? value : 0.0;
  if (safe >= 1000000000) {
    return 'Rp ${(safe / 1000000000).toStringAsFixed(1)} M';
  }
  if (safe >= 1000000) {
    return 'Rp ${(safe / 1000000).toStringAsFixed(1)} Jt';
  }
  if (safe >= 1000) {
    return 'Rp ${(safe / 1000).toStringAsFixed(1)} Rb';
  }
  return 'Rp ${safe.round()}';
}