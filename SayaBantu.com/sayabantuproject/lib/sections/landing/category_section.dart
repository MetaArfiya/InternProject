import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/safe_mouse_region.dart';

// ============================================================
// CATEGORY MODEL
// ============================================================
class _CategoryItem {
  final IconData icon;
  final String title;
  final String subtitle;

  const _CategoryItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

// ============================================================
// CATEGORY SECTION
// ============================================================
class CategorySection extends StatefulWidget {
  const CategorySection({super.key});

  @override
  State<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<CategorySection> {
  final List<_CategoryItem> categories = const [
    _CategoryItem(
      icon: Icons.home_repair_service_rounded,
      title: 'Perbaikan & Perawatan Rumah',
      subtitle: 'Layanan rumah',
    ),
    _CategoryItem(
      icon: Icons.cleaning_services_rounded,
      title: 'Kebersihan',
      subtitle: 'Layanan kebersihan',
    ),
    _CategoryItem(
      icon: Icons.construction_rounded,
      title: 'Konstruksi & Renovasi',
      subtitle: 'Layanan konstruksi',
    ),
    _CategoryItem(
      icon: Icons.build_rounded,
      title: 'Instalasi & Teknisi',
      subtitle: 'Layanan teknisi',
    ),
    _CategoryItem(
      icon: Icons.home_rounded,
      title: 'Jasa Rumah Tangga',
      subtitle: 'Layanan rumah tangga',
    ),
    _CategoryItem(
      icon: Icons.handyman_rounded,
      title: 'Jasa Umum',
      subtitle: 'Berbagai layanan',
    ),
    _CategoryItem(
      icon: Icons.add_circle_outline_rounded,
      title: 'Lainnya',
      subtitle: 'Kategori lainnya',
    ),
  ];

  void _onCategoryTap(_CategoryItem category) {
    debugPrint('Tap kategori: ${category.title}');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.sectionLight,
      child: LayoutBuilder(
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

          final titleSize = isSmallMobile
              ? 22.0
              : isMobile
                  ? 26.0
                  : isTablet
                      ? 34.0
                      : 42.0;

          final descSize = isSmallMobile
              ? 12.5
              : isMobile
                  ? 13.5
                  : 15.0;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel()
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideX(
                          begin: -0.08,
                          end: 0,
                          duration: 500.ms,
                          curve: Curves.easeOutCubic,
                        ),

                    SizedBox(height: isSmallMobile ? 10 : 14),

                    Text(
                      'Semua Kebutuhan\nRumahmu Ada Di Sini',
                      style: AppTextStyles.displayOnLight.copyWith(
                        fontSize: titleSize,
                        height: 1.15,
                      ),
                    )
                        .animate(delay: 120.ms)
                        .fadeIn(duration: 600.ms)
                        .slideY(
                          begin: 0.08,
                          end: 0,
                          delay: 120.ms,
                          duration: 600.ms,
                          curve: Curves.easeOutCubic,
                        ),

                    SizedBox(height: isSmallMobile ? 10 : 14),

                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: Text(
                        'Temukan berbagai layanan rumah tangga dan tenaga '
                        'profesional yang siap membantu kebutuhanmu.',
                        style: AppTextStyles.bodyOnLight.copyWith(
                          fontSize: descSize,
                          height: 1.5,
                        ),
                      ),
                    )
                        .animate(delay: 220.ms)
                        .fadeIn(duration: 600.ms),

                    SizedBox(
                      height: isSmallMobile
                          ? 20
                          : isMobile
                              ? 26
                              : isTablet
                                  ? 32
                                  : 40,
                    ),

                    if (categories.isEmpty)
                      _buildEmptyFallback()
                    else if (isMobile)
                      _buildMobileCategories(isSmallMobile: isSmallMobile)
                    else
                      _buildGridCategories(isTablet: isTablet),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionLabel() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.mint,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'KATEGORI LAYANAN',
          style: TextStyle(
            color: AppColors.primaryTeal,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileCategories({required bool isSmallMobile}) {
    final cardWidth = isSmallMobile ? 180.0 : 210.0;
    final cardHeight = isSmallMobile ? 150.0 : 165.0;

    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: categories.length,
        separatorBuilder: (_, __) =>
            SizedBox(width: isSmallMobile ? 10 : 14),
        itemBuilder: (context, index) {
          final category = categories[index];

          return SizedBox(
            width: cardWidth,
            child: _CategoryCard(
              category: category,
              animationDelay: index * 60,
              onTap: () => _onCategoryTap(category),
              isCompact: isSmallMobile,
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridCategories({required bool isTablet}) {
    final cardHeight = isTablet ? 118.0 : 120.0;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 2 : 4,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        mainAxisExtent: cardHeight,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];

        return _CategoryCard(
          category: category,
          animationDelay: index * 60,
          onTap: () => _onCategoryTap(category),
        );
      },
    );
  }

  Widget _buildEmptyFallback() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Text(
        'Belum ada kategori tersedia.',
        style: AppTextStyles.bodySmallOnLight,
      ),
    );
  }
}

// ============================================================
// CATEGORY CARD
// ============================================================
class _CategoryCard extends StatefulWidget {
  final _CategoryItem category;
  final int animationDelay;
  final VoidCallback? onTap;
  final bool isCompact;

  const _CategoryCard({
    required this.category,
    required this.animationDelay,
    this.onTap,
    this.isCompact = false,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final active = _isHovered || _isPressed;
    final compact = widget.isCompact;

    final cardPadding = compact ? 14.0 : 18.0;
    final iconBox = compact ? 42.0 : 52.0;
    final iconSize = compact ? 20.0 : 25.0;
    final iconRadius = compact ? 12.0 : 15.0;
    final gapIconText = compact ? 11.0 : 14.0;
    final titleSize = compact ? 13.5 : 15.0;
    final subtitleSize = compact ? 11.0 : 12.0;
    final gapTitleSub = compact ? 3.0 : 5.0;
    final arrowSize = compact ? 15.0 : 18.0;
    final cardRadius = compact ? 14.0 : 18.0;

    return SafeMouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: () => setState(() => _isHovered = true),
      onExit: () => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(cardRadius),
              border: Border.all(
                color: active
                    ? AppColors.mint
                    : AppColors.primaryTeal.withOpacity(0.12),
                width: active ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkTeal.withOpacity(
                    active ? 0.14 : 0.06,
                  ),
                  blurRadius: active ? 22 : 12,
                  offset: Offset(0, active ? 8 : 4),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: iconBox,
                  height: iconBox,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primaryTeal
                        : AppColors.primaryTeal.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(iconRadius),
                  ),
                  child: Icon(
                    widget.category.icon,
                    size: iconSize,
                    color: active
                        ? AppColors.white
                        : AppColors.primaryTeal,
                  ),
                ),
                SizedBox(width: gapIconText),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headingSmall.copyWith(
                          fontSize: titleSize,
                          color: AppColors.grey900,
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: gapTitleSub),
                      Text(
                        widget.category.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmallOnLight.copyWith(
                          color: AppColors.primaryTeal,
                          fontSize: subtitleSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedSlide(
                  duration: const Duration(milliseconds: 200),
                  offset: active
                      ? const Offset(0.12, 0)
                      : Offset.zero,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: arrowSize,
                    color: active
                        ? AppColors.primaryTeal
                        : AppColors.grey400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: widget.animationDelay),
          duration: 500.ms,
        )
        .slideY(
          begin: 0.08,
          end: 0,
          delay: Duration(milliseconds: widget.animationDelay),
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
  }
}