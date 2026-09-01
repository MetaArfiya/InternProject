import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'hero_left.dart';
import 'hero_right.dart';

class HeroSection extends StatelessWidget {
  final VoidCallback onCariJasa;
  final VoidCallback onJadiMitra;
  final Function(String) onSearch;

  const HeroSection({
    super.key,
    required this.onCariJasa,
    required this.onJadiMitra,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final isMobile = width < 768;
    final isTablet = width >= 768 && width < 1100;
    final isLaptop = width >= 1100 && width < 1440;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: isMobile
            ? 700
            : MediaQuery.of(context).size.height,
      ),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            "assets/images/herosection.png",
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        color: Colors.black.withOpacity(.58),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1440,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile
                    ? 20
                    : isTablet
                        ? 24
                        : isLaptop
                            ? 40
                            : 60,
                vertical: isMobile ? 60 : 40,
              ),
              child: isMobile
                    ? Column(
                        children: [

                          HeroLeft(
                            onCariJasa: onCariJasa,
                            onJadiMitra: onJadiMitra,
                            onSearch: onSearch,
                          )
                              .animate()
                              .fade(
                                duration: 700.ms,
                              )
                              .slideY(
                                begin: 0.3,
                                end: 0,
                                curve: Curves.easeOut,
                                duration: 700.ms,
                              ),

                          const SizedBox(height: 40),

                          const HeroRight()
                              .animate()
                              .fade(
                                delay: 300.ms,
                                duration: 700.ms,
                              )
                              .slideY(
                                begin: 0.3,
                                end: 0,
                                curve: Curves.easeOut,
                                duration: 700.ms,
                              ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [

                          Expanded(
                            flex: 6,
                            child: HeroLeft(
                              onCariJasa: onCariJasa,
                              onJadiMitra: onJadiMitra,
                              onSearch: onSearch,
                            )
                                .animate()
                                .fade(
                                  duration: 800.ms,
                                )
                                .slideX(
                                  begin: -0.25,
                                  end: 0,
                                  curve: Curves.easeOutCubic,
                                  duration: 800.ms,
                                ),
                          ),

                          SizedBox(
                            width: width > 1700
                                ? 80
                                : width > 1400
                                    ? 60
                                    : width > 1100
                                        ? 40
                                        : 20,
                          ),

                          Expanded(
                            flex: 5,
                            child: const HeroRight()
                                .animate()
                                .fade(
                                  delay: 250.ms,
                                  duration: 800.ms,
                                )
                                .slideX(
                                  begin: 0.25,
                                  end: 0,
                                  curve: Curves.easeOutCubic,
                                  duration: 800.ms,
                                )
                                .scale(
                                  begin: const Offset(0.95, 0.95),
                                  end: const Offset(1, 1),
                                  duration: 800.ms,
                                ),
                          ),
                        ],
                      ),
            ),
          ),
        ),
      ),
    );
  }
}