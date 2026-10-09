import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/complaint_model.dart';
import '../../services/api_service.dart';

// ============================================================
// MODE FIELD PEKERJAAN
// ============================================================
enum _JobFieldMode { hidden, required, optional }

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

  List<Map<String, dynamic>> _myJobs = [];
  bool _isLoadingJobs = false;

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
  // DESIGN TOKENS — disamakan dengan DashboardHeader
  // ============================================================

  static const double _buttonFontSize = 13;
  static const double _fieldFontSize = 13;
  static const double _smallRadius = 12;

  static const Color _accent = Color(0xFFF97316);
  static const Color _tableBorder = Color(0xFFE5E7EB);
  static const Color _tableDivider = Color(0xFFF3F4F6);
  static const Color _headerText = Color(0xFF6B7280);
  static const Color _cellText = Color(0xFF111827);

  // Spacing — mengikuti pola DashboardHeader
  static const double _gapAfterHeader = 16;
  static const double _gapBetweenSections = 16;
  static const double _gapTitleToContent = 16;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadComplaints();
    _loadMyJobs();
  }

  // ============================================================
  // JOB FIELD MODE
  // ============================================================

  _JobFieldMode _jobFieldMode(String category) {
    switch (category) {
      case 'Aplikasi':
        return _JobFieldMode.hidden;
      case 'Pembayaran':
      case 'Kualitas Pekerjaan':
      case 'Mitra Bermasalah':
        return _JobFieldMode.required;
      case 'Lainnya':
      default:
        return _JobFieldMode.optional;
    }
  }

  // ============================================================
  // LOAD COMPLAINTS
  // ============================================================

  Future<void> _loadComplaints() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.get('/complaints/my');

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

      if (!mounted) return;

      setState(() {
        final s = decoded['summary'] ?? {};

        _summary = {
          'total': int.tryParse(s['total']?.toString() ?? '0') ?? 0,
          'menunggu': int.tryParse(s['menunggu']?.toString() ?? '0') ?? 0,
          'diproses': int.tryParse(s['diproses']?.toString() ?? '0') ?? 0,
          'selesai': int.tryParse(s['selesai']?.toString() ?? '0') ?? 0,
          'ditolak': int.tryParse(s['ditolak']?.toString() ?? '0') ?? 0,
        };

        _complaints = decoded['data'] is List
            ? (decoded['data'] as List)
                .map((e) => ComplaintModel.fromJson(e))
                .toList()
            : [];

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  // ============================================================
  // LOAD MY JOBS
  // ============================================================

  Future<void> _loadMyJobs() async {
    if (_isLoadingJobs) return;

    setState(() => _isLoadingJobs = true);

    try {
      final response = await ApiService.get(
        '/pelanggan/my-jobs/complaint-eligible',
      );

      if (response.statusCode != 200) {
        if (mounted) setState(() => _myJobs = []);
        return;
      }

      final decoded = jsonDecode(response.body);

      List<dynamic> rawList = [];
      if (decoded is Map) {
        if (decoded['data'] is List) {
          rawList = decoded['data'];
        } else if (decoded['jobs'] is List) {
          rawList = decoded['jobs'];
        }
      } else if (decoded is List) {
        rawList = decoded;
      }

      final parsed = rawList.map<Map<String, dynamic>>((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return {
          'id': m['id'] is int
              ? m['id']
              : int.tryParse(m['id']?.toString() ?? ''),
          'code': (m['code'] ??
                  m['job_code'] ??
                  m['kode'] ??
                  m['invoice_code'] ??
                  '#${m['id']}')
              .toString(),
          'title': (m['tittle'] ??
                  m['title'] ??
                  m['judul'] ??
                  m['name'] ??
                  m['job_title'] ??
                  'Pekerjaan')
              .toString(),
          'status': (m['status'] ?? '').toString(),
        };
      }).where((e) => e['id'] != null).toList();

      if (mounted) {
        setState(() => _myJobs = parsed);
      }
    } catch (e) {
      debugPrint('❌ Gagal load jobs: $e');
      if (mounted) setState(() => _myJobs = []);
    } finally {
      if (mounted) {
        setState(() => _isLoadingJobs = false);
      }
    }
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<ComplaintModel> get _filteredComplaints {
    if (_selectedFilter == 'Semua') {
      return _complaints;
    }
    return _complaints.where((c) => c.status == _selectedFilter).toList();
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

  Widget _statusBadge(BuildContext context, String status) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(status), size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            status,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CREATE COMPLAINT DIALOG
  // ============================================================

  void _showCreateComplaintDialog() async {
    if (_myJobs.isEmpty && !_isLoadingJobs) {
      await _loadMyJobs();
    }

    if (!mounted) return;

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    String selectedCategory = _categories.first;
    int? selectedJobId;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final jobMode = _jobFieldMode(selectedCategory);

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
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
                              borderRadius: BorderRadius.circular(10),
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
                              'Buat Pengaduan',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF111827),
                                  ),
                            ),
                          ),
                          IconButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.pop(dialogContext),
                            icon: const Icon(
                              Icons.close,
                              size: 20,
                              color: Color(0xFF6B7280),
                            ),
                            splashRadius: 22,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      // FORM (scrollable)
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // KATEGORI
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
                                        if (value == null) return;
                                        setDialogState(() {
                                          selectedCategory = value;
                                          if (_jobFieldMode(value) ==
                                              _JobFieldMode.hidden) {
                                            selectedJobId = null;
                                          }
                                        });
                                      },
                              ),

                              const SizedBox(height: 14),

                              // JUDUL
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

                              // JOB DROPDOWN
                              if (jobMode != _JobFieldMode.hidden) ...[
                                const SizedBox(height: 14),
                                _buildJobDropdown(
                                  isSubmitting: isSubmitting,
                                  selectedJobId: selectedJobId,
                                  isRequired:
                                      jobMode == _JobFieldMode.required,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      selectedJobId = value;
                                    });
                                  },
                                ),
                              ],

                              const SizedBox(height: 14),

                              // DESKRIPSI
                              TextField(
                                controller: descriptionController,
                                enabled: !isSubmitting,
                                maxLines: 4,
                                style: const TextStyle(
                                  fontSize: _fieldFontSize,
                                ),
                                decoration: _inputDecoration(
                                  'Deskripsi Pengaduan',
                                  hint: 'Jelaskan masalah yang terjadi...',
                                ).copyWith(alignLabelWithHint: true),
                              ),
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
                              onPressed: isSubmitting
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 46),
                                foregroundColor:
                                    const Color(0xFF374151),
                                side: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Batal',
                                style: TextStyle(
                                  fontSize: _buttonFontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      final title =
                                          titleController.text.trim();
                                      final desc = descriptionController
                                          .text
                                          .trim();

                                      if (title.isEmpty || desc.isEmpty) {
                                        ScaffoldMessenger.of(
                                                this.context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Judul dan deskripsi harus diisi.',
                                            ),
                                            backgroundColor:
                                                Colors.orange,
                                          ),
                                        );
                                        return;
                                      }

                                      if (jobMode ==
                                              _JobFieldMode.required &&
                                          selectedJobId == null) {
                                        ScaffoldMessenger.of(
                                                this.context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Kategori "$selectedCategory" wajib memilih pekerjaan terkait.',
                                            ),
                                            backgroundColor:
                                                Colors.orange,
                                          ),
                                        );
                                        return;
                                      }

                                      setDialogState(
                                          () => isSubmitting = true);

                                      final success =
                                          await _submitComplaint(
                                        category: selectedCategory,
                                        title: title,
                                        description: desc,
                                        jobId: selectedJobId,
                                      );

                                      if (!mounted) return;

                                      if (success) {
                                        Navigator.pop(dialogContext);
                                        _loadComplaints();
                                      } else {
                                        setDialogState(
                                            () => isSubmitting = false);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 46),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10),
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
                                        fontSize: _buttonFontSize,
                                        fontWeight: FontWeight.w600,
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
      },
    );
  }

  // ============================================================
  // JOB DROPDOWN
  // ============================================================

  Widget _buildJobDropdown({
    required bool isSubmitting,
    required int? selectedJobId,
    required bool isRequired,
    required ValueChanged<int?> onChanged,
  }) {
    final label = isRequired
        ? 'Pekerjaan Terkait *'
        : 'Pekerjaan Terkait (opsional)';
    final hint = isRequired
        ? 'Wajib dipilih untuk kategori ini'
        : 'Pilih pekerjaan atau biarkan kosong';

    if (_isLoadingJobs) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.35)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text(
              'Memuat daftar pekerjaan...',
              style: TextStyle(fontSize: _fieldFontSize),
            ),
          ],
        ),
      );
    }

    if (_myJobs.isEmpty) {
      final isBlocking = isRequired;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isBlocking
              ? Colors.orange.withOpacity(0.08)
              : Colors.grey.shade50,
          border: Border.all(
            color: isBlocking
                ? Colors.orange.withOpacity(0.4)
                : Colors.grey.withOpacity(0.35),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isBlocking
                  ? Icons.warning_amber_rounded
                  : Icons.info_outline,
              size: 16,
              color: isBlocking ? Colors.orange : Colors.grey.shade500,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isBlocking
                    ? 'Anda belum memiliki pekerjaan yang bisa diadukan. Kategori ini memerlukan pekerjaan terkait.'
                    : 'Anda belum memiliki pekerjaan. Pengaduan akan dikirim tanpa terkait pekerjaan.',
                style: TextStyle(
                  fontSize: _fieldFontSize - 1,
                  color:
                      isBlocking ? Colors.orange.shade800 : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int?>(
      value: selectedJobId,
      isExpanded: true,
      decoration: _inputDecoration(label, hint: hint).copyWith(
        enabledBorder: isRequired && selectedJobId == null
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.orange.withOpacity(0.55),
                  width: 1.3,
                ),
              )
            : null,
      ),
      style: TextStyle(
        fontSize: _fieldFontSize,
        color: Theme.of(context).textTheme.bodyMedium?.color,
      ),
      items: [
        if (isRequired)
          const DropdownMenuItem<int?>(
            value: null,
            enabled: false,
            child: Text(
              '— Pilih pekerjaan —',
              style: TextStyle(
                fontSize: _fieldFontSize,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          )
        else
          const DropdownMenuItem<int?>(
            value: null,
            child: Text(
              '— Tidak terkait pekerjaan —',
              style: TextStyle(
                fontSize: _fieldFontSize,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ),
        ..._myJobs.map((job) {
          return DropdownMenuItem<int?>(
            value: job['id'] as int?,
            child: Text(
              '${job['code']} — ${job['title']}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: _fieldFontSize),
            ),
          );
        }),
      ],
      onChanged: isSubmitting ? null : onChanged,
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Colors.grey.withOpacity(0.35),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
      labelStyle: const TextStyle(fontSize: _fieldFontSize),
      hintStyle: TextStyle(
        fontSize: _fieldFontSize,
        color: Colors.grey.shade500,
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

      final response = await ApiService.post('/complaints', body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaduan berhasil dibuat.'),
            backgroundColor: Colors.green,
          ),
        );
        return true;
      }

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
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  // ============================================================
  // HEADER — sama persis dgn DashboardHeader
  // ============================================================

  Widget _buildHeader(BuildContext context, bool isMobile) {
    final textTheme = Theme.of(context).textTheme;

    final titleAndSubtitle = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pengaduan Saya',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ajukan dan pantau pengaduan kepada Admin.',
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );

    final button = ElevatedButton.icon(
      onPressed: _showCreateComplaintDialog,
      icon: const Icon(Icons.add, size: 18),
      label: Text(
        isMobile ? 'Buat' : 'Buat Pengaduan',
        style: const TextStyle(
          fontSize: _buttonFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_smallRadius),
        ),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleAndSubtitle,
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: button),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleAndSubtitle),
        const SizedBox(width: 20),
        button,
      ],
    );
  }

  // ============================================================
  // SUMMARY — Mobile 2×2, Web 4 kolom
  // ============================================================

  Widget _buildSummary(BuildContext context, bool isMobile) {
    final cards = [
      _summaryCard(
        context: context,
        title: 'Total',
        fullTitle: 'Total Pengaduan',
        value: '${_summary['total'] ?? 0}',
        icon: Icons.report_problem_outlined,
        color: const Color(0xFF2563EB),
      ),
      _summaryCard(
        context: context,
        title: 'Menunggu',
        fullTitle: 'Menunggu',
        value: '${_summary['menunggu'] ?? 0}',
        icon: Icons.access_time,
        color: _accent,
      ),
      _summaryCard(
        context: context,
        title: 'Diproses',
        fullTitle: 'Diproses',
        value: '${_summary['diproses'] ?? 0}',
        icon: Icons.sync,
        color: const Color(0xFF7C3AED),
      ),
      _summaryCard(
        context: context,
        title: 'Selesai',
        fullTitle: 'Selesai',
        value: '${_summary['selesai'] ?? 0}',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF16A34A),
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 10),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 10),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i != cards.length - 1) const SizedBox(width: 16),
        ],
      ],
    );
  }

  Widget _summaryCard({
    required BuildContext context,
    required String title,
    required String fullTitle,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.1,
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

  Widget _buildFilterSection(BuildContext context, bool isMobile) {
    const filters = [
      'Semua',
      'Menunggu',
      'Diproses',
      'Selesai',
      'Ditolak',
    ];

    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_smallRadius),
        border: Border.all(color: _tableBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 18, color: Color(0xFF6B7280)),
          const SizedBox(width: 8),
          if (!isMobile) ...[
            Text(
              'Filter Status:',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _tableBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFilter,
                isDense: true,
                icon: const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: Color(0xFF6B7280),
                  ),
                ),
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF111827),
                ),
                items: filters.map((filter) {
                  return DropdownMenuItem<String>(
                    value: filter,
                    child: Text(filter),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedFilter = value);
                },
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_filteredComplaints.length}',
              style: textTheme.labelMedium?.copyWith(
                color: _accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE — sama persis dgn judul "Pengaduan Saya"
  //   tanpa bar, pakai headlineSmall + bold
  // ============================================================

  Widget _buildSectionTitle(BuildContext context) {
    return Text(
      'Riwayat Pengaduan',
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  // ============================================================
  // COMPLAINT CARD (MOBILE)
  // ============================================================

  Widget _buildComplaintCard(BuildContext context, ComplaintModel complaint) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _tableBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  complaint.code,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _cellText,
                  ),
                ),
              ),
              _statusBadge(context, complaint.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            complaint.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: _cellText,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            complaint.category,
            style: textTheme.bodySmall?.copyWith(
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _tableDivider),
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
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: const Color(0xFF4B5563),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showComplaintDetail(complaint),
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text(
                'Lihat Detail',
                style: TextStyle(fontSize: 12.5),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 11),
                foregroundColor: const Color(0xFF7C3AED),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DESKTOP TABLE
  // ============================================================

  Widget _buildDesktopTable(BuildContext context) {
    final rows = _filteredComplaints;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _tableBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTableHeaderRow(context),
          const Divider(height: 1, thickness: 1, color: _tableDivider),

          for (int i = 0; i < rows.length; i++) ...[
            _buildTableDataRow(context, rows[i]),
            if (i != rows.length - 1)
              const Divider(height: 1, thickness: 1, color: _tableDivider),
          ],
        ],
      ),
    );
  }

  Widget _buildTableHeaderRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(flex: 2, child: _headerCell(context, 'ID')),
          Expanded(flex: 4, child: _headerCell(context, 'Judul Pengaduan')),
          Expanded(flex: 3, child: _headerCell(context, 'Kategori')),
          Expanded(flex: 3, child: _headerCell(context, 'ID Pekerjaan')),
          Expanded(flex: 2, child: _headerCell(context, 'Tanggal')),
          Expanded(flex: 3, child: _headerCell(context, 'Status')),
          Expanded(flex: 2, child: _headerCell(context, 'Aksi')),
        ],
      ),
    );
  }

  Widget _headerCell(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: _headerText,
          ),
    );
  }

  Widget _buildTableDataRow(BuildContext context, ComplaintModel complaint) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              complaint.code,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: _cellText,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              complaint.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: _cellText,
                height: 1.3,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              complaint.category,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: _cellText,
                height: 1.3,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              complaint.jobCode,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: _cellText,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              complaint.formattedDate,
              style: textTheme.bodyMedium?.copyWith(
                color: _cellText,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _statusBadge(context, complaint.status),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _pillButton(
                context: context,
                icon: Icons.visibility_outlined,
                label: 'Detail',
                bgColor: const Color(0xFFF1F5F9),
                fgColor: const Color(0xFF334155),
                onTap: () => _showComplaintDetail(complaint),
              ),
            ),
          ),
        ],
      ),
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

  void _showComplaintDetail(ComplaintModel complaint) {
    showDialog(
      context: context,
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
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
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
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: Color(0xFF6B7280),
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
                          _detailRow('ID Pengaduan', complaint.code),
                          _detailRow('Kategori', complaint.category),
                          _detailRow('ID Pekerjaan', complaint.jobCode),
                          _detailRow('Tanggal', complaint.formattedDate),
                          _detailRow('Judul', complaint.title),
                          const SizedBox(height: 12),
                          _sectionLabel('Deskripsi'),
                          const SizedBox(height: 6),
                          _detailBox(complaint.description),
                          const SizedBox(height: 16),
                          _sectionLabel('Tanggapan Admin'),
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
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              _statusBadge(dialogContext, complaint.status),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _detailBox(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF374151),
          height: 1.5,
        ),
      ),
    );
  }

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
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
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
  // ✅ Padding horizontal disamakan dgn CustomerDashboard
  //    mobile 16 / tablet 24 / desktop 28  (bukan 32)
  // ✅ TIDAK ada Center + ConstrainedBox — konten nempel kiri
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadComplaints(),
            _loadMyJobs(),
          ]);
        },
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
                  _buildHeader(context, isMobile),

                  const SizedBox(height: _gapAfterHeader),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: CircularProgressIndicator(
                          color: _accent,
                        ),
                      ),
                    )
                  else if (_errorMessage != null)
                    _buildErrorState(context)
                  else ...[
                    _buildSummary(context, isMobile),
                    const SizedBox(height: _gapBetweenSections),
                    _buildFilterSection(context, isMobile),
                    const SizedBox(height: _gapBetweenSections),
                    _buildSectionTitle(context),
                    const SizedBox(height: _gapTitleToContent),

                    if (_filteredComplaints.isEmpty)
                      _buildEmptyState(context)
                    else if (isMobile)
                      Column(
                        children: _filteredComplaints
                            .map((c) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 12,
                                  ),
                                  child: _buildComplaintCard(context, c),
                                ))
                            .toList(),
                      )
                    else
                      _buildDesktopTable(context),
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
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFDC2626),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFDC2626),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadComplaints,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text(
              'Coba Lagi',
              style: TextStyle(fontSize: _buttonFontSize),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
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
              Icons.report_problem_outlined,
              size: 34,
              color: _accent.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _selectedFilter == 'Semua'
                ? 'Belum ada pengaduan.'
                : 'Tidak ada pengaduan dengan status "$_selectedFilter".',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}