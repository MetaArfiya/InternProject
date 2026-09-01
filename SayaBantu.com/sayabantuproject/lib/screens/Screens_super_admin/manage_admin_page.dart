import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class ManageAdminPage extends StatefulWidget {
  const ManageAdminPage({super.key});

  @override
  State<ManageAdminPage> createState() => _ManageAdminPageState();
}

class _ManageAdminPageState extends State<ManageAdminPage> {
  final TextEditingController _searchController =
      TextEditingController();

  List<Map<String, dynamic>> _admins = [];

  String _searchQuery = '';

  bool _isLoading = true;

  String? _errorMessage;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      if (!mounted) return;

      setState(() {
        _searchQuery =
            _searchController.text.trim().toLowerCase();
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
      final response =
          await ApiService.get('/superadmin/admins');

      debugPrint(
        '📥 DATA ADMIN RESPONSE: ${response.body}',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body['success'] == true) {
          final data = body['data'];

          if (data is List) {
            setState(() {
              _admins = data
                  .map<Map<String, dynamic>>(
                    (item) =>
                        Map<String, dynamic>.from(item),
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
                body['message'] ??
                'Gagal mengambil data admin.';
            _isLoading = false;
          });
        }
      } else {
        String message =
            'Gagal mengambil data admin.';

        try {
          final body = jsonDecode(response.body);

          if (body['message'] != null) {
            message =
                body['message'].toString();
          }
        } catch (_) {}

        setState(() {
          _errorMessage =
              '$message\nStatus: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(
        '❌ ERROR LOAD ADMIN: $e',
      );

      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Tidak dapat terhubung ke server.\n$e';
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<Map<String, dynamic>> get _filteredAdmins {
    if (_searchQuery.isEmpty) {
      return _admins;
    }

    return _admins.where((admin) {
      final name =
          (admin['name'] ?? '')
              .toString()
              .toLowerCase();

      final email =
          (admin['email'] ?? '')
              .toString()
              .toLowerCase();

      final phone =
          (admin['phone'] ?? '')
              .toString()
              .toLowerCase();

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

        final isMobile = width < 700;
        final isTablet =
            width >= 700 && width < 1100;

        final horizontalPadding =
            isMobile ? 16.0 : 28.0;

        final verticalPadding =
            isMobile ? 16.0 : 28.0;

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFFF3F7FB),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              verticalPadding,
              horizontalPadding,
              28,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildHeader(isMobile),

                const SizedBox(height: 24),

                _buildSearchAndAction(
                  isMobile: isMobile,
                  isTablet: isTablet,
                ),

                const SizedBox(height: 20),

                if (_isLoading)
                  _buildLoading()
                else if (_errorMessage != null)
                  _buildError()
                else if (isMobile)
                  _buildMobileList()
                else
                  _buildDesktopTable(),

                const SizedBox(height: 20),
              ],
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
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'Kelola Admin',
          style: TextStyle(
            fontSize: isMobile ? 24 : 30,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kelola akun dan akses administrator platform.',
          style: TextStyle(
            fontSize: isMobile ? 13 : 15,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SEARCH + ACTION
  // ============================================================

  Widget _buildSearchAndAction({
    required bool isMobile,
    required bool isTablet,
  }) {
    if (isMobile) {
      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          _buildSearchBox(),

          const SizedBox(height: 12),

          _buildAddButton(),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildSearchBox(),
        ),

        const SizedBox(width: 16),

        _buildAddButton(),
      ],
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchBox() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFDCE4ED),
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF334155),
        ),
        decoration:
            const InputDecoration(
          hintText:
              'Cari nama, email, atau nomor telepon...',
          hintStyle: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Color(0xFF475569),
            size: 21,
          ),
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ADD BUTTON
  // ============================================================

  Widget _buildAddButton() {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: _showAddAdminDialog,
        icon: const Icon(
          Icons.person_add_alt_1,
          size: 18,
        ),
        label: const Text(
          'Tambah Admin',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 18,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(9),
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
      padding:
          const EdgeInsets.symmetric(
        vertical: 70,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFDCE4ED),
        ),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(),

          SizedBox(height: 16),

          Text(
            'Mengambil data admin...',
            style: TextStyle(
              color: Color(0xFF64748B),
            ),
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
      padding:
          const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFECACA),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 42,
            color: Colors.red,
          ),

          const SizedBox(height: 12),

          const Text(
            'Gagal mengambil data admin',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _errorMessage ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 18),

          ElevatedButton.icon(
            onPressed: _loadAdmins,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DESKTOP TABLE
  // ============================================================

  Widget _buildDesktopTable() {
    final admins = _filteredAdmins;

    if (admins.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFDCE4ED),
        ),
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(14),
        child: Column(
          children: [
            _buildTableHeader(),

            ...admins.map(
              (admin) =>
                  _buildTableRow(admin),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TABLE HEADER
  // ============================================================

  Widget _buildTableHeader() {
    return Container(
      height: 56,
      color: const Color(0xFFF8FAFC),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child:
                _tableTitle('ADMIN'),
          ),

          Expanded(
            flex: 2,
            child:
                _tableTitle('KONTAK'),
          ),

          Expanded(
            flex: 1,
            child:
                _tableTitle('STATUS'),
          ),

          Expanded(
            flex: 2,
            child:
                _tableTitle('LOGIN TERAKHIR'),
          ),

          SizedBox(
            width: 110,
            child:
                _tableTitle('AKSI'),
          ),
        ],
      ),
    );
  }

  Widget _tableTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF64748B),
      ),
    );
  }

  // ============================================================
  // TABLE ROW
  // ============================================================

  Widget _buildTableRow(
    Map<String, dynamic> admin,
  ) {
    final name =
        (admin['name'] ?? '-').toString();

    final email =
        (admin['email'] ?? '-').toString();

    final phone =
        (admin['phone'] ?? '-').toString();

    final status =
        _getStatus(admin);

    final lastLogin =
        _formatDate(
          admin['last_login_at'],
        );

    return Container(
      constraints:
          const BoxConstraints(
        minHeight: 86,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 12,
      ),
      decoration:
          const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                _buildAvatar(name),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              Color(0xFF1E293B),
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        'Admin',
                        style:
                            TextStyle(
                          fontSize: 12,
                          color:
                              Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 13,
                    color:
                        Color(0xFF334155),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  phone,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 1,
            child: Align(
              alignment:
                  Alignment.centerLeft,
              child:
                  _buildStatusWidget(status),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              lastLogin,
              style:
                  const TextStyle(
                fontSize: 13,
                color:
                    Color(0xFF475569),
              ),
            ),
          ),

          SizedBox(
            width: 110,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () {
                    _showEditAdminDialog(admin);
                  },
                  icon:
                      const Icon(
                    Icons.edit_outlined,
                    size: 19,
                    color:
                        Color(0xFF475569),
                  ),
                ),

                IconButton(
                  tooltip: 'Hapus',
                  onPressed: () {
                    _deleteAdmin(admin);
                  },
                  icon:
                      const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.red,
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
  // MOBILE
  // ============================================================

  Widget _buildMobileList() {
    final admins =
        _filteredAdmins;

    if (admins.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children:
          admins.map((admin) {
        return Padding(
          padding:
              const EdgeInsets.only(
            bottom: 12,
          ),
          child:
              _buildMobileCard(admin),
        );
      }).toList(),
    );
  }

  Widget _buildMobileCard(
    Map<String, dynamic> admin,
  ) {
    final name =
        (admin['name'] ?? '-').toString();

    final email =
        (admin['email'] ?? '-').toString();

    final phone =
        (admin['phone'] ?? '-').toString();

    final status =
        _getStatus(admin);

    final lastLogin =
        _formatDate(
          admin['last_login_at'],
        );

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFDCE4ED),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(name),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w700,
                        fontSize: 14,
                        color:
                            Color(0xFF1E293B),
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Admin',
                      style:
                          TextStyle(
                        fontSize: 12,
                        color:
                            Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),

              _buildStatusWidget(status),
            ],
          ),

          const SizedBox(height: 16),

          _mobileInfo(
            Icons.email_outlined,
            email,
          ),

          const SizedBox(height: 8),

          _mobileInfo(
            Icons.phone_outlined,
            phone,
          ),

          const SizedBox(height: 8),

          _mobileInfo(
            Icons.access_time_outlined,
            lastLogin,
          ),

          const SizedBox(height: 14),

          const Divider(
            color: Color(0xFFE2E8F0),
          ),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  _showEditAdminDialog(admin);
                },
                icon:
                    const Icon(
                  Icons.edit_outlined,
                  size: 17,
                ),
                label:
                    const Text('Edit'),
              ),

              TextButton.icon(
                onPressed: () {
                  _deleteAdmin(admin);
                },
                icon:
                    const Icon(
                  Icons.delete_outline,
                  size: 17,
                  color: Colors.red,
                ),
                label:
                    const Text(
                  'Hapus',
                  style:
                      TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mobileInfo(
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: const Color(0xFF64748B),
        ),

        const SizedBox(width: 9),

        Expanded(
          child: Text(
            text,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
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
    final initial =
        name.isNotEmpty
            ? name[0].toUpperCase()
            : '?';

    return Container(
      width: 42,
      height: 42,
      decoration:
          const BoxDecoration(
        color: Color(0xFFEEF5FF),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style:
              const TextStyle(
            color: Color(0xFF2563EB),
            fontWeight:
                FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _getStatus(
    Map<String, dynamic> admin,
  ) {
    final value =
        admin['is_active'];

    if (value == true ||
        value == 1 ||
        value == '1' ||
        value == 'true') {
      return 'Aktif';
    }

    return 'Nonaktif';
  }

  Widget _buildStatusWidget(
    String status,
  ) {
    final active =
        status == 'Aktif';

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFF1F5F9),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight:
              FontWeight.w700,
          color: active
              ? const Color(0xFF15803D)
              : const Color(0xFF64748B),
        ),
      ),
    );
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(dynamic value) {
    if (value == null ||
        value.toString().isEmpty) {
      return '-';
    }

    try {
      final date =
          DateTime.parse(
        value.toString(),
      ).toLocal();

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];

      final day =
          date.day.toString().padLeft(2, '0');

      final month =
          months[date.month - 1];

      final year =
          date.year.toString();

      final hour =
          date.hour.toString().padLeft(
                2,
                '0',
              );

      final minute =
          date.minute.toString().padLeft(
                2,
                '0',
              );

      return '$day $month $year, '
          '$hour:$minute';
    } catch (_) {
      return value.toString();
    }
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 50,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFDCE4ED),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off,
            size: 42,
            color: Color(0xFF94A3B8),
          ),

          SizedBox(height: 12),

          Text(
            'Admin tidak ditemukan',
            style: TextStyle(
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAMBAH ADMIN
  // ============================================================

  void _showAddAdminDialog() {
    final nameController =
        TextEditingController();

    final emailController =
        TextEditingController();

    final phoneController =
        TextEditingController();

    final passwordController =
        TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Tambah Admin',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              content: SizedBox(
                width: 420,
                child:
                    SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      _dialogField(
                        controller:
                            nameController,
                        label: 'Nama',
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      _dialogField(
                        controller:
                            emailController,
                        label: 'Email',
                        keyboardType:
                            TextInputType
                                .emailAddress,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      _dialogField(
                        controller:
                            phoneController,
                        label:
                            'Nomor Telepon',
                        keyboardType:
                            TextInputType.phone,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      _dialogField(
                        controller:
                            passwordController,
                        label: 'Password',
                        obscureText: true,
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed:
                      isSubmitting
                          ? null
                          : () {
                              Navigator.pop(
                                dialogContext,
                              );
                            },
                  child:
                      const Text('Batal'),
                ),

                ElevatedButton(
                  onPressed:
                      isSubmitting
                          ? null
                          : () async {
                              final name =
                                  nameController
                                      .text
                                      .trim();

                              final email =
                                  emailController
                                      .text
                                      .trim();

                              final phone =
                                  phoneController
                                      .text
                                      .trim();

                              final password =
                                  passwordController
                                      .text;

                              if (name.isEmpty ||
                                  email.isEmpty ||
                                  password.isEmpty) {
                                _showMessage(
                                  'Nama, email, dan password wajib diisi.',
                                  isError: true,
                                );
                                return;
                              }

                              if (password.length <
                                  6) {
                                _showMessage(
                                  'Password minimal 6 karakter.',
                                  isError: true,
                                );
                                return;
                              }

                              setDialogState(() {
                                isSubmitting = true;
                              });

                              try {
                                final response =
                                    await ApiService
                                        .post(
                                  '/superadmin/create-admin',
                                  {
                                    'name': name,
                                    'email': email,
                                    'phone': phone,
                                    'password':
                                        password,
                                  },
                                );

                                debugPrint(
                                  '📥 CREATE ADMIN: ${response.body}',
                                );

                                if (response
                                        .statusCode ==
                                    201) {
                                  if (dialogContext
                                      .mounted) {
                                    Navigator.pop(
                                      dialogContext,
                                    );
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
                                        jsonDecode(
                                      response.body,
                                    );

                                    message =
                                        body['message']
                                                ?.toString() ??
                                            message;
                                  } catch (_) {}

                                  if (dialogContext
                                      .mounted) {
                                    setDialogState(() {
                                      isSubmitting =
                                          false;
                                    });
                                  }

                                  _showMessage(
                                    message,
                                    isError: true,
                                  );
                                }
                              } catch (e) {
                                debugPrint(
                                  '❌ CREATE ADMIN ERROR: $e',
                                );

                                if (dialogContext
                                    .mounted) {
                                  setDialogState(() {
                                    isSubmitting =
                                        false;
                                  });
                                }

                                _showMessage(
                                  'Terjadi kesalahan: $e',
                                  isError: true,
                                );
                              }
                            },
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF2563EB,
                    ),
                    foregroundColor:
                        Colors.white,
                  ),
                  child:
                      isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Colors.white,
                              ),
                            )
                          : const Text(
                              'Tambah',
                            ),
                ),
              ],
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

  void _showEditAdminDialog(
    Map<String, dynamic> admin,
  ) {
    final id = admin['id'];

    if (id == null) {
      _showMessage(
        'ID admin tidak ditemukan.',
        isError: true,
      );
      return;
    }

    final nameController =
        TextEditingController(
      text:
          (admin['name'] ?? '').toString(),
    );

    final emailController =
        TextEditingController(
      text:
          (admin['email'] ?? '').toString(),
    );

    final phoneController =
        TextEditingController(
      text:
          (admin['phone'] ?? '').toString(),
    );

    bool isActive =
        admin['is_active'] == true ||
        admin['is_active'] == 1 ||
        admin['is_active'] == '1' ||
        admin['is_active'] == 'true';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        // ======================================================
        // PENTING:
        // Loading hanya milik dialog ini.
        // Tidak menggunakan _isSubmitting dari parent.
        // ======================================================

        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Edit Admin',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    _dialogField(
                      controller:
                          nameController,
                      label: 'Nama',
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _dialogField(
                      controller:
                          emailController,
                      label: 'Email',
                      keyboardType:
                          TextInputType
                              .emailAddress,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _dialogField(
                      controller:
                          phoneController,
                      label:
                          'Nomor Telepon',
                      keyboardType:
                          TextInputType.phone,
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    SwitchListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      title:
                          const Text(
                        'Status Aktif',
                      ),
                      value: isActive,
                      onChanged:
                          isSubmitting
                              ? null
                              : (value) {
                                  setDialogState(
                                    () {
                                      isActive =
                                          value;
                                    },
                                  );
                                },
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed:
                      isSubmitting
                          ? null
                          : () {
                              Navigator.pop(
                                dialogContext,
                              );
                            },
                  child:
                      const Text('Batal'),
                ),

                ElevatedButton(
                  onPressed:
                      isSubmitting
                          ? null
                          : () async {
                              final name =
                                  nameController
                                      .text
                                      .trim();

                              final email =
                                  emailController
                                      .text
                                      .trim();

                              final phone =
                                  phoneController
                                      .text
                                      .trim();

                              if (name.isEmpty ||
                                  email.isEmpty) {
                                _showMessage(
                                  'Nama dan email wajib diisi.',
                                  isError: true,
                                );
                                return;
                              }

                              // =================================
                              // MULAI LOADING
                              // =================================

                              setDialogState(() {
                                isSubmitting = true;
                              });

                              try {
                                final response =
                                    await ApiService
                                        .put(
                                  '/superadmin/admins/$id',
                                  {
                                    'name': name,
                                    'email': email,
                                    'phone': phone,
                                    'is_active':
                                        isActive,
                                  },
                                );

                                debugPrint(
                                  '📥 UPDATE ADMIN: ${response.body}',
                                );

                                // =================================
                                // BERHASIL
                                // =================================

                                if (response
                                        .statusCode ==
                                    200) {
                                  // Tutup dialog terlebih dahulu.
                                  if (dialogContext
                                      .mounted) {
                                    Navigator.pop(
                                      dialogContext,
                                    );
                                  }

                                  _showMessage(
                                    'Data admin berhasil diperbarui.',
                                  );

                                  // Ambil data terbaru dari DB.
                                  await _loadAdmins();

                                  return;
                                }

                                // =================================
                                // GAGAL DARI SERVER
                                // =================================

                                String message =
                                    'Gagal memperbarui admin.';

                                try {
                                  final body =
                                      jsonDecode(
                                    response.body,
                                  );

                                  message =
                                      body['message']
                                              ?.toString() ??
                                          message;
                                } catch (_) {}

                                if (dialogContext
                                    .mounted) {
                                  setDialogState(() {
                                    isSubmitting =
                                        false;
                                  });
                                }

                                _showMessage(
                                  message,
                                  isError: true,
                                );
                              } catch (e) {
                                // =================================
                                // ERROR REQUEST
                                // =================================

                                debugPrint(
                                  '❌ UPDATE ADMIN ERROR: $e',
                                );

                                if (dialogContext
                                    .mounted) {
                                  setDialogState(() {
                                    isSubmitting =
                                        false;
                                  });
                                }

                                _showMessage(
                                  'Terjadi kesalahan: $e',
                                  isError: true,
                                );
                              }
                            },
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF2563EB,
                    ),
                    foregroundColor:
                        Colors.white,
                  ),
                  child:
                      isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Colors.white,
                              ),
                            )
                          : const Text(
                              'Simpan',
                            ),
                ),
              ],
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

  void _deleteAdmin(
    Map<String, dynamic> admin,
  ) {
    final id = admin['id'];

    if (id == null) {
      _showMessage(
        'ID admin tidak ditemukan.',
        isError: true,
      );
      return;
    }

    final name =
        (admin['name'] ?? '-').toString();

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isDeleting = false;

        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Hapus Admin',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              content: Text(
                'Apakah kamu yakin ingin menghapus admin $name?',
              ),

              actions: [
                TextButton(
                  onPressed:
                      isDeleting
                          ? null
                          : () {
                              Navigator.pop(
                                dialogContext,
                              );
                            },
                  child:
                      const Text('Batal'),
                ),

                ElevatedButton(
                  onPressed:
                      isDeleting
                          ? null
                          : () async {
                              setDialogState(() {
                                isDeleting = true;
                              });

                              try {
                                final response =
                                    await ApiService
                                        .delete(
                                  '/superadmin/admins/$id',
                                );

                                debugPrint(
                                  '📥 DELETE ADMIN: ${response.body}',
                                );

                                if (response
                                        .statusCode ==
                                    200) {
                                  if (dialogContext
                                      .mounted) {
                                    Navigator.pop(
                                      dialogContext,
                                    );
                                  }

                                  _showMessage(
                                    'Admin berhasil dihapus.',
                                  );

                                  await _loadAdmins();
                                } else {
                                  String message =
                                      'Gagal menghapus admin.';

                                  try {
                                    final body =
                                        jsonDecode(
                                      response.body,
                                    );

                                    message =
                                        body['message']
                                                ?.toString() ??
                                            message;
                                  } catch (_) {}

                                  if (dialogContext
                                      .mounted) {
                                    setDialogState(() {
                                      isDeleting =
                                          false;
                                    });
                                  }

                                  _showMessage(
                                    message,
                                    isError: true,
                                  );
                                }
                              } catch (e) {
                                debugPrint(
                                  '❌ DELETE ADMIN ERROR: $e',
                                );

                                if (dialogContext
                                    .mounted) {
                                  setDialogState(() {
                                    isDeleting =
                                        false;
                                  });
                                }

                                _showMessage(
                                  'Terjadi kesalahan: $e',
                                  isError: true,
                                );
                              }
                            },
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.red,
                    foregroundColor:
                        Colors.white,
                  ),
                  child:
                      isDeleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Colors.white,
                              ),
                            )
                          : const Text(
                              'Hapus',
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
    required TextEditingController
        controller,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration:
          InputDecoration(
        labelText: label,
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(8),
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
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(message),
        backgroundColor:
            isError
                ? Colors.red
                : const Color(0xFF16A34A),
      ),
    );
  }
}