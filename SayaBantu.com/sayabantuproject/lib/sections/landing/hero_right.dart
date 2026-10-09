import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class HeroRight extends StatefulWidget {
  const HeroRight({super.key});

  @override
  State<HeroRight> createState() => _HeroRightState();
}

class _HeroRightState extends State<HeroRight> {
  late Future<Map<String, dynamic>?> _offersFuture;

  String get _baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    return 'http://10.0.2.2:8000/api';
  }

  @override
  void initState() {
    super.initState();
    _offersFuture = _fetchOffers();
  }

  Future<Map<String, dynamic>?> _fetchOffers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/landing-hero-offers'),
        headers: const {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) return null;

      final body = json.decode(response.body);
      if (body is Map && body['success'] == true) {
        final data = body['data'];
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching hero offers: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 400;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 440.0;

        return FutureBuilder<Map<String, dynamic>?>(
          future: _offersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                width: cardWidth,
                height: isSmallMobile ? 240 : 340,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.mint,
                    strokeWidth: 2.5,
                  ),
                ),
              );
            }

            final data = snapshot.data ?? const {};

            final List offers = data['offers'] is List
                ? data['offers'] as List
                : const [];

            final activeMitraCount =
                data['active_mitra_count']?.toString() ?? '0';

            final title =
                data['title']?.toString() ?? 'PENAWARAN MASUK';

            final hasOffers = offers.isNotEmpty;

            return SizedBox(
              width: cardWidth,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ====================================================
                  // KARTU UTAMA
                  // ====================================================
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(
                      top: isSmallMobile ? 16 : 22,
                      bottom: isSmallMobile ? 14 : 20,
                      right: isSmallMobile ? 6 : 10,
                    ),
                    padding: EdgeInsets.fromLTRB(
                      isSmallMobile ? 14 : 20,
                      isSmallMobile ? 18 : 24,
                      isSmallMobile ? 14 : 20,
                      isSmallMobile ? 18 : 28,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg.withOpacity(0.96),
                      borderRadius: BorderRadius.circular(
                        isSmallMobile ? 18 : 24,
                      ),
                      border: Border.all(
                        color: AppColors.mint.withOpacity(0.20),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow.withOpacity(0.30),
                          blurRadius: isSmallMobile ? 24 : 35,
                          offset: Offset(0, isSmallMobile ? 12 : 18),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // HEADER
                        Row(
                          children: [
                            Container(
                              width: isSmallMobile ? 28 : 34,
                              height: isSmallMobile ? 28 : 34,
                              decoration: BoxDecoration(
                                color: AppColors.mint.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(
                                  isSmallMobile ? 8 : 10,
                                ),
                              ),
                              child: Icon(
                                Icons.assignment_outlined,
                                color: AppColors.mint,
                                size: isSmallMobile ? 15 : 19,
                              ),
                            ),
                            SizedBox(width: isSmallMobile ? 8 : 10),
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.mockupTitle.copyWith(
                                  fontSize: isSmallMobile ? 10 : 12,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: isSmallMobile ? 14 : 20),

                        // LIST / EMPTY
                        if (offers.isEmpty)
                          _buildEmptyState(isSmallMobile: isSmallMobile)
                        else
                          ...offers.take(3).map((offer) {
                            final item = offer is Map
                                ? Map<String, dynamic>.from(offer)
                                : <String, dynamic>{};

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: isSmallMobile ? 8 : 10,
                              ),
                              child: _offerItem(
                                active: item['active'] == true,
                                initials:
                                    item['initials']?.toString() ?? 'M',
                                name: item['name']?.toString() ?? 'Mitra',
                                rating:
                                    item['rating']?.toString() ?? '5.0',
                                point:
                                    item['point']?.toString() ?? '0 poin',
                                price:
                                    item['price']?.toString() ?? 'Rp 0',
                                badge: item['badge']?.toString(),
                                isSmallMobile: isSmallMobile,
                              ),
                            );
                          }),

                        SizedBox(height: isSmallMobile ? 8 : 12),

                        // CTA
                        SizedBox(
                          width: double.infinity,
                          height: isSmallMobile ? 40 : 48,
                          child: ElevatedButton.icon(
                            onPressed: hasOffers ? () {} : null,
                            icon: Icon(
                              Icons.check_circle_outline,
                              size: isSmallMobile ? 15 : 18,
                            ),
                            label: Text(
                              'Terima Mitra Terbaik',
                              style: TextStyle(
                                fontSize: isSmallMobile ? 11.5 : 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.mint,
                              foregroundColor: AppColors.darkTeal,
                              disabledBackgroundColor:
                                  AppColors.grey500.withOpacity(0.4),
                              disabledForegroundColor:
                                  AppColors.white.withOpacity(0.6),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  isSmallMobile ? 10 : 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // BADGE VERIFIKASI
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _buildVerifiedPill(isSmallMobile: isSmallMobile),
                  ),

                  // BADGE ONLINE
                  Positioned(
                    bottom: 0,
                    left: isSmallMobile ? 10 : 16,
                    child: _buildOnlinePill(
                      activeMitraCount,
                      isSmallMobile: isSmallMobile,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // BADGE WIDGETS
  // ============================================================
  Widget _buildVerifiedPill({required bool isSmallMobile}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallMobile ? 8 : 12,
        vertical: isSmallMobile ? 6 : 9,
      ),
      decoration: BoxDecoration(
        color: AppColors.lightMint,
        borderRadius: BorderRadius.circular(isSmallMobile ? 10 : 13),
        border: Border.all(
          color: AppColors.white.withOpacity(0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkTeal.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            color: AppColors.primaryTeal,
            size: isSmallMobile ? 13 : 17,
          ),
          SizedBox(width: isSmallMobile ? 5 : 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terverifikasi',
                style: AppTextStyles.badgeVerifiedTitle.copyWith(
                  fontSize: isSmallMobile ? 9.5 : 11,
                ),
              ),
              Text(
                'Admin reviewed',
                style: AppTextStyles.badgeVerifiedSubtitle.copyWith(
                  fontSize: isSmallMobile ? 8 : 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOnlinePill(
    String activeMitraCount, {
    required bool isSmallMobile,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallMobile ? 10 : 13,
        vertical: isSmallMobile ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBgSoft,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.mint.withOpacity(0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkTeal.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isSmallMobile ? 6 : 8,
            height: isSmallMobile ? 6 : 8,
            decoration: const BoxDecoration(
              color: AppColors.onlineGreen,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isSmallMobile ? 6 : 8),
          Text(
            '$activeMitraCount mitra online sekarang',
            style: AppTextStyles.badgeOnline.copyWith(
              fontSize: isSmallMobile ? 9.5 : 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================
  Widget _buildEmptyState({required bool isSmallMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallMobile ? 12 : 16,
        vertical: isSmallMobile ? 22 : 30,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBgSoft,
        borderRadius: BorderRadius.circular(isSmallMobile ? 12 : 16),
        border: Border.all(
          color: AppColors.mint.withOpacity(0.12),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: isSmallMobile ? 42 : 52,
            height: isSmallMobile ? 42 : 52,
            decoration: BoxDecoration(
              color: AppColors.mint.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              color: AppColors.lightMint,
              size: isSmallMobile ? 20 : 25,
            ),
          ),
          SizedBox(height: isSmallMobile ? 10 : 13),
          Text(
            'Belum ada penawaran masuk',
            textAlign: TextAlign.center,
            style: AppTextStyles.mockupEmptyTitle.copyWith(
              fontSize: isSmallMobile ? 11.5 : 13,
            ),
          ),
          SizedBox(height: isSmallMobile ? 3 : 5),
          Text(
            'Penawaran dari mitra akan muncul di sini.',
            textAlign: TextAlign.center,
            style: AppTextStyles.mockupEmptySubtitle.copyWith(
              fontSize: isSmallMobile ? 9.5 : 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OFFER ITEM
  // ============================================================
  Widget _offerItem({
    required String initials,
    required String name,
    required String rating,
    required String point,
    required String price,
    String? badge,
    bool active = false,
    required bool isSmallMobile,
  }) {
    final avatarRadius = isSmallMobile ? 15.0 : 19.0;
    final nameFont = isSmallMobile ? 11.0 : 12.0;
    final metaFont = isSmallMobile ? 9.5 : 11.0;
    final metaSoftFont = isSmallMobile ? 9.0 : 10.0;
    final priceFont = isSmallMobile ? 11.0 : 12.0;
    final badgeFont = isSmallMobile ? 8.0 : 9.0;
    final padH = isSmallMobile ? 10.0 : 12.0;
    final padV = isSmallMobile ? 9.0 : 12.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: active ? AppColors.cardBgHover : AppColors.cardBgItem,
        borderRadius: BorderRadius.circular(isSmallMobile ? 11 : 14),
        border: Border.all(
          color: active
              ? AppColors.mint.withOpacity(0.65)
              : AppColors.white.withOpacity(0.07),
          width: active ? 1.2 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: active
                ? AppColors.mint.withOpacity(0.25)
                : AppColors.avatarBg,
            child: Text(
              initials,
              style: TextStyle(
                color: AppColors.lightMint,
                fontWeight: FontWeight.bold,
                fontSize: isSmallMobile ? 10 : 12,
              ),
            ),
          ),
          SizedBox(width: isSmallMobile ? 8 : 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.mockupName.copyWith(
                    fontSize: nameFont,
                  ),
                ),
                SizedBox(height: isSmallMobile ? 3 : 5),
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: AppColors.starYellow,
                      size: isSmallMobile ? 11 : 14,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      rating,
                      style: AppTextStyles.mockupMeta.copyWith(
                        fontSize: metaFont,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '• $point',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.mockupMetaSoft.copyWith(
                          fontSize: metaSoftFont,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: isSmallMobile ? 6 : 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (active
                        ? AppTextStyles.mockupPriceActive
                        : AppTextStyles.mockupPrice)
                    .copyWith(fontSize: priceFont),
              ),
              if (badge != null && badge.isNotEmpty) ...[
                SizedBox(height: isSmallMobile ? 3 : 5),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallMobile ? 5 : 7,
                    vertical: isSmallMobile ? 2 : 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mint.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    badge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.mockupBadge.copyWith(
                      fontSize: badgeFont,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}