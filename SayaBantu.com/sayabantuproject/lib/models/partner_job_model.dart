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
  });

  factory PartnerJobModel.fromJson(Map<String, dynamic> json) {
    return PartnerJobModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title'] ?? json['tittle'] ?? '',
      category: json['category'] ?? json['kategori'] ?? '',
      description: json['description'] ?? json['deskripsi'] ?? '',
      location: json['location'] ?? json['lokasi'] ?? '',
      time: json['time'] ?? json['created_at'] ?? '',
      price: json['price'] != null
          ? json['price'].toString()
          : (json['initial_budget'] != null
              ? "Rp ${json['initial_budget']}"
              : "Rp 0"),
      status: json['status'] ?? 'open',
      hasOffered: json['has_offered'] ?? json['hasOffered'] ?? false,
    );
  }

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
    };
  }
}