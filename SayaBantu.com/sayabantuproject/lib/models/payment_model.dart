class PaymentModel {
  final int id;
  final int jobId;
  final int pelangganId;
  final int? mitraId;

  // Nominal
  final double jobAmount;
  final double commissionPercent;
  final double commissionAmount;
  final double totalPaid;
  final double mitraEarning;

  // Status & metode
  final String status;
  final String? paymentMethod;
  final String? referenceCode;

  // ============================================================
  // BARU — BUKTI TRANSFER PELANGGAN
  // ============================================================
  final String? customerProofUrl;
  final DateTime? customerProofUploadedAt;
  final String? customerBankName;
  final String? customerAccountName;

  // ============================================================
  // BARU — BUKTI TRANSFER ADMIN KE MITRA
  // ============================================================
  final String? mitraProofUrl;
  final DateTime? mitraProofUploadedAt;
  final String? adminNote;

  // ============================================================
  // BARU — INFO REKENING MITRA (untuk admin transfer)
  // ============================================================
  final Map<String, dynamic>? mitraBank;

  // Timestamp
  final DateTime? paidAt;
  final DateTime? settledAt;
  final DateTime? createdAt;

  // Relasi (opsional)
  final String? jobTitle;
  final String? mitraName;
  final String? pelangganName;

  PaymentModel({
    required this.id,
    required this.jobId,
    required this.pelangganId,
    this.mitraId,
    required this.jobAmount,
    required this.commissionPercent,
    required this.commissionAmount,
    required this.totalPaid,
    required this.mitraEarning,
    required this.status,
    this.paymentMethod,
    this.referenceCode,
    this.customerProofUrl,
    this.customerProofUploadedAt,
    this.customerBankName,
    this.customerAccountName,
    this.mitraProofUrl,
    this.mitraProofUploadedAt,
    this.adminNote,
    this.mitraBank,
    this.paidAt,
    this.settledAt,
    this.createdAt,
    this.jobTitle,
    this.mitraName,
    this.pelangganName,
  });

  // ============================================================
  // GETTER: STATUS LABEL
  // ============================================================
  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'waiting_verification':
        return 'Menunggu Verifikasi';
      case 'paid':
        return 'Siap Transfer';
      case 'settled':
        return 'Selesai';
      case 'refunded':
        return 'Dikembalikan';
      case 'failed':
        return 'Gagal';
      default:
        return 'Tidak Diketahui';
    }
  }

  // ============================================================
  // GETTER: FLAG STATUS
  // ============================================================
  bool get isPending => status == 'pending';
  bool get isWaitingVerification => status == 'waiting_verification';
  bool get isPaid => status == 'paid';
  bool get isSettled => status == 'settled';
  bool get isRefunded => status == 'refunded';
  bool get isSuccess => status == 'settled';

  /// Apakah pelanggan bisa upload bukti transfer?
  bool get canUploadCustomerProof => status == 'pending';

  /// Apakah admin bisa verifikasi bukti pelanggan?
  bool get canVerifyCustomerProof => status == 'waiting_verification';

  /// Apakah admin bisa transfer ke mitra?
  bool get canSettleToMitra => status == 'paid';

  // ============================================================
  // GETTER: TANGGAL FORMAT INDONESIA
  // ============================================================
  String get formattedDate {
    final date = createdAt ?? paidAt ?? DateTime.now();

    const bulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];

    return '${date.day} ${bulan[date.month - 1]} ${date.year}';
  }

  // ============================================================
  // STATIC: FORMAT RUPIAH
  // ============================================================
  static String formatRupiah(double value) {
    final String number = value.round().toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );
    return 'Rp$number';
  }

  // ============================================================
  // FACTORY: FROM JSON
  // ============================================================
  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    String? jobTitle;
    if (json['job'] is Map) {
      jobTitle = json['job']['tittle']?.toString() ??
          json['job']['title']?.toString();
    }

    String? mitraName;
    if (json['mitra'] is Map) {
      mitraName = json['mitra']['name']?.toString();
    }

    String? pelangganName;
    if (json['pelanggan'] is Map) {
      pelangganName = json['pelanggan']['name']?.toString();
    }

    // Parse mitra_bank (dari adminIndex transform)
    Map<String, dynamic>? mitraBank;
    if (json['mitra_bank'] is Map) {
      mitraBank = Map<String, dynamic>.from(json['mitra_bank']);
    }

    return PaymentModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      jobId: int.tryParse(json['job_id']?.toString() ?? '0') ?? 0,
      pelangganId: int.tryParse(json['pelanggan_id']?.toString() ?? '0') ?? 0,
      mitraId: json['mitra_id'] != null
          ? int.tryParse(json['mitra_id'].toString())
          : null,

      jobAmount:
          double.tryParse(json['job_amount']?.toString() ?? '0') ?? 0,
      commissionPercent:
          double.tryParse(json['commission_percent']?.toString() ?? '0') ?? 0,
      commissionAmount:
          double.tryParse(json['commission_amount']?.toString() ?? '0') ?? 0,
      totalPaid:
          double.tryParse(json['total_paid']?.toString() ?? '0') ?? 0,
      mitraEarning:
          double.tryParse(json['mitra_earning']?.toString() ?? '0') ?? 0,

      status: json['status']?.toString() ?? 'pending',
      paymentMethod: json['payment_method']?.toString(),
      referenceCode: json['reference_code']?.toString(),

      // Bukti pelanggan
      customerProofUrl: json['customer_proof_url']?.toString(),
      customerProofUploadedAt: json['customer_proof_uploaded_at'] != null
          ? DateTime.tryParse(json['customer_proof_uploaded_at'].toString())
          : null,
      customerBankName: json['customer_bank_name']?.toString(),
      customerAccountName: json['customer_account_name']?.toString(),

      // Bukti mitra
      mitraProofUrl: json['mitra_proof_url']?.toString(),
      mitraProofUploadedAt: json['mitra_proof_uploaded_at'] != null
          ? DateTime.tryParse(json['mitra_proof_uploaded_at'].toString())
          : null,
      adminNote: json['admin_note']?.toString(),

      // Rekening mitra
      mitraBank: mitraBank,

      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'].toString())
          : null,
      settledAt: json['settled_at'] != null
          ? DateTime.tryParse(json['settled_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,

      jobTitle: jobTitle,
      mitraName: mitraName,
      pelangganName: pelangganName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'pelanggan_id': pelangganId,
      'mitra_id': mitraId,
      'job_amount': jobAmount,
      'commission_percent': commissionPercent,
      'commission_amount': commissionAmount,
      'total_paid': totalPaid,
      'mitra_earning': mitraEarning,
      'status': status,
      'payment_method': paymentMethod,
      'reference_code': referenceCode,
      'customer_proof_url': customerProofUrl,
      'customer_proof_uploaded_at': customerProofUploadedAt?.toIso8601String(),
      'customer_bank_name': customerBankName,
      'customer_account_name': customerAccountName,
      'mitra_proof_url': mitraProofUrl,
      'mitra_proof_uploaded_at': mitraProofUploadedAt?.toIso8601String(),
      'admin_note': adminNote,
      'paid_at': paidAt?.toIso8601String(),
      'settled_at': settledAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}