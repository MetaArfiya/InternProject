import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// 🔥 Import khusus Web untuk bypass CORS
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

import '../../services/api_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/admin_theme_provider.dart';
import '../../theme/app_colors.dart';

class AdminComplaintScreen extends StatefulWidget {
  const AdminComplaintScreen({super.key});

  @override
  State<AdminComplaintScreen> createState() =>
      _AdminComplaintScreenState();
}

class _AdminComplaintScreenState extends State<AdminComplaintScreen> {
  // ============================================================
  // THEME
  // ============================================================

  AdminTheme get theme => AdminThemeProvider.of(context);

  // ============================================================
  // TOKENS
  // ============================================================

  static const double _gapAfterHeader = 16;
  static const double _gapBetweenSections = 16;
  static const double _cardRadius = 14;
  static const double _radius = 10;

  /// Base URL storage yang otomatis menyesuaikan platform.
  /// Kembali menggunakan /storage karena route /api/images/complaints tidak ada (404).
  static String get _storageBaseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/storage';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000/storage';
    } catch (_) {}
    return 'http://127.0.0.1:8000/storage';
  }

  /// Cache buster per sesi — mencegah browser memakai cache negatif.
  late final String _cacheBuster =
      DateTime.now().millisecondsSinceEpoch.toString();

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _complaints = [];

  Map<String, int> _summary = {
    'total': 0,
    'menunggu': 0,
    'diproses': 0,
    'selesai': 0,
    'ditolak': 0,
  };

  String _selectedFilter = 'Semua';

  final List<String> _filters = [
    'Semua',
    'Menunggu',
    'Diproses',
    'Selesai',
    'Ditolak',
  ];

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();
    debugPrint('🔥 ADMIN COMPLAINT SCREEN INIT');
    debugPrint('🧹 CACHE BUSTER: $_cacheBuster');
    _loadComplaints();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadComplaints() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      debugPrint('🔥 LOAD COMPLAINTS DIPANGGIL');

      final response = await ApiService.get('/admin/complaints');

      debugPrint('📢 ADMIN COMPLAINTS: ${response.statusCode}');
      debugPrint('📢 BODY: ${response.body}');

      if (response.statusCode != 200) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat (${response.statusCode})';
        });
        return;
      }

      final decoded = jsonDecode(response.body);

      if (decoded['success'] != true) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage =
              decoded['message']?.toString() ?? 'Gagal memuat.';
        });
        return;
      }

      final summaryData = decoded['summary'] ?? {};

      final List<dynamic> list = decoded['data'] is List
          ? decoded['data'] as List<dynamic>
          : <dynamic>[];

      final complaints = list
          .whereType<Map>()
          .map<Map<String, dynamic>>(
            (e) => Map<String, dynamic>.from(e),
          )
          .toList();

      debugPrint('🔥 JUMLAH COMPLAINT: ${complaints.length}');

      if (!mounted) return;

      setState(() {
        _summary = {
          'total': int.tryParse(
                summaryData['total']?.toString() ?? '0',
              ) ??
              0,
          'menunggu': int.tryParse(
                summaryData['menunggu']?.toString() ?? '0',
              ) ??
              0,
          'diproses': int.tryParse(
                summaryData['diproses']?.toString() ?? '0',
              ) ??
              0,
          'selesai': int.tryParse(
                summaryData['selesai']?.toString() ?? '0',
              ) ??
              0,
          'ditolak': int.tryParse(
                summaryData['ditolak']?.toString() ?? '0',
              ) ??
              0,
        };

        _complaints = complaints;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ ERROR ADMIN COMPLAINTS: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  Future<void> _updateComplaintStatus(
    dynamic id,
    String newStatus, {
    String? note,
  }) async {
    try {
      final response = await ApiService.put(
        '/admin/complaints/$id',
        {
          'status': newStatus,
          if (note != null && note.isNotEmpty) 'admin_response': note,
        },
      );

      debugPrint('📢 PUT /admin/complaints/$id → ${response.statusCode}');
      debugPrint('📢 BODY: ${response.body}');

      if (response.statusCode == 200) {
        if (!mounted) return;

        _showSnack('Status pengaduan diubah menjadi $newStatus.');

        await _loadComplaints();
      } else {
        String message = 'Gagal mengubah status.';

        try {
          final decoded = jsonDecode(response.body);
          message = decoded['message']?.toString() ?? message;
        } catch (_) {}

        if (!mounted) return;
        _showSnack(message, error: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error: $e', error: true);
    }
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    final t = theme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? t.danger : t.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _getNestedValue(
    Map<String, dynamic> data,
    String relation,
    List<String> keys,
  ) {
    final rel = data[relation];

    if (rel is Map) {
      for (final key in keys) {
        final value = rel[key];

        if (value != null &&
            value.toString().trim().isNotEmpty &&
            value.toString() != 'null') {
          return value.toString();
        }
      }
    }

    return '-';
  }

  String _formatTanggal(String? iso) {
    if (iso == null || iso.isEmpty) return '-';

    try {
      final date = DateTime.parse(iso).toLocal();

      const bulan = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];

      return '${date.day.toString().padLeft(2, '0')} '
          '${bulan[date.month - 1]} ${date.year}';
    } catch (_) {
      return iso;
    }
  }

  String _code(Map<String, dynamic> c) {
    final id = c['id'];
    if (id is int) return 'PGD-${id.toString().padLeft(3, '0')}';
    return 'PGD-${id.toString()}';
  }

  // ============================================================
  // PROOF PHOTO HELPERS
  // ============================================================

  String? _getProofPhotoUrl(Map<String, dynamic> c) {
    final url = c['proof_photo_url']?.toString().trim();
    if (url != null && url.isNotEmpty && url != 'null') {
      return _buildStorageUrl(url);
    }

    final path = c['proof_photo']?.toString().trim();
    if (path != null && path.isNotEmpty && path != 'null') {
      return _buildStorageUrl(path);
    }

    return null;
  }

  String _buildStorageUrl(String rawPath) {
    var p = rawPath.trim();

    if (p.startsWith('http://') || p.startsWith('https://')) {
      return _withCacheBuster(p);
    }

    if (p.startsWith('/')) p = p.substring(1);
    if (p.startsWith('storage/')) p = p.substring('storage/'.length);

    return _withCacheBuster('$_storageBaseUrl/$p');
  }

  String _withCacheBuster(String url) {
    if (url.contains('?v=')) return url;
    final sep = url.contains('?') ? '&' : '?';
    return '$url${sep}v=$_cacheBuster';
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<Map<String, dynamic>> get _filteredComplaints {
    if (_selectedFilter == 'Semua') return _complaints;

    return _complaints
        .where((c) => c['status']?.toString() == _selectedFilter)
        .toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: t.bg,
      child: RefreshIndicator(
        onRefresh: _loadComplaints,
        color: t.accent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 700;
            final isTablet = width >= 700 && width < 1100;

            final horizontalPadding =
                isMobile ? 16.0 : (isTablet ? 24.0 : 28.0);
            final verticalPadding = isMobile ? 16.0 : 28.0;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: _gapAfterHeader),
                  if (_isLoading)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: CircularProgressIndicator(color: t.accent),
                      ),
                    )
                  else if (_errorMessage != null)
                    _buildError()
                  else ...[
                    _buildStatistics(isMobile, isTablet),
                    const SizedBox(height: _gapBetweenSections),
                    _buildComplaintSection(isMobile, isTablet),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    final t = theme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pengaduan',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: t.cellText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kelola pengaduan dari mitra dan pelanggan.',
          style: textTheme.bodyMedium?.copyWith(color: t.mutedText),
        ),
      ],
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatistics(bool isMobile, bool isTablet) {
    final t = theme;
    final cards = [
      _StatData(
        title: 'Menunggu',
        value: '${_summary['menunggu'] ?? 0}',
        subtitle: 'Pengaduan baru',
        icon: Icons.hourglass_empty_rounded,
        color: t.warning,
      ),
      _StatData(
        title: 'Diproses',
        value: '${_summary['diproses'] ?? 0}',
        subtitle: 'Sedang ditangani',
        icon: Icons.sync_rounded,
        color: AppColors.infoBlue,
      ),
      _StatData(
        title: 'Selesai',
        value: '${_summary['selesai'] ?? 0}',
        subtitle: 'Telah diselesaikan',
        icon: Icons.check_circle_outline_rounded,
        color: t.success,
      ),
      _StatData(
        title: 'Ditolak',
        value: '${_summary['ditolak'] ?? 0}',
        subtitle: 'Pengaduan ditolak',
        icon: Icons.cancel_outlined,
        color: t.danger,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard(cards[0])),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard(cards[1])),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildStatCard(cards[2])),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard(cards[3])),
            ],
          ),
        ],
      );
    }

    if (isTablet) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard(cards[0])),
              const SizedBox(width: 14),
              Expanded(child: _buildStatCard(cards[1])),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildStatCard(cards[2])),
              const SizedBox(width: 14),
              Expanded(child: _buildStatCard(cards[3])),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: _buildStatCard(cards[i])),
          if (i != cards.length - 1) const SizedBox(width: 16),
        ],
      ],
    );
  }

  Widget _buildStatCard(_StatData data) {
    final t = theme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: t.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(data.icon, color: data.color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: t.cellText,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.grey400,
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
  // COMPLAINT SECTION
  // ============================================================

  Widget _buildComplaintSection(bool isMobile, bool isTablet) {
    final t = theme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterBar(context),

          const SizedBox(height: 14),
          Divider(height: 1, color: t.divider),
          const SizedBox(height: 14),

          _buildSectionTitle(context),

          const SizedBox(height: 16),
          Divider(height: 1, color: t.divider),
          const SizedBox(height: 14),

          if (_filteredComplaints.isEmpty)
            _buildEmptyState(context)
          else if (isMobile)
            Column(
              children: _filteredComplaints
                  .map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildComplaintCard(context, c),
                    ),
                  )
                  .toList(),
            )
          else
            _buildDesktopTable(context, isTablet),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER BAR
  // ============================================================

  Widget _buildFilterBar(BuildContext context) {
    final t = theme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.filter_list_rounded,
          size: 18,
          color: t.headerText,
        ),
        const SizedBox(width: 8),
        Text(
          'Filter Status:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: t.mutedText,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 160,
          child: _buildFilterDropdown(context),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: t.accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_filteredComplaints.length}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: t.accent,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(BuildContext context) {
    final t = theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daftar Pengaduan',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: t.cellText,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_filteredComplaints.length} pengaduan ditampilkan',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: t.mutedText,
              ),
        ),
      ],
    );
  }

  // ============================================================
  // FILTER DROPDOWN
  // ============================================================

  Widget _buildFilterDropdown(BuildContext context) {
    final t = theme;
    return Container(
      height: 40,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: t.headerText,
          ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: t.cellText,
                fontWeight: FontWeight.w500,
              ),
          items: _filters
              .map(
                (f) => DropdownMenuItem<String>(
                  value: f,
                  child: Text(
                    f,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _selectedFilter = v);
          },
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE WIDGET (BYPASS CORS DI WEB)
  // ============================================================

  Widget _proofImage({
    required String url,
    required double width,
    required double height,
    required AdminTheme t,
    required String tag,
    BoxFit fit = BoxFit.cover,
  }) {
    assert(width.isFinite, 'Width must be finite');
    assert(height.isFinite, 'Height must be finite');

    // 🔥 JIKA DI WEB: Gunakan HTML <img> (Bebas CORS 100%)
    if (kIsWeb) {
      // Buat ID unik berdasarkan URL dan ukuran
      final viewType = 'img-${url.hashCode}-${width.toInt()}-${height.toInt()}';
      
      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        final img = web.HTMLImageElement()
          ..src = url
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover'
          ..style.borderRadius = '6px';
        return img;
      });

      return SizedBox(
        width: width,
        height: height,
        child: HtmlElementView(viewType: viewType),
      );
    }

    // 🔥 JIKA DI MOBILE/DESKTOP: Gunakan Image.network biasa
    return SizedBox(
      width: width,
      height: height,
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppColors.grey100,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ IMAGE FAIL ($tag): $url');
          debugPrint('❌ REASON ($tag): $error');
          return Container(
            color: AppColors.grey100,
            alignment: Alignment.center,
            child: Icon(
              Icons.broken_image_outlined,
              size: 18,
              color: t.mutedText,
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // DESKTOP TABLE
  // ============================================================

  Widget _buildDesktopTable(BuildContext context, bool isTablet) {
    final t = theme;
    final complaints = _filteredComplaints;

    debugPrint('🖥️ DESKTOP TABLE: ${complaints.length} DATA');

    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: isTablet ? 980 : 1180,
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(AppColors.grey50),
              headingRowHeight: 48,
              dataRowMinHeight: 74,
              dataRowMaxHeight: 100,
              columnSpacing: isTablet ? 18 : 24,
              horizontalMargin: 14,
              dividerThickness: 0.6,
              headingTextStyle: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: t.headerText,
              ),
              columns: const [
                DataColumn(label: Text('Pengaduan')),
                DataColumn(label: Text('Bukti')),
                DataColumn(label: Text('Pengadu')),
                DataColumn(label: Text('Pekerjaan')),
                DataColumn(label: Text('Kategori')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Aksi')),
              ],
              rows: complaints.map((c) {
                final proofUrl = _getProofPhotoUrl(c);
                return DataRow(
                  cells: [
                    // PENGADUAN
                    DataCell(
                      SizedBox(
                        width: 105,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _code(c),
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: t.cellText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTanggal(
                                c['created_at']?.toString(),
                              ),
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.grey400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // BUKTI FOTO
                    DataCell(
                      SizedBox(
                        width: 70,
                        child: proofUrl != null
                            ? GestureDetector(
                                onTap: () =>
                                    _showFullScreenImage(proofUrl),
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(6),
                                  child: _proofImage(
                                    url: proofUrl,
                                    width: 60,
                                    height: 48,
                                    t: t,
                                    tag: 'table',
                                  ),
                                ),
                              )
                            : Container(
                                width: 60,
                                height: 48,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.grey50,
                                  borderRadius:
                                      BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 16,
                                  color: AppColors.grey400,
                                ),
                              ),
                      ),
                    ),

                    // PENGADU
                    DataCell(
                      SizedBox(
                        width: 135,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getNestedValue(c, 'user', ['name']),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: t.cellText,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              c['user_role']?.toString() ?? '-',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.grey400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // PEKERJAAN
                    DataCell(
                      SizedBox(
                        width: 160,
                        child: Text(
                          _getNestedValue(
                            c,
                            'job',
                            ['tittle', 'title'],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: t.cellText,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),

                    // KATEGORI
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: Text(
                          c['category']?.toString() ?? '-',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: t.cellText,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),

                    // STATUS
                    DataCell(
                      _buildStatusBadge(
                        context,
                        c['status']?.toString() ?? '-',
                      ),
                    ),

                    // AKSI
                    DataCell(_buildActionButtons(context, c)),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE CARD
  // ============================================================

  Widget _buildComplaintCard(
    BuildContext context,
    Map<String, dynamic> c,
  ) {
    final t = theme;
    final status = c['status']?.toString() ?? '-';
    final textTheme = Theme.of(context).textTheme;
    final proofUrl = _getProofPhotoUrl(c);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _code(c),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: t.cellText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatTanggal(c['created_at']?.toString()),
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.grey400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(context, status),
            ],
          ),

          const SizedBox(height: 13),
          Divider(height: 1, color: t.divider),
          const SizedBox(height: 13),

          _mobileInfoRow(
            Icons.person_outline_rounded,
            'Pengadu',
            '${_getNestedValue(c, 'user', ['name'])} (${c['user_role'] ?? '-'})',
            t,
          ),

          _mobileInfoRow(
            Icons.work_outline_rounded,
            'Pekerjaan',
            _getNestedValue(c, 'job', ['tittle', 'title']),
            t,
          ),

          _mobileInfoRow(
            Icons.category_outlined,
            'Kategori',
            c['category']?.toString() ?? '-',
            t,
          ),

          // THUMBNAIL BUKTI FOTO (mobile)
          if (proofUrl != null) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _showFullScreenImage(proofUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final imageWidth = constraints.maxWidth;
                    return _proofImage(
                      url: proofUrl,
                      width: imageWidth,
                      height: 140,
                      t: t,
                      tag: 'mobile',
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 9),
          ],

          // BADGE BUKTI FOTO
          if (proofUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(
                      Icons.image_outlined,
                      size: 14,
                      color: t.accent,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'Bukti foto tersedia',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: t.accent,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 5),

          Text(
            'Pengaduan',
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: t.cellText,
            ),
          ),

          const SizedBox(height: 6),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: t.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c['title']?.toString() ?? '-',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: t.cellText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  c['description']?.toString() ?? '-',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    height: 1.45,
                    color: t.mutedText,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          _buildActionButtons(context, c),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE INFO ROW
  // ============================================================

  Widget _mobileInfoRow(
    IconData icon,
    String label,
    String value,
    AdminTheme t,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 14, color: t.mutedText),
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 66,
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: t.mutedText,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              ':',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.grey400,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: t.cellText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(BuildContext context, String status) {
    final t = theme;
    Color color;

    switch (status) {
      case 'Menunggu':
        color = t.warning;
        break;
      case 'Diproses':
        color = AppColors.infoBlue;
        break;
      case 'Selesai':
        color = t.success;
        break;
      case 'Ditolak':
        color = t.danger;
        break;
      default:
        color = t.mutedText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
      ),
    );
  }

  // ============================================================
  // ACTION BUTTONS
  // ============================================================

  Widget _buildActionButtons(
    BuildContext context,
    Map<String, dynamic> c,
  ) {
    final t = theme;
    final status = c['status']?.toString() ?? '';

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _pillButton(
          context: context,
          icon: Icons.visibility_outlined,
          label: 'Detail',
          bgColor: AppColors.grey100,
          fgColor: AppColors.grey700,
          onTap: () => _showComplaintDetail(c),
        ),

        if (status == 'Menunggu')
          _pillButton(
            context: context,
            icon: Icons.play_arrow_outlined,
            label: 'Proses',
            bgColor: t.accent,
            fgColor: AppColors.white,
            onTap: () => _updateComplaintStatus(c['id'], 'Diproses'),
          ),

        if (status == 'Diproses')
          _pillButton(
            context: context,
            icon: Icons.check_circle_outline,
            label: 'Selesai',
            bgColor: t.success,
            fgColor: AppColors.white,
            onTap: () => _updateComplaintStatus(c['id'], 'Selesai'),
          ),

        if (status == 'Menunggu' || status == 'Diproses')
          _pillButton(
            context: context,
            icon: Icons.cancel_outlined,
            label: 'Tolak',
            bgColor: t.danger.withValues(alpha: 0.10),
            fgColor: t.danger,
            onTap: () => _confirmReject(c),
          ),
      ],
    );
  }

  Widget _pillButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color fgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: fgColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: fgColor,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL DIALOG
  // ============================================================

  void _showComplaintDetail(Map<String, dynamic> c) {
    final t = theme;
    final responseController = TextEditingController(
      text: c['admin_response']?.toString() ?? '',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final textTheme = Theme.of(dialogContext).textTheme;
        final status = c['status']?.toString() ?? '';
        final proofUrl = _getProofPhotoUrl(c);

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
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
                          borderRadius: BorderRadius.circular(_radius),
                        ),
                        child: Icon(
                          Icons.report_problem_outlined,
                          color: t.accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Detail Pengaduan',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: t.cellText,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailRow('ID Pengaduan', _code(c), t),
                          _detailRow(
                            'Tanggal',
                            _formatTanggal(c['created_at']?.toString()),
                            t,
                          ),
                          _detailRow(
                            'Pengadu',
                            _getNestedValue(c, 'user', ['name']),
                            t,
                          ),
                          _detailRow(
                            'Role',
                            c['user_role']?.toString() ?? '-',
                            t,
                          ),
                          _detailRow(
                            'Kategori',
                            c['category']?.toString() ?? '-',
                            t,
                          ),
                          _detailRow(
                            'Pekerjaan',
                            _getNestedValue(
                              c,
                              'job',
                              ['tittle', 'title'],
                            ),
                            t,
                          ),
                          _detailRow(
                            'Judul',
                            c['title']?.toString() ?? '-',
                            t,
                          ),
                          _detailRow('Status', status, t),

                          const SizedBox(height: 12),

                          _detailSectionBox(
                            title: 'Keterangan Pengaduan',
                            child: Text(
                              c['description']?.toString() ?? '-',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: t.cellText,
                              ),
                            ),
                            t: t,
                          ),

                          // BUKTI FOTO
                          if (proofUrl != null) ...[
                            const SizedBox(height: 12),
                            _detailSectionBox(
                              title: 'Bukti Foto',
                              child: _buildProofImage(proofUrl, t),
                              t: t,
                            ),
                          ],

                          if ((c['admin_response']?.toString() ?? '')
                              .isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _detailSectionBox(
                              title: 'Tanggapan Admin',
                              backgroundColor:
                                  t.success.withValues(alpha: 0.08),
                              borderColor:
                                  t.success.withValues(alpha: 0.25),
                              titleColor: t.success,
                              child: Text(
                                c['admin_response'].toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: t.success,
                                ),
                              ),
                              t: t,
                            ),
                          ],

                          if (status == 'Menunggu' ||
                              status == 'Diproses') ...[
                            const SizedBox(height: 12),
                            Text(
                              'Tanggapan / Catatan Admin',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: t.cellText,
                              ),
                            ),
                            const SizedBox(height: 7),
                            TextField(
                              controller: responseController,
                              maxLines: 3,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText:
                                    'Tulis tanggapan untuk pengadu...',
                                hintStyle: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.grey400,
                                ),
                                filled: true,
                                fillColor: AppColors.grey50,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(_radius),
                                  borderSide: BorderSide(
                                    color: t.border,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(_radius),
                                  borderSide: BorderSide(
                                    color: t.border,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(_radius),
                                  borderSide: BorderSide(
                                    color: t.accent,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding:
                                    const EdgeInsets.all(11),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ACTIONS
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 46),
                            foregroundColor: AppColors.grey700,
                            side: const BorderSide(
                              color: AppColors.grey300,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_radius),
                            ),
                          ),
                          child: const Text(
                            'Tutup',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      if (status == 'Menunggu') ...[
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              _updateComplaintStatus(
                                c['id'],
                                'Diproses',
                                note: responseController.text.trim(),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: t.accent,
                              foregroundColor: AppColors.white,
                              minimumSize: const Size(0, 46),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(_radius),
                              ),
                            ),
                            child: const Text(
                              'Proses',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],

                      if (status == 'Diproses') ...[
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              _updateComplaintStatus(
                                c['id'],
                                'Selesai',
                                note: responseController.text.trim(),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: t.success,
                              foregroundColor: AppColors.white,
                              minimumSize: const Size(0, 46),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(_radius),
                              ),
                            ),
                            child: const Text(
                              'Tandai Selesai',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PROOF IMAGE WIDGET (detail dialog)
  // ============================================================

  Widget _buildProofImage(String url, AdminTheme t) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(url),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final imageWidth = constraints.maxWidth;
                return _proofImage(
                  url: url,
                  width: imageWidth,
                  height: 180,
                  t: t,
                  tag: 'detail',
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.open_in_full_rounded,
                size: 12,
                color: t.accent,
              ),
              const SizedBox(width: 4),
              Text(
                'Tap untuk melihat ukuran penuh',
                style: TextStyle(
                  fontSize: 11,
                  color: t.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FULL SCREEN IMAGE DIALOG
  // ============================================================

  void _showFullScreenImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: _proofImage(
                  url: url,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  t: theme,
                  tag: 'fullscreen',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL SECTION BOX
  // ============================================================

  Widget _detailSectionBox({
    required String title,
    required Widget child,
    required AdminTheme t,
    Color? backgroundColor,
    Color? borderColor,
    Color? titleColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: titleColor ?? t.cellText,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.grey50,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(
              color: borderColor ?? t.border,
            ),
          ),
          child: child,
        ),
      ],
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(String label, String value, AdminTheme t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: t.mutedText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: t.cellText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // KONFIRMASI TOLAK
  // ============================================================

  void _confirmReject(Map<String, dynamic> c) {
    final t = theme;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final textTheme = Theme.of(dialogContext).textTheme;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
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
                          color: t.danger.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(_radius),
                        ),
                        child: Icon(
                          Icons.cancel_outlined,
                          color: t.danger,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tolak Pengaduan?',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: t.cellText,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(),
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

                  Text(
                    'Apakah kamu yakin ingin menolak pengaduan ini?',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.grey700,
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Alasan penolakan...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: AppColors.grey400,
                      ),
                      filled: true,
                      fillColor: AppColors.grey50,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(_radius),
                        borderSide: BorderSide(
                          color: t.border,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(_radius),
                        borderSide: BorderSide(
                          color: t.border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(_radius),
                        borderSide: BorderSide(
                          color: t.accent,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(11),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 46),
                            foregroundColor: AppColors.grey700,
                            side: const BorderSide(
                              color: AppColors.grey300,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_radius),
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _updateComplaintStatus(
                              c['id'],
                              'Ditolak',
                              note: reasonController.text.trim(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: t.danger,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size(0, 46),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_radius),
                            ),
                          ),
                          child: const Text(
                            'Tolak',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
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
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState(BuildContext context) {
    final t = theme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
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
              Icons.inbox_outlined,
              size: 34,
              color: t.accent.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Tidak ada pengaduan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: t.mutedText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Belum ada pengaduan dengan status tersebut.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.grey400,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildError() {
    final t = theme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: t.danger.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: t.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: t.danger,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: t.danger,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadComplaints,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: t.accent,
              foregroundColor: AppColors.white,
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
}

// ============================================================
// DATA HELPER
// ============================================================

class _StatData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}