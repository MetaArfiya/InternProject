import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class AdminRatingScreen extends StatefulWidget {
  const AdminRatingScreen({super.key});

  @override
  State<AdminRatingScreen> createState() => _AdminRatingScreenState();
}

class _AdminRatingScreenState extends State<AdminRatingScreen> {
  // ============================================================
  // STATE
  // ============================================================
  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _ratings = [];

  int _total = 0;
  double _average = 0;
  int _highCount = 0;
  int _lowCount = 0;

  String _selectedFilter = 'Semua';

  final List<Map<String, dynamic>> _filterOptions = [
    {'label': 'Semua', 'value': null},
    {'label': '5 Bintang', 'value': 5},
    {'label': '4 Bintang', 'value': 4},
    {'label': '3 Bintang', 'value': 3},
    {'label': '2 Bintang', 'value': 2},
    {'label': '1 Bintang', 'value': 1},
  ];

  // ============================================================
  // PAGINATION STATE
  // ============================================================
  int _currentPage = 1;
  int _itemsPerPage = 10;
  static const List<int> _itemsPerPageOptions = [5, 10, 25, 50];

  // ============================================================
  // LIFECYCLE
  // ============================================================
  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================
  Future<void> _loadRatings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String endpoint = '/admin/ratings';
      final current = _filterOptions.firstWhere(
        (e) => e['label'] == _selectedFilter,
        orElse: () => _filterOptions.first,
      );
      final starsValue = current['value'];
      if (starsValue != null) {
        endpoint += '?stars=$starsValue';
      }

      final response = await ApiService.get(endpoint);

      debugPrint('⭐ RATINGS: ${response.statusCode}');
      debugPrint('⭐ BODY: ${response.body}');

