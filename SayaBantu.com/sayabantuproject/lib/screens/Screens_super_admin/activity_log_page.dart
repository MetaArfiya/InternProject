import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class ActivityLogPage extends StatefulWidget {
  const ActivityLogPage({super.key});

  @override
  State<ActivityLogPage> createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> {
  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';
  String _selectedFilter = 'Semua';

  List<ActivityData> _activities = [];

  bool _isLoading = true;
  String? _errorMessage;

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

      // ApiService.get() mengembalikan http.Response
      final Map<String, dynamic> responseData =
          jsonDecode(response.body);

      if (response.statusCode == 200 &&
          responseData['success'] == true) {
        final List<dynamic> data =
            responseData['data'] ?? [];

        final List<ActivityData> loadedActivities =
            data.map((item) {
          return ActivityData.fromJson(
            item as Map<String, dynamic>,
          );
        }).toList();

        if (!mounted) return;

        setState(() {
          _activities = loadedActivities;
          _isLoading = false;
        });
      } else {
        throw Exception(
          responseData['message'] ??
              'Gagal mengambil log aktivitas.',
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
      final matchesSearch =
          activity.name.toLowerCase().contains(query) ||
          activity.activity.toLowerCase().contains(query) ||
          activity.detail.toLowerCase().contains(query);

      final matchesFilter =
          _selectedFilter == 'Semua' ||
          activity.type == _selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 750;

        return Container(
          width: double.infinity,
          color: const Color(0xFFF5F8FC),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 28,
              0,
              isMobile ? 16 : 28,
              28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isMobile),

                const SizedBox(height: 20),

                _buildFilterSection(isMobile),

                const SizedBox(height: 20),

                _buildContent(isMobile),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent(bool isMobile) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return _buildActivityList(isMobile);
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(
        top: isMobile ? 16 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log Aktivitas',
            style: TextStyle(
              fontSize: isMobile ? 24 : 30,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Pantau seluruh aktivitas Super Admin dan sistem.',
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
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
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _buildSearchField(),
        ),
        const SizedBox(width: 14),
        SizedBox(
          width: 180,
          child: _buildFilterDropdown(),
        ),
      ],
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchField() {
    return SizedBox(
      height: 46,
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Cari aktivitas...',
          hintStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF64748B),
            size: 21,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Color(0xFF2563EB),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _buildFilterDropdown() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          isExpanded: true,
          borderRadius: BorderRadius.circular(10),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFF64748B),
            size: 21,
          ),
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF334155),
            fontWeight: FontWeight.w500,
          ),
          items: const [
            DropdownMenuItem(
              value: 'Semua',
              child: Text('Semua Aktivitas'),
            ),
            DropdownMenuItem(
              value: 'Admin',
              child: Text('Aktivitas Admin'),
            ),
            DropdownMenuItem(
              value: 'Sistem',
              child: Text('Aktivitas Sistem'),
            ),
            DropdownMenuItem(
              value: 'Login',
              child: Text('Aktivitas Login'),
            ),
          ],
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

  // ============================================================
  // ACTIVITY LIST
  // ============================================================

  Widget _buildActivityList(bool isMobile) {
    final activities = _filteredActivities;

    if (activities.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (!isMobile) _buildTableHeader(),

          ...activities.asMap().entries.map(
            (entry) {
              final int index = entry.key;
              final ActivityData activity = entry.value;

              return _buildActivityItem(
                activity,
                isMobile,
                index == activities.length - 1,
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABLE HEADER
  // ============================================================

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 15,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 230,
            child: Text(
              'PENGGUNA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'AKTIVITAS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          SizedBox(
            width: 190,
            child: Text(
              'WAKTU',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
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
  ) {
    if (isMobile) {
      return _buildMobileActivityCard(activity);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(
                  color: Color(0xFFE2E8F0),
                ),
              ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 230,
            child: _buildUserInfo(activity),
          ),

          Expanded(
            child: _buildActivityInfo(activity),
          ),

          SizedBox(
            width: 190,
            child: Row(
              children: [
                _buildTypeBadge(activity.type),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activity.time,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
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
            color: _getIconBackground(activity.type),
            shape: BoxShape.circle,
          ),
          child: Icon(
            activity.icon,
            size: 18,
            color: _getIconColor(activity.type),
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
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                activity.role,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
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
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            activity.detail,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BADGE
  // ============================================================

  Widget _buildTypeBadge(String type) {
    Color background;
    Color foreground;

    switch (type) {
      case 'Admin':
        background = const Color(0xFFEFF6FF);
        foreground = const Color(0xFF2563EB);
        break;

      case 'Sistem':
        background = const Color(0xFFFFF7ED);
        foreground = const Color(0xFFEA580C);
        break;

      case 'Login':
        background = const Color(0xFFECFDF5);
        foreground = const Color(0xFF059669);
        break;

      default:
        background = const Color(0xFFF1F5F9);
        foreground = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE
  // ============================================================

  Widget _buildMobileActivityCard(
    ActivityData activity,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _getIconBackground(activity.type),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  activity.icon,
                  size: 19,
                  color: _getIconColor(activity.type),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      activity.role,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),

              _buildTypeBadge(activity.type),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            activity.activity,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),

          const SizedBox(height: 5),

          Text(
            activity.detail,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(
                Icons.access_time_outlined,
                size: 15,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 5),
              Text(
                activity.time,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 60,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 50,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Color(0xFFEF4444),
          ),

          const SizedBox(height: 12),

          const Text(
            'Gagal mengambil log aktivitas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _errorMessage ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _loadActivities,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
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
      padding: const EdgeInsets.symmetric(
        vertical: 60,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.history_outlined,
            size: 52,
            color: Color(0xFFCBD5E1),
          ),
          SizedBox(height: 12),
          Text(
            'Aktivitas tidak ditemukan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Belum ada aktivitas yang sesuai dengan pencarian atau filter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COLORS
  // ============================================================

  Color _getIconBackground(String type) {
    switch (type) {
      case 'Admin':
        return const Color(0xFFEFF6FF);

      case 'Sistem':
        return const Color(0xFFFFF7ED);

      case 'Login':
        return const Color(0xFFECFDF5);

      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'Admin':
        return const Color(0xFF2563EB);

      case 'Sistem':
        return const Color(0xFFEA580C);

      case 'Login':
        return const Color(0xFF059669);

      default:
        return const Color(0xFF64748B);
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

  // ============================================================
  // FROM JSON
  // ============================================================

  factory ActivityData.fromJson(
    Map<String, dynamic> json,
  ) {
    return ActivityData(
      id: json['id'] ?? 0,

      name: json['name'] ?? 'Super Admin',

      role: json['role'] ?? 'Super Admin',

      activity: json['activity'] ?? '-',

      detail: json['detail'] ?? '-',

      type: json['type'] ?? 'Sistem',

      time: json['time'] ?? '-',

      icon: _getIconFromString(
        json['icon'],
      ),
    );
  }

  // ============================================================
  // CONVERT ICON STRING → ICONDATA
  // ============================================================

  static IconData _getIconFromString(
    dynamic iconName,
  ) {
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
        return Icons.person_add_alt_1;

      case 'person_add_alt_1':
        return Icons.person_add_alt_1;

      case 'admin':
        return Icons.admin_panel_settings_outlined;

      case 'security':
        return Icons.security_outlined;

      case 'logout':
        return Icons.logout_outlined;

      default:
        return Icons.history_outlined;
    }
  }
}