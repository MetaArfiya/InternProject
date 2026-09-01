import 'package:flutter/material.dart';

import '../models/job_model.dart';
import '../models/offer_model.dart';

class OfferCard extends StatelessWidget {
  final JobModel job;
  final OfferModel offer;
  final Function(OfferModel) onReject;
  final Function(OfferModel) onAccept;
  final Function(OfferModel) onOpenProfile;

  const OfferCard({
    super.key,
    required this.job,
    required this.offer,
    required this.onReject,
    required this.onAccept,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xffE5E7EB),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: Color(0xffFFF3E8),
            child: Icon(
              Icons.person,
              color: Color(0xffF97316),
              size: 38,
            ),
          ),

          const SizedBox(width: 20),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      offer.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(width: 10),

                    if (offer.verified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              color: Colors.green,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "Terverifikasi",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 18,
                    ),

                    const SizedBox(width: 20),

                    const Icon(
                      Icons.work_outline,
                      color: Colors.grey,
                      size: 18,
                    ),

                    const SizedBox(width: 5),

                    Text("${offer.jobsCompleted} Job"),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  offer.price,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xffF97316),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Konfirmasi"),
                      content: Text(
                        "Apakah Anda yakin ingin memilih ${offer.name} sebagai mitra?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Batal"),
                        ),

                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);

                            onAccept(offer);
                          },
                          child: const Text("Ya"),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 45),
                ),
                child: const Text("Terima"),
              ),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Tolak Penawaran"),
                      content: Text(
                        "Yakin ingin menolak penawaran dari ${offer.name}?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Batal"),
                        ),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            onReject(offer);
                          },
                          child: const Text("Tolak"),
                        ),
                      ],
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(120, 45),
                ),
                child: const Text("Tolak"),
              ),

              const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    onOpenProfile(offer);
                  },
                  child: const Text("Lihat Profil"),
                ),
            ],
          ),
        ],
      ),
    );
  }
}