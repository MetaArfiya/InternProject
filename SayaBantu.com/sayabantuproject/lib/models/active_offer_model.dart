class ActiveOfferModel {
  final int id;
  final String title;
  final double offeredPrice;
  final int queuePosition;
  final bool isTop;
  final String status;

  ActiveOfferModel({
    required this.id,
    required this.title,
    required this.offeredPrice,
    required this.queuePosition,
    required this.isTop,
    required this.status,
  });

  String get price {
    return "Rp ${offeredPrice.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}";
  }

  factory ActiveOfferModel.fromJson(Map<String, dynamic> json) {
    // 1. Parsing Safe ID
    int parsedId = 0;
    if (json['id'] != null) {
      parsedId = int.tryParse(json['id'].toString()) ?? 0;
    }

    // 2. Parsing Safe Price (Anti FormatException)
    double parsedPrice = 0.0;
    var rawPrice = json['price'] ?? json['offered_price'];
    if (rawPrice != null) {
      parsedPrice = double.tryParse(rawPrice.toString()) ?? 0.0;
    }

    // 3. Parsing Safe Queue Position
    int parsedQueue = 1;
    if (json['queue_position'] != null) {
      parsedQueue = int.tryParse(json['queue_position'].toString()) ?? 1;
    }

    // 4. Parsing Safe Is Top
    bool parsedIsTop = false;
    if (json['is_top'] != null) {
      parsedIsTop = json['is_top'] == true || json['is_top'].toString() == '1';
    }

    return ActiveOfferModel(
      id: parsedId,
      title: json['tittle']?.toString() ?? json['title']?.toString() ?? 'Pekerjaan Tidak Diketahui',
      offeredPrice: parsedPrice,
      queuePosition: parsedQueue,
      isTop: parsedIsTop,
      status: json['status']?.toString() ?? 'Menunggu',
    );
  }
}