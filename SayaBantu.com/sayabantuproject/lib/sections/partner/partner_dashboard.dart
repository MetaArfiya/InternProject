import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/partner_job_model.dart';
import '../../widgets/partner_job_card.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';

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
  // ============================================================
  // DATA
  // ============================================================

  List<PartnerJobModel> _jobs = [];
  bool _isLoading = true;
  String _errorMessage = '';

  int _activeOffersCount = 0;
  int _userPoints = 0;

  // ============================================================
  // LOKASI & RADIUS
  // ============================================================

  double? _mitraLat;
  double? _mitraLng;
  bool _loadingLocation = false;
  bool _locationDenied = false;
  double _radiusKm = 5;

  // ============================================================
  // DESIGN TOKENS
  // ============================================================

  static const Color _accent = AppColors.primaryTeal;

  static const double _gapAfterHeader = 16;
  static const double _gapBetweenSections = 16;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _requestLocationAndFetch();
  }

  // ============================================================
  // AMBIL LOKASI + FETCH
  // ============================================================

  Future<void> _requestLocationAndFetch() async {
    if (!mounted) return;
    setState(() {
      _loadingLocation = true;
      _locationDenied = false;
    });

    try {
      // 1. Cek izin lokasi
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        if (!mounted) return;
        setState(() {
          _loadingLocation = false;
          _locationDenied = true;
        });
        // Fallback: fetch tanpa radius
        await _fetchDashboardData();
        return;
      }

      // 2. Ambil posisi
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      if (!mounted) return;
      setState(() {
        _mitraLat = pos.latitude;
        _mitraLng = pos.longitude;
        _loadingLocation = false;
      });

      // 3. Fetch dengan radius
      await _fetchDashboardData();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingLocation = false;
        _locationDenied = true;
      });
      await _fetchDashboardData();
    }
  }

  Future<void> _fetchDashboardData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      // Build endpoint dengan / tanpa radius
      final String endpoint;
      if (_mitraLat != null && _mitraLng != null) {
        endpoint =
            '/mitra/available-jobs?lat=$_mitraLat&lng=$_mitraLng&radius=$_radiusKm';
      } else {
        endpoint = '/mitra/available-jobs';
      }

      final response = await ApiService.get(endpoint);

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

  Future<void> _onRefresh() async {
    if (_mitraLat == null || _mitraLng == null) {
      await _requestLocationAndFetch();
    } else {
      await _fetchDashboardData(silent: true);
    }
  }

  // ============================================================
  // KONFIRMASI
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
                          color: _accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.local_offer_outlined,
                          color: _accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Konfirmasi Penawaran',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.grey900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: AppColors.grey500,
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
                      color: AppColors.grey700,
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
                            foregroundColor: AppColors.grey700,
                            side: const BorderSide(
                              color: AppColors.grey300,
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
                            foregroundColor: AppColors.white,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.sectionAltLight,
      child: RefreshIndicator(
        onRefresh: _onRefresh,
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

                  _buildLocationCard(),

                  const SizedBox(height: _gapBetweenSections),

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
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lowongan Tersedia',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.grey900,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Temukan pekerjaan yang sesuai dengan keahlianmu.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.grey500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOCATION + RADIUS CARD
  // ============================================================

  Widget _buildLocationCard() {
    final hasLocation = _mitraLat != null && _mitraLng != null;

    // -------- Belum ada lokasi --------
    if (!hasLocation) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.amber.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.location_off_outlined,
                color: AppColors.amber,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lokasi Belum Aktif',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey900,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Aktifkan lokasi untuk melihat job terdekat dari kamu.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.grey600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed:
                  _loadingLocation ? null : _requestLocationAndFetch,
              style: TextButton.styleFrom(
                foregroundColor: _accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: _loadingLocation
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Aktifkan',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
            ),
          ],
        ),
      );
    }

    // -------- Sudah ada lokasi --------
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _accent.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.radar,
                  color: _accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Radius Pencarian',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Sesuaikan jangkauan job dari lokasimu',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_radiusKm.round()} km',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _accent,
                  ),
                ),
              ),
            ],
          ),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _accent,
              thumbColor: _accent,
              overlayColor: _accent.withValues(alpha: 0.15),
              inactiveTrackColor: _accent.withValues(alpha: 0.15),
              trackHeight: 4,
            ),
            child: Slider(
              value: _radiusKm,
              min: 1,
              max: 20,
              divisions: 19,
              onChanged: (v) {
                setState(() => _radiusKm = v);
              },
              onChangeEnd: (_) => _fetchDashboardData(silent: true),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Daftar Lowongan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.grey900,
          ),
        ),
        const SizedBox(width: 8),
        if (_jobs.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_jobs.length}',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: _accent,
              ),
            ),
          ),
      ],
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
        color: AppColors.primaryTeal,
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
        color: AppColors.success,
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkTeal.withValues(alpha: 0.03),
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
              color: color.withValues(alpha: 0.12),
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
                    color: AppColors.grey500,
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
                    color: AppColors.grey900,
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
          _buildJobWithDistance(_jobs[i]),
          if (i != _jobs.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }

  // ============================================================
  // JOB CARD + DISTANCE BADGE
  // ============================================================

  Widget _buildJobWithDistance(PartnerJobModel job) {
    return Stack(
      children: [
        // Card asli
        PartnerJobCard(
          job: job,
          onTakeOffer: () => _showTakeOfferConfirmation(job),
        ),

        // Badge jarak — overlay di kanan atas
        if (job.distanceKm != null)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.near_me,
                    size: 12,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${job.distanceKm!.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
        color: AppColors.danger.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: AppColors.danger,
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.danger,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _bootstrap,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
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

  Widget _buildEmptyState() {
    final hasLocation = _mitraLat != null && _mitraLng != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasLocation ? Icons.search_off : Icons.work_outline,
              size: 34,
              color: _accent.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            hasLocation
                ? 'Belum ada lowongan di radius ${_radiusKm.round()} km.'
                : 'Belum ada lowongan pekerjaan saat ini.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.grey700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasLocation
                ? 'Coba perbesar radius atau refresh untuk job baru.'
                : 'Silakan cek lagi nanti.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.grey500,
              height: 1.5,
            ),
          ),
          if (hasLocation) ...[
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}