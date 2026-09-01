import 'package:flutter/material.dart';

class PartnerProfileSection extends StatelessWidget {
  const PartnerProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final isMobile = width < 600;
        final isTablet = width >= 600 && width < 1000;

        final horizontalPadding = isMobile
            ? 16.0
            : isTablet
                ? 24.0
                : 30.0;

        final fontSize = isMobile
            ? 24.0
            : isTablet
                ? 28.0
                : 32.0;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 30,
          ),
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1200,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: isMobile ? 55 : 70,
                    color: const Color(0xffF97316),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Profil Mitra",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Kelola informasi profil Anda sebagai mitra.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}