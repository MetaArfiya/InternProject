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

class _CustomerComplaintScreenState
    extends State<CustomerComplaintScreen> {
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
  // ============================================================

  static const double _titleFontSize = 20;
  static const double _subtitleFontSize = 13;
  static const double _bodyFontSize = 13;
  static const double _fieldFontSize = 13;
  static const double _buttonFontSize = 13;

  static const double _fieldHeight = 42;
  static const double _cardRadius = 16;
  static const double _smallRadius = 12;

  // ============================================================
  // INIT
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

      if (!mounted) return;

      setState(() {
        final s = decoded['summary'] ?? {};

        _summary = {
          'total':
              int.tryParse(
                    s['total']?.toString() ?? '0',
                  ) ??
                  0,
          'menunggu':
              int.tryParse(
                    s['menunggu']?.toString() ?? '0',
                  ) ??
                  0,
          'diproses':
              int.tryParse(
                    s['diproses']?.toString() ?? '0',
                  ) ??
                  0,
          'selesai':
              int.tryParse(
                    s['selesai']?.toString() ?? '0',
                  ) ??
                  0,
          'ditolak':
              int.tryParse(
                    s['ditolak']?.toString() ?? '0',
                  ) ??
                  0,
        };

        _complaints =
            decoded['data'] is List
                ? (decoded['data'] as List)
                    .map(
                      (e) =>
                          ComplaintModel.fromJson(e),
                    )
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

  // ============================================================
  // FILTER
  // ============================================================

  List<ComplaintModel> get _filteredComplaints {
    if (_selectedFilter == 'Semua') {
      return _complaints;
    }

    return _complaints
        .where(
          (c) => c.status == _selectedFilter,
        )
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
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.report_problem_outlined),
                  SizedBox(width: 10),
                  Text(
                    'Buat Pengaduan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                        isExpanded: true,
                        decoration: _inputDecoration(
                          'Kategori Pengaduan',
                        ),
                        style: TextStyle(
                          fontSize: _fieldFontSize,
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color,
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(
                              category,
                              style: const TextStyle(
                                fontSize: _fieldFontSize,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: isSubmitting
                            ? null
                            : (value) {
                                if (value == null) {
                                  return;
                                }

                                setDialogState(
                                  () {
                                    selectedCategory =
                                        value;
                                  },
                                );
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
                          'Judul Pengaduan',
                          hint:
                              'Contoh: Mitra tidak datang sesuai jadwal',
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: jobIdController,
                        enabled: !isSubmitting,
                        keyboardType:
                            TextInputType.number,
                        style: const TextStyle(
                          fontSize: _fieldFontSize,
                        ),
                        decoration: _inputDecoration(
                          'ID Pekerjaan (opsional)',
                          hint: 'Contoh: 5',
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller:
                            descriptionController,
                        enabled: !isSubmitting,
                        maxLines: 4,
                        style: const TextStyle(
                          fontSize: _fieldFontSize,
                        ),
                        decoration: _inputDecoration(
                          'Deskripsi Pengaduan',
                          hint:
                              'Jelaskan masalah yang terjadi...',
                        ).copyWith(
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
                      : () {
                          Navigator.pop(
                            dialogContext,
                          );
                        },
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
                              titleController.text
                                  .trim();

                          final desc =
                              descriptionController
                                  .text
                                  .trim();

                          if (title.isEmpty ||
                              desc.isEmpty) {
                            ScaffoldMessenger.of(
                              this.context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Judul dan deskripsi harus diisi.',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(
                            () => isSubmitting = true,
                          );

                          int? jobId;

                          final jobIdText =
                              jobIdController.text
                                  .trim();

                          if (jobIdText.isNotEmpty) {
                            jobId =
                                int.tryParse(
                                  jobIdText,
                                );
                          }

                          final success =
                              await _submitComplaint(
                            category:
                                selectedCategory,
                            title: title,
                            description: desc,
                            jobId: jobId,
                          );

                          if (!mounted) return;

                          if (success) {
                            Navigator.pop(
                              dialogContext,
                            );
                            _loadComplaints();
                          } else {
                            setDialogState(
                              () => isSubmitting =
                                  false,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        _smallRadius,
                      ),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Kirim Pengaduan',
                          style: TextStyle(
                            fontSize:
                                _buttonFontSize,
                            fontWeight:
                                FontWeight.w600,
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

  InputDecoration _inputDecoration(
    String label, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(6),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(6),
        borderSide: BorderSide(
          color: Colors.grey.withOpacity(0.35),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(6),
        borderSide: const BorderSide(
          color: Colors.orange,
        ),
      ),
      labelStyle: const TextStyle(
        fontSize: _fieldFontSize,
      ),
      hintStyle: TextStyle(
        fontSize: _fieldFontSize,
        color: Colors.grey.shade500,
      ),
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

      final response =
          await ApiService.post(
        '/complaints',
        body,
      );

      debugPrint(
        '📢 POST /complaints → ${response.statusCode}',
      );
      debugPrint(
        '📢 BODY: ${response.body}',
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        if (!mounted) return false;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Pengaduan berhasil dibuat.',
            ),
            backgroundColor: Colors.green,
          ),
        );

        return true;
      }

      String message =
          'Gagal mengirim pengaduan.';

      try {
        final decoded =
            jsonDecode(response.body);

        message =
            decoded['message']?.toString() ??
                message;
      } catch (_) {}

      if (!mounted) return false;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );

      return false;
    } catch (e) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );

      return false;
    }
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(bool isMobile) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Pengaduan Saya',
                style: TextStyle(
                  fontSize: _titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ajukan dan pantau pengaduan kepada Admin.',
                style: TextStyle(
                  fontSize: _subtitleFontSize,
                  color: Colors.grey.shade600,
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
            size: 17,
          ),
          label: Text(
            isMobile
                ? 'Buat'
                : 'Buat Pengaduan',
            style: const TextStyle(
              fontSize: _buttonFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                _smallRadius,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary(
    bool isMobile,
  ) {
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
        children: cards
            .expand(
              (card) => [
                card,
                const SizedBox(height: 12),
              ],
            )
            .toList()
          ..removeLast(),
      );
    }

    return Row(
      children: cards
          .expand(
            (card) => [
              Expanded(child: card),
              const SizedBox(width: 16),
            ],
          )
          .toList()
        ..removeLast(),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            Theme.of(context).cardColor,
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.05,
            ),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:
                  color.withOpacity(0.12),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              color: color,
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
                    color:
                        Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
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

  Widget _buildFilterSection() {
    const filters = [
      'Semua',
      'Menunggu',
      'Diproses',
      'Selesai',
      'Ditolak',
    ];

    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color:
              Colors.grey.withOpacity(
            0.25,
          ),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.filter_list,
            size: 20,
            color: Colors.grey,
          ),

          const SizedBox(width: 10),

          const Text(
            'Filter Status:',
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w500,
            ),
          ),

          const SizedBox(width: 12),

          Container(
            width: 160,
            height: 42,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius:
                  BorderRadius.circular(6),
              border: Border.all(
                color:
                    Colors.grey.withOpacity(
                  0.35,
                ),
              ),
            ),
            child:
                DropdownButton<String>(
              value: _selectedFilter,
              isExpanded: true,
              underline:
                  const SizedBox(),
              menuWidth: 180,
              borderRadius:
                  BorderRadius.circular(8),
              dropdownColor:
                  theme.cardColor,
              icon: const Padding(
                padding:
                    EdgeInsets.only(
                  right: 8,
                ),
                child: Icon(
                  Icons
                      .keyboard_arrow_down,
                  size: 18,
                  color: Colors.grey,
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w400,
                color: theme
                    .textTheme
                    .bodyMedium
                    ?.color,
              ),
              items: filters.map(
                (filter) {
                  return DropdownMenuItem<
                      String>(
                    value: filter,
                    child: Text(
                      filter,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight
                                .w400,
                        color: theme
                            .textTheme
                            .bodyMedium
                            ?.color,
                      ),
                    ),
                  );
                },
              ).toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedFilter =
                      value;
                });
              },
            ),
          ),

          const Spacer(),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color:
                  Colors.orange.withOpacity(
                0.10,
              ),
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),
            child: Text(
              '${_filteredComplaints.length}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.orange,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
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
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            Theme.of(context).cardColor,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              Colors.grey.withOpacity(
            0.15,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  complaint.code,
                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              _statusBadge(
                complaint.status,
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            complaint.title,
            style:
                const TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            complaint.category,
            style: TextStyle(
              fontSize: 13,
              color:
                  Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          _infoRow(
            Icons.work_outline,
            'ID Pekerjaan',
            complaint.jobCode,
          ),

          const SizedBox(height: 8),

          _infoRow(
            Icons.calendar_today_outlined,
            'Tanggal',
            complaint.formattedDate,
          ),

          const SizedBox(height: 12),

          Text(
            complaint.description,
            maxLines: 3,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child:
                OutlinedButton.icon(
              onPressed: () =>
                  _showComplaintDetail(
                complaint,
              ),
              icon: const Icon(
                Icons.visibility_outlined,
                size: 17,
              ),
              label: const Text(
                'Lihat Detail Pengaduan',
                style: TextStyle(
                  fontSize:
                      _buttonFontSize,
                ),
              ),
              style:
                  OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 12,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
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
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey.shade500,
        ),
        const SizedBox(width: 9),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color:
                  Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style:
                const TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DESKTOP TABLE
  // ============================================================

  Widget _buildDesktopTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color:
            Theme.of(context).cardColor,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              Colors.grey.withOpacity(
            0.15,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection:
            Axis.horizontal,
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
                  fontSize: 13,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Judul Pengaduan',
                style: TextStyle(
                  fontSize: 13,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Kategori',
                style: TextStyle(
                  fontSize: 13,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'ID Pekerjaan',
                style: TextStyle(
                  fontSize: 13,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Tanggal',
                style: TextStyle(
                  fontSize: 13,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: TextStyle(
                  fontSize: 13,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Aksi',
                style: TextStyle(
                  fontSize: 13,
                ),
              ),
            ),
          ],
          rows: _filteredComplaints
              .map(
                (complaint) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          complaint.code,
                          style:
                              const TextStyle(
                            fontSize: 13,
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
                            style:
                                const TextStyle(
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          complaint.category,
                          style:
                              const TextStyle(
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          complaint.jobCode,
                          style:
                              const TextStyle(
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          complaint
                              .formattedDate,
                          style:
                              const TextStyle(
                            fontSize: 13,
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
                          tooltip:
                              'Lihat Detail',
                          icon:
                              const Icon(
                            Icons
                                .visibility_outlined,
                            size: 19,
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
              )
              .toList(),
        ),
      ),
    );
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
          title: const Row(
            children: [
              Icon(
                Icons.description_outlined,
              ),
              SizedBox(width: 10),
              Text(
                'Detail Pengaduan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child:
                SingleChildScrollView(
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
                      fontSize: 13,
                      fontWeight:
                          FontWeight.bold,
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
                      fontSize: 13,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

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
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      _statusBadge(
                        complaint.status,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
              ),
              child: const Text(
                'Tutup',
                style: TextStyle(
                  fontSize:
                      _buttonFontSize,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _detailBox(String value) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            Theme.of(context)
                .colorScheme
                .surface,
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Text(
        value,
        style:
            const TextStyle(
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color:
                    Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w500,
              ),
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
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context)
          .scaffoldBackgroundColor,
      child: RefreshIndicator(
        onRefresh: _loadComplaints,
        child: LayoutBuilder(
          builder:
              (context, constraints) {
            final isMobile =
                constraints.maxWidth <
                    700;

            return SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  EdgeInsets.all(
                isMobile ? 16 : 28,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildHeader(
                    isMobile,
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding:
                            EdgeInsets
                                .symmetric(
                          vertical: 60,
                        ),
                        child:
                            CircularProgressIndicator(
                          color:
                              Colors.orange,
                        ),
                      ),
                    )
                  else if (_errorMessage !=
                      null)
                    _buildErrorState()
                  else ...[
                    _buildSummary(
                      isMobile,
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    _buildFilterSection(),

                    const SizedBox(
                      height: 20,
                    ),

                    const Text(
                      'Riwayat Pengaduan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    if (_filteredComplaints
                        .isEmpty)
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
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color:
            Colors.red.withOpacity(0.05),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              Colors.red.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),

          const SizedBox(height: 12),

          Text(
            _errorMessage ??
                'Terjadi kesalahan.',
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 13,
              color: Colors.red,
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
            label: const Text(
              'Coba Lagi',
              style: TextStyle(
                fontSize:
                    _buttonFontSize,
              ),
            ),
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.orange,
              foregroundColor:
                  Colors.white,
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
      padding:
          const EdgeInsets.symmetric(
        vertical: 48,
      ),
      child: Column(
        children: [
          Icon(
            Icons
                .report_problem_outlined,
            size: 64,
            color:
                Colors.grey.shade300,
          ),

          const SizedBox(height: 16),

          Text(
            _selectedFilter == 'Semua'
                ? 'Belum ada pengaduan.'
                : 'Tidak ada pengaduan dengan status "$_selectedFilter".',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color:
                  Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}