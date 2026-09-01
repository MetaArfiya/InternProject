import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../widgets/custom_button.dart';

class HeroRight extends StatefulWidget {
  const HeroRight({super.key});

  @override
  State<HeroRight> createState() => _HeroRightState();
}

class _HeroRightState extends State<HeroRight> {
  late Future<Map<String, dynamic>?> _heroDataFuture;

  @override
  void initState() {
    super.initState();
    _heroDataFuture = fetchHeroData();
  }

  // Helper Base URL sesuai platform
  String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    } else {
      return 'http://10.0.2.2:8000/api'; // Android Emulator
    }
  }

  Future<Map<String, dynamic>?> fetchHeroData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/landing-hero-offers'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
          return body['data'];
        }
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching hero data: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _heroDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 420,
            height: 200, // Placeholder loading
            child: Center(
              child: CircularProgressIndicator(color: Color(0xff17C67A)),
            ),
          );
        }

        final data = snapshot.data;
        final List offers = data?['offers'] ?? [];
        final int activeMitraCount = data?['active_mitra_count'] ?? 0;
        final String title = data?['title'] ?? "PENAWARAN MASUK";

        // Hilangkan SizedBox height fixed, gunakan lebar saja.
        return SizedBox(
          width: 440,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              /// 1. CONTAINER UTAMA (Menentukan tinggi dari Stack)
              /// Kita beri margin atas dan bawah agar badge punya ruang
              Container(
                margin: const EdgeInsets.only(top: 20, bottom: 15, right: 15),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xff202C3F),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.35),
                      blurRadius: 35,
                      offset: const Offset(0, 20),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Tinggi menyesuaikan isi
                  children: [
                    Padding(
                      // Beri jarak kanan (right: 110) agar teks judul BERHENTI sebelum menyentuh badge "Terverifikasi"
                      padding: const EdgeInsets.only(right: 110),
                      child: Text(
                        title,
                        // Mengizinkan teks turun ke baris bawahnya saat panjang
                        softWrap: true,
                        maxLines: 2, // Maksimal 2 baris agar tetap rapi
                        overflow: TextOverflow.ellipsis, // Jika sangat panjang, beri titik-titik (...)
                        style: TextStyle(
                          color: Colors.white.withOpacity(.50),
                          fontSize: 12,
                          letterSpacing: 0.8,
                          height: 1.3, // Memberi sedikit jarak antar baris atas & bawah
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (offers.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            "Belum ada penawaran masuk",
                            style: TextStyle(color: Colors.white38),
                          ),
                        ),
                      )
                    else
                      ...offers.take(3).map((offer) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _offerItem(
                            active: offer['active'] ?? false,
                            initials: offer['initials'] ?? 'M',
                            name: offer['name'] ?? 'Mitra',
                            rating: offer['rating'] ?? '5.0',
                            point: offer['point'] ?? '0 poin',
                            price: offer['price'] ?? 'Rp 0',
                            badge: offer['badge'],
                          ),
                        );
                      }),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: "✓ Terima Mitra Terbaik",
                        width: double.infinity,
                        height: 48,
                        backgroundColor: const Color(0xff17C67A),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),

              /// 2. BADGE VERIFIED (Kanan Atas)
              /// Sekarang menumpang secara absolut di atas margin container
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff17C67A),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff17C67A).withOpacity(.3),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified,
                        color: Color(0xFF1E293B),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Terverifikasi",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            "Admin reviewed",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),

              /// 3. BADGE ONLINE (Bawah Kiri)
              /// Akan selalu menempel di bawah margin container secara otomatis
              Positioned(
                bottom: 0,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff283344),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xff17C67A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "$activeMitraCount mitra online sekarang",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _offerItem({
    required String initials,
    required String name,
    required String rating,
    required String point,
    required String price,
    String? badge,
    bool active = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: active ? const Color(0xff263347) : const Color(0xff2B374A),
        borderRadius: BorderRadius.circular(12),
        border: active
            ? Border.all(
                color: const Color(0xffF97316),
                width: 1.5,
              )
            : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor:
                active ? const Color(0xffF97316) : const Color(0xff3B485E),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 13,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      rating,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "• $point",
                      style: TextStyle(
                        color: Colors.white.withOpacity(.45),
                        fontSize: 11,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: TextStyle(
                  color: active ? const Color(0xffFF9A3E) : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffF97316),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ]
            ],
          )
        ],
      ),
    );
  }
}