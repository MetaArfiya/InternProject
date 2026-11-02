import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../theme/app_colors.dart';

/// Versi ringkas — untuk NotificationScreen (Pelanggan)
class CompactNotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const CompactNotificationCard({
    super.key,
    required this.notification,
    this.onTap,
  });

  // ============================================================
  // HELPER: MENENTUKAN IKON BERDASARKAN TIPE
  // ============================================================
  IconData _getIcon(String type) {
    switch (type) {
      case 'new_bid_received':
        return Icons.gavel_rounded; // Ikon palu lelang
      case 'bid_accepted':
        return Icons.check_circle_outline_rounded; // Ikon centang
      case 'chat':
        return Icons.chat_bubble_outline_rounded; // Ikon chat
      case 'job_completed':
        return Icons.task_alt_rounded; // Ikon pekerjaan selesai
      case 'welcome':
        return Icons.waving_hand_rounded; // Ikon salam
      default:
        return Icons.notifications_none_rounded; // Ikon default
    }
  }

  // ============================================================
  // HELPER: MENENTUKAN WARNA BERDASARKAN TIPE
  // ============================================================
  Color _getColor(String type) {
    switch (type) {
      case 'new_bid_received':
        return Colors.blue; // Biru untuk penawaran
      case 'bid_accepted':
        return Colors.green; // Hijau untuk diterima
      case 'chat':
        return AppColors.primaryTeal; // Teal untuk chat
      case 'job_completed':
        return Colors.purple; // Ungu untuk selesai
      default:
        return AppColors.grey500; // Abu-abu untuk default
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dapatkan warna berdasarkan tipe
    final iconColor = _getColor(notification.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryTeal.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KOTAK IKON
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12), // Background transparan
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIcon(notification.type), // Panggil fungsi ikon
                color: iconColor, // Warna dinamis
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // TEKS
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
      ),
    );
  }
}