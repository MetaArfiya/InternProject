import 'package:flutter/material.dart';

import '../models/notification_model.dart';

/// Versi ringkas — untuk NotificationScreen (Pelanggan)
class CompactNotificationCard extends StatelessWidget {
  final NotificationModel notification;

  const CompactNotificationCard({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: notification.iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              notification.icon,
              color: notification.iconColor,
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
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  notification.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notification.relativeTime,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    // "Baru" kalau belum dibaca DAN umur < 1 jam
    final bool isNew = !notification.isRead &&
        (notification.createdAt == null ||
            DateTime.now().difference(notification.createdAt!).inHours < 1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.12 : 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark
                  ? primaryColor.withOpacity(0.12)
                  : notification.iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              notification.icon,
              size: 28,
              color: notification.iconColor,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF172B4D),
                        ),
                      ),
                    ),
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
                Text(
                  notification.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    height: 1.35,
                    color: isDark
                        ? Colors.white70
                        : const Color(0xFF718096),
                  ),
                ),
                const SizedBox(height: 10),
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
                      notification.relativeTime,
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
          // Icon(
          //   Icons.chevron_right_rounded,
          //   size: 26,
          //   color: isDark ? Colors.white54 : const Color(0xFF718096),
          // ),
        ],
      ),
    );
  }
}