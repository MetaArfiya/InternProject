import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class FeatureItem extends StatelessWidget {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final String title;
  final String description;

  const FeatureItem({
    super.key,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 350;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================================================
            // ICON
            // ================================================
            Semantics(
              label: title,
              child: Container(
                width: isSmall ? 46 : 54,
                height: isSmall ? 46 : 54,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: isSmall ? 24 : 28,
                ),
              ),
            ),

            SizedBox(width: isSmall ? 12 : 18),

            // ================================================
            // TEXT
            // ================================================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.headingSmall.copyWith(
                      fontSize: isSmall ? 16 : 18,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: AppTextStyles.bodyOnLight.copyWith(
                      fontSize: isSmall ? 13 : 14.5,
                      height: 1.65,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}