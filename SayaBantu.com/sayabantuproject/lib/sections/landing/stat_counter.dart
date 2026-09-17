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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isSmall = constraints.maxWidth < 250;

        return MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: AnimatedScale(
            scale: _hover ? 1.02 : 1,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 10 : 12,
                vertical: isMobile ? 10 : 20,
              ),
              decoration: BoxDecoration(
                color: _hover
                    ? Colors.white.withOpacity(.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: isMobile
                  ? _buildMobileContent(isSmall)
                  : _buildDesktopContent(isSmall),
            ),
          ),
        );
      },
    );
  }

  // =========================
  // MOBILE
  // =========================

  Widget _buildMobileContent(bool isSmall) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          widget.icon,
          color: Colors.amber.shade300,
          size: 32,
        )
            .animate()
            .scale(
              duration: 500.ms,
              curve: Curves.elasticOut,
            ),

        const SizedBox(height: 8),

        Text(
          widget.value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        )
            .animate(delay: 100.ms)
            .fadeIn()
            .slideY(begin: .2),

        const SizedBox(height: 4),

        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        )
            .animate(delay: 200.ms)
            .fadeIn(),

        const SizedBox(height: 3),

        Text(
          widget.subtitle,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withOpacity(.85),
            fontSize: 13,
            height: 1.3,
          ),
        )
            .animate(delay: 300.ms)
            .fadeIn(),
      ],
    );
  }

  // =========================
  // DESKTOP / TABLET
  // =========================

  Widget _buildDesktopContent(bool isSmall) {
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

              const SizedBox(height: 16),

              Text(
                widget.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmall ? 30 : 38,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              )
                  .animate(delay: 100.ms)
                  .fadeIn()
                  .slideY(begin: .2),

              const SizedBox(height: 8),

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

              const SizedBox(height: 5),

              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(.85),
                  fontSize: isSmall ? 13 : 15,
                  height: 1.5,
                ),
              )
                  .animate(delay: 300.ms)
                  .fadeIn(),
            ],
          ),
        ),

        if (widget.showDivider)
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            width: 1,
            height: 130,
            color: Colors.white.withOpacity(.18),
          ),
      ],
    );
  }
}