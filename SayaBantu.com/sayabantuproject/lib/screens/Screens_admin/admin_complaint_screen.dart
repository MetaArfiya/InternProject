import 'dart:convert';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class AdminComplaintScreen extends StatefulWidget {
  const AdminComplaintScreen({super.key});

  @override
  State<AdminComplaintScreen> createState() =>
      _AdminComplaintScreenState();
}

class _AdminComplaintScreenState extends State<AdminComplaintScreen> {
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

  List<Map<String, dynamic>> _complaints = [];

  Map<String, int> _summary = {
    'total': 0,
    'menunggu': 0,
    'diproses': 0,
    'selesai': 0,
    'ditolak': 0,
  };

  String _selectedFilter = 'Semua';

  final List<String> _filters = [
    'Semua',
    'Menunggu',
    'Diproses',
    'Selesai',
    'Ditolak',
  ];

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();
    debugPrint('🔥 ADMIN COMPLAINT SCREEN INIT');
    _loadComplaints();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadComplaints() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      debugPrint('🔥 LOAD COMPLAINTS DIPANGGIL');

      final response = await ApiService.get('/admin/complaints');

      debugPrint('📢 ADMIN COMPLAINTS: ${response.statusCode}');
      debugPrint('📢 BODY: ${response.body}');

      if (response.statusCode != 200) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat (${response.statusCode})';
        });
        return;
      }

      final decoded = jsonDecode(response.body);

      if (decoded['success'] != true) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage =
              decoded['message']?.toString() ?? 'Gagal memuat.';
        });
        return;
      }

      final summaryData = decoded['summary'] ?? {};

      final List<dynamic> list = decoded['data'] is List
          ? decoded['data'] as List<dynamic>
          : <dynamic>[];

      final complaints = list
          .whereType<Map>()
          .map<Map<String, dynamic>>(
            (e) => Map<String, dynamic>.from(e),
          )
          .toList();

      debugPrint('🔥 JUMLAH COMPLAINT: ${complaints.length}');

      if (!mounted) return;

      setState(() {
        _summary = {
          'total': int.tryParse(
                summaryData['total']?.toString() ?? '0',
              ) ??
              0,
          'menunggu': int.tryParse(
                summaryData['menunggu']?.toString() ?? '0',
              ) ??
              0,
          'diproses': int.tryParse(
                summaryData['diproses']?.toString() ?? '0',
              ) ??
              0,
          'selesai': int.tryParse(
                summaryData['selesai']?.toString() ?? '0',
              ) ??
              0,
          'ditolak': int.tryParse(
                summaryData['ditolak']?.toString() ?? '0',
              ) ??
              0,
        };

        _complaints = complaints;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ ERROR ADMIN COMPLAINTS: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  Future<void> _updateComplaintStatus(
    dynamic id,
    String newStatus, {
    String? note,
  }) async {
    try {
      final response = await ApiService.put(
        '/admin/complaints/$id',
        {
          'status': newStatus,
          if (note != null && note.isNotEmpty) 'admin_response': note,
        },
      );

      debugPrint(
        '📢 PUT /admin/complaints/$id → ${response.statusCode}',
      );
      debugPrint('📢 BODY: ${response.body}');

      if (response.statusCode == 200) {
        if (!mounted) return;

        _showSnack(
          'Status pengaduan diubah menjadi $newStatus.',
        );

        await _loadComplaints();
      } else {
        String message = 'Gagal mengubah status.';

        try {
          final decoded = jsonDecode(response.body);
          message = decoded['message']?.toString() ?? message;
        } catch (_) {}

        if (!mounted) return;
        _showSnack(message, error: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error: $e', error: true);
    }
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? _dangerColor : _successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // HELPERS
  // ============================================================

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

  String _code(Map<String, dynamic> c) {
    final id = c['id'];
    if (id is int) return 'PGD-${id.toString().padLeft(3, '0')}';
    return 'PGD-${id.toString()}';
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<Map<String, dynamic>> get _filteredComplaints {
    if (_selectedFilter == 'Semua') return _complaints;

    return _complaints
        .where((c) => c['status']?.toString() == _selectedFilter)
        .toList();
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
                    _buildStatistics(isMobile, isTablet),
                    const SizedBox(height: _gapBetweenSections),
                    _buildComplaintSection(isMobile, isTablet),
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
          'Pengaduan',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kelola pengaduan dari mitra dan pelanggan.',
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatistics(bool isMobile, bool isTablet) {
    final cards = [
      _StatData(
        title: 'Menunggu',
        value: '${_summary['menunggu'] ?? 0}',
        subtitle: 'Pengaduan baru',
        icon: Icons.hourglass_empty_rounded,
        color: _warningColor,
      ),
      _StatData(
        title: 'Diproses',
        value: '${_summary['diproses'] ?? 0}',
        subtitle: 'Sedang ditangani',
        icon: Icons.sync_rounded,
        color: _infoColor,
      ),
      _StatData(
        title: 'Selesai',
        value: '${_summary['selesai'] ?? 0}',
        subtitle: 'Telah diselesaikan',
        icon: Icons.check_circle_outline_rounded,
        color: _successColor,
      ),
      _StatData(
        title: 'Ditolak',
        value: '${_summary['ditolak'] ?? 0}',
        subtitle: 'Pengaduan ditolak',
        icon: Icons.cancel_outlined,
        color: _dangerColor,
      ),
    ];

    // MOBILE — 2 kolom x 2
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard(cards[0])),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard(cards[1])),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildStatCard(cards[2])),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard(cards[3])),
            ],
          ),
        ],
      );
    }

    // TABLET — 2 kolom x 2
    if (isTablet) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard(cards[0])),
              const SizedBox(width: 14),
              Expanded(child: _buildStatCard(cards[1])),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildStatCard(cards[2])),
              const SizedBox(width: 14),
              Expanded(child: _buildStatCard(cards[3])),
            ],
          ),
        ],
      );
    }

    // DESKTOP — 4 kolom
    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: _buildStatCard(cards[i])),
          if (i != cards.length - 1) const SizedBox(width: 16),
        ],
      ],
    );
  }

  Widget _buildStatCard(_StatData data) {
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
              color: data.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(data.icon, color: data.color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.title,
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
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF94A3B8),
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
  // COMPLAINT SECTION
  // ============================================================

  Widget _buildComplaintSection(bool isMobile, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _tableBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // FILTER BAR — baris tersendiri di atas judul
          // ------------------------------------------------------
          _buildFilterBar(context),

          const SizedBox(height: 14),
          const Divider(height: 1, color: _tableDivider),
          const SizedBox(height: 14),

          // ------------------------------------------------------
          // SECTION TITLE
          // ------------------------------------------------------
          _buildSectionTitle(context),

          const SizedBox(height: 16),
          const Divider(height: 1, color: _tableDivider),
          const SizedBox(height: 14),

          // ------------------------------------------------------
          // LIST / TABLE
          // ------------------------------------------------------
          if (_filteredComplaints.isEmpty)
            _buildEmptyState(context)
          else if (isMobile)
            Column(
              children: _filteredComplaints
                  .map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildComplaintCard(context, c),
                    ),
                  )
                  .toList(),
            )
          else
            _buildDesktopTable(context, isTablet),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER BAR — label di kiri, dropdown, badge jumlah di kanan
  // ============================================================

  Widget _buildFilterBar(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.filter_list_rounded,
          size: 18,
          color: _headerText,
        ),
        const SizedBox(width: 8),
        const Text(
          'Filter Status:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _mutedText,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 160,
          child: _buildFilterDropdown(context),
        ),
        const Spacer(),
        // Badge jumlah data yang tampil
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_filteredComplaints.length}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _accent,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daftar Pengaduan',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _cellText,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_filteredComplaints.length} pengaduan ditampilkan',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _mutedText,
              ),
        ),
      ],
    );
  }

  // ============================================================
  // FILTER DROPDOWN
  // ============================================================

  Widget _buildFilterDropdown(BuildContext context) {
    return Container(
      height: 40,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: _tableBorder),
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: _headerText,
          ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _cellText,
                fontWeight: FontWeight.w500,
              ),
          items: _filters
              .map(
                (f) => DropdownMenuItem<String>(
                  value: f,
                  child: Text(
                    f,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _selectedFilter = v);
          },
        ),
      ),
    );
  }

  // ============================================================
  // DESKTOP TABLE
  // ============================================================

  Widget _buildDesktopTable(BuildContext context, bool isTablet) {
    final complaints = _filteredComplaints;

    debugPrint('🖥️ DESKTOP TABLE: ${complaints.length} DATA');

    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: _tableBorder),
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: isTablet ? 900 : 1100,
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(const Color(0xFFF9FAFB)),
              headingRowHeight: 48,
              dataRowMinHeight: 74,
              dataRowMaxHeight: 100,
              columnSpacing: isTablet ? 18 : 24,
              horizontalMargin: 14,
              dividerThickness: 0.6,
              headingTextStyle: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: _headerText,
              ),
              columns: const [
                DataColumn(label: Text('Pengaduan')),
                DataColumn(label: Text('Pengadu')),
                DataColumn(label: Text('Pekerjaan')),
                DataColumn(label: Text('Kategori')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Aksi')),
              ],
              rows: complaints.map((c) {
                return DataRow(
                  cells: [
                    // PENGADUAN
                    DataCell(
                      SizedBox(
                        width: 105,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _code(c),
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: _cellText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTanggal(
                                c['created_at']?.toString(),
                              ),
                              style: textTheme.labelSmall?.copyWith(
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // PENGADU
                    DataCell(
                      SizedBox(
                        width: 135,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getNestedValue(c, 'user', ['name']),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _cellText,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              c['user_role']?.toString() ?? '-',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelSmall?.copyWith(
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // PEKERJAAN
                    DataCell(
                      SizedBox(
                        width: 160,
                        child: Text(
                          _getNestedValue(
                            c,
                            'job',
                            ['tittle', 'title'],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: _cellText,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),

                    // KATEGORI
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: Text(
                          c['category']?.toString() ?? '-',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: _cellText,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),

                    // STATUS
                    DataCell(
                      _buildStatusBadge(context, c['status']?.toString() ?? '-'),
                    ),

                    // AKSI
                    DataCell(_buildActionButtons(context, c)),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE CARD
  // ============================================================

  Widget _buildComplaintCard(
    BuildContext context,
    Map<String, dynamic> c,
  ) {
    final status = c['status']?.toString() ?? '-';
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _tableBorder),
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
                      _code(c),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _cellText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatTanggal(c['created_at']?.toString()),
                      style: textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(context, status),
            ],
          ),

          const SizedBox(height: 13),
          const Divider(height: 1, color: _tableDivider),
          const SizedBox(height: 13),

          _mobileInfoRow(
            Icons.person_outline_rounded,
            'Pengadu',
            '${_getNestedValue(c, 'user', ['name'])} (${c['user_role'] ?? '-'})',
          ),

          _mobileInfoRow(
            Icons.work_outline_rounded,
            'Pekerjaan',
            _getNestedValue(c, 'job', ['tittle', 'title']),
          ),

          _mobileInfoRow(
            Icons.category_outlined,
            'Kategori',
            c['category']?.toString() ?? '-',
          ),

          const SizedBox(height: 5),

          Text(
            'Pengaduan',
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: _cellText,
            ),
          ),

          const SizedBox(height: 6),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _tableBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c['title']?.toString() ?? '-',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _cellText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  c['description']?.toString() ?? '-',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    height: 1.45,
                    color: _mutedText,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          _buildActionButtons(context, c),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE INFO ROW
  // ============================================================

  Widget _mobileInfoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 14, color: _mutedText),
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 66,
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: _mutedText,
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Text(
              ':',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color color;

    switch (status) {
      case 'Menunggu':
        color = _warningColor;
        break;
      case 'Diproses':
        color = _infoColor;
        break;
      case 'Selesai':
        color = _successColor;
        break;
      case 'Ditolak':
        color = _dangerColor;
        break;
      default:
        color = _mutedText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
      ),
    );
  }

  // ============================================================
  // ACTION BUTTONS
  // ============================================================

  Widget _buildActionButtons(
    BuildContext context,
    Map<String, dynamic> c,
  ) {
    final status = c['status']?.toString() ?? '';

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _pillButton(
          context: context,
          icon: Icons.visibility_outlined,
          label: 'Detail',
          bgColor: const Color(0xFFF1F5F9),
          fgColor: const Color(0xFF334155),
          onTap: () => _showComplaintDetail(c),
        ),

        if (status == 'Menunggu')
          _pillButton(
            context: context,
            icon: Icons.play_arrow_outlined,
            label: 'Proses',
            bgColor: _accent,
            fgColor: Colors.white,
            onTap: () => _updateComplaintStatus(c['id'], 'Diproses'),
          ),

        if (status == 'Diproses')
          _pillButton(
            context: context,
            icon: Icons.check_circle_outline,
            label: 'Selesai',
            bgColor: _successColor,
            fgColor: Colors.white,
            onTap: () => _updateComplaintStatus(c['id'], 'Selesai'),
          ),

        if (status == 'Menunggu' || status == 'Diproses')
          _pillButton(
            context: context,
            icon: Icons.cancel_outlined,
            label: 'Tolak',
            bgColor: _dangerColor.withOpacity(0.10),
            fgColor: _dangerColor,
            onTap: () => _confirmReject(c),
          ),
      ],
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
  // DETAIL DIALOG
  // ============================================================

  void _showComplaintDetail(Map<String, dynamic> c) {
    final responseController = TextEditingController(
      text: c['admin_response']?.toString() ?? '',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final textTheme = Theme.of(dialogContext).textTheme;
        final status = c['status']?.toString() ?? '';

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
                          Icons.report_problem_outlined,
                          color: _accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Detail Pengaduan',
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

                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailRow('ID Pengaduan', _code(c)),
                          _detailRow(
                            'Tanggal',
                            _formatTanggal(c['created_at']?.toString()),
                          ),
                          _detailRow(
                            'Pengadu',
                            _getNestedValue(c, 'user', ['name']),
                          ),
                          _detailRow(
                            'Role',
                            c['user_role']?.toString() ?? '-',
                          ),
                          _detailRow(
                            'Kategori',
                            c['category']?.toString() ?? '-',
                          ),
                          _detailRow(
                            'Pekerjaan',
                            _getNestedValue(
                              c,
                              'job',
                              ['tittle', 'title'],
                            ),
                          ),
                          _detailRow(
                            'Judul',
                            c['title']?.toString() ?? '-',
                          ),
                          _detailRow('Status', status),

                          const SizedBox(height: 12),

                          _detailSectionBox(
                            title: 'Keterangan Pengaduan',
                            child: Text(
                              c['description']?.toString() ?? '-',
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),

                          if ((c['admin_response']?.toString() ?? '')
                              .isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _detailSectionBox(
                              title: 'Tanggapan Admin',
                              backgroundColor:
                                  _successColor.withOpacity(0.08),
                              borderColor:
                                  _successColor.withOpacity(0.25),
                              titleColor: const Color(0xFF065F46),
                              child: Text(
                                c['admin_response'].toString(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                            ),
                          ],

                          if (status == 'Menunggu' ||
                              status == 'Diproses') ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Tanggapan / Catatan Admin',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _cellText,
                              ),
                            ),
                            const SizedBox(height: 7),
                            TextField(
                              controller: responseController,
                              maxLines: 3,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText:
                                    'Tulis tanggapan untuk pengadu...',
                                hintStyle: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF9CA3AF),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(_radius),
                                  borderSide: const BorderSide(
                                    color: _tableBorder,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(_radius),
                                  borderSide: const BorderSide(
                                    color: _tableBorder,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(_radius),
                                  borderSide: const BorderSide(
                                    color: _accent,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding:
                                    const EdgeInsets.all(11),
                              ),
                            ),
                          ],
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
                            foregroundColor:
                                const Color(0xFF374151),
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

                      if (status == 'Menunggu') ...[
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              _updateComplaintStatus(
                                c['id'],
                                'Diproses',
                                note: responseController.text.trim(),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 46),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(_radius),
                              ),
                            ),
                            child: const Text(
                              'Proses',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],

                      if (status == 'Diproses') ...[
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              _updateComplaintStatus(
                                c['id'],
                                'Selesai',
                                note: responseController.text.trim(),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _successColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 46),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(_radius),
                              ),
                            ),
                            child: const Text(
                              'Tandai Selesai',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
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
  // DETAIL SECTION BOX
  // ============================================================

  Widget _detailSectionBox({
    required String title,
    required Widget child,
    Color backgroundColor = const Color(0xFFF9FAFB),
    Color borderColor = _tableBorder,
    Color titleColor = _cellText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: borderColor),
          ),
          child: child,
        ),
      ],
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

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
                color: _mutedText,
              ),
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
  // KONFIRMASI TOLAK
  // ============================================================

  void _confirmReject(Map<String, dynamic> c) {
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
                          color: _dangerColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(_radius),
                        ),
                        child: const Icon(
                          Icons.cancel_outlined,
                          color: _dangerColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tolak Pengaduan?',
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
                    'Apakah kamu yakin ingin menolak pengaduan ini?',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Color(0xFF374151),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Alasan penolakan...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9CA3AF),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(_radius),
                        borderSide: const BorderSide(
                          color: _tableBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(_radius),
                        borderSide: const BorderSide(
                          color: _tableBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(_radius),
                        borderSide: const BorderSide(
                          color: _accent,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(11),
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
                            foregroundColor:
                                const Color(0xFF374151),
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
                            _updateComplaintStatus(
                              c['id'],
                              'Ditolak',
                              note: reasonController.text.trim(),
                            );
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
                            'Tolak',
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
  // EMPTY STATE
  // ============================================================

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
              color: _accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 34,
              color: _accent.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Tidak ada pengaduan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _mutedText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Belum ada pengaduan dengan status tersebut.',
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

  // ============================================================
  // ERROR STATE
  // ============================================================

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
            onPressed: _loadComplaints,
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
// DATA HELPER
// ============================================================

class _StatData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}