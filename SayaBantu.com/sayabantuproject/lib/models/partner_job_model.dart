class PartnerJobModel {
  final int id;
  final String title;
  final String category;
  final String description;
  final String location;
  final String time;
  final String price;
  final String status;
  final bool hasOffered;
  final String? imageUrl;

  PartnerJobModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.location,
    required this.time,
    required this.price,
    this.status = "open",
    this.hasOffered = false,
    this.imageUrl,
  });

  // ============================================================
  // BUILD IMAGE URL
  // ============================================================

  static String? _buildImageUrl(dynamic value) {
    if (value == null) return null;

    final String url = value.toString().trim();

    if (url.isEmpty) return null;

    // ------------------------------------------------------------
    // Jika Laravel sudah mengirim URL lengkap
    // ------------------------------------------------------------

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // ------------------------------------------------------------
    // URL server Laravel
    //
    // Android Emulator:
    // http://10.0.2.2:8000
    //
    // Jika menggunakan Chrome/Desktop:
    // bisa diganti menjadi http://localhost:8000
    // ------------------------------------------------------------

    const String serverUrl = 'http://localhost:8000';

    // ------------------------------------------------------------
    // Jika Laravel mengirim:
    //
    // /storage/jobs/nama-file.jpg
    //
    // menjadi:
    //
    // http://10.0.2.2:8000/api/images/jobs/nama-file.jpg
    // ------------------------------------------------------------

    if (url.startsWith('/storage/jobs/')) {
      final String filename =
          url.substring('/storage/jobs/'.length);

      return '$serverUrl/api/images/jobs/$filename';
    }

    // ------------------------------------------------------------
    // Jika hanya berupa path:
    //
    // /images/jobs/file.jpg
    // ------------------------------------------------------------

    if (url.startsWith('/')) {
      return '$serverUrl$url';
    }

    // ------------------------------------------------------------
    // Jika Laravel hanya mengirim:
    //
    // jobs/file.jpg
    // ------------------------------------------------------------

    return '$serverUrl/$url';
  }

  // ============================================================
  // FROM JSON
  // ============================================================

  factory PartnerJobModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final String? imageUrl =
        _buildImageUrl(json['image_url']);

    // Debug
    print('🖼️ PARTNER JOB ${json['id']}');
    print('🖼️ IMAGE DARI API: ${json['image_url']}');
    print('🌐 IMAGE URL FLUTTER: $imageUrl');

    return PartnerJobModel(
      id: int.tryParse(
            json['id']?.toString() ?? '0',
          ) ??
          0,

      title: json['title']?.toString() ??
          json['tittle']?.toString() ??
          '',

      category: json['category']?.toString() ??
          json['kategori']?.toString() ??
          '',

      description: json['description']?.toString() ??
          json['deskripsi']?.toString() ??
          '',

      location: json['location']?.toString() ??
          json['lokasi']?.toString() ??
          '',

      time: json['time']?.toString() ??
          json['created_at']?.toString() ??
          '',

      price: json['price'] != null
          ? json['price'].toString()
          : json['initial_budget'] != null
              ? "Rp ${json['initial_budget']}"
              : "Rp 0",

      status: json['status']?.toString() ?? 'open',

      hasOffered:
          json['has_offered'] == true ||
          json['has_offered'] == 1 ||
          json['has_offered'] == '1' ||
          json['has_offered'] == 'true' ||
          json['hasOffered'] == true ||
          json['hasOffered'] == 1 ||
          json['hasOffered'] == '1' ||
          json['hasOffered'] == 'true',

      imageUrl: imageUrl,
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'description': description,
      'location': location,
      'time': time,
      'price': price,
      'status': status,
      'has_offered': hasOffered,
      'image_url': imageUrl,
    };
  }
}