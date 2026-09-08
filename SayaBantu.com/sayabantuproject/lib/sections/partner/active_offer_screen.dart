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

  // ============================================================
  // AMBIL DATA PENAWARAN AKTIF
  // ============================================================

  Future<void> _fetchMyOffers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiService.get('/mitra/my-offers');

      debugPrint(
        '🔎 MY OFFERS STATUS CODE: ${response.statusCode}',
      );

      debugPrint(
        '🔎 MY OFFERS BODY: ${response.body}',
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        List<dynamic> loadedOffersJson = [];

        // --------------------------------------------------------
        // Jika response:
        // {
        //   "data": [...]
        // }
        // --------------------------------------------------------

        if (decodedData is Map<String, dynamic>) {
          final target =
              decodedData['data'] ??
              decodedData['offers'] ??
              [];

          if (target is List) {
            loadedOffersJson = target;
          }
        }

        // --------------------------------------------------------
        // Jika response langsung berupa:
        // [...]
        // --------------------------------------------------------

        else if (decodedData is List) {
          loadedOffersJson = decodedData;
        }

        final loadedOffers = <ActiveOfferModel>[];

        for (final item in loadedOffersJson) {
          try {
            if (item is Map<String, dynamic>) {
              loadedOffers.add(
                ActiveOfferModel.fromJson(item),
              );
            }
          } catch (e) {
            debugPrint(
              '⚠️ Gagal parsing offer: $e',
            );
          }
        }

        if (!mounted) return;

        setState(() {
          _offers = loadedOffers;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          _errorMessage =
              'Gagal memuat penawaran.\n'
              'Status: ${response.statusCode}';

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(
        '❌ ERROR FETCH OFFERS: $e',
      );

      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Terjadi kesalahan koneksi.\n$e';

        _isLoading = false;
      });
    }
  }

  // ============================================================
  // DIPANGGIL SETELAH MITRA BERHASIL MENGIRIM BUKTI
  // ============================================================

  Future<void> _onCompletionProofSubmitted() async {
    debugPrint(
      '✅ Bukti pekerjaan berhasil dikirim.',
    );

    // Ambil ulang data dari backend.
    //
    // Ini penting supaya status:
    //
    // Diterima Pelanggan
    //          ↓
    // Menunggu Konfirmasi
    //
    // benar-benar mengikuti database.

    await _fetchMyOffers();
  }

  // ============================================================
  // REFRESH MANUAL
  // ============================================================

  Future<void> _refreshOffers() async {
    await _fetchMyOffers();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        final isTablet =
            constraints.maxWidth >= 600 &&
            constraints.maxWidth < 1000;

        final padding = isMobile
            ? 16.0
            : isTablet
                ? 24.0
                : 35.0;

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Theme.of(context)
              .scaffoldBackgroundColor,
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // HEADER
              // ==================================================

              Text(
                'Penawaran Aktif Saya',
                style: TextStyle(
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Seluruh penawaran yang sedang menunggu '
                'respon atau telah diproses.',
                style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.6),
                  fontSize: isMobile ? 14 : 16,
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // CONTENT
              // ==================================================

              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    // ----------------------------------------------------------
    // LOADING
    // ----------------------------------------------------------

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // ----------------------------------------------------------
    // ERROR
    // ----------------------------------------------------------

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 60,
                color: Colors.grey,
              ),

              const SizedBox(height: 16),

              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _fetchMyOffers,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // TIDAK ADA PENAWARAN
    // ----------------------------------------------------------

    if (_offers.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshOffers,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
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
                    'Belum ada penawaran aktif.',
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

    // ----------------------------------------------------------
    // LIST PENAWARAN
    // ----------------------------------------------------------

    return RefreshIndicator(
      onRefresh: _refreshOffers,
      child: ListView.separated(
        physics:
            const AlwaysScrollableScrollPhysics(),

        itemCount: _offers.length,

        separatorBuilder: (_, __) =>
            const SizedBox(height: 12),

        itemBuilder: (context, index) {
          final offer = _offers[index];

          return ActiveOfferCard(
            offer: offer,
          );
        },
      ),
    );
  }
}