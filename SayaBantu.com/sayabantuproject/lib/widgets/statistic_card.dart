import 'package:flutter/material.dart';

class StatisticCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String title;
  final Color color;

  const StatisticCard({
    super.key,
    required this.icon,
    required this.value,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 220;

        return Container(
          height: isSmall ? 100 : 110,
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 16 : 22,
            vertical: isSmall ? 16 : 18,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xffE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: isSmall ? 46 : 52,
                height: isSmall ? 46 : 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: isSmall ? 24 : 28,
                ),
              ),

              SizedBox(width: isSmall ? 12 : 18),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: isSmall ? 22 : 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: isSmall ? 12 : 14,
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