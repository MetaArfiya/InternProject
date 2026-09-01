import 'dart:convert';
import 'package:flutter/material.dart';

import '../../models/job_model.dart';
import '../../models/offer_model.dart';
import '../../services/api_service.dart';
import '../../widgets/offer_card.dart';

class OfferScreen extends StatelessWidget {
  final JobModel job;
  final Function(OfferModel) onAccept;
  final VoidCallback onBack;
  final Function(OfferModel) onOpenProfile;
  final Function(OfferModel) onReject;

  const OfferScreen({
    super.key,
    required this.job,
    required this.onAccept,
    required this.onBack,
    required this.onOpenProfile,
    required this.onReject,
  });

  Future<List<OfferModel>> _fetchBids() async {
    final response = await ApiService.get('/jobs/${job.id}');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      List<dynamic> bidsJson = [];

      if (decoded is Map<String, dynamic>) {
        var target = decoded['data']?['bids'] ?? decoded['bids'] ?? decoded['data'];
        if (target is List) {
          bidsJson = target;
        }
      }

      return bidsJson.map((json) => OfferModel.fromJson(json)).toList();
    } else {
      throw Exception("Gagal memuat penawaran (Kode: ${response.statusCode})");
    }
  }

  Future<void> _handleAccept(BuildContext context, OfferModel offer) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiService.post('/jobs/accept-bid/${offer.id}', {});

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Penawaran berhasil diterima!"),
            backgroundColor: Colors.green,
          ),
        );
        onAccept(offer);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal menerima penawaran (Kode: ${response.statusCode})"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Kesalahan jaringan: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Colors.black,
        title: const Text(
          "Penawaran Mitra",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Budget : ${job.price}",
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: FutureBuilder<List<OfferModel>>(
                future: _fetchBids(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Terjadi kesalahan: ${snapshot.error}",
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final bids = snapshot.data ?? [];

                  if (bids.isEmpty) {
                    return const Center(
                      child: Text(
                        "Belum ada mitra yang mengajukan penawaran.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${bids.length} Mitra Mengirim Penawaran",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.separated(
                          itemCount: bids.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 20),
                          itemBuilder: (context, index) {
                            final offer = bids[index];
                            return OfferCard(
                              job: job,
                              offer: offer,
                              onAccept: (selectedOffer) =>
                                  _handleAccept(context, selectedOffer),
                              onOpenProfile: onOpenProfile,
                              onReject: onReject,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}