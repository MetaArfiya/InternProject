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
  // DESIGN TOKENS
  // ============================================================

  static const Color _accent = Color(0xFF2563EB);
  static const Color _bg = Color(0xFFF5F7FB);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _headerText = Color(0xFF6B7280);
  static const Color _cellText = Color(0xFF111827);

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
        final isTablet = width >= _mobileBreakpoint && width < _tabletBreakpoint;

        final horizontalPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
        final verticalPadding = isMobile ? 16.0 : 28.0;

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: _bg,
          child: RefreshIndicator(
            onRefresh: _loadAdmins,
            color: _accent,
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
                      _buildHeader(isMobile),
                      SizedBox(height: isMobile ? 18 : 24),
                      _buildSearchAndAction(isMobile),
                      SizedBox(height: isMobile ? 16 : 20),

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

  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kelola Admin',
          style: TextStyle(
            fontSize: isMobile ? 22 : 26,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kelola akun dan akses administrator platform.',
          style: TextStyle(
            fontSize: isMobile ? 12.5 : 13,
            color: const Color(0xFF64748B),
            height: 1.4,
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155)),
        decoration: const InputDecoration(
          hintText: 'Cari nama, email, atau nomor telepon...',
          hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          prefixIcon: Icon(
            Icons.search,
            color: Color(0xFF6B7280),
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
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: _accent),
          SizedBox(height: 16),
          Text(
            'Mengambil data admin...',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ],
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 42,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(height: 12),
          const Text(
            'Gagal mengambil data admin',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF7F1D1D),
              fontSize: 14,
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

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
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
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
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

  Widget _buildDesktopTable() {
    final admins = _filteredAdmins;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTableHeaderRow(),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),

          for (int i = 0; i < admins.length; i++) ...[
            _buildTableDataRow(admins[i]),
            if (i != admins.length - 1)
              const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
          ],
        ],
      ),
    );
  }

  Widget _buildTableHeaderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(flex: 3, child: _headerCell('Admin')),
          Expanded(flex: 3, child: _headerCell('Kontak')),
          Expanded(flex: 2, child: _headerCell('Status')),
          Expanded(flex: 3, child: _headerCell('Login Terakhir')),
          Expanded(flex: 2, child: _headerCell('Aksi')),
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

  Widget _buildTableDataRow(Map<String, dynamic> admin) {
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
                          fontWeight: FontWeight.w600,
                          color: _cellText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 11.5,
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
                    fontSize: 11.5,
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
                color: Color(0xFF475569),
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
                  color: const Color(0xFFDC2626),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
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
                        fontSize: 14,
                        color: Color(0xFF111827),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 11.5,
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
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 12),

          _mobileInfo(Icons.email_outlined, email),
          const SizedBox(height: 8),
          _mobileInfo(Icons.phone_outlined, phone),
          const SizedBox(height: 8),
          _mobileInfo(Icons.access_time_outlined, lastLogin),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
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
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
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
                  onPressed: () => _deleteAdmin(admin),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text(
                    'Hapus',
                    style: TextStyle(fontSize: 12.5),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
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
              color: Color(0xFF475569),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF9CA3AF),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: active
                  ? const Color(0xFF15803D)
                  : const Color(0xFF64748B),
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
                              Icons.person_add_alt_1,
                              color: _accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Tambah Admin',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
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
                                  borderRadius: BorderRadius.circular(10),
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
                                  borderRadius: BorderRadius.circular(10),
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
                              Icons.edit_outlined,
                              color: _accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Edit Admin',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
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
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _borderColor),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.toggle_on_outlined,
                                      size: 20,
                                      color: Color(0xFF6B7280),
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
                                  borderRadius: BorderRadius.circular(10),
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
                                  borderRadius: BorderRadius.circular(10),
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
      builder: (dialogContext) {
        bool isDeleting = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.delete_outline,
                    color: Color(0xFFDC2626),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Hapus Admin',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Apakah kamu yakin ingin menghapus admin "$name"?\n\n'
                'Tindakan ini tidak dapat dibatalkan.',
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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

                              _showMessage('Admin berhasil dihapus.');
                              await _loadAdmins();
                            } else {
                              String message = 'Gagal menghapus admin.';
                              try {
                                final body =
                                    jsonDecode(response.body);
                                message =
                                    body['message']?.toString() ?? message;
                              } catch (_) {}

                              if (dialogContext.mounted) {
                                setDialogState(() => isDeleting = false);
                              }

                              _showMessage(message, isError: true);
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setDialogState(() => isDeleting = false);
                            }

                            _showMessage(
                              'Terjadi kesalahan: $e',
                              isError: true,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
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
                            color: Colors.white,
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
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}