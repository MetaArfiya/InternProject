import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/admin_theme_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/indonesia_time.dart';

class ManageAdminPage extends StatefulWidget {
  const ManageAdminPage({super.key});

  @override
  State<ManageAdminPage> createState() => _ManageAdminPageState();
}

class _ManageAdminPageState extends State<ManageAdminPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _cities = [];

  int? _selectedCityId;
  bool _isLoadingCities = false;
  String? _cityErrorMessage;

  String _searchQuery = '';
  int _currentPage = 1;
  int _rowsPerPage = 10;
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
  // VALIDATION RULES
  // ============================================================

  static const int _nameMin = 3;
  static const int _nameMax = 100;
  static const int _emailMax = 100;
  static const int _phoneMin = 10;
  static const int _phoneMax = 15;
  static const int _passwordMin = 6;
  static const int _passwordMax = 100;

  static final RegExp _nameRegex = RegExp(r"^[a-zA-Z\s.,'-]+$");

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // ============================================================
  // FORMATTERS
  // ============================================================

  static final List<TextInputFormatter> _nameFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s.,'-]")),
  ];

  static final List<TextInputFormatter> _phoneFormatters = [
    FilteringTextInputFormatter.digitsOnly,
  ];

  static final List<TextInputFormatter> _emailFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z0-9@._%+-]")),
  ];

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
        _currentPage = 1;
      });
    });

    _loadAdmins();
    _loadCities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // VALIDATORS
  // ============================================================

  String? _validateName(String? value) {
    final v = (value ?? '').trim();

    if (v.isEmpty) return 'Nama wajib diisi.';
    if (v.length < _nameMin) {
      return 'Nama minimal $_nameMin karakter.';
    }
    if (v.length > _nameMax) {
      return 'Nama maksimal $_nameMax karakter.';
    }
    if (!_nameRegex.hasMatch(v)) {
      return "Nama hanya boleh huruf dan simbol . , ' -";
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final v = (value ?? '').trim();

    if (v.isEmpty) return 'Email wajib diisi.';
    if (v.length > _emailMax) {
      return 'Email maksimal $_emailMax karakter.';
    }
    if (v.contains(' ')) {
      return 'Email tidak boleh mengandung spasi.';
    }
    if (!_emailRegex.hasMatch(v)) {
      return 'Format email tidak valid (contoh: user@domain.com).';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final v = (value ?? '').trim();

    if (v.isEmpty) return null;

    if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
      return 'Nomor telepon hanya boleh berisi angka.';
    }
    if (v.length < _phoneMin) {
      return 'Nomor telepon minimal $_phoneMin digit.';
    }
    if (v.length > _phoneMax) {
      return 'Nomor telepon maksimal $_phoneMax digit.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';

    if (v.isEmpty) return 'Password wajib diisi.';
    if (v.length < _passwordMin) {
      return 'Password minimal $_passwordMin karakter.';
    }
    if (v.length > _passwordMax) {
      return 'Password maksimal $_passwordMax karakter.';
    }

    return null;
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
              final totalPages = _admins.isEmpty
                  ? 1
                  : (_admins.length / _rowsPerPage).ceil();
              _currentPage = _currentPage.clamp(1, totalPages).toInt();
              _isLoading = false;
            });
          } else {
            setState(() {
              _admins = [];
              _currentPage = 1;
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _errorMessage = body['message'] ?? 'Gagal mengambil data admin.';
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
  // LOAD CITIES
  // ============================================================

  Future<void> _loadCities() async {
    if (!mounted) return;

    setState(() {
      _isLoadingCities = true;
      _cityErrorMessage = null;
    });

    try {
      final response = await ApiService.get('/cities');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body['success'] == true && body['data'] is List) {
          final cities = (body['data'] as List)
              .map<Map<String, dynamic>>(
                (item) => Map<String, dynamic>.from(item),
              )
              .toList();

          setState(() {
            _cities = cities;
            _isLoadingCities = false;
            _cityErrorMessage = cities.isEmpty
                ? 'Belum ada data kota tersedia.'
                : null;
          });
        } else {
          setState(() {
            _cities = [];
            _isLoadingCities = false;
            _cityErrorMessage =
                body['message']?.toString() ?? 'Format data kota tidak valid.';
          });
        }
      } else {
        String message = 'Gagal mengambil daftar kota.';

        try {
          final body = jsonDecode(response.body);
          message = body['message']?.toString() ?? message;
        } catch (_) {}

        setState(() {
          _cities = [];
          _isLoadingCities = false;
          _cityErrorMessage = message;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cities = [];
        _isLoadingCities = false;
        _cityErrorMessage = 'Tidak dapat mengambil data kota.';
      });

      debugPrint('Error load cities: $e');
    }
  }

  // ============================================================
  // CITY PICKER
  // ============================================================

  Future<int?> _showCityPicker(AdminTheme t) async {
    final searchController = TextEditingController();
    List<Map<String, dynamic>> filteredCities = List.from(_cities);

    final result = await showDialog<int>(
      context: context,
      builder: (pickerContext) {
        return StatefulBuilder(
          builder: (context, setPickerState) {
            void filterCities(String query) {
              final keyword = query.trim().toLowerCase();

              setPickerState(() {
                filteredCities = _cities.where((city) {
                  final name = (city['name'] ?? '').toString().toLowerCase();
                  return name.contains(keyword);
                }).toList();
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Pilih Wilayah Kota',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      onChanged: filterCities,
                      decoration: InputDecoration(
                        hintText: 'Cari nama kota/kabupaten...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: filteredCities.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text('Kota tidak ditemukan.'),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredCities.length,
                              itemBuilder: (context, index) {
                                final city = filteredCities[index];
                                final id = int.tryParse(city['id'].toString());

                                if (id == null) {
                                  return const SizedBox.shrink();
                                }

                                return ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    Icons.location_city_outlined,
                                  ),
                                  title: Text(city['name'].toString()),
                                  onTap: () {
                                    Navigator.pop(pickerContext, id);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () async {
                    final cityName = await _showAddCityPrompt(t);

                    if (cityName == null || cityName.trim().isEmpty) {
                      return;
                    }

                    try {
                      final response = await ApiService.post('/cities', {
                        'name': cityName.trim(),
                      });

                      final body = jsonDecode(response.body);

                      if (response.statusCode == 201 &&
                          body['success'] == true) {
                        final city = Map<String, dynamic>.from(body['data']);
                        final newId = int.tryParse(city['id'].toString());

                        if (newId == null) {
                          _showMessage(
                            'Kota tersimpan, tetapi ID tidak valid.',
                            isError: true,
                            t: t,
                          );
                          return;
                        }

                        if (mounted) {
                          setState(() {
                            _cities.add(city);
                            _cities.sort(
                              (a, b) => a['name'].toString().compareTo(
                                b['name'].toString(),
                              ),
                            );
                            _cityErrorMessage = null;
                          });
                        }

                        if (pickerContext.mounted) {
                          Navigator.pop(pickerContext, newId);
                        }

                        _showMessage(
                          'Kota ${city['name']} berhasil ditambahkan.',
                          t: t,
                        );
                        return;
                      }

                      final message =
                          body['message']?.toString() ??
                          'Gagal menambahkan kota.';

                      // Jika nama sudah ada, muat ulang dan pilih kota tersebut.
                      if (response.statusCode == 422) {
                        await _loadCities();

                        final existingCity = _cities.firstWhere(
                          (city) =>
                              city['name'].toString().trim().toLowerCase() ==
                              cityName.trim().toLowerCase(),
                          orElse: () => <String, dynamic>{},
                        );

                        final existingId = int.tryParse(
                          existingCity['id']?.toString() ?? '',
                        );

                        if (existingId != null && pickerContext.mounted) {
                          Navigator.pop(pickerContext, existingId);
                          _showMessage(
                            'Kota sudah tersedia. Kota tersebut dipilih.',
                            t: t,
                          );
                          return;
                        }
                      }

                      _showMessage(message, isError: true, t: t);
                    } catch (e) {
                      _showMessage(
                        'Gagal menambahkan kota: $e',
                        isError: true,
                        t: t,
                      );
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah kota baru'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(pickerContext),
                  child: const Text('Tutup'),
                ),
              ],
            );
          },
        );
      },
    );

    searchController.dispose();
    return result;
  }

  // ============================================================
  // ADD CITY PROMPT
  // ============================================================

  Future<String?> _showAddCityPrompt(AdminTheme t) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Tambah Kota Baru',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            maxLength: 255,
            decoration: InputDecoration(
              labelText: 'Nama kota/kabupaten',
              hintText: 'Contoh: Nganjuk',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.pop(dialogContext, value.trim());
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isNotEmpty) {
                  Navigator.pop(dialogContext, value);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: t.accent,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
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

      final city = admin['city'];
      final cityName = city is Map
          ? (city['name'] ?? '').toString().toLowerCase()
          : '';

      return name.contains(_searchQuery) ||
          email.contains(_searchQuery) ||
          phone.contains(_searchQuery) ||
          cityName.contains(_searchQuery);
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

        final horizontalPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 28.0);
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
              child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isMobile, t),
                      const SizedBox(height: 16),
                      _buildSearchAndAction(isMobile, t),
                      const SizedBox(height: 16),
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
                    ],
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
          hintStyle: const TextStyle(color: AppColors.grey400, fontSize: 13),
          prefixIcon: Icon(Icons.search, color: t.headerText, size: 20),
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
          Icon(Icons.error_outline, size: 42, color: t.danger),
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
            style: TextStyle(fontSize: 12.5, color: t.danger, height: 1.4),
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
      padding: const EdgeInsets.symmetric(vertical: 48),
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
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: t.mutedText,
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
    final start = (_currentPage - 1) * _rowsPerPage;
    final pageAdmins = admins.skip(start).take(_rowsPerPage).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildTableHeaderRow(t),

          Divider(height: 1, thickness: 1, color: t.divider),

          for (int i = 0; i < pageAdmins.length; i++) ...[
            _buildTableDataRow(pageAdmins[i], t),

            if (i != pageAdmins.length - 1)
              Divider(height: 1, thickness: 1, color: t.divider),
          ],

          Divider(height: 1, thickness: 1, color: t.border),

          _buildAdminPagination(t, admins.length),
        ],
      ),
    );
  }

  Widget _buildAdminPagination(AdminTheme t, int total) {
    final totalPages = total == 0 ? 1 : (total / _rowsPerPage).ceil();

    final start = total == 0 ? 0 : ((_currentPage - 1) * _rowsPerPage) + 1;

    final end = (_currentPage * _rowsPerPage).clamp(0, total);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 550;

          final information = Text(
            total == 0
                ? 'Menampilkan 0 dari 0 admin'
                : 'Menampilkan $start–$end dari $total admin',
            style: TextStyle(fontSize: 12, color: t.headerText),
          );

          final controls = Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              // DROPDOWN JUMLAH DATA
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: t.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _rowsPerPage,
                    isDense: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: t.headerText,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: t.cellText,
                      fontWeight: FontWeight.w500,
                    ),
                    items: [10, 25, 50].map((value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value / hal'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _rowsPerPage = value;
                        _currentPage = 1;
                      });
                    },
                  ),
                ),
              ),

              // HALAMAN SEBELUMNYA
              _adminPaginationButton(
                icon: Icons.chevron_left,
                enabled: _currentPage > 1,
                color: t,
                onTap: () {
                  setState(() {
                    _currentPage--;
                  });
                },
              ),

              // INDIKATOR HALAMAN
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Hal $_currentPage / $totalPages',
                  style: TextStyle(
                    fontSize: 12,
                    color: t.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // HALAMAN SELANJUTNYA
              _adminPaginationButton(
                icon: Icons.chevron_right,
                enabled: _currentPage < totalPages,
                color: t,
                onTap: () {
                  setState(() {
                    _currentPage++;
                  });
                },
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [information, const SizedBox(height: 12), controls],
            );
          }

          return Row(
            children: [
              Expanded(child: information),
              controls,
            ],
          );
        },
      ),
    );
  }

  Widget _adminPaginationButton({
    required IconData icon,
    required bool enabled,
    required AdminTheme color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.border),
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? color.cellText : AppColors.grey300,
          ),
        ),
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
          Expanded(flex: 2, child: _headerCell('Wilayah', t)),
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

    // Ambil nama wilayah dari response API
    String cityName = '-';

    if (admin['city'] is Map) {
      final city = admin['city'] as Map;

      if (city['name'] != null && city['name'].toString().trim().isNotEmpty) {
        cityName = city['name'].toString();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ======================================================
          // ADMIN
          // ======================================================
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _buildAvatar(name, admin['photo_url']?.toString(), t),
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

          // ======================================================
          // KONTAK
          // ======================================================
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
                  style: TextStyle(fontSize: 12.5, color: t.cellText),
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

          // ======================================================
          // WILAYAH
          // ======================================================
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  Icons.location_city_outlined,
                  size: 17,
                  color: t.headerText,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    cityName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: t.cellText,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // STATUS
          // ======================================================
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusBadge(status, t),
            ),
          ),

          // ======================================================
          // LOGIN TERAKHIR
          // ======================================================
          Expanded(
            flex: 3,
            child: Text(
              lastLogin,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: t.mutedText, height: 1.3),
            ),
          ),

          // ======================================================
          // AKSI
          // ======================================================
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
          padding: EdgeInsets.only(bottom: index == admins.length - 1 ? 0 : 12),
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

    // Ambil nama wilayah
    String cityName = '-';

    if (admin['city'] is Map) {
      final city = admin['city'] as Map;

      if (city['name'] != null && city['name'].toString().trim().isNotEmpty) {
        cityName = city['name'].toString();
      }
    }

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
          // ======================================================
          // HEADER CARD
          // ======================================================
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(name, admin['photo_url']?.toString(), t),
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

          // ======================================================
          // EMAIL
          // ======================================================
          _mobileInfo(Icons.email_outlined, email, t),

          const SizedBox(height: 8),

          // ======================================================
          // TELEPON
          // ======================================================
          _mobileInfo(Icons.phone_outlined, phone, t),

          const SizedBox(height: 8),

          // ======================================================
          // WILAYAH
          // ======================================================
          _mobileInfo(Icons.location_city_outlined, cityName, t),

          const SizedBox(height: 8),

          // ======================================================
          // LOGIN TERAKHIR
          // ======================================================
          _mobileInfo(Icons.access_time_outlined, lastLogin, t),

          const SizedBox(height: 14),

          Divider(height: 1, color: t.divider),

          const SizedBox(height: 10),

          // ======================================================
          // ACTION
          // ======================================================
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditAdminDialog(admin, t),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit', style: TextStyle(fontSize: 12.5)),
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
                  label: const Text('Hapus', style: TextStyle(fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: t.danger,
                    side: BorderSide(color: t.danger.withValues(alpha: 0.3)),
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
            style: TextStyle(fontSize: 12.5, color: t.mutedText, height: 1.35),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAvatar(String name, String? photoUrl, AdminTheme t) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: t.accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: ClipOval(
        child: (photoUrl != null && photoUrl.isNotEmpty)
            ? Image.network(
                photoUrl,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: t.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              )
            : Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    color: t.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _getStatus(Map<String, dynamic> admin) {
    final value = admin['is_active'];

    if (value == true || value == 1 || value == '1' || value == 'true') {
      return 'Aktif';
    }

    return 'Nonaktif';
  }

  Widget _buildStatusBadge(String status, AdminTheme t) {
    final active = status == 'Aktif';
    final color = active ? t.accent : AppColors.grey400;
    final bgColor = active
        ? t.accent.withValues(alpha: 0.12)
        : AppColors.grey100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: active ? t.accent : t.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CITY FORM FIELD
  // ============================================================

  Widget _buildCityFormField({
    required AdminTheme t,
    required StateSetter setDialogState,
    required bool isSubmitting,
  }) {
    return FormField<int>(
      validator: (value) {
        if (value == null) {
          return 'Wilayah kota wajib dipilih.';
        }
        return null;
      },
      builder: (field) {
        final selectedCity = _cities.cast<Map<String, dynamic>?>().firstWhere(
          (city) => int.tryParse(city?['id']?.toString() ?? '') == field.value,
          orElse: () => null,
        );

        final selectedName = selectedCity?['name']?.toString();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: isSubmitting || _isLoadingCities
                  ? null
                  : () async {
                      final cityId = await _showCityPicker(t);

                      if (cityId != null) {
                        field.didChange(cityId);
                        setDialogState(() {
                          _selectedCityId = cityId;
                        });
                      }
                    },
              child: InputDecorator(
                isEmpty: selectedName == null,
                decoration: InputDecoration(
                  labelText: '',
                  prefixIcon: const Icon(
                    Icons.location_city_outlined,
                    size: 19,
                  ),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
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
                  errorText: field.errorText,
                ),
                child: Text(
                  _isLoadingCities
                      ? 'Memuat daftar kota...'
                      : selectedName ??
                            (_cityErrorMessage ?? 'Pilih wilayah kota'),
                  style: TextStyle(
                    fontSize: 13,
                    color: selectedName == null
                        ? AppColors.grey400
                        : t.cellText,
                  ),
                ),
              ),
            ),
            if (_cityErrorMessage != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: isSubmitting || _isLoadingCities
                      ? null
                      : () async {
                          await _loadCities();
                          setDialogState(() {});
                        },
                  icon: const Icon(Icons.refresh, size: 15),
                  label: const Text(
                    'Muat ulang daftar kota',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return '-';

    try {
      final parsed = IndonesiaTime.tryParseApiTimestamp(value);
      if (parsed == null) return '-';
      final date = IndonesiaTime.toWall(parsed);

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
    _selectedCityId = null;

    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();

    bool isSubmitting = false;
    bool obscurePassword = true;

    AutovalidateMode autovalidateMode = AutovalidateMode.disabled;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
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
                            child: Form(
                              key: formKey,
                              autovalidateMode: autovalidateMode,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _dialogField(
                                    t: t,
                                    controller: nameController,
                                    label: 'Nama',
                                    hint: 'Contoh: Budi Santoso',
                                    helper:
                                        'Min $_nameMin, maks $_nameMax karakter',
                                    icon: Icons.person_outline,
                                    enabled: !isSubmitting,
                                    maxLength: _nameMax,
                                    inputFormatters: _nameFormatters,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    validator: _validateName,
                                  ),
                                  const SizedBox(height: 12),
                                  _dialogField(
                                    t: t,
                                    controller: emailController,
                                    label: 'Email',
                                    hint: 'Contoh: budi@sayabantu.com',
                                    helper:
                                        'Maks $_emailMax karakter, format email valid',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    enabled: !isSubmitting,
                                    maxLength: _emailMax,
                                    inputFormatters: _emailFormatters,
                                    validator: _validateEmail,
                                  ),
                                  const SizedBox(height: 12),
                                  _dialogField(
                                    t: t,
                                    controller: phoneController,
                                    label: 'Nomor Telepon',
                                    hint: 'Contoh: 081234567890',
                                    helper:
                                        'Opsional — $_phoneMin-$_phoneMax digit, hanya angka',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    enabled: !isSubmitting,
                                    maxLength: _phoneMax,
                                    inputFormatters: _phoneFormatters,
                                    validator: _validatePhone,
                                  ),
                                  const SizedBox(height: 12),
                                  _dialogField(
                                    t: t,
                                    controller: passwordController,
                                    label: 'Password',
                                    hint: 'Min $_passwordMin karakter',
                                    helper:
                                        '$_passwordMin-$_passwordMax karakter',
                                    icon: Icons.lock_outline,
                                    obscureText: obscurePassword,
                                    enabled: !isSubmitting,
                                    maxLength: _passwordMax,
                                    validator: _validatePassword,
                                    suffixIcon: IconButton(
                                      onPressed: isSubmitting
                                          ? null
                                          : () {
                                              setDialogState(() {
                                                obscurePassword =
                                                    !obscurePassword;
                                              });
                                            },
                                      icon: Icon(
                                        obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        size: 20,
                                        color: t.headerText,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // DROPDOWN WILAYAH KOTA
                                  _buildCityFormField(
                                    t: t,
                                    setDialogState: setDialogState,
                                    isSubmitting: isSubmitting,
                                  ),
                                ],
                              ),
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
                                        setDialogState(() {
                                          autovalidateMode = AutovalidateMode
                                              .onUserInteraction;
                                        });

                                        if (!(formKey.currentState
                                                ?.validate() ??
                                            false)) {
                                          return;
                                        }

                                        if (_selectedCityId == null) {
                                          _showMessage(
                                            'Silakan pilih wilayah kota.',
                                            isError: true,
                                            t: t,
                                          );
                                          return;
                                        }

                                        final name = nameController.text.trim();
                                        final email = emailController.text
                                            .trim();
                                        final phone = phoneController.text
                                            .trim();
                                        final password =
                                            passwordController.text;

                                        setDialogState(() {
                                          isSubmitting = true;
                                        });

                                        try {
                                          final response =
                                              await ApiService.post(
                                                '/superadmin/create-admin',
                                                {
                                                  'name': name,
                                                  'email': email,
                                                  'phone': phone,
                                                  'password': password,
                                                  'city_id': _selectedCityId,
                                                },
                                              );

                                          if (response.statusCode == 201) {
                                            if (dialogContext.mounted) {
                                              Navigator.pop(dialogContext);
                                            }

                                            _showMessage(
                                              'Admin berhasil ditambahkan.',
                                              t: t,
                                            );

                                            await _loadAdmins();
                                            return;
                                          }

                                          String message =
                                              'Gagal menambahkan admin.';

                                          try {
                                            final body = jsonDecode(
                                              response.body,
                                            );

                                            if (body['errors'] is Map) {
                                              final errors =
                                                  body['errors'] as Map;

                                              if (errors.isNotEmpty) {
                                                final firstKey =
                                                    errors.keys.first;
                                                final firstErr =
                                                    errors[firstKey];

                                                if (firstErr is List &&
                                                    firstErr.isNotEmpty) {
                                                  message = firstErr[0]
                                                      .toString();
                                                }
                                              }
                                            } else if (body['message'] !=
                                                null) {
                                              message = body['message']
                                                  .toString();
                                            }
                                          } catch (_) {}

                                          if (dialogContext.mounted) {
                                            setDialogState(() {
                                              isSubmitting = false;
                                            });
                                          }

                                          _showMessage(
                                            message,
                                            isError: true,
                                            t: t,
                                          );
                                        } catch (e) {
                                          if (dialogContext.mounted) {
                                            setDialogState(() {
                                              isSubmitting = false;
                                            });
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
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: isSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
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

  void _showEditAdminDialog(Map<String, dynamic> admin, AdminTheme t) {
    final id = admin['id'];

    if (id == null) {
      _showMessage('ID admin tidak ditemukan.', isError: true, t: t);
      return;
    }

    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(
      text: (admin['name'] ?? '').toString(),
    );

    final emailController = TextEditingController(
      text: (admin['email'] ?? '').toString(),
    );

    final phoneController = TextEditingController(
      text: (admin['phone'] ?? '').toString(),
    );

    // Ambil kota admin yang sudah tersimpan.
    int? selectedCityId;

    if (admin['city_id'] != null) {
      selectedCityId = int.tryParse(admin['city_id'].toString());
    } else if (admin['city'] is Map) {
      final city = admin['city'] as Map;
      selectedCityId = int.tryParse(city['id']?.toString() ?? '');
    }

    bool isActive =
        admin['is_active'] == true ||
        admin['is_active'] == 1 ||
        admin['is_active'] == '1' ||
        admin['is_active'] == 'true';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;

        AutovalidateMode autovalidateMode = AutovalidateMode.disabled;

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
                        // HEADER
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

                        // FORM
                        Flexible(
                          child: SingleChildScrollView(
                            child: Form(
                              key: formKey,
                              autovalidateMode: autovalidateMode,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // NAMA
                                  _dialogField(
                                    t: t,
                                    controller: nameController,
                                    label: 'Nama',
                                    hint: 'Contoh: Budi Santoso',
                                    helper:
                                        'Min $_nameMin, maks $_nameMax karakter',
                                    icon: Icons.person_outline,
                                    enabled: !isSubmitting,
                                    maxLength: _nameMax,
                                    inputFormatters: _nameFormatters,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    validator: _validateName,
                                  ),

                                  const SizedBox(height: 12),

                                  // EMAIL
                                  _dialogField(
                                    t: t,
                                    controller: emailController,
                                    label: 'Email',
                                    hint: 'Contoh: budi@sayabantu.com',
                                    helper:
                                        'Maks $_emailMax karakter, format email valid',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    enabled: !isSubmitting,
                                    maxLength: _emailMax,
                                    inputFormatters: _emailFormatters,
                                    validator: _validateEmail,
                                  ),

                                  const SizedBox(height: 12),

                                  // NOMOR TELEPON
                                  _dialogField(
                                    t: t,
                                    controller: phoneController,
                                    label: 'Nomor Telepon',
                                    hint: 'Contoh: 081234567890',
                                    helper:
                                        'Opsional — $_phoneMin-$_phoneMax digit, hanya angka',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    enabled: !isSubmitting,
                                    maxLength: _phoneMax,
                                    inputFormatters: _phoneFormatters,
                                    validator: _validatePhone,
                                  ),

                                  const SizedBox(height: 12),

                                  // WILAYAH KOTA
                                  FormField<int>(
                                    initialValue: selectedCityId,
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Wilayah kota wajib dipilih.';
                                      }
                                      return null;
                                    },
                                    builder: (field) {
                                      Map<String, dynamic>? selectedCity;

                                      for (final city in _cities) {
                                        if (int.tryParse(
                                              city['id'].toString(),
                                            ) ==
                                            field.value) {
                                          selectedCity = city;
                                          break;
                                        }
                                      }

                                      final cityName = selectedCity?['name']
                                          ?.toString();

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Wilayah (Kota)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: t.cellText,
                                            ),
                                          ),
                                          const SizedBox(height: 7),
                                          InkWell(
                                            onTap: isSubmitting
                                                ? null
                                                : () async {
                                                    final result =
                                                        await _showCityPicker(
                                                          t,
                                                        );

                                                    if (result != null) {
                                                      field.didChange(result);

                                                      setDialogState(() {
                                                        selectedCityId = result;
                                                      });
                                                    }
                                                  },
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: InputDecorator(
                                              decoration: InputDecoration(
                                                prefixIcon: Icon(
                                                  Icons.location_city_outlined,
                                                  color: t.headerText,
                                                  size: 20,
                                                ),
                                                suffixIcon: Icon(
                                                  Icons.keyboard_arrow_down,
                                                  color: t.headerText,
                                                ),
                                                filled: true,
                                                fillColor: AppColors.grey50,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 14,
                                                    ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  borderSide: BorderSide(
                                                    color: t.border,
                                                  ),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: t.border,
                                                      ),
                                                    ),
                                                errorText: field.errorText,
                                              ),
                                              child: Text(
                                                cityName ??
                                                    'Pilih wilayah kota',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: cityName != null
                                                      ? t.cellText
                                                      : t.headerText,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 12),

                                  // SWITCH STATUS
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.grey50,
                                      borderRadius: BorderRadius.circular(10),
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
                        ),

                        const SizedBox(height: 20),

                        // TOMBOL
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
                                        setDialogState(() {
                                          autovalidateMode = AutovalidateMode
                                              .onUserInteraction;
                                        });

                                        if (!(formKey.currentState
                                                ?.validate() ??
                                            false)) {
                                          return;
                                        }

                                        final name = nameController.text.trim();
                                        final email = emailController.text
                                            .trim();
                                        final phone = phoneController.text
                                            .trim();

                                        setDialogState(() {
                                          isSubmitting = true;
                                        });

                                        try {
                                          final response = await ApiService.put(
                                            '/superadmin/admins/$id',
                                            {
                                              'name': name,
                                              'email': email,
                                              'phone': phone,
                                              'city_id': selectedCityId,
                                              'is_active': isActive,
                                            },
                                          );

                                          if (response.statusCode == 200) {
                                            if (dialogContext.mounted) {
                                              Navigator.pop(dialogContext);
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

                                            if (body['errors'] is Map) {
                                              final errors =
                                                  body['errors'] as Map;

                                              if (errors.isNotEmpty) {
                                                final firstKey =
                                                    errors.keys.first;
                                                final firstErr =
                                                    errors[firstKey];

                                                if (firstErr is List &&
                                                    firstErr.isNotEmpty) {
                                                  message = firstErr[0]
                                                      .toString();
                                                }
                                              }
                                            } else if (body['message'] !=
                                                null) {
                                              message = body['message']
                                                  .toString();
                                            }
                                          } catch (_) {}

                                          if (dialogContext.mounted) {
                                            setDialogState(() {
                                              isSubmitting = false;
                                            });
                                          }

                                          _showMessage(
                                            message,
                                            isError: true,
                                            t: t,
                                          );
                                        } catch (e) {
                                          if (dialogContext.mounted) {
                                            setDialogState(() {
                                              isSubmitting = false;
                                            });
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
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: isSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
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
      barrierDismissible: false,
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
                    Icon(Icons.delete_outline, color: t.danger),
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
                actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                actions: [
                  TextButton(
                    onPressed: isDeleting
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Batal', style: TextStyle(fontSize: 13)),
                  ),
                  ElevatedButton(
                    onPressed: isDeleting
                        ? null
                        : () async {
                            setDialogState(() {
                              isDeleting = true;
                            });

                            try {
                              final response = await ApiService.delete(
                                '/superadmin/admins/$id',
                              );

                              if (response.statusCode == 200) {
                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                }

                                _showMessage('Admin berhasil dihapus.', t: t);

                                await _loadAdmins();
                              } else {
                                String message = 'Gagal menghapus admin.';

                                try {
                                  final body = jsonDecode(response.body);
                                  message =
                                      body['message']?.toString() ?? message;
                                } catch (_) {}

                                if (dialogContext.mounted) {
                                  setDialogState(() {
                                    isDeleting = false;
                                  });
                                }

                                _showMessage(message, isError: true, t: t);
                              }
                            } catch (e) {
                              if (dialogContext.mounted) {
                                setDialogState(() {
                                  isDeleting = false;
                                });
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
    String? hint,
    String? helper,
    IconData? icon,
    bool obscureText = false,
    bool enabled = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLength,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      enabled: enabled,
      maxLength: maxLength,
      validator: validator,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
        prefixIcon: icon != null ? Icon(icon, size: 19) : null,
        suffixIcon: suffixIcon,
        counterText: '',
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: t.danger, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: t.danger, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: t.border),
        ),
        labelStyle: TextStyle(fontSize: 13, color: t.headerText),
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.grey400),
        helperStyle: TextStyle(
          fontSize: 11,
          color: t.headerText.withValues(alpha: 0.8),
          height: 1.3,
        ),
        errorStyle: TextStyle(fontSize: 11, color: t.danger, height: 1.3),
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

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? t.danger : t.accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
