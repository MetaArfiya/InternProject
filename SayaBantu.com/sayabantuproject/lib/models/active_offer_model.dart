class ActiveOfferModel {
  final int id;
  final int jobId; // <-- tambahkan
  final String title;
  final double offeredPrice;
  final int queuePosition;
  final bool isTop;
  final String status;

  // Fitur bukti (opsional)
  final bool canSubmitProof;
  final bool proofSubmitted;
  final String? proofImage;
  final String? proofDescription;

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
    this.proofDescription,
  });

  String get price {
    return "Rp ${offeredPrice.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}";
  }

  factory ActiveOfferModel.fromJson(Map<String, dynamic> json) {
    return ActiveOfferModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      jobId: int.tryParse(json['job_id']?.toString() ?? '0') ?? 0,
      title: json['tittle']?.toString() ?? json['title']?.toString() ?? 'Pekerjaan Tidak Diketahui',
      offeredPrice: double.tryParse((json['price'] ?? json['offered_price'])?.toString() ?? '0') ?? 0.0,
      queuePosition: int.tryParse(json['queue_position']?.toString() ?? '1') ?? 1,
      isTop: json['is_top'] == true || json['is_top']?.toString() == '1',
      status: json['status']?.toString() ?? 'Menunggu',
      canSubmitProof: json['can_submit_proof'] == true || json['can_submit_proof']?.toString() == '1',
      proofSubmitted: json['proof_submitted'] == true || json['proof_submitted']?.toString() == '1',
      proofImage: json['proof_image']?.toString(),
      proofDescription: json['proof_description']?.toString(),
    );
  }
}