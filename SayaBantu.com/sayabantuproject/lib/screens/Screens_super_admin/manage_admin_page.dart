import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';

class ManageAdminPage extends StatefulWidget {
  const ManageAdminPage({super.key});

  @override
  State<ManageAdminPage> createState() => _ManageAdminPageState();
}

class _ManageAdminPageState extends State<ManageAdminPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _admins = [];

  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;

  // ============================================================
  // DESIGN TOKENS (disamakan dengan AdminVerificationScreen)
  // ============================================================

  static const Color _accent = Color(0xFF2563EB);
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
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    _loadAdmins();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD ADMIN
  // ============================================================

  Future<void> _loadAdmins() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.get('/superadmin/admins');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body['success'] == true) {
          final data = body['data'];

          if (data is List) {
            setState(() {
              _admins = data
                  .map<Map<String, dynamic>>(
                    (item) => Map<String, dynamic>.from(item),
                  )
                  .toList();
              _isLoading = false;
            });
          } else {
            setState(() {
              _admins = [];
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _errorMessage =
                body['message'] ?? 'Gagal mengambil data admin.';
            _isLoading = false;
          });
        }
      } else {
        String message = 'Gagal mengambil data admin.';
        try {
          final body = jsonDecode(response.body);
          if (body['message'] != null) {
            message = body['message'].toString();
          }
        } catch (_) {}

        setState(() {
          _errorMessage = '$message\nStatus: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Tidak dapat terhubung ke server.\n$e';
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<Map<String, dynamic>> get _filteredAdmins {
    if (_searchQuery.isEmpty) return _admins;

    return _admins.where((admin) {
      final name = (admin['name'] ?? '').toString().toLowerCase();
      final email = (admin['email'] ?? '').toString().toLowerCase();
      final phone = (admin['phone'] ?? '').toString().toLowerCase();

      return name.contains(_searchQuery) ||
          email.contains(_searchQuery) ||
          phone.contains(_searchQuery);
    }).toList();
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
          child: RefreshIndicator(
            onRefresh: _loadAdmins,
            color: _accent,
            child: SingleChildScrollView(
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
                  _buildSearchAndAction(isMobile),
                  const SizedBox(height: _gapBetweenSections),

                  if (_isLoading)
                    _buildLoading()
                  else if (_errorMessage != null)
                    _buildError()
                  else if (_filteredAdmins.isEmpty)
                    _buildEmptyState()
                  else if (isMobile)
                    _buildMobileList()
                  else
                    _buildDesktopTable(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // HEADER — disamakan dgn AdminVerificationScreen:
  //   • Judul: headlineSmall + bold
  //   • Subtitle: bodyMedium + grey.shade600
  //   • Jarak judul → subtitle = 6 px
  // ============================================================

  Widget _buildHeader(BuildContext context, bool isMobile) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kelola Admin',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kelola akun dan akses administrator platform.',
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SEARCH + ACTION
  // ============================================================

  Widget _buildSearchAndAction(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchBox(),
          const SizedBox(height: 10),
          _buildAddButton(),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _buildSearchBox()),
        const SizedBox(width: 14),
        _buildAddButton(),
      ],
    );
  }

  Widget _buildSearchBox() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _tableBorder),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 13, color: _cellText),
        decoration: const InputDecoration(
          hintText: 'Cari nama, email, atau nomor telepon...',
          hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          prefixIcon: Icon(
            Icons.search,
            color: _headerText,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: _showAddAdminDialog,
        icon: const Icon(Icons.person_add_alt_1, size: 17),
        label: const Text(
          'Tambah Admin',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOADING — disamakan dgn AdminVerificationScreen
  // ============================================================

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: CircularProgressIndicator(color: _accent),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
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
            size: 42,
            color: _dangerColor,
          ),
          const SizedBox(height: 12),
          const Text(
            'Gagal mengambil data admin',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF7F1D1D),
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF991B1B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _loadAdmins,
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

  // ============================================================
  // EMPTY — disamakan dgn _buildEmptyCard di AdminVerificationScreen
  // ============================================================

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
              Icons.search_off,
              size: 34,
              color: _accent.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Admin tidak ditemukan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _mutedText,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WEB — TABEL (disamakan dgn tabel AdminVerificationScreen)
  // ============================================================

  Widget _buildDesktopTable() {
    final admins = _filteredAdmins;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _tableBorder),
      ),
      child: Column(
        children: [
          _buildTableHeaderRow(),
          ...List.generate(
            admins.length,
            (i) => _buildTableDataRow(admins[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(_radius)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Admin',
              style: TextStyle(
                fontSize: 12,
                color: _headerText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Kontak',
              style: TextStyle(
                fontSize: 12,
                color: _headerText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Status',
              style: TextStyle(
                fontSize: 12,
                color: _headerText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Login Terakhir',
              style: TextStyle(
                fontSize: 12,
                color: _headerText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Aksi',
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

  Widget _buildTableDataRow(Map<String, dynamic> admin) {
    final name = (admin['name'] ?? '-').toString();
    final email = (admin['email'] ?? '-').toString();
    final phone = (admin['phone'] ?? '-').toString();
    final status = _getStatus(admin);
    final lastLogin = _formatDate(admin['last_login_at']);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _tableDivider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Kolom 1: Avatar + Nama + Role
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _buildAvatar(name),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _cellText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Kolom 2: Kontak
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: _cellText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),

          // Kolom 3: Status
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusBadge(status),
            ),
          ),

          // Kolom 4: Login terakhir
          Expanded(
            flex: 3,
            child: Text(
              lastLogin,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: _cellText,
                height: 1.3,
              ),
            ),
          ),

          // Kolom 5: Aksi
          Expanded(
            flex: 2,
            child: Row(
              children: [
                _iconButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Edit',
                  color: const Color(0xFF475569),
                  onTap: () => _showEditAdminDialog(admin),
                ),
                const SizedBox(width: 4),
                _iconButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Hapus',
                  color: _dangerColor,
                  onTap: () => _deleteAdmin(admin),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE — CARD LIST
  // ============================================================

  Widget _buildMobileList() {
    final admins = _filteredAdmins;

    return Column(
      children: admins.asMap().entries.map((entry) {
        final index = entry.key;
        final admin = entry.value;

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == admins.length - 1 ? 0 : 12,
          ),
          child: _buildMobileCard(admin),
        );
      }).toList(),
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> admin) {
    final name = (admin['name'] ?? '-').toString();
    final email = (admin['email'] ?? '-').toString();
    final phone = (admin['phone'] ?? '-').toString();
    final status = _getStatus(admin);
    final lastLogin = _formatDate(admin['last_login_at']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _tableBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: _cellText,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(status),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: _tableDivider),
          const SizedBox(height: 12),

          _mobileInfo(Icons.email_outlined, email),
          const SizedBox(height: 8),
          _mobileInfo(Icons.phone_outlined, phone),
          const SizedBox(height: 8),
          _mobileInfo(Icons.access_time_outlined, lastLogin),

          const SizedBox(height: 14),
          const Divider(height: 1, color: _tableDivider),
          const SizedBox(height: 10),

          // AKSI
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditAdminDialog(admin),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text(
                    'Edit',
                    style: TextStyle(fontSize: 12.5),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_radius),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteAdmin(admin),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text(
                    'Hapus',
                    style: TextStyle(fontSize: 12.5),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _dangerColor,
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_radius),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mobileInfo(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              color: _cellText,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: _accent,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _getStatus(Map<String, dynamic> admin) {
    final value = admin['is_active'];

    if (value == true ||
        value == 1 ||
        value == '1' ||
        value == 'true') {
      return 'Aktif';
    }

    return 'Nonaktif';
  }

  Widget _buildStatusBadge(String status) {
    final active = status == 'Aktif';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active
            ? _successColor.withOpacity(0.12)
            : const Color(0xFFCBD5E1).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? _successColor : const Color(0xFF9CA3AF),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: active ? const Color(0xFF15803D) : _mutedText,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return '-';

    try {
      final date = DateTime.parse(value.toString()).toLocal();

      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];

      final day = date.day.toString().padLeft(2, '0');
      final month = months[date.month - 1];
      final year = date.year.toString();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$day $month $year, $hour:$minute';
    } catch (_) {
      return value.toString();
    }
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
  // TAMBAH ADMIN
  // ============================================================

  void _showAddAdminDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;

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
                        icon: Icons.person_add_alt_1,
                        color: _accent,
                        title: 'Tambah Admin',
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _dialogField(
                                controller: nameController,
                                label: 'Nama',
                                icon: Icons.person_outline,
                                enabled: !isSubmitting,
                              ),
                              const SizedBox(height: 12),
                              _dialogField(
                                controller: emailController,
                                label: 'Email',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                enabled: !isSubmitting,
                              ),
                              const SizedBox(height: 12),
                              _dialogField(
                                controller: phoneController,
                                label: 'Nomor Telepon',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                enabled: !isSubmitting,
                              ),
                              const SizedBox(height: 12),
                              _dialogField(
                                controller: passwordController,
                                label: 'Password',
                                icon: Icons.lock_outline,
                                obscureText: true,
                                enabled: !isSubmitting,
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
                              onPressed: isSubmitting
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
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
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
                                      final name =
                                          nameController.text.trim();
                                      final email =
                                          emailController.text.trim();
                                      final phone =
                                          phoneController.text.trim();
                                      final password =
                                          passwordController.text;

                                      if (name.isEmpty ||
                                          email.isEmpty ||
                                          password.isEmpty) {
                                        _showMessage(
                                          'Nama, email, dan password wajib diisi.',
                                          isError: true,
                                        );
                                        return;
                                      }

                                      if (phone.isNotEmpty &&
                                          !RegExp(r'^[0-9]+$')
                                              .hasMatch(phone)) {
                                        _showMessage(
                                          'Nomor telepon hanya boleh berisi angka.',
                                          isError: true,
                                        );
                                        return;
                                      }

                                      if (password.length < 6) {
                                        _showMessage(
                                          'Password minimal 6 karakter.',
                                          isError: true,
                                        );
                                        return;
                                      }

                                      setDialogState(
                                        () => isSubmitting = true,
                                      );

                                      try {
                                        final response =
                                            await ApiService.post(
                                          '/superadmin/create-admin',
                                          {
                                            'name': name,
                                            'email': email,
                                            'phone': phone,
                                            'password': password,
                                          },
                                        );

                                        if (response.statusCode == 201) {
                                          if (dialogContext.mounted) {
                                            Navigator.pop(dialogContext);
                                          }

                                          _showMessage(
                                            'Admin berhasil ditambahkan.',
                                          );

                                          await _loadAdmins();
                                        } else {
                                          String message =
                                              'Gagal menambahkan admin.';

                                          try {
                                            final body =
                                                jsonDecode(response.body);
                                            message =
                                                body['message']?.toString() ??
                                                    message;
                                          } catch (_) {}

                                          if (dialogContext.mounted) {
                                            setDialogState(
                                              () => isSubmitting = false,
                                            );
                                          }

                                          _showMessage(
                                            message,
                                            isError: true,
                                          );
                                        }
                                      } catch (e) {
                                        if (dialogContext.mounted) {
                                          setDialogState(
                                            () => isSubmitting = false,
                                          );
                                        }

                                        _showMessage(
                                          'Terjadi kesalahan: $e',
                                          isError: true,
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 46),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(_radius),
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
                                      'Tambah',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
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
    ).then((_) {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      passwordController.dispose();
    });
  }

  // ============================================================
  // EDIT ADMIN
  // ============================================================

  void _showEditAdminDialog(Map<String, dynamic> admin) {
    final id = admin['id'];

    if (id == null) {
      _showMessage('ID admin tidak ditemukan.', isError: true);
      return;
    }

    final nameController = TextEditingController(
      text: (admin['name'] ?? '').toString(),
    );
    final emailController = TextEditingController(
      text: (admin['email'] ?? '').toString(),
    );
    final phoneController = TextEditingController(
      text: (admin['phone'] ?? '').toString(),
    );

    bool isActive = admin['is_active'] == true ||
        admin['is_active'] == 1 ||
        admin['is_active'] == '1' ||
        admin['is_active'] == 'true';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;

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
                        icon: Icons.edit_outlined,
                        color: _accent,
                        title: 'Edit Admin',
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _dialogField(
                                controller: nameController,
                                label: 'Nama',
                                icon: Icons.person_outline,
                                enabled: !isSubmitting,
                              ),
                              const SizedBox(height: 12),
                              _dialogField(
                                controller: emailController,
                                label: 'Email',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                enabled: !isSubmitting,
                              ),
                              const SizedBox(height: 12),
                              _dialogField(
                                controller: phoneController,
                                label: 'Nomor Telepon',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                enabled: !isSubmitting,
                              ),
                              const SizedBox(height: 8),

                              // SWITCH STATUS
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius:
                                      BorderRadius.circular(_radius),
                                  border: Border.all(color: _tableBorder),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.toggle_on_outlined,
                                      size: 20,
                                      color: _headerText,
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'Status Aktif',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF374151),
                                        ),
                                      ),
                                    ),
                                    Switch(
                                      value: isActive,
                                      activeColor: _accent,
                                      onChanged: isSubmitting
                                          ? null
                                          : (value) {
                                              setDialogState(() {
                                                isActive = value;
                                              });
                                            },
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
                              onPressed: isSubmitting
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
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
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
                                      final name =
                                          nameController.text.trim();
                                      final email =
                                          emailController.text.trim();
                                      final phone =
                                          phoneController.text.trim();

                                      if (name.isEmpty || email.isEmpty) {
                                        _showMessage(
                                          'Nama dan email wajib diisi.',
                                          isError: true,
                                        );
                                        return;
                                      }

                                      if (phone.isNotEmpty &&
                                          !RegExp(r'^[0-9]+$')
                                              .hasMatch(phone)) {
                                        _showMessage(
                                          'Nomor telepon hanya boleh berisi angka.',
                                          isError: true,
                                        );
                                        return;
                                      }

                                      setDialogState(
                                        () => isSubmitting = true,
                                      );

                                      try {
                                        final response =
                                            await ApiService.put(
                                          '/superadmin/admins/$id',
                                          {
                                            'name': name,
                                            'email': email,
                                            'phone': phone,
                                            'is_active': isActive,
                                          },
                                        );

                                        if (response.statusCode == 200) {
                                          if (dialogContext.mounted) {
                                            Navigator.pop(dialogContext);
                                          }

                                          _showMessage(
                                            'Data admin berhasil diperbarui.',
                                          );

                                          await _loadAdmins();
                                          return;
                                        }

                                        String message =
                                            'Gagal memperbarui admin.';
                                        try {
                                          final body =
                                              jsonDecode(response.body);
                                          message =
                                              body['message']?.toString() ??
                                                  message;
                                        } catch (_) {}

                                        if (dialogContext.mounted) {
                                          setDialogState(
                                            () => isSubmitting = false,
                                          );
                                        }

                                        _showMessage(
                                          message,
                                          isError: true,
                                        );
                                      } catch (e) {
                                        if (dialogContext.mounted) {
                                          setDialogState(
                                            () => isSubmitting = false,
                                          );
                                        }

                                        _showMessage(
                                          'Terjadi kesalahan: $e',
                                          isError: true,
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 46),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(_radius),
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
                                      'Simpan',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
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
    ).then((_) {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
    });
  }

  // ============================================================
  // DELETE ADMIN
  // ============================================================

  void _deleteAdmin(Map<String, dynamic> admin) {
    final id = admin['id'];

    if (id == null) {
      _showMessage('ID admin tidak ditemukan.', isError: true);
      return;
    }

    final name = (admin['name'] ?? '-').toString();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isDeleting = false;

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
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _dialogHeader(
                        dialogContext,
                        icon: Icons.delete_outline,
                        color: _dangerColor,
                        title: 'Hapus Admin',
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Text(
                        'Apakah kamu yakin ingin menghapus admin "$name"?\n\n'
                        'Tindakan ini tidak dapat dibatalkan.',
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
                              onPressed: isDeleting
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
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: isDeleting
                                  ? null
                                  : () async {
                                      setDialogState(
                                          () => isDeleting = true);

                                      try {
                                        final response =
                                            await ApiService.delete(
                                          '/superadmin/admins/$id',
                                        );

                                        if (response.statusCode == 200) {
                                          if (dialogContext.mounted) {
                                            Navigator.pop(dialogContext);
                                          }

                                          _showMessage(
                                              'Admin berhasil dihapus.');
                                          await _loadAdmins();
                                        } else {
                                          String message =
                                              'Gagal menghapus admin.';
                                          try {
                                            final body =
                                                jsonDecode(response.body);
                                            message =
                                                body['message']?.toString() ??
                                                    message;
                                          } catch (_) {}

                                          if (dialogContext.mounted) {
                                            setDialogState(
                                                () => isDeleting = false);
                                          }

                                          _showMessage(message,
                                              isError: true);
                                        }
                                      } catch (e) {
                                        if (dialogContext.mounted) {
                                          setDialogState(
                                              () => isDeleting = false);
                                        }

                                        _showMessage(
                                          'Terjadi kesalahan: $e',
                                          isError: true,
                                        );
                                      }
                                    },
                              icon: isDeleting
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
                                isDeleting ? 'Menghapus...' : 'Hapus',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
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
      },
    );
  }

  // ============================================================
  // DIALOG FIELD
  // ============================================================

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool obscureText = false,
    bool enabled = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      enabled: enabled,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 19) : null,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
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
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? _dangerColor : _successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}