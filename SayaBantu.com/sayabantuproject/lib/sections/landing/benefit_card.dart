import 'package:flutter/material.dart';

class BenefitCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const BenefitCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final isMobile = width < 768;
    final isTablet = width >= 768 && width < 1100;

    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(.08),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: isMobile ? 30 : 36,
          ),

          SizedBox(height: isMobile ? 16 : 22),

          Text(
            title,
            softWrap: true,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isMobile
                  ? 18
                  : isTablet
                      ? 20
                      : 22,
            ),
          ),

          SizedBox(height: isMobile ? 10 : 14),

          Text(
            description,
            softWrap: true,
            style: TextStyle(
              color: Colors.white70,
              height: 1.6,
              fontSize: isMobile ? 14 : 15,
            ),
          ),
        ],
      ),
    );
  }
}