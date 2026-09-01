import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'category_card.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final bool isMobile = width < 600;
        final bool isTablet = width >= 600 && width < 1100;

        final double horizontalPadding = isMobile
            ? 20
            : isTablet
                ? 50
                : 120;

        final double titleSize = isMobile
            ? 32
            : isTablet
                ? 38
                : 46;

        final int columnCount = isMobile
            ? 1
            : isTablet
                ? 2
                : 4;

        final double childRatio = isMobile
            ? 1.8
            : isTablet
                ? 1.45
                : 1.15;

        final categories = const [
          CategoryCard(
            icon: "❄️",
            title: "AC & Elektronik",
            total: "284 mitra aktif",
            bgColor: Color(0xffEDF8FF),
            borderColor: Color(0xffD7ECFF),
          ),
          CategoryCard(
            icon: "🔌",
            title: "Plumbing",
            total: "198 mitra aktif",
            bgColor: Color(0xffF6F0FF),
            borderColor: Color(0xffE6D9FF),
          ),
          CategoryCard(
            icon: "💡",
            title: "Listrik",
            total: "321 mitra aktif",
            bgColor: Color(0xffFFF8E7),
            borderColor: Color(0xffFFE5A6),
          ),
          CategoryCard(
            icon: "🪣",
            title: "Cat & Tembok",
            total: "156 mitra aktif",
            bgColor: Color(0xffFFF5EC),
            borderColor: Color(0xffFFDDBD),
          ),
          CategoryCard(
            icon: "🔨",
            title: "Pertukangan",
            total: "247 mitra aktif",
            bgColor: Color(0xffF0FFF4),
            borderColor: Color(0xffCFEFD7),
          ),
          CategoryCard(
            icon: "🧹",
            title: "Kebersihan",
            total: "189 mitra aktif",
            bgColor: Color(0xffFFF0F6),
            borderColor: Color(0xffFFD6E7),
          ),
          CategoryCard(
            icon: "🌿",
            title: "Taman & Outdoor",
            total: "93 mitra aktif",
            bgColor: Color(0xffF0FFF7),
            borderColor: Color(0xffCFEFDB),
          ),
          CategoryCard(
            icon: "📦",
            title: "Pindahan Barang",
            total: "74 mitra aktif",
            bgColor: Color(0xffF8FAFC),
            borderColor: Color(0xffE2E8F0),
          ),
        ];

        return Container(
          color: Theme.of(context).cardColor,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: isMobile ? 50 : 80,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "KATEGORI JASA",
                style: TextStyle(
                  color: Color(0xffF97316),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  fontSize: 14,
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideX(begin: -.2),

              const SizedBox(height: 10),

              Text(
                "Semua Kebutuhan\nRumahmu Ada Di Sini",
                style: TextStyle(
                  fontSize: titleSize,
                  height: 1.15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff08162F),
                ),
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: .2),

              SizedBox(height: isMobile ? 30 : 50),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnCount,
                  crossAxisSpacing: isMobile ? 12 : 20,
                  mainAxisSpacing: isMobile ? 12 : 20,
                  childAspectRatio: childRatio,
                ),
                itemBuilder: (context, index) {
                  return categories[index]
                      .animate(delay: (100 * index).ms)
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: .25)
                      .scale(
                        begin: const Offset(.9, .9),
                        curve: Curves.easeOut,
                      );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}