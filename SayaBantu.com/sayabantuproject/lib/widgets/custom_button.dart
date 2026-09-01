import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double width;
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
    this.backgroundColor = const Color(0xffF97316),
    this.textColor = Colors.white,
    this.width = 180,
    this.height = 56,
    this.borderRadius = 14,
    this.outlined = false,
    this.icon,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w700,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return MouseRegion(
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
              color: outlined ? Colors.transparent : backgroundColor,
              borderRadius: radius,
              border: outlined
                  ? Border.all(
                      color: Color.fromRGBO(
                        255,
                        255,
                        255,
                        0.35,
                      ),
                      width: 1.2,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    icon,
                    size: 18,
                    color: textColor,
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