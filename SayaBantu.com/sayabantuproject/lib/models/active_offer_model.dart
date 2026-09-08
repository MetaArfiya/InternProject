class ActiveOfferModel {
  final int id;
  final String title;
  final double offeredPrice;
  final int queuePosition;
  final bool isTop;
  final String status;

  // Untuk fitur bukti pekerjaan
  final bool canSubmitProof;
  final bool proofSubmitted;
  final String? proofImage;
  final String? proofDescription;

  ActiveOfferModel({
    required this.id,
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
    // ID
    int parsedId = 0;

    if (json['id'] != null) {
      parsedId = int.tryParse(json['id'].toString()) ?? 0;
    }

    // Harga
    double parsedPrice = 0.0;

    final rawPrice = json['price'] ?? json['offered_price'];

    if (rawPrice != null) {
      parsedPrice = double.tryParse(rawPrice.toString()) ?? 0.0;
    }

    // Posisi antrean
    int parsedQueue = 1;

    if (json['queue_position'] != null) {
      parsedQueue =
          int.tryParse(json['queue_position'].toString()) ?? 1;
    }

    // Top
    bool parsedIsTop = false;

    if (json['is_top'] != null) {
      parsedIsTop =
          json['is_top'] == true ||
          json['is_top'].toString() == '1';
    }

    // Status
    final parsedStatus =
        json['status']?.toString() ?? 'Menunggu';

    // Bukti pekerjaan
    bool parsedProofSubmitted = false;

    if (json['proof_submitted'] != null) {
      parsedProofSubmitted =
          json['proof_submitted'] == true ||
          json['proof_submitted'].toString() == '1' ||
          json['proof_submitted'].toString().toLowerCase() == 'true';
    }

    // Apakah mitra boleh mengirim bukti
    bool parsedCanSubmitProof = false;

    if (json['can_submit_proof'] != null) {
      parsedCanSubmitProof =
          json['can_submit_proof'] == true ||
          json['can_submit_proof'].toString() == '1' ||
          json['can_submit_proof'].toString().toLowerCase() == 'true';
    }

    return ActiveOfferModel(
      id: parsedId,

      title: json['tittle']?.toString() ??
          json['title']?.toString() ??
          'Pekerjaan Tidak Diketahui',

      offeredPrice: parsedPrice,

      queuePosition: parsedQueue,

      isTop: parsedIsTop,

      status: parsedStatus,

      canSubmitProof: parsedCanSubmitProof,

      proofSubmitted: parsedProofSubmitted,

      proofImage: json['proof_image']?.toString(),

      proofDescription:
          json['proof_description']?.toString(),
    );
  }
}