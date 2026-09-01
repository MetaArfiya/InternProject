import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TestimonialCard extends StatelessWidget {
  final String category;
  final String review;
  final String name;
  final String job;
  final String avatar;
  final Color avatarColor;
  final bool useImage;

  const TestimonialCard({
    super.key,
    required this.category,
    required this.review,
    required this.name,
    required this.job,
    required this.avatar,
    this.avatarColor = const Color(0xffF97316),
    this.useImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 350;

        return Container(
          padding: EdgeInsets.all(isSmall ? 18 : 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xffE7EEF5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.star, color: Color(0xffFBBF24), size: 18),
                  Icon(Icons.star, color: Color(0xffFBBF24), size: 18),
                  Icon(Icons.star, color: Color(0xffFBBF24), size: 18),
                  Icon(Icons.star, color: Color(0xffFBBF24), size: 18),
                  Icon(Icons.star, color: Color(0xffFBBF24), size: 18),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                review,
                style: TextStyle(
                  color: const Color(0xff475569),
                  fontSize: isSmall ? 13 : 15,
                  height: 1.8,
                ),
              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: const Color(0xffF97316),
                    fontWeight: FontWeight.w600,
                    fontSize: isSmall ? 11 : 13,
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 18),

              Row(
                children: [
                  useImage
                      ? CircleAvatar(
                          radius: isSmall ? 18 : 22,
                          backgroundImage: AssetImage(avatar),
                        )
                      : CircleAvatar(
                          radius: isSmall ? 18 : 22,
                          backgroundColor: avatarColor,
                          child: Text(
                            avatar,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                  SizedBox(width: isSmall ? 10 : 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmall ? 14 : 16,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          job,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xff94A3B8),
                            fontSize: isSmall ? 11 : 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: .25)
            .scale(begin: const Offset(.97, .97));
      },
    );
  }
}