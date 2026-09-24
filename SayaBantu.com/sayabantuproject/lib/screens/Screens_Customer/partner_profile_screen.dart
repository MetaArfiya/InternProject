import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

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

  // Kumpulkan semua skill berfoto → untuk viewer
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
        title = (c['title'] ?? c['name'] ?? c['nama'] ?? 'Sertifikat').toString();
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
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: const Text("Profil Mitra"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onFinish,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? _ErrorView(message: _errorMessage, onRetry: _fetchMitraProfile)
              : RefreshIndicator(
                  onRefresh: _fetchMitraProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeaderCard(),
                        const SizedBox(height: 12),
                        _buildStatsRow(),
                        const SizedBox(height: 12),
                        _buildAboutCard(),
                        const SizedBox(height: 12),
                        _buildSkillsCard(),
                        if (_certificates().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildCertificatesCard(),
                        ],
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: _isLoading || _errorMessage.isNotEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffF97316),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: widget.onFinish,
                    child: const Text(
                      "Selesai",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // ================= HEADER =================

  Widget _buildHeaderCard() {
    final photo = _profilePhotoUrl();
    final verified = _isVerified();
    final rating = _ratingValue();
    final reviews = _reviewsCount();

    return _Card(
      child: Column(
        children: [
          // Avatar dengan border gradient + tappable
          GestureDetector(
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
                  gradient: const LinearGradient(
                    colors: [Color(0xffF97316), Color(0xffFDBA74)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xffF97316).withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: const Color(0xffFFE7D1),
                  backgroundImage: photo != null ? NetworkImage(photo) : null,
                  onBackgroundImageError: photo != null ? (_, __) {} : null,
                  child: photo == null
                      ? const Icon(Icons.person,
                          size: 56, color: Color(0xffF97316))
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _name(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Rating chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 1,
                  height: 12,
                  color: Colors.black.withOpacity(0.15),
                ),
                const SizedBox(width: 6),
                Text(
                  '$reviews Review',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),

          if (verified) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.verified, color: Colors.green, size: 15),
                  SizedBox(width: 6),
                  Text(
                    "Mitra Terverifikasi",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ================= STATS =================

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatisticCard(
            icon: Icons.check_circle_outline,
            value: "${_get(['jobs_completed'], 0)}",
            title: "Job Selesai",
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatisticCard(
            icon: Icons.thumb_up_alt_outlined,
            value: _get(['satisfaction', 'kepuasan'], '0%').toString(),
            title: "Kepuasan",
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatisticCard(
            icon: Icons.calendar_today_outlined,
            value: "${_get(['joined_year'], '2024')}",
            title: "Bergabung",
          ),
        ),
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
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.5,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  // ================= SKILLS =================

  Widget _buildSkillsCard() {
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
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (skills.isEmpty)
            Text(
              'Belum ada keahlian terdaftar.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            )
          else
            _buildSkillsContent(skills),
        ],
      ),
    );
  }

  Widget _buildSkillsContent(List<dynamic> skills) {
    final hasPhotos = skills.any((s) =>
        s is Map &&
        ((s['photo_url']?.toString().isNotEmpty ?? false) ||
            (s['photo']?.toString().isNotEmpty ?? false)));

    if (!hasPhotos) {
      // Chip teks (kalau tidak ada foto sama sekali)
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
              color: const Color(0xffFFE7D1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xffF97316),
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          );
        }).toList(),
      );
    }

    // Gallery items untuk viewer
    final gallery = _skillGallery();

    // Grid 2 kolom, aspect ratio 4:5 (kartu)
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78, // lebih tinggi → foto lebih besar
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

        // Cari index di gallery (untuk viewer)
        final galleryIndex = url == null
            ? -1
            : gallery.indexWhere((g) => g.url == url);

        return GestureDetector(
          onTap: url != null && galleryIndex >= 0
              ? () => _openImageViewer(
                    items: gallery,
                    initialIndex: galleryIndex,
                  )
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Foto skill
                Expanded(
                  child: Hero(
                    tag: 'skill_$i',
                    child: _NetworkImage(
                      url: url,
                      fallbackIcon: Icons.handyman,
                    ),
                  ),
                ),
                // Label nama
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade100),
                    ),
                  ),
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      color: Colors.black87,
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

  Widget _buildCertificatesCard() {
    final certs = _certificates();
    final gallery = _certificateGallery();

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
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: certs.length,
            itemBuilder: (context, i) {
              final c = certs[i];
              String title = 'Sertifikat';
              String? url;

              if (c is Map) {
                title = (c['title'] ??
                        c['name'] ??
                        c['nama'] ??
                        'Sertifikat')
                    .toString();
                url = _normalizeUrl(c['url']?.toString()) ??
                    _normalizeUrl(c['file']?.toString());
              } else if (c is String) {
                url = _normalizeUrl(c);
              }

              final galleryIndex = url == null
                  ? -1
                  : gallery.indexWhere((g) => g.url == url);

              return GestureDetector(
                onTap: url != null && galleryIndex >= 0
                    ? () => _openImageViewer(
                          items: gallery,
                          initialIndex: galleryIndex,
                        )
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Thumbnail sertifikat
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
                            // Badge "sertifikat" kecil
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
                      // Label
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade100),
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
                            color: Colors.black87,
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
            color: const Color(0xffF97316),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
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
            // PageView foto
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

            // Top bar (back + counter)
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

            // Bottom bar (judul gambar)
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
                        if (widget.items.length > 1) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Geser untuk melihat lainnya · Cubit untuk zoom',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 11,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 6),
                          Text(
                            'Cubit untuk zoom',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xffF97316), size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5, color: Colors.grey[600]),
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
          color: Colors.orange.shade50,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xffF97316),
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
      color: Colors.orange.shade50,
      child: Center(
        child: Icon(fallbackIcon, color: const Color(0xffF97316), size: 32),
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
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffF97316),
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