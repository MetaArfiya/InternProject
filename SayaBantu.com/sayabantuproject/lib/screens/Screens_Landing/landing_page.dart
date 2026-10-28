import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/job_model.dart';
import '../../sections/landing/about_section.dart';
import '../../sections/landing/category_section.dart';
import '../../sections/landing/footer_section.dart';
import '../../sections/landing/hero_section.dart';
import '../../sections/landing/how_it_works_section.dart';
import '../../sections/landing/navbar.dart';
import '../../sections/landing/partner_cta_section.dart';
import '../../sections/landing/search_result_section.dart';
import '../../sections/landing/stats_section.dart';
import '../../sections/landing/testimonial_section.dart';
import '../../sections/landing/why_section.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  // ============================================================
  // GLOBAL KEYS
  // ============================================================
  final GlobalKey _layananKey = GlobalKey();
  final GlobalKey _caraKerjaKey = GlobalKey();
  final GlobalKey _mitraKey = GlobalKey();
  final GlobalKey _tentangKey = GlobalKey();
  final GlobalKey _searchResultKey = GlobalKey();

  // ============================================================
  // STATE
  // ============================================================
  String _searchKeyword = '';
  List<JobModel> _filteredJobs = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Debounce untuk mencegah spam API saat user mengetik
  Timer? _debounceTimer;
  // Guard agar tidak setState setelah dispose
  bool _isDisposed = false;

  // ============================================================
  // API BASE URL
  // ============================================================
  String get _baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    return 'http://10.0.2.2:8000/api';
  }

  @override
  void initState() {
    super.initState();
    _fetchJobsFromApi();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // SAFE SETSTATE
  // ============================================================
  void _safeSetState(VoidCallback fn) {
    if (!mounted || _isDisposed) return;
    setState(fn);
  }

  // ============================================================
  // API CALL
  // ============================================================
  Future<void> _fetchJobsFromApi() async {
    _safeSetState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Uri url = Uri.parse('$_baseUrl/jobs/search').replace(
        queryParameters: _searchKeyword.trim().isNotEmpty
            ? {'keyword': _searchKeyword.trim()}
            : null,
      );

      final response = await http.get(
        url,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (_isDisposed) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> jobListJson = [];

        if (decoded is Map<String, dynamic>) {
          final target = decoded['data'] ?? decoded['jobs'] ?? [];
          if (target is List) jobListJson = target;
        } else if (decoded is List) {
          jobListJson = decoded;
        }

        _safeSetState(() {
          _filteredJobs = jobListJson
              .map((json) => JobModel.fromJson(json as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      } else {
        _safeSetState(() {
          _errorMessage =
              'Gagal mengambil data (Kode: ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (_isDisposed) return;
      _safeSetState(() {
        _errorMessage = 'Tidak dapat terhubung ke server. '
            'Pastikan koneksi internet Anda aktif.';
        _isLoading = false;
      });
      debugPrint('Fetch jobs error: $e');
    }
  }

  // ============================================================
  // SEARCH (dengan debounce)
  // ============================================================
  void _searchJob(String keyword) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _safeSetState(() {
        _searchKeyword = keyword;
      });

      _fetchJobsFromApi();

      if (keyword.trim().isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToKey(_searchResultKey);
        });
      }
    });
  }

  // ============================================================
  // SCROLL TO KEY
  // ============================================================
  void _scrollToKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final bool showSearchResult = _searchKeyword.trim().isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ============================
          // NAVBAR
          // ============================
          SliverToBoxAdapter(
            child: CustomNavbar(
              onLayanan: () => _scrollToKey(_layananKey),
              onCaraKerja: () => _scrollToKey(_caraKerjaKey),
              onMitra: () => _scrollToKey(_mitraKey),
              onTentang: () => _scrollToKey(_tentangKey),
            ),
          ),

          // ============================
          // HERO
          // ============================
          SliverToBoxAdapter(
            child: HeroSection(
              onCariJasa: () => _scrollToKey(_layananKey),
              onJadiMitra: () => _scrollToKey(_mitraKey),
              onSearch: _searchJob,
            ),
          ),

          // ============================
          // SEARCH RESULT (kondisional)
          // ============================
          if (showSearchResult)
            SliverToBoxAdapter(
              child: Container(
                key: _searchResultKey,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _buildSearchResult(),
              ),
            ),

          // ============================
          // KATEGORI
          // ============================
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: _layananKey,
              child: const CategorySection(),
            ),
          ),

          // ============================
          // CARA KERJA
          // ============================
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: _caraKerjaKey,
              child: const HowItWorksSection(),
            ),
          ),

          // ============================
          // STATS
          // ============================
          const SliverToBoxAdapter(child: StatsSection()),

          // ============================
          // WHY
          // ============================
          const SliverToBoxAdapter(child: WhySection()),

          // ============================
          // TESTIMONI
          // ============================
          const SliverToBoxAdapter(child: TestimonialSection()),

          // ============================
          // PARTNER CTA (Jadi Mitra)
          // ============================
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: _mitraKey,
              child: PartnerCTASection(
                onDaftarMitra: () => _scrollToKey(_mitraKey),
                onPelajari: () => _scrollToKey(_caraKerjaKey),
              ),
            ),
          ),

          // ============================
          // TENTANG KAMI
          // ============================
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: _tentangKey,
              child: const AboutSection(),
            ),
          ),

          // ============================
          // FOOTER
          // ============================
          const SliverToBoxAdapter(child: FooterSection()),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH RESULT STATE
  // ============================================================
  Widget _buildSearchResult() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchJobsFromApi,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return SearchResultSection(
      jobs: _filteredJobs,
      keyword: _searchKeyword,
    );
  }
}