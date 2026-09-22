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
  // FETCH DATA
  // ============================================================

  Future<void> _fetchMyOffers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiService.get(
        '/mitra/my-offers',
      );

      debugPrint(
        '🔎 MY OFFERS STATUS CODE: ${response.statusCode}',
      );

      debugPrint(
        '🔎 MY OFFERS BODY: ${response.body}',
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(
          response.body,
        );

        List<dynamic> loadedOffersJson = [];

        if (decodedData is Map<String, dynamic>) {
          final target =
              decodedData['data'] ??
              decodedData['offers'] ??
              [];

          if (target is List) {
            loadedOffersJson = target;
          }
        } else if (decodedData is List) {
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
  // REFRESH
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
      builder: (
        context,
        constraints,
      ) {
        final double width = constraints.maxWidth;

        final bool isMobile = width < 600;

        final bool isTablet =
            width >= 600 && width < 1000;

        final double horizontalPadding = isMobile
            ? 16
            : isTablet
                ? 24
                : 32;

        final double topPadding = isMobile
            ? 16
            : isTablet
                ? 24
                : 30;

        final double availableWidth =
            constraints.maxWidth -
            (horizontalPadding * 2);

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Theme.of(context)
              .scaffoldBackgroundColor,
          child: RefreshIndicator(
            onRefresh: _refreshOffers,
            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                topPadding,
                horizontalPadding,
                32,
              ),
              children: [
                // ==================================================
                // TITLE
                // ==================================================

                Text(
                  'Penawaran Aktif Saya',
                  style: TextStyle(
                    fontSize: isMobile
                        ? 24
                        : 32,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                // ==================================================
                // DESCRIPTION
                // ==================================================

                Text(
                  'Seluruh penawaran yang sedang menunggu '
                  'respon atau telah diproses.',
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.6),
                    fontSize: isMobile
                        ? 14
                        : 16,
                    height: 1.45,
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                // ==================================================
                // CONTENT
                // ==================================================

                _buildContent(
                  context,
                  isMobile: isMobile,
                  isTablet: isTablet,
                  availableWidth: availableWidth,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent(
    BuildContext context, {
    required bool isMobile,
    required bool isTablet,
    required double availableWidth,
  }) {
    // ==========================================================
    // LOADING
    // ==========================================================

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(
          top: 80,
          bottom: 80,
        ),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    if (_errorMessage.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 80,
        ),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 60,
              color: Colors.grey,
            ),

            const SizedBox(
              height: 16,
            ),

            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
                height: 1.4,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            ElevatedButton.icon(
              onPressed: _fetchMyOffers,
              icon: const Icon(
                Icons.refresh,
                size: 18,
              ),
              label: const Text(
                'Coba Lagi',
              ),
            ),
          ],
        ),
      );
    }

    // ==========================================================
    // EMPTY
    // ==========================================================

    if (_offers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(
          top: 70,
          bottom: 70,
        ),
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

            const SizedBox(
              height: 12,
            ),

            Text(
              'Belum ada penawaran aktif.',
              textAlign: TextAlign.center,
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
      );
    }

    // ==========================================================
    // TABLE
    // ==========================================================

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          // Desktop:
          // tabel memenuhi seluruh area yang tersedia.
          //
          // Tablet / mobile:
          // tabel tetap punya lebar minimum agar
          // kolom tidak terlalu kecil.
          width: isMobile || isTablet
              ? 1350
              : availableWidth,
          child: Table(
            defaultVerticalAlignment:
                TableCellVerticalAlignment.middle,

            // ==================================================
            // COLUMN WIDTH
            // ==================================================

            columnWidths:
                isMobile || isTablet
                    ? const {
                        0: FixedColumnWidth(70),
                        1: FixedColumnWidth(230),
                        2: FixedColumnWidth(150),
                        3: FixedColumnWidth(150),
                        4: FixedColumnWidth(190),
                        5: FixedColumnWidth(180),
                        6: FixedColumnWidth(180),
                        7: FixedColumnWidth(200),
                      }
                    : const {
                        0: FlexColumnWidth(0.55),
                        1: FlexColumnWidth(1.80),
                        2: FlexColumnWidth(1.15),
                        3: FlexColumnWidth(1.15),
                        4: FlexColumnWidth(1.50),
                        5: FlexColumnWidth(1.40),
                        6: FlexColumnWidth(1.40),
                        7: FlexColumnWidth(1.55),
                      },

            // ==================================================
            // TABLE BORDER
            // ==================================================

            border: const TableBorder(
              top: BorderSide(
                color: Color(0xffE5E7EB),
                width: 1,
              ),
              left: BorderSide(
                color: Color(0xffE5E7EB),
                width: 1,
              ),
              right: BorderSide(
                color: Color(0xffE5E7EB),
                width: 1,
              ),
              bottom: BorderSide(
                color: Color(0xffE5E7EB),
                width: 1,
              ),
              horizontalInside: BorderSide(
                color: Color(0xffE5E7EB),
                width: 1,
              ),
              verticalInside: BorderSide(
                color: Color(0xffE5E7EB),
                width: 1,
              ),
            ),

            // ==================================================
            // TABLE ROWS
            // ==================================================

            children: [
              _buildTableHeader(),

              ..._offers.asMap().entries.map(
              (entry) {
                final int index = entry.key;
                final ActiveOfferModel offer = entry.value;

                return buildActiveOfferRow(
                  context,
                  offer,
                  index + 1,
                );
              },
            ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TABLE HEADER
  // ============================================================

  TableRow _buildTableHeader() {
    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return TableRow(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xff1F2937)
            : const Color(0xffFFF7F7),
      ),
      children: [
        _headerCell('NO'),
        _headerCell('NAMA PEKERJAAN'),
        _headerCell('HARGA'),
        _headerCell('PERINGKAT'),
        _headerCell('STATUS'),
        _headerCell('BUKTI'),
        _headerCell('ACC PELANGGAN'),
        _headerCell('AKSI'),
      ],
    );
  }

  // ============================================================
  // HEADER CELL
  // ============================================================

  Widget _headerCell(
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xffC62828),
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}