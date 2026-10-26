import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/admin_theme_provider.dart';
import '../../theme/app_colors.dart';

class ActivePartnerPage extends StatefulWidget {
  const ActivePartnerPage({super.key});

  @override
  State<ActivePartnerPage> createState() => _ActivePartnerPageState();
}

class _ActivePartnerPageState extends State<ActivePartnerPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _partners = [];

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
  // LIFECYCLE
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

    _loadActivePartners();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadActivePartners() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.get('/superadmin/active-partners');

      debugPrint('DATA MITRA AKTIF: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body is Map<String, dynamic> && body['success'] == true) {
          final data = body['data'];

          if (data is List) {
            setState(() {
              _partners = data
                  .map<Map<String, dynamic>>(
                    (item) => Map<String, dynamic>.from(item),
                  )
                  .toList();
              _isLoading = false;
            });
          } else {
            setState(() {
              _partners = [];
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _errorMessage =
                body['message']?.toString() ??
                'Gagal mengambil data mitra aktif.';
            _isLoading = false;
          });
        }
      } else {
        String message = 'Gagal mengambil data mitra aktif.';
        try {
          final body = jsonDecode(response.body);
          if (body is Map<String, dynamic> && body['message'] != null) {
            message = body['message'].toString();
          }
        } catch (_) {}

        setState(() {
          _errorMessage = '$message\nStatus: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('ERROR MITRA AKTIF: $e');
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

  List<Map<String, dynamic>> get _filteredPartners {
    if (_searchQuery.isEmpty) return _partners;

    return _partners.where((partner) {
      final name = _getValue(partner, [
        'name',
        'partner_name',
        'mitra_name',
      ]).toLowerCase();

      final email = _getValue(partner, [
        'email',
        'partner_email',
        'mitra_email',
      ]).toLowerCase();

      final phone = _getValue(partner, [
        'phone',
        'phone_number',
        'nomor_telepon',
      ]).toLowerCase();

      final jobTitle = _getValue(partner, [
        'job_title',
        'job_name',
        'title',
        'service_title',
      ]).toLowerCase();

      return name.contains(_searchQuery) ||
          email.contains(_searchQuery) ||
          phone.contains(_searchQuery) ||
          jobTitle.contains(_searchQuery);
    }).toList();
  }

  String _getValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null &&
          value.toString().trim().isNotEmpty &&
          value.toString() != 'null') {
        return value.toString();
      }
    }
    return '-';
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
            onRefresh: _loadActivePartners,
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
                  _buildSearchBox(t),
                  const SizedBox(height: 16),

                  if (_isLoading)
                    _buildLoading(t)
                  else if (_errorMessage != null)
                    _buildError(t)
                  else if (_filteredPartners.isEmpty)
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
          'Mitra Aktif',
          style: TextStyle(
            fontSize: isMobile ? 22 : 26,
            fontWeight: FontWeight.w700,
            color: t.cellText,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Melihat mitra yang sedang mengerjakan pekerjaan aktif.',
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
  // SEARCH BOX
  // ============================================================

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
          hintText: 'Cari nama mitra, email, telepon, atau pekerjaan...',
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
            'Mengambil data mitra aktif...',
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
            'Gagal mengambil data mitra aktif',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: t.danger,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: t.danger, height: 1.4),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadActivePartners,
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
              Icons.engineering_outlined,
              size: 34,
              color: t.accent.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Belum ada mitra yang sedang bekerja',
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
    final partners = _filteredPartners;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          _buildTableHeaderRow(t),
          Divider(height: 1, thickness: 1, color: t.divider),

          for (int i = 0; i < partners.length; i++) ...[
            _buildTableDataRow(partners[i], t),
            if (i != partners.length - 1)
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
          Expanded(flex: 3, child: _headerCell('Mitra', t)),
          Expanded(flex: 3, child: _headerCell('Kontak', t)),
          Expanded(flex: 3, child: _headerCell('Pekerjaan Aktif', t)),
          Expanded(flex: 3, child: _headerCell('Lokasi', t)),
          Expanded(flex: 3, child: _headerCell('Status', t)),
        ],
      ),
    );
  }

  Widget _headerCell(String text, AdminTheme t) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: t.headerText,
      ),
    );
  }

  Widget _buildTableDataRow(Map<String, dynamic> partner, AdminTheme t) {
    final name = _getValue(partner, ['name', 'partner_name', 'mitra_name']);
    final email = _getValue(partner, ['email', 'partner_email', 'mitra_email']);
    final phone = _getValue(partner, [
      'phone',
      'phone_number',
      'nomor_telepon',
    ]);
    final jobTitle = _getValue(partner, [
      'job_title',
      'job_name',
      'title',
      'service_title',
    ]);
    final location = _getValue(partner, [
      'location',
      'address',
      'job_location',
      'alamat',
    ]);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Mitra
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _buildAvatar(name, partner['photo_url']?.toString(), t),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.cellText,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Kontak
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

          // Pekerjaan Aktif
          Expanded(
            flex: 3,
            child: Text(
              jobTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: t.mutedText, height: 1.3),
            ),
          ),

          // Lokasi
          Expanded(
            flex: 3,
            child: Text(
              location,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: t.mutedText, height: 1.3),
            ),
          ),

          // Status
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusBadge(t),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE — CARD LIST
  // ============================================================

  Widget _buildMobileList(AdminTheme t) {
    final partners = _filteredPartners;

    return Column(
      children: partners.asMap().entries.map((entry) {
        final index = entry.key;
        final partner = entry.value;

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == partners.length - 1 ? 0 : 12,
          ),
          child: _buildMobileCard(partner, t),
        );
      }).toList(),
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> partner, AdminTheme t) {
    final name = _getValue(partner, ['name', 'partner_name', 'mitra_name']);
    final email = _getValue(partner, ['email', 'partner_email', 'mitra_email']);
    final phone = _getValue(partner, [
      'phone',
      'phone_number',
      'nomor_telepon',
    ]);
    final jobTitle = _getValue(partner, [
      'job_title',
      'job_name',
      'title',
      'service_title',
    ]);
    final location = _getValue(partner, [
      'location',
      'address',
      'job_location',
      'alamat',
    ]);

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
              _buildAvatar(name, partner['photo_url']?.toString(), t),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: t.cellText,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildStatusBadge(t),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(height: 1, color: t.divider),
          const SizedBox(height: 12),

          _mobileInfo(Icons.email_outlined, email, t),
          const SizedBox(height: 8),
          _mobileInfo(Icons.phone_outlined, phone, t),
          const SizedBox(height: 8),
          _mobileInfo(Icons.work_outline, jobTitle, t),
          const SizedBox(height: 8),
          _mobileInfo(Icons.location_on_outlined, location, t),
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
  // AVATAR & STATUS
  // ============================================================

    Widget _buildAvatar(String name, String? photoUrl, AdminTheme t) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: t.accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: ClipOval(
        child: (photoUrl != null && photoUrl.isNotEmpty)
            ? Image.network(
                photoUrl, // <-- LANGSUNG PAKAI URL ASLI DARI LARAVEL
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: t.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
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
                    fontSize: 15,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatusBadge(AdminTheme t) {
    // "Sedang Bekerja" = status sukses → pakai t.accent (Teal)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: t.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: t.accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Sedang Bekerja',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: t.accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}