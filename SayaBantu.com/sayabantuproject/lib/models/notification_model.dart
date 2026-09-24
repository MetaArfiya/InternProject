import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

class NotificationModel {
  final String id;         // ← UUID (String), bukan int
  final String type;       // ← hasil extract dari class name atau data.type
  final String title;
  final String message;
  final DateTime? createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.createdAt,
    this.isRead = false,
  });

  // ============================================================
  // ICON MAPPING
  // ============================================================
  IconData get icon {
    switch (type.toLowerCase()) {
      case 'new_bid_received':
      case 'bid_received':
      case 'penawaran_baru':
        return Icons.local_offer_outlined;

      case 'bid_accepted':
      case 'penawaran_diterima':
        return Icons.business_center_outlined;

      case 'job_started':
      case 'pekerjaan_diproses':
        return Icons.engineering_outlined;

      case 'job_completed':
      case 'pekerjaan_selesai':
        return Icons.check_circle_outline;

      case 'payment_received':
      case 'pembayaran_diterima':
        return Icons.credit_card_outlined;

      case 'welcome':
      case 'selamat_datang':
        return Icons.notifications_none_outlined;

      default:
        return Icons.info_outline_rounded;
    }
  }

  // ============================================================
  // ICON COLOR
  // ============================================================
  Color get iconColor {
    switch (type.toLowerCase()) {
      case 'new_bid_received':
      case 'bid_received':
      case 'penawaran_baru':
        return const Color(0xff2196F3);

      case 'bid_accepted':
      case 'penawaran_diterima':
        return const Color(0xff22C55E);

      case 'job_started':
      case 'pekerjaan_diproses':
        return const Color(0xffF59E0B);

      case 'job_completed':
      case 'pekerjaan_selesai':
        return const Color(0xff22C55E);

      case 'payment_received':
      case 'pembayaran_diterima':
        return const Color(0xffF59E0B);

      case 'welcome':
      case 'selamat_datang':
        return const Color(0xff8B5CF6);

      default:
        return const Color(0xff64748B);
    }
  }

  // ============================================================
  // ICON BACKGROUND
  // ============================================================
  Color get iconBackground {
    switch (type.toLowerCase()) {
      case 'new_bid_received':
      case 'bid_received':
      case 'penawaran_baru':
        return const Color(0xffE8F3FF);

      case 'bid_accepted':
      case 'penawaran_diterima':
        return const Color(0xffEAF9F0);

      case 'job_started':
      case 'pekerjaan_diproses':
        return const Color(0xffFFF4DE);

      case 'job_completed':
      case 'pekerjaan_selesai':
        return const Color(0xffEAF9F0);

      case 'payment_received':
      case 'pembayaran_diterima':
        return const Color(0xffFFF4DE);

      case 'welcome':
      case 'selamat_datang':
        return const Color(0xffF1ECFF);

      default:
        return const Color(0xffF1F5F9);
    }
  }

  // ============================================================
  // RELATIVE TIME
  // ============================================================
  String get relativeTime {
    if (createdAt == null) return '-';

    final now = DateTime.now();
    final diff = now.difference(createdAt!);

    if (diff.isNegative) return 'Baru saja';
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';

    const bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${createdAt!.day} ${bulan[createdAt!.month - 1]} ${createdAt!.year}';
  }

  // ============================================================
  // FROM JSON — untuk format Laravel Notification
  // ============================================================
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // ---------------------------------------------------------
    // 1. Ambil data nested (Laravel taruh payload di 'data')
    // ---------------------------------------------------------
    Map<String, dynamic> data = {};
    if (json['data'] is Map<String, dynamic>) {
      data = json['data'] as Map<String, dynamic>;
    } else if (json['data'] is String) {
      try {
        data = jsonDecode(json['data'].toString()) as Map<String, dynamic>;
      } catch (_) {}
    }

    // ---------------------------------------------------------
    // 2. Extract type — prioritas dari data['type'],
    //    fallback dari class name (App\Notifications\NewBidReceived → new_bid_received)
    // ---------------------------------------------------------
    String type = data['type']?.toString() ?? '';
    if (type.isEmpty) {
      type = _extractTypeFromClass(json['type']?.toString() ?? '');
    }

    // ---------------------------------------------------------
    // 3. Title & message
    // ---------------------------------------------------------
    final String title = data['title']?.toString() ??
        data['judul']?.toString() ??
        _defaultTitle(type);

    final String message = data['message']?.toString() ??
        data['body']?.toString() ??
        data['pesan']?.toString() ??
        '-';

    // ---------------------------------------------------------
    // 4. Tanggal
    // ---------------------------------------------------------
    final dynamic rawDate = json['created_at'] ?? json['createdAt'];
    final DateTime? createdAt = rawDate == null
        ? null
        : DateTime.tryParse(rawDate.toString());

    // ---------------------------------------------------------
    // 5. is_read
    // ---------------------------------------------------------
    final bool isRead = json['read_at'] != null;

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: type,
      title: title,
      message: message,
      createdAt: createdAt,
      isRead: isRead,
    );
  }

  // ============================================================
  // HELPER: Extract type dari class name Laravel
  // "App\\Notifications\\NewBidReceived" → "new_bid_received"
  // ============================================================
  static String _extractTypeFromClass(String fullClass) {
    if (fullClass.isEmpty) return 'info';

    // Ambil bagian setelah '\' terakhir
    final className = fullClass.split('\\').last;

    // Convert PascalCase → snake_case
    final snake = className
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]}_${m[2]}')
        .toLowerCase();

    return snake;
  }

  // ============================================================
  // HELPER: Default title kalau data.title tidak ada
  // ============================================================
  static String _defaultTitle(String type) {
    switch (type.toLowerCase()) {
      case 'new_bid_received':
      case 'bid_received':
        return 'Penawaran Baru';
      case 'bid_accepted':
        return 'Penawaran Diterima';
      case 'job_started':
        return 'Pekerjaan Dimulai';
      case 'job_completed':
        return 'Pekerjaan Selesai';
      case 'payment_received':
        return 'Pembayaran Diterima';
      case 'welcome':
        return 'Selamat Datang';
      default:
        return 'Notifikasi';
    }
  }
}

// // Helper kecil untuk decode JSON di dalam model
// dynamic jsonDecode(String s) {
//   // Import di atas sudah include dart:convert
//   return const JsonCodec().decode(s);
// }