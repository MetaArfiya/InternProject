import 'package:flutter/material.dart';

class PartnerNotificationScreen extends StatelessWidget {
  const PartnerNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            28,
            20,
            28,
            28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============================================================
              // HEADER
              // ============================================================
              Text(
                'Notifikasi',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? Colors.white
                      : const Color(0xFF172B4D),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Lihat informasi terbaru mengenai pekerjaan dan akun kamu.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: isDark
                      ? Colors.white70
                      : const Color(0xFF718096),
                ),
              ),

              const SizedBox(height: 24),

              // ============================================================
              // NOTIFICATION 1
              // ============================================================
              _NotificationCard(
                icon: Icons.business_center_outlined,
                title: 'Penawaran diterima',
                description:
                    'Penawaran jasa kamu telah diterima oleh pelanggan.',
                time: 'Baru saja',
                isNew: true,
              ),

              const SizedBox(height: 16),

              // ============================================================
              // NOTIFICATION 2
              // ============================================================
              _NotificationCard(
                icon: Icons.credit_card_outlined,
                title: 'Pembayaran diterima',
                description:
                    'Pembayaran dari pelanggan telah diterima.',
                time: '1 jam yang lalu',
              ),

              const SizedBox(height: 16),

              // ============================================================
              // NOTIFICATION 3
              // ============================================================
              _NotificationCard(
                icon: Icons.info_outline_rounded,
                title: 'Informasi',
                description:
                    'Pastikan pekerjaan diselesaikan sesuai pesanan pelanggan.',
                time: 'Kemarin',
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// NOTIFICATION CARD
// ============================================================================

class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String time;
  final bool isNew;

  const _NotificationCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.time,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 22,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              isDark ? 0.12 : 0.025,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ================================================================
          // ICON
          // ================================================================
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark
                  ? primaryColor.withOpacity(0.12)
                  : const Color(0xFFFFF1E8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 28,
              color: primaryColor,
            ),
          ),

          const SizedBox(width: 18),

          // ================================================================
          // CONTENT
          // ================================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF172B4D),
                        ),
                      ),
                    ),

                    // ======================================================
                    // BADGE BARU
                    // ======================================================
                    if (isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? primaryColor.withOpacity(0.15)
                              : const Color(0xFFFFF0E8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Baru',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 6),

                // ==========================================================
                // DESCRIPTION
                // ==========================================================
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    height: 1.35,
                    color: isDark
                        ? Colors.white70
                        : const Color(0xFF718096),
                  ),
                ),

                const SizedBox(height: 10),

                // ==========================================================
                // TIME
                // ==========================================================
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 15,
                      color: isDark
                          ? Colors.white54
                          : const Color(0xFF9AA4B2),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      time,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF9AA4B2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // ================================================================
          // ARROW
          // ================================================================
          Icon(
            Icons.chevron_right_rounded,
            size: 26,
            color: isDark
                ? Colors.white54
                : const Color(0xFF718096),
          ),
        ],
      ),
    );
  }
}