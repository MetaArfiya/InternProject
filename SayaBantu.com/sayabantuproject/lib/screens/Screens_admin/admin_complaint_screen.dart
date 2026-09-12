import 'package:flutter/material.dart';

class AdminComplaintScreen extends StatefulWidget {
  const AdminComplaintScreen({super.key});

  @override
  State<AdminComplaintScreen> createState() =>
      _AdminComplaintScreenState();
}

class _AdminComplaintScreenState extends State<AdminComplaintScreen> {
  final List<Map<String, dynamic>> _complaints = [
    {
      'id': 'PGD-001',
      'mitra': 'Budi Santoso',
      'pelanggan': 'Andi Pratama',
      'pekerjaan': 'Service AC Bocor',
      'nominal': 145000,
      'tanggal': '12 Sep 2026',
      'status': 'Menunggu',
      'deskripsi':
          'Pekerjaan telah selesai dilakukan, tetapi pelanggan belum melakukan pembayaran sesuai kesepakatan awal.',
    },
    {
      'id': 'PGD-002',
      'mitra': 'Dewi Lestari',
      'pelanggan': 'Siti Rahma',
      'pekerjaan': 'Perbaikan Kunci Rumah',
      'nominal': 85000,
      'tanggal': '11 Sep 2026',
      'status': 'Diproses',
      'deskripsi':
          'Mitra menyatakan pekerjaan sudah selesai dan pelanggan belum memberikan pembayaran.',
    },
    {
      'id': 'PGD-003',
      'mitra': 'Rudi Hartono',
      'pelanggan': 'Fajar Nugroho',
      'pekerjaan': 'Pemasangan Lampu Teras',
      'nominal': 120000,
      'tanggal': '10 Sep 2026',
      'status': 'Selesai',
      'deskripsi':
          'Pengaduan telah ditangani oleh admin dan pembayaran telah dikonfirmasi.',
    },
    {
      'id': 'PGD-004',
      'mitra': 'Andi Wijaya',
      'pelanggan': 'Maya Putri',
      'pekerjaan': 'Pengecatan Rumah',
      'nominal': 350000,
      'tanggal': '09 Sep 2026',
      'status': 'Ditolak',
      'deskripsi':
          'Pengaduan ditolak karena bukti penyelesaian pekerjaan belum mencukupi.',
    },
  ];

  String _selectedFilter = 'Semua';

  final List<String> _filters = [
    'Semua',
    'Menunggu',
    'Diproses',
    'Selesai',
    'Ditolak',
  ];

  // =========================================================
  // FORMAT RUPIAH
  // =========================================================

  String _formatRupiah(dynamic value) {
    final number = int.tryParse(value.toString()) ?? 0;
    final formatted = number.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        );

