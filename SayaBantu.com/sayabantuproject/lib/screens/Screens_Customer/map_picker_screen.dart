import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

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
  late LatLng _selectedPosition;

  final MapController _mapController = MapController();

  bool _isLoadingAddress = false;

  String _address = "";

  @override
  void initState() {
    super.initState();

    _selectedPosition = widget.initialPosition;

    _getAddress(_selectedPosition);
  }
  // =========================================================
// AMBIL LOKASI GPS SAAT INI
// =========================================================

Future<void> _goToCurrentLocation() async {
  try {
    bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'GPS/lokasi perangkat sedang tidak aktif.',
          ),
        ),
      );

      return;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Izin lokasi ditolak.',
          ),
        ),
      );

      return;
    }

    if (permission ==
        LocationPermission.deniedForever) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Izin lokasi ditolak permanen. '
            'Silakan aktifkan izin lokasi dari pengaturan perangkat.',
          ),
        ),
      );

      return;
    }

    final Position position =
        await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    final LatLng currentPosition = LatLng(
      position.latitude,
      position.longitude,
    );

    if (!mounted) return;

    setState(() {
      _selectedPosition = currentPosition;
      _isLoadingAddress = true;
    });

    _mapController.move(
      currentPosition,
      17,
    );

    await _getAddress(currentPosition);
  } catch (e) {
    debugPrint(
      'Gagal mendapatkan lokasi GPS: $e',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Gagal mendapatkan lokasi saat ini: $e',
        ),
      ),
    );
  }
}
  // =========================================================
  // REVERSE GEOCODING OPENSTREETMAP
  // =========================================================

  Future<void> _getAddress(LatLng position) async {
    if (!mounted) return;

    setState(() {
      _isLoadingAddress = true;
      _address = "";
    });

    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/reverse',
        {
          'format': 'jsonv2',
          'lat': position.latitude.toString(),
          'lon': position.longitude.toString(),
          'zoom': '18',
          'addressdetails': '1',
          'accept-language': 'id',
        },
      );

      final response = await http.get(
        uri,
        headers: const {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Reverse geocoding gagal: ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body);

      final addressData =
          data['address'] as Map<String, dynamic>?;

      if (addressData == null) {
        throw Exception('Data alamat tidak ditemukan');
      }

      final formattedAddress =
          _formatIndonesiaAddress(addressData);

      if (!mounted) return;

      setState(() {
        _address = formattedAddress;
      });
    } catch (e) {
      debugPrint(
        'Gagal mengambil alamat OpenStreetMap: $e',
      );

      if (!mounted) return;

      setState(() {
        _address = 'Alamat tidak ditemukan';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoadingAddress = false;
      });
    }
  }

  // =========================================================
  // FORMAT ALAMAT INDONESIA
  // =========================================================

  String _formatIndonesiaAddress(
    Map<String, dynamic> address,
  ) {
    final List<String> parts = [];

    void addPart(dynamic value) {
      if (value == null) return;

      final text = value.toString().trim();

      if (text.isEmpty) return;

      if (!parts.contains(text)) {
        parts.add(text);
      }
    }

    // -------------------------------------------------------
    // JALAN / GANG
    // -------------------------------------------------------

    final road = address['road'];

    final houseNumber = address['house_number'];

    if (road != null &&
        road.toString().trim().isNotEmpty) {
      String roadName = road.toString().trim();

      // Tidak menambahkan "Jl." otomatis karena
      // nama jalan dari OSM bisa berupa Gang, Jalan,
      // Lorong, dll.
      if (houseNumber != null &&
          houseNumber.toString().trim().isNotEmpty) {
        roadName =
            '$roadName No. ${houseNumber.toString().trim()}';
      }

      addPart(roadName);
    }

    // -------------------------------------------------------
    // DUSUN / DESA / KELURAHAN
    // -------------------------------------------------------

    addPart(address['neighbourhood']);

    addPart(address['quarter']);

    addPart(address['hamlet']);

    // -------------------------------------------------------
    // DESA / KELURAHAN
    // -------------------------------------------------------

    addPart(address['village']);

    // -------------------------------------------------------
    // KECAMATAN
    // -------------------------------------------------------

    addPart(address['suburb']);

    addPart(address['town']);

    // -------------------------------------------------------
    // KOTA / KABUPATEN
    // -------------------------------------------------------

    addPart(address['city']);

    addPart(address['municipality']);

    addPart(address['county']);

    // -------------------------------------------------------
    // PROVINSI
    // -------------------------------------------------------

    String? province =
        address['state']?.toString().trim();

    if (province != null &&
        province.isNotEmpty) {
      province = _convertProvinceName(province);

      addPart(province);
    }

    // -------------------------------------------------------
    // KODE POS
    // -------------------------------------------------------

    addPart(address['postcode']);

    // -------------------------------------------------------
    // NEGARA
    // -------------------------------------------------------

    final country =
        address['country']?.toString().trim();

    if (country != null &&
        country.isNotEmpty) {
      if (country.toLowerCase() == 'indonesia') {
        addPart('Indonesia');
      } else {
        addPart(country);
      }
    }

    if (parts.isEmpty) {
      return 'Alamat tidak ditemukan';
    }

    return parts.join(', ');
  }

  // =========================================================
  // KONVERSI NAMA PROVINSI
  // =========================================================

  String _convertProvinceName(
    String province,
  ) {
    final normalized =
        province.toLowerCase().trim();

    switch (normalized) {
      case 'special region of yogyakarta':
        return 'Daerah Istimewa Yogyakarta';

      case 'yogyakarta':
        return 'Daerah Istimewa Yogyakarta';

      case 'west java':
        return 'Jawa Barat';

      case 'central java':
        return 'Jawa Tengah';

      case 'east java':
        return 'Jawa Timur';

      case 'banten':
        return 'Banten';

      case 'jakarta':
      case 'dki jakarta':
        return 'DKI Jakarta';

      case 'west sumatra':
        return 'Sumatera Barat';

      case 'south sumatra':
        return 'Sumatera Selatan';

      case 'north sumatra':
        return 'Sumatera Utara';

      case 'south sulawesi':
        return 'Sulawesi Selatan';

      case 'north sulawesi':
        return 'Sulawesi Utara';

      case 'west kalimantan':
        return 'Kalimantan Barat';

      case 'south kalimantan':
        return 'Kalimantan Selatan';

      case 'east kalimantan':
        return 'Kalimantan Timur';

      case 'central kalimantan':
        return 'Kalimantan Tengah';

      case 'north kalimantan':
        return 'Kalimantan Utara';

      case 'bali':
        return 'Bali';

      case 'papua':
        return 'Papua';

      default:
        return province;
    }
  }

  // =========================================================
  // KETIKA PETA DIKLIK
  // =========================================================

  void _onMapTap(
    TapPosition tapPosition,
    LatLng position,
  ) {
    if (!mounted) return;

    setState(() {
      _selectedPosition = position;
    });

    _getAddress(position);
  }

  // =========================================================
  // GUNAKAN LOKASI
  // =========================================================

  void _useLocation() {
    if (_isLoadingAddress) return;

    Navigator.pop(
      context,
      {
        'position': _selectedPosition,
        'address': _address,
      },
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.of(context).size.width;

    final screenHeight =
        MediaQuery.of(context).size.height;

    final isMobile = screenWidth < 600;

    return Dialog(
      insetPadding: EdgeInsets.all(
        isMobile ? 10 : 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: SizedBox(
        width:
            isMobile ? screenWidth - 20 : 700,
        height:
            isMobile ? screenHeight - 40 : 650,
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(18),
          child: Column(
            children: [

              // =================================================
              // HEADER
              // =================================================

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [

                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.orange,
                    ),

                    const SizedBox(width: 10),

                    const Expanded(
                      child: Text(
                        'Pilih Lokasi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon:
                          const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // =================================================
              // MAP
              // =================================================

              Expanded(
                child: Stack(
                  children: [

                    FlutterMap(
                      mapController:
                          _mapController,
                      options: MapOptions(
                        initialCenter:
                            _selectedPosition,
                        initialZoom: 16,
                        onTap: _onMapTap,
                      ),
                      children: [

                        // =================================================
                        // OPENSTREETMAP
                        // =================================================

                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.sayabantu.project',
                        ),

                        // =================================================
                        // MARKER
                        // =================================================

                        MarkerLayer(
                          markers: [

                            Marker(
                              point:
                                  _selectedPosition,
                              width: 50,
                              height: 50,
                              child:
                                  const Icon(
                                Icons.location_pin,
                                size: 50,
                                color: Colors.red,
                              ),
                            ),

                          ],
                        ),
                      ],
                    ),

                    // =================================================
                    // PETUNJUK
                    // =================================================

                    Positioned(
                      top: 15,
                      left: 15,
                      right: 15,
                      child: Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 8,
                              color: Colors.black
                                  .withOpacity(
                                0.15,
                              ),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Ketuk peta untuk menentukan lokasi',
                          textAlign:
                              TextAlign.center,
                        ),
                      ),
                    ),

                    // =================================================
                    // TOMBOL LOKASI TERPILIH
                    // =================================================

                    Positioned(
                      right: 15,
                      bottom: 15,
                      child:
                          FloatingActionButton
                              .small(
                        backgroundColor:
                            Colors.white,
                        foregroundColor:
                            Colors.black87,
                        onPressed: () {
                          _mapController.move(
                            _selectedPosition,
                            16,
                          );
                        },
                        child: const Icon(
                          Icons.my_location,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // =================================================
              // INFORMASI ALAMAT
              // =================================================

              Container(
                padding:
                    const EdgeInsets.all(18),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    const Text(
                      'Lokasi terpilih',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // =================================================
                    // LOADING ALAMAT
                    // =================================================

                    if (_isLoadingAddress)

                      const Row(
                        children: [

                          SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),

                          SizedBox(width: 10),

                          Text(
                            'Mencari alamat...',
                          ),

                        ],
                      )

                    else

                      Text(
                        _address.isEmpty
                            ? 'Alamat belum ditemukan'
                            : _address,
                        maxLines: 3,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              Colors.grey.shade700,
                        ),
                      ),

                    const SizedBox(height: 10),

                    // =================================================
                    // KOORDINAT
                    // =================================================

                    Text(
                      '${_selectedPosition.latitude.toStringAsFixed(6)}, '
                      '${_selectedPosition.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 15),

                    // =================================================
                    // BUTTON
                    // =================================================

                    SizedBox(
                      width: double.infinity,
                      child:
                          ElevatedButton(
                        onPressed:
                            _isLoadingAddress ||
                                    _address.isEmpty
                                ? null
                                : _useLocation,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(
                            0xffF97316,
                          ),
                          foregroundColor:
                              Colors.white,
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 15,
                          ),
                        ),
                        child: const Text(
                          'Gunakan Lokasi Ini',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}