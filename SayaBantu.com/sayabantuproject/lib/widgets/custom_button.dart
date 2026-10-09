import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'safe_mouse_region.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final double borderRadius;
  final bool outlined;
  final IconData? icon;
  final double fontSize;
  final FontWeight fontWeight;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 48,
    this.borderRadius = 12,
    this.outlined = false,
    this.icon,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w700,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primaryTeal;
    final fg = textColor ?? AppColors.white;
    final radius = BorderRadius.circular(borderRadius);

    return SafeMouseRegion(
      cursor: onPressed == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: outlined ? Colors.transparent : bg,
              borderRadius: radius,
              border: outlined
                  ? Border.all(
                      color: fg.withOpacity(0.5),
                      width: 1.5,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.buttonPrimary.copyWith(
                      color: fg,
                      fontSize: fontSize,
                      fontWeight: fontWeight,
                    ),
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    icon,
                    size: 18,
                    color: fg,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}