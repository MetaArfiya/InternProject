import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/complaint_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';

class PartnerComplaintScreen extends StatefulWidget {
  const PartnerComplaintScreen({super.key});

  @override
  State<PartnerComplaintScreen> createState() =>
      _PartnerComplaintScreenState();
}

class _PartnerComplaintScreenState extends State<PartnerComplaintScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  List<ComplaintModel> _complaints = [];

  Map<String, int> _summary = {
    'total': 0,
    'menunggu': 0,
    'diproses': 0,
    'selesai': 0,
    'ditolak': 0,
  };

  String _selectedFilter = 'Semua';

  int _currentPage = 1;
  int _rowsPerPage = 10;
  static const List<int> _rowsPerPageOptions = [10, 25, 50, 100];

  // ============================================================
  // DESIGN TOKENS
  // ============================================================

  static const double _buttonFontSize = 13;
  static const double _fieldFontSize = 13;
  static const double _smallRadius = 12;

  // ✅ dari orange → teal
  static const Color _accent = AppColors.primaryTeal;
  static const Color _tableBorder = Color(0xFFE5E7EB);
  static const Color _tableDivider = Color(0xFFF3F4F6);
  static const Color _headerText = AppColors.grey500;
  static const Color _cellText = AppColors.grey900;

  static const double _gapAfterHeader = 16;
  static const double _gapBetweenSections = 16;
  static const double _gapTitleToContent = 16;

  final List<String> _categories = const [
    'Aplikasi',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  // ============================================================
  // LOAD COMPLAINTS
  // ============================================================

  Future<void> _loadComplaints() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await ApiService.get('/complaints/my');

      if (response.statusCode != 200) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat data (${response.statusCode}).';
        });
        return;
      }

      final decoded = jsonDecode(response.body);

      if (decoded['success'] != true) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage =
              decoded['message']?.toString() ?? 'Gagal memuat data.';
        });
        return;
      }

      if (!mounted) return;

      setState(() {
        final s = decoded['summary'] ?? {};

        _summary = {
          'total': _parseIntSafe(s['total']),
          'menunggu': _parseIntSafe(s['menunggu']),
          'diproses': _parseIntSafe(s['diproses']),
          'selesai': _parseIntSafe(s['selesai']),
          'ditolak': _parseIntSafe(s['ditolak']),
        };

        _complaints = decoded['data'] is List
            ? (decoded['data'] as List)
                .map((e) => ComplaintModel.fromJson(e))
                .toList()
            : [];

        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ ERROR: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  int _parseIntSafe(dynamic value) {
    if (value == null) return 0;

    final parsed = int.tryParse(value.toString());
    if (parsed != null && parsed >= 0) return parsed;

    final asDouble = double.tryParse(value.toString());
    if (asDouble != null && asDouble.isFinite && asDouble >= 0) {
      return asDouble.toInt();
    }

    return 0;
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<ComplaintModel> get _filteredComplaints {
    if (_selectedFilter == 'Semua') return _complaints;
    return _complaints.where((c) => c.status == _selectedFilter).toList();
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  int get _totalPages {
    if (_filteredComplaints.isEmpty) return 1;
    if (_rowsPerPage <= 0) return 1;

    final total = (_filteredComplaints.length / _rowsPerPage).ceil();

    if (!total.isFinite || total < 1) return 1;

    return total;
  }

  List<ComplaintModel> get _pagedComplaints {
    if (_rowsPerPage <= 0) return _filteredComplaints;

    final list = _filteredComplaints;
    final start = (_currentPage - 1) * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, list.length);

    if (start < 0 || start >= list.length) return [];
    return list.sublist(start, end);
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() => _currentPage = page);
  }

  void _changeRowsPerPage(int value) {
    if (value <= 0) return;
    setState(() {
      _rowsPerPage = value;
      _currentPage = 1;
    });
  }

  // ============================================================
  // STATUS
  // ============================================================

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Menunggu':
        return _accent; // teal
      case 'Diproses':
        return AppColors.primaryTeal; // ← dari ungu
      case 'Selesai':
        return const Color(0xFF16A34A); // hijau
      case 'Ditolak':
        return const Color(0xFFDC2626); // merah
      default:
        return AppColors.grey500;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Menunggu':
        return Icons.access_time;
      case 'Diproses':
        return Icons.sync;
      case 'Selesai':
        return Icons.check_circle_outline;
      case 'Ditolak':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Widget _statusBadge(BuildContext context, String status) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(status), size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
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
      color: AppColors.sectionAltLight, // ← mint muda
      child: RefreshIndicator(
        onRefresh: _loadComplaints,
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
                  _buildHeader(context, isMobile),

                  const SizedBox(height: _gapAfterHeader),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: CircularProgressIndicator(color: _accent),
                      ),
                    )
                  else if (_errorMessage != null)
                    _buildError(context)
                  else ...[
                    _buildSummary(context, isMobile),
                    const SizedBox(height: _gapBetweenSections),
                    _buildFilterSection(context, isMobile),
                    const SizedBox(height: _gapBetweenSections),
                    _buildSectionTitle(context),
                    const SizedBox(height: _gapTitleToContent),

                    if (_filteredComplaints.isEmpty)
                      _buildEmptyState(context)
                    else if (isMobile)
                      Column(
                        children: _filteredComplaints
                            .map((c) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 12),
                                  child: _buildComplaintCard(context, c),
                                ))
                            .toList(),
                      )
                    else
                      _buildDesktopTable(context),
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
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context, bool isMobile) {
    final titleAndSubtitle = const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lapor Masalah',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.grey900,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Laporkan bug atau kirim saran untuk pengembangan aplikasi.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.grey500,
          ),
        ),
      ],
    );

    final button = ElevatedButton.icon(
      onPressed: _showCreateComplaintDialog,
      icon: const Icon(Icons.add, size: 18),
      label: Text(
        isMobile ? 'Lapor' : 'Lapor Sekarang',
        style: const TextStyle(
          fontSize: _buttonFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent, // ← teal
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_smallRadius),
        ),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleAndSubtitle,
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: button),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleAndSubtitle),
        const SizedBox(width: 20),
        button,
      ],
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(BuildContext context) {
    return const Text(
      'Riwayat Laporan',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.grey900,
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary(BuildContext context, bool isMobile) {
    final cards = [
      _summaryCard(
        title: 'Total',
        value: '${_summary['total'] ?? 0}',
        icon: Icons.report_problem_outlined,
        color: AppColors.primaryTeal, // ← dari biru
      ),
      _summaryCard(
        title: 'Menunggu',
        value: '${_summary['menunggu'] ?? 0}',
        icon: Icons.access_time,
        color: const Color(0xFFF59E0B), // amber
      ),
      _summaryCard(
        title: 'Diproses',
        value: '${_summary['diproses'] ?? 0}',
        icon: Icons.sync,
        color: AppColors.primaryTeal, // ← dari ungu
      ),
      _summaryCard(
        title: 'Selesai',
        value: '${_summary['selesai'] ?? 0}',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF16A34A),
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha:0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkTeal.withValues(alpha:0.03),
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
              color: color.withValues(alpha:0.12),
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
                    color: AppColors.grey500,
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
                    color: AppColors.grey900,
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
  // FILTER BAR
  // ============================================================

  Widget _buildFilterSection(BuildContext context, bool isMobile) {
    const filters = [
      'Semua',
      'Menunggu',
      'Diproses',
      'Selesai',
      'Ditolak',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_smallRadius),
        border: Border.all(color: _tableBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 18, color: AppColors.grey500),
          const SizedBox(width: 8),
          if (!isMobile) ...[
            const Text(
              'Filter Status:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.grey700,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _tableBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFilter,
                isDense: true,
                icon: const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: AppColors.grey500,
                  ),
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey900,
                  fontSize: 13,
                ),
                items: filters.map((filter) {
                  return DropdownMenuItem<String>(
                    value: filter,
                    child: Text(filter),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedFilter = value;
                    _currentPage = 1;
                  });
                },
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha:0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_filteredComplaints.length}',
              style: const TextStyle(
                color: _accent,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE — CARD
  // ============================================================

  Widget _buildComplaintCard(
    BuildContext context,
    ComplaintModel complaint,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha:0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint.code,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _cellText,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      complaint.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _cellText,
                        height: 1.3,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(context, complaint.status),
            ],
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha:0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              complaint.category,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _accent, // ← teal
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: _tableDivider),
          const SizedBox(height: 12),

          _infoRow(
            Icons.calendar_today_outlined,
            'Tanggal',
            complaint.formattedDate,
          ),

          const SizedBox(height: 10),

          Text(
            complaint.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.grey700,
              height: 1.45,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showComplaintDetail(complaint),
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text(
                'Lihat Detail',
                style: TextStyle(fontSize: 12.5),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 11),
                foregroundColor: _accent, // ← dari ungu
                side: const BorderSide(color: AppColors.grey300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.grey400),
        const SizedBox(width: 8),
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.grey600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _cellText,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DESKTOP TABLE
  // ============================================================

  Widget _buildDesktopTable(BuildContext context) {
    final rows = _pagedComplaints;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _tableBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTableHeaderRow(context),
          const Divider(height: 1, thickness: 1, color: _tableDivider),

          for (int i = 0; i < rows.length; i++) ...[
            _buildTableDataRow(context, rows[i]),
            if (i != rows.length - 1)
              const Divider(height: 1, thickness: 1, color: _tableDivider),
          ],

          const Divider(height: 1, thickness: 1, color: _tableDivider),
          _buildTableFooter(context),
        ],
      ),
    );
  }

  Widget _buildTableHeaderRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(flex: 2, child: _headerCell(context, 'ID')),
          Expanded(flex: 4, child: _headerCell(context, 'Judul Laporan')),
          Expanded(flex: 3, child: _headerCell(context, 'Kategori')),
          Expanded(flex: 2, child: _headerCell(context, 'Tanggal')),
          Expanded(flex: 3, child: _headerCell(context, 'Status')),
          Expanded(flex: 2, child: _headerCell(context, 'Aksi')),
        ],
      ),
    );
  }

  Widget _headerCell(BuildContext context, String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w500,
        color: _headerText,
        fontSize: 13,
      ),
    );
  }

  Widget _buildTableDataRow(
    BuildContext context,
    ComplaintModel complaint,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              complaint.code,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: _cellText,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              complaint.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _cellText,
                height: 1.3,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              complaint.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _cellText,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              complaint.formattedDate,
              style: const TextStyle(
                color: _cellText,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _statusBadge(context, complaint.status),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _pillButton(
                context: context,
                icon: Icons.visibility_outlined,
                label: 'Detail',
                bgColor: AppColors.grey100,
                fgColor: AppColors.grey700,
                onTap: () => _showComplaintDetail(complaint),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillButton({
    required BuildContext context,
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
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: fgColor,
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
  // TABLE FOOTER
  // ============================================================

  Widget _buildTableFooter(BuildContext context) {
    final total = _filteredComplaints.length;
    final totalPages = _totalPages;

    final start = total == 0 ? 0 : ((_currentPage - 1) * _rowsPerPage) + 1;
    final end = total == 0
        ? 0
        : (_currentPage * _rowsPerPage).clamp(0, total);

    final safePage = _currentPage.clamp(1, totalPages);

    final canPrev = safePage > 1;
    final canNext = safePage < totalPages;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text(
            'Menampilkan $start–$end dari $total aktivitas',
            style: const TextStyle(
              color: _headerText,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _buildRowsPerPageDropdown(context),
              const SizedBox(width: 12),
              _navButton(
                icon: Icons.chevron_left,
                enabled: canPrev,
                onTap: () => _goToPage(safePage - 1),
              ),
              const SizedBox(width: 8),
              _pageIndicator(context, safePage, totalPages),
              const SizedBox(width: 8),
              _navButton(
                icon: Icons.chevron_right,
                enabled: canNext,
                onTap: () => _goToPage(safePage + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRowsPerPageDropdown(BuildContext context) {
    return Container(
      height: 32,
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
          icon: const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppColors.grey500,
            ),
          ),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.grey900,
            fontSize: 12,
          ),
          items: _rowsPerPageOptions.map((value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text('$value / hal'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) _changeRowsPerPage(value);
          },
        ),
      ),
    );
  }

  Widget _navButton({
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled ? AppColors.grey300 : AppColors.grey200,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.grey700 : AppColors.grey300,
          ),
        ),
      ),
    );
  }

  Widget _pageIndicator(
    BuildContext context,
    int page,
    int totalPages,
  ) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha:0.20), // ← dari ungu
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Hal $page / $totalPages',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.primaryTeal, // ← teal
          fontSize: 12,
        ),
      ),
    );
  }

  // ============================================================
  // CREATE COMPLAINT DIALOG
  // ============================================================

  void _showCreateComplaintDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    String selectedCategory = _categories.first;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha:0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.report_problem_outlined,
                              color: _accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Lapor Masalah',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.grey900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.pop(dialogContext),
                            icon: const Icon(
                              Icons.close,
                              size: 20,
                              color: AppColors.grey500,
                            ),
                            splashRadius: 22,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Info box → mint soft
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.mint.withValues(alpha:0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primaryTeal
                                        .withValues(alpha:0.20),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: AppColors.primaryTeal,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Gunakan form ini untuk melaporkan bug atau memberi saran tentang aplikasi.',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.darkTeal,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 14),

                              DropdownButtonFormField<String>(
                                initialValue: selectedCategory,
                                isExpanded: true,
                                decoration: _inputDecoration('Kategori'),
                                style: const TextStyle(
                                  fontSize: _fieldFontSize,
                                  color: AppColors.grey900,
                                ),
                                items: _categories.map((c) {
                                  return DropdownMenuItem<String>(
                                    value: c,
                                    child: Text(c),
                                  );
                                }).toList(),
                                onChanged: isSubmitting
                                    ? null
                                    : (value) {
                                        if (value == null) return;
                                        setDialogState(
                                            () => selectedCategory = value);
                                      },
                              ),

                              const SizedBox(height: 14),

                              TextField(
                                controller: titleController,
                                enabled: !isSubmitting,
                                style: const TextStyle(
                                  fontSize: _fieldFontSize,
                                ),
                                decoration: _inputDecoration(
                                  'Judul Laporan',
                                  hint:
                                      'Contoh: Tombol kirim tawaran tidak berfungsi',
                                ),
                              ),

                              const SizedBox(height: 14),

                              TextField(
                                controller: descriptionController,
                                enabled: !isSubmitting,
                                maxLines: 5,
                                style: const TextStyle(
                                  fontSize: _fieldFontSize,
                                ),
                                decoration: _inputDecoration(
                                  'Deskripsi',
                                  hint:
                                      'Jelaskan detail masalah atau saran Anda...',
                                ).copyWith(alignLabelWithHint: true),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSubmitting
                                  ? null                                  : () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 46),
                                foregroundColor: AppColors.grey700,
                                side: const BorderSide(
                                  color: AppColors.grey300,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Batal',
                                style: TextStyle(
                                  fontSize: _buttonFontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      final title =
                                          titleController.text.trim();
                                      final desc =
                                          descriptionController.text.trim();

                                      if (title.isEmpty || desc.isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Judul dan deskripsi harus diisi.',
                                            ),
                                            backgroundColor:
                                                Color(0xFFF59E0B),
                                          ),
                                        );
                                        return;
                                      }

                                      setDialogState(
                                          () => isSubmitting = true);

                                      final success = await _submitComplaint(
                                        category: selectedCategory,
                                        title: title,
                                        description: desc,
                                      );

                                      if (!dialogContext.mounted) return;

                                      if (success) {
                                        Navigator.pop(dialogContext);
                                        _loadComplaints();
                                      } else {
                                        setDialogState(
                                            () => isSubmitting = false);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent, // ← teal
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 46),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Kirim Laporan',
                                      style: TextStyle(
                                        fontSize: _buttonFontSize,
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
      },
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _tableBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _tableBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
      labelStyle: const TextStyle(
        fontSize: _fieldFontSize,
        color: AppColors.grey600,
      ),
      hintStyle: const TextStyle(
        fontSize: _fieldFontSize,
        color: AppColors.grey400,
      ),
    );
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<bool> _submitComplaint({
    required String category,
    required String title,
    required String description,
  }) async {
    try {
      final body = {
        'category': category,
        'title': title,
        'description': description,
      };

      final response = await ApiService.post('/complaints', body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan berhasil dikirim. Terima kasih!'),
            backgroundColor: AppColors.primaryTeal, // ← teal
          ),
        );
        return true;
      }

      String message = 'Gagal mengirim laporan.';
      try {
        final decoded = jsonDecode(response.body);
        message = decoded['message']?.toString() ?? message;
      } catch (_) {}

      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      return false;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      return false;
    }
  }

  // ============================================================
  // DETAIL DIALOG
  // ============================================================

  void _showComplaintDetail(ComplaintModel complaint) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha:0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: _accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Detail Laporan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.grey900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: AppColors.grey500,
                        ),
                        splashRadius: 22,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailRow('ID Laporan', complaint.code),
                          _detailRow('Kategori', complaint.category),
                          _detailRow('Tanggal', complaint.formattedDate),
                          _detailRow('Judul', complaint.title),
                          const SizedBox(height: 12),
                          _sectionLabel('Deskripsi'),
                          const SizedBox(height: 6),
                          _detailBox(complaint.description),
                          const SizedBox(height: 16),
                          _sectionLabel('Tanggapan Admin'),
                          const SizedBox(height: 6),
                          _detailBox(
                            complaint.adminResponse ??
                                'Belum ada tanggapan dari admin.',
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text(
                                'Status: ',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.grey700,
                                ),
                              ),
                              _statusBadge(dialogContext, complaint.status),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.grey800,
          ),
        ),
      ],
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
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.grey600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _tableBorder),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.grey700,
          height: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // ERROR & EMPTY
  // ============================================================

  Widget _buildError(BuildContext context) {
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
            Icons.error_outline,
            size: 48,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFDC2626),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadComplaints,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent, // ← teal
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

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha:0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.report_problem_outlined,
              size: 34,
              color: _accent.withValues(alpha:0.7),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum ada laporan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }
}