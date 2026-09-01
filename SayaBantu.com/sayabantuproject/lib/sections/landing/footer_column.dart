import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FooterColumn extends StatelessWidget {
  final String title;
  final List<String> items;

  const FooterColumn({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),

          const SizedBox(height: 22),

          ...items.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                entry.value,
                softWrap: true,
                style: TextStyle(
                  color: Colors.white.withOpacity(.7),
                  fontSize: 15,
                  height: 1.5,
                ),
              )
                  .animate(delay: (entry.key * 100).ms)
                  .fadeIn()
                  .slideX(begin: -.15),
            ),
          ),
        ],
      ),
    );
  }
}