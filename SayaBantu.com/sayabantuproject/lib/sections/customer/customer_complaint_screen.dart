// lib/sections/customer/customer_complaint_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/complaint_model.dart';
import '../../services/api_service.dart';

class CustomerComplaintScreen extends StatefulWidget {
  const CustomerComplaintScreen({super.key});

  @override
  State<CustomerComplaintScreen> createState() =>
      _CustomerComplaintScreenState();
}

class _CustomerComplaintScreenState extends State<CustomerComplaintScreen> {
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

  // Kategori khusus pelanggan
  final List<String> _categories = [
    'Mitra Bermasalah',
    'Kualitas Pekerjaan',
    'Pembayaran',
    'Aplikasi',
    'Lainnya',
  ];

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
      final response = await ApiService.get('/complaints/my');

      debugPrint('📢 CUSTOMER COMPLAINTS: ${response.statusCode}');
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

      setState(() {
        final s = decoded['summary'] ?? {};
        _summary = {
          'total':    int.tryParse(s['total']?.toString() ?? '0') ?? 0,
          'menunggu': int.tryParse(s['menunggu']?.toString() ?? '0') ?? 0,
          'diproses': int.tryParse(s['diproses']?.toString() ?? '0') ?? 0,
          'selesai':  int.tryParse(s['selesai']?.toString() ?? '0') ?? 0,
          'ditolak':  int.tryParse(s['ditolak']?.toString() ?? '0') ?? 0,
        };

        _complaints = (decoded['data'] is List)
            ? (decoded['data'] as List)
                .map((e) => ComplaintModel.fromJson(e))
                .toList()
            : [];

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

  List<ComplaintModel> get _filteredComplaints {
    if (_selectedFilter == 'Semua') return _complaints;
    return _complaints.where((c) => c.status == _selectedFilter).toList();
  }

  // ============================================================
  // HELPERS
  // ============================================================
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Menunggu': return Colors.orange;
      case 'Diproses': return Colors.blue;
      case 'Selesai':  return Colors.green;
      case 'Ditolak':  return Colors.red;
      default:         return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Menunggu': return Icons.access_time;
      case 'Diproses': return Icons.sync;
      case 'Selesai':  return Icons.check_circle_outline;
      case 'Ditolak':  return Icons.cancel_outlined;
      default:         return Icons.info_outline;
    }
  }

