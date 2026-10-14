import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/admin_theme_provider.dart';
import '../../theme/app_colors.dart';

class ActivityLogPage extends StatefulWidget {
  const ActivityLogPage({super.key});

  @override
  State<ActivityLogPage> createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedFilter = 'Semua';

  List<ActivityData> _activities = [];

  bool _isLoading = true;
  bool _isDeleting = false;
  String? _errorMessage;

  // ============================================================
  // THEME
  // ============================================================

  AdminTheme get theme => AdminThemeProvider.of(context);

  // ============================================================
  // BREAKPOINTS
  // ============================================================

  static const double _mobileBreakpoint = 700;
  static const double _tabletBreakpoint = 1100;

  // ============================================================
  // PAGINATION
  // ============================================================

  int _currentPage = 1;
  int _itemsPerPage = 10;
  static const List<int> _pageSizeOptions = [5, 10, 25, 50];

  // ============================================================
  // FILTER OPTIONS
  // ============================================================

  final List<Map<String, dynamic>> _filterOptions = [
    {'label': 'Semua Aktivitas', 'value': 'Semua'},
    {'label': 'Super Admin', 'value': 'Super Admin'},
    {'label': 'Admin', 'value': 'Admin'},
    {'label': 'Mitra', 'value': 'Mitra'},
    {'label': 'Pelanggan', 'value': 'Pelanggan'},
    {'label': 'Sistem', 'value': 'Sistem'},
  ];

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD ACTIVITY
  // ============================================================

  Future<void> _loadActivities() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.get('/activity-logs');

