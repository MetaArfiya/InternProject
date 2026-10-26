import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/tracking_model.dart';

/// Widget peta untuk menampilkan posisi mitra & lokasi tujuan.
class TrackingMap extends StatefulWidget {
  final TrackingModel tracking;
  final bool showMitra;

  const TrackingMap({super.key, required this.tracking, this.showMitra = true});

  @override
  State<TrackingMap> createState() => _TrackingMapState();
}

class _TrackingMapState extends State<TrackingMap> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitMarkers());
  }

  @override
  void didUpdateWidget(covariant TrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fitMarkers();
  }

  /// Auto zoom agar kedua marker kelihatan
  void _fitMarkers() {
    final points = <LatLng>[];
    if (widget.tracking.destination != null) {
      points.add(widget.tracking.destination!);
    }
    if (widget.showMitra && widget.tracking.mitraPosition != null) {
      points.add(widget.tracking.mitraPosition!);
    }
    if (points.isEmpty) return;

    try {
      if (points.length == 1) {
        _mapController.move(points.first, 15);
      } else {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(points),
            padding: const EdgeInsets.all(60),
          ),
        );
      }
    } catch (_) {
      // controller belum siap
    }
  }

  @override
  Widget build(BuildContext context) {
    final destination = widget.tracking.destination;
    final mitra = widget.tracking.mitraPosition;

    final markers = <Marker>[];

    if (destination != null) {
      markers.add(
        Marker(
          point: destination,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_on,
            color: Color(0xFFDC2626),
            size: 40,
          ),
        ),
      );
    }

    if (widget.showMitra && mitra != null) {
      markers.add(
        Marker(
          point: mitra,
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF0F766E), width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6),
              ],
            ),
            child: const Icon(
              Icons.engineering,
              color: Color(0xFF0F766E),
              size: 22,
            ),
          ),
        ),
      );
    }

    final initial = destination ?? mitra ?? const LatLng(-6.2, 106.8);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: initial,
          initialZoom: 14,
          minZoom: 3,
          maxZoom: 18,
        ),
        children: [
          // ✅ GANTI KE OSM FRANCE (stabil, tanpa API key)
          TileLayer(
            urlTemplate: 'https://maps.wikimedia.org/osm-intl/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.sayabantu.app',
            maxZoom: 19,
          ),
          MarkerLayer(markers: markers),
          if (destination != null && mitra != null)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [mitra, destination],
                  strokeWidth: 3,
                  color: const Color(0xFF0F766E),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
