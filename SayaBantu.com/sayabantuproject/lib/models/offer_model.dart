
import '../utils/indonesia_time.dart';

class OfferModel {
  final int id;
  final int jobId;
  final int mitraId;

  final String name;
  final bool verified;
  final int jobsCompleted;

  final String price;
  final double priceAmount;

  final String? note;
  final String status;

  // Jadwal dan durasi yang diajukan Mitra
  final DateTime? proposedStartAt;
  final int? estimatedDurationMinutes;

  OfferModel({
    required this.id,
    required this.jobId,
    required this.mitraId,
    required this.name,
    this.verified = false,
    this.jobsCompleted = 0,
    required this.price,
    required this.priceAmount,
    this.note,
    this.status = 'Menunggu',
    this.proposedStartAt,
    this.estimatedDurationMinutes,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    // ============================================================
    // 1. HARGA PENAWARAN
    // ============================================================

    final rawPrice = json['offered_price'] ??
        json['price'] ??
        json['bid_amount'] ??
        '0';

    final double amount =
        double.tryParse(rawPrice.toString()) ?? 0.0;

    final formattedPrice =
        'Rp ${amount.toInt().toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]}.',
            )}';

    // ============================================================
    // 2. NAMA MITRA
    // ============================================================

    String partnerName = 'Mitra Jasa';

    if (json['user'] is Map) {
      partnerName =
          json['user']['name']?.toString() ?? partnerName;
    } else if (json['mitra'] is Map) {
      partnerName =
          json['mitra']['name']?.toString() ?? partnerName;
    } else if (json['mitra_profile'] is Map) {
      partnerName =
          json['mitra_profile']['name']?.toString() ?? partnerName;
    } else if (json['user_name'] != null) {
      partnerName = json['user_name'].toString();
    } else if (json['name'] != null) {
      partnerName = json['name'].toString();
    }

    // ============================================================
    // 3. STATUS VERIFIKASI MITRA
    // ============================================================

    bool isVerified = false;

    if (json['mitra_profile'] is Map &&
        json['mitra_profile']['is_verified'] != null) {
      final value = json['mitra_profile']['is_verified'];

      isVerified = value == true ||
          value == 1 ||
          value.toString() == '1';
    } else if (json['verified'] != null) {
      final value = json['verified'];

      isVerified = value == true ||
          value == 1 ||
          value.toString() == '1';
    }

    // ============================================================
    // 4. JUMLAH JOB SELESAI
    // ============================================================

    int completedJobs = 0;

    final rawJobsCompleted =
        (json['mitra_profile'] is Map
            ? json['mitra_profile']['jobs_completed']
            : null) ??
        json['jobs_completed'];

    if (rawJobsCompleted != null) {
      completedJobs =
          int.tryParse(rawJobsCompleted.toString()) ?? 0;
    }

    // ============================================================
    // 5. STATUS PENAWARAN
    // ============================================================

    final String bidStatus =
        json['status']?.toString().trim().isNotEmpty == true
            ? json['status'].toString().trim()
            : 'Menunggu';

    // ============================================================
    // 6. JADWAL MULAI YANG DIAJUKAN MITRA
    // ============================================================

    final rawProposedStart =
        json['proposed_start_at'] ??
        json['proposedStartAt'];

    DateTime? parsedProposedStart;

    if (rawProposedStart != null &&
        rawProposedStart.toString().trim().isNotEmpty) {
      final parsed = IndonesiaTime.tryParseApiTimestamp(rawProposedStart);
      parsedProposedStart = parsed == null ? null : IndonesiaTime.toWall(parsed);
    }

    // ============================================================
    // 7. ESTIMASI DURASI PENGERJAAN
    // ============================================================

    final rawDuration =
        json['estimated_duration_minutes'] ??
        json['estimatedDurationMinutes'];

    int? parsedDuration;

    if (rawDuration != null) {
      parsedDuration = int.tryParse(rawDuration.toString());
    }

    // ============================================================
    // 8. CATATAN / PESAN MITRA
    // ============================================================

    final String? partnerNote =
        json['note']?.toString() ??
        json['message']?.toString();

    // ============================================================
    // 9. RETURN MODEL
    // ============================================================

    return OfferModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,

      jobId: int.tryParse(
            json['job_id']?.toString() ?? '0',
          ) ??
          0,

      mitraId: int.tryParse(
            json['mitra_id']?.toString() ??
                json['user_id']?.toString() ??
                '0',
          ) ??
          0,

      name: partnerName,
      verified: isVerified,
      jobsCompleted: completedJobs,

      price: formattedPrice,
      priceAmount: amount,

      note: partnerNote,
      status: bidStatus,

      proposedStartAt: parsedProposedStart,
      estimatedDurationMinutes: parsedDuration,
    );
  }

  // ============================================================
  // HELPER STATUS
  // ============================================================

  bool get isPending =>
      status.toLowerCase().trim() == 'menunggu';

  bool get isAccepted =>
      status.toLowerCase().trim().contains('diterima') ||
      status.toLowerCase().trim().contains('accepted');

  bool get isRejected =>
      status.toLowerCase().trim().contains('ditolak') ||
      status.toLowerCase().trim().contains('rejected');

  // ============================================================
  // HELPER JADWAL
  // ============================================================

  String get proposedStartAtText {
    if (proposedStartAt == null) {
      return 'Belum mengajukan jadwal';
    }

    final date = proposedStartAt!;

    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute';
  }

  // ============================================================
  // HELPER DURASI
  // ============================================================

  String get estimatedDurationText {
    final minutes = estimatedDurationMinutes;

    if (minutes == null || minutes <= 0) {
      return 'Belum mencantumkan durasi';
    }

    if (minutes < 60) {
      return '$minutes menit';
    }

    if (minutes % 1440 == 0) {
      final days = minutes ~/ 1440;
      return '$days hari';
    }

    if (minutes % 60 == 0) {
      final hours = minutes ~/ 60;
      return '$hours jam';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    return '$hours jam $remainingMinutes menit';
  }
}
