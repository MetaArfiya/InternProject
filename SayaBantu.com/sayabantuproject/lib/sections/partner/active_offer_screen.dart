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

  // ============================================================
  // DESIGN TOKENS — disamakan dengan DashboardHeader / PaymentScreen
  // ============================================================

  static const Color _accent = Color(0xFFF97316);
  static const Color _tableBorder = Color(0xFFE5E7EB);
  static const Color _tableDivider = Color(0xFFF3F4F6);
  static const Color _headerText = Color(0xFF6B7280);

  // Spacing — mengikuti pola DashboardHeader
  static const double _gapAfterHeader = 16;

  @override
  void initState() {
    super.initState();
    _fetchMyOffers();
  }

  // ============================================================
  // FETCH
  // ============================================================

  Future<void> _fetchMyOffers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiService.get('/mitra/my-offers');

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        List<dynamic> loadedOffersJson = [];

        if (decodedData is Map<String, dynamic>) {
          final target = decodedData['data'] ?? decodedData['offers'] ?? [];
          if (target is List) loadedOffersJson = target;
        } else if (decodedData is List) {
          loadedOffersJson = decodedData;
        }

        final loadedOffers = <ActiveOfferModel>[];

        for (final item in loadedOffersJson) {
          try {
            if (item is Map<String, dynamic>) {
              loadedOffers.add(ActiveOfferModel.fromJson(item));
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
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Terjadi kesalahan koneksi.\n$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshOffers() async {
    await _fetchMyOffers();
  }

  // ============================================================
  // BUILD
  // ============================================================
  // ✅ Padding horizontal disamakan dgn CustomerDashboard
  //    mobile 16 / tablet 24 / desktop 28  (bukan 32)
  // ✅ TIDAK ada Center + ConstrainedBox — konten nempel kiri
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: RefreshIndicator(
        onRefresh: _refreshOffers,
        color: _accent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 700;
            final isTablet = width >= 700 && width < 1100;

            final horizontalPadding =
                isMobile ? 16.0 : (isTablet ? 24.0 : 28.0);
            final verticalPadding = isMobile ? 16.0 : 28.0;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),

                  const SizedBox(height: _gapAfterHeader),

                  _buildContent(
                    isMobile: isMobile,
                    isTablet: isTablet,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // HEADER — sama persis dgn DashboardHeader
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Penawaran Aktif Saya',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Seluruh penawaran yang sedang menunggu respon atau telah diproses.',
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent({
    required bool isMobile,
    required bool isTablet,
  }) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: CircularProgressIndicator(color: _accent),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) return _buildErrorState();
    if (_offers.isEmpty) return _buildEmptyState();

    if (isMobile) return _buildMobileList();
    return _buildDesktopTable(isTablet: isTablet);
  }

  // ============================================================
  // MOBILE — RECEIPT STYLE
  // ============================================================

  Widget _buildMobileList() {
    return Column(
      children: _offers.asMap().entries.map((entry) {
        final index = entry.key;
        final offer = entry.value;

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == _offers.length - 1 ? 0 : 12,
          ),
          child: _buildMobileOfferCard(offer, index + 1),
        );
      }).toList(),
    );
  }

  Widget _buildMobileOfferCard(ActiveOfferModel offer, int number) {
    final existingRow = buildActiveOfferRow(context, offer, number);
    final cells = existingRow.children;

    const labels = [
      '', // 0: skip (dipakai header)
      'Pekerjaan',
      'Harga',
      'Peringkat',
      'Status',
      'Bukti',
      'ACC Pelanggan',
      'Aksi',
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _tableBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // HEADER
          // ==========================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Penawaran #$number',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _accent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: _tableDivider),

          // ==========================================
          // BODY
          // ==========================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: List.generate(
                cells.length,
                (index) {
                  if (index == 0) return const SizedBox.shrink();

                  return _buildReceiptRow(
                    label: labels[index],
                    value: cells[index],
                    isLast: index == cells.length - 1,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECEIPT ROW — label jelas, value rapat ke kiri
  // ============================================================

  Widget _buildReceiptRow({
    required String label,
    required Widget value,
    required bool isLast,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // LABEL — lebih tua, lebih tebal
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF334155), // slate-700
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // VALUE — rata KIRI, dekat label
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: value,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WEB — TABEL
  // ============================================================

  Widget _buildDesktopTable({required bool isTablet}) {
    if (isTablet) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _tableBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1200,
              child: _buildTable(isTablet: true),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _tableBorder),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: constraints.maxWidth,
              child: _buildTable(isTablet: false),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTable({required bool isTablet}) {
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: isTablet
          ? const {
              0: FixedColumnWidth(60),
              1: FixedColumnWidth(220),
              2: FixedColumnWidth(140),
              3: FixedColumnWidth(130),
              4: FixedColumnWidth(170),
              5: FixedColumnWidth(160),
              6: FixedColumnWidth(170),
              7: FixedColumnWidth(160),
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
      border: const TableBorder(
        bottom: BorderSide(color: _tableDivider),
        horizontalInside: BorderSide(color: _tableDivider),
      ),
      children: [
        _buildTableHeader(),
        ..._offers.asMap().entries.map((entry) {
          return buildActiveOfferRow(
            context,
            entry.value,
            entry.key + 1,
          );
        }),
      ],
    );
  }

  TableRow _buildTableHeader() {
    return TableRow(
      decoration: const BoxDecoration(color: Colors.white),
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

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Text(
        text,
        style: const TextStyle(
          color: _headerText,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================
  // ERROR & EMPTY
  // ============================================================

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(height: 14),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFDC2626),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchMyOffers,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 34,
              color: _accent.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum ada penawaran aktif.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}