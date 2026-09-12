import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class ActivePartnerPage extends StatefulWidget {
  const ActivePartnerPage({super.key});

  @override
  State<ActivePartnerPage> createState() => _ActivePartnerPageState();
}

class _ActivePartnerPageState extends State<ActivePartnerPage> {
  final TextEditingController _searchController =
      TextEditingController();

  List<Map<String, dynamic>> _partners = [];

  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;

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

    _loadActivePartners();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD MITRA AKTIF
  // ============================================================

  Future<void> _loadActivePartners() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Endpoint ini perlu tersedia di backend Laravel.
      final response =
          await ApiService.get('/superadmin/active-partners');

      debugPrint(
        'DATA MITRA AKTIF: ${response.body}',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body is Map<String, dynamic> &&
            body['success'] == true) {
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
        String message =
            'Gagal mengambil data mitra aktif.';

        try {
          final body = jsonDecode(response.body);

          if (body is Map<String, dynamic> &&
              body['message'] != null) {
            message = body['message'].toString();
          }
        } catch (_) {}

        setState(() {
          _errorMessage =
              '$message\nStatus: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('ERROR MITRA AKTIF: $e');

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

  List<Map<String, dynamic>> get _filteredPartners {
    if (_searchQuery.isEmpty) {
      return _partners;
    }

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

  String _getValue(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
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
        final isMobile = width < 700;

        final horizontalPadding = isMobile ? 16.0 : 28.0;
        final verticalPadding = isMobile ? 16.0 : 28.0;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isMobile),

                const SizedBox(height: 24),

                _buildSearchBox(),

                const SizedBox(height: 20),

                if (_isLoading)
                  _buildLoading()
                else if (_errorMessage != null)
                  _buildError()
                else if (isMobile)
                  _buildMobileList()
                else
                  _buildDesktopTable(),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mitra Aktif',
          style: TextStyle(
            fontSize: isMobile ? 24 : 30,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Melihat mitra yang sedang mengerjakan pekerjaan aktif.',
          style: TextStyle(
            fontSize: isMobile ? 13 : 15,
            color: const Color(0xFF64748B),
          ),
        ),
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
        borderRadius: BorderRadius.circular(10),
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
        decoration: const InputDecoration(
          hintText:
              'Cari nama mitra, email, telepon, atau pekerjaan...',
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
          contentPadding: EdgeInsets.symmetric(
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

  Widget _buildLoading() {
    return _messageContainer(
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Mengambil data mitra aktif...',
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
    return _messageContainer(
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 42,
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          const Text(
            'Gagal mengambil data mitra aktif',
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
            onPressed: _loadActivePartners,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _messageContainer({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 70,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFDCE4ED),
        ),
      ),
      child: child,
    );
  }

  // ============================================================
  // DESKTOP TABLE
  // ============================================================

  Widget _buildDesktopTable() {
    final partners = _filteredPartners;

    if (partners.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFDCE4ED),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            _buildTableHeader(),
            ...partners.map(_buildTableRow),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      height: 56,
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _tableTitle('MITRA'),
          ),
          Expanded(
            flex: 2,
            child: _tableTitle('KONTAK'),
          ),
          Expanded(
            flex: 2,
            child: _tableTitle('PEKERJAAN AKTIF'),
          ),
          Expanded(
            flex: 2,
            child: _tableTitle('LOKASI'),
          ),
          SizedBox(
            width: 105,
            child: _tableTitle('STATUS'),
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

  Widget _buildTableRow(
    Map<String, dynamic> partner,
  ) {
    final name = _getValue(
      partner,
      ['name', 'partner_name', 'mitra_name'],
    );

    final email = _getValue(
      partner,
      ['email', 'partner_email', 'mitra_email'],
    );

    final phone = _getValue(
      partner,
      ['phone', 'phone_number', 'nomor_telepon'],
    );

    final jobTitle = _getValue(
      partner,
      ['job_title', 'job_name', 'title', 'service_title'],
    );

    final location = _getValue(
      partner,
      ['location', 'address', 'job_location', 'alamat'],
    );

    return Container(
      constraints: const BoxConstraints(
        minHeight: 86,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
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
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  phone,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              jobTitle,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              location,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
              ),
            ),
          ),
          SizedBox(
            width: 105,
            child: _buildStatusWidget(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE
  // ============================================================

  Widget _buildMobileList() {
    final partners = _filteredPartners;

    if (partners.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: partners.map((partner) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMobileCard(partner),
        );
      }).toList(),
    );
  }

  Widget _buildMobileCard(
    Map<String, dynamic> partner,
  ) {
    final name = _getValue(
      partner,
      ['name', 'partner_name', 'mitra_name'],
    );

    final email = _getValue(
      partner,
      ['email', 'partner_email', 'mitra_email'],
    );

    final phone = _getValue(
      partner,
      ['phone', 'phone_number', 'nomor_telepon'],
    );

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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFDCE4ED),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(name),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              _buildStatusWidget(),
            ],
          ),
          const SizedBox(height: 16),
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
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
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
    final initial = name.isNotEmpty
        ? name[0].toUpperCase()
        : '?';

    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: Color(0xFFE8F7EF),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF16A34A),
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildStatusWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Sedang Bekerja',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF15803D),
        ),
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
        vertical: 50,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFDCE4ED),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.engineering_outlined,
            size: 45,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 12),
          Text(
            'Belum ada mitra yang sedang bekerja',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}