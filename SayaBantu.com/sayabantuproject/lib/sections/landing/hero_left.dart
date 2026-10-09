import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/responsive.dart';

class HeroLeft extends StatefulWidget {
  final VoidCallback onCariJasa;
  final VoidCallback onJadiMitra;
  final Function(String) onSearch;
  final bool isCompact;

  const HeroLeft({
    super.key,
    required this.onCariJasa,
    required this.onJadiMitra,
    required this.onSearch,
    this.isCompact = false,
  });

  @override
  State<HeroLeft> createState() => _HeroLeftState();
}

class _HeroLeftState extends State<HeroLeft> {
  final TextEditingController _searchController = TextEditingController();
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // API
  // ============================================================
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
      debugPrint('Error fetching hero stats: $e');
      return null;
    }
  }

  // ============================================================
  // HELPERS
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
    required String fallback,
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  String _compactNumber(String value) {
    final number = int.tryParse(value);
    if (number == null) return value;
    if (number >= 1000000) {
      final result = (number / 1000000).toStringAsFixed(1);
      return '${result.replaceAll('.0', '')}jt+';
    }
    if (number >= 1000) {
      final result = (number / 1000).toStringAsFixed(1);
      return '${result.replaceAll('.0', '')}rb+';
    }
    return number.toString();
  }

  bool _isPositive(String value) {
    final number = int.tryParse(value) ?? 0;
    return number > 0;
  }

  void _submitSearch() {
    widget.onSearch(_searchController.text.trim());
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final compact = widget.isCompact;
    final horizontalAlignment =
        isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    return FutureBuilder<Map<String, dynamic>?>(
      future: _statsFuture,
      builder: (context, snapshot) {
        final data = _extractData(snapshot.data);

        final ratingValue = _readString(
          data,
          ['rating_value', 'rating', 'average_rating'],
          fallback: '0',
        );
        final completedJobs = _readString(
          data,
          ['completed_jobs', 'total_completed_jobs', 'jobs_completed'],
          fallback: '0',
        );
        final verifiedMitra = _readString(
          data,
          [
            'verified_mitra_count',
            'mitra_count',
            'total_mitra',
            'active_mitra_count',
          ],
          fallback: '0',
        );

        final isLoading =
            snapshot.connectionState == ConnectionState.waiting;

        // ==========================================
        // SKALA UKURAN
        // ==========================================
        final gapBadgeHeadline = compact ? 14.0 : (isMobile ? 18.0 : 22.0);
        final gapHeadlineDesc = compact ? 12.0 : 18.0;
        final gapDescSearch = compact ? 18.0 : 28.0;
        final gapSearchLink = compact ? 8.0 : 14.0;
        final gapLinkStats = compact ? 20.0 : 30.0;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: horizontalAlignment,
          children: [
            // BADGE
            if (isLoading)
              _buildSkeletonBadge(compact: compact)
            else if (_isPositive(verifiedMitra))
              _buildVerifiedBadge(verifiedMitra, compact: compact)
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(
                    begin: 0.05,
                    end: 0,
                    curve: Curves.easeOutCubic,
                    duration: 500.ms,
                  )
            else
              _buildTrustBadge(compact: compact)
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(
                    begin: 0.05,
                    end: 0,
                    curve: Curves.easeOutCubic,
                    duration: 500.ms,
                  ),

            SizedBox(height: gapBadgeHeadline),

            // HEADLINE
            _buildHeadline(isMobile: isMobile, compact: compact)
                .animate(delay: 100.ms)
                .fadeIn(duration: 600.ms)
                .slideY(
                  begin: 0.10,
                  end: 0,
                  curve: Curves.easeOutCubic,
                  duration: 600.ms,
                ),

            SizedBox(height: gapHeadlineDesc),

            // DESCRIPTION
            _buildDescription(isMobile: isMobile, compact: compact)
                .animate(delay: 200.ms)
                .fadeIn(duration: 600.ms)
                .slideY(
                  begin: 0.08,
                  end: 0,
                  curve: Curves.easeOutCubic,
                  duration: 600.ms,
                ),

            SizedBox(height: gapDescSearch),

            // SEARCH BAR
            _buildSearchBar(isMobile: isMobile, compact: compact)
                .animate(delay: 300.ms)
                .fadeIn(duration: 600.ms)
                .slideY(
                  begin: 0.08,
                  end: 0,
                  curve: Curves.easeOutCubic,
                  duration: 600.ms,
                ),

            SizedBox(height: gapSearchLink),

            // SECONDARY LINK
            _buildSecondaryLink(compact: compact)
                .animate(delay: 400.ms)
                .fadeIn(duration: 600.ms),

            SizedBox(height: gapLinkStats),

            // STATISTICS
            if (isLoading)
              _buildSkeletonStats(isMobile: isMobile, compact: compact)
                  .animate(delay: 500.ms)
                  .fadeIn(duration: 500.ms)
            else
              _buildStatistics(
                ratingValue: ratingValue,
                completedJobs: completedJobs,
                isMobile: isMobile,
                compact: compact,
              ).animate(delay: 500.ms).fadeIn(duration: 600.ms),
          ],
        );
      },
    );
  }

  // ============================================================
  // BADGE
  // ============================================================
  Widget _buildVerifiedBadge(
    String verifiedMitra, {
    required bool compact,
  }) {
    final count = _compactNumber(verifiedMitra);
    final fontSize = compact ? 10.0 : 11.5;
    final iconSize = compact ? 13.0 : 15.0;
    final padH = compact ? 12.0 : 14.0;
    final padV = compact ? 6.0 : 8.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: AppColors.darkTeal.withOpacity(0.6),
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
            Icons.verified_rounded,
            color: AppColors.mint,
            size: iconSize,
          ),
          const SizedBox(width: 6),
          Text(
            '$count Mitra Terverifikasi',
            style: AppTextStyles.labelOnDark.copyWith(fontSize: fontSize),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge({required bool compact}) {
    final fontSize = compact ? 10.0 : 11.5;
    final iconSize = compact ? 13.0 : 15.0;
    final padH = compact ? 12.0 : 14.0;
    final padV = compact ? 6.0 : 8.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: AppColors.darkTeal.withOpacity(0.6),
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
            Icons.shield_outlined,
            color: AppColors.mint,
            size: iconSize,
          ),
          const SizedBox(width: 6),
          Text(
            'Mitra Terverifikasi & Pembayaran Aman',
            style: AppTextStyles.labelOnDark.copyWith(fontSize: fontSize),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonBadge({required bool compact}) {
    return Container(
      width: compact ? 180 : 220,
      height: compact ? 26 : 32,
      decoration: BoxDecoration(
        color: AppColors.darkTeal.withOpacity(0.4),
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }

  // ============================================================
  // HEADLINE
  // ============================================================
  Widget _buildHeadline({
    required bool isMobile,
    required bool compact,
  }) {
    final double titleSize;
    if (compact) {
      titleSize = 26;
    } else if (isMobile) {
      titleSize = 32;
    } else {
      titleSize = Responsive.titleSize(context);
    }

    return Semantics(
      header: true,
      child: SizedBox(
        width: double.infinity,
        child: RichText(
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          text: TextSpan(
            style: AppTextStyles.displayOnDark.copyWith(
              fontSize: titleSize,
              height: 1.12,
            ),
            children: [
              const TextSpan(text: 'Butuh Bantuan di Rumah?\n'),
              TextSpan(
                text: 'Pesan Jasa, ',
                style: AppTextStyles.displayAccentOnDark.copyWith(
                  fontSize: titleSize,
                  height: 1.12,
                ),
              ),
              const TextSpan(text: 'Tepat Harga.'),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DESCRIPTION
  // ============================================================
  Widget _buildDescription({
    required bool isMobile,
    required bool compact,
  }) {
    final fontSize = compact ? 12.5 : (isMobile ? 13.0 : 14.5);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Text(
        'Posting kebutuhanmu, terima penawaran dari mitra terverifikasi, '
        'dan nego langsung. Transparan, aman, dan kamu yang pegang kendali.',
        textAlign: isMobile ? TextAlign.center : TextAlign.left,
        style: AppTextStyles.bodyOnDark.copyWith(
          fontSize: fontSize,
          height: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================
  Widget _buildSearchBar({
    required bool isMobile,
    required bool compact,
  }) {
    final height = compact ? 46.0 : 56.0;
    final iconSize = compact ? 17.0 : 20.0;
    final hintFont = compact ? 12.0 : 13.5;
    final buttonWidth = compact ? 82.0 : (isMobile ? 100.0 : 118.0);
    final buttonFont = compact ? 11.0 : (isMobile ? 12.0 : 13.0);
    final buttonHeight = compact ? 36.0 : 44.0;
    final padLeft = compact ? 12.0 : 16.0;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(compact ? 12 : 15),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.25),
              blurRadius: compact ? 16 : 24,
              offset: Offset(0, compact ? 6 : 10),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: padLeft),
            Icon(
              Icons.search_rounded,
              color: AppColors.primaryTeal,
              size: iconSize,
            ),
            SizedBox(width: compact ? 8 : 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _submitSearch(),
                style: TextStyle(fontSize: compact ? 12.5 : 13.5),
                decoration: InputDecoration(
                  hintText: 'Mau jasa apa hari ini?',
                  hintStyle: AppTextStyles.bodySmallOnLight.copyWith(
                    color: AppColors.grey500,
                    fontSize: hintFont,
                  ),
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
              ),
            ),
            SizedBox(width: compact ? 4 : 6),
            Material(
              color: AppColors.primaryTeal,
              borderRadius: BorderRadius.circular(compact ? 9 : 12),
              child: InkWell(
                onTap: _submitSearch,
                borderRadius: BorderRadius.circular(compact ? 9 : 12),
                child: SizedBox(
                  width: buttonWidth,
                  height: buttonHeight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Cari',
                        style: AppTextStyles.buttonSearch.copyWith(
                          fontSize: buttonFont,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.white,
                        size: compact ? 13 : 15,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: compact ? 4 : 6),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECONDARY LINK
  // ============================================================
  Widget _buildSecondaryLink({required bool compact}) {
    return Center(
      child: TextButton.icon(
        onPressed: widget.onJadiMitra,
        icon: Icon(
          Icons.person_outline_rounded,
          size: compact ? 13 : 15,
        ),
        label: Text(
          'Ingin jadi mitra? Daftar sekarang',
          style: TextStyle(
            fontSize: compact ? 11.5 : 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.mint,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 8,
            vertical: compact ? 2 : 4,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================
  Widget _buildStatistics({
    required String ratingValue,
    required String completedJobs,
    required bool isMobile,
    required bool compact,
  }) {
    final items = <Widget>[];

    if (_isPositive(ratingValue)) {
      items.add(HeroInfo(
        icon: Icons.star_rounded,
        value: ratingValue,
        label: 'Rating',
      ));
    }
    if (_isPositive(completedJobs)) {
      items.add(HeroInfo(
        icon: Icons.check_circle_rounded,
        value: _compactNumber(completedJobs),
        label: 'Job Selesai',
      ));
    }
    items.add(const HeroInfo(
      icon: Icons.card_giftcard_rounded,
      value: 'Gratis',
      label: 'Biaya Posting',
    ));

    return Wrap(
      alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
      spacing: compact ? 18 : (isMobile ? 22 : 34),
      runSpacing: compact ? 12 : 16,
      children: items,
    );
  }

  Widget _buildSkeletonStats({
    required bool isMobile,
    required bool compact,
  }) {
    return Row(
      mainAxisAlignment:
          isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: List.generate(
        3,
        (i) => Container(
          margin: EdgeInsets.only(right: compact ? 16 : 24),
          width: compact ? 56 : 70,
          height: compact ? 34 : 42,
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HERO INFO
// ============================================================
class HeroInfo extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const HeroInfo({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isSmall = MediaQuery.of(context).size.width < 400;

    return Column(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.mint, size: isSmall ? 15 : 18),
            SizedBox(width: isSmall ? 4 : 6),
            Text(
              value,
              style: AppTextStyles.statValue.copyWith(
                fontSize: isSmall ? 15 : 18,
              ),
            ),
          ],
        ),
        SizedBox(height: isSmall ? 2 : 4),
        Text(
          label,
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: AppTextStyles.statLabel.copyWith(
            fontSize: isSmall ? 10 : 11,
          ),
        ),
      ],
    );
  }
}