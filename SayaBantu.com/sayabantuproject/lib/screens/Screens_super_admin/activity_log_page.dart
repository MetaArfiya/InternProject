import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';

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
  // DESIGN TOKENS (disamakan dengan AdminVerificationScreen)
  // ============================================================

  static const Color _accent = Color(0xFFF97316);
  static const Color _successColor = Color(0xFF16A34A);
  static const Color _dangerColor = Color(0xFFDC2626);
  static const Color _infoColor = Color(0xFF2563EB);
  static const Color _warningColor = Color(0xFFD97706);
  static const Color _purpleColor = Color(0xFF7C3AED);

  static const Color _tableBorder = Color(0xFFE5E7EB);
  static const Color _tableDivider = Color(0xFFF3F4F6);
  static const Color _headerText = Color(0xFF6B7280);
  static const Color _cellText = Color(0xFF111827);
  static const Color _mutedText = Color(0xFF64748B);

  static const double _gapAfterHeader = 16;
  static const double _gapBetweenSections = 16;
  static const double _cardRadius = 14;
  static const double _radius = 10;

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
  // LOAD ACTIVITY DARI DATABASE
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
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                _buildHeader(context, isMobile),
                const SizedBox(height: _gapAfterHeader),

                // SEARCH + FILTER
                _buildFilterSection(isMobile),
                const SizedBox(height: _gapBetweenSections),

                // CONTENT
                _buildContentBody(isMobile),

                // PAGINATION
                if (!_isLoading &&
                    _errorMessage == null &&
                    _filteredActivities.isNotEmpty) ...[
                  const SizedBox(height: _gapBetweenSections),
                  _buildPaginationFullWidth(isMobile),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // CONTENT BODY
  // ============================================================
  Widget _buildContentBody(bool isMobile) {
    if (_isLoading) return _buildLoadingState();
    if (_errorMessage != null) return _buildErrorState();

    final totalFiltered = _filteredActivities.length;
    if (totalFiltered == 0) return _buildEmptyState();

    final activities = _paginatedActivities;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _tableBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (!isMobile) _buildTableHeader(),
          ...activities.asMap().entries.map((entry) {
            final number =
                (_currentPage - 1) * _itemsPerPage + entry.key + 1;
            return _buildActivityItem(
              entry.value,
              isMobile,
              entry.key == activities.length - 1,
              number,
            );
          }),
        ],
      ),
    );
  }

  // ============================================================
  // PAGINATION (disamakan dgn AdminVerificationScreen)
  // ============================================================
  Widget _buildPaginationFullWidth(bool isMobile) {
    final total = _filteredActivities.length;
    final totalPages = _totalPages;
    final startItem = (_currentPage - 1) * _itemsPerPage + 1;
    final endItem = (startItem + _itemsPerPage - 1).clamp(0, total);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _tableBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              'Menampilkan $startItem–$endItem dari $total aktivitas',
              style: const TextStyle(
                fontSize: 12.5,
                color: _headerText,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _tableBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _itemsPerPage,
                    isDense: true,
                    icon: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: _headerText,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _cellText,
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
              ),
              const SizedBox(width: 8),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Hal $_currentPage / $totalPages',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _paginationIconButton(
                icon: Icons.chevron_right,
                onTap: _currentPage < totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
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
  }) {
    return Material(
      color: Colors.white,
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
              color: onTap == null
                  ? const Color(0xFFE5E7EB)
                  : const Color(0xFFD1D5DB),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: onTap == null
                ? const Color(0xFFD1D5DB)
                : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER — disamakan dgn AdminVerificationScreen
  // ============================================================
  Widget _buildHeader(BuildContext context, bool isMobile) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Log Aktivitas',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (!isMobile) ...[
              const SizedBox(width: 12),
              _buildDeleteButton(),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Pantau seluruh aktivitas pengguna, mitra, admin, dan sistem.',
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TOMBOL HAPUS
  // ============================================================
  Widget _buildDeleteButton() {
    return OutlinedButton.icon(
      onPressed: _isDeleting ? null : _showDeleteRangeDialog,
      icon: const Icon(Icons.delete_sweep_outlined, size: 16),
      label: const Text(
        'Hapus Log',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: _dangerColor,
        side: BorderSide(color: _dangerColor.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH + FILTER
  // ============================================================
  Widget _buildFilterSection(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchField(),
          const SizedBox(height: 10),
          _buildFilterDropdown(),
          const SizedBox(height: 10),
          _buildDeleteButton(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _buildSearchField()),
        const SizedBox(width: 14),
        SizedBox(width: 200, child: _buildFilterDropdown()),
      ],
    );
  }

  // ============================================================
  // SEARCH FIELD
  // ============================================================
  Widget _buildSearchField() {
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
        style: const TextStyle(fontSize: 13, color: _cellText),
        decoration: InputDecoration(
          hintText: 'Cari aktivitas, nama, atau role...',
          hintStyle: const TextStyle(
            fontSize: 13,
            color: Color(0xFF9CA3AF),
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: _headerText,
            size: 20,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radius),
            borderSide: const BorderSide(color: _tableBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radius),
            borderSide: const BorderSide(color: _tableBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radius),
            borderSide: const BorderSide(color: _accent, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FILTER DROPDOWN
  // ============================================================
  Widget _buildFilterDropdown() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _tableBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          isExpanded: true,
          borderRadius: BorderRadius.circular(_radius),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: _headerText,
            size: 20,
          ),
          style: const TextStyle(
            fontSize: 13,
            color: _cellText,
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
  // TABLE HEADER (disamakan dgn tabel AdminVerificationScreen)
  // ============================================================
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(_radius)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              'No',
              style: TextStyle(
                fontSize: 12,
                color: _headerText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: 240,
            child: Text(
              'Pengguna',
              style: TextStyle(
                fontSize: 12,
                color: _headerText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Aktivitas',
              style: TextStyle(
                fontSize: 12,
                color: _headerText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: 180,
            child: Text(
              'Waktu',
              style: TextStyle(
                fontSize: 12,
                color: _headerText,
                fontWeight: FontWeight.w500,
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
  ) {
    if (isMobile) return _buildMobileActivityCard(activity, number);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                top: BorderSide(color: _tableDivider),
              ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _mutedText,
              ),
            ),
          ),
          SizedBox(width: 240, child: _buildUserInfo(activity)),
          Expanded(child: _buildActivityInfo(activity)),
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: _mutedText,
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
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _getRoleBackground(activity.role),
            shape: BoxShape.circle,
          ),
          child: Icon(
            activity.icon,
            size: 18,
            color: _getRoleColor(activity.role),
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
                  color: _cellText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                activity.role,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: _getRoleColor(activity.role),
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
  Widget _buildActivityInfo(ActivityData activity) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activity.activity,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _cellText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            activity.detail,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9CA3AF),
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
    Color background;
    Color foreground;

    switch (role) {
      case 'Super Admin':
        background = _purpleColor.withOpacity(0.12);
        foreground = _purpleColor;
        break;
      case 'Admin':
        background = _infoColor.withOpacity(0.12);
        foreground = _infoColor;
        break;
      case 'Mitra':
        background = _accent.withOpacity(0.12);
        foreground = _accent;
        break;
      case 'Pelanggan':
        background = _successColor.withOpacity(0.12);
        foreground = _successColor;
        break;
      case 'Sistem':
      default:
        background = const Color(0xFFCBD5E1).withOpacity(0.4);
        foreground = _mutedText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE CARD
  // ============================================================
  Widget _buildMobileActivityCard(ActivityData activity, int number) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _tableDivider),
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
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _mutedText,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _getRoleBackground(activity.role),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  activity.icon,
                  size: 19,
                  color: _getRoleColor(activity.role),
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
                        color: _cellText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      activity.role,
                      style: TextStyle(
                        fontSize: 11,
                        color: _getRoleColor(activity.role),
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
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _cellText,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            activity.detail,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.access_time_outlined,
                size: 14,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 5),
              Text(
                activity.time,
                style: const TextStyle(
                  fontSize: 11,
                  color: _mutedText,
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
  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: CircularProgressIndicator(color: _accent),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: _dangerColor,
          ),
          const SizedBox(height: 12),
          const Text(
            'Gagal mengambil log aktivitas',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7F1D1D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF991B1B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _loadActivities,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_radius),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _tableBorder),
      ),
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
              Icons.history_outlined,
              size: 34,
              color: _accent.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Aktivitas tidak ditemukan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _cellText,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Belum ada aktivitas yang sesuai dengan pencarian atau filter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: _mutedText,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DIALOG HEADER HELPER (disamakan dgn AdminVerificationScreen)
  // ============================================================
  Widget _dialogHeader(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(_radius),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _cellText,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, size: 20, color: _headerText),
          splashRadius: 22,
        ),
      ],
    );
  }

  // ============================================================
  // DIALOG: HAPUS LOG
  // ============================================================
  void _showDeleteRangeDialog() {
    DateTime? startDate;
    DateTime? endDate;
    String scope = 'range';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _dialogHeader(
                        dialogContext,
                        icon: Icons.delete_sweep_outlined,
                        color: _dangerColor,
                        title: 'Hapus Log Aktivitas',
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pilih metode penghapusan:',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _mutedText,
                                ),
                              ),
                              const SizedBox(height: 12),
                              RadioListTile<String>(
                                value: 'range',
                                groupValue: scope,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                activeColor: _accent,
                                title: const Text(
                                  'Berdasarkan rentang waktu',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                onChanged: (v) {
                                  if (v == null) return;
                                  setDialogState(() => scope = v);
                                },
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
                                ),
                                const SizedBox(height: 10),
                                _buildDatePickerTile(
                                  label: 'Sampai Tanggal',
                                  value: endDate,
                                  onPick: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: endDate ?? DateTime.now(),
                                      firstDate:
                                          startDate ?? DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      setDialogState(
                                          () => endDate = picked);
                                    }
                                  },
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _quickRangeChip(
                                        '7 hari terakhir', 7, (s, e) {
                                      setDialogState(() {
                                        startDate = s;
                                        endDate = e;
                                      });
                                    }),
                                    _quickRangeChip(
                                        '30 hari terakhir', 30, (s, e) {
                                      setDialogState(() {
                                        startDate = s;
                                        endDate = e;
                                      });
                                    }),
                                    _quickRangeChip(
                                        '90 hari terakhir', 90, (s, e) {
                                      setDialogState(() {
                                        startDate = s;
                                        endDate = e;
                                      });
                                    }),
                                  ],
                                ),
                              ],
                              RadioListTile<String>(
                                value: 'all',
                                groupValue: scope,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                activeColor: _dangerColor,
                                title: const Text(
                                  'Semua log',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Menghapus seluruh riwayat aktivitas',
                                  style: TextStyle(fontSize: 11),
                                ),
                                onChanged: (v) {
                                  if (v == null) return;
                                  setDialogState(() => scope = v);
                                },
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius:
                                      BorderRadius.circular(_radius),
                                  border: Border.all(
                                      color: const Color(0xFFFECACA)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        color: _dangerColor, size: 18),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Data yang sudah dihapus tidak dapat dikembalikan.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF991B1B),
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
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isDeleting
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 46),
                                foregroundColor: const Color(0xFF374151),
                                side: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(_radius),
                                ),
                              ),
                              child: const Text(
                                'Batal',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _isDeleting
                                  ? null
                                  : () async {
                                      if (scope == 'range' &&
                                          (startDate == null ||
                                              endDate == null)) {
                                        _showMessage(
                                          'Pilih tanggal mulai dan tanggal akhir.',
                                          isError: true,
                                        );
                                        return;
                                      }
                                      final ok = await _confirmDelete(
                                        dialogContext,
                                        scope: scope,
                                        startDate: startDate,
                                        endDate: endDate,
                                      );
                                      if (ok != true) return;
                                      setDialogState(
                                          () => _isDeleting = true);
                                      final success = scope == 'all'
                                          ? await _deleteAllLogs()
                                          : await _deleteLogsByRange(
                                              startDate!, endDate!);
                                      if (!mounted) return;
                                      setDialogState(
                                          () => _isDeleting = false);
                                      if (success &&
                                          dialogContext.mounted) {
                                        Navigator.pop(dialogContext);
                                      }
                                    },
                              icon: _isDeleting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.delete_outline,
                                      size: 18),
                              label: Text(
                                  _isDeleting ? 'Menghapus...' : 'Hapus'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _dangerColor,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 46),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(_radius),
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

  Widget _buildDatePickerTile({
    required String label,
    required DateTime? value,
    required VoidCallback onPick,
  }) {
    final text = value == null ? 'Pilih tanggal' : _formatDateId(value);

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(_radius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: _tableBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: _headerText),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: value == null
                          ? const Color(0xFF94A3B8)
                          : _cellText,
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
  ) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: () {
        final end = DateTime.now();
        final start = end.subtract(Duration(days: days));
        onSelect(start, end);
      },
      backgroundColor: _accent.withOpacity(0.10),
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
  }) {
    final String desc = scope == 'all'
        ? 'SEMUA log aktivitas akan dihapus permanen.'
        : 'Log dari ${_formatDateId(startDate!)} '
            'sampai ${_formatDateId(endDate!)} '
            'akan dihapus permanen.';

    return showDialog<bool>(
      context: dialogContext,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _dialogHeader(
                    ctx,
                    icon: Icons.warning_amber_rounded,
                    color: _dangerColor,
                    title: 'Konfirmasi Penghapusan',
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 46),
                            foregroundColor: const Color(0xFF374151),
                            side: const BorderSide(
                              color: Color(0xFFD1D5DB),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_radius),
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(ctx, true),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text(
                            'Ya, Hapus',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _dangerColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 46),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_radius),
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
  }

  Future<bool> _deleteLogsByRange(DateTime start, DateTime end) async {
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
        _showMessage('$deleted log berhasil dihapus.');
        await _loadActivities();
        return true;
      }

      _showMessage(
        body['message']?.toString() ?? 'Gagal menghapus log.',
        isError: true,
      );
      return false;
    } catch (e) {
      debugPrint('DELETE BY RANGE ERROR: $e');
      _showMessage('Terjadi kesalahan: $e', isError: true);
      return false;
    }
  }

  Future<bool> _deleteAllLogs() async {
    try {
      debugPrint('DELETE ALL');

      final response = await ApiService.delete('/activity-logs/all');

      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('BODY: ${response.body}');

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        final deleted = body['deleted'] ?? 0;
        _showMessage('$deleted log berhasil dihapus.');
        await _loadActivities();
        return true;
      }

      _showMessage(
        body['message']?.toString() ?? 'Gagal menghapus semua log.',
        isError: true,
      );
      return false;
    } catch (e) {
      debugPrint('DELETE ALL ERROR: $e');
      _showMessage('Terjadi kesalahan: $e', isError: true);
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

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? _dangerColor : _successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Color _getRoleBackground(String role) {
    switch (role) {
      case 'Super Admin':
        return _purpleColor.withOpacity(0.12);
      case 'Admin':
        return _infoColor.withOpacity(0.12);
      case 'Mitra':
        return _accent.withOpacity(0.12);
      case 'Pelanggan':
        return _successColor.withOpacity(0.12);
      default:
        return const Color(0xFFCBD5E1).withOpacity(0.4);
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Super Admin':
        return _purpleColor;
      case 'Admin':
        return _infoColor;
      case 'Mitra':
        return _accent;
      case 'Pelanggan':
        return _successColor;
      default:
        return _mutedText;
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