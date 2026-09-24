class ActiveOfferModel {
  final int id;
  final int jobId;
  final String title;
  final double offeredPrice;
  final int queuePosition;
  final bool isTop;
  final String status;

  // Fitur bukti
  final bool canSubmitProof;
  final bool proofSubmitted;
  final String? proofImage;
  final String? completionPhotoUrl;
  final String? proofDescription;

  // 🆕 TIMELINE
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? completionSubmittedAt;
  final DateTime? completionVerifiedAt;

  ActiveOfferModel({
    required this.id,
    required this.jobId,
    required this.title,
    required this.offeredPrice,
    required this.queuePosition,
    required this.isTop,
    required this.status,
    this.canSubmitProof = false,
    this.proofSubmitted = false,
    this.proofImage,
    this.completionPhotoUrl,
    this.proofDescription,
    this.startedAt,
    this.completedAt,
    this.completionSubmittedAt,
    this.completionVerifiedAt,
  });

  String get price {
    return "Rp ${offeredPrice.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}";
  }

  /// Path bukti (prioritas: completionPhotoUrl → proofImage)
  String? get proofImagePath {
    if (completionPhotoUrl != null && completionPhotoUrl!.isNotEmpty) {
      return completionPhotoUrl;
    }
    if (proofImage != null && proofImage!.isNotEmpty) {
      return proofImage;
    }
    return null;
  }

  /// Helper parse DateTime dari API
  static DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    return DateTime.tryParse(value.toString());
  }

  factory ActiveOfferModel.fromJson(Map<String, dynamic> json) {
    return ActiveOfferModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      jobId: int.tryParse(json['job_id']?.toString() ?? '0') ?? 0,
      title: json['tittle']?.toString() ??
             json['title']?.toString() ??
             'Pekerjaan Tidak Diketahui',
      offeredPrice: double.tryParse(
            (json['price'] ?? json['offered_price'])?.toString() ?? '0',
          ) ??
          0.0,
      queuePosition:
          int.tryParse(json['queue_position']?.toString() ?? '1') ?? 1,
      isTop: json['is_top'] == true || json['is_top']?.toString() == '1',
      status: json['status']?.toString() ?? 'Menunggu',
      canSubmitProof: json['can_submit_proof'] == true ||
          json['can_submit_proof']?.toString() == '1',
      proofSubmitted: json['proof_submitted'] == true ||
          json['proof_submitted']?.toString() == '1',
      proofImage: json['proof_image']?.toString(),
      completionPhotoUrl: json['completion_photo_url']?.toString(),
      proofDescription: json['proof_description']?.toString(),

      // 🆕 Timeline
      startedAt: _parseDate(json['started_at']),
      completedAt: _parseDate(json['completed_at']),
      completionSubmittedAt: _parseDate(json['completion_submitted_at']),
      completionVerifiedAt: _parseDate(json['completion_verified_at']),
    );
  }
}