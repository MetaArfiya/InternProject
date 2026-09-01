import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CategoryCard extends StatefulWidget {
  final String icon;
  final String title;
  final String total;
  final Color bgColor;
  final Color borderColor;

  const CategoryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.total,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 250;

        return MouseRegion(
          onEnter: (_) => setState(() => isHover = true),
          onExit: (_) => setState(() => isHover = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,

            transform: Matrix4.identity()
              ..translate(0.0, isHover ? -8.0 : 0.0),

            padding: EdgeInsets.all(
              isSmall ? 14 : 22,
            ),

            decoration: BoxDecoration(
              color: widget.bgColor,
              borderRadius: BorderRadius.circular(18),

              border: Border.all(
                color: widget.borderColor,
                width: 1.5,
              ),

              boxShadow: isHover
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(.10),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : [],
            ),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.icon,
                  style: TextStyle(
                    fontSize: isSmall ? 26 : 34,
                  ),
                ),

                SizedBox(
                  height: isSmall ? 12 : 20,
                ),

                Text(
                  widget.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isSmall ? 16 : 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff08162F),
                  ),
                ),

                SizedBox(
                  height: isSmall ? 5 : 8,
                ),

                Text(
                  widget.total,
                  style: TextStyle(
                    fontSize: isSmall ? 12 : 14,
                    color: const Color(0xffF97316),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(
              begin: const Offset(.9, .9),
            );
      },
    );
  }
}