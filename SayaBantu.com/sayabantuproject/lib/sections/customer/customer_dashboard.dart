import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/job_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/indonesia_time.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/pekerjaan_card.dart';
import '../../widgets/statistic_card.dart';

class CustomerDashboard extends StatefulWidget {
  final Function(JobModel) onOpenOffer;
  final ValueChanged<JobModel> onOpenTracking;
  final ValueChanged<JobModel> onOpenChat;

  const CustomerDashboard({
    super.key,
    required this.onOpenOffer,
    required this.onOpenTracking,
    required this.onOpenChat,
  });

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  List<JobModel> _jobs = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _statusFilter = 'semua';

  static const List<Map<String, String>> _statusFilterOptions = [
    {'value': 'semua', 'label': 'Semua'},
    {'value': 'menunggu_offer', 'label': 'Mencari Mitra'},
    {'value': 'sedang_dikerjakan', 'label': 'Sedang Dikerjakan'},
    {'value': 'menunggu_konfirmasi', 'label': 'Menunggu Konfirmasi'},
    {'value': 'selesai', 'label': 'Selesai'},
    {'value': 'dibatalkan', 'label': 'Dibatalkan'},
  ];

  int _currentPage = 1;
  int _rowsPerPage = 10;
  static const List<int> _rowsPerPageOptions = [10, 25, 50, 100];

  static const double _buttonRadius = 12;
  static const double _mobileBreakpoint = 700;
  static const double _tabletBreakpoint = 1100;
  static const double _bodyFontSize = 13;

  static const Color _accent = AppColors.primaryTeal;
  static const Color _tableBorder = Color(0xFFE5E7EB);
  static const Color _tableDivider = Color(0xFFF3F4F6);
  static const Color _headerText = AppColors.grey500;
  static const Color _cellText = AppColors.grey900;

  static const double _gapAfterHeader = 16;
  static const double _gapBetweenSections = 16;
  static const double _gapTitleToContent = 16;

  @override
  void initState() {
    super.initState();
    _fetchMyJobs();
  }

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
          _jobs = jobListJson.map((json) => JobModel.fromJson(json)).toList();
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

