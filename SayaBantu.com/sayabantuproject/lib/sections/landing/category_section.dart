import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final bool isMobile = width < 600;
        final bool isTablet = width >= 600 && width < 1100;

        // ==========================================================
        // RESPONSIVE
        // ==========================================================

        final double horizontalPadding = isMobile
            ? 20
            : isTablet
                ? 50
                : 120;

        final double verticalPadding = isMobile
            ? 32
            : isTablet
                ? 48
                : 55;

        final double titleSize = isMobile
            ? 28
            : isTablet
                ? 34
                : 42;

        // ==========================================================
        // DATA KATEGORI
        // ==========================================================

        final categories = const [
          _CategoryData(
            icon: "🏠",
            title: "Perbaikan & Perawatan Rumah",
            total: "Layanan rumah",
            bgColor: Color(0xffEDF8FF),
            borderColor: Color(0xffD7ECFF),
          ),
          _CategoryData(
            icon: "🧹",
            title: "Kebersihan",
            total: "Layanan kebersihan",
            bgColor: Color(0xffFFF0F6),
            borderColor: Color(0xffFFD6E7),
          ),
          _CategoryData(
            icon: "🔨",
            title: "Konstruksi & Renovasi",
            total: "Layanan konstruksi",
            bgColor: Color(0xffF0FFF4),
            borderColor: Color(0xffCFEFD7),
          ),
          _CategoryData(
            icon: "🔧",
            title: "Instalasi & Teknisi",
            total: "Layanan teknisi",
            bgColor: Color(0xffFFF8E7),
            borderColor: Color(0xffFFE5A6),
          ),
          _CategoryData(
            icon: "🏠",
            title: "Jasa Rumah Tangga",
            total: "Layanan rumah tangga",
            bgColor: Color(0xffF6F0FF),
            borderColor: Color(0xffE6D9FF),
          ),
          _CategoryData(
            icon: "🛠️",
            title: "Jasa Umum",
            total: "Berbagai layanan",
            bgColor: Color(0xffFFF5EC),
            borderColor: Color(0xffFFDDBD),
          ),
          _CategoryData(
            icon: "➕",
            title: "Lainnya",
            total: "Kategori lainnya",
            bgColor: Color(0xffF8FAFC),
            borderColor: Color(0xffE2E8F0),
          ),
        ];

        // ==========================================================
        // MOBILE
        // ==========================================================

        Widget buildMobileCategories() {
          return SizedBox(
            height: 155,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              padding: EdgeInsets.zero,
              itemCount: categories.length,
              separatorBuilder: (_, __) {
                return const SizedBox(width: 12);
              },
              itemBuilder: (context, index) {
                final category = categories[index];

                return SizedBox(
                  width: 160,
                  height: 150,
                  child: _CategoryCard(
                    data: category,
                  )
                      .animate(
                        delay: (70 * index).ms,
                      )
                      .fadeIn(
                        duration: 400.ms,
                      )
                      .slideX(
                        begin: .12,
                      ),
                );
              },
            ),
          );
        }

        // ==========================================================
        // TABLET + DESKTOP
        // ==========================================================

        Widget buildGridCategories() {
          final int columnCount = isTablet ? 2 : 4;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,

              // Membuat kartu lebih pendek
              childAspectRatio: isTablet ? 2.15 : 2.25,
            ),
            itemBuilder: (context, index) {
              return _CategoryCard(
                data: categories[index],
              )
                  .animate(
                    delay: (70 * index).ms,
                  )
                  .fadeIn(
                    duration: 400.ms,
                  )
                  .slideY(
                    begin: .12,
                  );
            },
          );
        }

        // ==========================================================
        // SECTION
        // ==========================================================

        return Container(
          color: Theme.of(context).cardColor,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ======================================================
              // LABEL
              // ======================================================

              const Text(
                "KATEGORI JASA",
                style: TextStyle(
                  color: Color(0xffF97316),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  fontSize: 13,
                ),
              )
                  .animate()
                  .fadeIn(
                    duration: 400.ms,
                  )
                  .slideX(
                    begin: -.12,
                  ),

              const SizedBox(height: 7),

              // ======================================================
              // TITLE
              // ======================================================

              Text(
                "Semua Kebutuhan\nRumahmu Ada Di Sini",
                style: TextStyle(
                  fontSize: titleSize,
                  height: 1.12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff08162F),
                ),
              )
                  .animate(
                    delay: 120.ms,
                  )
                  .fadeIn(
                    duration: 450.ms,
                  )
                  .slideY(
                    begin: .1,
                  ),

              // ======================================================
              // JARAK
              // ======================================================

              SizedBox(
                height: isMobile ? 20 : 28,
              ),

              // ======================================================
              // CATEGORY
              // ======================================================

              if (isMobile)
                buildMobileCategories()
              else
                buildGridCategories(),
            ],
          ),
        );
      },
    );
  }
}

// ================================================================
// DATA CATEGORY
// ================================================================

class _CategoryData {
  final String icon;
  final String title;
  final String total;
  final Color bgColor;
  final Color borderColor;

  const _CategoryData({
    required this.icon,
    required this.title,
    required this.total,
    required this.bgColor,
    required this.borderColor,
  });
}

// ================================================================
// CATEGORY CARD
// ================================================================

class _CategoryCard extends StatefulWidget {
  final _CategoryData data;

  const _CategoryCard({
    required this.data,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: data.bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: data.borderColor,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  _isPressed ? 0.02 : 0.08,
                ),
                blurRadius: _isPressed ? 4 : 12,
                offset: _isPressed
                    ? const Offset(0, 2)
                    : const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ======================================================
              // ICON
              // ======================================================

              Text(
                data.icon,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  height: 1,
                ),
              ),

              const SizedBox(height: 10),

              // ======================================================
              // TITLE
              // ======================================================

              Flexible(
                child: Text(
                  data.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff0F172A),
                  ),
                ),
              ),

              const SizedBox(height: 5),

              // ======================================================
              // SUBTITLE
              // ======================================================

              Text(
                data.total,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                  color: Color(0xffF97316),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}