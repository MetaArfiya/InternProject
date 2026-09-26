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
      final response = await ApiService.get('/mitra/my-offers');

      debugPrint('🔎 MY OFFERS STATUS CODE: ${response.statusCode}');
      debugPrint('🔎 MY OFFERS BODY: ${response.body}');

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        List<dynamic> loadedOffersJson = [];

        if (decodedData is Map<String, dynamic>) {
          final target =
              decodedData['data'] ?? decodedData['offers'] ?? [];

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
            debugPrint('⚠️ Gagal parsing offer: $e');
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
              'Gagal memuat penawaran.\nStatus: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ ERROR FETCH OFFERS: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Terjadi kesalahan koneksi.\n$e';
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
      builder: (context, constraints) {
        final double width = constraints.maxWidth;

        final bool isMobile = width < 600;
        final bool isTablet = width >= 600 && width < 1000;

        final double horizontalPadding = isMobile
            ? 16
            : (isTablet ? 24 : 32);

        final double topPadding = isMobile
            ? 16
            : (isTablet ? 24 : 30);

        final double availableWidth =
            constraints.maxWidth - (horizontalPadding * 2);

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: RefreshIndicator(
            onRefresh: _refreshOffers,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                    fontSize: isMobile ? 22 : 30,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 6),

                // ==================================================
                // DESCRIPTION
                // ==================================================
                Text(
                  'Seluruh penawaran yang sedang menunggu respon atau telah diproses.',
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.6),
                    fontSize: isMobile ? 12 : 15,
                    height: 1.4,
                  ),
                ),

                SizedBox(
                  height: isMobile ? 18 : 24,
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
          top: 70,
          bottom: 70,
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
          vertical: 70,
        ),
        child: Column(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: isMobile ? 50 : 60,
              color: Colors.grey,
            ),

            const SizedBox(height: 14),

            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red,
                fontSize: isMobile ? 12 : 14,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 14),

            ElevatedButton.icon(
              onPressed: _fetchMyOffers,
              icon: const Icon(
                Icons.refresh,
                size: 17,
              ),
              label: Text(
                'Coba Lagi',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                ),
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
          top: 60,
          bottom: 60,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: isMobile ? 52 : 60,
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.3),
            ),

            const SizedBox(height: 12),

            Text(
              'Belum ada penawaran aktif.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
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
    // MOBILE
    // ==========================================================

    if (isMobile) {
      return _buildMobileOffers(context);
    }

    // ==========================================================
    // TABLET + DESKTOP
    // ==========================================================

    return _buildDesktopTable(
      context,
      isTablet: isTablet,
      availableWidth: availableWidth,
    );
  }

  // ============================================================
  // MOBILE OFFER LIST
  // ============================================================

  Widget _buildMobileOffers(BuildContext context) {
    return Column(
      children: [
        ..._offers.asMap().entries.map(
          (entry) {
            final int index = entry.key;
            final ActiveOfferModel offer = entry.value;

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == _offers.length - 1
                    ? 0
                    : 12,
              ),
              child: _buildMobileOfferCard(
                context,
                offer,
                index + 1,
              ),
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE OFFER CARD
  // ============================================================

  Widget _buildMobileOfferCard(
    BuildContext context,
    ActiveOfferModel offer,
    int number,
  ) {
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;

    final Color cardColor =
        Theme.of(context).cardColor;

    final Color borderColor = isDark
        ? const Color(0xff374151)
        : const Color(0xffE5E7EB);

    final Color mutedColor =
        Theme.of(context)
                .textTheme
                .bodyMedium
                ?.color
                ?.withOpacity(0.55) ??
            Colors.grey;

    // ==========================================================
    // Ambil children dari row desktop yang sudah ada.
    //
    // Dengan cara ini kita tidak perlu mengambil ulang field
    // dari ActiveOfferModel dan tidak mengubah active_offer_card.dart.
    // ==========================================================

    final TableRow existingRow =
        buildActiveOfferRow(
      context,
      offer,
      number,
    );

    final List<Widget> cells =
        existingRow.children;

    final List<String> labels = [
      'NO',
      'NAMA PEKERJAAN',
      'HARGA',
      'PERINGKAT',
      'STATUS',
      'BUKTI',
      'ACC PELANGGAN',
      'AKSI',
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // CARD HEADER
            // ==================================================

            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(8),
                    color: isDark
                        ? const Color(0xff1F2937)
                        : const Color(0xffFFF7ED),
                  ),
                  child: Center(
                    child: Text(
                      '#$number',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white
                            : const Color(0xffEA580C),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'Penawaran Aktif',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.color,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Divider(
              height: 1,
              color: borderColor,
            ),

            const SizedBox(height: 4),

            // ==================================================
            // DETAIL
            // ==================================================

            ...List.generate(
              cells.length,
              (index) {
                final Widget cell = cells[index];

                return _buildMobileDetailRow(
                  context,
                  label: index < labels.length
                      ? labels[index]
                      : '',
                  value: cell,
                  mutedColor: mutedColor,
                  isLast: index == cells.length - 1,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE DETAIL ROW
  // ============================================================

  Widget _buildMobileDetailRow(
    BuildContext context, {
    required String label,
    required Widget value,
    required Color mutedColor,
    required bool isLast,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isLast ? 8 : 7,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: mutedColor,
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 3),

          // ----------------------------------------------------
          // Isi cell yang sudah dibuat oleh active_offer_card.dart
          // ----------------------------------------------------

          SizedBox(
            width: double.infinity,
            child: value,
          ),

          if (!isLast) ...[
            const SizedBox(height: 4),

            Divider(
              height: 1,
              color: Theme.of(context)
                  .dividerColor
                  .withOpacity(0.35),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // DESKTOP / TABLET TABLE
  // ============================================================

  Widget _buildDesktopTable(
    BuildContext context, {
    required bool isTablet,
    required double availableWidth,
  }) {
    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final Color borderColor = isDark
        ? const Color(0xff374151)
        : const Color(0xffF3F4F6);

    final Color outerBorderColor = isDark
        ? const Color(0xff374151)
        : const Color(0xffE5E7EB);

    // ----------------------------------------------------------
    // Untuk tablet tetap gunakan tabel.
    //
    // Lebar minimum dibuat agar semua kolom tidak terlalu sempit.
    // Desktop menggunakan availableWidth.
    // ----------------------------------------------------------

    final double tableWidth = isTablet
        ? 1180
        : availableWidth;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: outerBorderColor,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Table(
              defaultVerticalAlignment:
                  TableCellVerticalAlignment.middle,

              // ==================================================
              // COLUMN WIDTH
              // ==================================================

              columnWidths: isTablet
                  ? const {
                      0: FixedColumnWidth(60),
                      1: FixedColumnWidth(210),
                      2: FixedColumnWidth(135),
                      3: FixedColumnWidth(130),
                      4: FixedColumnWidth(160),
                      5: FixedColumnWidth(160),
                      6: FixedColumnWidth(170),
                      7: FixedColumnWidth(155),
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
              // BORDER
              // ==================================================

              border: TableBorder(
                bottom: BorderSide(
                  color: borderColor,
                  width: 1,
                ),
                horizontalInside: BorderSide(
                  color: borderColor,
                  width: 1,
                ),
              ),

              // ==================================================
              // ROWS
              // ==================================================

              children: [
                _buildTableHeader(),

                ..._offers.asMap().entries.map(
                  (entry) {
                    final int index = entry.key;
                    final ActiveOfferModel offer =
                        entry.value;

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
            ? const Color(0xff111827)
            : Colors.white,
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

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.color ??
              Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}