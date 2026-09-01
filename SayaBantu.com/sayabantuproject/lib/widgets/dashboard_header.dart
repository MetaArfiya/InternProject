import 'package:flutter/material.dart';

import '../models/job_model.dart';
import '../screens/Screens_Customer/posting_jasa_dialog.dart';

class DashboardHeader extends StatelessWidget {
  final Function(JobModel)? onAddJob;

  const DashboardHeader({
    super.key,
    this.onAddJob,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pekerjaan Saya",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff1E293B),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Pantau status semua jasa yang kamu posting",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final JobModel? job =
                            await showDialog<JobModel>(
                          context: context,
                          builder: (_) =>
                              const PostingJasaDialog(),
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
                          vertical: 16,
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text(
                        "Posting Jasa Baru",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pekerjaan Saya",
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff1E293B),
                          ),
                        ),

                        SizedBox(height: 8),

                        Text(
                          "Pantau status semua jasa yang kamu posting",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  ElevatedButton.icon(
                    onPressed: () async {
                      final JobModel? job =
                          await showDialog<JobModel>(
                        context: context,
                        builder: (_) =>
                            const PostingJasaDialog(),
                      );

                      if (job != null) {
                        onAddJob?.call(job);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xffF97316),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 18,
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      "Posting Jasa Baru",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
      },
    );
  }
}