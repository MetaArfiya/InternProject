import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'testimonial_card.dart';

class TestimonialSection extends StatelessWidget {
  const TestimonialSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 700;
        final isTablet = width >= 700 && width < 1100;

        final columnCount = isMobile
            ? 1
            : isTablet
                ? 2
                : 3;

        return Container(
          width: double.infinity,
          color: const Color(0xffF8FAFC),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 90,
            vertical: isMobile ? 50 : 100,
          ),
          child: Column(
            children: [
              const Text(
                "ULASAN PELANGGAN",
                style: TextStyle(
                  color: Color(0xffF97316),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ).animate().fadeIn().slideY(begin: .3),

              const SizedBox(height: 18),

              Text(
                "Mereka Sudah Merasakan",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 32 : 46,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xff08162F),
                ),
              ).animate(delay: 150.ms).fadeIn().slideY(begin: .2),

              Text(
                "Bedanya SayaBantu",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 32 : 46,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xffF97316),
                ),
              ).animate(delay: 250.ms).fadeIn().slideY(begin: .2),

              SizedBox(height: isMobile ? 40 : 70),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: columnCount,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: isMobile ? .85 : .75,
                children: [
                  const TestimonialCard(
                    category: "🔧 Service AC Bocor",
                    review:
                        "\"Baru posting 10 menit, sudah ada 4 mitra yang nawar! Saya tinggal pilih yang poinnya paling tinggi. Kerjanya rapi dan profesional.\"",
                    name: "Anisa Rahmawati",
                    job: "Ibu Rumah Tangga, Cilandak",
                    avatar: "AR",
                  ).animate().fadeIn().slideY(begin: .3),

                  const TestimonialCard(
                    category: "🪜 Cat Ulang 8 Kamar Kos",
                    review:
                        "\"Sebagai pemilik kos saya sering butuh tukang mendadak. Sekarang tinggal posting di SayaBantu dan tunggu penawaran masuk.\"",
                    name: "Rendra Kusuma",
                    job: "Pemilik Kos, Mampang",
                    avatar: "RK",
                    avatarColor: Color(0xff64748B),
                  ).animate(delay: 200.ms).fadeIn().slideY(begin: .3),

                  const TestimonialCard(
                    category: "💡 Instalasi Wallpaper & Lampu",
                    review:
                        "\"Yang saya suka adalah transparansinya. Semua penawaran langsung terlihat sehingga saya bebas membandingkan harga.\"",
                    name: "Sari Dewi Putri",
                    job: "Desainer Interior, Jakarta Selatan",
                    avatar: "SD",
                  ).animate(delay: 400.ms).fadeIn().slideY(begin: .3),
                ],
              ),

              SizedBox(height: isMobile ? 35 : 55),

              Wrap(
                alignment: WrapAlignment.center,
                spacing: 20,
                runSpacing: 15,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      5,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 4),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: [
                            const Color(0xffF97316),
                            const Color(0xff0EA5E9),
                            const Color(0xff8B5CF6),
                            const Color(0xff10B981),
                            const Color(0xffF59E0B),
                          ][index],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          ["AN", "BS", "RK", "EP", "SD"][index],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Text(
                    "8.200+ ulasan dari pelanggan nyata",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xff334155),
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        color: Color(0xffFBBF24),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "4.9 / 5 rata-rata kepuasan",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff334155),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const Text(
                    "98% masalah terselesaikan",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xff334155),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
                  .animate(delay: 700.ms)
                  .fadeIn()
                  .scale(begin: const Offset(.95, .95)),
            ],
          ),
        );
      },
    );
  }
}