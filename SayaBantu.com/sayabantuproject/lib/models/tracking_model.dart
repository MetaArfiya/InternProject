import 'package:latlong2/latlong.dart';

class TrackingModel {
  final int jobId;
  final String jobCode;
  final String title;

  final LatLng? destination;
  final String? destinationAddress;

  final LatLng? mitraPosition;
  final DateTime? mitraUpdatedAt;

  final double? distanceKm;
  final int? etaMinutes;
  final String? status; // menuju / sampai / dikerjakan / selesai / null
  final DateTime? startedAt;

  TrackingModel({
    required this.jobId,
    required this.jobCode,
    required this.title,
    this.destination,
    this.destinationAddress,
    this.mitraPosition,
    this.mitraUpdatedAt,
    this.distanceKm,
    this.etaMinutes,
    this.status,
    this.startedAt,
  });

  factory TrackingModel.fromJson(Map<String, dynamic> json) {
    LatLng? ll(dynamic lat, dynamic lng) {
      if (lat == null || lng == null) return null;
      final la = double.tryParse(lat.toString());
      final ln = double.tryParse(lng.toString());
      if (la == null || ln == null) return null;
      return LatLng(la, ln);
    }

    final dest = json['destination'];
    final mitra = json['mitra'];

    return TrackingModel(
      jobId: (json['job_id'] as num?)?.toInt() ?? 0,
      jobCode: json['job_code']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Pekerjaan',
      destination: dest is Map ? ll(dest['lat'], dest['lng']) : null,
      destinationAddress:
          dest is Map ? dest['address']?.toString() : null,
      mitraPosition:
          mitra is Map ? ll(mitra['lat'], mitra['lng']) : null,
      mitraUpdatedAt: mitra is Map && mitra['updated_at'] != null
          ? DateTime.tryParse(mitra['updated_at'].toString())
          : null,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      etaMinutes: (json['eta_minutes'] as num?)?.toInt(),
      status: json['status']?.toString(),
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'].toString())
          : null,
    );
  }

  bool get isActive =>
      status == 'menuju' || status == 'sampai' || status == 'dikerjakan';
}