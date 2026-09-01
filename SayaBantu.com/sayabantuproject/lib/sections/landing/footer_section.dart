import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'footer_column.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 700;
        final isTablet = width >= 700 && width < 1100;

        return Container(
          width: double.infinity,
          color: const Color(0xff0F172A),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile
                ? 20
                : isTablet
                    ? 40
                    : 90,
            vertical: isMobile ? 50 : 70,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
              spacing: isMobile ? 30 : 60,
              runSpacing: 40,
              children: [
                SizedBox(
                  width: isMobile
                      ? width - 40
                      : isTablet
                          ? 320
                          : 360,
                  child: _footerBrand(context)
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideX(begin: -.2),
                ),

                const SizedBox(
                  width: 170,
                  child: FooterColumn(
                    title: "Layanan",
                    items: [
                      "Service AC",
                      "Plumbing",
                      "Listrik",
                      "Cleaning Service",
                      "Renovasi Rumah",
                    ],
                  ),
                )
                    .animate(delay: 150.ms)
                    .fadeIn()
                    .slideY(begin: .2),

                const SizedBox(
                  width: 170,
                  child: FooterColumn(
                    title: "Perusahaan",
                    items: [
                      "Tentang Kami",
                      "Karier",
                      "Blog",
                      "Kontak",
                    ],
                  ),
                )
                    .animate(delay: 250.ms)
                    .fadeIn()
                    .slideY(begin: .2),

                const SizedBox(
                  width: 190,
                  child: FooterColumn(
                    title: "Dukungan",
                    items: [
                      "FAQ",
                      "Pusat Bantuan",
                      "Kebijakan Privasi",
                      "Syarat & Ketentuan",
                    ],
                  ),
                )
                    .animate(delay: 350.ms)
                    .fadeIn()
                    .slideY(begin: .2),
              ],
            ),

              const SizedBox(height: 50),

              Divider(
                color: Colors.white.withOpacity(.08),
              ).animate(delay: 450.ms).fadeIn(),

              const SizedBox(height: 20),

              Center(
                child: Text(
                  "© 2026 SayaBantu. All Rights Reserved.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.55),
                  ),
                ),
              ).animate(delay: 550.ms).fadeIn(),
            ],
          ),
        );
      },
    );
  }

  Widget _footerBrand(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xffF97316),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.home_repair_service,
                color: Colors.white,
              ),
            ),

            const SizedBox(width: 12),

            const Flexible(
              child: Text(
                "SayaBantu",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Text(
            "Platform marketplace jasa rumah tangga yang mempertemukan pelanggan dengan mitra terpercaya secara cepat, transparan, dan aman.",
            style: TextStyle(
              color: Colors.white.withOpacity(.7),
              fontSize: 15,
              height: 1.8,
            ),
          ),
        ),

        const SizedBox(height: 28),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _social(Icons.facebook),
            _social(Icons.camera_alt),
            _social(Icons.chat),
            _social(Icons.play_arrow),
          ],
        ),
      ],
    );
  }

  Widget _social(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: Colors.white,
        size: 20,
      ),
    ).animate().fadeIn().scale(begin: const Offset(.8, .8));
  }
}