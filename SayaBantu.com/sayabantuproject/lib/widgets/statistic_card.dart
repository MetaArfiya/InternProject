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
        final width = constraints.maxWidth;

        // ============================================================
        // BREAKPOINT
        // ============================================================
        // compact  → mobile 3 kolom  (layout vertikal)
        // normal   → tablet / desktop (layout horizontal)
        // ============================================================

        final isCompact = width < 180;

        return Container(
          padding: EdgeInsets.all(isCompact ? 10 : 18),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isCompact
              ? _buildCompact()
              : _buildNormal(),
        );
      },
    );
  }

  // ============================================================
  // LAYOUT COMPACT — MOBILE (3 kolom sempit)
  // ============================================================

  Widget _buildCompact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 17,
          ),
        ),

        const SizedBox(height: 8),

        // Value
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),

        const SizedBox(height: 2),

        // Title
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LAYOUT NORMAL — TABLET / DESKTOP
  // ============================================================

  Widget _buildNormal() {
    return Row(
      children: [
        // Icon
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 23,
          ),
        ),

        const SizedBox(width: 16),

        // Value & Title
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
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}