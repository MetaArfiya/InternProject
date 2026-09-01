import 'dart:typed_data';

class JobModel {
  final int id;
  final int pelangganId;
  final int? mitraId;
  final String tittle;
  final String category;
  final String description;
  final String? location;
  final String? imageUrl;
  final Uint8List? imageBytes; // Digunakan oleh JobCard
  final double initialBudget;
  final double? finalPrice;
  final String status;
  final String price;
  final String? createdAt;

  // Properti pendukung UI / State lokal
  final String? partnerName;
  final String? acceptedPrice;
  final String? completedDate;
  final List<dynamic> offers;
  final int bidderCount;
  final int offerCount; // Digunakan oleh JobCard

  JobModel({
    required this.id,
    required this.pelangganId,
    this.mitraId,
    required this.tittle,
    required this.category,
    required this.description,
    this.location,
    this.imageUrl,
    this.imageBytes,
    required this.initialBudget,
    this.finalPrice,
    required this.status,
    required this.price,
    this.createdAt,
    this.partnerName,
    this.acceptedPrice,
    this.completedDate,
    this.offers = const [],
    this.bidderCount = 0,
    this.offerCount = 0,
  });

  // Getter penolong
  String get title => tittle;
  String get time => createdAt ?? 'Baru saja';

  // CopyWith untuk pembaharuan state immutable
  JobModel copyWith({
    int? id,
    int? pelangganId,
    int? mitraId,
    String? tittle,
    String? category,
    String? description,
    String? location,
    String? imageUrl,
    Uint8List? imageBytes,
    double? initialBudget,
    double? finalPrice,
    String? status,
    String? price,
    String? createdAt,
    String? partnerName,
    String? acceptedPrice,
    String? completedDate,
    List<dynamic>? offers,
    int? bidderCount,
    int? offerCount,
  }) {
    return JobModel(
      id: id ?? this.id,
      pelangganId: pelangganId ?? this.pelangganId,
      mitraId: mitraId ?? this.mitraId,
      tittle: tittle ?? this.tittle,
      category: category ?? this.category,
      description: description ?? this.description,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      imageBytes: imageBytes ?? this.imageBytes,
      initialBudget: initialBudget ?? this.initialBudget,
      finalPrice: finalPrice ?? this.finalPrice,
      status: status ?? this.status,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      partnerName: partnerName ?? this.partnerName,
      acceptedPrice: acceptedPrice ?? this.acceptedPrice,
      completedDate: completedDate ?? this.completedDate,
      offers: offers ?? this.offers,
      bidderCount: bidderCount ?? this.bidderCount,
      offerCount: offerCount ?? this.offerCount,
    );
  }

  // Deserialisasi JSON dari REST API
  factory JobModel.fromJson(Map<String, dynamic> json) {
    final double budget =
        double.tryParse(json['initial_budget']?.toString() ?? '0') ?? 0.0;

    final double? finalP = json['final_price'] != null
        ? double.tryParse(json['final_price'].toString())
        : null;

    String categoryValue = 'Umum';
    if (json['category'] != null) {
      if (json['category'] is Map) {
        categoryValue = json['category']['name']?.toString() ?? 'Umum';
      } else if (json['category'] is String) {
        categoryValue = json['category'];
      }
    }

    final offersList = json['offers'] is List ? json['offers'] as List : [];

    return JobModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      pelangganId:
          int.tryParse(json['pelanggan_id']?.toString() ?? '0') ?? 0,
      mitraId: json['mitra_id'] != null
          ? int.tryParse(json['mitra_id'].toString())
          : null,
      tittle: json['tittle']?.toString() ??
          json['title']?.toString() ??
          'Tanpa Judul',
      category: categoryValue,
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString(),
      imageUrl: json['image_url']?.toString(),
      initialBudget: budget,
      finalPrice: finalP,
      status: json['status']?.toString() ?? 'Mencari Mitra',
      price: _formatRupiah(budget),
      createdAt: json['created_at']?.toString(),
      offers: offersList,
      bidderCount: offersList.length,
      offerCount: offersList.length,
    );
  }

  static String _formatRupiah(double number) {
    return 'Rp ${number.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }
}