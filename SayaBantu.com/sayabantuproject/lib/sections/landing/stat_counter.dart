import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/safe_mouse_region.dart';

class StatCounter extends StatefulWidget {
  final IconData icon;
  final String value;
  final String title;
  final String subtitle;
  final bool showDivider;
  final bool isCompact;

  const StatCounter({
    super.key,
    required this.icon,
    required this.value,
    required this.title,
    required this.subtitle,
    this.showDivider = true,
    this.isCompact = false,
  });

  @override
  State<StatCounter> createState() => _StatCounterState();
}

class _StatCounterState extends State<StatCounter> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 400;
    final isMobile = screenWidth < 768;

    // ==========================================
    // SKALA UKURAN
    // ==========================================
    final cardPadding = widget.isCompact
        ? (isSmallMobile ? 14.0 : 16.0)
        : (isSmallMobile ? 16.0 : 20.0);

    final iconBox = widget.isCompact
        ? (isSmallMobile ? 32.0 : 36.0)
        : (isSmallMobile ? 38.0 : 44.0);

    final iconSize = widget.isCompact
        ? (isSmallMobile ? 16.0 : 18.0)
        : (isSmallMobile ? 18.0 : 22.0);

    final iconRadius = widget.isCompact
        ? (isSmallMobile ? 10.0 : 11.0)
        : (isSmallMobile ? 11.0 : 13.0);

    final gapIconValue = widget.isCompact
        ? (isSmallMobile ? 8.0 : 10.0)
        : (isSmallMobile ? 10.0 : 14.0);

    final valueFont = widget.isCompact
        ? (isSmallMobile ? 20.0 : 24.0)
        : (isSmallMobile ? 24.0 : 30.0);

    final gapValueTitle = widget.isCompact ? 3.0 : 4.0;

    final titleFont = widget.isCompact
        ? (isSmallMobile ? 11.0 : 12.0)
        : (isSmallMobile ? 11.5 : 13.0);

    final gapTitleSub = 2.0;

    final subFont = widget.isCompact
        ? (isSmallMobile ? 10.0 : 11.0)
        : (isSmallMobile ? 10.0 : 11.5);

    final cardRadius = widget.isCompact
        ? (isSmallMobile ? 12.0 : 14.0)
        : (isSmallMobile ? 14.0 : 20.0);

    return SafeMouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: () => setState(() => _hover = true),
      onExit: () => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.02 : 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: cardPadding,
            vertical: cardPadding,
          ),
          decoration: BoxDecoration(
            color: _hover
                ? AppColors.white.withOpacity(0.10)
                : AppColors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(
              color: _hover
                  ? AppColors.mint.withOpacity(0.55)
                  : AppColors.mint.withOpacity(0.18),
              width: _hover ? 1.5 : 1,
            ),
            boxShadow: [
              if (_hover)
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: widget.isCompact
              // ==============================
              // COMPACT LAYOUT — horizontal
              // ==============================
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: iconBox,
                      height: iconBox,
                      decoration: BoxDecoration(
                        color: _hover
                            ? AppColors.mint
                            : AppColors.mint.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(iconRadius),
                      ),
                      child: Icon(
                        widget.icon,
                        color: _hover
                            ? AppColors.darkTeal
                            : AppColors.mint,
                        size: iconSize,
                      ),
                    ),
                    SizedBox(width: gapIconValue + 4),
                    // Value + Title + Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.statValue.copyWith(
                              fontSize: valueFont,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: gapValueTitle),
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.statLabel.copyWith(
                              color: AppColors.white.withOpacity(0.95),
                              fontSize: titleFont,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: gapTitleSub),
                          Text(
                            widget.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.statLabel.copyWith(
                              fontSize: subFont,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              // ==============================
              // DEFAULT LAYOUT — vertikal
              // ==============================
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: iconBox,
                      height: iconBox,
                      decoration: BoxDecoration(
                        color: _hover
                            ? AppColors.mint
                            : AppColors.mint.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(iconRadius),
                      ),
                      child: Icon(
                        widget.icon,
                        color: _hover
                            ? AppColors.darkTeal
                            : AppColors.mint,
                        size: iconSize,
                      ),
                    ),
                    SizedBox(height: gapIconValue),
                    Text(
                      widget.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.statValue.copyWith(
                        fontSize: valueFont,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: gapValueTitle),
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.statLabel.copyWith(
                        color: AppColors.white.withOpacity(0.95),
                        fontSize: titleFont,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: gapTitleSub),
                    Text(
                      widget.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.statLabel.copyWith(
                        fontSize: subFont,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}