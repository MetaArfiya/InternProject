import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class TestimonialCard extends StatelessWidget {
  final String category;
  final IconData categoryIcon;
  final String review;
  final String name;
  final String job;
  final String avatar;
  final bool useImage;

  const TestimonialCard({
    super.key,
    required this.category,
    required this.categoryIcon,
    required this.review,
    required this.name,
    required this.job,
    required this.avatar,
    this.useImage = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;

    // ==========================================
    // SKALA UKURAN
    // ==========================================
    final cardPadding = isSmall ? 14.0 : 18.0;
    final cardRadius = isSmall ? 14.0 : 18.0;
    final starSize = isSmall ? 14.0 : 17.0;
    final reviewFont = isSmall ? 12.0 : 13.0;
    final categoryIconSize = isSmall ? 11.0 : 13.0;
    final categoryFont = isSmall ? 10.0 : 11.0;
    final nameFont = isSmall ? 12.0 : 13.0;
    final jobFont = isSmall ? 10.0 : 11.0;
    final avatarRadius = isSmall ? 15.0 : 19.0;
    final gapSmall = isSmall ? 4.0 : 6.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(
          color: AppColors.primaryTeal.withOpacity(0.10),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkTeal.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // RATING
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (_) => Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(
                  Icons.star_rounded,
                  color: AppColors.starYellow,
                  size: starSize,
                ),
              ),
            ),
          ),

          SizedBox(height: isSmall ? 8 : 12),

          // REVIEW
          Text(
            review,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmallOnLight.copyWith(
              fontSize: reviewFont,
              height: 1.55,
              color: AppColors.grey700,
            ),
          ),

          SizedBox(height: isSmall ? 10 : 14),

          // CATEGORY BADGE
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 8 : 10,
              vertical: isSmall ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.mint.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  categoryIcon,
                  color: AppColors.primaryTeal,
                  size: categoryIconSize,
                ),
                SizedBox(width: gapSmall),
                Flexible(
                  child: Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelOnDark.copyWith(
                      color: AppColors.primaryTeal,
                      fontSize: categoryFont,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isSmall ? 10 : 14),
          Divider(
            height: 1,
            color: AppColors.primaryTeal.withOpacity(0.10),
          ),
          SizedBox(height: isSmall ? 8 : 12),

          // USER
          Row(
            children: [
              _buildAvatar(isSmall, avatarRadius),
              SizedBox(width: isSmall ? 9 : 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingSmall.copyWith(
                        fontSize: nameFont,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmallOnLight.copyWith(
                        fontSize: jobFont,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================
  Widget _buildAvatar(bool isSmall, double radius) {
    if (useImage) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: AssetImage(avatar),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryTeal,
      child: Text(
        avatar,
        style: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
          fontSize: isSmall ? 10 : 11,
        ),
      ),
    );
  }
}