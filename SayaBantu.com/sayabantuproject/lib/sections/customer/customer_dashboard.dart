import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/job_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/pekerjaan_card.dart';
import '../../widgets/statistic_card.dart';

class CustomerDashboard extends StatefulWidget {
  final Function(JobModel) onOpenOffer;

  const CustomerDashboard({
    super.key,
    required this.onOpenOffer,
  });

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  List<JobModel> _jobs = [];
  bool _isLoading = true;
  String? _errorMessage;

  // ============================================================
  // FILTER STATE
  // ============================================================

  String _statusFilter = 'semua';

  static const List<Map<String, String>> _statusFilterOptions = [
    {'value': 'semua', 'label': 'Semua'},
    {'value': 'menunggu_offer', 'label': 'Mencari Mitra'},
    {'value': 'sedang_dikerjakan', 'label': 'Sedang Dikerjakan'},
    {'value': 'menunggu_konfirmasi', 'label': 'Menunggu Konfirmasi'},
    {'value': 'selesai', 'label': 'Selesai'},
    {'value': 'dibatalkan', 'label': 'Dibatalkan'},
  ];

  // ============================================================
  // PAGINATION STATE
  // ============================================================

  int _currentPage = 1;
  int _rowsPerPage = 10;
  static const List<int> _rowsPerPageOptions = [10, 25, 50, 100];

  // ============================================================
  // DESIGN TOKENS
  // ============================================================

  static const double _bodyFontSize = 13;
  static const double _buttonFontSize = 13;
  static const double _dialogTitleFontSize = 18;
  static const double _smallRadius = 12;

  static const double _mobileBreakpoint = 700;
  static const double _tabletBreakpoint = 1100;

  // ✅ Aksen warna — konsisten dengan brand teal
  static const Color _accent = AppColors.primaryTeal;

  // Warna tabel
  static const Color _tableBorder = Color(0xFFE5E7EB);
  static const Color _tableDivider = Color(0xFFF3F4F6);
  static const Color _headerText = AppColors.grey500;
  static const Color _cellText = AppColors.grey900;

  @override
  void initState() {
    super.initState();
    _fetchMyJobs();
  }

  // ============================================================
  // FETCH DATA
  // ============================================================

  Future<void> _fetchMyJobs() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await ApiService.get('/pelanggan/my-jobs');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List<dynamic> jobListJson = [];

        if (decoded is Map<String, dynamic>) {
          final target = decoded['data'] ?? decoded['jobs'] ?? [];
          if (target is List) {
            jobListJson = target;
          }
        } else if (decoded is List) {
          jobListJson = decoded;
        }

        if (!mounted) return;

