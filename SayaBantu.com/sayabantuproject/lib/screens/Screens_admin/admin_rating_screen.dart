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
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
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
    if (rating >= 4) return Colors.green;
    if (rating == 3) return Colors.orange;
    return Colors.red;
  }

  Widget _buildStars(int rating, {double size = 18}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }

  Widget _buildRatingBadge(int rating) {
    final color = _ratingColor(rating);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            '$rating/5',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating berhasil dihapus.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRatings();
      } else {
        String message = 'Gagal menghapus rating.';
        try {
          final decoded = jsonDecode(response.body);
          message = decoded['message']?.toString() ?? message;
        } catch (_) {}
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating berhasil disembunyikan.'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadRatings();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyembunyikan rating.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return RefreshIndicator(
          onRefresh: _loadRatings,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kelola Rating Mitra',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pantau dan kelola penilaian pelanggan terhadap mitra.',
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.7),
                  ),
                ),
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
                  _buildSummarySection(isMobile),
                  const SizedBox(height: 24),
                  _buildFilterSection(),
                  const SizedBox(height: 18),
                  if (_ratings.isEmpty)
                    _buildEmptyState()
                  else if (isMobile)
                    _buildMobileList()
                  else
                    _buildDesktopTable(),
                ],
              ],
            ),
          ),
        );
      },
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
        color: Colors.blue,
      ),
      _summaryCard(
        title: 'Rata-rata Rating',
        value: _average.toStringAsFixed(1),
        icon: Icons.star_rate_outlined,
        color: Colors.amber.shade700,
      ),
      _summaryCard(
        title: 'Rating Positif',
        value: '$_highCount',
        icon: Icons.thumb_up_alt_outlined,
        color: Colors.green,
      ),
      _summaryCard(
        title: 'Rating Rendah',
        value: '$_lowCount',
        icon: Icons.warning_amber_outlined,
        color: Colors.red,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          for (final c in cards) ...[c, const SizedBox(height: 12)],
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 12),
        Expanded(child: cards[1]),
        const SizedBox(width: 12),
        Expanded(child: cards[2]),
        const SizedBox(width: 12),
        Expanded(child: cards[3]),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 27),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
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
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list),
          const SizedBox(width: 10),
          const Text(
            'Filter Rating:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 15),
          SizedBox(
            width: 170,
            child: DropdownButtonFormField<String>(
              value: _selectedFilter,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
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
          const Spacer(),
          Text(
            '${_ratings.length} ulasan',
            style: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABLE
  // ============================================================
  Widget _buildDesktopTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.4),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 25,
          headingRowColor: MaterialStateProperty.all(
            Theme.of(context).colorScheme.surface,
          ),
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Mitra')),
            DataColumn(label: Text('Pelanggan')),
            DataColumn(label: Text('Layanan')),
            DataColumn(label: Text('Rating')),
            DataColumn(label: Text('Tanggal')),
            DataColumn(label: Text('Aksi')),
          ],
          rows: _ratings.map((r) {
            final rating = _getStars(r);
            return DataRow(
              cells: [
                DataCell(Text(
                  _code(r),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                )),
                DataCell(Text(_getNestedValue(r, 'mitra', ['name']))),
                DataCell(Text(_getNestedValue(r, 'pelanggan', ['name']))),
                DataCell(Text(_getNestedValue(r, 'job', ['tittle', 'title']))),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStars(rating, size: 16),
                    const SizedBox(width: 5),
                    Text('$rating'),
                  ],
                )),
                DataCell(Text(_formatTanggal(r['created_at']?.toString()))),
                DataCell(IconButton(
                  tooltip: 'Lihat Detail',
                  icon: const Icon(Icons.visibility_outlined),
                  onPressed: () => _showRatingDetail(r),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE
  // ============================================================
  Widget _buildMobileList() {
    return Column(
      children: _ratings.map((r) {
        final rating = _getStars(r);
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.4),
            ),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildRatingBadge(rating),
                ],
              ),
              const SizedBox(height: 12),
              _mobileInfoRow(Icons.handshake_outlined, 'Mitra',
                  _getNestedValue(r, 'mitra', ['name'])),
              _mobileInfoRow(Icons.person_outline, 'Pelanggan',
                  _getNestedValue(r, 'pelanggan', ['name'])),
              _mobileInfoRow(Icons.work_outline, 'Layanan',
                  _getNestedValue(r, 'job', ['tittle', 'title'])),
              _mobileInfoRow(Icons.calendar_today_outlined, 'Tanggal',
                  _formatTanggal(r['created_at']?.toString())),
              const SizedBox(height: 10),
              _buildStars(rating),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  r['comment']?.toString() ?? '-',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showRatingDetail(r),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Lihat Detail Rating'),
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
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          SizedBox(
            width: 85,
            child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
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
          title: const Row(
            children: [
              Icon(Icons.rate_review_outlined),
              SizedBox(width: 10),
              Text('Detail Rating'),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('ID Rating', _code(r)),
                  _detailRow('Nama Mitra', _getNestedValue(r, 'mitra', ['name'])),
                  _detailRow('Nama Pelanggan', _getNestedValue(r, 'pelanggan', ['name'])),
                  _detailRow('Layanan', _getNestedValue(r, 'job', ['tittle', 'title'])),
                  _detailRow('Tanggal', _formatTanggal(r['created_at']?.toString())),
                  const SizedBox(height: 12),
                  const Text('Rating',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _buildStars(rating, size: 25),
                      const SizedBox(width: 10),
                      Text('$rating/5',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text('Komentar',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 7),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
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
              icon: const Icon(Icons.visibility_off_outlined),
              label: const Text('Sembunyikan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _confirmDeleteRating(r);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Hapus'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
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
            width: 125,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
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
          title: const Text('Sembunyikan Rating'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rating akan disembunyikan dari publik. Data tetap tersimpan.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Alasan (opsional)',
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
                backgroundColor: Colors.orange,
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
          title: const Text('Hapus Rating'),
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
                backgroundColor: Colors.red,
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
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Icon(Icons.rate_review_outlined, size: 55, color: Colors.grey),
          SizedBox(height: 12),
          Text('Tidak ada rating yang ditemukan.',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
            onPressed: _loadRatings,
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