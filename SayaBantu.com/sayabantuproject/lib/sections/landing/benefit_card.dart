import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isCompact;

  const BenefitCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    // ==========================================
    // SKALA UKURAN
    // ==========================================
    final cardPadding = isCompact ? 14.0 : 18.0;
    final cardRadius = isCompact ? 14.0 : 18.0;
    final iconBox = isCompact ? 36.0 : 42.0;
    final iconSize = isCompact ? 18.0 : 22.0;
    final iconRadius = isCompact ? 10.0 : 12.0;
    final titleFont = isCompact ? 13.0 : 15.0;
    final descFont = isCompact ? 11.0 : 12.0;
    final gapIconTitle = isCompact ? 10.0 : 14.0;
    final gapTitleDesc = isCompact ? 4.0 : 6.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(
          color: AppColors.mint.withOpacity(0.20),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ICON
          Container(
            width: iconBox,
            height: iconBox,
            decoration: BoxDecoration(
              color: AppColors.mint.withOpacity(0.15),
              borderRadius: BorderRadius.circular(iconRadius),
            ),
            child: Icon(
              icon,
              color: AppColors.mint,
              size: iconSize,
            ),
          ),

          SizedBox(height: gapIconTitle),

          // TITLE
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.white,
              fontSize: titleFont,
              height: 1.25,
            ),
          ),

          SizedBox(height: gapTitleDesc),

          // DESCRIPTION
          Expanded(
            child: Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmallOnDark.copyWith(
                fontSize: descFont,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}