      debugPrint('ACTIVITY LOGS: ${response.statusCode}');
      debugPrint('BODY: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final List<dynamic> data = responseData['data'] ?? [];

        final List<ActivityData> loadedActivities = data.map((item) {
          return ActivityData.fromJson(item as Map<String, dynamic>);
        }).toList();

        if (!mounted) return;

        setState(() {
          _activities = loadedActivities;
          _isLoading = false;
          _currentPage = 1;
        });
      } else {
        throw Exception(
          responseData['message'] ?? 'Gagal mengambil log aktivitas.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // FILTER DATA
  // ============================================================

  List<ActivityData> get _filteredActivities {
    final query = _searchQuery.toLowerCase().trim();

    return _activities.where((activity) {
      final matchesSearch = query.isEmpty ||
          activity.name.toLowerCase().contains(query) ||
          activity.activity.toLowerCase().contains(query) ||
          activity.detail.toLowerCase().contains(query) ||
          activity.role.toLowerCase().contains(query);

      final matchesFilter = _selectedFilter == 'Semua' ||
          activity.role.toLowerCase() == _selectedFilter.toLowerCase();

      return matchesSearch && matchesFilter;
    }).toList();
  }

  // ============================================================
  // PAGINATION HELPERS
  // ============================================================

  int get _totalPages {
    final total = _filteredActivities.length;
    if (total == 0) return 1;
    return ((total - 1) ~/ _itemsPerPage) + 1;
  }

  List<ActivityData> get _paginatedActivities {
    final all = _filteredActivities;
    final start = (_currentPage - 1) * _itemsPerPage;
    if (start >= all.length) return [];
    final end = (start + _itemsPerPage).clamp(0, all.length);
    return all.sublist(start, end);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < _mobileBreakpoint;
        final isTablet =
            width >= _mobileBreakpoint && width < _tabletBreakpoint;

        final horizontalPadding =
            isMobile ? 16.0 : (isTablet ? 24.0 : 28.0);
        final verticalPadding = isMobile ? 16.0 : 28.0;

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: t.bg,
          child: RefreshIndicator(
            onRefresh: _loadActivities,
            color: t.accent,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isMobile, t),
                  const SizedBox(height: 16),
                  _buildFilterSection(isMobile, t),
                  const SizedBox(height: 16),
                  _buildContentBody(isMobile, t),

                  if (!_isLoading &&
                      _errorMessage == null &&
                      _filteredActivities.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildPaginationFullWidth(isMobile, t),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // CONTENT BODY
  // ============================================================

  Widget _buildContentBody(bool isMobile, AdminTheme t) {
    if (_isLoading) return _buildLoadingState(t);
    if (_errorMessage != null) return _buildErrorState(t);

    final totalFiltered = _filteredActivities.length;
    if (totalFiltered == 0) return _buildEmptyState(t);

    final activities = _paginatedActivities;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (!isMobile) _buildTableHeader(t),
          ...activities.asMap().entries.map((entry) {
            final number =
                (_currentPage - 1) * _itemsPerPage + entry.key + 1;
            return _buildActivityItem(
              entry.value,
              isMobile,
              entry.key == activities.length - 1,
              number,
              t,
            );
          }),
        ],
      ),
    );
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  Widget _buildPaginationFullWidth(bool isMobile, AdminTheme t) {
    final total = _filteredActivities.length;
    final totalPages = _totalPages;
    final startItem = (_currentPage - 1) * _itemsPerPage + 1;
    final endItem = (startItem + _itemsPerPage - 1).clamp(0, total);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              'Menampilkan $startItem–$endItem dari $total aktivitas',
              style: TextStyle(
                fontSize: 12.5,
                color: t.headerText,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: t.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _itemsPerPage,
                    isDense: true,
                    icon: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: t.headerText,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: t.cellText,
                      fontWeight: FontWeight.w600,
                    ),
                    items: _pageSizeOptions
                        .map((n) => DropdownMenuItem<int>(
                              value: n,
                              child: Text('$n / hal'),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _itemsPerPage = v;
                        _currentPage = 1;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _paginationIconButton(
                icon: Icons.chevron_left,
                onTap: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
                t: t,
              ),
              const SizedBox(width: 8),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Hal $_currentPage / $totalPages',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: t.accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _paginationIconButton(
                icon: Icons.chevron_right,
                onTap: _currentPage < totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
                t: t,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paginationIconButton({
    required IconData icon,
    required VoidCallback? onTap,
    required AdminTheme t,
  }) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: onTap == null ? t.border : AppColors.grey300,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: onTap == null
                ? AppColors.grey300
                : AppColors.grey700,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER  ← tanpa top padding, font konsisten
  // ============================================================

  Widget _buildHeader(bool isMobile, AdminTheme t) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Log Aktivitas',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: t.cellText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pantau seluruh aktivitas pengguna, mitra, admin, dan sistem.',
                style: textTheme.bodyMedium?.copyWith(
                  color: t.mutedText,
                ),
              ),
            ],
          ),
        ),
        if (!isMobile) ...[
          const SizedBox(width: 16),
          _buildDeleteButton(t),
        ],
      ],
    );
  }

  // ============================================================
  // TOMBOL HAPUS
  // ============================================================

  Widget _buildDeleteButton(AdminTheme t) {
    return OutlinedButton.icon(
      onPressed: _isDeleting ? null : () => _showDeleteRangeDialog(t),
      icon: const Icon(Icons.delete_sweep_outlined, size: 18),
      label: const Text(
        'Hapus Log',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: t.danger,
        side: BorderSide(color: t.danger),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH + FILTER
  // ============================================================

  Widget _buildFilterSection(bool isMobile, AdminTheme t) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchField(t),
          const SizedBox(height: 10),
          _buildFilterDropdown(t),
          const SizedBox(height: 10),
          _buildDeleteButton(t),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _buildSearchField(t)),
        const SizedBox(width: 14),
        SizedBox(width: 200, child: _buildFilterDropdown(t)),
      ],
    );
  }

  Widget _buildSearchField(AdminTheme t) {
    return SizedBox(
      height: 46,
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _currentPage = 1;
          });
        },
        style: TextStyle(fontSize: 13, color: t.cellText),
        decoration: InputDecoration(
          hintText: 'Cari aktivitas, nama, atau role...',
          hintStyle: TextStyle(fontSize: 14, color: t.mutedText),
          prefixIcon: Icon(
            Icons.search,
            color: t.mutedText,
            size: 21,
          ),
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: t.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: t.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: t.accent),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(AdminTheme t) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          isExpanded: true,
          borderRadius: BorderRadius.circular(10),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: t.mutedText,
            size: 21,
          ),
          style: TextStyle(
            fontSize: 13,
            color: t.cellText,
            fontWeight: FontWeight.w500,
          ),
          items: _filterOptions.map((option) {
            return DropdownMenuItem<String>(
              value: option['value'] as String,
              child: Text(
                option['label'] as String,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedFilter = value;
              _currentPage = 1;
            });
          },
        ),
      ),
    );
  }

  // ============================================================
  // TABLE HEADER
  // ============================================================

  Widget _buildTableHeader(AdminTheme t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(color: AppColors.grey50),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              'No',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: t.headerText,
              ),
            ),
          ),
          SizedBox(
            width: 240,
            child: Text(
              'Pengguna',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: t.headerText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Aktivitas',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: t.headerText,
              ),
            ),
          ),
          SizedBox(
            width: 180,
            child: Text(
              'Waktu',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: t.headerText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIVITY ITEM
  // ============================================================

  Widget _buildActivityItem(
    ActivityData activity,
    bool isMobile,
    bool isLast,
    int number,
    AdminTheme t,
  ) {
    if (isMobile) return _buildMobileActivityCard(activity, number, t);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: t.divider),
              ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.grey400,
              ),
            ),
          ),
          SizedBox(width: 240, child: _buildUserInfo(activity)),
          Expanded(child: _buildActivityInfo(activity, t)),
          SizedBox(
            width: 180,
            child: Row(
              children: [
                _buildRoleBadge(activity.role),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activity.time,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: t.mutedText,
                    ),
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
  // USER INFO
  // ============================================================

  Widget _buildUserInfo(ActivityData activity) {
    final roleColor = _getRoleColor(activity.role);

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: roleColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            activity.icon,
            size: 18,
            color: roleColor,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                activity.role,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: roleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACTIVITY INFO
  // ============================================================

  Widget _buildActivityInfo(ActivityData activity, AdminTheme t) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activity.activity,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: t.cellText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            activity.detail,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.grey400,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ROLE BADGE
  // ============================================================

  Widget _buildRoleBadge(String role) {
    final color = _getRoleColor(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE CARD
  // ============================================================

  Widget _buildMobileActivityCard(
    ActivityData activity,
    int number,
    AdminTheme t,
  ) {
    final roleColor = _getRoleColor(activity.role);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: t.divider),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: t.mutedText,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  activity.icon,
                  size: 19,
                  color: roleColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      activity.role,
                      style: TextStyle(
                        fontSize: 11,
                        color: roleColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildRoleBadge(activity.role),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            activity.activity,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: t.cellText,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            activity.detail,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.grey400,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.access_time_outlined,
                size: 15,
                color: AppColors.grey400,
              ),
              const SizedBox(width: 5),
              Text(
                activity.time,
                style: TextStyle(
                  fontSize: 11,
                  color: t.mutedText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING / ERROR / EMPTY
  // ============================================================

  Widget _buildLoadingState(AdminTheme t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Center(child: CircularProgressIndicator(color: t.accent)),
    );
  }

  Widget _buildErrorState(AdminTheme t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: t.danger,
          ),
          const SizedBox(height: 12),
          Text(
            'Gagal mengambil log aktivitas',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: t.cellText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: t.mutedText),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _loadActivities,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: t.accent,
              foregroundColor: AppColors.white,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AdminTheme t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.history_outlined,
            size: 52,
            color: AppColors.grey300,
          ),
          const SizedBox(height: 12),
          Text(
            'Aktivitas tidak ditemukan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: t.cellText,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Belum ada aktivitas yang sesuai dengan pencarian atau filter.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.grey400),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DIALOG: HAPUS LOG
  // ============================================================

  void _showDeleteRangeDialog(AdminTheme t) {
    DateTime? startDate;
    DateTime? endDate;
    String scope = 'range';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AdminThemeProvider(
          theme: t,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                title: Row(
                  children: [
                    Icon(
                      Icons.delete_sweep_outlined,
                      color: t.danger,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Hapus Log Aktivitas',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: t.cellText,
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 440,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih metode penghapusan:',
                          style: TextStyle(
                            fontSize: 13,
                            color: t.mutedText,
                          ),
                        ),
                        const SizedBox(height: 12),

                        RadioGroup<String>(
                          groupValue: scope,
                          onChanged: (v) {
                            if (v == null) return;
                            setDialogState(() => scope = v);
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RadioListTile<String>(
                                value: 'range',
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                activeColor: t.accent,
                                title: Text(
                                  'Berdasarkan rentang waktu',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: t.cellText,
                                  ),
                                ),
                              ),

                              if (scope == 'range') ...[
                                const SizedBox(height: 4),
                                _buildDatePickerTile(
                                  label: 'Dari Tanggal',
                                  value: startDate,
                                  onPick: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: startDate ??
                                          DateTime.now().subtract(
                                              const Duration(days: 30)),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      setDialogState(
                                          () => startDate = picked);
                                    }
                                  },
                                  t: t,
                                ),
                                const SizedBox(height: 10),
                                _buildDatePickerTile(
                                  label: 'Sampai Tanggal',
                                  value: endDate,
                                  onPick: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          endDate ?? DateTime.now(),
                                      firstDate:
                                          startDate ?? DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      setDialogState(
                                          () => endDate = picked);
                                    }
                                  },
                                  t: t,
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _quickRangeChip(
                                      '7 hari terakhir',
                                      7,
                                      (s, e) {
                                        setDialogState(() {
                                          startDate = s;
                                          endDate = e;
                                        });
                                      },
                                      t,
                                    ),
                                    _quickRangeChip(
                                      '30 hari terakhir',
                                      30,
                                      (s, e) {
                                        setDialogState(() {
                                          startDate = s;
                                          endDate = e;
                                        });
                                      },
                                      t,
                                    ),
                                    _quickRangeChip(
                                      '90 hari terakhir',
                                      90,
                                      (s, e) {
                                        setDialogState(() {
                                          startDate = s;
                                          endDate = e;
                                        });
                                      },
                                      t,
                                    ),
                                  ],
                                ),
                              ],

                              RadioListTile<String>(
                                value: 'all',
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                activeColor: t.danger,
                                title: Text(
                                  'Semua log',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: t.cellText,
                                  ),
                                ),
                                subtitle: Text(
                                  'Menghapus seluruh riwayat aktivitas',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: t.mutedText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: t.danger.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: t.danger.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: t.danger,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Data yang sudah dihapus tidak dapat dikembalikan.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: t.danger,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: _isDeleting
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isDeleting
                        ? null
                        : () async {
                            if (scope == 'range' &&
                                (startDate == null || endDate == null)) {
                              _showMessage(
                                'Pilih tanggal mulai dan tanggal akhir.',
                                isError: true,
                                t: t,
                              );
                              return;
                            }
                            final ok = await _confirmDelete(
                              dialogContext,
                              scope: scope,
                              startDate: startDate,
                              endDate: endDate,
                              t: t,
                            );
                            if (ok != true) return;
                            setDialogState(() => _isDeleting = true);
                            final success = scope == 'all'
                                ? await _deleteAllLogs(t)
                                : await _deleteLogsByRange(
                                    startDate!,
                                    endDate!,
                                    t,
                                  );
                            if (!mounted) return;
                            setDialogState(() => _isDeleting = false);
                            if (success && dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          },
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.delete_outline, size: 18),
                    label: Text(_isDeleting ? 'Menghapus...' : 'Hapus'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: t.danger,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDatePickerTile({
    required String label,
    required DateTime? value,
    required VoidCallback onPick,
    required AdminTheme t,
  }) {
    final text = value == null ? 'Pilih tanggal' : _formatDateId(value);

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: t.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: t.mutedText,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.grey400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: value == null
                          ? AppColors.grey400
                          : t.cellText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickRangeChip(
    String label,
    int days,
    void Function(DateTime start, DateTime end) onSelect,
    AdminTheme t,
  ) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: () {
        final end = DateTime.now();
        final start = end.subtract(Duration(days: days));
        onSelect(start, end);
      },
      backgroundColor: t.accent.withValues(alpha: 0.10),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Future<bool?> _confirmDelete(
    BuildContext dialogContext, {
    required String scope,
    DateTime? startDate,
    DateTime? endDate,
    required AdminTheme t,
  }) {
    final String desc = scope == 'all'
        ? 'SEMUA log aktivitas akan dihapus permanen.'
        : 'Log dari ${_formatDateId(startDate!)} '
            'sampai ${_formatDateId(endDate!)} '
            'akan dihapus permanen.';

    return showDialog<bool>(
      context: dialogContext,
      builder: (ctx) {
        return AdminThemeProvider(
          theme: t,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: Text(
              'Konfirmasi Penghapusan',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: t.cellText,
              ),
            ),
            content: Text(
              desc,
              style: TextStyle(color: t.mutedText),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.danger,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Ya, Hapus'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _deleteLogsByRange(
    DateTime start,
    DateTime end,
    AdminTheme t,
  ) async {
    try {
      final startStr = _formatDateApi(start);
      final endStr = _formatDateApi(end);

      final url =
          '/activity-logs/by-range?start_date=$startStr&end_date=$endStr';

      debugPrint('DELETE BY RANGE: $url');

      final response = await ApiService.delete(url);

      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('BODY: ${response.body}');

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        final deleted = body['deleted'] ?? 0;
        _showMessage('$deleted log berhasil dihapus.', t: t);
        await _loadActivities();
        return true;
      }

      _showMessage(
        body['message']?.toString() ?? 'Gagal menghapus log.',
        isError: true,
        t: t,
      );
      return false;
    } catch (e) {
      debugPrint('DELETE BY RANGE ERROR: $e');
      _showMessage('Terjadi kesalahan: $e', isError: true, t: t);
      return false;
    }
  }

  Future<bool> _deleteAllLogs(AdminTheme t) async {
    try {
      debugPrint('DELETE ALL');

      final response = await ApiService.delete('/activity-logs/all');

      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('BODY: ${response.body}');

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        final deleted = body['deleted'] ?? 0;
        _showMessage('$deleted log berhasil dihapus.', t: t);
        await _loadActivities();
        return true;
      }

      _showMessage(
        body['message']?.toString() ?? 'Gagal menghapus semua log.',
        isError: true,
        t: t,
      );
      return false;
    } catch (e) {
      debugPrint('DELETE ALL ERROR: $e');
      _showMessage('Terjadi kesalahan: $e', isError: true, t: t);
      return false;
    }
  }

  String _formatDateId(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${d.day.toString().padLeft(2, '0')} '
        '${months[d.month - 1]} ${d.year}';
  }

  String _formatDateApi(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  void _showMessage(
    String msg, {
    bool isError = false,
    required AdminTheme t,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? t.danger : t.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // ROLE COLOR — Semua TEAL (beda opacity per role)
  // ============================================================

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Super Admin':
        return AppColors.primaryTeal;
      case 'Admin':
        return AppColors.primaryTeal.withValues(alpha: 0.85);
      case 'Mitra':
        return AppColors.primaryTeal.withValues(alpha: 0.7);
      case 'Pelanggan':
        return AppColors.primaryTeal.withValues(alpha: 0.55);
      default:
        return AppColors.grey500;
    }
  }
}

// ============================================================
// MODEL
// ============================================================

class ActivityData {
  final int id;
  final String name;
  final String role;
  final String activity;
  final String detail;
  final String type;
  final String time;
  final IconData icon;

  ActivityData({
    required this.id,
    required this.name,
    required this.role,
    required this.activity,
    required this.detail,
    required this.type,
    required this.time,
    required this.icon,
  });

  factory ActivityData.fromJson(Map<String, dynamic> json) {
    final role = json['role']?.toString() ?? 'Sistem';

    return ActivityData(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'System',
      role: role,
      activity: json['activity'] ?? '-',
      detail: json['detail'] ?? '-',
      type: json['type'] ?? 'Sistem',
      time: json['time'] ?? '-',
      icon: _getIconFromRole(role, json['icon']),
    );
  }

  static IconData _getIconFromRole(String role, dynamic iconName) {
    final custom = _getCustomIcon(iconName);
    if (custom != null) return custom;

    switch (role) {
      case 'Super Admin':
        return Icons.admin_panel_settings_outlined;
      case 'Admin':
        return Icons.verified_user_outlined;
      case 'Mitra':
        return Icons.handyman_outlined;
      case 'Pelanggan':
        return Icons.person_outline;
      default:
        return Icons.history_outlined;
    }
  }

  static IconData? _getCustomIcon(dynamic iconName) {
    switch (iconName?.toString()) {
      case 'login':
        return Icons.login_outlined;
      case 'settings':
        return Icons.settings_outlined;
      case 'edit':
        return Icons.edit_outlined;
      case 'delete':
        return Icons.delete_outline;
      case 'restore':
        return Icons.restore_outlined;
      case 'stars':
        return Icons.stars_outlined;
      case 'person_add':
      case 'person_add_alt_1':
        return Icons.person_add_alt_1;
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      case 'security':
        return Icons.security_outlined;
      case 'logout':
        return Icons.logout_outlined;
      case 'post_add':
        return Icons.post_add;
      case 'check_circle':
        return Icons.check_circle_outline;
      case 'local_offer':
        return Icons.local_offer_outlined;
      case 'upload_file':
        return Icons.upload_file_outlined;
      case 'payment':
        return Icons.payment_outlined;
      case 'report_problem':
        return Icons.report_problem_outlined;
      case 'block':
        return Icons.block;
      default:
        return null;
    }
  }
}