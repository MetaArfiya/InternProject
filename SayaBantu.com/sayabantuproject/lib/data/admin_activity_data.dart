import 'package:flutter/foundation.dart';

class AdminActivityData extends ChangeNotifier {
  AdminActivityData._();

  static final AdminActivityData instance = AdminActivityData._();

  // =========================================================
  // LAPORAN HARIAN
  // =========================================================

  static int approvedPartners = 0;
  static int moderatedPosts = 0;
  static int rejectedPosts = 0;
  static int userReports = 0;

  // =========================================================
  // BADGE SIDEBAR
  // =========================================================

  static int pendingPartners = 0;
  static int flaggedPosts = 0;

  // =========================================================
  // AKTIVITAS HARI INI
  // =========================================================

  static final List<Map<String, dynamic>> activities = [];

  // =========================================================
  // VERIFIKASI MITRA
  // =========================================================

  static void addApprovedPartner({
    String? name,
  }) {
    approvedPartners++;

    if (pendingPartners > 0) {
      pendingPartners--;
    }

    _addActivity(
      title: name == null
          ? 'Mitra berhasil diverifikasi'
          : 'Mitra $name berhasil diverifikasi',
      icon: 'verified',
      colorType: 'green',
    );
  }

  // =========================================================
  // MODERASI - POSTINGAN AMAN
  // =========================================================

  static void addModeratedPost({
    String? title,
  }) {
    moderatedPosts++;

    _addActivity(
      title: title == null
          ? 'Postingan selesai dimoderasi'
          : 'Postingan "$title" selesai dimoderasi',
      icon: 'flag',
      colorType: 'purple',
    );
  }

  // =========================================================
  // MODERASI - POSTINGAN DITOLAK
  // =========================================================

  static void addRejectedPost({
    String? title,
  }) {
    rejectedPosts++;

    _addActivity(
      title: title == null
          ? 'Postingan ditolak'
          : 'Postingan "$title" ditolak',
      icon: 'cancel',
      colorType: 'red',
    );
  }

  // =========================================================
  // LAPORAN PENGGUNA
  // =========================================================

  static void addUserReport({
    String? title,
  }) {
    userReports++;

    _addActivity(
      title: title == null
          ? 'Laporan pengguna diterima'
          : 'Laporan pengguna "$title" diterima',
      icon: 'report',
      colorType: 'orange',
    );
  }

  // =========================================================
  // UPDATE BADGE MODERASI
  // =========================================================

  static void setFlaggedCount(int count) {
    flaggedPosts = count < 0 ? 0 : count;

    instance.notifyListeners();
  }

  // =========================================================
  // UPDATE BADGE VERIFIKASI
  // =========================================================

  static void setPendingPartnerCount(int count) {
    pendingPartners = count < 0 ? 0 : count;

    instance.notifyListeners();
  }

  // =========================================================
  // TAMBAH AKTIVITAS
  // =========================================================

  static void _addActivity({
    required String title,
    required String icon,
    required String colorType,
  }) {
    final now = DateTime.now();

    activities.insert(
      0,
      {
        'title': title,
        'icon': icon,
        'colorType': colorType,
        'time': _formatTime(now),
        'date': now,
      },
    );

    instance.notifyListeners();
  }

  // =========================================================
  // FORMAT JAM
  // =========================================================

  static String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  // =========================================================
  // RESET DATA
  // =========================================================

  static void resetToday() {
    approvedPartners = 0;
    moderatedPosts = 0;
    rejectedPosts = 0;
    userReports = 0;

    activities.clear();

    instance.notifyListeners();
  }
}