  Widget _statusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(status), size: 15, color: color),
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

  // ============================================================
  // CREATE COMPLAINT
  // ============================================================
  void _showCreateComplaintDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final jobIdController = TextEditingController();

    String selectedCategory = _categories.first;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
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
                        onChanged: isSubmitting
                            ? null
                            : (value) {
                                if (value == null) return;
                                setDialogState(() => selectedCategory = value);
                              },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: titleController,
                        enabled: !isSubmitting,
                        decoration: const InputDecoration(
                          labelText: 'Judul Pengaduan',
                          hintText: 'Contoh: Mitra tidak datang sesuai jadwal',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: jobIdController,
                        enabled: !isSubmitting,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'ID Pekerjaan (opsional)',
                          hintText: 'Contoh: 5',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: descriptionController,
                        enabled: !isSubmitting,
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
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          final desc = descriptionController.text.trim();

                          if (title.isEmpty || desc.isEmpty) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Judul dan deskripsi harus diisi.'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          int? jobId;
                          final jobIdText = jobIdController.text.trim();
                          if (jobIdText.isNotEmpty) {
                            jobId = int.tryParse(jobIdText);
                          }

                          final success = await _submitComplaint(
                            category: selectedCategory,
                            title: title,
                            description: desc,
                            jobId: jobId,
                          );

                          if (!mounted) return;

                          if (success) {
                            Navigator.pop(dialogContext);
                            _loadComplaints();
                          } else {
                            setDialogState(() => isSubmitting = false);
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Kirim Pengaduan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _submitComplaint({
    required String category,
    required String title,
    required String description,
    int? jobId,
  }) async {
    try {
      final body = {
        'category': category,
        'title': title,
        'description': description,
        if (jobId != null) 'job_id': jobId,
      };

      final response = await ApiService.post('/complaints', body);

      debugPrint('📢 POST /complaints → ${response.statusCode}');
      debugPrint('📢 BODY: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaduan berhasil dibuat.'),
            backgroundColor: Colors.green,
          ),
        );
        return true;
      } else {
        String message = 'Gagal mengirim pengaduan.';
        try {
          final decoded = jsonDecode(response.body);
          message = decoded['message']?.toString() ?? message;
        } catch (_) {}

        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
        return false;
      }
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      return false;
    }
  }

  // ============================================================
  // DETAIL
  // ============================================================
  void _showComplaintDetail(ComplaintModel complaint) {
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
                  _detailRow('ID Pengaduan', complaint.code),
                  _detailRow('Kategori', complaint.category),
                  _detailRow('ID Pekerjaan', complaint.jobCode),
                  _detailRow('Tanggal', complaint.formattedDate),
                  _detailRow('Judul', complaint.title),
                  const SizedBox(height: 12),
                  const Text(
                    'Deskripsi',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(complaint.description),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tanggapan Admin',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      complaint.adminResponse ??
                          'Belum ada tanggapan dari admin.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Status: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      _statusBadge(complaint.status),
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
            child: Text(label, style: const TextStyle(color: Colors.grey)),
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
  // SUMMARY CARD
  // ============================================================
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
            child: Icon(icon, color: color, size: 26),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;

        final cards = [
          _summaryCard(
            title: 'Total Pengaduan',
            value: '${_summary['total'] ?? 0}',
            icon: Icons.report_problem_outlined,
            color: Colors.blue,
          ),
          _summaryCard(
            title: 'Menunggu',
            value: '${_summary['menunggu'] ?? 0}',
            icon: Icons.access_time,
            color: Colors.orange,
          ),
          _summaryCard(
            title: 'Diproses',
            value: '${_summary['diproses'] ?? 0}',
            icon: Icons.sync,
            color: Colors.purple,
          ),
          _summaryCard(
            title: 'Selesai',
            value: '${_summary['selesai'] ?? 0}',
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

  // ============================================================
  // FILTER
  // ============================================================
  Widget _buildFilterSection() {
    const filters = ['Semua', 'Menunggu', 'Diproses', 'Selesai', 'Ditolak'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.4),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 550;

          final dropdown = DropdownButtonFormField<String>(
            value: _selectedFilter,
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: filters.map((filter) {
              return DropdownMenuItem<String>(
                value: filter,
                child: Text(filter, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedFilter = value);
            },
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.filter_list, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Filter Status',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      '${_filteredComplaints.length} pengaduan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                dropdown,
              ],
            );
          }

          return Row(
            children: [
              const Icon(Icons.filter_list, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Filter Status:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 15),
              SizedBox(width: 200, child: dropdown),
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
          );
        },
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================
  Widget _buildComplaintCard(ComplaintModel complaint) {
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
                  complaint.code,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              _statusBadge(complaint.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            complaint.title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            complaint.category,
            style: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.work_outline, 'ID Pekerjaan', complaint.jobCode),
          _infoRow(
              Icons.calendar_today_outlined, 'Tanggal', complaint.formattedDate),
          const SizedBox(height: 8),
          Text(
            complaint.description,
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

  Widget _infoRow(IconData icon, String label, String value) {
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
              style: const TextStyle(fontWeight: FontWeight.w500),
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
                    complaint.code,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataCell(
                  SizedBox(width: 220, child: Text(complaint.title)),
                ),
                DataCell(Text(complaint.category)),
                DataCell(Text(complaint.jobCode)),
                DataCell(Text(complaint.formattedDate)),
                DataCell(_statusBadge(complaint.status)),
                DataCell(
                  IconButton(
                    tooltip: 'Lihat Detail',
                    icon: const Icon(Icons.visibility_outlined),
                    onPressed: () => _showComplaintDetail(complaint),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
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

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: RefreshIndicator(
            onRefresh: _loadComplaints,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  minHeight: constraints.maxHeight,
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
                          label: Text(isMobile ? 'Buat' : 'Buat Pengaduan'),
                        ),
                      ],
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
                      _buildSummarySection(),
                      const SizedBox(height: 24),
                      _buildFilterSection(),
                      const SizedBox(height: 18),
                      if (_filteredComplaints.isEmpty)
                        _buildEmptyState()
                      else if (isMobile)
                        Column(
                          children: _filteredComplaints
                              .map(_buildComplaintCard)
                              .toList(),
                        )
                      else
                        _buildDesktopTable(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
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

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.report_problem_outlined, size: 55, color: Colors.grey),
          SizedBox(height: 12),
          Text('Belum ada pengaduan.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}