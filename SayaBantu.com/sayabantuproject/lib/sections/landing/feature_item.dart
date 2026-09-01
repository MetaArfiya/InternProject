import 'package:flutter/material.dart';

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

          return Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
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

                SizedBox(
                  width: isSmall ? 12 : 18,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isSmall ? 16 : 19,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff08162F),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        description,
                        style: TextStyle(
                          color: const Color(0xff64748B),
                          fontSize: isSmall ? 13 : 15,
                          height: 1.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
}