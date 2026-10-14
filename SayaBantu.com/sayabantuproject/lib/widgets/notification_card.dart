import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../theme/app_colors.dart';

/// Versi ringkas — untuk NotificationScreen (Pelanggan)
class CompactNotificationCard extends StatelessWidget {
  final NotificationModel notification;

  const CompactNotificationCard({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha:0.10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              // ✅ dari `notification.iconBackground` → mint soft
              color: AppColors.mint.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              notification.icon,
              // ✅ dari `notification.iconColor` → teal
              color: AppColors.primaryTeal,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  notification.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.grey600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notification.relativeTime,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Versi besar dengan badge "Baru" — untuk PartnerNotificationScreen (Mitra)
class PartnerNotificationCard extends StatelessWidget {
  final NotificationModel notification;

  const PartnerNotificationCard({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // "Baru" kalau belum dibaca DAN umur < 1 jam
    final bool isNew = !notification.isRead &&
        (notification.createdAt == null ||
            DateTime.now().difference(notification.createdAt!).inHours < 1);

    // ============================================================
    // WARNA KONDISIONAL (dark/light)
    // ============================================================
    final cardBg = isDark ? const Color(0xFF1E1E1E) : AppColors.white;
    final cardBorder = isDark
        ? AppColors.white.withValues(alpha:0.08)
        : AppColors.primaryTeal.withValues(alpha:0.10);
    final iconBg = isDark
        ? AppColors.primaryTeal.withValues(alpha:0.15)
        : AppColors.mint.withValues(alpha:0.15);
    final iconColor = AppColors.primaryTeal; // teal di kedua mode
    final titleColor = isDark ? AppColors.white : AppColors.grey900;
    final messageColor = isDark
        ? AppColors.white.withValues(alpha:0.70)
        : AppColors.grey600;
    final timeColor = isDark
        ? AppColors.white.withValues(alpha:0.55)
        : AppColors.grey500;
    final badgeBg = isDark
        ? AppColors.primaryTeal.withValues(alpha:0.20)
        : AppColors.mint.withValues(alpha:0.20);
    final badgeFg = AppColors.primaryTeal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha:0.12)
                : AppColors.darkTeal.withValues(alpha:0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ICON
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              notification.icon,
              size: 28,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 18),

          // CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                    ),
                    // BADGE "BARU"
                    if (isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Baru',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: badgeFg,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: messageColor,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 15,
                      color: timeColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      notification.relativeTime,
                      style: TextStyle(
                        fontSize: 13,
                        color: timeColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}