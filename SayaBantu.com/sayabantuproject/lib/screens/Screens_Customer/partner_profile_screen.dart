import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';

class PartnerProfileScreen extends StatefulWidget {
  final VoidCallback onFinish;
  final int mitraId;

  const PartnerProfileScreen({
    super.key,
    required this.onFinish,
    required this.mitraId,
  });

  @override
  State<PartnerProfileScreen> createState() => _PartnerProfileScreenState();
}

class _PartnerProfileScreenState extends State<PartnerProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  String _errorMessage = '';

  // ✅ dari orange → teal
  static const Color _accent = AppColors.primaryTeal;

  @override
  void initState() {
    super.initState();
    _fetchMitraProfile();
  }

  Future<void> _fetchMitraProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiService.get('/mitra/${widget.mitraId}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final raw = jsonResponse['data'] ?? jsonResponse;
        if (raw is Map) {
          setState(() {
            _profileData = Map<String, dynamic>.from(raw);
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Format data tidak valid.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              "Gagal terhubung ke server (Kode: ${response.statusCode})";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Terjadi kesalahan: $e";
        _isLoading = false;
      });
    }
  }

  // ================= HELPERS =================

  dynamic _get(List<String> keys, [dynamic fallback]) {
    final m = _profileData;
    if (m == null) return fallback;
    for (final k in keys) {
      final v = m[k];
      if (v != null) return v;
    }
    return fallback;
  }

  String _baseUrl() {
    try {
      return ApiService.baseUrl;
    } catch (_) {
      return '';
    }
  }

  String? _normalizeUrl(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;

    final base = _baseUrl();

    if (!s.startsWith('http://') && !s.startsWith('https://')) {
      if (base.isEmpty) return s;
      if (s.startsWith('/')) return '$base$s';
      return '$base/$s';
    }

    if (base.isEmpty) return s;
    try {
      final baseUri = Uri.parse(base);
      final rawUri = Uri.parse(s);
      return rawUri
          .replace(
            scheme: baseUri.scheme,
            host: baseUri.host,
            port: baseUri.hasPort ? baseUri.port : null,
          )
          .toString();
    } catch (_) {
      return s;
    }
  }

  String? _profilePhotoUrl() {
    final candidates = <String?>[
      _get(['profile_photo_url'])?.toString(),
      _get(['profile_photo'])?.toString(),
      _get(['photo_url'])?.toString(),
    ];
    for (final c in candidates) {
      final n = _normalizeUrl(c);
      if (n != null) return n;
    }
    return null;
  }

  String _name() => (_get(['name', 'nama'], 'Mitra')).toString();

  double _ratingValue() {
    final v = _get(['rating', 'avg_rating', 'average_rating'], 0.0);
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  int _reviewsCount() {
    final v = _get(
        ['reviews_count', 'total_reviews', 'ratings_count', 'reviews_total']);
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    final list = _get(['reviews', 'ratings']);
    if (list is List) return list.length;
    return 0;
  }

  bool _isVerified() => _get(['verified', 'is_verified'], false) == true;

  List<dynamic> _skills() {
    final s = _get(['skills', 'keahlian']);
    return s is List ? s : const [];
  }

  List<dynamic> _certificates() {
    final c = _get(['certificates', 'certificate', 'sertifikat']);
    if (c is List) return c;
    if (c is String && c.isNotEmpty) return [c];
    return const [];
  }

  // ================= FULLSCREEN VIEWER =================

  void _openImageViewer({
    required List<_GalleryItem> items,
    required int initialIndex,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, __, ___) => _ImageViewerScreen(
          items: items,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  List<_GalleryItem> _skillGallery() {
    final result = <_GalleryItem>[];
    for (final s in _skills()) {
      if (s is Map) {
        final url = _normalizeUrl(s['photo_url']?.toString()) ??
            _normalizeUrl(s['photo']?.toString());
        if (url != null) {
          result.add(_GalleryItem(
            url: url,
            title: (s['name'] ?? s['nama'] ?? 'Keahlian').toString(),
          ));
        }
      }
    }
    return result;
  }

  List<_GalleryItem> _certificateGallery() {
    final result = <_GalleryItem>[];
    for (final c in _certificates()) {
      String title = 'Sertifikat';
      String? url;
      if (c is Map) {
        title =
            (c['title'] ?? c['name'] ?? c['nama'] ?? 'Sertifikat').toString();
        url = _normalizeUrl(c['url']?.toString()) ??
            _normalizeUrl(c['file']?.toString());
      } else if (c is String) {
        url = _normalizeUrl(c);
      }
      if (url != null) {
        result.add(_GalleryItem(url: url, title: title));
      }
    }
    return result;
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sectionAltLight, // ← mint muda
      appBar: AppBar(
        title: const Text(
          "Profil Mitra",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.grey900,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.grey900,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onFinish,
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryTeal),
            )
          : _errorMessage.isNotEmpty
              ? _ErrorView(message: _errorMessage, onRetry: _fetchMitraProfile)
              : RefreshIndicator(
                  onRefresh: _fetchMitraProfile,
                  color: AppColors.primaryTeal,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final isMobile = width < 700;
                      final isTablet = width >= 700 && width < 1100;

                      final horizontalPadding =
                          isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);

                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: isMobile ? 16 : 24,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 900),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHeaderCard(isMobile),
                                SizedBox(height: isMobile ? 12 : 16),
                                _buildStatsRow(isMobile),
                                SizedBox(height: isMobile ? 12 : 16),
                                _buildAboutCard(),
                                SizedBox(height: isMobile ? 12 : 16),
                                _buildSkillsCard(isMobile),
                                if (_certificates().isNotEmpty) ...[
                                  SizedBox(height: isMobile ? 12 : 16),
                                  _buildCertificatesCard(isMobile),
                                ],
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  // ================= HEADER =================

  Widget _buildHeaderCard(bool isMobile) {
    final photo = _profilePhotoUrl();
    final verified = _isVerified();
    final rating = _ratingValue();
    final reviews = _reviewsCount();

    final avatar = GestureDetector(
      onTap: photo != null
          ? () => _openImageViewer(
                items: [_GalleryItem(url: photo, title: _name())],
                initialIndex: 0,
              )
          : null,
      child: Hero(
        tag: 'profile_avatar',
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // ✅ dari orange → teal gradient
            gradient: const LinearGradient(
              colors: [AppColors.primaryTeal, AppColors.mint],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryTeal.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: isMobile ? 42 : 52,
            backgroundColor: AppColors.mint.withOpacity(0.30),
            backgroundImage: photo != null ? NetworkImage(photo) : null,
            onBackgroundImageError: photo != null ? (_, __) {} : null,
            child: photo == null
                ? Icon(
                    Icons.person,
                    size: isMobile ? 50 : 60,
                    color: AppColors.primaryTeal,
                  )
                : null,
          ),
        ),
      ),
    );

    final nameAndRating = Column(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          _name(),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: isMobile ? 20 : 22,
            fontWeight: FontWeight.bold,
            color: AppColors.grey900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            // Rating chip — tetap amber (bintang)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Color(0xFFF59E0B), size: 15),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 1,
                    height: 12,
                    color: AppColors.grey900.withOpacity(0.15),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$reviews Review',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            // Verified chip — tetap hijau (konotasi)
            if (verified)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified,
                        color: Color(0xFF16A34A), size: 14),
                    SizedBox(width: 5),
                    Text(
                      "Terverifikasi",
                      style: TextStyle(
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );

    return _Card(
      child: isMobile
          ? Column(
              children: [
                avatar,
                const SizedBox(height: 14),
                nameAndRating,
              ],
            )
          : Row(
              children: [
                avatar,
                const SizedBox(width: 24),
                Expanded(child: nameAndRating),
              ],
            ),
    );
  }

  // ================= STATS =================

  Widget _buildStatsRow(bool isMobile) {
    final stats = [
      _StatisticCard(
        icon: Icons.check_circle_outline,
        value: "${_get(['jobs_completed'], 0)}",
        title: "Job Selesai",
      ),
      _StatisticCard(
        icon: Icons.thumb_up_alt_outlined,
        value: _get(['satisfaction', 'kepuasan'], '0%').toString(),
        title: "Kepuasan",
      ),
      _StatisticCard(
        icon: Icons.calendar_today_outlined,
        value: "${_get(['joined_year'], '2024')}",
        title: "Bergabung",
      ),
    ];

    final gap = isMobile ? 8.0 : 12.0;

    return Row(
      children: [
        for (int i = 0; i < stats.length; i++) ...[
          Expanded(child: stats[i]),
          if (i != stats.length - 1) SizedBox(width: gap),
        ],
      ],
    );
  }

  // ================= ABOUT =================

  Widget _buildAboutCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Tentang Mitra"),
          const SizedBox(height: 10),
          Text(
            _get(['about', 'bio'], 'Belum ada deskripsi profil.').toString(),
            style: const TextStyle(
              color: AppColors.grey700,
              height: 1.55,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  // ================= SKILLS =================

  Widget _buildSkillsCard(bool isMobile) {
    final skills = _skills();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle("Keahlian"),
              const Spacer(),
              if (skills.isNotEmpty)
                Text(
                  '${skills.length} item',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (skills.isEmpty)
            const Text(
              'Belum ada keahlian terdaftar.',
              style: TextStyle(color: AppColors.grey600, fontSize: 13),
            )
          else
            _buildSkillsContent(skills, isMobile),
        ],
      ),
    );
  }

  Widget _buildSkillsContent(List<dynamic> skills, bool isMobile) {
    final hasPhotos = skills.any((s) =>
        s is Map &&
        ((s['photo_url']?.toString().isNotEmpty ?? false) ||
            (s['photo']?.toString().isNotEmpty ?? false)));

    if (!hasPhotos) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: skills.map<Widget>((skill) {
          final label = skill is Map
              ? (skill['name'] ?? skill['nama'] ?? '-').toString()
              : skill.toString();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.mint.withOpacity(0.15), // ← dari orange soft
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.primaryTeal, // ← teal
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          );
        }).toList(),
      );
    }

    final gallery = _skillGallery();
    final crossAxisCount = isMobile ? 2 : 3;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: skills.length,
      itemBuilder: (context, i) {
        final s = skills[i];
        final name = s is Map
            ? (s['name'] ?? s['nama'] ?? 'Keahlian').toString()
            : s.toString();

        String? url;
        if (s is Map) {
          url = _normalizeUrl(s['photo_url']?.toString()) ??
              _normalizeUrl(s['photo']?.toString());
        }

        final galleryIndex =
            url == null ? -1 : gallery.indexWhere((g) => g.url == url);

        return GestureDetector(
          onTap: url != null && galleryIndex >= 0
              ? () => _openImageViewer(
                    items: gallery,
                    initialIndex: galleryIndex,
                  )
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primaryTeal.withOpacity(0.10),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkTeal.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Hero(
                    tag: 'skill_$i',
                    child: _NetworkImage(
                      url: url,
                      fallbackIcon: Icons.handyman,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    border: Border(
                      top: BorderSide(color: AppColors.grey100),
                    ),
                  ),
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.grey900,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= CERTIFICATES =================

  Widget _buildCertificatesCard(bool isMobile) {
    final certs = _certificates();
    final gallery = _certificateGallery();
    final crossAxisCount = isMobile ? 2 : 3;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle("Sertifikat"),
              const Spacer(),
              Text(
                '${certs.length} item',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.grey500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: certs.length,
            itemBuilder: (context, i) {
              final c = certs[i];
              String title = 'Sertifikat';
              String? url;

              if (c is Map) {
                title =
                    (c['title'] ?? c['name'] ?? c['nama'] ?? 'Sertifikat')
                        .toString();
                url = _normalizeUrl(c['url']?.toString()) ??
                    _normalizeUrl(c['file']?.toString());
              } else if (c is String) {
                url = _normalizeUrl(c);
              }

              final galleryIndex =
                  url == null ? -1 : gallery.indexWhere((g) => g.url == url);

              return GestureDetector(
                onTap: url != null && galleryIndex >= 0
                    ? () => _openImageViewer(
                          items: gallery,
                          initialIndex: galleryIndex,
                        )
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primaryTeal.withOpacity(0.10),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkTeal.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Hero(
                              tag: 'cert_$i',
                              child: _NetworkImage(
                                url: url,
                                fallbackIcon: Icons.workspace_premium,
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.workspace_premium,
                                        color: Colors.white, size: 11),
                                    SizedBox(width: 3),
                                    Text(
                                      'Sertifikat',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          border: Border(
                            top: BorderSide(color: AppColors.grey100),
                          ),
                        ),
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: AppColors.grey900,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.grey900,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// MODEL GALLERY
// ============================================================

class _GalleryItem {
  final String url;
  final String title;
  const _GalleryItem({required this.url, required this.title});
}

// ============================================================
// FULLSCREEN IMAGE VIEWER
// ============================================================

class _ImageViewerScreen extends StatefulWidget {
  final List<_GalleryItem> items;
  final int initialIndex;

  const _ImageViewerScreen({
    required this.items,
    required this.initialIndex,
  });

  @override
  State<_ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<_ImageViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _uiVisible = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleUi() {
    setState(() => _uiVisible = !_uiVisible);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleUi,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.items.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, i) {
                final item = widget.items[i];
                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 5.0,
                  clipBehavior: Clip.none,
                  child: Center(
                    child: Hero(
                      tag: 'viewer_${item.url}',
                      child: Image.network(
                        item.url,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.broken_image,
                                  color: Colors.white54, size: 56),
                              SizedBox(height: 8),
                              Text(
                                'Gagal memuat gambar',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Top bar
            AnimatedOpacity(
              opacity: _uiVisible ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: IgnorePointer(
                ignoring: !_uiVisible,
                child: Container(
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.65),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 26),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_currentIndex + 1} / ${widget.items.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom bar
            AnimatedOpacity(
              opacity: _uiVisible ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: IgnorePointer(
                ignoring: !_uiVisible,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.items[_currentIndex].title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.items.length > 1
                              ? 'Geser untuk melihat lainnya · Cubit untuk zoom'
                              : 'Cubit untuk zoom',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// WIDGET KECIL
// ============================================================

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryTeal.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkTeal.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String title;

  const _StatisticCard({
    required this.icon,
    required this.value,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryTeal.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkTeal.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryTeal, size: 20), // ← teal
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkImage extends StatelessWidget {
  final String? url;
  final IconData fallbackIcon;

  const _NetworkImage({required this.url, required this.fallbackIcon});

  @override
  Widget build(BuildContext context) {
    if (url == null) return _fallback();

    return Image.network(
      url!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.mint.withOpacity(0.15),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryTeal,
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ Gagal load gambar: $url → $error');
        return _fallback();
      },
    );
  }

  Widget _fallback() {
    return Container(
      color: AppColors.mint.withOpacity(0.15),
      child: Center(
        child: Icon(
          fallbackIcon,
          color: AppColors.primaryTeal,
          size: 32,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.grey700),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal, // ← teal
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("Coba Lagi"),
            ),
          ],
        ),
      ),
    );
  }
}