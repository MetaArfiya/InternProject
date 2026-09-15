// lib/screens/Screens_SuperAdmin/activity_log_page.dart

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

      debugPrint('📋 ACTIVITY LOGS: ${response.statusCode}');
      debugPrint('📋 BODY: ${response.body}');

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
    if (_isLoading) return _buildLoadingState();
    if (_errorMessage != null) return _buildErrorState();
    return _buildActivityList(isMobile);
  }

  // ============================================================
  // HEADER
  // ============================================================
  Widget _buildHeader(bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(top: isMobile ? 16 : 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
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
                  'Pantau seluruh aktivitas pengguna, mitra, admin, dan sistem.',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 16),
            _buildDeleteButton(),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // TOMBOL HAPUS
  // ============================================================
  Widget _buildDeleteButton() {
    return OutlinedButton.icon(
      onPressed: _isDeleting ? null : _showDeleteRangeDialog,
      icon: const Icon(Icons.delete_sweep_outlined, size: 18),
      label: const Text(
        'Hapus Log',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFDC2626),
        side: const BorderSide(color: Color(0xFFDC2626)),
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
          setState(() => _searchQuery = value);
        },
        decoration: InputDecoration(
          hintText: 'Cari aktivitas, nama, atau role...',
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
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2563EB)),
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
            fontSize: 13,
            color: Color(0xFF334155),
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
            setState(() => _selectedFilter = value);
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

    if (activities.isEmpty) return _buildEmptyState();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (!isMobile) _buildTableHeader(),
          ...activities.asMap().entries.map((entry) {
            return _buildActivityItem(
              entry.value,
              isMobile,
              entry.key == activities.length - 1,
            );
          }),
        ],
      ),
    );
  }

  // ============================================================
  // TABLE HEADER
  // ============================================================
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
      child: const Row(
        children: [
          SizedBox(
            width: 240,
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
            width: 180,
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
    if (isMobile) return _buildMobileActivityCard(activity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
      ),
      child: Row(
        children: [
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
                  color: Color(0xFF1E293B),
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
  // ROLE BADGE
  // ============================================================
  Widget _buildRoleBadge(String role) {
    Color background;
    Color foreground;

    switch (role) {
      case 'Super Admin':
        background = const Color(0xFFF3E8FF);
        foreground = const Color(0xFF7C3AED);
        break;

      case 'Admin':
        background = const Color(0xFFEFF6FF);
        foreground = const Color(0xFF2563EB);
        break;

      case 'Mitra':
        background = const Color(0xFFFFF7ED);
        foreground = const Color(0xFFEA580C);
        break;

      case 'Pelanggan':
        background = const Color(0xFFECFDF5);
        foreground = const Color(0xFF059669);
        break;

      case 'Sistem':
      default:
        background = const Color(0xFFF1F5F9);
        foreground = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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
  Widget _buildMobileActivityCard(ActivityData activity) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
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
                        color: Color(0xFF1E293B),
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
  // DIALOG: HAPUS LOG
  // ============================================================
  void _showDeleteRangeDialog() {
    DateTime? startDate;
    DateTime? endDate;
    String scope = 'range'; // 'range' | 'all'

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: const Row(
                children: [
                  Icon(Icons.delete_sweep_outlined,
                      color: Color(0xFFDC2626), size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Hapus Log Aktivitas',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 18),
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
                      const Text(
                        'Pilih metode penghapusan:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // RADIO: RENTANG WAKTU
                      RadioListTile<String>(
                        value: 'range',
                        groupValue: scope,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        activeColor: const Color(0xFF2563EB),
                        title: const Text(
                          'Berdasarkan rentang waktu',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
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
                              setDialogState(() => startDate = picked);
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
                              initialDate:
                                  endDate ?? DateTime.now(),
                              firstDate: startDate ?? DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setDialogState(() => endDate = picked);
                            }
                          },
                        ),

                        const SizedBox(height: 10),

                        // Quick pick
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _quickRangeChip('7 hari terakhir', 7, (s, e) {
                              setDialogState(() {
                                startDate = s;
                                endDate = e;
                              });
                            }),
                            _quickRangeChip('30 hari terakhir', 30, (s, e) {
                              setDialogState(() {
                                startDate = s;
                                endDate = e;
                              });
                            }),
                            _quickRangeChip('90 hari terakhir', 90, (s, e) {
                              setDialogState(() {
                                startDate = s;
                                endDate = e;
                              });
                            }),
                          ],
                        ),
                      ],

                      // RADIO: SEMUA LOG
                      RadioListTile<String>(
                        value: 'all',
                        groupValue: scope,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        activeColor: const Color(0xFFDC2626),
                        title: const Text(
                          'Semua log',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
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
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFFFECACA)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Color(0xFFDC2626), size: 18),
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
                          // Validasi
                          if (scope == 'range' &&
                              (startDate == null || endDate == null)) {
                            _showMessage(
                              'Pilih tanggal mulai dan tanggal akhir.',
                              isError: true,
                            );
                            return;
                          }

                          // Konfirmasi
                          final ok = await _confirmDelete(
                            dialogContext,
                            scope: scope,
                            startDate: startDate,
                            endDate: endDate,
                          );
                          if (ok != true) return;

                          setDialogState(() => _isDeleting = true);

                          final success = scope == 'all'
                              ? await _deleteAllLogs()
                              : await _deleteLogsByRange(
                                  startDate!, endDate!);

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
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.delete_outline, size: 18),
                  label: Text(_isDeleting ? 'Menghapus...' : 'Hapus'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
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
        );
      },
    );
  }

  // ============================================================
  // DATE PICKER TILE
  // ============================================================
  Widget _buildDatePickerTile({
    required String label,
    required DateTime? value,
    required VoidCallback onPick,
  }) {
    final text = value == null
        ? 'Pilih tanggal'
        : _formatDateId(value);

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: Color(0xFF64748B)),
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
                          : const Color(0xFF1E293B),
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

  // ============================================================
  // QUICK RANGE CHIP
  // ============================================================
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
      backgroundColor: const Color(0xFFEFF6FF),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  // ============================================================
  // KONFIRMASI
  // ============================================================
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
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            'Konfirmasi Penghapusan',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(desc),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya, Hapus'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // API CALL — HAPUS BY RANGE
  // ============================================================
  Future<bool> _deleteLogsByRange(DateTime start, DateTime end) async {
    try {
      final startStr = _formatDateApi(start);
      final endStr = _formatDateApi(end);

      final url =
          '/activity-logs/by-range?start_date=$startStr&end_date=$endStr';

      debugPrint('🗑️ DELETE BY RANGE: $url');

      final response = await ApiService.delete(url);

      debugPrint('🗑️ STATUS: ${response.statusCode}');
      debugPrint('🗑️ BODY: ${response.body}');

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
      debugPrint('❌ DELETE BY RANGE ERROR: $e');
      _showMessage('Terjadi kesalahan: $e', isError: true);
      return false;
    }
  }

  // ============================================================
  // API CALL — HAPUS SEMUA
  // ============================================================
  Future<bool> _deleteAllLogs() async {
    try {
      debugPrint('🗑️ DELETE ALL');

      final response = await ApiService.delete('/activity-logs/all');

      debugPrint('🗑️ STATUS: ${response.statusCode}');
      debugPrint('🗑️ BODY: ${response.body}');

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
      debugPrint('❌ DELETE ALL ERROR: $e');
      _showMessage('Terjadi kesalahan: $e', isError: true);
      return false;
    }
  }

  // ============================================================
  // FORMAT TANGGAL (untuk UI — "15 Sep 2026")
  // ============================================================
  String _formatDateId(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${d.day.toString().padLeft(2, '0')} '
        '${months[d.month - 1]} ${d.year}';
  }

  // ============================================================
  // FORMAT TANGGAL (untuk API — "2026-09-15")
  // ============================================================
  String _formatDateApi(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // SNACKBAR
  // ============================================================
  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor:
              isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // LOADING / ERROR / EMPTY
  // ============================================================
  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
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
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.history_outlined, size: 52, color: Color(0xFFCBD5E1)),
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
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COLORS — per role
  // ============================================================
  Color _getRoleBackground(String role) {
    switch (role) {
      case 'Super Admin':
        return const Color(0xFFF3E8FF);
      case 'Admin':
        return const Color(0xFFEFF6FF);
      case 'Mitra':
        return const Color(0xFFFFF7ED);
      case 'Pelanggan':
        return const Color(0xFFECFDF5);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Super Admin':
        return const Color(0xFF7C3AED);
      case 'Admin':
        return const Color(0xFF2563EB);
      case 'Mitra':
        return const Color(0xFFEA580C);
      case 'Pelanggan':
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

  // ============================================================
  // ICON MAPPER
  // ============================================================
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