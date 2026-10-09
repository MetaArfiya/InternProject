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
  // DESIGN TOKENS — disamakan dengan DashboardHeader / PaymentScreen
  // ============================================================

  static const Color _accent = Color(0xFFF97316);
  static const Color _tableBorder = Color(0xFFE5E7EB);
  static const Color _tableDivider = Color(0xFFF3F4F6);
  static const Color _headerText = Color(0xFF6B7280);
  static const Color _cellText = Color(0xFF111827);

  static const double _smallRadius = 12;

  // Spacing — mengikuti pola DashboardHeader
  static const double _gapAfterHeader = 16;
  static const double _gapBetweenSections = 16;

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
          var target = decodedData['jobs'] ?? decodedData['data'] ?? [];

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
  // KONFIRMASI — disamakan style dialog dgn halaman lain
  // ============================================================

  void _showTakeOfferConfirmation(PartnerJobModel job) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.local_offer_outlined,
                          color: _accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Konfirmasi Penawaran',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF111827),
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: Color(0xFF6B7280),
                        ),
                        splashRadius: 22,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  Text(
                    'Apakah Anda yakin ingin mengajukan penawaran untuk pekerjaan "${job.title}"?',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 46),
                            foregroundColor: const Color(0xFF374151),
                            side: const BorderSide(
                              color: Color(0xFFD1D5DB),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            widget.onTakeOffer(job);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 46),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Ya, Ajukan',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  // ✅ Padding horizontal disamakan dgn CustomerDashboard
  //    mobile 16 / tablet 24 / desktop 28  (bukan 30)
  // ✅ TIDAK ada Center + ConstrainedBox — konten nempel kiri
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: RefreshIndicator(
        onRefresh: _fetchDashboardData,
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

                  _buildStatRow(isMobile: isMobile),

                  const SizedBox(height: _gapBetweenSections),

                  _buildSectionTitle(context),

                  const SizedBox(height: _gapBetweenSections),

                  _buildContent(context, isMobile: isMobile),
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
          'Lowongan Tersedia',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Temukan pekerjaan yang sesuai dengan keahlianmu.',
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION TITLE — sama persis dgn judul "Riwayat ..." halaman lain
  // ============================================================

  Widget _buildSectionTitle(BuildContext context) {
    return Text(
      'Daftar Lowongan',
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  // ============================================================
  // 3 KOTAK SEJAJAR
  // ============================================================

  Widget _buildStatRow({required bool isMobile}) {
    final cards = [
      _statCard(
        icon: Icons.work_outline,
        title: 'Lowongan',
        fullTitle: 'Total Lowongan',
        value: _jobs.length.toString(),
        color: const Color(0xFF2563EB),
        isCompact: isMobile,
      ),
      _statCard(
        icon: Icons.description_outlined,
        title: 'Penawaran',
        fullTitle: 'Penawaran Aktif',
        value: _activeOffersCount.toString(),
        color: _accent,
        isCompact: isMobile,
      ),
      _statCard(
        icon: Icons.stars,
        title: 'Poin',
        fullTitle: 'Total Poin',
        value: _userPoints.toString(),
        color: const Color(0xFF16A34A),
        isCompact: isMobile,
      ),
    ];

    final gap = isMobile ? 8.0 : 16.0;

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i != cards.length - 1) SizedBox(width: gap),
        ],
      ],
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
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(isCompact ? 9 : 11),
            ),
            child: Icon(
              icon,
              color: color,
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
                  isCompact ? title : fullTitle,
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
                    fontSize: isCompact ? 18 : 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
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
  // CONTENT
  // ============================================================

  Widget _buildContent(BuildContext context, {required bool isMobile}) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: CircularProgressIndicator(color: _accent),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }

    if (_jobs.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        for (int i = 0; i < _jobs.length; i++) ...[
          PartnerJobCard(
            job: _jobs[i],
            onTakeOffer: () => _showTakeOfferConfirmation(_jobs[i]),
          ),
          if (i != _jobs.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }

  // ============================================================
  // ERROR & EMPTY
  // ============================================================

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
            Icons.cloud_off_outlined,
            size: 48,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFDC2626),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchDashboardData,
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
              Icons.work_outline,
              size: 34,
              color: _accent.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum ada lowongan pekerjaan saat ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}