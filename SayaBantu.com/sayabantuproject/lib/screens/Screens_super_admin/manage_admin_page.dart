import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/admin_theme_provider.dart';
import '../../theme/app_colors.dart';

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
  // THEME
  // ============================================================

  AdminTheme get theme => AdminThemeProvider.of(context);

  // ============================================================
  // BREAKPOINTS
  // ============================================================

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
    final t = theme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < _mobileBreakpoint;
        final isTablet =
            width >= _mobileBreakpoint && width < _tabletBreakpoint;

        final horizontalPadding =
            isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
        final verticalPadding = isMobile ? 16.0 : 28.0;

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: t.bg,
          child: RefreshIndicator(
            onRefresh: _loadAdmins,
            color: t.accent,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1300),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isMobile, t),
                      SizedBox(height: isMobile ? 18 : 24),
                      _buildSearchAndAction(isMobile, t),
                      SizedBox(height: isMobile ? 16 : 20),

                      if (_isLoading)
                        _buildLoading(t)
                      else if (_errorMessage != null)
                        _buildError(t)
                      else if (_filteredAdmins.isEmpty)
                        _buildEmptyState(t)
                      else if (isMobile)
                        _buildMobileList(t)
                      else
                        _buildDesktopTable(t),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(bool isMobile, AdminTheme t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kelola Admin',
          style: TextStyle(
            fontSize: isMobile ? 22 : 26,
            fontWeight: FontWeight.w700,
            color: t.cellText,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kelola akun dan akses administrator platform.',
          style: TextStyle(
            fontSize: isMobile ? 12.5 : 13,
            color: t.mutedText,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SEARCH + ACTION
  // ============================================================

  Widget _buildSearchAndAction(bool isMobile, AdminTheme t) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchBox(t),
          const SizedBox(height: 10),
          _buildAddButton(t),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _buildSearchBox(t)),
        const SizedBox(width: 14),
        _buildAddButton(t),
      ],
    );
  }

  Widget _buildSearchBox(AdminTheme t) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.border),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(fontSize: 13.5, color: t.cellText),
        decoration: InputDecoration(
          hintText: 'Cari nama, email, atau nomor telepon...',
          hintStyle: const TextStyle(
            color: AppColors.grey400,
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: t.headerText,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(AdminTheme t) {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: () => _showAddAdminDialog(t),
        icon: const Icon(Icons.person_add_alt_1, size: 17),
        label: const Text(
          'Tambah Admin',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: t.accent,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading(AdminTheme t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(color: t.accent),
          const SizedBox(height: 16),
          Text(
            'Mengambil data admin...',
            style: TextStyle(color: t.mutedText, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError(AdminTheme t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: t.danger.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 42,
            color: t.danger,
          ),
          const SizedBox(height: 12),
          Text(
            'Gagal mengambil data admin',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: t.danger,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: t.danger,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _loadAdmins,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: t.accent,
              foregroundColor: AppColors.white,
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
  // EMPTY
  // ============================================================

  Widget _buildEmptyState(AdminTheme t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: t.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off,
              size: 34,
              color: t.accent.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Admin tidak ditemukan',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: t.cellText,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WEB — TABEL
  // ============================================================

  Widget _buildDesktopTable(AdminTheme t) {
    final admins = _filteredAdmins;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTableHeaderRow(t),
          Divider(height: 1, thickness: 1, color: t.divider),

          for (int i = 0; i < admins.length; i++) ...[
            _buildTableDataRow(admins[i], t),
            if (i != admins.length - 1)
              Divider(height: 1, thickness: 1, color: t.divider),
          ],
        ],
      ),
    );
  }

  Widget _buildTableHeaderRow(AdminTheme t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(flex: 3, child: _headerCell('Admin', t)),
          Expanded(flex: 3, child: _headerCell('Kontak', t)),
          Expanded(flex: 2, child: _headerCell('Status', t)),
          Expanded(flex: 3, child: _headerCell('Login Terakhir', t)),
          Expanded(flex: 2, child: _headerCell('Aksi', t)),
        ],
      ),
    );
  }

  Widget _headerCell(String text, AdminTheme t) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: t.headerText,
      ),
    );
  }

  Widget _buildTableDataRow(Map<String, dynamic> admin, AdminTheme t) {
    final name = (admin['name'] ?? '-').toString();
    final email = (admin['email'] ?? '-').toString();
    final phone = (admin['phone'] ?? '-').toString();
    final status = _getStatus(admin);
    final lastLogin = _formatDate(admin['last_login_at']);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _buildAvatar(name, t),
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
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: t.cellText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.grey400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

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
                  style: TextStyle(
                    fontSize: 12.5,
                    color: t.cellText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.grey400,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusBadge(status, t),
            ),
          ),

          Expanded(
            flex: 3,
            child: Text(
              lastLogin,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: t.mutedText,
                height: 1.3,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Row(
              children: [
                _iconButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Edit',
                  color: t.cellText,
                  onTap: () => _showEditAdminDialog(admin, t),
                ),
                const SizedBox(width: 4),
                _iconButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Hapus',
                  color: t.danger,
                  onTap: () => _deleteAdmin(admin, t),
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
      color: AppColors.transparent,
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

  Widget _buildMobileList(AdminTheme t) {
    final admins = _filteredAdmins;

    return Column(
      children: admins.asMap().entries.map((entry) {
        final index = entry.key;
        final admin = entry.value;

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == admins.length - 1 ? 0 : 12,
          ),
          child: _buildMobileCard(admin, t),
        );
      }).toList(),
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> admin, AdminTheme t) {
    final name = (admin['name'] ?? '-').toString();
    final email = (admin['email'] ?? '-').toString();
    final phone = (admin['phone'] ?? '-').toString();
    final status = _getStatus(admin);
    final lastLogin = _formatDate(admin['last_login_at']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(name, t),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: t.cellText,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.grey400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(status, t),
            ],
          ),

          const SizedBox(height: 14),
          Divider(height: 1, color: t.divider),
          const SizedBox(height: 12),

          _mobileInfo(Icons.email_outlined, email, t),
          const SizedBox(height: 8),
          _mobileInfo(Icons.phone_outlined, phone, t),
          const SizedBox(height: 8),
          _mobileInfo(Icons.access_time_outlined, lastLogin, t),

          const SizedBox(height: 14),
          Divider(height: 1, color: t.divider),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditAdminDialog(admin, t),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text(
                    'Edit',
                    style: TextStyle(fontSize: 12.5),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: t.cellText,
                    side: BorderSide(color: t.border),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteAdmin(admin, t),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text(
                    'Hapus',
                    style: TextStyle(fontSize: 12.5),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: t.danger,
                    side: BorderSide(
                      color: t.danger.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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

  Widget _mobileInfo(IconData icon, String text, AdminTheme t) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.grey400),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              color: t.mutedText,
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

  Widget _buildAvatar(String name, AdminTheme t) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: t.accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: t.accent,
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

  Widget _buildStatusBadge(String status, AdminTheme t) {
    final active = status == 'Aktif';
    // Semua role pakai TEAL, nonaktif pakai abu
    final color = active ? t.accent : AppColors.grey400;
    final bgColor = active
        ? t.accent.withValues(alpha: 0.12)
        : AppColors.grey100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: active ? t.accent : t.mutedText,
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
  // TAMBAH ADMIN
  // ============================================================

  void _showAddAdminDialog(AdminTheme t) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;

        return AdminThemeProvider(
          theme: t,
          child: StatefulBuilder(
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
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: t.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.person_add_alt_1,
                                color: t.accent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Tambah Admin',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: t.cellText,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              icon: Icon(
                                Icons.close,
                                size: 20,
                                color: t.headerText,
                              ),
                              splashRadius: 22,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        Divider(height: 1, color: t.divider),
                        const SizedBox(height: 16),

                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _dialogField(
                                  t: t,
                                  controller: nameController,
                                  label: 'Nama',
                                  icon: Icons.person_outline,
                                  enabled: !isSubmitting,
                                ),
                                const SizedBox(height: 12),
                                _dialogField(
                                  t: t,
                                  controller: emailController,
                                  label: 'Email',
                                  icon: Icons.email_outlined,
                                  keyboardType:
                                      TextInputType.emailAddress,
                                  enabled: !isSubmitting,
                                ),
                                const SizedBox(height: 12),
                                _dialogField(
                                  t: t,
                                  controller: phoneController,
                                  label: 'Nomor Telepon',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter
                                        .digitsOnly,
                                  ],
                                  enabled: !isSubmitting,
                                ),
                                const SizedBox(height: 12),
                                _dialogField(
                                  t: t,
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
                                  foregroundColor: AppColors.grey700,
                                  side: const BorderSide(
                                    color: AppColors.grey300,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
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
                                        final name = nameController.text
                                            .trim();
                                        final email = emailController
                                            .text
                                            .trim();
                                        final phone = phoneController
                                            .text
                                            .trim();
                                        final password =
                                            passwordController.text;

                                        if (name.isEmpty ||
                                            email.isEmpty ||
                                            password.isEmpty) {
                                          _showMessage(
                                            'Nama, email, dan password wajib diisi.',
                                            isError: true,
                                            t: t,
                                          );
                                          return;
                                        }

                                        if (phone.isNotEmpty &&
                                            !RegExp(r'^[0-9]+$')
                                                .hasMatch(phone)) {
                                          _showMessage(
                                            'Nomor telepon hanya boleh berisi angka.',
                                            isError: true,
                                            t: t,
                                          );
                                          return;
                                        }

                                        if (password.length < 6) {
                                          _showMessage(
                                            'Password minimal 6 karakter.',
                                            isError: true,
                                            t: t,
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

                                          if (response.statusCode ==
                                              201) {
                                            if (dialogContext.mounted) {
                                              Navigator.pop(
                                                dialogContext,
                                              );
                                            }

                                            _showMessage(
                                              'Admin berhasil ditambahkan.',
                                              t: t,
                                            );

                                            await _loadAdmins();
                                          } else {
                                            String message =
                                                'Gagal menambahkan admin.';

                                            try {
                                              final body = jsonDecode(
                                                response.body,
                                              );
                                              message = body['message']
                                                      ?.toString() ??
                                                  message;
                                            } catch (_) {}

                                            if (dialogContext.mounted) {
                                              setDialogState(
                                                () => isSubmitting =
                                                    false,
                                              );
                                            }

                                            _showMessage(
                                              message,
                                              isError: true,
                                              t: t,
                                            );
                                          }
                                        } catch (e) {
                                          if (dialogContext.mounted) {
                                            setDialogState(
                                              () => isSubmitting =
                                                  false,
                                            );
                                          }

                                          _showMessage(
                                            'Terjadi kesalahan: $e',
                                            isError: true,
                                            t: t,
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: t.accent,
                                  foregroundColor: AppColors.white,
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
                                          color: AppColors.white,
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
          ),
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

  void _showEditAdminDialog(
    Map<String, dynamic> admin,
    AdminTheme t,
  ) {
    final id = admin['id'];

    if (id == null) {
      _showMessage('ID admin tidak ditemukan.', isError: true, t: t);
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

        return AdminThemeProvider(
          theme: t,
          child: StatefulBuilder(
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
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: t.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.edit_outlined,
                                color: t.accent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Edit Admin',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: t.cellText,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              icon: Icon(
                                Icons.close,
                                size: 20,
                                color: t.headerText,
                              ),
                              splashRadius: 22,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        Divider(height: 1, color: t.divider),
                        const SizedBox(height: 16),

                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _dialogField(
                                  t: t,
                                  controller: nameController,
                                  label: 'Nama',
                                  icon: Icons.person_outline,
                                  enabled: !isSubmitting,
                                ),
                                const SizedBox(height: 12),
                                _dialogField(
                                  t: t,
                                  controller: emailController,
                                  label: 'Email',
                                  icon: Icons.email_outlined,
                                  keyboardType:
                                      TextInputType.emailAddress,
                                  enabled: !isSubmitting,
                                ),
                                const SizedBox(height: 12),
                                _dialogField(
                                  t: t,
                                  controller: phoneController,
                                  label: 'Nomor Telepon',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter
                                        .digitsOnly,
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
                                    color: AppColors.grey50,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    border: Border.all(color: t.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.toggle_on_outlined,
                                        size: 20,
                                        color: t.headerText,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Status Aktif',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: t.cellText,
                                          ),
                                        ),
                                      ),
                                      Switch(
                                        value: isActive,
                                        activeThumbColor: t.accent,
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
                                  foregroundColor: AppColors.grey700,
                                  side: const BorderSide(
                                    color: AppColors.grey300,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
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
                                        final name = nameController.text
                                            .trim();
                                        final email = emailController
                                            .text
                                            .trim();
                                        final phone = phoneController
                                            .text
                                            .trim();

                                        if (name.isEmpty ||
                                            email.isEmpty) {
                                          _showMessage(
                                            'Nama dan email wajib diisi.',
                                            isError: true,
                                            t: t,
                                          );
                                          return;
                                        }

                                        if (phone.isNotEmpty &&
                                            !RegExp(r'^[0-9]+$')
                                                .hasMatch(phone)) {
                                          _showMessage(
                                            'Nomor telepon hanya boleh berisi angka.',
                                            isError: true,
                                            t: t,
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

                                          if (response.statusCode ==
                                              200) {
                                            if (dialogContext.mounted) {
                                              Navigator.pop(
                                                dialogContext,
                                              );
                                            }

                                            _showMessage(
                                              'Data admin berhasil diperbarui.',
                                              t: t,
                                            );

                                            await _loadAdmins();
                                            return;
                                          }

                                          String message =
                                              'Gagal memperbarui admin.';
                                          try {
                                            final body = jsonDecode(
                                              response.body,
                                            );
                                            message = body['message']
                                                    ?.toString() ??
                                                message;
                                          } catch (_) {}

                                          if (dialogContext.mounted) {
                                            setDialogState(
                                              () => isSubmitting =
                                                  false,
                                            );
                                          }

                                          _showMessage(
                                            message,
                                            isError: true,
                                            t: t,
                                          );
                                        } catch (e) {
                                          if (dialogContext.mounted) {
                                            setDialogState(
                                              () => isSubmitting =
                                                  false,
                                            );
                                          }

                                          _showMessage(
                                            'Terjadi kesalahan: $e',
                                            isError: true,
                                            t: t,
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: t.accent,
                                  foregroundColor: AppColors.white,
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
                                          color: AppColors.white,
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
          ),
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

  void _deleteAdmin(Map<String, dynamic> admin, AdminTheme t) {
    final id = admin['id'];

    if (id == null) {
      _showMessage('ID admin tidak ditemukan.', isError: true, t: t);
      return;
    }

    final name = (admin['name'] ?? '-').toString();

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isDeleting = false;

        return AdminThemeProvider(
          theme: t,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: t.danger,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Hapus Admin',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: t.cellText,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'Apakah kamu yakin ingin menghapus admin "$name"?\n\n'
                  'Tindakan ini tidak dapat dibatalkan.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: t.mutedText,
                  ),
                ),
                actionsPadding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                actions: [
                  TextButton(
                    onPressed: isDeleting
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text(
                      'Batal',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: isDeleting
                        ? null
                        : () async {
                            setDialogState(() => isDeleting = true);

                            try {
                              final response = await ApiService.delete(
                                '/superadmin/admins/$id',
                              );

                              if (response.statusCode == 200) {
                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                }

                                _showMessage(
                                  'Admin berhasil dihapus.',
                                  t: t,
                                );
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
                                    () => isDeleting = false,
                                  );
                                }

                                _showMessage(
                                  message,
                                  isError: true,
                                  t: t,
                                );
                              }
                            } catch (e) {
                              if (dialogContext.mounted) {
                                setDialogState(
                                  () => isDeleting = false,
                                );
                              }

                              _showMessage(
                                'Terjadi kesalahan: $e',
                                isError: true,
                                t: t,
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: t.danger,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Text(
                            'Hapus',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
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

  // ============================================================
  // DIALOG FIELD
  // ============================================================

  Widget _dialogField({
    required AdminTheme t,
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
        fillColor: AppColors.grey50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
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
          borderSide: BorderSide(color: t.accent, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: t.border),
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
    required AdminTheme t,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? t.danger : t.accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}