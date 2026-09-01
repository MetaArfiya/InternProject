import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StepCard extends StatelessWidget {
  final String number;
  final Color numberColor;
  final IconData icon;
  final String title;
  final String description;
  final List<String> points;

  const StepCard({
    super.key,
    required this.number,
    required this.numberColor,
    required this.icon,
    required this.title,
    required this.description,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 260;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              constraints: BoxConstraints(
                minHeight: isSmall ? 320 : 350,
              ),
              padding: EdgeInsets.fromLTRB(
                isSmall ? 18 : 24,
                65,
                isSmall ? 18 : 24,
                isSmall ? 20 : 25,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xffE6EDF5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.05),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    color: numberColor,
                    size: isSmall ? 28 : 32,
                  ),

                  const SizedBox(height: 20),

                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isSmall ? 17 : 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xff08162F),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    description,
                    style: TextStyle(
                      color: const Color(0xff64748B),
                      height: 1.6,
                      fontSize: isSmall ? 14 : 15,
                    ),
                  ),

                  const SizedBox(height: 20),

                  ...points.map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 18,
                            color: numberColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              point,
                              style: TextStyle(
                                color: const Color(0xff334155),
                                fontSize: isSmall ? 13 : 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: .2)
                .scale(begin: const Offset(.97, .97)),

            Positioned(
              top: -24,
              left: 28,
              child: Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: numberColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: numberColor.withOpacity(.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              )
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.elasticOut),
            ),
          ],
        );
      },
    );
  }
}