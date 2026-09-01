import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StatCounter extends StatefulWidget {
  final IconData icon;
  final String value;
  final String title;
  final String subtitle;
  final bool showDivider;

  const StatCounter({
    super.key,
    required this.icon,
    required this.value,
    required this.title,
    required this.subtitle,
    this.showDivider = true,
  });

  @override
  State<StatCounter> createState() => _StatCounterState();
}

class _StatCounterState extends State<StatCounter> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.04 : 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 20,
          ),
          decoration: BoxDecoration(
            color: _hover
                ? Colors.white.withOpacity(.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 250;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.icon,
                          color: Colors.amber.shade300,
                          size: isSmall ? 30 : 38,
                        )
                            .animate()
                            .scale(
                              duration: 500.ms,
                              curve: Curves.elasticOut,
                            ),

                        SizedBox(
                          height: isSmall ? 12 : 20,
                        ),

                        Text(
                          widget.value,
                          style: TextStyle(
                            fontSize: isSmall ? 30 : 38,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        )
                            .animate(delay: 100.ms)
                            .fadeIn()
                            .slideY(begin: .2),

                        const SizedBox(height: 10),

                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmall ? 15 : 18,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                            .animate(delay: 200.ms)
                            .fadeIn(),

                        const SizedBox(height: 6),

                        Text(
                          widget.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(.85),
                            fontSize: isSmall ? 13 : 15,
                            height: 1.6,
                          ),
                        )
                            .animate(delay: 300.ms)
                            .fadeIn(),
                      ],
                    ),
                  ),

                  if (widget.showDivider && !isSmall)
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 25,
                      ),
                      width: 1,
                      height: 150,
                      color: Colors.white.withOpacity(.18),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}