import 'package:flutter/material.dart';

class AdminRatingScreen extends StatefulWidget {
  const AdminRatingScreen({super.key});

  @override
  State<AdminRatingScreen> createState() => _AdminRatingScreenState();
}

class _AdminRatingScreenState extends State<AdminRatingScreen> {
  final List<Map<String, dynamic>> _ratings = [
    {
      'id': 'RAT-001',
      'mitra': 'Andi Teknik AC',
      'pelanggan': 'Budi Santoso',
      'layanan': 'Service AC Bocor',
      'rating': 5,
      'komentar': 'Pelayanan sangat baik, cepat, dan hasil pekerjaannya rapi.',
      'tanggal': '12 September 2026',
    },
    {
      'id': 'RAT-002',
      'mitra': 'Joko Plumbing',
      'pelanggan': 'Siti Aminah',
      'layanan': 'Perbaikan Pipa Air',
      'rating': 4,
      'komentar': 'Pekerjaan cukup bagus dan mitra sangat ramah.',
      'tanggal': '11 September 2026',
    },
    {
      'id': 'RAT-003',
      'mitra': 'Dimas Elektrik',
      'pelanggan': 'Rina Wulandari',
      'layanan': 'Perbaikan Instalasi Listrik',
      'rating': 3,
      'komentar': 'Hasil pekerjaan cukup baik, tetapi datang sedikit terlambat.',
      'tanggal': '10 September 2026',
    },
    {
      'id': 'RAT-004',
      'mitra': 'Budi Cat Rumah',
      'pelanggan': 'Agus Pratama',
      'layanan': 'Pengecatan Ruang Tamu',
      'rating': 2,
      'komentar': 'Hasil pengecatan kurang rapi dan waktu pengerjaan cukup lama.',
      'tanggal': '09 September 2026',
    },
    {
      'id': 'RAT-005',
      'mitra': 'Clean Home',
      'pelanggan': 'Dewi Lestari',
      'layanan': 'Jasa Kebersihan Rumah',
      'rating': 1,
      'komentar': 'Pelayanan kurang memuaskan dan beberapa bagian rumah belum dibersihkan.',
      'tanggal': '08 September 2026',
    },
    {
      'id': 'RAT-006',
      'mitra': 'Andi Teknik AC',
      'pelanggan': 'Fajar Hidayat',
      'layanan': 'Cuci AC Rumah',
      'rating': 5,
      'komentar': 'Sangat profesional. Akan menggunakan jasa ini lagi.',
      'tanggal': '07 September 2026',
    },
  ];

  String _selectedFilter = 'Semua';

  final List<String> _filterOptions = [
    'Semua',
    '5 Bintang',
    '4 Bintang',
    '3 Bintang',
    '2 Bintang',
    '1 Bintang',
  ];

  List<Map<String, dynamic>> get _filteredRatings {
    if (_selectedFilter == 'Semua') {
      return _ratings;
    }

    final selectedRating = int.parse(
      _selectedFilter.substring(0, 1),
    );

    return _ratings
        .where((rating) => rating['rating'] == selectedRating)
        .toList();
  }

  double get _averageRating {
    if (_ratings.isEmpty) return 0;

    final total = _ratings.fold<int>(
      0,
      (total, item) => total + (item['rating'] as int),
    );

    return total / _ratings.length;
  }

  int get _highRatingCount {
    return _ratings
        .where((rating) => rating['rating'] >= 4)
        .length;
  }

  int get _lowRatingCount {
    return _ratings
        .where((rating) => rating['rating'] <= 2)
        .length;
  }

  Color _ratingColor(int rating) {
    if (rating >= 4) {
      return Colors.green;
    }

    if (rating == 3) {
      return Colors.orange;
    }

    return Colors.red;
  }

