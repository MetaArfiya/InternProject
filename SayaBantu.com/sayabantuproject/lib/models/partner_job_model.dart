import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

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

  // ============================================================
  // 🆕 FIELD BARU — Jarak dari mitra (km)
  // ============================================================
  final double? distanceKm;

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
    this.distanceKm,   // ← baru
  });

  // ============================================================
  // BUILD IMAGE URL
  // ============================================================

  static String? _buildImageUrl(dynamic value) {
    if (value == null) return null;

    final String url = value.toString().trim();

    if (url.isEmpty) return null;

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    const String serverUrl = 'http://localhost:8000';

    if (url.startsWith('/storage/jobs/')) {
      final String filename = url.substring('/storage/jobs/'.length);
      return '$serverUrl/api/images/jobs/$filename';
    }

    if (url.startsWith('/')) {
      return '$serverUrl$url';
    }

    return '$serverUrl/$url';
  }

  // ============================================================
  // FROM JSON
  // ============================================================

  factory PartnerJobModel.fromJson(Map<String, dynamic> json) {
    final String? imageUrl = _buildImageUrl(json['image_url']);

    // ---- Parse distance_km (bisa null / int / double / string) ----
    double? parsedDistance;
    final rawDistance = json['distance_km'];
    if (rawDistance != null) {
      if (rawDistance is num) {
        parsedDistance = rawDistance.toDouble();
      } else {
        parsedDistance = double.tryParse(rawDistance.toString());
      }
    }

    // Debug
    debugPrint('🖼️ PARTNER JOB ${json['id']}');
    debugPrint('🖼️ IMAGE DARI API: ${json['image_url']}');
    debugPrint('🌐 IMAGE URL FLUTTER: $imageUrl');
    debugPrint('📏 DISTANCE: $parsedDistance km');

    return PartnerJobModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,

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

      hasOffered: json['has_offered'] == true ||
          json['has_offered'] == 1 ||
          json['has_offered'] == '1' ||
          json['has_offered'] == 'true' ||
          json['hasOffered'] == true ||
          json['hasOffered'] == 1 ||
          json['hasOffered'] == '1' ||
          json['hasOffered'] == 'true',

      imageUrl: imageUrl,

      // 🆕
      distanceKm: parsedDistance,
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
      'distance_km': distanceKm,
    };
  }
}