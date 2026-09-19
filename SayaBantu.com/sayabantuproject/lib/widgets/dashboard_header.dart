import 'package:flutter/material.dart';

import '../models/job_model.dart';
import '../screens/Screens_Customer/posting_jasa_dialog.dart';

class DashboardHeader extends StatelessWidget {
  final Function(JobModel)? onAddJob;

  const DashboardHeader({
    super.key,
    this.onAddJob,
  });

  // ============================================================
  // STANDARD UI
  // ============================================================

  static const double _buttonFontSize = 13;
  static const double _buttonRadius = 12;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        // ========================================================
        // MOBILE
        // ========================================================

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pekerjaan Saya',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 6),

              Text(
                'Pantau status semua jasa yang kamu posting',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: _buildPostButton(context),
              ),
            ],
          );
        }

        // ========================================================
        // DESKTOP / TABLET
        // ========================================================

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pekerjaan Saya',
                    style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Pantau status semua jasa yang kamu posting',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            _buildPostButton(context),
          ],
        );
      },
    );
  }

  // ============================================================
  // BUTTON POSTING JASA
  // ============================================================

  Widget _buildPostButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        final JobModel? job = await showDialog<JobModel>(
          context: context,
          builder: (_) => const PostingJasaDialog(),
        );

        if (job != null) {
          onAddJob?.call(job);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xffF97316),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonRadius),
        ),
      ),
      icon: const Icon(
        Icons.add,
        size: 18,
      ),
      label: const Text(
        'Posting Jasa Baru',
        style: TextStyle(
          fontSize: _buttonFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}