  Widget _buildStars(
    int rating, {
    double size = 18,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) {
          return Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: size,
          );
        },
      ),
    );
  }

  Widget _buildRatingBadge(int rating) {
    final color = _ratingColor(rating);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: 15,
            color: color,
          ),
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
          color: Theme.of(context)
              .dividerColor
              .withOpacity(0.4),
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
            child: Icon(
              icon,
              color: color,
              size: 27,
            ),
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

  Widget _buildSummarySection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;

        final cards = [
          _summaryCard(
            title: 'Total Rating',
            value: '${_ratings.length}',
            icon: Icons.rate_review_outlined,
            color: Colors.blue,
          ),
          _summaryCard(
            title: 'Rata-rata Rating',
            value: _averageRating.toStringAsFixed(1),
            icon: Icons.star_rate_outlined,
            color: Colors.amber.shade700,
          ),
          _summaryCard(
            title: 'Rating Positif',
            value: '$_highRatingCount',
            icon: Icons.thumb_up_alt_outlined,
            color: Colors.green,
          ),
          _summaryCard(
            title: 'Rating Rendah',
            value: '$_lowRatingCount',
            icon: Icons.warning_amber_outlined,
            color: Colors.red,
          ),
        ];

        if (isMobile) {
          return Column(
            children: [
              for (final card in cards) ...[
                card,
                const SizedBox(height: 12),
              ],
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
      },
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context)
              .dividerColor
              .withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list),
          const SizedBox(width: 10),
          const Text(
            'Filter Rating:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
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
              items: _filterOptions.map((filter) {
                return DropdownMenuItem<String>(
                  value: filter,
                  child: Text(filter),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedFilter = value;
                });
              },
            ),
          ),
          const Spacer(),
          Text(
            '${_filteredRatings.length} ulasan',
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

  void _showRatingDetail(Map<String, dynamic> ratingData) {
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
                  _detailRow(
                    'ID Rating',
                    ratingData['id'],
                  ),
                  _detailRow(
                    'Nama Mitra',
                    ratingData['mitra'],
                  ),
                  _detailRow(
                    'Nama Pelanggan',
                    ratingData['pelanggan'],
                  ),
                  _detailRow(
                    'Layanan',
                    ratingData['layanan'],
                  ),
                  _detailRow(
                    'Tanggal',
                    ratingData['tanggal'],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Rating',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _buildStars(
                        ratingData['rating'],
                        size: 25,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${ratingData['rating']}/5',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Komentar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      ratingData['komentar'],
                    ),
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
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _confirmDeleteRating(ratingData);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Hapus Rating'),
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
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRating(Map<String, dynamic> ratingData) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Rating'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus rating ini? '
            'Tindakan ini hanya menghapus data dummy dari tampilan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _ratings.removeWhere(
                    (item) => item['id'] == ratingData['id'],
                  );
                });

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rating berhasil dihapus.'),
                  ),
                );
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

  Widget _buildDesktopTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context)
              .dividerColor
              .withOpacity(0.4),
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
            DataColumn(label: Text('ID Rating')),
            DataColumn(label: Text('Mitra')),
            DataColumn(label: Text('Pelanggan')),
            DataColumn(label: Text('Layanan')),
            DataColumn(label: Text('Rating')),
            DataColumn(label: Text('Tanggal')),
            DataColumn(label: Text('Aksi')),
          ],
          rows: _filteredRatings.map((ratingData) {
            final rating = ratingData['rating'] as int;

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    ratingData['id'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataCell(Text(ratingData['mitra'])),
                DataCell(Text(ratingData['pelanggan'])),
                DataCell(Text(ratingData['layanan'])),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStars(rating, size: 16),
                      const SizedBox(width: 5),
                      Text('$rating'),
                    ],
                  ),
                ),
                DataCell(Text(ratingData['tanggal'])),
                DataCell(
                  IconButton(
                    tooltip: 'Lihat Detail',
                    icon: const Icon(
                      Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      _showRatingDetail(ratingData);
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return Column(
      children: _filteredRatings.map((ratingData) {
        final rating = ratingData['rating'] as int;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context)
                  .dividerColor
                  .withOpacity(0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ratingData['id'],
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
              _mobileInfoRow(
                Icons.handshake_outlined,
                'Mitra',
                ratingData['mitra'],
              ),
              _mobileInfoRow(
                Icons.person_outline,
                'Pelanggan',
                ratingData['pelanggan'],
              ),
              _mobileInfoRow(
                Icons.work_outline,
                'Layanan',
                ratingData['layanan'],
              ),
              _mobileInfoRow(
                Icons.calendar_today_outlined,
                'Tanggal',
                ratingData['tanggal'],
              ),
              const SizedBox(height: 10),
              _buildStars(rating),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  ratingData['komentar'],
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showRatingDetail(ratingData);
                  },
                  icon: const Icon(
                    Icons.visibility_outlined,
                  ),
                  label: const Text('Lihat Detail Rating'),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

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
          Icon(
            icon,
            size: 18,
            color: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.color
                ?.withOpacity(0.6),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kelola Rating Mitra',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
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
              _buildSummarySection(),
              const SizedBox(height: 24),
              _buildFilterSection(),
              const SizedBox(height: 18),
              if (_filteredRatings.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(35),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 55,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Tidak ada rating yang ditemukan.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else if (isMobile)
                _buildMobileList()
              else
                _buildDesktopTable(),
            ],
          ),
        );
      },
    );
  }
}