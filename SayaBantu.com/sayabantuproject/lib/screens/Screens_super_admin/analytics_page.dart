import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/admin_theme_provider.dart';
import '../../theme/app_colors.dart';

class SuperAdminAnalyticsPage extends StatefulWidget {
  const SuperAdminAnalyticsPage({super.key});

  @override
  State<SuperAdminAnalyticsPage> createState() =>
      _SuperAdminAnalyticsPageState();
}

class _SuperAdminAnalyticsPageState extends State<SuperAdminAnalyticsPage> {
  // ================================================================
  // THEME
  // ================================================================

  AdminTheme get theme => AdminThemeProvider.of(context);

  // ================================================================
  // STATE — ANALYTICS
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
  // STATE — PAYMENT
  // ================================================================

  double _paymentTotalPembayaran = 0;
  double _paymentTotalKomisi = 0;
  double _paymentTotalMitraEarning = 0;
  double _paymentPendingAmount = 0;
 //double _paymentSettledAmount = 0;
  int _paymentTotalTransaksi = 0;
  Map<String, dynamic> _paymentPerStatus = {};
  List<dynamic> _paymentChart = [];
  List<dynamic> _paymentTopMitra = [];

  // ================================================================
  // BREAKPOINTS
  // ================================================================

  static const double _mobileBreakpoint = 700;
  static const double _tabletBreakpoint = 1100;

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
          analyticsBody['message']?.toString() ??
              'Analytics gagal diambil.',
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
        // ANALYTICS
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

