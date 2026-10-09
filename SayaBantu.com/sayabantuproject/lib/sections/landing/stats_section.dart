import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'stat_counter.dart';

class StatsSection extends StatefulWidget {
  const StatsSection({super.key});

  @override
  State<StatsSection> createState() => _StatsSectionState();
}

class _StatsSectionState extends State<StatsSection> {
  late Future<Map<String, dynamic>?> _statsFuture;

  String get _baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    return 'http://10.0.2.2:8000/api';
  }

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchStats();
  }

  Future<Map<String, dynamic>?> _fetchStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/landing-stats'),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) return null;
      final body = json.decode(response.body);
      if (body is! Map<String, dynamic>) return null;
      if (body['success'] != true) return null;
      return body;
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final isSmallMobile = width < 400;
        final isMobile = width < 768;
        final isTablet = width >= 768 && width < 1100;

        final horizontalPadding = isSmallMobile
            ? 16.0
            : isMobile
                ? 20.0
                : isTablet
                    ? 36.0
                    : 64.0;

        final verticalPadding = isSmallMobile
            ? 40.0
            : isMobile
                ? 48.0
                : isTablet
                    ? 64.0
                    : 88.0;

        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.sectionGradientStart,
                AppColors.sectionGradientEnd,
              ],
            ),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: -60,
                bottom: -60,
                child: IgnorePointer(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.mint.withOpacity(0.06),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -80,
                top: -80,
                child: IgnorePointer(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: FutureBuilder<Map<String, dynamic>?>(
                      future: _statsFuture,
                      builder: (context, snapshot) {
                        final isLoading =
                            snapshot.connectionState ==
                                ConnectionState.waiting;
                        final data = _extractData(snapshot.data);

                        if (!isLoading && data.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final titleSize = isSmallMobile
                            ? 22.0
                            : isMobile
                                ? 26.0
                                : 42.0;

                        final descSize = isSmallMobile
                            ? 12.5
                            : isMobile
                                ? 13.5
                                : 16.0;

                        return Column(
                          children: [
                            _buildSectionLabel(isSmallMobile: isSmallMobile)
                                .animate()
                                .fadeIn(duration: 500.ms)
                                .slideY(
                                  begin: 0.10,
                                  end: 0,
                                  duration: 500.ms,
                                  curve: Curves.easeOutCubic,
                                ),

                            SizedBox(height: isSmallMobile ? 10 : 14),

                            Text(
                              'Dipercaya Ribuan\nPelanggan & Mitra',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.displayOnDark.copyWith(
                                fontSize: titleSize,
                                height: 1.15,
                              ),
                            )
                                .animate(delay: 100.ms)
                                .fadeIn(duration: 600.ms)
                                .slideY(
                                  begin: 0.10,
                                  end: 0,
                                  duration: 600.ms,
                                  curve: Curves.easeOutCubic,
                                ),

                            SizedBox(height: isSmallMobile ? 8 : 12),

                            ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 560),
                              child: Text(
                                'Angka nyata dari platform kami '
                                'yang terus berkembang',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyOnDark.copyWith(
                                  fontSize: descSize,
                                  height: 1.5,
                                ),
                              ),
                            )
                                .animate(delay: 200.ms)
                                .fadeIn(duration: 600.ms),

                            SizedBox(
                              height: isSmallMobile
                                  ? 28
                                  : isMobile
                                      ? 36
                                      : 64,
                            ),

                            if (isLoading)
                              _buildSkeletonGrid(
                                isMobile: isMobile,
                                isSmallMobile: isSmallMobile,
                              )
                            else
                              _buildStatsGrid(
                                data: data,
                                isMobile: isMobile,
                                isTablet: isTablet,
                                isSmallMobile: isSmallMobile,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // SECTION LABEL
  // ============================================================
  Widget _buildSectionLabel({required bool isSmallMobile}) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallMobile ? 11 : 14,
          vertical: isSmallMobile ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.darkTeal.withOpacity(0.5),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppColors.mint.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insights_rounded,
              color: AppColors.mint,
              size: isSmallMobile ? 12 : 14,
            ),
            SizedBox(width: isSmallMobile ? 6 : 8),
            Text(
              'STATISTIK PLATFORM',
              style: TextStyle(
                color: AppColors.lightMint,
                fontSize: isSmallMobile ? 10 : 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EXTRACT DATA
  // ============================================================
  Map<String, dynamic> _extractData(Map<String, dynamic>? response) {
    if (response == null) return {};
    final rawData = response['data'];
    if (rawData is Map<String, dynamic>) return rawData;
    if (rawData is Map) return Map<String, dynamic>.from(rawData);
    return response;
  }

  String _readString(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  bool _isPositive(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return value.trim().isNotEmpty;
    return (int.tryParse(cleaned) ?? 0) > 0;
  }

  // ============================================================
  // STATS GRID
  // ============================================================
  Widget _buildStatsGrid({
    required Map<String, dynamic> data,
    required bool isMobile,
    required bool isTablet,
    required bool isSmallMobile,
  }) {
    final completedJobs = _readString(
      data,
      ['completed_jobs', 'total_completed_jobs', 'jobs_completed'],
    );
    final completedSubtitle = _readString(
      data,
      ['completed_subtitle', 'job_subtitle'],
      fallback: 'total diselesaikan',
    );

    final verifiedMitra = _readString(
      data,
      [
        'verified_mitra_count',
        'mitra_count',
        'total_mitra',
        'active_mitra_count',
      ],
    );
    final verifiedSubtitle = _readString(
      data,
      ['verified_subtitle', 'mitra_subtitle'],
      fallback: 'mitra terverifikasi',
    );

    final ratingValue = _readString(
      data,
      ['rating_value', 'rating', 'average_rating'],
    );
    final ratingSubtitle = _readString(
      data,
      ['rating_subtitle'],
      fallback: 'dari ulasan pelanggan',
    );

    final items = <Widget>[];

    if (_isPositive(completedJobs)) {
      items.add(StatCounter(
        icon: Icons.task_alt_rounded,
        value: completedJobs,
        title: 'Pekerjaan Selesai',
        subtitle: completedSubtitle,
        isCompact: isMobile,
      ));
    }
    if (_isPositive(verifiedMitra)) {
      items.add(StatCounter(
        icon: Icons.handyman_rounded,
        value: verifiedMitra,
        title: 'Mitra Terverifikasi',
        subtitle: verifiedSubtitle,
        isCompact: isMobile,
      ));
    }
    if (_isPositive(ratingValue)) {
      items.add(StatCounter(
        icon: Icons.star_rounded,
        value: ratingValue,
        title: 'Rating Rata-rata',
        subtitle: ratingSubtitle,
        isCompact: isMobile,
      ));
    }

    // Biaya Pasang Iklan — HANYA 1 card (hapus duplikat)
    items.add(StatCounter(
      icon: Icons.card_giftcard_rounded,
      value: 'Rp 0',
      title: 'Biaya Pasang Iklan',
      subtitle: 'posting gratis selamanya',
      isCompact: isMobile,
    ));

    if (items.isEmpty) return const SizedBox.shrink();

    // ============================================================
    // Tentukan maxPerRow
    // ============================================================
    final int itemCount = items.length;
    final int maxPerRow;
    if (isMobile) {
      maxPerRow = 1;
    } else if (isTablet) {
      maxPerRow = itemCount <= 3 ? 3 : 2;
    } else {
      maxPerRow = 4;
    }

    // ============================================================
    // Split items jadi rows
    // ============================================================
    final List<List<Widget>> rows = [];

    if (itemCount <= maxPerRow) {
      rows.add(items);
    } else {
      for (int i = 0; i < itemCount; i += maxPerRow) {
        final end = (i + maxPerRow > itemCount) ? itemCount : i + maxPerRow;
        rows.add(items.sublist(i, end));
      }
    }

    return Column(
      children: [
        for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
          _buildCardRow(
            cards: rows[rowIndex],
            maxPerRow: maxPerRow,
            startIndex: rowIndex * maxPerRow,
            isSmallMobile: isSmallMobile,
          ),
          if (rowIndex < rows.length - 1)
            SizedBox(height: isSmallMobile ? 10 : (isMobile ? 12 : 20)),
        ],
      ],
    );
  }

  // ============================================================
  // BUILD CARD ROW
  // ============================================================
  Widget _buildCardRow({
    required List<Widget> cards,
    required int maxPerRow,
    required int startIndex,
    required bool isSmallMobile,
  }) {
    final bool isFullRow = cards.length == maxPerRow;

    if (isFullRow) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            Expanded(
              child: cards[i]
                  .animate(
                    delay: Duration(
                      milliseconds: 400 + ((startIndex + i) * 120),
                    ),
                  )
                  .fadeIn(duration: 500.ms)
                  .slideY(
                    begin: 0.15,
                    end: 0,
                    duration: 500.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ),
            if (i < cards.length - 1)
              SizedBox(width: isSmallMobile ? 10 : 16),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(
            child: cards[i]
                .animate(
                  delay: Duration(
                    milliseconds: 400 + ((startIndex + i) * 120),
                  ),
                )
                .fadeIn(duration: 500.ms)
                .slideY(
                  begin: 0.15,
                  end: 0,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
                ),
          ),
          if (i < cards.length - 1)
            SizedBox(width: isSmallMobile ? 10 : 16),
        ],
        const Spacer(),
      ],
    );
  }

  // ============================================================
  // SKELETON
  // ============================================================
  Widget _buildSkeletonGrid({
    required bool isMobile,
    required bool isSmallMobile,
  }) {
    final cardCount = isMobile ? 1 : 4;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile) const Spacer(),
        for (int i = 0; i < cardCount; i++) ...[
          Expanded(
            child: Container(
              height: isSmallMobile ? 100 : 170,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(
                  isSmallMobile ? 14 : 20,
                ),
              ),
            ),
          ),
          if (i < cardCount - 1)
            SizedBox(width: isSmallMobile ? 10 : 16),
        ],
        if (isMobile) const Spacer(),
      ],
    );
  }
}