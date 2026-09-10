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
  final Uint8List? imageBytes;
  final double initialBudget;
  final double? finalPrice;
  final String status;
  final String price;
  final String? createdAt;
  final String? startedAt;
  final String? completedAt;

  final String? partnerName;
  final String? acceptedPrice;
  final String? completedDate;
  final List<dynamic> offers;
  final int bidderCount;
  final int offerCount;

  final String? completionPhotoUrl;
  final String? completionStatus;
  final String? completionAdminNote;
  final DateTime? completionSubmittedAt;
  final DateTime? completionVerifiedAt;

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
    this.startedAt,
    this.completedAt,
    this.partnerName,
    this.acceptedPrice,
    this.completedDate,
    this.offers = const [],
    this.bidderCount = 0,
    this.offerCount = 0,
    this.completionPhotoUrl,
    this.completionStatus,
    this.completionAdminNote,
    this.completionSubmittedAt,
    this.completionVerifiedAt,
  });

  String get title => tittle;
  String get time => createdAt ?? 'Baru saja';

  // ============================================================
  // BUILD IMAGE URL
  // ============================================================
  static String? _buildImageUrl(dynamic value) {
    if (value == null) return null;
    final String url = value.toString().trim();
    if (url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    const String serverUrl = 'http://127.0.0.1:8000';
    if (url.startsWith('/storage/jobs/')) {
      final filename = url.substring('/storage/jobs/'.length);
      return '$serverUrl/api/images/jobs/$filename';
    }
    if (url.startsWith('/')) return '$serverUrl$url';
    return '$serverUrl/$url';
  }

  static String? _buildProofUrl(dynamic value) {
    if (value == null) return null;
    final String url = value.toString().trim();
    if (url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    const String serverUrl = 'http://127.0.0.1:8000';
    if (url.startsWith('/storage/completion_proofs/')) {
      final filename = url.substring('/storage/completion_proofs/'.length);
      return '$serverUrl/api/images/completion_proofs/$filename';
    }
    if (url.startsWith('/')) return '$serverUrl$url';
    return '$serverUrl/$url';
  }

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
    String? startedAt,
    String? completedAt,
    String? partnerName,
    String? acceptedPrice,
    String? completedDate,
    List<dynamic>? offers,
    int? bidderCount,
    int? offerCount,
    String? completionPhotoUrl,
    String? completionStatus,
    String? completionAdminNote,
    DateTime? completionSubmittedAt,
    DateTime? completionVerifiedAt,
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
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      partnerName: partnerName ?? this.partnerName,
      acceptedPrice: acceptedPrice ?? this.acceptedPrice,
      completedDate: completedDate ?? this.completedDate,
      offers: offers ?? this.offers,
      bidderCount: bidderCount ?? this.bidderCount,
      offerCount: offerCount ?? this.offerCount,
      completionPhotoUrl: completionPhotoUrl ?? this.completionPhotoUrl,
      completionStatus: completionStatus ?? this.completionStatus,
      completionAdminNote: completionAdminNote ?? this.completionAdminNote,
      completionSubmittedAt: completionSubmittedAt ?? this.completionSubmittedAt,
      completionVerifiedAt: completionVerifiedAt ?? this.completionVerifiedAt,
    );
  }

  factory JobModel.fromJson(Map<String, dynamic> json) {
    // ============================================================
    // BUDGET
    // ============================================================
    final double budget = double.tryParse(json['initial_budget']?.toString() ?? '0') ?? 0.0;

    // ============================================================
    // FINAL PRICE (dari acceptBid)
    // ============================================================
    final double? finalP = json['final_price'] != null
        ? double.tryParse(json['final_price'].toString())
        : null;

    // ============================================================
    // CATEGORY
    // ============================================================
    String categoryValue = 'Umum';
    if (json['category'] != null) {
      if (json['category'] is Map) {
        categoryValue = json['category']['name']?.toString() ?? 'Umum';
      } else if (json['category'] is String) {
        categoryValue = json['category'].toString();
      }
    }

    // ============================================================
    // OFFERS & COUNT
    // ============================================================
    final List<dynamic> offersList = json['offers'] is List
        ? json['offers'] as List<dynamic>
        : <dynamic>[];
    final int offerCountFromDatabase = int.tryParse(
      json['bids_count']?.toString() ?? json['offer_count']?.toString() ?? '0',
    ) ?? 0;

    // ============================================================
    // IMAGE
    // ============================================================
    final String? imageUrl = _buildImageUrl(json['image_url']);

    // ============================================================
    // BUKTI PEKERJAAN
    // ============================================================
    final completionPhotoUrl = _buildProofUrl(json['completion_photo_url']?.toString());
    final completionStatus = json['completion_status']?.toString();
    final completionAdminNote = json['completion_admin_note']?.toString();
    final completionSubmittedAt = json['completion_submitted_at'] != null
        ? DateTime.tryParse(json['completion_submitted_at'].toString())
        : null;
    final completionVerifiedAt = json['completion_verified_at'] != null
        ? DateTime.tryParse(json['completion_verified_at'].toString())
        : null;

    // ============================================================
    // PARTNER NAME (dari relasi 'mitra')
    // ============================================================
    String? partnerName;
    if (json['mitra'] is Map) {
      partnerName = json['mitra']['name']?.toString();
    } else if (json['mitra_name'] != null) {
      partnerName = json['mitra_name'].toString();
    }

    // ============================================================
    // ACCEPTED PRICE (format Rupiah dari final_price)
    // ============================================================
    final String? acceptedPrice = finalP != null ? _formatRupiah(finalP) : null;

    return JobModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      pelangganId: int.tryParse(json['pelanggan_id']?.toString() ?? '0') ?? 0,
      mitraId: json['mitra_id'] != null ? int.tryParse(json['mitra_id'].toString()) : null,
      tittle: json['tittle']?.toString() ?? json['title']?.toString() ?? 'Tanpa Judul',
      category: categoryValue,
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString(),
      imageUrl: imageUrl,
      initialBudget: budget,
      finalPrice: finalP,
      status: json['status']?.toString() ?? 'Mencari Mitra',
      price: _formatRupiah(budget),
      createdAt: json['created_at']?.toString(),
      startedAt: json['started_at']?.toString(),
      completedAt: json['completed_at']?.toString(),
      partnerName: partnerName,
      acceptedPrice: acceptedPrice,  // <-- INI YANG TADI KOSONG
      offers: offersList,
      bidderCount: offerCountFromDatabase,
      offerCount: offerCountFromDatabase,
      completionPhotoUrl: completionPhotoUrl,
      completionStatus: completionStatus,
      completionAdminNote: completionAdminNote,
      completionSubmittedAt: completionSubmittedAt,
      completionVerifiedAt: completionVerifiedAt,
    );
  }

  static String _formatRupiah(double number) {
    return 'Rp ${number.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }
}