        // PAYMENT
        if (overviewData != null) {
          _paymentTotalPembayaran =
              _toDouble(overviewData['total_pembayaran']);
          _paymentTotalKomisi = _toDouble(overviewData['total_komisi']);
          _paymentTotalMitraEarning =
              _toDouble(overviewData['total_mitra_earning']);
          _paymentPendingAmount =
              _toDouble(overviewData['pending_amount']);
         // _paymentSettledAmount =
             // _toDouble(overviewData['settled_amount']);
          _paymentTotalTransaksi =
              _toInt(overviewData['total_transaksi']);
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
    final t = theme;
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
          color: t.bg,
          child: RefreshIndicator(
            onRefresh: _loadAll,
            color: t.accent,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1300),
                  child: _buildContent(width, isMobile, t),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(double width, bool isMobile, AdminTheme t) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 100),
        child: Center(
          child: CircularProgressIndicator(color: t.accent),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState(t);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HEADER
        _buildHeader(isMobile, t),
        SizedBox(height: isMobile ? 20 : 26),

        // GENERAL STATS
        _buildSectionLabel('Ringkasan Platform', isMobile, t),
        const SizedBox(height: 12),
        _buildStatGrid(
          isMobile: isMobile,
          cards: [
            _StatData(
              title: 'TOTAL TRANSAKSI',
              value: _formatRupiah(_totalTransaksi),
              description: '7 hari terakhir',
              icon: Icons.payments_rounded,
              color: t.accent,
            ),
            _StatData(
              title: 'JOB SELESAI',
              value: '$_jobSelesai',
              description: '7 hari terakhir',
              icon: Icons.check_circle_rounded,
              color: t.accent,
            ),
            _StatData(
              title: 'PENGGUNA BARU',
              value: '$_penggunaBaru',
              description:
                  '$_pelangganBaru pelanggan · $_mitraBaru mitra',
              icon: Icons.people_alt_rounded,
              color: t.accent,
            ),
            _StatData(
              title: 'MITRA AKTIF',
              value: '$_mitraAktif',
              description: '$_mitraMenunggu menunggu verifikasi',
              icon: Icons.handyman_rounded,
              color: t.accent,
            ),
          ],
          t: t,
        ),

        SizedBox(height: isMobile ? 18 : 22),

        // JOB CHART
        _JobChartCard(data: _jobSelesaiPerHari, t: t),

        SizedBox(height: isMobile ? 22 : 28),

        // PEMBAYARAN
        _buildSectionLabel('Analytics Pembayaran', isMobile, t),
        const SizedBox(height: 4),
        Text(
          'Ringkasan transaksi dan pencairan dana platform',
          style: TextStyle(fontSize: 12, color: t.mutedText),
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
              color: t.accent,
            ),
            _StatData(
              title: 'KOMISI PLATFORM',
              value: _formatRupiah(_paymentTotalKomisi),
              description: 'Pendapatan aplikasi',
              icon: Icons.percent_rounded,
              color: t.accent,
            ),
            _StatData(
              title: 'TOTAL KE MITRA',
              value: _formatRupiah(_paymentTotalMitraEarning),
              description: 'Sudah dibayarkan',
              icon: Icons.handshake_rounded,
              color: t.accent,
            ),
            _StatData(
              title: 'PENDING CAIR',
              value: _formatRupiah(_paymentPendingAmount),
              description: 'Belum ditransfer',
              icon: Icons.hourglass_top_rounded,
              color: t.accent,
            ),
          ],
          t: t,
        ),

        SizedBox(height: isMobile ? 18 : 22),

        // PAYMENT CHART + TOP MITRA
        _buildTwoColumnRow(
          isMobile: isMobile,
          left: _PaymentChartCard(data: _paymentChart, t: t),
          right: _TopMitraCard(data: _paymentTopMitra, t: t),
        ),

        SizedBox(height: isMobile ? 18 : 22),

        // BOTTOM ROW
        _buildThreeColumnRow(
          isMobile: isMobile,
          first: _DailyIncomeCard(data: _pendapatanHarian, t: t),
          second: _UserGrowthCard(data: _pertumbuhanPengguna, t: t),
          third: _PaymentStatusCard(data: _paymentPerStatus, t: t),
        ),
      ],
    );
  }

  // ================================================================
  // HEADER
  // ================================================================

  Widget _buildHeader(bool isMobile, AdminTheme t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics Platform',
          style: TextStyle(
            fontSize: isMobile ? 22 : 26,
            fontWeight: FontWeight.w700,
            color: t.cellText,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ringkasan performa SiapBantu.com — $_periode',
          style: TextStyle(
            fontSize: isMobile ? 12.5 : 13,
            color: t.mutedText,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // SECTION LABEL
  // ================================================================

  Widget _buildSectionLabel(String text, bool isMobile, AdminTheme t) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: t.accent, // ← Sekarang TEAL
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: isMobile ? 15 : 17,
            fontWeight: FontWeight.w700,
            color: t.cellText,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // STAT GRID
  // ================================================================

  Widget _buildStatGrid({
    required bool isMobile,
    required List<_StatData> cards,
    required AdminTheme t,
  }) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard(cards[0], t)),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard(cards[1], t)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildStatCard(cards[2], t)),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard(cards[3], t)),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: _buildStatCard(cards[i], t)),
          if (i != cards.length - 1) const SizedBox(width: 14),
        ],
      ],
    );
  }

  Widget _buildStatCard(_StatData data, AdminTheme t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
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
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: t.mutedText,
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
                    color: AppColors.grey400,
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
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, size: 20, color: data.color),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // LAYOUT HELPERS
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

  Widget _buildErrorState(AdminTheme t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: t.danger.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: t.danger,
          ),
          const SizedBox(height: 12),
          Text(
            'Gagal mengambil data analytics',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: t.danger,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: t.danger,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: t.accent,
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
  final AdminTheme t;

  const _JobChartCard({required this.data, required this.t});

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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Job Selesai per Hari',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: t.cellText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Data berdasarkan job yang berstatus Selesai',
            style: TextStyle(fontSize: 11.5, color: t.mutedText),
          ),
          const SizedBox(height: 20),
          if (entries.isEmpty)
            SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  'Belum ada data job selesai.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey400,
                  ),
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
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: t.cellText,
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
                                        ? t.accent.withValues(alpha: 0.9)
                                        : t.accent.withValues(alpha: 0.55),
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
                            style: TextStyle(
                              fontSize: 10.5,
                              color: t.mutedText,
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
          Row(
            children: [
              _Legend(
                color: t.accent.withValues(alpha: 0.55),
                text: 'Hari Kerja',
              ),
              const SizedBox(width: 20),
              _Legend(
                color: t.accent.withValues(alpha: 0.9),
                text: 'Weekend',
              ),
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
  final AdminTheme t;

  const _PaymentChartCard({required this.data, required this.t});

  @override
  Widget build(BuildContext context) {
    final maxValue = data
        .whereType<Map>()
        .map<double>((e) => _toDouble(e['total_pembayaran']))
        .fold<double>(1, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pendapatan Bulanan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: t.cellText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total pembayaran 12 bulan terakhir',
            style: TextStyle(fontSize: 11.5, color: t.mutedText),
          ),
          const SizedBox(height: 18),
          if (data.isEmpty)
            SizedBox(
              height: 150,
              child: Center(
                child: Text(
                  'Belum ada data pembayaran.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey400,
                  ),
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
                          style: TextStyle(
                            fontSize: 11,
                            color: t.mutedText,
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
                                color: AppColors.grey100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor:
                                  (total / maxValue).clamp(0.0, 1.0),
                              child: Container(
                                height: 16,
                                decoration: BoxDecoration(
                                  color: t.accent,
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
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: t.cellText,
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
  final AdminTheme t;

  const _TopMitraCard({required this.data, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Mitra',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: t.cellText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Berdasarkan pendapatan tertinggi',
            style: TextStyle(fontSize: 11.5, color: t.mutedText),
          ),
          const SizedBox(height: 16),
          if (data.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Belum ada data mitra.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.grey400,
                ),
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

              // Semua jadi Teal (beda opacity untuk ranking)
              final colors = [
                t.accent,
                t.accent.withValues(alpha: 0.75),
                t.accent.withValues(alpha: 0.55),
              ];
              final color = idx <= 3
                  ? colors[idx - 1]
                  : AppColors.grey300;

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
                          color: AppColors.white,
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
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: t.cellText,
                        ),
                      ),
                    ),
                    Text(
                      _formatRupiahShort(total),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: t.accent,
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
  final AdminTheme t;

  const _PaymentStatusCard({required this.data, required this.t});

  @override
  Widget build(BuildContext context) {
    final labels = {
      'pending': 'Menunggu',
      'paid': 'Dibayar',
      'settled': 'Selesai',
      'refunded': 'Refund',
      'failed': 'Gagal',
    };

    // Semua TEAL kecuali failed (merah)
    final colors = {
      'pending': t.accent,
      'paid': t.accent,
      'settled': t.accent,
      'refunded': t.accent,
      'failed': t.danger,
    };

    return _ListCard(
      title: 'Status Pembayaran',
      t: t,
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
                  style: TextStyle(
                    fontSize: 12,
                    color: t.mutedText,
                  ),
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: t.cellText,
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
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.grey500,
          ),
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
  final AdminTheme t;

  const _DailyIncomeCard({required this.data, required this.t});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final values = entries.map((e) => _toDouble(e.value)).toList();
    final double maxValue =
        values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);

    return _ListCard(
      title: 'Pendapatan Harian',
      t: t,
      children: entries.map((item) {
        final double value = _toDouble(item.value);
        final double progress = maxValue == 0 ? 0 : value / maxValue;

        return _ProgressRow(
          label: item.key,
          value: _formatRupiahShort(value),
          progress: progress.clamp(0.0, 1.0),
          color: t.accent,
          t: t,
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
  final AdminTheme t;

  const _UserGrowthCard({required this.data, required this.t});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final values = entries.map((e) => _toInt(e.value)).toList();
    final int maxValue =
        values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);

    return _ListCard(
      title: 'Pertumbuhan Pengguna',
      t: t,
      children: entries.map((item) {
        final int value = _toInt(item.value);
        final double progress = maxValue == 0 ? 0 : value / maxValue;

        return _ProgressRow(
          label: item.key,
          value: '+$value',
          progress: progress.clamp(0.0, 1.0),
          color: t.accent,
          t: t,
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
  final AdminTheme t;

  const _ListCard({
    required this.title,
    required this.children,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: t.cellText,
            ),
          ),
          const SizedBox(height: 15),
          if (children.isEmpty)
            Text(
              'Belum ada data.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.grey400,
              ),
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
  final AdminTheme t;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
    required this.t,
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
              style: TextStyle(
                fontSize: 11,
                color: t.mutedText,
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
                    color: AppColors.grey100,
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
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: t.cellText,
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