  Future<void> _completeJob(JobModel job) async {
    try {
      final response = await ApiService.post('/jobs/${job.id}/verify-proof', {
        'status': 'approved',
      });

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSnack('Pekerjaan berhasil dikonfirmasi selesai!', success: true);
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

  Future<void> _cancelJob(JobModel job) async {
    try {
      final response = await ApiService.post(
        '/jobs/${job.id}/cancel-customer',
        {'reason': 'Dibatalkan oleh pelanggan'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSnack('Pekerjaan berhasil dibatalkan.', success: true);
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
        content: Text(message, style: Theme.of(context).textTheme.bodyMedium),
        backgroundColor: success ? AppColors.primaryTeal : Colors.red,
      ),
    );
  }

  void addJob(JobModel job) {
    setState(() {
      _jobs.insert(0, job);
    });
  }

  bool _canConfirm(JobModel job) {
    final s = job.status.toLowerCase();
    final isWaitingConfirm =
        s == 'menunggu konfirmasi selesai' ||
        s == 'menunggu konfirmasi' ||
        s.contains('konfirmasi');
    final hasProof =
        job.completionPhotoUrl != null &&
        job.completionPhotoUrl!.trim().isNotEmpty;
    return isWaitingConfirm && hasProof;
  }

  bool _canOpenOffer(JobModel job) {
    final status = job.status.toLowerCase().trim();
    return status.contains('mencari') ||
        status.contains('offer') ||
        status == 'open' ||
        status == 'pending' ||
        status == 'baru' ||
        status == 'diposting';
  }

  bool _hasJobActions(JobModel job) =>
      _canOpenOffer(job) ||
      _canTrack(job) ||
      _canChat(job) ||
      _canConfirm(job) ||
      _canCancel(job);

  bool _canChat(JobModel job) => job.mitraId != null;

  bool _canCancel(JobModel job) {
    final s = job.status.toLowerCase().trim();

    if (s.contains('selesai') || s.contains('batal') || s.contains('cancel')) {
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

  bool _canTrack(JobModel job) {
    final s = job.status.toLowerCase().trim();
    return s == 'sedang dikerjakan' ||
        s.contains('dikerjakan') ||
        s == 'dalam pengerjaan';
  }

  void _openTracking(JobModel job) {
    widget.onOpenTracking(job);
  }

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

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: AppColors.sectionAltLight,
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
                const SizedBox(height: _gapAfterHeader),
                _buildStatistics(
                  isMobile: isMobile,
                  totalJobs: _jobs.length,
                  runningJobs: _countRunningJobs(),
                  completedJobs: _countCompletedJobs(),
                ),
                const SizedBox(height: _gapBetweenSections),
                _buildFilterBar(context, isMobile),
                const SizedBox(height: _gapBetweenSections),
                _buildSectionTitle(context),
                const SizedBox(height: _gapTitleToContent),
                _buildJobContent(context, isMobile),
              ],
            ),
          ),
        );
      },
    );
  }

  int _countRunningJobs() {
    return _jobs.where((job) {
      final status = job.status.toLowerCase();
      return status == 'sedang dikerjakan' ||
          status == 'proses' ||
          status == 'dalam pengerjaan';
    }).length;
  }

  int _countCompletedJobs() {
    return _jobs.where((job) => job.status.toLowerCase() == 'selesai').length;
  }

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
        color: AppColors.primaryTeal,
      ),
      StatisticCard(
        icon: Icons.settings,
        value: runningJobs.toString(),
        title: 'Sedang Berjalan',
        color: AppColors.mint,
      ),
      StatisticCard(
        icon: Icons.check_circle,
        value: completedJobs.toString(),
        title: 'Selesai',
        color: const Color(0xFF16A34A),
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

  Widget _buildFilterBar(BuildContext context, bool isMobile) {
    final textTheme = Theme.of(context).textTheme;
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
                const Icon(Icons.tune, size: 18, color: AppColors.grey500),
                const SizedBox(width: 10),
                Text(
                  'Filter Status:',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey600,
                  ),
                ),
                const SizedBox(width: 10),
                _buildStatusFilterDropdown(context, isMobile),
              ],
            ),
          ),
          _buildCountBadge(context, totalFiltered),
        ],
      ),
    );
  }

  Widget _buildCountBadge(BuildContext context, int count) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: _accent,
        ),
      ),
    );
  }

  Widget _buildStatusFilterDropdown(BuildContext context, bool isMobile) {
    final textTheme = Theme.of(context).textTheme;

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
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.grey900,
          ),
          items: _statusFilterOptions.map((opt) {
            return DropdownMenuItem<String>(
              value: opt['value'],
              child: Text(opt['label'] ?? '', overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: _changeStatusFilter,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context) {
    return Text(
      'Daftar Pekerjaan',
      style: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildJobContent(BuildContext context, bool isMobile) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState(context);
    }

    if (_jobs.isEmpty) {
      return _buildEmptyState(context);
    }

    final filtered = _filteredJobs;

    if (filtered.isEmpty) {
      return _buildNoFilterResultState(context);
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
              onOpenTracking: widget.onOpenTracking,
              onComplete: _showCompleteConfirmation,
            ),
          );
        }).toList(),
      );
    }

    return _buildJobsTable(context);
  }

  Widget _buildNoFilterResultState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
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
              style: TextButton.styleFrom(foregroundColor: _accent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobsTable(BuildContext context) {
    final rows = _pagedJobs;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < 1200
            ? 1200.0
            : constraints.maxWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
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
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: _tableDivider,
                      ),
                  ],
                  const Divider(height: 1, thickness: 1, color: _tableDivider),
                  _buildTableFooter(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableHeaderRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(flex: 4, child: _headerCell(context, 'Pekerjaan')),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _headerCell(context, 'Mitra')),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _headerCell(context, 'Kategori')),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: _headerCell(context, 'Lokasi')),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _headerCell(context, 'Tanggal')),
          const SizedBox(width: 16),
          Expanded(flex: 4, child: _headerCell(context, 'Aksi')),
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

  Widget _buildTableDataRow(BuildContext context, JobModel job) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _cellText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusBadge(context, job.status),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              job.partnerName ?? '-',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: job.partnerName != null ? _cellText : AppColors.grey400,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              job.category,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: _cellText,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              job.location ?? '-',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: _cellText,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(job.createdAt),
              style: textTheme.bodyMedium?.copyWith(color: _cellText),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _pillButton(
                  context: context,
                  icon: Icons.visibility_outlined,
                  label: 'Detail & Aksi',
                  bgColor: AppColors.grey100,
                  fgColor: AppColors.grey700,
                  onTap: () => _showJobDetailDialog(job),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _jobThumbnail(JobModel job) {
    final imageUrl = job.imageUrl;
    final hasImage =
        imageUrl != null &&
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

  Widget _buildStatusBadge(BuildContext context, String status) {
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
      bg = AppColors.mint.withValues(alpha: 0.18);
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
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: fg,
        ),
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

  Widget _buildTableFooter(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
            style: textTheme.bodySmall?.copyWith(color: _headerText),
          ),
          const Spacer(),
          Row(
            children: [
              _buildRowsPerPageDropdown(context),
              const SizedBox(width: 12),
              _navButton(
                icon: Icons.chevron_left,
                enabled: canPrev,
                onTap: () => _goToPage(_currentPage - 1),
              ),
              const SizedBox(width: 8),
              _pageIndicator(context),
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

  Widget _buildRowsPerPageDropdown(BuildContext context) {
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

  Widget _pageIndicator(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Hal $_currentPage / $_totalPages',
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryTeal,
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    
    // Ambil string, potong jika ada huruf T
    String dateString = date.toString().split('T')[0];
    
    // Jika format dari API adalah YYYY-MM-DD, ubah ke DD/MM/YYYY
    final parts = dateString.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return dateString;
  }

  String _formatDateTime(dynamic date) {
    if (date == null) return '-';

    try {
      final timestamp = IndonesiaTime.tryParseApiTimestamp(date);
      if (timestamp == null) return date.toString();

      final wallTime = IndonesiaTime.toWall(timestamp);
      final day = wallTime.day.toString().padLeft(2, '0');
      final month = wallTime.month.toString().padLeft(2, '0');
      final hour = wallTime.hour.toString().padLeft(2, '0');
      final minute = wallTime.minute.toString().padLeft(2, '0');
      return '$day-$month-${wallTime.year} $hour:$minute';
    } catch (e) {
      return date.toString();
    }
  }

  void _showJobDetailDialog(JobModel job) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650, maxHeight: 750),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // HEADER DIALOG
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                    child: Row(
                      children: [
                        Expanded(
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

                  // BODY DIALOG (SCROLLABLE)
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _dialogJobHeader(dialogContext, job),
                          const SizedBox(height: 20),

                          // BAGIAN INFO DETAIL
                          _sectionTitle('Informasi Pekerjaan'),
                          const SizedBox(height: 10),
                          _detailRow('Kategori', job.category),
                          _detailRow('Durasi', job.duration ?? '-'),
                          _detailRow(
                            'Jadwal Diminta',
                            _formatDateTime(job.preferredStartAt),
                          ),
                          const SizedBox(height: 16),

                          // BAGIAN LOKASI
                          _sectionTitle('Lokasi & Alamat'),
                          const SizedBox(height: 10),
                          _detailRow('Kota / Wilayah', job.location ?? '-'),
                          if (job.addressDetail != null &&
                              job.addressDetail!.isNotEmpty)
                            _detailRow('Detail Alamat', job.addressDetail!),
                          const SizedBox(height: 16),

                          // BAGIAN HARGA & MITRA
                          _sectionTitle('Harga & Mitra'),
                          const SizedBox(height: 10),
                          _detailRow('Harga Awal', job.price),
                          if (job.acceptedPrice != null &&
                              job.acceptedPrice!.trim().isNotEmpty)
                            _detailRow('Harga Deal', job.acceptedPrice!),
                          if (job.partnerName != null &&
                              job.partnerName!.trim().isNotEmpty)
                            _detailRow('Mitra Terpilih', job.partnerName!),
                          const SizedBox(height: 16),

                          // BAGIAN STATUS & WAKTU
                          _sectionTitle('Status & Waktu'),
                          const SizedBox(height: 10),
                          _detailRow(
                            'Status Saat Ini',
                            job.status.toUpperCase(),
                          ),
                          _detailRow(
                            'Dibuat Pada',
                            _formatDateTime(job.createdAt),
                          ),
                          if (_hasValue(job.startedAt))
                            _detailRow(
                              'Mulai Dikerjakan',
                              _formatDateTime(job.startedAt),
                            ),
                          if (_hasValue(job.completedAt))
                            _detailRow(
                              'Selesai Pada',
                              _formatDateTime(job.completedAt),
                            ),

                          // ==========================================
                          // BAGIAN BUKTI PEKERJAAN (KEMBALI DITAMBAHKAN)
                          // ==========================================
                          if (_hasProof(job)) ...[
                            const SizedBox(height: 20),
                            _sectionTitle('Bukti Pekerjaan dari Mitra'),
                            const SizedBox(height: 10),
                            _dialogProofImage(job),
                          ],

                          // ==========================================
                          // BAGIAN RATING (KEMBALI DITAMBAHKAN)
                          // ==========================================
                          if (_hasRating(job)) ...[
                            const SizedBox(height: 20),
                            _dialogRating(dialogContext, job),
                          ],

                          // ==========================================
                          // BAGIAN AKSI / TOMBOL (KEMBALI DITAMBAHKAN)
                          // ==========================================
                          if (_hasJobActions(job)) ...[
                            const SizedBox(height: 24),
                            const Divider(color: Color(0xFFE5E7EB)),
                            const SizedBox(height: 14),
                            Text(
                              'Aksi Pekerjaan',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.grey700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (_canOpenOffer(job))
                                  _pillButton(
                                    context: dialogContext,
                                    icon: Icons.local_offer_outlined,
                                    label: 'Lihat Offer',
                                    bgColor: AppColors.mint.withValues(
                                      alpha: 0.15,
                                    ),
                                    fgColor: AppColors.primaryTeal,
                                    onTap: () {
                                      Navigator.of(dialogContext).pop();
                                      widget.onOpenOffer(job);
                                    },
                                  ),
                                if (_canTrack(job))
                                  _pillButton(
                                    context: dialogContext,
                                    icon: Icons.location_searching,
                                    label: 'Lacak Mitra',
                                    bgColor: const Color(0xFF0F766E),
                                    fgColor: Colors.white,
                                    onTap: () {
                                      Navigator.of(dialogContext).pop();
                                      _openTracking(job);
                                    },
                                  ),
                                if (_canChat(job))
                                  _pillButton(
                                    context: dialogContext,
                                    icon: Icons.chat_bubble_outline,
                                    label: 'Chat Mitra',
                                    bgColor: AppColors.primaryTeal,
                                    fgColor: Colors.white,
                                    onTap: () {
                                      Navigator.of(dialogContext).pop();
                                      widget.onOpenChat(job);
                                    },
                                  ),
                                if (_canConfirm(job))
                                  _pillButton(
                                    context: dialogContext,
                                    icon: Icons.verified_outlined,
                                    label: 'Konfirmasi Selesai',
                                    bgColor: const Color(0xFF16A34A),
                                    fgColor: Colors.white,
                                    onTap: () {
                                      Navigator.of(dialogContext).pop();
                                      _showCompleteConfirmation(job);
                                    },
                                  ),
                                if (_canCancel(job))
                                  _pillButton(
                                    context: dialogContext,
                                    icon: Icons.cancel_outlined,
                                    label: 'Batalkan',
                                    bgColor: const Color(0xFFFEE2E2),
                                    fgColor: const Color(0xFFDC2626),
                                    onTap: () {
                                      Navigator.of(dialogContext).pop();
                                      _showCancelConfirmation(job);
                                    },
                                  ),
                              ],
                            ),
                          ],
                          // ==========================================
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

  Widget _dialogJobHeader(BuildContext context, JobModel job) {
    final imageUrl = job.imageUrl;
    final hasImage =
        imageUrl != null &&
        imageUrl.trim().isNotEmpty &&
        imageUrl.trim() != 'null';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 80,
                height: 80,
                color: AppColors.grey100,
                child: hasImage
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          color: AppColors.grey400,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildStatusBadge(context, job.status),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _sectionTitle('Deskripsi Pekerjaan'),
        const SizedBox(height: 8),
        Text(
          job.description,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.grey700,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.grey800,
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.grey500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.grey900,
              ),
            ),
          ),
        ],
      ),
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
                  style: TextStyle(fontSize: 12, color: AppColors.grey400),
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

  Widget _dialogRating(BuildContext context, JobModel job) {
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasValue(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty && value != 'null';
    return true;
  }

  void _showCompleteConfirmation(JobModel selectedJob) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final textTheme = Theme.of(dialogContext).textTheme;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Konfirmasi Selesai',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          content: Text(
            "Apakah pekerjaan '${selectedJob.title}' sudah selesai dikerjakan?\n\n"
            "Setelah dikonfirmasi, kamu akan diminta melakukan pembayaran.",
            style: textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Batal',
                style: textTheme.bodyMedium?.copyWith(
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
                  borderRadius: BorderRadius.circular(_buttonRadius),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                _completeJob(selectedJob);
              },
              child: Text(
                'Ya, Konfirmasi',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCancelConfirmation(JobModel selectedJob) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final textTheme = Theme.of(dialogContext).textTheme;

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
              Text(
                'Batalkan Pekerjaan',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            "Apakah kamu yakin ingin membatalkan pekerjaan '${selectedJob.title}'?\n\n"
            "Tindakan ini tidak bisa dibatalkan.",
            style: textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Tidak',
                style: textTheme.bodyMedium?.copyWith(
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
                  borderRadius: BorderRadius.circular(_buttonRadius),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                _cancelJob(selectedJob);
              },
              child: Text(
                'Ya, Batalkan',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 42),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Terjadi kesalahan.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.red,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchMyJobs,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(
                'Coba Lagi',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
                  borderRadius: BorderRadius.circular(_buttonRadius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
                color: _accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 36,
                color: _accent.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Belum ada pekerjaan',
              style: textTheme.titleSmall?.copyWith(
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