      if (response.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat (${response.statusCode})';
        });
        return;
      }

      final decoded = jsonDecode(response.body);

      if (decoded['success'] != true) {
        setState(() {
          _isLoading = false;
          _errorMessage = decoded['message']?.toString() ?? 'Gagal memuat.';
        });
        return;
      }

      if (!mounted) return;

      final s = decoded['summary'] ?? {};
      final list = (decoded['data'] is List) ? decoded['data'] as List : [];

      setState(() {
        _total = int.tryParse(s['total']?.toString() ?? '0') ?? 0;
        _average = double.tryParse(s['average']?.toString() ?? '0') ?? 0;
        _highCount = int.tryParse(s['high_count']?.toString() ?? '0') ?? 0;
        _lowCount = int.tryParse(s['low_count']?.toString() ?? '0') ?? 0;

        _ratings = list
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();

        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ ERROR RATINGS: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================
  String _code(Map<String, dynamic> r) {
    final id = r['id'];
    if (id is int) return 'RAT-${id.toString().padLeft(3, '0')}';
    return 'RAT-${id.toString()}';
  }

  String _getNestedValue(
    Map<String, dynamic> data,
    String relation,
    List<String> keys,
  ) {
    final rel = data[relation];
    if (rel is Map) {
      for (final key in keys) {
        final value = rel[key];
        if (value != null &&
            value.toString().trim().isNotEmpty &&
            value.toString() != 'null') {
          return value.toString();
        }
      }
    }
    return '-';
  }

  String _formatTanggal(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      final date = DateTime.parse(iso).toLocal();
      const bulan = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      return '${date.day} ${bulan[date.month - 1]} ${date.year}';
    } catch (_) {
      return iso;
    }
  }

  int _getStars(Map<String, dynamic> r) {
    return int.tryParse(r['stars']?.toString() ?? '0') ?? 0;
  }

  Color _ratingColor(int rating) {
    if (rating >= 4) return const Color(0xFF059669);
    if (rating == 3) return const Color(0xFFF59E0B);
    return const Color(0xFFDC2626);
  }

  Widget _buildStars(int rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star : Icons.star_border,
          color: const Color(0xFFF59E0B),
          size: size,
        );
      }),
    );
  }

  Widget _buildRatingBadge(int rating) {
    final color = _ratingColor(rating);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$rating/5',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAGINATION HELPERS
  // ============================================================
  int get _totalPages {
    final total = _ratings.length;
    if (total == 0) return 1;
    return ((total - 1) ~/ _itemsPerPage) + 1;
  }

  List<Map<String, dynamic>> get _paginatedRatings {
    final start = (_currentPage - 1) * _itemsPerPage;
    if (start >= _ratings.length) return [];
    final end = (start + _itemsPerPage).clamp(0, _ratings.length);
    return _ratings.sublist(start, end);
  }

  // ============================================================
  // AKSI ADMIN
  // ============================================================
  Future<void> _deleteRating(int id) async {
    try {
      final response = await ApiService.delete('/admin/ratings/$id');

      debugPrint('⭐ DELETE RATING: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (!mounted) return;
        _snack('Rating berhasil dihapus.', color: const Color(0xFF16A34A));
        _loadRatings();
      } else {
        String message = 'Gagal menghapus rating.';
        try {
          final decoded = jsonDecode(response.body);
          message = decoded['message']?.toString() ?? message;
        } catch (_) {}
        if (!mounted) return;
        _snack(message, color: const Color(0xFFDC2626));
      }
    } catch (e) {
      if (!mounted) return;
      _snack('Error: $e', color: const Color(0xFFDC2626));
    }
  }

  Future<void> _hideRating(int id, String? reason) async {
    try {
      final response = await ApiService.put(
        '/admin/ratings/$id/hide',
        {'reason': reason ?? ''},
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        _snack('Rating berhasil disembunyikan.',
            color: const Color(0xFFF59E0B));
        _loadRatings();
      } else {
        if (!mounted) return;
        _snack('Gagal menyembunyikan rating.',
            color: const Color(0xFFDC2626));
      }
    } catch (e) {
      if (!mounted) return;
      _snack('Error: $e', color: const Color(0xFFDC2626));
    }
  }

  void _snack(String msg, {required Color color}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        final double hPad = isMobile ? 16 : 24;

        return RefreshIndicator(
          onRefresh: _loadRatings,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, hPad, hPad, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isMobile),
                      const SizedBox(height: 20),

                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 80),
                            child: CircularProgressIndicator(
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        )
                      else if (_errorMessage != null)
                        _buildError()
                      else ...[
                        _buildSummarySection(isMobile),
                        const SizedBox(height: 16),
                        _buildFilterSection(isMobile),
                        const SizedBox(height: 16),
                        if (_ratings.isEmpty)
                          _buildEmptyState()
                        else if (isMobile)
                          _buildMobileList()
                        else
                          _buildDesktopTable(),
                      ],

                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                if (!_isLoading &&
                    _errorMessage == null &&
                    _ratings.isNotEmpty)
                  _buildPaginationFullWidth(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // HEADER
  // ============================================================
  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kelola Rating Mitra',
          style: TextStyle(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pantau dan kelola penilaian pelanggan terhadap mitra.',
          style: TextStyle(
            fontSize: isMobile ? 12 : 13,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY — Mobile: 2 atas 2 bawah (grid 2x2)
  // ============================================================
  Widget _buildSummarySection(bool isMobile) {
    final cards = [
      _summaryCard(
        title: 'Total Rating',
        value: '$_total',
        icon: Icons.rate_review_outlined,
        color: const Color(0xFF2563EB),
        bg: const Color(0xFFEFF6FF),
      ),
      _summaryCard(
        title: 'Rata-rata',
        value: _average.toStringAsFixed(1),
        icon: Icons.star_rate_outlined,
        color: const Color(0xFFF59E0B),
        bg: const Color(0xFFFFF7ED),
      ),
      _summaryCard(
        title: 'Rating Positif',
        value: '$_highCount',
        icon: Icons.thumb_up_alt_outlined,
        color: const Color(0xFF059669),
        bg: const Color(0xFFECFDF5),
      ),
      _summaryCard(
        title: 'Rating Rendah',
        value: '$_lowCount',
        icon: Icons.warning_amber_outlined,
        color: const Color(0xFFDC2626),
        bg: const Color(0xFFFEF2F2),
      ),
    ];

    // ---- MOBILE: 2 kolom x 2 baris ----
    if (isMobile) {
      return Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 10),
                Expanded(child: cards[1]),
              ],
            ),
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[2]),
                const SizedBox(width: 10),
                Expanded(child: cards[3]),
              ],
            ),
          ),
        ],
      );
    }

    // ---- DESKTOP: 4 sejajar ----
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 12),
          Expanded(child: cards[1]),
          const SizedBox(width: 12),
          Expanded(child: cards[2]),
          const SizedBox(width: 12),
          Expanded(child: cards[3]),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY CARD — Compact (cocok untuk grid 2x2)
  // ============================================================
  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon di atas
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),

          // Value
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER
  // ============================================================
  Widget _buildFilterSection(bool isMobile) {
    final dropdown = Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          isExpanded: true,
          borderRadius: BorderRadius.circular(10),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFF64748B),
            size: 21,
          ),
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF334155),
            fontWeight: FontWeight.w600,
          ),
          items: _filterOptions.map((f) {
            return DropdownMenuItem<String>(
              value: f['label'] as String,
              child: Text(f['label'] as String),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedFilter = value);
            _loadRatings();
          },
        ),
      ),
    );

    final label = Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.filter_list,
            size: 18,
            color: Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Rating',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_ratings.length} ulasan ditampilkan',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                label,
                const SizedBox(height: 12),
                dropdown,
              ],
            )
          : Row(
              children: [
                label,
                const Spacer(),
                SizedBox(width: 200, child: dropdown),
              ],
            ),
    );
  }

  // ============================================================
  // TABLE (DESKTOP)
  // ============================================================
  Widget _buildDesktopTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                headingRowHeight: 48,
                dataRowMinHeight: 56,
                dataRowMaxHeight: 56,
                columnSpacing: 24,
                horizontalMargin: 20,
                dividerThickness: 1,
                showBottomBorder: true,
                columns: const [
                  DataColumn(label: _TableHeader('ID')),
                  DataColumn(label: _TableHeader('MITRA')),
                  DataColumn(label: _TableHeader('PELANGGAN')),
                  DataColumn(label: _TableHeader('LAYANAN')),
                  DataColumn(label: _TableHeader('RATING')),
                  DataColumn(label: _TableHeader('TANGGAL')),
                  DataColumn(label: _TableHeader('AKSI')),
                ],
                rows: _paginatedRatings.map((r) {
                  final rating = _getStars(r);
                  return DataRow(
                    cells: [
                      DataCell(Text(
                        _code(r),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      )),
                      DataCell(_tableCell(
                          _getNestedValue(r, 'mitra', ['name']))),
                      DataCell(_tableCell(
                          _getNestedValue(r, 'pelanggan', ['name']))),
                      DataCell(_tableCell(
                          _getNestedValue(r, 'job', ['tittle', 'title']))),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStars(rating),
                          const SizedBox(width: 6),
                          Text(
                            '$rating',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      )),
                      DataCell(_tableCell(
                          _formatTanggal(r['created_at']?.toString()))),
                      DataCell(IconButton(
                        tooltip: 'Lihat Detail',
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        color: const Color(0xFF2563EB),
                        onPressed: () => _showRatingDetail(r),
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tableCell(String text) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
    );
  }

  // ============================================================
  // MOBILE LIST
  // ============================================================
  Widget _buildMobileList() {
    return Column(
      children: _paginatedRatings.map((r) {
        final rating = _getStars(r);
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _code(r),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  _buildRatingBadge(rating),
                ],
              ),
              const SizedBox(height: 12),
              _mobileInfoRow(
                Icons.handshake_outlined,
                'Mitra',
                _getNestedValue(r, 'mitra', ['name']),
              ),
              _mobileInfoRow(
                Icons.person_outline,
                'Pelanggan',
                _getNestedValue(r, 'pelanggan', ['name']),
              ),
              _mobileInfoRow(
                Icons.work_outline,
                'Layanan',
                _getNestedValue(r, 'job', ['tittle', 'title']),
              ),
              _mobileInfoRow(
                Icons.calendar_today_outlined,
                'Tanggal',
                _formatTanggal(r['created_at']?.toString()),
              ),
              const SizedBox(height: 10),
              _buildStars(rating),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showRatingDetail(r),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Lihat Detail'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _mobileInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAGINATION — FULL WIDTH (Edge to Edge)
  // ============================================================
  Widget _buildPaginationFullWidth() {
    final total = _ratings.length;
    final totalPages = _totalPages;
    final startItem = (_currentPage - 1) * _itemsPerPage + 1;
    final endItem = (startItem + _itemsPerPage - 1).clamp(0, total);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              'Menampilkan $startItem–$endItem dari $total ulasan',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _itemsPerPage,
                    isDense: true,
                    borderRadius: BorderRadius.circular(8),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w600,
                    ),
                    items: _itemsPerPageOptions
                        .map((n) => DropdownMenuItem<int>(
                              value: n,
                              child: Text('$n / hal'),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _itemsPerPage = v;
                        _currentPage = 1;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _paginationIconButton(
                icon: Icons.chevron_left,
                onTap: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
              ),
              const SizedBox(width: 6),
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Hal $_currentPage / $totalPages',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _paginationIconButton(
                icon: Icons.chevron_right,
                onTap: _currentPage < totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paginationIconButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap == null
              ? const Color(0xFFF1F5F9)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null
              ? const Color(0xFFCBD5E1)
              : const Color(0xFF334155),
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL DIALOG
  // ============================================================
  void _showRatingDetail(Map<String, dynamic> r) {
    final rating = _getStars(r);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Row(
            children: [
              Icon(Icons.rate_review_outlined, color: Color(0xFF2563EB)),
              SizedBox(width: 10),
              Text('Detail Rating',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('ID Rating', _code(r)),
                  _detailRow(
                      'Nama Mitra', _getNestedValue(r, 'mitra', ['name'])),
                  _detailRow('Nama Pelanggan',
                      _getNestedValue(r, 'pelanggan', ['name'])),
                  _detailRow('Layanan',
                      _getNestedValue(r, 'job', ['tittle', 'title'])),
                  _detailRow(
                      'Tanggal', _formatTanggal(r['created_at']?.toString())),
                  const SizedBox(height: 12),
                  const Text('Rating',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildStars(rating, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        '$rating/5',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Komentar',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(r['comment']?.toString() ?? '-'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tutup'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _confirmHideRating(r);
              },
              icon: const Icon(Icons.visibility_off_outlined, size: 16),
              label: const Text('Sembunyikan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF59E0B),
                side: const BorderSide(color: Color(0xFFF59E0B)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _confirmDeleteRating(r);
              },
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Hapus'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmHideRating(Map<String, dynamic> r) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text('Sembunyikan Rating',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rating akan disembunyikan dari publik. Data tetap tersimpan.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Alasan (opsional)',
                  hintStyle: const TextStyle(fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _hideRating(r['id'], reasonController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Sembunyikan'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteRating(Map<String, dynamic> r) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text('Hapus Rating',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: const Text(
            'Apakah Anda yakin ingin menghapus rating ini? '
            'Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _deleteRating(r['id']);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // EMPTY & ERROR
  // ============================================================
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.rate_review_outlined,
              size: 52, color: Color(0xFFCBD5E1)),
          SizedBox(height: 12),
          Text(
            'Tidak ada rating',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Belum ada rating yang sesuai dengan filter.',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline,
              size: 48, color: Color(0xFFDC2626)),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFDC2626)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadRatings,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HELPER WIDGET — Header tabel
// ============================================================
class _TableHeader extends StatelessWidget {
  const _TableHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: Color(0xFF64748B),
      ),
    );
  }
}