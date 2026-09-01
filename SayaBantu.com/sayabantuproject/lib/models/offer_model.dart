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
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    // 1. FIX HARGA: Cek 'offered_price' (standard Laravel), 'price', atau 'bid_amount'
    final rawPrice = json['offered_price'] ?? json['price'] ?? json['bid_amount'] ?? '0';
    final double amount = double.tryParse(rawPrice.toString()) ?? 0.0;

    // 2. FIX NAMA MITRA: Cek relasi 'user', 'mitra', 'mitra_profile', atau 'user_name'
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

    return OfferModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      jobId: int.tryParse(json['job_id']?.toString() ?? '0') ?? 0,
      mitraId: int.tryParse(json['mitra_id']?.toString() ?? json['user_id']?.toString() ?? '0') ?? 0,
      name: partnerName,
      verified: json['verified'] ?? true,
      jobsCompleted: int.tryParse(json['jobs_completed']?.toString() ?? '10') ?? 10,
      priceAmount: amount,
      price: 'Rp ${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
      note: json['note']?.toString() ?? json['message']?.toString(),
    );
  }
}