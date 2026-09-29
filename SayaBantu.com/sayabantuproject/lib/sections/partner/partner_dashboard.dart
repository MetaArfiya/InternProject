import 'dart:convert';
import 'package:flutter/material.dart';

import '../../models/partner_job_model.dart';
import '../../widgets/partner_job_card.dart';
import '../../services/api_service.dart';

class PartnerDashboard extends StatefulWidget {
  final Function(PartnerJobModel) onTakeOffer;

  const PartnerDashboard({
    super.key,
    required this.onTakeOffer,
  });

  @override
  State<PartnerDashboard> createState() => _PartnerDashboardState();
}

class _PartnerDashboardState extends State<PartnerDashboard> {
  List<PartnerJobModel> _jobs = [];
  bool _isLoading = true;
  String _errorMessage = '';

  int _activeOffersCount = 0;
  int _userPoints = 0;

  // ============================================================
  // DESIGN TOKENS
  // ============================================================

  static const double _mobileBreakpoint = 700;
  static const double _tabletBreakpoint = 1100;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // ============================================================
  // FETCH DATA
  // ============================================================

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiService.get('/mitra/available-jobs');

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        List<dynamic> jobListJson = [];

        if (decodedData is Map<String, dynamic>) {
          var target =
              decodedData['jobs'] ?? decodedData['data'] ?? [];

          if (target is List) {
            jobListJson = target;
          } else if (target is Map && target.containsKey('data')) {
            jobListJson = target['data'] is List ? target['data'] : [];
          }
        } else if (decodedData is List) {
          jobListJson = decodedData;
        }

        final List<PartnerJobModel> loadedJobs = jobListJson
            .map((json) => PartnerJobModel.fromJson(json))
            .where((job) => !job.hasOffered)
            .toList();

        if (mounted) {
          setState(() {
            _jobs = loadedJobs;

            if (decodedData is Map) {
              _activeOffersCount = int.tryParse(
                    decodedData['active_offers_count']?.toString() ?? '0',
                  ) ??
                  0;

              _userPoints = int.tryParse(
                    decodedData['user_points']?.toString() ?? '0',
                  ) ??
                  0;
            }

            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Gagal memuat data (Status: ${response.statusCode})';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan koneksi: $e';
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // KONFIRMASI
  // ============================================================

  void _showTakeOfferConfirmation(PartnerJobModel job) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi Penawaran"),
        content: Text(
          "Apakah Anda yakin ingin mengajukan penawaran "
          "untuk pekerjaan '${job.title}'?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onTakeOffer(job);
            },
            child: const Text("Ya, Ajukan"),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < _mobileBreakpoint;
        final isTablet =
            width >= _mobileBreakpoint && width < _tabletBreakpoint;

        final padding = isMobile ? 16.0 : (isTablet ? 24.0 : 30.0);

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // HEADER
              // ==================================================
              Text(
                "Lowongan Tersedia",
                style: TextStyle(
                  fontSize: isMobile ? 22 : 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Temukan pekerjaan yang sesuai dengan keahlianmu.",
                style: TextStyle(
                  color: const Color(0xFF64748B),
                  fontSize: isMobile ? 12.5 : 13,
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // STATISTIC CARDS — 3 SEJAJAR
              // ==================================================
              _buildStatRow(isMobile: isMobile),

              const SizedBox(height: 22),

              // ==================================================
              // MAIN CONTENT
              // ==================================================
              Expanded(child: _buildContent()),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // 3 KOTAK SEJAJAR — TANPA SCROLL
  // ============================================================

  Widget _buildStatRow({required bool isMobile}) {
    final gap = isMobile ? 8.0 : 16.0;

    return SizedBox(
      height: isMobile ? 112 : 130,   // ← SEBELUM: 100 : 110
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              icon: Icons.work_outline,
              title: 'Lowongan',
              fullTitle: 'Total Lowongan',
              value: _jobs.length.toString(),
              color: const Color(0xFF2563EB),
              isCompact: isMobile,
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: _statCard(
              icon: Icons.description_outlined,
              title: 'Penawaran',
              fullTitle: 'Penawaran Aktif',
              value: _activeOffersCount.toString(),
              color: const Color(0xFFF97316),
              isCompact: isMobile,
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: _statCard(
              icon: Icons.stars,
              title: 'Poin',
              fullTitle: 'Total Poin',
              value: _userPoints.toString(),
              color: const Color(0xFF16A34A),
              isCompact: isMobile,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String fullTitle,
    required String value,
    required Color color,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 10 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: isCompact ? 28 : 36,
            height: isCompact ? 28 : 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(isCompact ? 7 : 10),
            ),
            child: Icon(
              icon,
              color: color,
              size: isCompact ? 15 : 20,
            ),
          ),
          SizedBox(height: isCompact ? 6 : 8),

          // Value
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isCompact ? 18 : 22,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.1,
            ),
          ),
          SizedBox(height: isCompact ? 2 : 3),

          // Title
          Text(
            isCompact ? title : fullTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isCompact ? 10 : 12,
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
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _fetchDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text("Coba Lagi"),
            ),
          ],
        ),
      );
    }

    if (_jobs.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            Center(
              child: Text(
                "Belum ada lowongan pekerjaan saat ini.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _jobs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final job = _jobs[index];
          return PartnerJobCard(
            job: job,
            onTakeOffer: () => _showTakeOfferConfirmation(job),
          );
        },
      ),
    );
  }
}