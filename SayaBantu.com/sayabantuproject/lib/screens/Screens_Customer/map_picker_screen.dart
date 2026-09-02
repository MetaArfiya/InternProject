import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class MapPickerDialog extends StatefulWidget {
  final LatLng initialPosition;

  const MapPickerDialog({
    super.key,
    required this.initialPosition,
  });

  @override
  State<MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<MapPickerDialog> {
  final MapController _mapController = MapController();

  late LatLng _selectedPosition;

  String _address = "";
  bool _isLoadingAddress = false;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();

    _selectedPosition = widget.initialPosition;

    // Ambil alamat dari posisi awal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getAddress(_selectedPosition);
    });
  }

  // =========================================================
  // MENGAMBIL ALAMAT BERDASARKAN KOORDINAT
  // =========================================================

  Future<void> _getAddress(LatLng position) async {
  if (!mounted) return;

  setState(() {
    _isLoadingAddress = true;
    _address = "";
  });

  try {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?format=json'
      '&lat=${position.latitude}'
      '&lon=${position.longitude}'
      '&zoom=18'
      '&addressdetails=1',
    );

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'SayaBantu.Com/1.0',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final displayName = data['display_name'];

      if (displayName != null &&
          displayName.toString().trim().isNotEmpty) {
        if (mounted) {
          setState(() {
            _address = displayName.toString();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _address = "Alamat tidak ditemukan";
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _address = "Alamat tidak ditemukan";
        });
      }
    }
  } catch (e) {
    debugPrint("Reverse geocoding error: $e");

    if (mounted) {
      setState(() {
        _address = "Alamat tidak ditemukan";
      });
    }
  } finally {
    if (mounted) {
      setState(() {
        _isLoadingAddress = false;
      });
    }
  }
}
  // =========================================================
  // MEMILIH LOKASI DENGAN KLIK PETA
  // =========================================================

  void _onMapTap(
    TapPosition tapPosition,
    LatLng position,
  ) {
    setState(() {
      _selectedPosition = position;
      _address = "";
    });

    _getAddress(position);
  }

  // =========================================================
  // MENGAMBIL LOKASI PERANGKAT SAAT INI
  // =========================================================

  Future<void> _getCurrentLocation() async {
    if (_isGettingLocation) return;

    setState(() {
      _isGettingLocation = true;
    });

    try {
      // -------------------------------------------------------
      // CEK GPS / LOCATION SERVICE
      // -------------------------------------------------------

      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        _showMessage(
          "Layanan lokasi sedang tidak aktif.",
        );

        setState(() {
          _isGettingLocation = false;
        });

        return;
      }

      // -------------------------------------------------------
      // CEK PERMISSION
      // -------------------------------------------------------

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;

        _showMessage(
          "Izin lokasi ditolak.",
        );

        setState(() {
          _isGettingLocation = false;
        });

        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        _showMessage(
          "Izin lokasi ditolak secara permanen. "
          "Silakan aktifkan izin lokasi melalui pengaturan perangkat.",
        );

        setState(() {
          _isGettingLocation = false;
        });

        return;
      }

      // -------------------------------------------------------
      // AMBIL POSISI TERKINI
      // -------------------------------------------------------

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final currentPosition = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _selectedPosition = currentPosition;
      });

      // -------------------------------------------------------
      // PINDAHKAN PETA KE LOKASI SAAT INI
      // -------------------------------------------------------

      _mapController.move(
        currentPosition,
        17,
      );

      // -------------------------------------------------------
      // AMBIL ALAMAT
      // -------------------------------------------------------

      await _getAddress(currentPosition);

      if (!mounted) return;

      _showMessage(
        "Lokasi saat ini berhasil ditemukan.",
      );
    } catch (e) {
      debugPrint("Gagal mendapatkan lokasi: $e");

      if (!mounted) return;

      _showMessage(
        "Gagal mendapatkan lokasi saat ini.",
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  // =========================================================
  // SNACKBAR
  // =========================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // =========================================================
  // GUNAKAN LOKASI
  // =========================================================

  void _useLocation() {
    Navigator.pop(
      context,
      {
        "position": _selectedPosition,
        "address": _address,
        "latitude": _selectedPosition.latitude,
        "longitude": _selectedPosition.longitude,
      },
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    final isMobile = screenWidth < 600;

    return Dialog(
      insetPadding: EdgeInsets.all(
        isMobile ? 10 : 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: isMobile
            ? screenWidth - 20
            : 700,
        height: isMobile
            ? screenHeight - 40
            : 650,
        child: Column(
          children: [
            // =================================================
            // HEADER
            // =================================================

            _buildHeader(context),

            // =================================================
            // MAP
            // =================================================

            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,

                    options: MapOptions(
                      initialCenter: _selectedPosition,
                      initialZoom: 16,

                      onTap: _onMapTap,

                      interactionOptions:
                          const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),

                    children: [
                      // ------------------------------------------------
                      // OPEN STREET MAP
                      // ------------------------------------------------

                      TileLayer(
                        urlTemplate:
                            "https://tile.openstreetmap.org/{z}/{x}/{y}.png",

                        userAgentPackageName:
                            "com.sayabantu.project",
                      ),

                      // ------------------------------------------------
                      // MARKER
                      // ------------------------------------------------

                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedPosition,
                            width: 55,
                            height: 55,

                            child: const Icon(
                              Icons.location_pin,
                              size: 52,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // =================================================
                  // PETUNJUK DI ATAS PETA
                  // =================================================

                  Positioned(
                    top: 15,
                    left: 15,
                    right: 15,
                    child: _buildMapInstruction(),
                  ),

                  // =================================================
                  // TOMBOL LOKASI SAYA
                  // =================================================

                  Positioned(
                    right: 15,
                    bottom: 15,
                    child: _buildCurrentLocationButton(),
                  ),
                ],
              ),
            ),

            // =================================================
            // INFORMASI LOKASI
            // =================================================

            _buildLocationInformation(context),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surface,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: Colors.orange,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  "Pilih Lokasi",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 2),

                Text(
                  "Tentukan lokasi pekerjaan pada peta",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: "Tutup",
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PETUNJUK PETA
  // =========================================================

  Widget _buildMapInstruction() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 2),
            color: Colors.black.withOpacity(0.15),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: 18,
          ),

          SizedBox(width: 8),

          Flexible(
            child: Text(
              "Ketuk peta untuk menentukan lokasi",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUTTON LOKASI SAAT INI
  // =========================================================

  Widget _buildCurrentLocationButton() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _isGettingLocation
            ? null
            : _getCurrentLocation,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: _isGettingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.my_location,
                    size: 23,
                  ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // INFORMASI LOKASI
  // =========================================================

  Widget _buildLocationInformation(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        14,
        18,
        18,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surface,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            "Lokasi terpilih",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // -------------------------------------------------
          // ALAMAT
          // -------------------------------------------------

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  BorderRadius.circular(10),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: _isLoadingAddress
                ? const Row(
                    children: [
                      SizedBox(
                        width: 17,
                        height: 17,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Mencari alamat...",
                        style: TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 20,
                        color: Colors.red,
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          _address.isEmpty
                              ? "Alamat belum ditemukan"
                              : _address,
                          maxLines: 3,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: _address.isEmpty
                                ? Colors.grey.shade600
                                : Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 8),

          // -------------------------------------------------
          // KOORDINAT
          // -------------------------------------------------

          Text(
            "Koordinat: "
            "${_selectedPosition.latitude.toStringAsFixed(6)}, "
            "${_selectedPosition.longitude.toStringAsFixed(6)}",
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 14),

          // -------------------------------------------------
          // BUTTON GUNAKAN LOKASI
          // -------------------------------------------------

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  _isLoadingAddress
                      ? null
                      : _useLocation,
              icon: const Icon(
                Icons.check,
                size: 19,
              ),
              label: const Text(
                "Gunakan Lokasi Ini",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xffF97316),
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    Colors.grey.shade300,
                disabledForegroundColor:
                    Colors.grey.shade600,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}