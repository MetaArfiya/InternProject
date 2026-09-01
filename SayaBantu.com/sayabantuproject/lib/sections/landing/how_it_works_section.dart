import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'step_card.dart';

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 700;
        final isTablet = width >= 700 && width < 1100;

        final horizontalPadding = isMobile
            ? 20.0
            : isTablet
                ? 50.0
                : 80.0;

        final titleSize = isMobile
            ? 32.0
            : isTablet
                ? 40.0
                : 48.0;

        return Container(
          width: double.infinity,
          color: const Color(0xffF8FAFC),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: isMobile ? 50 : 90,
          ),
          child: Column(
            children: [
              const Text(
                "CARA KERJA",
                style: TextStyle(
                  color: Color(0xffF97316),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ).animate().fadeIn().slideY(begin: .3),

              const SizedBox(height: 15),

              Text(
                "Sesederhana Itu.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xff08162F),
                ),
              )
                  .animate(delay: 150.ms)
                  .fadeIn()
                  .slideY(begin: .2),

              Text(
                "Tiga Langkah Selesai.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xffF97316),
                ),
              )
                  .animate(delay: 250.ms)
                  .fadeIn()
                  .slideY(begin: .2),

              const SizedBox(height: 20),

              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: const Text(
                  "Tidak ada biaya tersembunyi. Tidak ada perantara. Kamu deal langsung dengan mitra pilihanmu.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xff64748B),
                    height: 1.8,
                    fontSize: 18,
                  ),
                ),
              )
                  .animate(delay: 350.ms)
                  .fadeIn()
                  .slideY(begin: .2),

              SizedBox(height: isMobile ? 40 : 70),

              if (isMobile)
                Column(
                  children: [
                    const StepCard(
                      number: "01",
                      numberColor: Color(0xff1DA1F2),
                      icon: Icons.edit_note,
                      title: "Posting Masalahmu",
                      description:
                          "Ceritakan masalah di rumahmu, upload foto kendala, dan set budget awal yang kamu bayangkan.",
                      points: [
                        "Gratis tanpa biaya posting",
                        "Upload foto untuk deskripsi lebih jelas",
                        "Set budget fleksibel",
                      ],
                    ).animate().fadeIn().slideY(begin: .3),

                    const SizedBox(height: 20),

                    const StepCard(
                      number: "02",
                      numberColor: Color(0xffF97316),
                      icon: Icons.handshake,
                      title: "Nego Langsung dengan Mitra",
                      description:
                          "Mitra-mitra terverifikasi akan langsung mengajukan penawaran harga.",
                      points: [
                        "Mitra diurutkan dari poin tertinggi",
                        "Bandingkan harga transparan",
                        "Chat langsung dengan mitra",
                      ],
                    )
                        .animate(delay: 200.ms)
                        .fadeIn()
                        .slideY(begin: .3),

                    const SizedBox(height: 20),

                    const StepCard(
                      number: "03",
                      numberColor: Color(0xff10B981),
                      icon: Icons.task_alt,
                      title: "Terima & Konfirmasi Selesai",
                      description:
                          "Terima tawaran terbaik dan pantau progres pekerjaan.",
                      points: [
                        "Bayar hanya setelah puas",
                        "Poin reward otomatis",
                        "Beri rating",
                      ],
                    )
                        .animate(delay: 400.ms)
                        .fadeIn()
                        .slideY(begin: .3),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: const StepCard(
                        number: "01",
                        numberColor: Color(0xff1DA1F2),
                        icon: Icons.edit_note,
                        title: "Posting Masalahmu",
                        description:
                            "Ceritakan masalah di rumahmu, upload foto kendala, dan set budget awal.",
                        points: [
                          "Gratis tanpa biaya posting",
                          "Upload foto lebih jelas",
                          "Set budget fleksibel",
                        ],
                      ).animate().fadeIn().slideY(begin: .3),
                    ),
                    const SizedBox(width: 30),
                    Expanded(
                      child: const StepCard(
                        number: "02",
                        numberColor: Color(0xffF97316),
                        icon: Icons.handshake,
                        title: "Nego Langsung dengan Mitra",
                        description:
                            "Mitra terverifikasi akan mengajukan penawaran harga.",
                        points: [
                          "Urutan poin tertinggi",
                          "Bandingkan harga",
                          "Chat langsung",
                        ],
                      )
                          .animate(delay: 200.ms)
                          .fadeIn()
                          .slideY(begin: .3),
                    ),
                    const SizedBox(width: 30),
                    Expanded(
                      child: const StepCard(
                        number: "03",
                        numberColor: Color(0xff10B981),
                        icon: Icons.task_alt,
                        title: "Terima & Konfirmasi Selesai",
                        description:
                            "Terima tawaran terbaik dan selesaikan pekerjaan.",
                        points: [
                          "Bayar setelah puas",
                          "Reward otomatis",
                          "Rating mitra",
                        ],
                      )
                          .animate(delay: 400.ms)
                          .fadeIn()
                          .slideY(begin: .3),
                    ),
                  ],
                ),

              const SizedBox(height: 50),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff0F172A),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _Badge("Kamu Posting", Color(0xff1DA1F2)),
                    Icon(Icons.arrow_forward, color: Colors.white38, size: 18),
                    _Badge("Mitra Nawar", Color(0xffF97316)),
                    Icon(Icons.arrow_forward, color: Colors.white38, size: 18),
                    _Badge("Kamu Pilih", Color(0xffEAB308)),
                    _Badge("Kerja Jalan", Color(0xff8B5CF6)),
                    _Badge("Deal Selesai 🎉", Color(0xff10B981)),
                  ],
                ),
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

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}