    return 'Rp$formatted';
  }

  // =========================================================
  // FILTER DATA
  // =========================================================

  List<Map<String, dynamic>> get _filteredComplaints {
    if (_selectedFilter == 'Semua') {
      return _complaints;
    }

    return _complaints
        .where(
          (complaint) =>
              complaint['status'] == _selectedFilter,
        )
        .toList();
  }

  // =========================================================
  // STATISTIK
  // =========================================================

  int _countByStatus(String status) {
    return _complaints
        .where((complaint) => complaint['status'] == status)
        .length;
  }

  // =========================================================
  // UBAH STATUS
  // =========================================================

  void _updateComplaintStatus(
    String complaintId,
    String newStatus,
  ) {
    setState(() {
      final index = _complaints.indexWhere(
        (complaint) => complaint['id'] == complaintId,
      );

      if (index != -1) {
        _complaints[index]['status'] = newStatus;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Status pengaduan berhasil diubah menjadi $newStatus.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================
  // DETAIL PENGADUAN
  // =========================================================

  void _showComplaintDetail(
    Map<String, dynamic> complaint,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
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
                  _detailRow(
                    'ID Pengaduan',
                    complaint['id'].toString(),
                  ),
                  _detailRow(
                    'Tanggal',
                    complaint['tanggal'].toString(),
                  ),
                  _detailRow(
                    'Nama Mitra',
                    complaint['mitra'].toString(),
                  ),
                  _detailRow(
                    'Nama Pelanggan',
                    complaint['pelanggan'].toString(),
                  ),
                  _detailRow(
                    'Pekerjaan',
                    complaint['pekerjaan'].toString(),
                  ),
                  _detailRow(
                    'Nominal',
                    _formatRupiah(complaint['nominal']),
                  ),
                  _detailRow(
                    'Status',
                    complaint['status'].toString(),
                  ),
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
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      complaint['deskripsi'].toString(),
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Tutup'),
            ),
            if (complaint['status'] == 'Menunggu')
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();

                  _updateComplaintStatus(
                    complaint['id'].toString(),
                    'Diproses',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text('Proses Pengaduan'),
              ),
            if (complaint['status'] == 'Diproses')
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();

                  _updateComplaintStatus(
                    complaint['id'].toString(),
                    'Selesai',
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

  Widget _detailRow(
    String label,
    String value,
  ) {
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
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
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

  // =========================================================
  // KONFIRMASI TOLAK
  // =========================================================

  void _confirmReject(
    Map<String, dynamic> complaint,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            'Tolak Pengaduan?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'Apakah kamu yakin ingin menolak pengaduan ini?',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                _updateComplaintStatus(
                  complaint['id'].toString(),
                  'Ditolak',
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

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile),
          const SizedBox(height: 24),
          _buildStatistics(isMobile),
          const SizedBox(height: 24),
          _buildComplaintSection(isMobile),
        ],
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pengaduan Mitra',
          style: TextStyle(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kelola pengaduan mitra terkait pekerjaan yang belum dibayar pelanggan.',
          style: TextStyle(
            fontSize: isMobile ? 12 : 13,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // STATISTIK
  // =========================================================

  Widget _buildStatistics(bool isMobile) {
    final cards = [
      {
        'title': 'Menunggu',
        'value': _countByStatus('Menunggu'),
        'subtitle': 'Pengaduan baru',
        'icon': Icons.hourglass_empty_outlined,
        'color': const Color(0xFFF59E0B),
        'background': const Color(0xFFFFF7ED),
      },
      {
        'title': 'Diproses',
        'value': _countByStatus('Diproses'),
        'subtitle': 'Sedang ditangani',
        'icon': Icons.sync_outlined,
        'color': const Color(0xFF3B82F6),
        'background': const Color(0xFFEFF6FF),
      },
      {
        'title': 'Selesai',
        'value': _countByStatus('Selesai'),
        'subtitle': 'Telah diselesaikan',
        'icon': Icons.check_circle_outline,
        'color': const Color(0xFF10B981),
        'background': const Color(0xFFECFDF5),
      },
      {
        'title': 'Ditolak',
        'value': _countByStatus('Ditolak'),
        'subtitle': 'Pengaduan ditolak',
        'icon': Icons.cancel_outlined,
        'color': const Color(0xFFEF4444),
        'background': const Color(0xFFFEF2F2),
      },
    ];

    if (isMobile) {
      return Column(
        children: cards
            .map(
              (card) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildStatisticCard(card),
              ),
            )
            .toList(),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width < 1050
            ? 2
            : 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemBuilder: (context, index) {
        return _buildStatisticCard(cards[index]);
      },
    );
  }

  Widget _buildStatisticCard(
    Map<String, dynamic> card,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
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
                  style: const TextStyle(
                    fontSize: 10,
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

  // =========================================================
  // SECTION PENGADUAN
  // =========================================================

  Widget _buildComplaintSection(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
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
                Expanded(
                  child: _buildSectionTitle(),
                ),
                _buildFilterDropdown(),
              ],
            ),
          const SizedBox(height: 18),
          const Divider(
            height: 1,
            color: Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 12),
          if (_filteredComplaints.isEmpty)
            _buildEmptyState()
          else if (isMobile)
            Column(
              children: _filteredComplaints
                  .map(
                    (complaint) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildComplaintCard(complaint),
                    ),
                  )
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
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
          ),
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF334155),
          ),
          items: _filters
              .map(
                (filter) => DropdownMenuItem<String>(
                  value: filter,
                  child: Text(filter),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _selectedFilter = value;
            });
          },
        ),
      ),
    );
  }

  // =========================================================
  // DESKTOP TABLE
  // =========================================================

  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 950,
        ),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            const Color(0xFFF8FAFC),
          ),
          dataRowMinHeight: 70,
          dataRowMaxHeight: 90,
          columnSpacing: 24,
          horizontalMargin: 12,
          columns: const [
            DataColumn(
              label: Text('Pengaduan'),
            ),
            DataColumn(
              label: Text('Mitra'),
            ),
            DataColumn(
              label: Text('Pekerjaan'),
            ),
            DataColumn(
              label: Text('Nominal'),
            ),
            DataColumn(
              label: Text('Status'),
            ),
            DataColumn(
              label: Text('Aksi'),
            ),
          ],
          rows: _filteredComplaints
              .map(
                (complaint) => DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              complaint['id'].toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              complaint['tanggal'].toString(),
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
                        width: 130,
                        child: Text(
                          complaint['mitra'].toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 160,
                        child: Text(
                          complaint['pekerjaan'].toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        _formatRupiah(complaint['nominal']),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    DataCell(
                      _buildStatusBadge(
                        complaint['status'].toString(),
                      ),
                    ),
                    DataCell(
                      _buildActionButtons(complaint),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  // =========================================================
  // MOBILE CARD
  // =========================================================

  Widget _buildComplaintCard(
    Map<String, dynamic> complaint,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  complaint['id'].toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              _buildStatusBadge(
                complaint['status'].toString(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _mobileInfoRow(
            Icons.person_outline,
            'Mitra',
            complaint['mitra'].toString(),
          ),
          _mobileInfoRow(
            Icons.person_search_outlined,
            'Pelanggan',
            complaint['pelanggan'].toString(),
          ),
          _mobileInfoRow(
            Icons.work_outline,
            'Pekerjaan',
            complaint['pekerjaan'].toString(),
          ),
          _mobileInfoRow(
            Icons.payments_outlined,
            'Nominal',
            _formatRupiah(complaint['nominal']),
          ),
          _mobileInfoRow(
            Icons.calendar_today_outlined,
            'Tanggal',
            complaint['tanggal'].toString(),
          ),
          const SizedBox(height: 12),
          _buildActionButtons(complaint),
        ],
      ),
    );
  }

  Widget _mobileInfoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF64748B),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 75,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
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

  // =========================================================
  // STATUS BADGE
  // =========================================================

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
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
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

  // =========================================================
  // ACTION BUTTONS
  // =========================================================

  Widget _buildActionButtons(
    Map<String, dynamic> complaint,
  ) {
    final status = complaint['status'].toString();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            _showComplaintDetail(complaint);
          },
          icon: const Icon(
            Icons.visibility_outlined,
            size: 14,
          ),
          label: const Text('Detail'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF7C3AED),
            side: const BorderSide(
              color: Color(0xFFD8B4FE),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            textStyle: const TextStyle(
              fontSize: 11,
            ),
          ),
        ),
        if (status == 'Menunggu')
          ElevatedButton(
            onPressed: () {
              _updateComplaintStatus(
                complaint['id'].toString(),
                'Diproses',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              textStyle: const TextStyle(
                fontSize: 11,
              ),
            ),
            child: const Text('Proses'),
          ),
        if (status == 'Diproses')
          ElevatedButton(
            onPressed: () {
              _updateComplaintStatus(
                complaint['id'].toString(),
                'Selesai',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              textStyle: const TextStyle(
                fontSize: 11,
              ),
            ),
            child: const Text('Selesai'),
          ),
        if (status == 'Menunggu' || status == 'Diproses')
          OutlinedButton(
            onPressed: () {
              _confirmReject(complaint);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(
                color: Color(0xFFFCA5A5),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              textStyle: const TextStyle(
                fontSize: 11,
              ),
            ),
            child: const Text('Tolak'),
          ),
      ],
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 45),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
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
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}