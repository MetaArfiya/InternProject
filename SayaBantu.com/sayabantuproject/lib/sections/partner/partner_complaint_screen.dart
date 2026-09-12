import 'package:flutter/material.dart';

class PartnerComplaintScreen extends StatefulWidget {
  const PartnerComplaintScreen({super.key});

  @override
  State<PartnerComplaintScreen> createState() =>
      _PartnerComplaintScreenState();
}

class _PartnerComplaintScreenState extends State<PartnerComplaintScreen> {
  final List<Map<String, dynamic>> _complaints = [
    {
      'id': 'PGD-001',
      'category': 'Pelanggan Bermasalah',
      'title': 'Pelanggan tidak berada di lokasi',
      'description':
          'Saya sudah datang ke lokasi pelanggan, tetapi pelanggan tidak berada di tempat dan tidak memberikan informasi sebelumnya.',
      'jobId': 'JOB-001',
      'date': '12 September 2026',
      'status': 'Menunggu',
      'response': '-',
    },
    {
      'id': 'PGD-002',
      'category': 'Pembayaran',
      'title': 'Pembayaran belum diterima',
      'description':
          'Pekerjaan sudah selesai, tetapi pembayaran dari pelanggan belum masuk ke sistem.',
      'jobId': 'JOB-002',
      'date': '10 September 2026',
      'status': 'Diproses',
      'response': 'Admin sedang memeriksa status pembayaran.',
    },
    {
      'id': 'PGD-003',
      'category': 'Pekerjaan',
      'title': 'Detail pekerjaan tidak sesuai',
      'description':
          'Pekerjaan yang diterima berbeda dengan deskripsi awal yang diberikan pelanggan.',
      'jobId': 'JOB-003',
      'date': '08 September 2026',
      'status': 'Selesai',
      'response':
          'Admin telah menghubungi pelanggan dan menyelesaikan permasalahan.',
    },
  ];

  final List<String> _categories = [
    'Pelanggan Bermasalah',
    'Pembayaran',
    'Pekerjaan',
    'Aplikasi',
    'Lainnya',
  ];

  String _selectedFilter = 'Semua';

