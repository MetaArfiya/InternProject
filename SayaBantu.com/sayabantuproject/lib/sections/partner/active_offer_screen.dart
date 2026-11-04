
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../widgets/active_offer_card.dart';
import '../../services/api_service.dart';
import '../../models/active_offer_model.dart';
import '../../theme/app_colors.dart';

class ActiveOfferScreen extends StatefulWidget {
  final ValueChanged<ActiveOfferModel> onOpenTracking;

  const ActiveOfferScreen({
    super.key,
    required this.onOpenTracking,
  });

  @override
  State<ActiveOfferScreen> createState() => _ActiveOfferScreenState();
}

class _ActiveOfferScreenState extends State<ActiveOfferScreen>
    with WidgetsBindingObserver {
  List<ActiveOfferModel> _offers = [];

  int _currentPage = 1;
  int _rowsPerPage = 10;

  final List<int> _rowsPerPageOptions = [10, 25, 50];

  bool _isLoading = true;
  String _errorMessage = '';

  Timer? _refreshTimer;
  bool _isAppInForeground = true;

  // ============================================================
  // DESIGN TOKENS
  // ============================================================

  static const Color _accent = AppColors.primaryTeal;
  static const Color _tableBorder = AppColors.grey200;
  static const Color _tableDivider = AppColors.grey100;

  static const double _gapAfterHeader = 16;

  int get _totalPages {
    if (_offers.isEmpty) return 1;
    return (_offers.length / _rowsPerPage).ceil();
  }

  int get _startIndex => (_currentPage - 1) * _rowsPerPage;

  int get _endIndex =>
      (_startIndex + _rowsPerPage).clamp(0, _offers.length);

  List<ActiveOfferModel> get _paginatedOffers {
    return _offers
        .skip(_startIndex)
        .take(_rowsPerPage)
        .toList();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _fetchMyOffers();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // AUTO REFRESH & LIFECYCLE
  // ============================================================

  void _startAutoRefresh() {
    _refreshTimer?.cancel();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        if (_isAppInForeground && mounted) {
          _fetchMyOffers(silent: true);
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppInForeground = true;
      _fetchMyOffers(silent: true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _isAppInForeground = false;
    }
  }

  // ============================================================
  // FETCH DATA
  // ============================================================

  Future<void> _fetchMyOffers({bool silent = false}) async {
    if (!mounted) return;

    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final response = await ApiService.get('/mitra/my-offers');

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

          _currentPage = _currentPage
              .clamp(1, _totalPages)
              .toInt();

          _isLoading = false;
          _errorMessage = '';
        });
      } else {
        if (!mounted || silent) return;

        setState(() {
          _errorMessage =
              'Gagal memuat penawaran.\nStatus: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted || silent) return;

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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.sectionAltLight,
      child: RefreshIndicator(
        onRefresh: _refreshOffers,
        color: _accent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            final isMobile = width < 700;
            final isTablet = width >= 700 && width < 1100;

            final horizontalPadding = isMobile
                ? 16.0
                : (isTablet ? 24.0 : 28.0);

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
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Penawaran Aktif Saya',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.grey900,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Seluruh penawaran yang sedang menunggu respon atau telah diproses.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.grey500,
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

    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }

    if (_offers.isEmpty) {
      return _buildEmptyState();
    }

    if (isMobile) {
      return _buildMobileList();
    }

    return _buildDesktopTable(isTablet: isTablet);
  }

  // ============================================================
  // WIDGET BUKTI
  // ============================================================

  Widget _buildProofImage(String? proofUrl) {
    if (proofUrl == null ||
        proofUrl.isEmpty ||
        proofUrl == 'null') {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _tableBorder),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                size: 20,
                color: AppColors.grey400,
              ),
              SizedBox(height: 4),
              Text(
                'Tidak ada',
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.grey500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final fullUrl = proofUrl.startsWith('http')
        ? proofUrl
        : '${ApiService.baseUrl}$proofUrl';

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            child: Image.network(
              fullUrl,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _tableBorder),
          image: DecorationImage(
            image: NetworkImage(fullUrl),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL BUTTON
  // ============================================================

  Widget _buildDetailButton(
    BuildContext context,
    ActiveOfferModel offer,
  ) {
    return Material(
      color: AppColors.grey100,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          debugPrint(
            'Klik detail untuk Job ID: ${offer.jobId}',
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 14,
                color: AppColors.grey700,
              ),
              SizedBox(width: 6),
              Text(
                'Detail',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildMobileOfferCard(
    ActiveOfferModel offer,
    int number,
  ) {
    final existingRow = buildActiveOfferRow(
      context,
      offer,
      number,
      onOpenTracking: widget.onOpenTracking,
    );

    final cells = existingRow.children;

    const labels = [
      '',
      'Pekerjaan',
      'Harga',
      'Jadwal mulai',
      'Peringkat',
      'Status',
      'Bukti',
      'ACC Pelanggan',
      'Aksi',
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    color: _accent.withValues(alpha: 0.12),
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

          const Divider(
            height: 1,
            color: _tableDivider,
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: List.generate(cells.length, (index) {
                if (index == 0) {
                  return const SizedBox.shrink();
                }

                return _buildReceiptRow(
                  label: labels[index],
                  value: cells[index],
                  isLast: index == cells.length - 1,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECEIPT ROW
  // ============================================================

  Widget _buildReceiptRow({
    required String label,
    required Widget value,
    required bool isLast,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: isLast ? 0 : 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.grey700,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
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
  // WEB — TABEL + PAGINATION
  // ============================================================

  Widget _buildDesktopTable({required bool isTablet}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _tableBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TABLE
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                child: isTablet
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: 1380,
                          child: _buildTable(isTablet: true),
                        ),
                      )
                    : SizedBox(
                        width: constraints.maxWidth,
                        child: _buildTable(isTablet: false),
                      ),
              ),

              // DIVIDER
              const Divider(
                height: 1,
                thickness: 1,
                color: _tableBorder,
              ),

              // PAGINATION — MENYATU DENGAN TABEL
              _buildPagination(),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // TABLE
  // ============================================================

  Widget _buildTable({required bool isTablet}) {
    final pageOffers = _paginatedOffers;

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: isTablet
          ? const {
              0: FixedColumnWidth(60),
              1: FixedColumnWidth(220),
              2: FixedColumnWidth(140),
              3: FixedColumnWidth(170),
              4: FixedColumnWidth(130),
              5: FixedColumnWidth(170),
              6: FixedColumnWidth(160),
              7: FixedColumnWidth(170),
              8: FixedColumnWidth(160),
            }
          : const {
              0: FlexColumnWidth(0.55),
              1: FlexColumnWidth(1.80),
              2: FlexColumnWidth(1.15),
              3: FlexColumnWidth(1.50),
              4: FlexColumnWidth(1.50),
              5: FlexColumnWidth(1.40),
              6: FlexColumnWidth(1.40),
              7: FlexColumnWidth(1.40),
              8: FlexColumnWidth(1.55),
            },
      border: const TableBorder(
        bottom: BorderSide(color: _tableDivider),
        horizontalInside: BorderSide(color: _tableDivider),
      ),
      children: [
        _buildTableHeader(),
        ...pageOffers.asMap().entries.map((entry) {
          return buildActiveOfferRow(
            context,
            entry.value,
            _startIndex + entry.key + 1,
            onOpenTracking: widget.onOpenTracking,
          );
        }),
      ],
    );
  }

  // ============================================================
  // TABLE HEADER
  // ============================================================

  TableRow _buildTableHeader() {
    return const TableRow(
      decoration: BoxDecoration(
        color: AppColors.white,
      ),
      children: [
        _HeaderCell('NO'),
        _HeaderCell('NAMA PEKERJAAN'),
        _HeaderCell('HARGA'),
        _HeaderCell('JADWAL MULAI'),
        _HeaderCell('PERINGKAT'),
        _HeaderCell('STATUS'),
        _HeaderCell('BUKTI'),
        _HeaderCell('ACC PELANGGAN'),
        _HeaderCell('AKSI'),
      ],
    );
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  Widget _buildPagination() {
    final total = _offers.length;

    final information = Text(
      total == 0
          ? 'Menampilkan 0 dari 0 penawaran'
          : 'Menampilkan ${_startIndex + 1}–$_endIndex dari $total penawaran',
      style: const TextStyle(
        fontSize: 12,
        color: AppColors.grey500,
      ),
    );

    final controls = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        // JUMLAH DATA PER HALAMAN
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _tableBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _rowsPerPage,
              isDense: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: AppColors.grey500,
              ),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.grey900,
                fontWeight: FontWeight.w500,
              ),
              items: _rowsPerPageOptions.map((value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value / hal'),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _rowsPerPage = value;
                  _currentPage = 1;
                });
              },
            ),
          ),
        ),

        // HALAMAN SEBELUMNYA
        _paginationButton(
          icon: Icons.chevron_left,
          enabled: _currentPage > 1,
          onTap: () {
            setState(() {
              _currentPage--;
            });
          },
        ),

        // INDIKATOR HALAMAN
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Hal $_currentPage / $_totalPages',
            style: const TextStyle(
              fontSize: 12,
              color: _accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // HALAMAN SELANJUTNYA
        _paginationButton(
          icon: Icons.chevron_right,
          enabled: _currentPage < _totalPages,
          onTap: () {
            setState(() {
              _currentPage++;
            });
          },
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 550;

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                information,
                const SizedBox(height: 12),
                controls,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: information),
              controls,
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // PAGINATION BUTTON
  // ============================================================

  Widget _paginationButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _tableBorder),
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled
                ? AppColors.grey700
                : AppColors.grey300,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: AppColors.danger,
          ),
          const SizedBox(height: 14),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.danger,
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
              foregroundColor: AppColors.white,
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

  // ============================================================
  // EMPTY STATE
  // ============================================================

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
              color: _accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 34,
              color: _accent.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum ada penawaran aktif.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.grey600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HEADER CELL
// ============================================================

class _HeaderCell extends StatelessWidget {
  final String text;

  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 14,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.grey500,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