        setState(() {
          _jobs = jobListJson
              .map((json) => JobModel.fromJson(json))
              .toList();
          _currentPage = 1;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              'Gagal mengambil data lowongan (Kode: ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Terjadi kesalahan koneksi: $e';
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // KONFIRMASI SELESAI
  // ============================================================

  Future<void> _completeJob(JobModel job) async {
    try {
      final response = await ApiService.post(
        '/jobs/${job.id}/verify-proof',
        {
          'status': 'approved',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSnack(
          'Pekerjaan berhasil dikonfirmasi selesai!',
          success: true,
        );
        _fetchMyJobs();
      } else {
        String message = 'Gagal konfirmasi (${response.statusCode})';

        try {
          final decoded = jsonDecode(response.body);
          if (decoded['message'] != null) {
            message = decoded['message'].toString();
          }
        } catch (_) {}

        _showSnack(message);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Terjadi kesalahan: $e');
    }
  }

  // ============================================================
  // ✅ BATALKAN PEKERJAAN — API CALL
  // Endpoint: POST /jobs/{id}/cancel-customer
  // ============================================================

  Future<void> _cancelJob(JobModel job) async {
    try {
      final response = await ApiService.post(
        '/jobs/${job.id}/cancel-customer',
        {
          'reason': 'Dibatalkan oleh pelanggan',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSnack(
          'Pekerjaan berhasil dibatalkan.',
          success: true,
        );
        _fetchMyJobs();
      } else {
        String message = 'Gagal membatalkan (${response.statusCode})';

        try {
          final decoded = jsonDecode(response.body);
          if (decoded['message'] != null) {
            message = decoded['message'].toString();
          }
        } catch (_) {}

        _showSnack(message);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Terjadi kesalahan: $e');
    }
  }

  void _showSnack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: _bodyFontSize),
        ),
        backgroundColor: success ? AppColors.primaryTeal : Colors.red,
      ),
    );
  }

  // ============================================================
  // TAMBAH PEKERJAAN
  // ============================================================

  void addJob(JobModel job) {
    setState(() {
      _jobs.insert(0, job);
    });
  }

  // ============================================================
  // CEK APAKAH TOMBOL "KONFIRMASI SELESAI" HARUS MUNCUL
  // ============================================================

  bool _canConfirm(JobModel job) {
    final s = job.status.toLowerCase();

    final isWaitingConfirm = s == 'menunggu konfirmasi selesai' ||
        s == 'menunggu konfirmasi' ||
        s.contains('konfirmasi');

    final hasProof = job.completionPhotoUrl != null &&
        job.completionPhotoUrl!.trim().isNotEmpty;

    return isWaitingConfirm && hasProof;
  }

  // ============================================================
  // ✅ CEK APAKAH TOMBOL "BATALKAN" HARUS MUNCUL
  // ============================================================

  bool _canCancel(JobModel job) {
    final s = job.status.toLowerCase().trim();

    if (s.contains('selesai') ||
        s.contains('batal') ||
        s.contains('cancel')) {
      return false;
    }

    if (s.contains('dikerjakan') ||
        s.contains('proses') ||
        s.contains('pengerjaan') ||
        s.contains('konfirmasi')) {
      return false;
    }

    return s.contains('mencari') ||
        s.contains('cari') ||
        s.contains('mitra') ||
        s.contains('menunggu') ||
        s.contains('offer') ||
        s == 'open' ||
        s == 'pending' ||
        s == 'baru' ||
        s == 'diposting';
  }

  // ============================================================
  // FILTER HELPER
  // ============================================================

  List<JobModel> get _filteredJobs {
    if (_statusFilter == 'semua') return _jobs;

    return _jobs.where((job) {
      final s = job.status.toLowerCase().trim();

      switch (_statusFilter) {
        case 'menunggu_konfirmasi':
          return s.contains('konfirmasi');

        case 'sedang_dikerjakan':
          return s.contains('dikerjakan') ||
              s.contains('proses') ||
              s.contains('pengerjaan');

        case 'selesai':
          return !s.contains('konfirmasi') && s.contains('selesai');

        case 'dibatalkan':
          return s.contains('batal') || s.contains('cancel');

        case 'menunggu_offer':
          return s.contains('mencari') ||
              s.contains('cari') ||
              s.contains('mitra') ||
              s.contains('offer') ||
              s.contains('penawar') ||
              (s.contains('menunggu') && !s.contains('konfirmasi')) ||
              s == 'open' ||
              s == 'pending' ||
              s == 'baru' ||
              s == 'diposting';

        default:
          return true;
      }
    }).toList();
  }

  void _changeStatusFilter(String? value) {
    if (value == null) return;
    setState(() {
      _statusFilter = value;
      _currentPage = 1;
    });
  }

  // ============================================================
  // PAGINATION HELPERS
  // ============================================================

  int get _totalPages {
    final list = _filteredJobs;
    if (list.isEmpty) return 1;
    return (list.length / _rowsPerPage).ceil();
  }

  List<JobModel> get _pagedJobs {
    final list = _filteredJobs;
    final start = (_currentPage - 1) * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, list.length);
    if (start >= list.length) return [];
    return list.sublist(start, end);
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() => _currentPage = page);
  }

  void _changeRowsPerPage(int newValue) {
    setState(() {
      _rowsPerPage = newValue;
      _currentPage = 1;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final isMobile = width < _mobileBreakpoint;
        final isTablet =
            width >= _mobileBreakpoint && width < _tabletBreakpoint;

        final horizontalPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 28.0);
        final verticalPadding = isMobile ? 16.0 : 28.0;
        final sectionGap = isMobile ? 20.0 : 24.0;

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: AppColors.sectionAltLight, // ← dari theme → mint muda
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardHeader(
                  onAddJob: (newJob) {
                    addJob(newJob);
                    _fetchMyJobs();
                  },
                ),

                SizedBox(height: sectionGap),

                _buildStatistics(
                  isMobile: isMobile,
                  totalJobs: _jobs.length,
                  runningJobs: _countRunningJobs(),
                  completedJobs: _countCompletedJobs(),
                ),

                SizedBox(height: sectionGap),

                _buildFilterBar(isMobile),

                SizedBox(height: isMobile ? 14 : 18),

                _buildSectionTitle(isMobile),

                SizedBox(height: isMobile ? 12 : 16),

                _buildJobContent(isMobile),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // HITUNG STATISTIK
  // ============================================================

  int _countRunningJobs() {
    return _jobs.where((job) {
      final status = job.status.toLowerCase();
      return status == 'sedang dikerjakan' ||
          status == 'proses' ||
          status == 'dalam pengerjaan';
    }).length;
  }

  int _countCompletedJobs() {
    return _jobs
        .where((job) => job.status.toLowerCase() == 'selesai')
        .length;
  }

  // ============================================================
  // STATISTIK WIDGET
  // ============================================================

  Widget _buildStatistics({
    required bool isMobile,
    required int totalJobs,
    required int runningJobs,
    required int completedJobs,
  }) {
    final cards = [
      StatisticCard(
        icon: Icons.assignment,
        value: totalJobs.toString(),
        title: 'Total Posting',
        color: AppColors.primaryTeal, // ← teal
      ),
      StatisticCard(
        icon: Icons.settings,
        value: runningJobs.toString(),
        title: 'Sedang Berjalan',
        color: AppColors.mint, // ← mint
      ),
      StatisticCard(
        icon: Icons.check_circle,
        value: completedJobs.toString(),
        title: 'Selesai',
        color: const Color(0xFF16A34A), // ← tetap hijau (untuk "selesai")
      ),
    ];

    final gap = isMobile ? 8.0 : 16.0;

    return SizedBox(
      height: isMobile ? 108 : 104,
      child: Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            Expanded(child: cards[i]),
            if (i != cards.length - 1) SizedBox(width: gap),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // FILTER BAR
  // ============================================================

  Widget _buildFilterBar(bool isMobile) {
    final totalFiltered = _filteredJobs.length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _tableBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.tune,
                  size: 18,
                  color: AppColors.grey500,
                ),

                const SizedBox(width: 10),

                Text(
                  'Filter Status:',
                  style: TextStyle(
                    fontSize: isMobile ? 12.5 : 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey600,
                  ),
                ),

                const SizedBox(width: 10),

                _buildStatusFilterDropdown(isMobile),
              ],
            ),
          ),

          _buildCountBadge(totalFiltered),
        ],
      ),
    );
  }

  Widget _buildCountBadge(int count) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _accent,
        ),
      ),
    );
  }

  Widget _buildStatusFilterDropdown(bool isMobile) {
    return Container(
      height: 34,
      constraints: BoxConstraints(
        minWidth: isMobile ? 130 : 160,
        maxWidth: isMobile ? 180 : 220,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _tableBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _statusFilter,
          isDense: true,
          isExpanded: true,
          icon: const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: AppColors.grey500,
            ),
          ),
          style: TextStyle(
            fontSize: isMobile ? 12 : 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.grey900,
          ),
          items: _statusFilterOptions.map((opt) {
            return DropdownMenuItem<String>(
              value: opt['value'],
              child: Text(
                opt['label'] ?? '',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: _changeStatusFilter,
        ),
      ),
    );
  }

  // ============================================================
  // JUDUL SECTION
  // ============================================================

  Widget _buildSectionTitle(bool isMobile) {
    return Row(
      children: [
        Container(
          width: 4,
          height: isMobile ? 18 : 20,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Daftar Pekerjaan',
          style: TextStyle(
            fontSize: isMobile ? 15 : 16,
            fontWeight: FontWeight.w700,
            color: AppColors.grey800,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // JOB CONTENT
  // ============================================================

  Widget _buildJobContent(bool isMobile) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: _accent),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_jobs.isEmpty) {
      return _buildEmptyState();
    }

    final filtered = _filteredJobs;

    if (filtered.isEmpty) {
      return _buildNoFilterResultState();
    }

    if (isMobile) {
      return Column(
        children: filtered.map((job) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: JobCard(
              job: job,
              onRefresh: _fetchMyJobs,
              onOpenOffer: widget.onOpenOffer,
              onComplete: _showCompleteConfirmation,
            ),
          );
        }).toList(),
      );
    }

    return _buildJobsTable();
  }

  Widget _buildNoFilterResultState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_alt_off_outlined,
              size: 42,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 12),
            Text(
              'Tidak ada pekerjaan dengan filter ini',
              style: TextStyle(
                fontSize: _bodyFontSize,
                color: AppColors.grey600,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _changeStatusFilter('semua'),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset Filter'),
              style: TextButton.styleFrom(
                foregroundColor: _accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TABEL PEKERJAAN
  // ============================================================

  Widget _buildJobsTable() {
    final rows = _pagedJobs;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _tableBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTableHeaderRow(),

          const Divider(height: 1, thickness: 1, color: _tableDivider),

          for (int i = 0; i < rows.length; i++) ...[
            _buildTableDataRow(rows[i]),
            if (i != rows.length - 1)
              const Divider(height: 1, thickness: 1, color: _tableDivider),
          ],

          const Divider(height: 1, thickness: 1, color: _tableDivider),

          _buildTableFooter(),
        ],
      ),
    );
  }

  Widget _buildTableHeaderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(flex: 4, child: _headerCell('Pekerjaan')),
          Expanded(flex: 2, child: _headerCell('Mitra')),
          Expanded(flex: 2, child: _headerCell('Kategori')),
          Expanded(flex: 3, child: _headerCell('Lokasi')),
          Expanded(flex: 2, child: _headerCell('Tanggal')),
          Expanded(flex: 4, child: _headerCell('Aksi')),
        ],
      ),
    );
  }

  Widget _headerCell(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _headerText,
      ),
    );
  }

  // ============================================================
  // DATA ROW
  // ============================================================

  Widget _buildTableDataRow(JobModel job) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Kolom 1
          Expanded(
            flex: 4,
            child: Row(
              children: [
                _jobThumbnail(job),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        job.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _cellText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusBadge(job.status),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Kolom 2
          Expanded(
            flex: 2,
            child: Text(
              job.partnerName ?? '-',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: job.partnerName != null
                    ? _cellText
                    : AppColors.grey400,
                height: 1.3,
              ),
            ),
          ),

          // Kolom 3
          Expanded(
            flex: 2,
            child: Text(
              job.category,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: _cellText,
                height: 1.3,
              ),
            ),
          ),

          // Kolom 4
          Expanded(
            flex: 3,
            child: Text(
              job.location ?? '-',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: _cellText,
                height: 1.3,
              ),
            ),
          ),

          // Kolom 5
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(job.createdAt),
              style: const TextStyle(fontSize: 13, color: _cellText),
            ),
          ),

          // Kolom 6
          Expanded(
            flex: 4,
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _pillButton(
                  icon: Icons.visibility_outlined,
                  label: 'Detail',
                  bgColor: AppColors.grey100,
                  fgColor: AppColors.grey700,
                  onTap: () => _showJobDetailDialog(job),
                ),
                _pillButton(
                  icon: Icons.local_offer_outlined,
                  label: 'Lihat Offer',
                  bgColor: AppColors.mint.withOpacity(0.15),
                  fgColor: AppColors.primaryTeal,
                  onTap: () => widget.onOpenOffer(job),
                ),
                if (_canConfirm(job))
                  _pillButton(
                    icon: Icons.verified_outlined,
                    label: 'Konfirmasi Selesai',
                    bgColor: const Color(0xFF16A34A),
                    fgColor: Colors.white,
                    onTap: () => _showCompleteConfirmation(job),
                  ),
                if (_canCancel(job))
                  _pillButton(
                    icon: Icons.cancel_outlined,
                    label: 'Batalkan',
                    bgColor: const Color(0xFFFEE2E2),
                    fgColor: const Color(0xFFDC2626),
                    onTap: () => _showCancelConfirmation(job),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // THUMBNAIL
  // ============================================================

  Widget _jobThumbnail(JobModel job) {
    final imageUrl = job.imageUrl;

    final hasImage = imageUrl != null &&
        imageUrl.trim().isNotEmpty &&
        imageUrl.trim() != 'null';

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 52,
        height: 52,
        color: AppColors.grey100,
        child: hasImage
            ? Image.network(
                imageUrl,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.grey400,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) {
                  return const Icon(
                    Icons.image_not_supported_outlined,
                    size: 20,
                    color: AppColors.grey400,
                  );
                },
              )
            : const Icon(
                Icons.image_outlined,
                size: 20,
                color: AppColors.grey400,
              ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(String status) {
    final s = status.toLowerCase();

    Color bg;
    Color fg;

    if (s.contains('batal') || s.contains('cancel')) {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
    } else if (s.contains('konfirmasi')) {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
    } else if (s == 'selesai') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF16A34A);
    } else if (s == 'sedang dikerjakan' ||
        s == 'proses' ||
        s == 'dalam pengerjaan') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
    } else {
      // default: "mencari mitra" dll → mint/teal
      bg = AppColors.mint.withOpacity(0.18);
      fg = AppColors.primaryTeal;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  // ============================================================
  // PILL BUTTON
  // ============================================================

  Widget _pillButton({
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
                style: TextStyle(
                  fontSize: 11,
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
  // FOOTER TABEL
  // ============================================================

  Widget _buildTableFooter() {
    final total = _filteredJobs.length;
    final start = total == 0 ? 0 : ((_currentPage - 1) * _rowsPerPage) + 1;
    final end = (_currentPage * _rowsPerPage).clamp(0, total);
    final canPrev = _currentPage > 1;
    final canNext = _currentPage < _totalPages;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text(
            'Menampilkan $start–$end dari $total pekerjaan',
            style: const TextStyle(fontSize: 12.5, color: _headerText),
          ),
          const Spacer(),
          Row(
            children: [
              _buildRowsPerPageDropdown(),
              const SizedBox(width: 12),
              _navButton(
                icon: Icons.chevron_left,
                enabled: canPrev,
                onTap: () => _goToPage(_currentPage - 1),
              ),
              const SizedBox(width: 8),
              _pageIndicator(),
              const SizedBox(width: 8),
              _navButton(
                icon: Icons.chevron_right,
                enabled: canNext,
                onTap: () => _goToPage(_currentPage + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRowsPerPageDropdown() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _tableBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _rowsPerPage,
          isDense: true,
          icon: const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppColors.grey500,
            ),
          ),
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.grey900,
          ),
          items: _rowsPerPageOptions.map((value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text('$value / hal'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) _changeRowsPerPage(value);
          },
        ),
      ),
    );
  }

  Widget _navButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled ? AppColors.grey300 : AppColors.grey200,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.grey700 : AppColors.grey300,
          ),
        ),
      ),
    );
  }

  Widget _pageIndicator() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.mint.withOpacity(0.20), // ← dari ungu → mint
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Hal $_currentPage / $_totalPages',
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryTeal, // ← teal
        ),
      ),
    );
  }

  // ============================================================
  // FORMAT TANGGAL
  // ============================================================

  String _formatDate(dynamic date) {
    if (date == null) return '-';

    DateTime? parsed;
    if (date is DateTime) {
      parsed = date;
    } else if (date is String) {
      parsed = DateTime.tryParse(date);
    }
    if (parsed == null) return '-';

    return '${parsed.day}/${parsed.month}/${parsed.year}';
  }

  String _formatDateTime(dynamic date) {
    if (date == null) return '-';

    DateTime? parsed;
    if (date is DateTime) {
      parsed = date;
    } else if (date is String) {
      parsed = DateTime.tryParse(date);
    }
    if (parsed == null) return '-';

    final d = parsed.day.toString().padLeft(2, '0');
    final m = parsed.month.toString().padLeft(2, '0');
    final y = parsed.year;
    final hh = parsed.hour.toString().padLeft(2, '0');
    final mm = parsed.minute.toString().padLeft(2, '0');

    return '$d-$m-$y $hh:$mm';
  }

  // ============================================================
  // DETAIL DIALOG
  // ============================================================

  void _showJobDetailDialog(JobModel job) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 680),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Detail Pekerjaan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.grey900,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(
                            Icons.close,
                            size: 20,
                            color: AppColors.grey500,
                          ),
                          splashRadius: 22,
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFE5E7EB)),

                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _dialogJobHeader(job),
                          const SizedBox(height: 18),
                          _dialogMitra(job),
                          const SizedBox(height: 14),
                          _dialogMetaChips(job),
                          const SizedBox(height: 16),
                          _buildStatusBadge(job.status),

                          if (_hasProof(job)) ...[
                            const SizedBox(height: 20),
                            const Divider(color: Color(0xFFE5E7EB)),
                            const SizedBox(height: 14),
                            const Text(
                              '📷 Bukti Pekerjaan',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.grey700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _dialogProofImage(job),
                          ],

                          if (_hasRating(job)) ...[
                            const SizedBox(height: 18),
                            _dialogRating(job),
                          ],
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

  Widget _dialogJobHeader(JobModel job) {
    final imageUrl = job.imageUrl;
    final hasImage = imageUrl != null &&
        imageUrl.trim().isNotEmpty &&
        imageUrl.trim() != 'null';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 88,
            height: 88,
            color: AppColors.grey100,
            child: hasImage
                ? Image.network(
                    imageUrl,
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.grey400,
                      size: 24,
                    ),
                  )
                : const Icon(
                    Icons.image_outlined,
                    color: AppColors.grey400,
                    size: 24,
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey900,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                job.description,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.grey500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dialogMitra(JobModel job) {
    final namaMitra = job.partnerName;
    if (namaMitra == null || namaMitra.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        const Icon(
          Icons.person_outline,
          size: 16,
          color: Color(0xFF16A34A),
        ),
        const SizedBox(width: 6),
        Text(
          'Mitra: $namaMitra',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF16A34A),
          ),
        ),
      ],
    );
  }

  Widget _dialogMetaChips(JobModel job) {
    final chips = <Widget>[];

    chips.add(_metaChip(
      Icons.attach_money,
      'Harga Awal: ${job.price}',
    ));

    if (job.acceptedPrice != null && job.acceptedPrice!.trim().isNotEmpty) {
      chips.add(_metaChip(
        Icons.payments_outlined,
        'Harga Deal: ${job.acceptedPrice}',
      ));
    } else if (job.finalPrice != null) {
      chips.add(_metaChip(
        Icons.payments_outlined,
        'Harga Deal: ${_formatCurrency(job.finalPrice)}',
      ));
    }

    if (_hasValue(job.createdAt)) {
      chips.add(_metaChip(
        Icons.access_time,
        'Dibuat: ${_formatDateTime(job.createdAt)}',
      ));
    }

    if (_hasValue(job.startedAt)) {
      chips.add(_metaChip(
        Icons.play_circle_outline,
        'Mulai: ${_formatDateTime(job.startedAt)}',
      ));
    }

    if (_hasValue(job.completedAt)) {
      chips.add(_metaChip(
        Icons.check_circle_outline,
        'Selesai: ${_formatDateTime(job.completedAt)}',
      ));
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.grey500),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.grey600,
          ),
        ),
      ],
    );
  }

  bool _hasProof(JobModel job) {
    final proof = job.completionPhotoUrl;
    return proof != null && proof.trim().isNotEmpty && proof.trim() != 'null';
  }

  Widget _dialogProofImage(JobModel job) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        job.completionPhotoUrl!,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 200,
            color: AppColors.grey100,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.grey400,
            ),
          );
        },
        errorBuilder: (_, __, ___) {
          return Container(
            height: 200,
            color: AppColors.grey100,
            alignment: Alignment.center,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 32,
                  color: AppColors.grey400,
                ),
                SizedBox(height: 6),
                Text(
                  'Gagal memuat gambar',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey400,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _hasRating(JobModel job) {
    final r = job.myRating;
    return r != null && r > 0;
  }

  Widget _dialogRating(JobModel job) {
    final rating = job.myRating ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star, color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 8),
          Text(
            'Rating Anda: $rating/5',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool _hasValue(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty && value != 'null';
    return true;
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '-';

    double? amount;

    if (value is num) {
      amount = value.toDouble();
    } else if (value is String) {
      amount = double.tryParse(value);
    }

    if (amount == null) return value.toString();

    final intAmount = amount.toInt();
    final str = intAmount.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }

    return 'Rp ${buffer.toString()}';
  }

  // ============================================================
  // KONFIRMASI SELESAI — DIALOG
  // ============================================================

  void _showCompleteConfirmation(JobModel selectedJob) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Konfirmasi Selesai',
            style: TextStyle(
              fontSize: _dialogTitleFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            "Apakah pekerjaan '${selectedJob.title}' sudah selesai dikerjakan?\n\n"
            "Setelah dikonfirmasi, kamu akan diminta melakukan pembayaran.",
            style: const TextStyle(
              fontSize: _bodyFontSize,
              height: 1.5,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontSize: _buttonFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_smallRadius),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                _completeJob(selectedJob);
              },
              child: const Text(
                'Ya, Konfirmasi',
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
  }

  // ============================================================
  // ✅ KONFIRMASI BATALKAN — DIALOG
  // ============================================================

  void _showCancelConfirmation(JobModel selectedJob) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                'Batalkan Pekerjaan',
                style: TextStyle(
                  fontSize: _dialogTitleFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            "Apakah kamu yakin ingin membatalkan pekerjaan "
            "'${selectedJob.title}'?\n\n"
            "Tindakan ini tidak bisa dibatalkan.",
            style: const TextStyle(
              fontSize: _bodyFontSize,
              height: 1.5,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Tidak',
                style: TextStyle(
                  fontSize: _buttonFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_smallRadius),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                _cancelJob(selectedJob);
              },
              child: const Text(
                'Ya, Batalkan',
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
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Terjadi kesalahan.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: _bodyFontSize,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchMyJobs,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text(
                'Coba Lagi',
                style: TextStyle(
                  fontSize: _buttonFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_smallRadius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 36,
                color: _accent.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum ada pekerjaan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.grey700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Yuk, posting pekerjaan pertamamu lewat tombol di atas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.grey600,
                fontSize: _bodyFontSize,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}