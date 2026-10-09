import 'package:flutter/material.dart';

class PartnerProfileSection extends StatelessWidget {
  const PartnerProfileSection({super.key});

  // ============================================================
  // DESIGN TOKENS — disamakan dengan DashboardHeader / PaymentScreen
  // ============================================================

  static const Color _accent = Color(0xFFF97316);

  // Spacing — mengikuti pola DashboardHeader
  static const double _gapAfterHeader = 16;
  static const double _gapBetweenSections = 16;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 700;
          final isTablet = width >= 700 && width < 1100;

          final horizontalPadding =
              isMobile ? 16.0 : (isTablet ? 24.0 : 28.0);
          final verticalPadding = isMobile ? 16.0 : 28.0;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),

                const SizedBox(height: _gapAfterHeader),

                _buildPlaceholder(context, isMobile: isMobile),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // HEADER — sama persis dgn DashboardHeader
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profil Mitra',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kelola informasi profil Anda sebagai mitra.',
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PLACEHOLDER — icon bulat + teks
  // ============================================================

  Widget _buildPlaceholder(
    BuildContext context, {
    required bool isMobile,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 48 : 64,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline,
              size: 34,
              color: _accent.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: _gapBetweenSections),
          const Text(
            'Belum ada data profil',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Informasi profil mitra akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}