import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';

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
  // DESIGN TOKENS (disamakan dengan AdminVerificationScreen)
  // ============================================================

  static const Color _accent = Color(0xFF16A34A);
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
      final name = _getValue(
        partner,
        ['name', 'partner_name', 'mitra_name'],
      ).toLowerCase();

      final email = _getValue(
        partner,
        ['email', 'partner_email', 'mitra_email'],
      ).toLowerCase();

      final phone = _getValue(
        partner,
        ['phone', 'phone_number', 'nomor_telepon'],
      ).toLowerCase();

      final jobTitle = _getValue(
        partner,
        ['job_title', 'job_name', 'title', 'service_title'],
      ).toLowerCase();

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
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, isMobile),
                const SizedBox(height: _gapAfterHeader),
                _buildSearchBox(),
                const SizedBox(height: _gapBetweenSections),

                if (_isLoading)
                  _buildLoading()
                else if (_errorMessage != null)
                  _buildError()
                else if (_filteredPartners.isEmpty)
                  _buildEmptyState()
                else if (isMobile)
                  _buildMobileList()
                else
                  _buildDesktopTable(),

                const SizedBox(height: 24),
              ],
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
          'Mitra Aktif',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Melihat mitra yang sedang mengerjakan pekerjaan aktif.',
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SEARCH BOX
  // ============================================================

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
          hintText: 'Cari nama mitra, email, telepon, atau pekerjaan...',
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
            'Gagal mengambil data mitra aktif',
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
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadActivePartners,
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
              Icons.engineering_outlined,
              size: 34,
              color: _accent.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum ada mitra yang sedang bekerja',
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
    final partners = _filteredPartners;

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
            partners.length,
            (i) => _buildTableDataRow(partners[i]),
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
              'Mitra',
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
            flex: 3,
            child: Text(
              'Pekerjaan Aktif',
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
              'Lokasi',
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
              'Status',
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

  Widget _buildTableDataRow(Map<String, dynamic> partner) {
    final name = _getValue(partner, ['name', 'partner_name', 'mitra_name']);
    final email =
        _getValue(partner, ['email', 'partner_email', 'mitra_email']);
    final phone =
        _getValue(partner, ['phone', 'phone_number', 'nomor_telepon']);
    final jobTitle = _getValue(
      partner,
      ['job_title', 'job_name', 'title', 'service_title'],
    );
    final location = _getValue(
      partner,
      ['location', 'address', 'job_location', 'alamat'],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _tableDivider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Mitra: Avatar + Nama
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _buildAvatar(name),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _cellText,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Kontak: Email + Phone
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

          // Pekerjaan Aktif
          Expanded(
            flex: 3,
            child: Text(
              jobTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: _cellText,
                height: 1.3,
              ),
            ),
          ),

          // Lokasi
          Expanded(
            flex: 3,
            child: Text(
              location,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: _cellText,
                height: 1.3,
              ),
            ),
          ),

          // Status
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusBadge(),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE — CARD LIST
  // ============================================================

  Widget _buildMobileList() {
    final partners = _filteredPartners;

    return Column(
      children: partners.asMap().entries.map((entry) {
        final index = entry.key;
        final partner = entry.value;

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == partners.length - 1 ? 0 : 12,
          ),
          child: _buildMobileCard(partner),
        );
      }).toList(),
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> partner) {
    final name = _getValue(partner, ['name', 'partner_name', 'mitra_name']);
    final email =
        _getValue(partner, ['email', 'partner_email', 'mitra_email']);
    final phone =
        _getValue(partner, ['phone', 'phone_number', 'nomor_telepon']);
    final jobTitle = _getValue(
      partner,
      ['job_title', 'job_name', 'title', 'service_title'],
    );
    final location = _getValue(
      partner,
      ['location', 'address', 'job_location', 'alamat'],
    );

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
          // HEADER: avatar + nama + status
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
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _cellText,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildStatusBadge(),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: _tableDivider),
          const SizedBox(height: 12),

          _mobileInfo(Icons.email_outlined, email),
          const SizedBox(height: 8),
          _mobileInfo(Icons.phone_outlined, phone),
          const SizedBox(height: 8),
          _mobileInfo(Icons.work_outline, jobTitle),
          const SizedBox(height: 8),
          _mobileInfo(Icons.location_on_outlined, location),
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
  // AVATAR & STATUS
  // ============================================================

  Widget _buildAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: 40,
      height: 40,
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
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _successColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 6,
            color: _successColor,
          ),
          SizedBox(width: 5),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Sedang Bekerja',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF15803D),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}