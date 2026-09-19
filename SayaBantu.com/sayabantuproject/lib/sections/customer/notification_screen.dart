import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  // ==========================================================
  // DATA NOTIFIKASI
  // ==========================================================

  List<Map<String, dynamic>> get notifications => [
        {
          'icon': Icons.local_offer_outlined,
          'iconColor': const Color(0xff2196F3),
          'iconBackground': const Color(0xffE8F3FF),
          'title': 'Penawaran Baru',
          'message':
              'Budi Teknik AC mengirim penawaran untuk pekerjaan Anda.',
          'time': '2 menit lalu',
        },
        {
          'icon': Icons.engineering_outlined,
          'iconColor': const Color(0xffF59E0B),
          'iconBackground': const Color(0xffFFF4DE),
          'title': 'Pekerjaan Diproses',
          'message':
              'Andi Service mulai mengerjakan pekerjaan Anda.',
          'time': '1 jam lalu',
        },
        {
          'icon': Icons.check_circle_outline,
          'iconColor': const Color(0xff22C55E),
          'iconBackground': const Color(0xffEAF9F0),
          'title': 'Pekerjaan Selesai',
          'message': 'Service AC Bocor telah selesai.',
          'time': 'Kemarin',
        },
        {
          'icon': Icons.notifications_none_outlined,
          'iconColor': const Color(0xff8B5CF6),
          'iconBackground': const Color(0xffF1ECFF),
          'title': 'Selamat Datang',
          'message':
              'Terima kasih telah bergabung di SayaBantu.',
          'time': '3 hari lalu',
        },
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 28,
              vertical: isMobile ? 16 : 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // HEADER
                // ==================================================

                Text(
                  'Notifikasi',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Semua aktivitas terbaru akan muncul di sini.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // LIST NOTIFIKASI
                // ==================================================

                if (notifications.isEmpty)
                  _buildEmptyState(context)
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(
                        context,
                        notifications[index],
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================================
  // NOTIFICATION CARD
  // ==========================================================

  Widget _buildNotificationCard(
    BuildContext context,
    Map<String, dynamic> notification,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xffE5E7EB),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // ICON
          // ======================================================

          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: notification['iconBackground'] as Color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              notification['icon'] as IconData,
              color: notification['iconColor'] as Color,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          // ======================================================
          // CONTENT
          // ======================================================

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  notification['message'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  notification['time'] as String,
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

  // ==========================================================
  // EMPTY STATE
  // ==========================================================

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 48,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xffE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xffF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_none_outlined,
              size: 24,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'Belum ada notifikasi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Semua aktivitas terbaru akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}