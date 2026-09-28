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

      final response =
          await ApiService.get('/admin/complaints');

      debugPrint(
        '📢 ADMIN COMPLAINTS: ${response.statusCode}',
      );
      debugPrint(
        '📢 BODY: ${response.body}',
      );

      if (response.statusCode != 200) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage =
              'Gagal memuat (${response.statusCode})';
        });

        return;
      }

      final decoded = jsonDecode(response.body);

      if (decoded['success'] != true) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage =
              decoded['message']?.toString() ??
                  'Gagal memuat.';
        });

        return;
      }

      final summaryData =
          decoded['summary'] ?? {};

      final List<dynamic> list =
          decoded['data'] is List
              ? decoded['data'] as List<dynamic>
              : <dynamic>[];

      final complaints = list
          .whereType<Map>()
          .map<Map<String, dynamic>>(
            (e) => Map<String, dynamic>.from(e),
          )
          .toList();

      debugPrint(
        '🔥 JUMLAH COMPLAINT: ${complaints.length}',
      );

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
      debugPrint(
        '❌ ERROR ADMIN COMPLAINTS: $e',
      );

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
          if (note != null && note.isNotEmpty)
            'admin_response': note,
        },
      );

      debugPrint(
        '📢 PUT /admin/complaints/$id → '
        '${response.statusCode}',
      );

      debugPrint(
        '📢 BODY: ${response.body}',
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status pengaduan diubah menjadi $newStatus.',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        await _loadComplaints();
      } else {
        String message =
            'Gagal mengubah status.';

        try {
          final decoded =
              jsonDecode(response.body);

          message =
              decoded['message']?.toString() ??
                  message;
        } catch (_) {}

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
    if (iso == null || iso.isEmpty) {
      return '-';
    }

    try {
      final date =
          DateTime.parse(iso).toLocal();

      const bulan = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];

      return '${date.day.toString().padLeft(2, '0')} '
          '${bulan[date.month - 1]} ${date.year}';
    } catch (_) {
      return iso;
    }
  }

  String _code(Map<String, dynamic> c) {
    final id = c['id'];

    if (id is int) {
      return 'PGD-${id.toString().padLeft(3, '0')}';
    }

    return 'PGD-${id.toString()}';
  }

  // ============================================================
  // FILTER
  // ============================================================
  List<Map<String, dynamic>> get _filteredComplaints {
    if (_selectedFilter == 'Semua') {
      return _complaints;
    }

    return _complaints
        .where(
          (c) =>
              c['status']?.toString() ==
              _selectedFilter,
        )
        .toList();
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.of(context).size.width;

    final bool isMobile =
        screenWidth < 700;

    final bool isTablet =
        screenWidth >= 700 &&
        screenWidth < 1100;

    final horizontalPadding = isMobile
        ? 14.0
        : isTablet
            ? 20.0
            : 24.0;

    return RefreshIndicator(
      onRefresh: _loadComplaints,
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          isMobile ? 18 : 24,
          horizontalPadding,
          32,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildHeader(isMobile),

            SizedBox(
              height: isMobile ? 18 : 24,
            ),

            if (_isLoading)
              _buildLoading()
            else if (_errorMessage != null)
              _buildError()
            else ...[
              _buildStatistics(
                isMobile,
                isTablet,
              ),

              SizedBox(
                height: isMobile ? 18 : 24,
              ),

              _buildComplaintSection(
                isMobile,
                isTablet,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================
  Widget _buildLoading() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 80,
      ),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(
        color: Colors.orange,
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================
  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'Pengaduan',
          style: TextStyle(
            fontSize: isMobile ? 23 : 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Kelola pengaduan dari mitra dan pelanggan.',
          style: TextStyle(
            fontSize: isMobile ? 12 : 13,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================
  Widget _buildStatistics(
    bool isMobile,
    bool isTablet,
  ) {
    final cards = [
      {
        'title': 'Menunggu',
        'value': _summary['menunggu'] ?? 0,
        'subtitle': 'Pengaduan baru',
        'icon':
            Icons.hourglass_empty_rounded,
        'color':
            const Color(0xFFF59E0B),
        'background':
            const Color(0xFFFFF7ED),
      },
      {
        'title': 'Diproses',
        'value': _summary['diproses'] ?? 0,
        'subtitle': 'Sedang ditangani',
        'icon': Icons.sync_rounded,
        'color':
            const Color(0xFF3B82F6),
        'background':
            const Color(0xFFEFF6FF),
      },
      {
        'title': 'Selesai',
        'value': _summary['selesai'] ?? 0,
        'subtitle':
            'Telah diselesaikan',
        'icon':
            Icons.check_circle_outline_rounded,
        'color':
            const Color(0xFF10B981),
        'background':
            const Color(0xFFECFDF5),
      },
      {
        'title': 'Ditolak',
        'value': _summary['ditolak'] ?? 0,
        'subtitle':
            'Pengaduan ditolak',
        'icon':
            Icons.cancel_outlined,
        'color':
            const Color(0xFFEF4444),
        'background':
            const Color(0xFFFEF2F2),
      },
    ];

    // ----------------------------------------------------------
    // MOBILE
    // ----------------------------------------------------------
    if (isMobile) {
      return GridView.builder(
        shrinkWrap: true,
        physics:
            const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.75,
        ),
        itemBuilder: (_, index) {
          return _buildStatisticCard(
            cards[index],
            compact: true,
          );
        },
      );
    }

    // ----------------------------------------------------------
    // TABLET
    // ----------------------------------------------------------
    if (isTablet) {
      return GridView.builder(
        shrinkWrap: true,
        physics:
            const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 3.0,
        ),
        itemBuilder: (_, index) {
          return _buildStatisticCard(
            cards[index],
          );
        },
      );
    }

    // ----------------------------------------------------------
    // DESKTOP
    // ----------------------------------------------------------
    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 2.45,
      ),
      itemBuilder: (_, index) {
        return _buildStatisticCard(
          cards[index],
        );
      },
    );
  }

  Widget _buildStatisticCard(
    Map<String, dynamic> card, {
    bool compact = false,
  }) {
    return Container(
      padding:
          EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 40 : 46,
            height: compact ? 40 : 46,
            decoration: BoxDecoration(
              color:
                  card['background'] as Color,
              borderRadius:
                  BorderRadius.circular(11),
            ),
            child: Icon(
              card['icon'] as IconData,
              color: card['color'] as Color,
              size: compact ? 20 : 23,
            ),
          ),

          SizedBox(
            width: compact ? 9 : 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(
                  card['title'].toString(),
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize:
                        compact ? 11 : 12,
                    color:
                        const Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  card['value'].toString(),
                  style: TextStyle(
                    fontSize:
                        compact ? 20 : 23,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        const Color(0xFF111827),
                  ),
                ),

                if (!compact) ...[
                  const SizedBox(height: 2),
                  Text(
                    card['subtitle'].toString(),
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color:
                          Color(0xFF94A3B8),
                    ),
                  ),
                ],
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
  Widget _buildComplaintSection(
    bool isMobile,
    bool isTablet,
  ) {
    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // MOBILE HEADER
          // ------------------------------------------------------
          if (isMobile)
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child:
                      _buildFilterDropdown(),
                ),
              ],
            )

          // ------------------------------------------------------
          // TABLET + DESKTOP HEADER
          // ------------------------------------------------------
          else
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center,
              children: [
                Expanded(
                  child:
                      _buildSectionTitle(),
                ),

                const SizedBox(width: 20),

                // FIX:
                // Dropdown diberi lebar pasti supaya
                // DropdownButton.isExpanded tidak menerima
                // unbounded width.
                SizedBox(
                  width: isTablet
                      ? 170
                      : 190,
                  child:
                      _buildFilterDropdown(),
                ),
              ],
            ),

          const SizedBox(height: 16),

          const Divider(
            height: 1,
            color: Color(0xFFE2E8F0),
          ),

          const SizedBox(height: 14),

          // ------------------------------------------------------
          // CONTENT
          // ------------------------------------------------------
          if (_filteredComplaints.isEmpty)
            _buildEmptyState()
          else if (isMobile)
            Column(
              children:
                  _filteredComplaints
                      .map(
                        (c) => Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 10,
                          ),
                          child:
                              _buildComplaintCard(c),
                        ),
                      )
                      .toList(),
            )
          else
            _buildDesktopTable(isTablet),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================
  Widget _buildSectionTitle() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Daftar Pengaduan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_filteredComplaints.length} pengaduan ditampilkan',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FILTER DROPDOWN
  // ============================================================
  Widget _buildFilterDropdown() {
    return Container(
      height: 40,
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        borderRadius:
            BorderRadius.circular(9),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,

          // Aman karena parent sekarang
          // selalu mempunyai bounded width.
          isExpanded: true,

          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: Color(0xFF64748B),
          ),

          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF334155),
            fontWeight: FontWeight.w500,
          ),

          items: _filters
              .map(
                (f) =>
                    DropdownMenuItem<String>(
                  value: f,
                  child: Text(
                    f,
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),

          onChanged: (v) {
            if (v == null) return;

            setState(() {
              _selectedFilter = v;
            });
          },
        ),
      ),
    );
  }

  // ============================================================
  // DESKTOP TABLE
  // ============================================================
  Widget _buildDesktopTable(
    bool isTablet,
  ) {
    final complaints =
        _filteredComplaints;

    debugPrint(
      '🖥️ DESKTOP TABLE: '
      '${complaints.length} DATA',
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(10),
        child: SingleChildScrollView(
          scrollDirection:
              Axis.horizontal,
          child: SizedBox(
            width: isTablet ? 900 : 1100,
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(
                const Color(0xFFF8FAFC),
              ),

              headingRowHeight: 48,

              dataRowMinHeight: 74,
              dataRowMaxHeight: 100,

              columnSpacing:
                  isTablet ? 18 : 24,

              horizontalMargin: 14,

              dividerThickness: 0.6,

              headingTextStyle:
                  const TextStyle(
                fontSize: 11,
                fontWeight:
                    FontWeight.w700,
                color:
                    Color(0xFF475569),
              ),

              columns: const [
                DataColumn(
                  label:
                      Text('Pengaduan'),
                ),
                DataColumn(
                  label:
                      Text('Pengadu'),
                ),
                DataColumn(
                  label:
                      Text('Pekerjaan'),
                ),
                DataColumn(
                  label:
                      Text('Kategori'),
                ),
                DataColumn(
                  label:
                      Text('Status'),
                ),
                DataColumn(
                  label:
                      Text('Aksi'),
                ),
              ],

              rows: complaints.map((c) {
                debugPrint(
                  '🖥️ ROW: ${c['id']}',
                );

                return DataRow(
                  cells: [
                    // ------------------------------------------------
                    // PENGADUAN
                    // ------------------------------------------------
                    DataCell(
                      SizedBox(
                        width: 105,
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              _code(c),
                              style:
                                  const TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight
                                        .w700,
                                color:
                                    Color(
                                  0xFF1E293B,
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              _formatTanggal(
                                c['created_at']
                                    ?.toString(),
                              ),
                              style:
                                  const TextStyle(
                                fontSize: 10,
                                color:
                                    Color(
                                  0xFF94A3B8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ------------------------------------------------
                    // PENGADU
                    // ------------------------------------------------
                    DataCell(
                      SizedBox(
                        width: 135,
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              _getNestedValue(
                                c,
                                'user',
                                ['name'],
                              ),
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight
                                        .w600,
                                color:
                                    Color(
                                  0xFF1E293B,
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 3,
                            ),
                            Text(
                              c['user_role']
                                      ?.toString() ??
                                  '-',
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                fontSize: 10,
                                color:
                                    Color(
                                  0xFF94A3B8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ------------------------------------------------
                    // PEKERJAAN
                    // ------------------------------------------------
                    DataCell(
                      SizedBox(
                        width: 160,
                        child: Text(
                          _getNestedValue(
                            c,
                            'job',
                            [
                              'tittle',
                              'title',
                            ],
                          ),
                          maxLines: 2,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 12,
                            color:
                                Color(
                              0xFF475569,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ------------------------------------------------
                    // KATEGORI
                    // ------------------------------------------------
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: Text(
                          c['category']
                                  ?.toString() ??
                              '-',
                          maxLines: 2,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 12,
                            color:
                                Color(
                              0xFF475569,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ------------------------------------------------
                    // STATUS
                    // ------------------------------------------------
                    DataCell(
                      _buildStatusBadge(
                        c['status']
                                ?.toString() ??
                            '-',
                      ),
                    ),

                    // ------------------------------------------------
                    // AKSI
                    // ------------------------------------------------
                    DataCell(
                      _buildActionButtons(c),
                    ),
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
    Map<String, dynamic> c,
  ) {
    final status =
        c['status']?.toString() ?? '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFF),
        borderRadius:
            BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // --------------------------------------------------------
          // TOP
          // --------------------------------------------------------
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _code(c),
                      style:
                          const TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatTanggal(
                        c['created_at']
                            ?.toString(),
                      ),
                      style:
                          const TextStyle(
                        fontSize: 10,
                        color:
                            Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              _buildStatusBadge(status),
            ],
          ),

          const SizedBox(height: 13),

          const Divider(
            height: 1,
            color: Color(0xFFE2E8F0),
          ),

          const SizedBox(height: 13),

          _mobileInfoRow(
            Icons.person_outline_rounded,
            'Pengadu',
            '${_getNestedValue(
              c,
              'user',
              ['name'],
            )} (${c['user_role'] ?? '-'})',
          ),

          _mobileInfoRow(
            Icons.work_outline_rounded,
            'Pekerjaan',
            _getNestedValue(
              c,
              'job',
              [
                'tittle',
                'title',
              ],
            ),
          ),

          _mobileInfoRow(
            Icons.category_outlined,
            'Kategori',
            c['category']
                    ?.toString() ??
                '-',
          ),

          const SizedBox(height: 5),

          const Text(
            'Pengaduan',
            style: TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF334155),
            ),
          ),

          const SizedBox(height: 6),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(8),
              border: Border.all(
                color:
                    const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  c['title']?.toString() ??
                      '-',
                  style:
                      const TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(0xFF1E293B),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  c['description']
                          ?.toString() ??
                      '-',
                  maxLines: 3,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 11,
                    height: 1.45,
                    color:
                        Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _buildActionButtons(c),
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
      padding:
          const EdgeInsets.only(
        bottom: 9,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment:
                Alignment.center,
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFF1F5F9),
              borderRadius:
                  BorderRadius.circular(7),
            ),
            child: Icon(
              icon,
              size: 14,
              color:
                  const Color(0xFF64748B),
            ),
          ),

          const SizedBox(width: 9),

          SizedBox(
            width: 66,
            child: Padding(
              padding:
                  const EdgeInsets.only(
                top: 5,
              ),
              child: Text(
                label,
                style:
                    const TextStyle(
                  fontSize: 11,
                  color:
                      Color(0xFF64748B),
                ),
              ),
            ),
          ),

          const Padding(
            padding:
                EdgeInsets.only(top: 5),
            child: Text(
              ':',
              style:
                  TextStyle(
                fontSize: 11,
                color:
                    Color(0xFF94A3B8),
              ),
            ),
          ),

          const SizedBox(width: 6),

          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.only(
                top: 5,
              ),
              child: Text(
                value,
                style:
                    const TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      Color(0xFF334155),
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
  Widget _buildStatusBadge(
    String status,
  ) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case 'Menunggu':
        backgroundColor =
            const Color(0xFFFFF7ED);
        textColor =
            const Color(0xFFC2410C);
        break;

      case 'Diproses':
        backgroundColor =
            const Color(0xFFEFF6FF);
        textColor =
            const Color(0xFF1D4ED8);
        break;

      case 'Selesai':
        backgroundColor =
            const Color(0xFFECFDF5);
        textColor =
            const Color(0xFF047857);
        break;

      case 'Ditolak':
        backgroundColor =
            const Color(0xFFFEF2F2);
        textColor =
            const Color(0xFFB91C1C);
        break;

      default:
        backgroundColor =
            const Color(0xFFF1F5F9);
        textColor =
            const Color(0xFF475569);
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow:
            TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight:
              FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  // ============================================================
  // ACTION BUTTONS
  // ============================================================
  Widget _buildActionButtons(
    Map<String, dynamic> c,
  ) {
    final status =
        c['status']?.toString() ?? '';

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        OutlinedButton.icon(
          onPressed: () =>
              _showComplaintDetail(c),
          icon: const Icon(
            Icons.visibility_outlined,
            size: 14,
          ),
          label:
              const Text('Detail'),
          style:
              OutlinedButton.styleFrom(
            foregroundColor:
                const Color(0xFF7C3AED),
            side: const BorderSide(
              color:
                  Color(0xFFD8B4FE),
            ),
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            minimumSize:
                const Size(0, 34),
            tapTargetSize:
                MaterialTapTargetSize
                    .shrinkWrap,
            textStyle:
                const TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),

        if (status == 'Menunggu')
          ElevatedButton(
            onPressed: () =>
                _updateComplaintStatus(
              c['id'],
              'Diproses',
            ),
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF7C3AED),
              foregroundColor:
                  Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 8,
              ),
              minimumSize:
                  const Size(0, 34),
              tapTargetSize:
                  MaterialTapTargetSize
                      .shrinkWrap,
              textStyle:
                  const TextStyle(
                fontSize: 11,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
            child:
                const Text('Proses'),
          ),

        if (status == 'Diproses')
          ElevatedButton(
            onPressed: () =>
                _updateComplaintStatus(
              c['id'],
              'Selesai',
            ),
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF10B981),
              foregroundColor:
                  Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 8,
              ),
              minimumSize:
                  const Size(0, 34),
              tapTargetSize:
                  MaterialTapTargetSize
                      .shrinkWrap,
              textStyle:
                  const TextStyle(
                fontSize: 11,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
            child:
                const Text('Selesai'),
          ),

        if (status == 'Menunggu' ||
            status == 'Diproses')
          OutlinedButton(
            onPressed: () =>
                _confirmReject(c),
            style:
                OutlinedButton.styleFrom(
              foregroundColor:
                  const Color(0xFFEF4444),
              side: const BorderSide(
                color:
                    Color(0xFFFCA5A5),
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 8,
              ),
              minimumSize:
                  const Size(0, 34),
              tapTargetSize:
                  MaterialTapTargetSize
                      .shrinkWrap,
              textStyle:
                  const TextStyle(
                fontSize: 11,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
            child:
                const Text('Tolak'),
          ),
      ],
    );
  }

  // ============================================================
  // DETAIL DIALOG
  // ============================================================
  void _showComplaintDetail(
    Map<String, dynamic> c,
  ) {
    final responseController =
        TextEditingController(
      text:
          c['admin_response']
                  ?.toString() ??
              '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        final screenWidth =
            MediaQuery.of(
          dialogContext,
        ).size.width;

        final bool isMobile =
            screenWidth < 600;

        final status =
            c['status']?.toString() ?? '';

        return AlertDialog(
          insetPadding:
              EdgeInsets.symmetric(
            horizontal:
                isMobile ? 16 : 40,
            vertical: 24,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
          titlePadding:
              const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            0,
          ),
          contentPadding:
              const EdgeInsets.fromLTRB(
            20,
            16,
            20,
            8,
          ),
          actionsPadding:
              const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            14,
          ),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFF3E8FF,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child: const Icon(
                  Icons
                      .report_problem_outlined,
                  color:
                      Color(0xFF7C3AED),
                  size: 21,
                ),
              ),

              const SizedBox(width: 11),

              const Expanded(
                child: Text(
                  'Detail Pengaduan',
                  style:
                      TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),

          content: SizedBox(
            width:
                isMobile
                    ? double.maxFinite
                    : 500,
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(
                maxHeight:
                    MediaQuery.of(
                          dialogContext,
                        ).size.height *
                        0.65,
              ),
              child:
                  SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    _detailRow(
                      'ID Pengaduan',
                      _code(c),
                    ),
                    _detailRow(
                      'Tanggal',
                      _formatTanggal(
                        c['created_at']
                            ?.toString(),
                      ),
                    ),
                    _detailRow(
                      'Pengadu',
                      _getNestedValue(
                        c,
                        'user',
                        ['name'],
                      ),
                    ),
                    _detailRow(
                      'Role',
                      c['user_role']
                              ?.toString() ??
                          '-',
                    ),
                    _detailRow(
                      'Kategori',
                      c['category']
                              ?.toString() ??
                          '-',
                    ),
                    _detailRow(
                      'Pekerjaan',
                      _getNestedValue(
                        c,
                        'job',
                        [
                          'tittle',
                          'title',
                        ],
                      ),
                    ),
                    _detailRow(
                      'Judul',
                      c['title']
                              ?.toString() ??
                          '-',
                    ),
                    _detailRow(
                      'Status',
                      status,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _detailSectionBox(
                      title:
                          'Keterangan Pengaduan',
                      child: Text(
                        c['description']
                                ?.toString() ??
                            '-',
                        style:
                            const TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color:
                              Color(
                            0xFF475569,
                          ),
                        ),
                      ),
                    ),

                    if ((c['admin_response']
                                ?.toString() ??
                            '')
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 12,
                      ),

                      _detailSectionBox(
                        title:
                            'Tanggapan Admin',
                        backgroundColor:
                            const Color(
                          0xFFECFDF5,
                        ),
                        borderColor:
                            const Color(
                          0xFFA7F3D0,
                        ),
                        titleColor:
                            const Color(
                          0xFF065F46,
                        ),
                        child: Text(
                          c['admin_response']
                              .toString(),
                          style:
                              const TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color:
                                Color(
                              0xFF065F46,
                            ),
                          ),
                        ),
                      ),
                    ],

                    if (status ==
                            'Menunggu' ||
                        status ==
                            'Diproses') ...[
                      const SizedBox(
                        height: 12,
                      ),

                      const Text(
                        'Tanggapan / Catatan Admin',
                        style:
                            TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              Color(
                            0xFF334155,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 7,
                      ),

                      TextField(
                        controller:
                            responseController,
                        maxLines: 3,
                        style:
                            const TextStyle(
                          fontSize: 12,
                        ),
                        decoration:
                            InputDecoration(
                          hintText:
                              'Tulis tanggapan untuk pengadu...',
                          hintStyle:
                              const TextStyle(
                            fontSize: 12,
                            color:
                                Color(
                              0xFF94A3B8,
                            ),
                          ),
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                            borderSide:
                                const BorderSide(
                              color:
                                  Color(
                                0xFFE2E8F0,
                              ),
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                            borderSide:
                                const BorderSide(
                              color:
                                  Color(
                                0xFFE2E8F0,
                              ),
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                            borderSide:
                                const BorderSide(
                              color:
                                  Color(
                                0xFF7C3AED,
                              ),
                            ),
                          ),
                          contentPadding:
                              const EdgeInsets
                                  .all(11),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(
                dialogContext,
              ).pop(),
              child:
                  const Text('Tutup'),
            ),

            if (status == 'Menunggu')
              ElevatedButton(
                onPressed: () {
                  Navigator.of(
                    dialogContext,
                  ).pop();

                  _updateComplaintStatus(
                    c['id'],
                    'Diproses',
                    note:
                        responseController
                            .text
                            .trim(),
                  );
                },
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xFF7C3AED,
                  ),
                  foregroundColor:
                      Colors.white,
                  elevation: 0,
                ),
                child:
                    const Text('Proses'),
              ),

            if (status == 'Diproses')
              ElevatedButton(
                onPressed: () {
                  Navigator.of(
                    dialogContext,
                  ).pop();

                  _updateComplaintStatus(
                    c['id'],
                    'Selesai',
                    note:
                        responseController
                            .text
                            .trim(),
                  );
                },
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xFF10B981,
                  ),
                  foregroundColor:
                      Colors.white,
                  elevation: 0,
                ),
                child:
                    const Text(
                  'Tandai Selesai',
                ),
              ),
          ],
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
    Color backgroundColor =
        const Color(0xFFF8FAFC),
    Color borderColor =
        const Color(0xFFE2E8F0),
    Color titleColor =
        const Color(0xFF334155),
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                FontWeight.w700,
            color: titleColor,
          ),
        ),

        const SizedBox(height: 7),

        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius:
                BorderRadius.circular(9),
            border: Border.all(
              color: borderColor,
            ),
          ),
          child: child,
        ),
      ],
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================
  Widget _detailRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 9,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style:
                  const TextStyle(
                fontSize: 11,
                color:
                    Color(0xFF64748B),
              ),
            ),
          ),

          const Text(
            ': ',
            style:
                TextStyle(
              fontSize: 11,
              color:
                  Color(0xFF94A3B8),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(
                fontSize: 11,
                fontWeight:
                    FontWeight.w600,
                color:
                    Color(0xFF1E293B),
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
  void _confirmReject(
    Map<String, dynamic> c,
  ) {
    final reasonController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final width =
            MediaQuery.of(
          dialogContext,
        ).size.width;

        final isMobile =
            width < 600;

        return AlertDialog(
          insetPadding:
              EdgeInsets.symmetric(
            horizontal:
                isMobile ? 16 : 40,
            vertical: 24,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
          title: const Text(
            'Tolak Pengaduan?',
            style:
                TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF111827),
            ),
          ),
          content: SizedBox(
            width:
                isMobile
                    ? double.maxFinite
                    : 420,
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                const Text(
                  'Apakah kamu yakin ingin menolak pengaduan ini?',
                  style:
                      TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color:
                        Color(0xFF64748B),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                TextField(
                  controller:
                      reasonController,
                  maxLines: 3,
                  style:
                      const TextStyle(
                    fontSize: 12,
                  ),
                  decoration:
                      InputDecoration(
                    hintText:
                        'Alasan penolakan...',
                    hintStyle:
                        const TextStyle(
                      fontSize: 12,
                      color:
                          Color(0xFF94A3B8),
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        10,
                      ),
                    ),
                    contentPadding:
                        const EdgeInsets
                            .all(11),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(
                dialogContext,
              ).pop(),
              child:
                  const Text('Batal'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();

                _updateComplaintStatus(
                  c['id'],
                  'Ditolak',
                  note:
                      reasonController
                          .text
                          .trim(),
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFFEF4444,
                ),
                foregroundColor:
                    Colors.white,
                elevation: 0,
              ),
              child:
                  const Text('Tolak'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 55,
        horizontal: 20,
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFF8FAFC),
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 30,
              color:
                  Color(0xFFCBD5E1),
            ),
          ),

          const SizedBox(height: 13),

          const Text(
            'Tidak ada pengaduan',
            style:
                TextStyle(
              fontSize: 14,
              fontWeight:
                  FontWeight.w600,
              color:
                  Color(0xFF475569),
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Belum ada pengaduan dengan status tersebut.',
            style:
                TextStyle(
              fontSize: 12,
              color:
                  Color(0xFF94A3B8),
            ),
            textAlign:
                TextAlign.center,
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
      padding:
          const EdgeInsets.all(35),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              Colors.red.withOpacity(
            0.2,
          ),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),

          const SizedBox(height: 12),

          Text(
            _errorMessage ??
                'Terjadi kesalahan.',
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color: Colors.red,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed:
                _loadComplaints,
            icon: const Icon(
              Icons.refresh,
              size: 18,
            ),
            label:
                const Text('Coba Lagi'),
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.orange,
              foregroundColor:
                  Colors.white,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}