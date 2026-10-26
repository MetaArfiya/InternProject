import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

import 'api_service.dart';

/// Service untuk handle tracking lokasi mitra.
/// Pakai singleton pattern agar hanya 1 instance aktif.
class TrackingService {
  TrackingService._();
  static final TrackingService instance = TrackingService._();

  Timer? _timer;
  int? _activeJobId;

  /// Callback opsional untuk update UI saat ada response dari server
  Function(Map<String, dynamic>)? onTick;

  bool get isRunning => _timer != null && _timer!.isActive;
  int? get activeJobId => _activeJobId;

  // =========================================================
  // CEK & MINTA IZIN LOKASI
  // =========================================================
  Future<bool> _ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  // =========================================================
  // MULAI TRACKING — kirim posisi awal + timer periodik
  // =========================================================
  Future<bool> startTracking(
    int jobId, {
    Duration interval = const Duration(seconds: 10),
  }) async {
    if (isRunning) await stopTracking();

    final allowed = await _ensurePermission();
    if (!allowed) return false;

    _activeJobId = jobId;

    // Kirim posisi awal
    final ok = await _sendLocation(jobId);
    if (!ok) {
      _activeJobId = null;
      return false;
    }

    // Timer periodik
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) async {
      if (_activeJobId == null) return;
      await _sendLocation(_activeJobId!);
    });

    return true;
  }

  // =========================================================
  // KIRIM POSISI SEKALI
  // =========================================================
  Future<bool> _sendLocation(int jobId) async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final response = await ApiService.post('/jobs/$jobId/tracking/location', {
        'lat': pos.latitude,
        'lng': pos.longitude,
      });

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data['data'] is Map && onTick != null) {
            onTick!(Map<String, dynamic>.from(data['data']));
          }
        } catch (_) {}
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // =========================================================
  // STOP TRACKING
  // =========================================================
  Future<void> stopTracking() async {
    _timer?.cancel();
    _timer = null;
    _activeJobId = null;
  }
}
