import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/responsive.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HeroLeft extends StatefulWidget {
  final VoidCallback onCariJasa;
  final VoidCallback onJadiMitra;
  final Function(String) onSearch;

  const HeroLeft({
    super.key,
    required this.onCariJasa,
    required this.onJadiMitra,
    required this.onSearch,
  });

  @override
  State<HeroLeft> createState() => _HeroLeftState();
}

class _HeroLeftState extends State<HeroLeft> {
  final TextEditingController searchController = TextEditingController();
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
      debugPrint("Fetching hero stats from: $url");

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
          return body;
        }
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching hero stats: $e");
      return null;
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = Responsive.width(context);

    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final isLaptop = Responsive.isLaptop(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2118),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFFFF8A00),
            ),
          ),
          child: const Text(
            "🔥 1.240+ Mitra Terverifikasi Siap Melayani",
            style: TextStyle(
              color: Color(0xFFFFC27A),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .slideX(begin: -.2),

        const SizedBox(height: 28),

        Text(
          "Bantuan\nRumah",
          style: TextStyle(
            color: Colors.white,
            fontSize: Responsive.titleSize(context),
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        )
            .animate(delay: 200.ms)
            .fadeIn(duration: 600.ms)
            .slideY(begin: .3),

        const SizedBox(height: 4),

        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: Responsive.subtitleSize(context),
              fontWeight: FontWeight.w800,
              height: 1,
            ),
            children: const [
              TextSpan(
                text: "Tepat Harga,\n",
                style: TextStyle(
                  color: Color(0xFFFF7A00),
                ),
              ),
              TextSpan(
                text: "Tepat Waktu.",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        )
            .animate(delay: 350.ms)
            .fadeIn(duration: 600.ms)
            .slideX(begin: -.2),

        const SizedBox(height: 24),

        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 520,
          ),
          child: Text(
            "Posting masalah, negosiasi harga langsung dengan mitra terbaik di area kamu. Transparan penuh sehingga kamu tetap memegang kendali.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: isMobile ? 13 : 15,
              height: 1.8,
            ),
          ),
        )
            .animate(delay: 500.ms)
            .fadeIn()
            .slideY(begin: .2),

        const SizedBox(height: 30),

        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 520,
          ),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const SizedBox(width: 15),
                const Icon(
                  Icons.search,
                  color: Colors.grey,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: "Mau jasa apa hari ini?",
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                    onSubmitted: widget.onSearch,
                  ),
                ),
                InkWell(
                  onTap: () {
                    widget.onSearch(
                      searchController.text.trim(),
                    );
                  },
                  child: Container(
                    width: isMobile
                        ? 110
                        : isLaptop
                            ? 125
                            : 140,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF7A00),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        "Cari Mitra",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
            .animate(delay: 700.ms)
            .fadeIn(duration: 700.ms)
            .slideY(begin: .3)
            .scale(
              begin: const Offset(0.95, 0.95),
              curve: Curves.easeOut,
            ),

        const SizedBox(height: 28),

        (isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: widget.onCariJasa,
                      child: const Text("Cari Jasa Sekarang"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: widget.onJadiMitra,
                      child: const Text("Jadi Mitra"),
                    ),
                  ),
                ],
              )
            : Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  ElevatedButton(
                    onPressed: widget.onCariJasa,
                    child: const Text("Cari Jasa Sekarang"),
                  ),
                  OutlinedButton(
                    onPressed: widget.onJadiMitra,
                    child: const Text("Jadi Mitra"),
                  ),
                ],
              ))
            .animate(delay: 900.ms)
            .fadeIn(duration: 600.ms)
            .slideY(begin: .3),

        const SizedBox(height: 28),

        /// PENGAMBILAN DATA STATISTIK MENGGUNAKAN FUTUREBUILDER
        FutureBuilder<Map<String, dynamic>?>(
          future: _statsFuture,
          builder: (context, snapshot) {
            final response = snapshot.data;
            final data = response?['data'];

            // Nilai fallback jika API sedang loading atau gagal
            final ratingVal = data?['rating_value'] ?? "4.9";
            final completedJobs = data?['completed_jobs'] ?? "12rb+";

            return Wrap(
              spacing: isMobile ? 20 : isTablet ? 24 : 36,
              runSpacing: 18,
              children: [
                HeroInfo(
                  icon: "⭐",
                  value: ratingVal,
                  label: "Rating",
                ),
                HeroInfo(
                  icon: "✔",
                  value: completedJobs,
                  label: "Job Selesai",
                ),
                const HeroInfo(
                  icon: "🎁",
                  value: "0%",
                  label: "Biaya Posting",
                ),
              ],
            );
          },
        )
            .animate(delay: 1100.ms)
            .fadeIn()
            .slideY(begin: .2),
      ],
    );
  }
}

class HeroInfo extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const HeroInfo({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$icon $value",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}