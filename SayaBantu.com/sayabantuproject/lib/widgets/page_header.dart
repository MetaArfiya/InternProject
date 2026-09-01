import 'package:flutter/material.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xff1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}