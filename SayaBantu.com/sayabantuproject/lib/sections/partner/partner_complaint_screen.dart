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

  final List<String> _categories = [
    'Mitra Bermasalah',
    'Kualitas Pekerjaan',
    'Pembayaran',
    'Aplikasi',
    'Lainnya',
  ];

  // ============================================================
  // STANDARD UI
  // Mengikuti PaymentScreen
  // ============================================================

  static const double _bodyFontSize = 13;
  static const double _fieldFontSize = 13;
  static const double _buttonFontSize = 13;

  static const double _fieldHeight = 42;

  static const double _cardRadius = 16;
  static const double _smallRadius = 12;

  @override
  void initState() {
    super.initState();
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
      final response = await ApiService.get('/complaints/my');

      debugPrint(
        '📢 CUSTOMER COMPLAINTS: ${response.statusCode}',
      );
      debugPrint('📢 BODY: ${response.body}');

      if (response.statusCode != 200) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage =
              'Gagal memuat data (${response.statusCode}).';
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
          'total':
              int.tryParse(s['total']?.toString() ?? '0') ?? 0,
          'menunggu':
              int.tryParse(s['menunggu']?.toString() ?? '0') ?? 0,
          'diproses':
              int.tryParse(s['diproses']?.toString() ?? '0') ?? 0,
          'selesai':
              int.tryParse(s['selesai']?.toString() ?? '0') ?? 0,
          'ditolak':
              int.tryParse(s['ditolak']?.toString() ?? '0') ?? 0,
        };

        _complaints = decoded['data'] is List
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
    if (_selectedFilter == 'Semua') {
      return _complaints;
    }

    return _complaints
        .where((c) => c.status == _selectedFilter)
        .toList();
  }

  // ============================================================
  // STATUS
  // ============================================================

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
        vertical: 5,
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
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
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
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(
                'Buat Pengaduan',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDialogDropdown(
                        value: selectedCategory,
                        items: _categories,
                        label: 'Kategori Pengaduan',
                        enabled: !isSubmitting,
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            selectedCategory = value;
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      _buildDialogField(
                        controller: titleController,
                        label: 'Judul Pengaduan',
                        hint:
                            'Contoh: Mitra tidak datang sesuai jadwal',
                        enabled: !isSubmitting,
                      ),

                      const SizedBox(height: 14),

                      _buildDialogField(
                        controller: jobIdController,
                        label: 'ID Pekerjaan (opsional)',
                        hint: 'Contoh: 5',
                        enabled: !isSubmitting,
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 14),

                      _buildDialogField(
                        controller: descriptionController,
                        label: 'Deskripsi Pengaduan',
                        hint:
                            'Jelaskan masalah yang terjadi...',
                        enabled: !isSubmitting,
                        maxLines: 4,
                        alignLabelWithHint: true,
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
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      fontSize: _buttonFontSize,
                    ),
                  ),
                ),

                ElevatedButton(
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
                                  style: TextStyle(
                                    fontSize: _bodyFontSize,
                                  ),
                                ),
                              ),
                            );

                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                          });

                          int? jobId;

                          final jobIdText =
                              jobIdController.text.trim();

                          if (jobIdText.isNotEmpty) {
                            jobId = int.tryParse(jobIdText);
                          }

                          final success =
                              await _submitComplaint(
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
                            setDialogState(() {
                              isSubmitting = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
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
                          'Kirim Pengaduan',
                          style: TextStyle(
                            fontSize: _buttonFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogDropdown({
    required String value,
    required List<String> items,
    required String label,
    required bool enabled,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      height: _fieldHeight,
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        style: const TextStyle(
          fontSize: _fieldFontSize,
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: const TextStyle(
                fontSize: _fieldFontSize,
              ),
            ),
          );
        }).toList(),
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool enabled,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool alignLabelWithHint = false,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: _fieldFontSize,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: _fieldFontSize,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        alignLabelWithHint: alignLabelWithHint,
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
    int? jobId,
  }) async {
    try {
      final body = {
        'category': category,
        'title': title,
        'description': description,
        if (jobId != null) 'job_id': jobId,
      };

      final response = await ApiService.post(
        '/complaints',
        body,
      );

      debugPrint(
        '📢 POST /complaints → ${response.statusCode}',
      );
      debugPrint('📢 BODY: ${response.body}');

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        if (!mounted) return false;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pengaduan berhasil dibuat.',
              style: TextStyle(
                fontSize: _bodyFontSize,
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );

        return true;
      }

      String message = 'Gagal mengirim pengaduan.';

      try {
        final decoded = jsonDecode(response.body);

        message =
            decoded['message']?.toString() ?? message;
      } catch (_) {}

      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontSize: _bodyFontSize,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );

      return false;
    } catch (e) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
            style: const TextStyle(
              fontSize: _bodyFontSize,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );

      return false;
    }
  }

  // ============================================================
  // DETAIL
  // ============================================================

  void _showComplaintDetail(
    ComplaintModel complaint,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.description_outlined,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Detail Pengaduan',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _detailRow(
                    'ID Pengaduan',
                    complaint.code,
                  ),
                  _detailRow(
                    'Kategori',
                    complaint.category,
                  ),
                  _detailRow(
                    'ID Pekerjaan',
                    complaint.jobCode,
                  ),
                  _detailRow(
                    'Tanggal',
                    complaint.formattedDate,
                  ),
                  _detailRow(
                    'Judul',
                    complaint.title,
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontSize: _bodyFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  _detailBox(
                    complaint.description,
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Tanggapan Admin',
                    style: TextStyle(
                      fontSize: _bodyFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  _detailBox(
                    complaint.adminResponse ??
                        'Belum ada tanggapan dari admin.',
                  ),

                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Status: ',
                        style: TextStyle(
                          fontSize: _bodyFontSize,
                          fontWeight: FontWeight.bold,
                        ),
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
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text(
                'Tutup',
                style: TextStyle(
                  fontSize: _buttonFontSize,
                ),
              ),
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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: _bodyFontSize,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
        color: Theme.of(context)
            .colorScheme
            .surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: _bodyFontSize,
        ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(
          _cardRadius,
        ),
        border: Border.all(
          color: Theme.of(context)
              .dividerColor
              .withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(
                _smallRadius,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
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
                    fontSize: 19,
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
        final isMobile =
            constraints.maxWidth < 750;

        final cards = [
          _summaryCard(
            title: 'Total Pengaduan',
            value:
                '${_summary['total'] ?? 0}',
            icon:
                Icons.report_problem_outlined,
            color: Colors.blue,
          ),
          _summaryCard(
            title: 'Menunggu',
            value:
                '${_summary['menunggu'] ?? 0}',
            icon: Icons.access_time,
            color: Colors.orange,
          ),
          _summaryCard(
            title: 'Diproses',
            value:
                '${_summary['diproses'] ?? 0}',
            icon: Icons.sync,
            color: Colors.purple,
          ),
          _summaryCard(
            title: 'Selesai',
            value:
                '${_summary['selesai'] ?? 0}',
            icon:
                Icons.check_circle_outline,
            color: Colors.green,
          ),
        ];

        if (isMobile) {
          return Column(
            children: [
              for (int i = 0;
                  i < cards.length;
                  i++) ...[
                cards[i],
                if (i != cards.length - 1)
                  const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (int i = 0;
                i < cards.length;
                i++) ...[
              Expanded(
                child: cards[i],
              ),
              if (i != cards.length - 1)
                const SizedBox(width: 12),
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
    const filters = [
      'Semua',
      'Menunggu',
      'Diproses',
      'Selesai',
      'Ditolak',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context)
              .dividerColor
              .withOpacity(0.4),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow =
              constraints.maxWidth < 550;

          final dropdown =
              SizedBox(
            width: 160,
            height: _fieldHeight,
            child:
                DropdownButtonFormField<String>(
              value: _selectedFilter,
              isExpanded: true,
              decoration:
                  InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    6,
                  ),
                ),
                enabledBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    6,
                  ),
                ),
                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    6,
                  ),
                ),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                size: 18,
              ),
              items:
                  filters.map((filter) {
                return DropdownMenuItem<
                    String>(
                  value: filter,
                  child: Text(
                    filter,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize:
                          _fieldFontSize,
                      fontWeight:
                          FontWeight.w400,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedFilter = value;
                });
              },
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.filter_list,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Filter Status',
                      style: TextStyle(
                        fontSize:
                            _fieldFontSize,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_filteredComplaints.length} pengaduan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                        color: Theme.of(
                          context,
                        )
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                dropdown,
              ],
            );
          }

          return Row(
            children: [
              const Icon(
                Icons.filter_list,
                size: 20,
              ),

              const SizedBox(width: 8),

              const Text(
                'Filter Status:',
                style: TextStyle(
                  fontSize: _fieldFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(width: 12),

              dropdown,

              const Spacer(),

              Text(
                '${_filteredComplaints.length} pengaduan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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
  // COMPLAINT CARD
  // ============================================================

  Widget _buildComplaintCard(
    ComplaintModel complaint,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(
          _cardRadius,
        ),
        border: Border.all(
          color: Theme.of(context)
              .dividerColor
              .withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  complaint.code,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _statusBadge(
                complaint.status,
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            complaint.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            complaint.category,
            style: TextStyle(
              fontSize: _bodyFontSize,
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
            complaint.jobCode,
          ),

          _infoRow(
            Icons.calendar_today_outlined,
            'Tanggal',
            complaint.formattedDate,
          ),

          const SizedBox(height: 4),

          Text(
            complaint.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: _bodyFontSize,
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  _showComplaintDetail(
                complaint,
              ),
              icon: const Icon(
                Icons.visibility_outlined,
                size: 18,
              ),
              label: const Text(
                'Lihat Detail Pengaduan',
                style: TextStyle(
                  fontSize: _buttonFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
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
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
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
                fontSize: _bodyFontSize,
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
                fontSize: _bodyFontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DESKTOP TABLE
  // ============================================================

  Widget _buildDesktopTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(
          _cardRadius,
        ),
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
          headingRowColor:
              MaterialStateProperty.all(
            Theme.of(context)
                .colorScheme
                .surface,
          ),
          columns: const [
            DataColumn(
              label: Text(
                'ID',
                style: TextStyle(
                  fontSize: _bodyFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Judul Pengaduan',
                style: TextStyle(
                  fontSize: _bodyFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Kategori',
                style: TextStyle(
                  fontSize: _bodyFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'ID Pekerjaan',
                style: TextStyle(
                  fontSize: _bodyFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Tanggal',
                style: TextStyle(
                  fontSize: _bodyFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: TextStyle(
                  fontSize: _bodyFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Aksi',
                style: TextStyle(
                  fontSize: _bodyFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          rows: _filteredComplaints.map(
            (complaint) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      complaint.code,
                      style: const TextStyle(
                        fontSize: _bodyFontSize,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),

                  DataCell(
                    SizedBox(
                      width: 220,
                      child: Text(
                        complaint.title,
                        style: const TextStyle(
                          fontSize:
                              _bodyFontSize,
                        ),
                      ),
                    ),
                  ),

                  DataCell(
                    Text(
                      complaint.category,
                      style: const TextStyle(
                        fontSize:
                            _bodyFontSize,
                      ),
                    ),
                  ),

                  DataCell(
                    Text(
                      complaint.jobCode,
                      style: const TextStyle(
                        fontSize:
                            _bodyFontSize,
                      ),
                    ),
                  ),

                  DataCell(
                    Text(
                      complaint.formattedDate,
                      style: const TextStyle(
                        fontSize:
                            _bodyFontSize,
                      ),
                    ),
                  ),

                  DataCell(
                    _statusBadge(
                      complaint.status,
                    ),
                  ),

                  DataCell(
                    IconButton(
                      tooltip: 'Lihat Detail',
                      icon: const Icon(
                        Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () =>
                          _showComplaintDetail(
                        complaint,
                      ),
                    ),
                  ),
                ],
              );
            },
          ).toList(),
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
        final isMobile =
            constraints.maxWidth < 800;

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Theme.of(context)
              .scaffoldBackgroundColor,
          child: RefreshIndicator(
            onRefresh: _loadComplaints,
            child: SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(
                isMobile ? 16 : 28,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ============================
                    // HEADER
                    // ============================

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
                                'Pengaduan Saya',
                                style: Theme.of(
                                  context,
                                )
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                'Ajukan dan pantau pengaduan kepada Admin.',
                                style: Theme.of(
                                  context,
                                )
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      )
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withOpacity(
                                            0.7,
                                          ),
                                    ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        ElevatedButton.icon(
                          onPressed:
                              _showCreateComplaintDialog,
                          icon: const Icon(
                            Icons.add,
                            size: 18,
                          ),
                          label: Text(
                            isMobile
                                ? 'Buat'
                                : 'Buat Pengaduan',
                            style: const TextStyle(
                              fontSize:
                                  _buttonFontSize,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          style:
                              ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ============================
                    // CONTENT
                    // ============================

                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(
                            vertical: 80,
                          ),
                          child:
                              CircularProgressIndicator(
                            color: Colors.orange,
                          ),
                        ),
                      )
                    else if (_errorMessage != null)
                      _buildError()
                    else ...[
                      Text(
                        'Ringkasan Pengaduan',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                      ),

                      const SizedBox(height: 14),

                      _buildSummarySection(),

                      const SizedBox(height: 24),

                      Text(
                        'Riwayat Pengaduan',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                      ),

                      const SizedBox(height: 14),

                      _buildFilterSection(),

                      const SizedBox(height: 18),

                      if (_filteredComplaints.isEmpty)
                        _buildEmptyState()
                      else if (isMobile)
                        Column(
                          children:
                              _filteredComplaints
                                  .map(
                                    _buildComplaintCard,
                                  )
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

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(
          _cardRadius,
        ),
        border: Border.all(
          color: Colors.red.withOpacity(0.2),
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
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: _bodyFontSize,
              color: Colors.red,
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _loadComplaints,
            icon: const Icon(
              Icons.refresh,
              size: 18,
            ),
            label: const Text(
              'Coba Lagi',
              style: TextStyle(
                fontSize: _buttonFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(
          _cardRadius,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.report_problem_outlined,
            size: 48,
            color: Colors.grey,
          ),

          SizedBox(height: 12),

          Text(
            'Belum ada pengaduan.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}