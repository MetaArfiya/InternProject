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
  final String status; // ✅ BARU

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
    this.status = 'Menunggu', // ✅ default
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    // ============================================================
    // 1. HARGA
    // ============================================================
    final rawPrice =
        json['offered_price'] ?? json['price'] ?? json['bid_amount'] ?? '0';
    final double amount = double.tryParse(rawPrice.toString()) ?? 0.0;

    // ============================================================
    // 2. NAMA MITRA
    // ============================================================
    String partnerName = "Mitra Jasa";
    if (json['user'] != null && json['user'] is Map) {
      partnerName = json['user']['name']?.toString() ?? partnerName;
    } else if (json['mitra'] != null && json['mitra'] is Map) {
      partnerName = json['mitra']['name']?.toString() ?? partnerName;
    } else if (json['mitra_profile'] != null && json['mitra_profile'] is Map) {
      partnerName = json['mitra_profile']['name']?.toString() ?? partnerName;
    } else if (json['user_name'] != null) {
      partnerName = json['user_name'].toString();
    } else if (json['name'] != null) {
      partnerName = json['name'].toString();
    }

    // ============================================================
    // 3. VERIFIED — cek dari beberapa kemungkinan field
    // ============================================================
    bool isVerified = false;
    if (json['mitra_profile'] is Map &&
        json['mitra_profile']['is_verified'] != null) {
      isVerified = json['mitra_profile']['is_verified'] == true ||
          json['mitra_profile']['is_verified'] == 1;
    } else if (json['verified'] != null) {
      isVerified = json['verified'] == true;
    }

    // ============================================================
    // 4. JOBS COMPLETED
    // ============================================================
    int jobsCompleted = 0;
    if (json['mitra_profile'] is Map &&
        json['mitra_profile']['jobs_completed'] != null) {
      jobsCompleted = int.tryParse(
            json['mitra_profile']['jobs_completed'].toString(),
          ) ??
          0;
    } else if (json['jobs_completed'] != null) {
      jobsCompleted = int.tryParse(json['jobs_completed'].toString()) ?? 0;
    }

    // ============================================================
    // 5. STATUS — kunci untuk tombol berbeda
    // ============================================================
    final String bidStatus =
        json['status']?.toString().trim() ?? 'Menunggu';

    return OfferModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      jobId: int.tryParse(json['job_id']?.toString() ?? '0') ?? 0,
      mitraId: int.tryParse(
            json['mitra_id']?.toString() ??
                json['user_id']?.toString() ??
                '0',
          ) ??
          0,
      name: partnerName,
      verified: isVerified,
      jobsCompleted: jobsCompleted,
      priceAmount: amount,
      price:
          'Rp ${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
      note: json['note']?.toString() ?? json['message']?.toString(),
      status: bidStatus, // ✅
    );
  }

  // ============================================================
  // HELPER — biar gampang dipakai di UI
  // ============================================================

  bool get isPending => status.toLowerCase() == 'menunggu';
  bool get isAccepted => status.toLowerCase().contains('diterima');
  bool get isRejected => status.toLowerCase().contains('ditolak');
}