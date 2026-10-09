import 'package:flutter/material.dart';

import '../models/job_model.dart';
import '../screens/Screens_Customer/posting_jasa_dialog.dart';
import '../theme/app_colors.dart';

class DashboardHeader extends StatelessWidget {
  final Function(JobModel)? onAddJob;

  const DashboardHeader({
    super.key,
    this.onAddJob,
  });

  static const double _buttonFontSize = 13;
  static const double _buttonRadius = 12;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pekerjaan Saya',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pantau status semua jasa yang kamu posting',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.grey500,
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

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pekerjaan Saya',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey900,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Pantau status semua jasa yang kamu posting',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.grey500,
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
        backgroundColor: AppColors.primaryTeal, // ← dari orange
        foregroundColor: AppColors.white,
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