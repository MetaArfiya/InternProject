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
          padding: EdgeInsets.all(isSmall ? 16 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xffE7EEF5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rating
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    color: Color(0xffFBBF24),
                    size: 17,
                  ),
                  Icon(
                    Icons.star,
                    color: Color(0xffFBBF24),
                    size: 17,
                  ),
                  Icon(
                    Icons.star,
                    color: Color(0xffFBBF24),
                    size: 17,
                  ),
                  Icon(
                    Icons.star,
                    color: Color(0xffFBBF24),
                    size: 17,
                  ),
                  Icon(
                    Icons.star,
                    color: Color(0xffFBBF24),
                    size: 17,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Review
              Text(
                review,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xff475569),
                  fontSize: isSmall ? 12 : 13,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 14),

              // Category
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xffF97316),
                    fontWeight: FontWeight.w600,
                    fontSize: isSmall ? 10 : 11,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const Divider(
                height: 1,
                color: Color(0xffE7EEF5),
              ),

              const SizedBox(height: 12),

              // User
              Row(
                children: [
                  useImage
                      ? CircleAvatar(
                          radius: isSmall ? 17 : 19,
                          backgroundImage: AssetImage(avatar),
                        )
                      : CircleAvatar(
                          radius: isSmall ? 17 : 19,
                          backgroundColor: avatarColor,
                          child: Text(
                            avatar,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isSmall ? 10 : 11,
                            ),
                          ),
                        ),

                  SizedBox(
                    width: isSmall ? 9 : 11,
                  ),

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
                            fontSize: isSmall ? 12 : 13,
                            color: const Color(0xff0F172A),
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          job,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xff94A3B8),
                            fontSize: isSmall ? 10 : 11,
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
            .scale(
              begin: const Offset(.97, .97),
            );
      },
    );
  }
}