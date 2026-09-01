import 'package:flutter/material.dart';

class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  State<AdminVerificationScreen> createState() =>
      _AdminVerificationScreenState();
}

class _AdminVerificationScreenState
    extends State<AdminVerificationScreen> {
  int selectedMenu = 0;

  final List<Map<String, dynamic>> partners = [
    {
      "name": "Ahmad Fauzi",
      "email": "ahmad.fauzi@gmail.com",
      "category": "AC & Elektronik",
      "city": "Jakarta Selatan",
      "time": "2 jam lalu",
    },
    {
      "name": "Dewi Lestari",
      "email": "dewilestari@gmail.com",
      "category": "Plumbing",
      "city": "Jakarta Barat",
      "time": "5 jam lalu",
    },
    {
      "name": "Rudi Hartono",
      "email": "rudi.h@gmail.com",
      "category": "Pertukangan",
      "city": "Bogor",
      "time": "1 hari lalu",
    },
  ];

  int approvedToday = 12;
  int rejected = 3;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 700;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F7FB),

          drawer: isMobile
              ? Drawer(
                  child: _buildSidebar(context),
                )
              : null,

          appBar: isMobile
              ? AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  iconTheme: const IconThemeData(
                    color: Color(0xFF111827),
                  ),
                  title: const Text(
                    'Admin Operator',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : null,

          body: Row(
            children: [
              if (!isMobile)
                SizedBox(
                  width: 198,
                  child: _buildSidebar(context),
                ),

              Expanded(
                child: _buildMainContent(
                  context,
                  width,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================
  // SIDEBAR
  // =========================================================

  Widget _buildSidebar(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),

            // ADMIN PROFILE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFF8B5CF6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 9),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Operator',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Level: Admin Harian',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            _menuItem(
              icon: Icons.verified_outlined,
              title: 'Verifikasi Mitra',
              badge: partners.length.toString(),
              index: 0,
            ),

            _menuItem(
              icon: Icons.flag_outlined,
              title: 'Moderasi Konten',
              badge: '2',
              index: 1,
            ),

            _menuItem(
              icon: Icons.bar_chart_outlined,
              title: 'Laporan Harian',
              index: 2,
            ),

            _menuItem(
              icon: Icons.notifications_outlined,
              title: 'Notifikasi',
              index: 3,
            ),

            const Spacer(),

            // BAGIAN BAWAH SIDEBAR
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 0, 18, 20),
              child: Container(
                height: 85,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: const Color(0xFFE2E8F0),
                ),
                child: const Center(
                  child: Icon(
                    Icons.image_outlined,
                    color: Color(0xFF94A3B8),
                    size: 30,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required int index,
    String? badge,
  }) {
    final active = selectedMenu == index;

    return InkWell(
      onTap: () {
        setState(() {
          selectedMenu = index;
        });

        Navigator.of(context).maybePop();
      },
      child: Container(
        width: double.infinity,
        height: 48,
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 17),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFFF3E8FF)
              : Colors.transparent,
          border: active
              ? const Border(
                  right: BorderSide(
                    color: Color(0xFF8B5CF6),
                    width: 3,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: active
                  ? const Color(0xFF7C3AED)
                  : const Color(0xFF475569),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.w400,
                  color: active
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFF475569),
                ),
              ),
            ),

            if (badge != null)
              Container(
                width: 19,
                height: 19,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // MAIN CONTENT
  // =========================================================

  Widget _buildMainContent(
    BuildContext context,
    double screenWidth,
  ) {
    final isMobile = screenWidth < 700;
    final isTablet =
        screenWidth >= 700 && screenWidth < 1100;

    final horizontalPadding = isMobile
        ? 16.0
        : isTablet
            ? 24.0
            : 27.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: isMobile ? 20 : 0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: isMobile
                ? _desktopContent(
                    context,
                    isMobile,
                    isTablet,
                  )
                : Center(
                    child: _desktopContent(
                      context,
                      isMobile,
                      isTablet,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _desktopContent(
    BuildContext context,
    bool isMobile,
    bool isTablet,
  ) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        maxWidth: 1475,
      ),
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 0 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _pageTitle(),
            style: TextStyle(
              fontSize: isMobile ? 24 : 27,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            _pageSubtitle(),
            style: TextStyle(
              fontSize: isMobile ? 12 : 13,
              color: const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 24),

          if (selectedMenu == 0)
            _buildVerificationContent(
              context,
              isMobile,
              isTablet,
            )
          else
            _buildPlaceholderContent(
              context,
              isMobile,
            ),
        ],
      ),
    );
  }

  // =========================================================
  // PAGE TITLE
  // =========================================================

  String _pageTitle() {
    switch (selectedMenu) {
      case 1:
        return 'Moderasi Konten';
      case 2:
        return 'Laporan Harian';
      case 3:
        return 'Notifikasi';
      default:
        return 'Verifikasi Mitra Baru';
    }
  }

  String _pageSubtitle() {
    switch (selectedMenu) {
      case 1:
        return 'Kelola dan moderasi konten pengguna.';
      case 2:
        return 'Pantau aktivitas dan laporan harian.';
      case 3:
        return 'Kelola notifikasi sistem.';
      default:
        return '${partners.length} mitra menunggu persetujuan';
    }
  }

  // =========================================================
  // VERIFICATION CONTENT
  // =========================================================

  Widget _buildVerificationContent(
    BuildContext context,
    bool isMobile,
    bool isTablet,
  ) {
    return Column(
      children: [
        if (isMobile)
          Column(
            children: [
              _statCard(
                title: 'Menunggu',
                value: partners.length.toString(),
                icon: Icons.hourglass_empty,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 10),
              _statCard(
                title: 'Disetujui Hari Ini',
                value: approvedToday.toString(),
                icon: Icons.check_circle_outline,
                color: const Color(0xFF10B981),
              ),
              const SizedBox(height: 10),
              _statCard(
                title: 'Ditolak',
                value: rejected.toString(),
                icon: Icons.cancel_outlined,
                color: const Color(0xFFEF4444),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _statCard(
                  title: 'Menunggu',
                  value: partners.length.toString(),
                  icon: Icons.hourglass_empty,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  title: 'Disetujui Hari Ini',
                  value: approvedToday.toString(),
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  title: 'Ditolak',
                  value: rejected.toString(),
                  icon: Icons.cancel_outlined,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),

        const SizedBox(height: 22),

        _buildPartnerList(
          context,
          isMobile,
          isTablet,
        ),
      ],
    );
  }

  // =========================================================
  // STAT CARD
  // =========================================================

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      height: 80,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 22,
          ),

          const SizedBox(width: 12),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                title,
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

  // =========================================================
  // PARTNER LIST
  // =========================================================

  Widget _buildPartnerList(
    BuildContext context,
    bool isMobile,
    bool isTablet,
  ) {
    if (partners.isEmpty) {
      return _emptyPartnerState();
    }

    if (isMobile) {
      return Column(
        children: partners.map((partner) {
          return _buildMobilePartnerCard(
            context,
            partner,
          );
        }).toList(),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFFDCE3EC),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 50,
          dataRowMinHeight: 43,
          dataRowMaxHeight: 43,
          horizontalMargin: 13,
          columnSpacing: isTablet ? 20 : 30,
          headingRowColor:
              WidgetStateProperty.all(
            const Color(0xFFF8FAFC),
          ),
          columns: const [
            DataColumn(
              label: Text(
                'Nama Mitra',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Kategori',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Kota',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Waktu Daftar',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Berkas',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Aksi',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          rows: partners.map((partner) {
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 145,
                    child: _partnerName(partner),
                  ),
                ),

                DataCell(
                  SizedBox(
                    width: 90,
                    child: Text(
                      partner['category'],
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                DataCell(
                  SizedBox(
                    width: 90,
                    child: Text(
                      partner['city'],
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                DataCell(
                  SizedBox(
                    width: 75,
                    child: Text(
                      partner['time'],
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                DataCell(
                  _documentButton(context),
                ),

                DataCell(
                  _actionButtons(
                    context,
                    partner,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // =========================================================
  // MOBILE CARD
  // =========================================================

  Widget _buildMobilePartnerCard(
    BuildContext context,
    Map<String, dynamic> partner,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFDCE3EC),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _partnerName(partner),

          const SizedBox(height: 14),

          _mobileInfo(
            Icons.category_outlined,
            'Kategori',
            partner['category'],
          ),

          const SizedBox(height: 8),

          _mobileInfo(
            Icons.location_on_outlined,
            'Kota',
            partner['city'],
          ),

          const SizedBox(height: 8),

          _mobileInfo(
            Icons.access_time,
            'Waktu Daftar',
            partner['time'],
          ),

          const SizedBox(height: 14),

          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _documentButton(context),
              _approveButton(
                context,
                partner,
              ),
              _rejectButton(
                context,
                partner,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mobileInfo(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF64748B),
        ),
        const SizedBox(width: 7),
        Text(
          '$title: ',
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // PARTNER NAME
  // =========================================================

  Widget _partnerName(
    Map<String, dynamic> partner,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          partner['name'],
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          partner['email'],
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // DOCUMENT BUTTON
  // =========================================================

  Widget _documentButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Berkas Mitra'),
              content: const Text(
                'Berkas pendaftaran mitra dapat diperiksa di halaman ini.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Tutup'),
                ),
              ],
            );
          },
        );
      },
      icon: const Icon(
        Icons.attach_file,
        size: 13,
      ),
      label: const Text(
        'Lihat Berkas',
        style: TextStyle(fontSize: 11),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFEDE9FE),
        foregroundColor: const Color(0xFF7C3AED),
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 9,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7),
        ),
      ),
    );
  }

  // =========================================================
  // ACTION BUTTONS
  // =========================================================

  Widget _actionButtons(
    BuildContext context,
    Map<String, dynamic> partner,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _approveButton(
          context,
          partner,
        ),
        const SizedBox(width: 6),
        _rejectButton(
          context,
          partner,
        ),
      ],
    );
  }

  Widget _approveButton(
    BuildContext context,
    Map<String, dynamic> partner,
  ) {
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          partners.remove(partner);
          approvedToday++;
        });

        _showMessage(
          context,
          'Mitra berhasil disetujui.',
          const Color(0xFF10B981),
        );
      },
      icon: const Icon(
        Icons.check,
        size: 13,
      ),
      label: const Text(
        'Approve',
        style: TextStyle(fontSize: 11),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 9,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7),
        ),
      ),
    );
  }

  Widget _rejectButton(
    BuildContext context,
    Map<String, dynamic> partner,
  ) {
    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          partners.remove(partner);
          rejected++;
        });

        _showMessage(
          context,
          'Mitra ditolak.',
          const Color(0xFFEF4444),
        );
      },
      icon: const Icon(
        Icons.close,
        size: 13,
      ),
      label: const Text(
        'Reject',
        style: TextStyle(fontSize: 11),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFEF4444),
        side: const BorderSide(
          color: Color(0xFFFCA5A5),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 9,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7),
        ),
      ),
    );
  }

  // =========================================================
  // SNACKBAR
  // =========================================================

  void _showMessage(
    BuildContext context,
    String message,
    Color color,
  ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _emptyPartnerState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 45,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFDCE3EC),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.verified_outlined,
            size: 42,
            color: Color(0xFF10B981),
          ),
          SizedBox(height: 10),
          Text(
            'Tidak ada mitra yang menunggu verifikasi',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PLACEHOLDER
  // =========================================================

  Widget _buildPlaceholderContent(
    BuildContext context,
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile ? 30 : 50,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFDCE3EC),
        ),
      ),
      child: Column(
        children: [
          Icon(
            selectedMenu == 1
                ? Icons.flag_outlined
                : selectedMenu == 2
                    ? Icons.bar_chart_outlined
                    : Icons.notifications_outlined,
            size: 50,
            color: const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 14),
          Text(
            _pageTitle(),
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Halaman ini siap dikembangkan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}