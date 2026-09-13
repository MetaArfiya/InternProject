import 'dart:convert';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class AdminComplaintScreen extends StatefulWidget {
  const AdminComplaintScreen({super.key});

  @override
  State<AdminComplaintScreen> createState() => _AdminComplaintScreenState();
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
    _loadComplaints();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================
  Future<void> _loadComplaints() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.get('/admin/complaints');

      debugPrint('📢 ADMIN COMPLAINTS: ${response.statusCode}');
      debugPrint('📢 BODY: ${response.body}');

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
        _summary = {
          'total':    int.tryParse(s['total']?.toString() ?? '0') ?? 0,
          'menunggu': int.tryParse(s['menunggu']?.toString() ?? '0') ?? 0,
          'diproses': int.tryParse(s['diproses']?.toString() ?? '0') ?? 0,
          'selesai':  int.tryParse(s['selesai']?.toString() ?? '0') ?? 0,
          'ditolak':  int.tryParse(s['ditolak']?.toString() ?? '0') ?? 0,
        };

        _complaints = list
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();

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

      debugPrint('📢 PUT /admin/complaints/$id → ${response.statusCode}');
      debugPrint('📢 BODY: ${response.body}');

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status pengaduan diubah menjadi $newStatus.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadComplaints();
      } else {
        String message = 'Gagal mengubah status.';
        try {
          final decoded = jsonDecode(response.body);
          message = decoded['message']?.toString() ?? message;
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
  String _getValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null &&
          value.toString().trim().isNotEmpty &&
          value.toString() != 'null') {
        return value.toString();
      }
    }
    return '-';
  }

  /// Ambil field dari relasi nested, misal `user.name` atau `job.tittle`
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

  String _formatRupiah(dynamic value) {
    final number = int.tryParse(value.toString()) ?? 0;
    final formatted = number.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        );
    return 'Rp$formatted';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return RefreshIndicator(
      onRefresh: _loadComplaints,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isMobile),
            const SizedBox(height: 24),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: CircularProgressIndicator(color: Colors.orange),
                ),
              )
            else if (_errorMessage != null)
              _buildError()
            else ...[
              _buildStatistics(isMobile),
              const SizedBox(height: 24),
              _buildComplaintSection(isMobile),
            ],
          ],
        ),
      ),
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
          'Pengaduan',
          style: TextStyle(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
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
  // STATISTIK
  // ============================================================
  Widget _buildStatistics(bool isMobile) {
    final cards = [
      {
        'title': 'Menunggu',
        'value': _summary['menunggu'] ?? 0,
        'subtitle': 'Pengaduan baru',
        'icon': Icons.hourglass_empty_outlined,
        'color': const Color(0xFFF59E0B),
        'background': const Color(0xFFFFF7ED),
      },
      {
        'title': 'Diproses',
        'value': _summary['diproses'] ?? 0,
        'subtitle': 'Sedang ditangani',
        'icon': Icons.sync_outlined,
        'color': const Color(0xFF3B82F6),
        'background': const Color(0xFFEFF6FF),
      },
      {
        'title': 'Selesai',
        'value': _summary['selesai'] ?? 0,
        'subtitle': 'Telah diselesaikan',
        'icon': Icons.check_circle_outline,
        'color': const Color(0xFF10B981),
        'background': const Color(0xFFECFDF5),
      },
      {
        'title': 'Ditolak',
        'value': _summary['ditolak'] ?? 0,
        'subtitle': 'Pengaduan ditolak',
        'icon': Icons.cancel_outlined,
        'color': const Color(0xFFEF4444),
        'background': const Color(0xFFFEF2F2),
      },
    ];

    if (isMobile) {
      return Column(
        children: cards
            .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildStatisticCard(c),
                ))
            .toList(),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width < 1050 ? 2 : 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemBuilder: (_, i) => _buildStatisticCard(cards[i]),
    );
  }

  Widget _buildStatisticCard(Map<String, dynamic> card) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: card['background'] as Color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              card['icon'] as IconData,
              color: card['color'] as Color,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card['title'].toString(),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                Text(
                  card['value'].toString(),
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  card['subtitle'].toString(),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION
  // ============================================================
  Widget _buildComplaintSection(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(),
                const SizedBox(height: 14),
                _buildFilterDropdown(),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _buildSectionTitle()),
                _buildFilterDropdown(),
              ],
            ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          if (_filteredComplaints.isEmpty)
            _buildEmptyState()
          else if (isMobile)
            Column(
              children: _filteredComplaints
                  .map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildComplaintCard(c),
                      ))
                  .toList(),
            )
          else
            _buildDesktopTable(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
          items: _filters
              .map((f) => DropdownMenuItem<String>(value: f, child: Text(f)))
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
  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 950),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          dataRowMinHeight: 70,
          dataRowMaxHeight: 95,
          columnSpacing: 24,
          horizontalMargin: 12,
          columns: const [
            DataColumn(label: Text('Pengaduan')),
            DataColumn(label: Text('Pengadu')),
            DataColumn(label: Text('Pekerjaan')),
            DataColumn(label: Text('Kategori')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Aksi')),
          ],
          rows: _filteredComplaints.map((c) {
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 110,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _code(c),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTanggal(c['created_at']?.toString()),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 150,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getNestedValue(c, 'user', ['name']),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          c['user_role']?.toString() ?? '-',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 170,
                    child: Text(
                      _getNestedValue(c, 'job', ['tittle', 'title']),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    c['category']?.toString() ?? '-',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                DataCell(_buildStatusBadge(c['status']?.toString() ?? '-')),
                DataCell(_buildActionButtons(c)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE CARD
  // ============================================================
  Widget _buildComplaintCard(Map<String, dynamic> c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _code(c),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              _buildStatusBadge(c['status']?.toString() ?? '-'),
            ],
          ),
          const SizedBox(height: 12),
          _mobileInfoRow(
            Icons.person_outline,
            'Pengadu',
            '${_getNestedValue(c, 'user', ['name'])} '
                '(${c['user_role'] ?? '-'})',
          ),
          _mobileInfoRow(
            Icons.work_outline,
            'Pekerjaan',
            _getNestedValue(c, 'job', ['tittle', 'title']),
          ),
          _mobileInfoRow(
            Icons.category_outlined,
            'Kategori',
            c['category']?.toString() ?? '-',
          ),
          _mobileInfoRow(
            Icons.calendar_today_outlined,
            'Tanggal',
            _formatTanggal(c['created_at']?.toString()),
          ),
          const SizedBox(height: 8),
          Text(
            c['title']?.toString() ?? '-',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            c['description']?.toString() ?? '-',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          _buildActionButtons(c),
        ],
      ),
    );
  }

  Widget _mobileInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ),
          const Text(': ',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
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
  // STATUS BADGE
  // ============================================================
  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case 'Menunggu':
        backgroundColor = const Color(0xFFFFF7ED);
        textColor = const Color(0xFFC2410C);
        break;
      case 'Diproses':
        backgroundColor = const Color(0xFFEFF6FF);
        textColor = const Color(0xFF1D4ED8);
        break;
      case 'Selesai':
        backgroundColor = const Color(0xFFECFDF5);
        textColor = const Color(0xFF047857);
        break;
      case 'Ditolak':
        backgroundColor = const Color(0xFFFEF2F2);
        textColor = const Color(0xFFB91C1C);
        break;
      default:
        backgroundColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  // ============================================================
  // ACTION BUTTONS
  // ============================================================
  Widget _buildActionButtons(Map<String, dynamic> c) {
    final status = c['status']?.toString() ?? '';

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        OutlinedButton.icon(
          onPressed: () => _showComplaintDetail(c),
          icon: const Icon(Icons.visibility_outlined, size: 14),
          label: const Text('Detail'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF7C3AED),
            side: const BorderSide(color: Color(0xFFD8B4FE)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            textStyle: const TextStyle(fontSize: 11),
          ),
        ),
        if (status == 'Menunggu')
          ElevatedButton(
            onPressed: () => _updateComplaintStatus(c['id'], 'Diproses'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              textStyle: const TextStyle(fontSize: 11),
            ),
            child: const Text('Proses'),
          ),
        if (status == 'Diproses')
          ElevatedButton(
            onPressed: () => _updateComplaintStatus(c['id'], 'Selesai'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              textStyle: const TextStyle(fontSize: 11),
            ),
            child: const Text('Selesai'),
          ),
        if (status == 'Menunggu' || status == 'Diproses')
          OutlinedButton(
            onPressed: () => _confirmReject(c),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFFCA5A5)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              textStyle: const TextStyle(fontSize: 11),
            ),
            child: const Text('Tolak'),
          ),
      ],
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
      builder: (dialogContext) {
        final status = c['status']?.toString() ?? '';

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.report_problem_outlined,
                  color: Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Detail Pengaduan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('ID Pengaduan', _code(c)),
                  _detailRow('Tanggal', _formatTanggal(c['created_at']?.toString())),
                  _detailRow('Pengadu', _getNestedValue(c, 'user', ['name'])),
                  _detailRow('Role', c['user_role']?.toString() ?? '-'),
                  _detailRow('Kategori', c['category']?.toString() ?? '-'),
                  _detailRow('Pekerjaan', _getNestedValue(c, 'job', ['tittle', 'title'])),
                  _detailRow('Judul', c['title']?.toString() ?? '-'),
                  _detailRow('Status', status),
                  const SizedBox(height: 16),
                  const Text(
                    'Keterangan Pengaduan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      c['description']?.toString() ?? '-',
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),

                  // Tanggapan admin (kalau sudah ada)
                  if ((c['admin_response']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Tanggapan Admin',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
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

                  // Form tanggapan (kalau masih aktif)
                  if (status == 'Menunggu' || status == 'Diproses') ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Tanggapan / Catatan Admin',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: responseController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Tulis tanggapan untuk pengadu...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Tutup'),
            ),
            if (status == 'Menunggu')
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _updateComplaintStatus(
                    c['id'],
                    'Diproses',
                    note: responseController.text.trim(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text('Proses'),
              ),
            if (status == 'Diproses')
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _updateComplaintStatus(
                    c['id'],
                    'Selesai',
                    note: responseController.text.trim(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text('Tandai Selesai'),
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
            width: 125,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ),
          const Text(': ',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
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

  // ============================================================
  // KONFIRMASI TOLAK
  // ============================================================
  void _confirmReject(Map<String, dynamic> c) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            'Tolak Pengaduan?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Apakah kamu yakin ingin menolak pengaduan ini?',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Alasan penolakan...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _updateComplaintStatus(
                  c['id'],
                  'Ditolak',
                  note: reasonController.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Tolak'),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 45),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Tidak ada pengaduan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Belum ada pengaduan dengan status tersebut.',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================
  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadComplaints,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}