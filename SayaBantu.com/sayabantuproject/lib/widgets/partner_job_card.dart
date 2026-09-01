import 'package:flutter/material.dart';
import '../models/partner_job_model.dart'; // Import PartnerJobModel

class PartnerJobCard extends StatelessWidget {
  final PartnerJobModel job; // Ganti dari JobModel menjadi PartnerJobModel
  final VoidCallback onTakeOffer;

  const PartnerJobCard({
    super.key,
    required this.job,
    required this.onTakeOffer,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              job.category,
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              job.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  job.price,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                ElevatedButton(
                  onPressed: onTakeOffer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffF97316),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Ambil & Nego"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}