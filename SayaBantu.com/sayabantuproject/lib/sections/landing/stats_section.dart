import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'stat_counter.dart';

class StatsSection extends StatefulWidget {
  const StatsSection({super.key});

  @override
  State<StatsSection> createState() => _StatsSectionState();
}

class _StatsSectionState extends State<StatsSection> {
  late Future<Map<String, dynamic>?> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = fetchStatsData();
  }

  String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    } else {
      return 'http://10.0.2.2:8000/api';
    }
  }

  Future<Map<String, dynamic>?> fetchStatsData() async {
    try {
      final url = Uri.parse('$baseUrl/landing-stats');
      debugPrint("Fetching stats from: $url");

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("Stats Response Status: ${response.statusCode}");
      debugPrint("Stats Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
          return body;
        }
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching stats: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final isMobile = width < 600;
        final isTablet = width >= 600 && width < 1100;

        final columnCount = isMobile
            ? 1
            : isTablet
                ? 2
                : 4;

        return Container(
          width: double.infinity,
          color: const Color(0xffF97316),
          child: Stack(
            children: [
              /// Background Circle Kiri
              Positioned(
                left: -60,
                bottom: -60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              /// Background Circle Kanan
              Positioned(
                right: -90,
                top: -90,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.06),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile
                      ? 20
                      : isTablet
                          ? 50
                          : 100,
                  vertical: isMobile ? 50 : 90,
                ),
                child: Column(
                  children: [
                    /// Judul
                    Text(
                      "Dipercaya Ribuan Pelanggan & Mitra",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 28 : 42,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: .3),

                    const SizedBox(height: 14),

                    /// Subtitle
                    Text(
                      "Angka nyata dari platform kami yang terus berkembang",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(.9),
                        fontSize: isMobile ? 14 : 18,
                      ),
                    )
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: .2),

                    SizedBox(
                      height: isMobile ? 40 : 70,
                    ),

                    /// FETCH DATA DARI DATABASE DENGAN FUTUREBUILDER
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _statsFuture,
                      builder: (context, snapshot) {
                        // Tampilkan loading indicator saat data sedang diambil
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40.0),
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          );
                        }

                        final response = snapshot.data;
                        final data = response?['data'];

                        // Nilai fallback jika API kosong atau gagal dimuat
                        final completedJobs = data?['completed_jobs'] ?? "12.480+";
                        final completedSubtitle = data?['completed_subtitle'] ?? "sejak Januari 2024";

                        final verifiedMitra = data?['verified_mitra'] ?? "1.240+";
                        final verifiedSubtitle = data?['verified_subtitle'] ?? "di 12 kota besar";

                        final ratingValue = data?['rating_value'] ?? "4.9 / 5";
                        final ratingSubtitle = data?['rating_subtitle'] ?? "dari 8.200+ ulasan";

                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: columnCount,
                          crossAxisSpacing: 30,
                          mainAxisSpacing: 30,
                          childAspectRatio: isMobile ? 2.3 : 1.25,
                          children: [
                            StatCounter(
                              icon: Icons.task_alt,
                              value: completedJobs,
                              title: "Pekerjaan Selesai",
                              subtitle: completedSubtitle,
                            )
                                .animate(delay: 400.ms)
                                .fadeIn(duration: 500.ms)
                                .slideY(begin: .25),

                            StatCounter(
                              icon: Icons.handyman,
                              value: verifiedMitra,
                              title: "Mitra Terverifikasi",
                              subtitle: verifiedSubtitle,
                            )
                                .animate(delay: 550.ms)
                                .fadeIn(duration: 500.ms)
                                .slideY(begin: .25),

                            StatCounter(
                              icon: Icons.star,
                              value: ratingValue,
                              title: "Rating Rata-rata",
                              subtitle: ratingSubtitle,
                            )
                                .animate(delay: 700.ms)
                                .fadeIn(duration: 500.ms)
                                .slideY(begin: .25),

                            const StatCounter(
                              icon: Icons.card_giftcard,
                              value: "Rp 0",
                              title: "Biaya Pasang Iklan",
                              subtitle: "posting gratis selamanya",
                              showDivider: false,
                            )
                                .animate(delay: 850.ms)
                                .fadeIn(duration: 500.ms)
                                .slideY(begin: .25),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}