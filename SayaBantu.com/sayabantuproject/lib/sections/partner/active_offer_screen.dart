import 'dart:convert';
import 'package:flutter/material.dart';

import '../../widgets/active_offer_card.dart';
import '../../services/api_service.dart';
import '../../models/active_offer_model.dart';

class ActiveOfferScreen extends StatefulWidget {
  const ActiveOfferScreen({super.key});

  @override
  State<ActiveOfferScreen> createState() => _ActiveOfferScreenState();
}

class _ActiveOfferScreenState extends State<ActiveOfferScreen> {
  List<ActiveOfferModel> _offers = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchMyOffers();
  }

  Future<void> _fetchMyOffers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiService.get('/mitra/my-offers');

      debugPrint("🔎 MY OFFERS STATUS CODE: ${response.statusCode}");
      debugPrint("🔎 MY OFFERS BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        List<dynamic> loadedOffersJson = [];

        if (decodedData is Map<String, dynamic>) {
          var target = decodedData['data'] ?? decodedData['offers'] ?? [];
          if (target is List) {
            loadedOffersJson = target;
          }
        } else if (decodedData is List) {
          loadedOffersJson = decodedData;
        }

        if (mounted) {
          setState(() {
            _offers = loadedOffersJson
                .map((json) => ActiveOfferModel.fromJson(json))
                .toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Gagal memuat penawaran (Status: ${response.statusCode})';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("❌ ERROR FETCH OFFERS: $e");
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan koneksi: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1000;

        final padding = isMobile
            ? 16.0
            : isTablet
                ? 24.0
                : 35.0;

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian Header (Tombol refresh sudah dihapus)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Penawaran Aktif Saya",
                    style: TextStyle(
                      fontSize: isMobile ? 24 : 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Seluruh penawaran yang sedang menunggu respon atau telah diproses.",
                    style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.6),
                      fontSize: isMobile ? 14 : 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Konten Utama (Loading, Error, atau List Data)
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _fetchMyOffers,
              icon: const Icon(Icons.refresh),
              label: const Text("Coba Lagi"),
            ),
          ],
        ),
      );
    }

    if (_offers.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchMyOffers,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 60,
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Belum ada penawaran aktif.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMyOffers,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _offers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final offer = _offers[index];
          return ActiveOfferCard(offer: offer);
        },
      ),
    );
  }
}