  List<Map<String, dynamic>> get _filteredComplaints {
    if (_selectedFilter == 'Semua') {
      return _complaints;
    }

    return _complaints
        .where((complaint) => complaint['status'] == _selectedFilter)
        .toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Menunggu':
        return Colors.orange;
      case 'Diproses':
        return Colors.blue;
      case 'Selesai':
        return Colors.green;
      case 'Ditolak':
        return Colors.red;
      default:
        return Colors.grey;
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

  Widget _statusBadge(String status) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
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
            _getStatusIcon(status),
            size: 15,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateComplaintDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final jobIdController = TextEditingController();

    String selectedCategory = _categories.first;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.report_problem_outlined),
                  SizedBox(width: 10),
                  Text('Buat Pengaduan'),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Kategori Pengaduan',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            selectedCategory = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Judul Pengaduan',
                          hintText: 'Contoh: Pembayaran belum diterima',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: jobIdController,
                        decoration: const InputDecoration(
                          labelText: 'ID Pekerjaan',
                          hintText: 'Contoh: JOB-004',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi Pengaduan',
                          hintText: 'Jelaskan masalah yang terjadi...',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty ||
                        descriptionController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Judul dan deskripsi harus diisi.',
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      _complaints.insert(0, {
                        'id': 'PGD-${(_complaints.length + 1).toString().padLeft(3, '0')}',
                        'category': selectedCategory,
                        'title': titleController.text.trim(),
                        'description': descriptionController.text.trim(),
                        'jobId': jobIdController.text.trim().isEmpty
                            ? '-'
                            : jobIdController.text.trim(),
                        'date': '12 September 2026',
                        'status': 'Menunggu',
                        'response': '-',
                      });
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Pengaduan berhasil dibuat.',
                        ),
                      ),
                    );
                  },
                  child: const Text('Kirim Pengaduan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showComplaintDetail(Map<String, dynamic> complaint) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.description_outlined),
              SizedBox(width: 10),
              Text('Detail Pengaduan'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('ID Pengaduan', complaint['id']),
                  _detailRow('Kategori', complaint['category']),
                  _detailRow('ID Pekerjaan', complaint['jobId']),
                  _detailRow('Tanggal', complaint['date']),
                  _detailRow('Judul', complaint['title']),
                  const SizedBox(height: 12),
                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(complaint['description']),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tanggapan Admin',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(complaint['response']),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Status: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _statusBadge(complaint['status']),
                    ],
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
            child: Icon(
              icon,
              color: color,
              size: 26,
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
                const SizedBox(height: 6),
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
    final waiting = _complaints
        .where((complaint) => complaint['status'] == 'Menunggu')
        .length;

    final processing = _complaints
        .where((complaint) => complaint['status'] == 'Diproses')
        .length;

    final completed = _complaints
        .where((complaint) => complaint['status'] == 'Selesai')
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;

        final cards = [
          _summaryCard(
            title: 'Total Pengaduan',
            value: '${_complaints.length}',
            icon: Icons.report_problem_outlined,
            color: Colors.blue,
          ),
          _summaryCard(
            title: 'Menunggu',
            value: '$waiting',
            icon: Icons.access_time,
            color: Colors.orange,
          ),
          _summaryCard(
            title: 'Diproses',
            value: '$processing',
            icon: Icons.sync,
            color: Colors.purple,
          ),
          _summaryCard(
            title: 'Selesai',
            value: '$completed',
            icon: Icons.check_circle_outline,
            color: Colors.green,
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
            for (int i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i != cards.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFilterSection() {
    const filters = [
      'Semua',
      'Menunggu',
      'Diproses',
      'Selesai',
      'Ditolak',
    ];

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
            'Filter Status:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 15),
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<String>(
              value: _selectedFilter,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
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
                });
              },
            ),
          ),
          const Spacer(),
          Text(
            '${_filteredComplaints.length} pengaduan',
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

  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
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
                  complaint['id'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              _statusBadge(complaint['status']),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            complaint['title'],
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            complaint['category'],
            style: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          _infoRow(
            Icons.work_outline,
            'ID Pekerjaan',
            complaint['jobId'],
          ),
          _infoRow(
            Icons.calendar_today_outlined,
            'Tanggal',
            complaint['date'],
          ),
          const SizedBox(height: 8),
          Text(
            complaint['description'],
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showComplaintDetail(complaint),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Lihat Detail Pengaduan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
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
          const SizedBox(width: 9),
          SizedBox(
            width: 110,
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

  Widget _buildDesktopTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
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
            DataColumn(label: Text('Judul Pengaduan')),
            DataColumn(label: Text('Kategori')),
            DataColumn(label: Text('ID Pekerjaan')),
            DataColumn(label: Text('Tanggal')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Aksi')),
          ],
          rows: _filteredComplaints.map((complaint) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    complaint['id'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 220,
                    child: Text(complaint['title']),
                  ),
                ),
                DataCell(Text(complaint['category'])),
                DataCell(Text(complaint['jobId'])),
                DataCell(Text(complaint['date'])),
                DataCell(_statusBadge(complaint['status'])),
                DataCell(
                  IconButton(
                    tooltip: 'Lihat Detail',
                    icon: const Icon(Icons.visibility_outlined),
                    onPressed: () {
                      _showComplaintDetail(complaint);
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

  @override
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 800;

      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              minHeight: constraints.maxHeight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pengaduan Saya',
                            style: TextStyle(
                              fontSize: isMobile ? 24 : 28,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ajukan dan pantau pengaduan kepada Admin.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _showCreateComplaintDialog,
                      icon: const Icon(Icons.add),
                      label: Text(
                        isMobile ? 'Buat' : 'Buat Pengaduan',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSummarySection(),
                const SizedBox(height: 24),
                _buildFilterSection(),
                const SizedBox(height: 18),
                if (_filteredComplaints.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(35),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.report_problem_outlined,
                          size: 55,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Belum ada pengaduan.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                else if (isMobile)
                  Column(
                    children: _filteredComplaints
                        .map(_buildComplaintCard)
                        .toList(),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: _buildDesktopTable(),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
  }
}