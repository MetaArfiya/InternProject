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
  // DESIGN TOKENS — disamakan dgn DashboardHeader / PaymentScreen
  // ============================================================

  static const Color _accent = Color(0xFFF97316);
  static const Color _successColor = Color(0xFF16A34A);
  static const Color _dangerColor = Color(0xFFDC2626);
  static const Color _infoColor = Color(0xFF2563EB);
  static const Color _warningColor = Color(0xFFD97706);
  static const Color _purpleColor = Color(0xFF7C3AED);

  static const Color _tableBorder = Color(0xFFE5E7EB);
  static const Color _tableDivider = Color(0xFFF3F4F6);
  static const Color _headerText = Color(0xFF6B7280);
  static const Color _cellText = Color(0xFF111827);
  static const Color _mutedText = Color(0xFF64748B);

  static const double _gapAfterHeader = 16;
  static const double _gapBetweenSections = 16;
  static const double _cardRadius = 14;
  static const double _radius = 10;

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
          _errorMessage =
              decoded['message']?.toString() ?? 'Gagal memuat.';
        });
        return;
      }

      if (!mounted) return;

      final s = decoded['summary'] ?? {};
      final list = (decoded['data'] is List) ? decoded['data'] as List : [];

      setState(() {
        _total = int.tryParse(s['total']?.toString() ?? '0') ?? 0;
        _average =
            double.tryParse(s['average']?.toString() ?? '0') ?? 0;
        _highCount =
            int.tryParse(s['high_count']?.toString() ?? '0') ?? 0;
        _lowCount =
            int.tryParse(s['low_count']?.toString() ?? '0') ?? 0;

        _ratings = list
            .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e),
            )
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
      return '${date.day.toString().padLeft(2, '0')} '
          '${bulan[date.month - 1]} ${date.year}';
    } catch (_) {
      return iso;
    }
  }

  int _getStars(Map<String, dynamic> r) {
    return int.tryParse(r['stars']?.toString() ?? '0') ?? 0;
  }

  Color _ratingColor(int rating) {
    if (rating >= 4) return _successColor;
    if (rating == 3) return _warningColor;
    return _dangerColor;
  }

  Widget _buildStars(int rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star : Icons.star_border,
          color: _warningColor,
          size: size,
        );
      }),
    );
  }

  Widget _buildRatingBadge(BuildContext context, int rating) {
    final color = _ratingColor(rating);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            '$rating/5',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
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
        _snack('Rating berhasil dihapus.', error: false);
        _loadRatings();
      } else {
        String message = 'Gagal menghapus rating.';
        try {
          final decoded = jsonDecode(response.body);
          message = decoded['message']?.toString() ?? message;
        } catch (_) {}
        if (!mounted) return;
        _snack(message, error: true);
      }
    } catch (e) {
      if (!mounted) return;
      _snack('Error: $e', error: true);
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
        _snack('Rating berhasil disembunyikan.', error: false);
        _loadRatings();
      } else {
        if (!mounted) return;
        _snack('Gagal menyembunyikan rating.', error: true);
      }
    } catch (e) {
      if (!mounted) return;
      _snack('Error: $e', error: true);
    }
  }

  void _snack(String msg, {required bool error}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: error ? _dangerColor : _successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: RefreshIndicator(
        onRefresh: _loadRatings,
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

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: CircularProgressIndicator(color: _accent),
                      ),
                    )
                  else if (_errorMessage != null)
                    _buildError()
                  else ...[
                    _buildSummarySection(isMobile),
                    const SizedBox(height: _gapBetweenSections),
                    _buildFilterSection(isMobile),
                    const SizedBox(height: _gapBetweenSections),

                    if (_ratings.isEmpty)
                      _buildEmptyState()
                    else if (isMobile)
                      _buildMobileList()
                    else
                      _buildDesktopTable(),

                    if (_ratings.isNotEmpty) ...[
                      const SizedBox(height: _gapBetweenSections),
                      _buildPagination(),
                    ],
                  ],
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
          'Kelola Rating Mitra',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pantau dan kelola penilaian pelanggan terhadap mitra.',
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummarySection(bool isMobile) {
    final cards = [
      _summaryCard(
        title: 'Total Rating',
        value: '$_total',
        icon: Icons.rate_review_outlined,
        color: _infoColor,
      ),
      _summaryCard(
        title: 'Rata-rata',
        value: _average.toStringAsFixed(1),
        icon: Icons.star_rate_outlined,
        color: _warningColor,
      ),
      _summaryCard(
        title: 'Rating Positif',
        value: '$_highCount',
        icon: Icons.thumb_up_alt_outlined,
        color: _successColor,
      ),
      _summaryCard(
        title: 'Rating Rendah',
        value: '$_lowCount',
        icon: Icons.warning_amber_outlined,
        color: _dangerColor,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 10),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 10),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i != cards.length - 1) const SizedBox(width: 16),
        ],
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _tableBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.1,
                  ),
                ),
              ],
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
    final textTheme = Theme.of(context).textTheme;

    final dropdown = Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _tableBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          isExpanded: true,
          icon: const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: _headerText,
            ),
          ),
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: _cellText,
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _tableBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 18, color: _headerText),
          const SizedBox(width: 8),
          if (!isMobile) ...[
            Text(
              'Filter Rating:',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (isMobile)
            Expanded(child: dropdown)
          else
            SizedBox(width: 190, child: dropdown),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_ratings.length}',
              style: textTheme.labelMedium?.copyWith(
                color: _accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABLE (DESKTOP)
  // ============================================================

  Widget _buildDesktopTable() {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _tableBorder),
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
                    WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                headingRowHeight: 48,
                dataRowMinHeight: 56,
                dataRowMaxHeight: 56,
                columnSpacing: 24,
                horizontalMargin: 20,
                dividerThickness: 1,
                showBottomBorder: true,
                headingTextStyle: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: _headerText,
                ),
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
                      DataCell(
                        Text(
                          _code(r),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _cellText,
                          ),
                        ),
                      ),
                      DataCell(
                        _tableCell(_getNestedValue(r, 'mitra', ['name'])),
                      ),
                      DataCell(
                        _tableCell(
                            _getNestedValue(r, 'pelanggan', ['name'])),
                      ),
                      DataCell(
                        _tableCell(
                            _getNestedValue(r, 'job', ['tittle', 'title'])),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildStars(rating),
                            const SizedBox(width: 6),
                            Text(
                              '$rating',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _cellText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        _tableCell(
                            _formatTanggal(r['created_at']?.toString())),
                      ),
                      DataCell(
                        _pillButton(
                          icon: Icons.visibility_outlined,
                          label: 'Detail',
                          bgColor: const Color(0xFFF1F5F9),
                          fgColor: const Color(0xFF334155),
                          onTap: () => _showRatingDetail(r),
                        ),
                      ),
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
      style: const TextStyle(fontSize: 13, color: _cellText),
    );
  }

  Widget _pillButton({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color fgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: fgColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: fgColor,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE LIST
  // ============================================================

  Widget _buildMobileList() {
    return Column(
      children: _paginatedRatings.map((r) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _mobileRatingCard(r),
        );
      }).toList(),
    );
  }

  Widget _mobileRatingCard(Map<String, dynamic> r) {
    final rating = _getStars(r);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _tableBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _code(r),
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _cellText,
                  ),
                ),
              ),
              _buildRatingBadge(context, rating),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: _tableDivider),
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
            isLast: true,
          ),
          const SizedBox(height: 12),
          _buildStars(rating),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showRatingDetail(r),
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text(
                'Lihat Detail',
                style: TextStyle(fontSize: 12.5),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 11),
                foregroundColor: _purpleColor,
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_radius),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 8),
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: _mutedText),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _cellText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  Widget _buildPagination() {
    final total = _ratings.length;
    final totalPages = _totalPages;
    final startItem = (_currentPage - 1) * _itemsPerPage + 1;
    final endItem = (startItem + _itemsPerPage - 1).clamp(0, total);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _tableBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              'Menampilkan $startItem–$endItem dari $total ulasan',
              style: const TextStyle(
                fontSize: 12.5,
                color: _headerText,
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
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _tableBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _itemsPerPage,
                    isDense: true,
                    borderRadius: BorderRadius.circular(8),
                    icon: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: _headerText,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _cellText,
                      fontWeight: FontWeight.w600,
                    ),
                    items: _itemsPerPageOptions
                        .map(
                          (n) => DropdownMenuItem<int>(
                            value: n,
                            child: Text('$n / hal'),
                          ),
                        )
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
              const SizedBox(width: 12),
              _navButton(
                icon: Icons.chevron_left,
                enabled: _currentPage > 1,
                onTap: () => setState(() => _currentPage--),
              ),
              const SizedBox(width: 8),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Hal $_currentPage / $totalPages',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _navButton(
                icon: Icons.chevron_right,
                enabled: _currentPage < totalPages,
                onTap: () => setState(() => _currentPage++),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled
                  ? const Color(0xFFD1D5DB)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? const Color(0xFF374151)
                : const Color(0xFFD1D5DB),
          ),
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
      barrierDismissible: false,
      builder: (dialogContext) {
        final textTheme = Theme.of(dialogContext).textTheme;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HEADER
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(_radius),
                        ),
                        child: const Icon(
                          Icons.rate_review_outlined,
                          color: _accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Detail Rating',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _cellText,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(),
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: _headerText,
                        ),
                        splashRadius: 22,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // CONTENT
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailRow('ID Rating', _code(r)),
                          _detailRow(
                            'Nama Mitra',
                            _getNestedValue(r, 'mitra', ['name']),
                          ),
                          _detailRow(
                            'Nama Pelanggan',
                            _getNestedValue(r, 'pelanggan', ['name']),
                          ),
                          _detailRow(
                            'Layanan',
                            _getNestedValue(r, 'job', ['tittle', 'title']),
                          ),
                          _detailRow(
                            'Tanggal',
                            _formatTanggal(r['created_at']?.toString()),
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            'Rating',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _cellText,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildStars(rating, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                '$rating/5',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _cellText,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            'Komentar',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _cellText,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(_radius),
                              border: Border.all(color: _tableBorder),
                            ),
                            child: Text(
                              r['comment']?.toString() ?? '-',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF374151),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ACTIONS
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 46),
                            foregroundColor: const Color(0xFF374151),
                            side: const BorderSide(
                              color: Color(0xFFD1D5DB),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_radius),
                            ),
                          ),
                          child: const Text(
                            'Tutup',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _confirmHideRating(r);
                          },
                          icon: const Icon(
                            Icons.visibility_off_outlined,
                            size: 16,
                          ),
                          label: const Text(
                            'Sembunyikan',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 46),
                            foregroundColor: _warningColor,
                            side: const BorderSide(color: _warningColor),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_radius),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _confirmDeleteRating(r);
                          },
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text(
                            'Hapus',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 46),
                            backgroundColor: _dangerColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_radius),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
            width: 115,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: _mutedText),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _cellText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONFIRM HIDE
  // ============================================================

  void _confirmHideRating(Map<String, dynamic> r) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final textTheme = Theme.of(dialogContext).textTheme;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _warningColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(_radius),
                        ),
                        child: const Icon(
                          Icons.visibility_off_outlined,
                          color: _warningColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sembunyikan Rating',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _cellText,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(),
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: _headerText,
                        ),
                        splashRadius: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  const Text(
                    'Rating akan disembunyikan dari publik. Data tetap tersimpan.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Alasan (opsional)',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9CA3AF),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(_radius),
                        borderSide:
                            const BorderSide(color: _tableBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(_radius),
                        borderSide:
                            const BorderSide(color: _tableBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(_radius),
                        borderSide: const BorderSide(
                          color: _accent,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 46),
                            foregroundColor: const Color(0xFF374151),
                            side: const BorderSide(
                              color: Color(0xFFD1D5DB),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_radius),
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _hideRating(
                              r['id'],
                              reasonController.text.trim(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _warningColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 46),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_radius),
                            ),
                          ),
                          child: const Text(
                            'Sembunyikan',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // CONFIRM DELETE
  // ============================================================

  void _confirmDeleteRating(Map<String, dynamic> r) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final textTheme = Theme.of(dialogContext).textTheme;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _dangerColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(_radius),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: _dangerColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Hapus Rating',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _cellText,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(),
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: _headerText,
                        ),
                        splashRadius: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  const Text(
                    'Apakah Anda yakin ingin menghapus rating ini? Tindakan ini tidak dapat dibatalkan.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 46),
                            foregroundColor: const Color(0xFF374151),
                            side: const BorderSide(
                              color: Color(0xFFD1D5DB),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_radius),
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _deleteRating(r['id']);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _dangerColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 46),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_radius),
                            ),
                          ),
                          child: const Text(
                            'Hapus',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
              Icons.rate_review_outlined,
              size: 34,
              color: _accent.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Tidak ada rating',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _mutedText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Belum ada rating yang sesuai dengan filter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: _dangerColor,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _dangerColor,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadRatings,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_radius),
              ),
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
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
    );
  }
}