import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import '../utils/indonesia_time.dart';

class PartnerJobModel {
  final int id;
  final String title;
  final String category;
  final String description;
  final String location;
  final String time;
  final String price;
  final double initialBudget;
  final String duration;
  final String status;
  final bool hasOffered;
  final String? imageUrl;
  final double? distanceKm;

  // Waktu mulai yang diinginkan Pelanggan
  final DateTime? preferredStartAt;

  PartnerJobModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.location,
    required this.time,
    required this.price,
    required this.initialBudget,
    required this.duration,
    this.status = "open",
    this.hasOffered = false,
    this.imageUrl,
    this.distanceKm,
    this.preferredStartAt,
  });

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

  factory PartnerJobModel.fromJson(Map<String, dynamic> json) {
    final String? imageUrl = _buildImageUrl(json['image_url']);

    double? parsedDistance;
    final rawDistance = json['distance_km'];

    if (rawDistance != null) {
      if (rawDistance is num) {
        parsedDistance = rawDistance.toDouble();
      } else {
        parsedDistance = double.tryParse(rawDistance.toString());
      }
    }

    DateTime? parsedPreferredStart;
    final rawPreferredStart = json['preferred_start_at'];

    if (rawPreferredStart != null &&
        rawPreferredStart.toString().trim().isNotEmpty) {
      parsedPreferredStart = IndonesiaTime.tryParseApiTimestamp(
        rawPreferredStart,
      );
    }

    debugPrint('🖼️ PARTNER JOB ${json['id']}');
    debugPrint('🖼️ IMAGE DARI API: ${json['image_url']}');
    debugPrint('🌐 IMAGE URL FLUTTER: $imageUrl');
    debugPrint('📏 DISTANCE: $parsedDistance km');
    debugPrint('📅 PREFERRED START: $parsedPreferredStart');

    return PartnerJobModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? json['tittle']?.toString() ?? '',
      category:
          json['category']?.toString() ?? json['kategori']?.toString() ?? '',
      description:
          json['description']?.toString() ??
          json['deskripsi']?.toString() ??
          '',
      location:
          json['location']?.toString() ?? json['lokasi']?.toString() ?? '',
      time: json['time']?.toString() ?? json['created_at']?.toString() ?? '',
      price: json['price'] != null
          ? json['price'].toString()
          : json['initial_budget'] != null
          ? "Rp ${json['initial_budget']}"
          : "Rp 0",
      initialBudget:
          double.tryParse(json['initial_budget']?.toString() ?? '0') ?? 0,
      duration: json['duration']?.toString() ?? '-',
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
      distanceKm: parsedDistance,
      preferredStartAt: parsedPreferredStart,
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
      'initial_budget': initialBudget,
      'duration': duration,
      'status': status,
      'has_offered': hasOffered,
      'image_url': imageUrl,
      'distance_km': distanceKm,
      'preferred_start_at': preferredStartAt?.toIso8601String(),
    };
  }
}
