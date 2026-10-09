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
  final ScrollController _scrollController = ScrollController();

  String _searchKeyword = '';
  List<JobModel> _filteredJobs = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ============================================================
  // GLOBAL KEYS
  // ============================================================
  final GlobalKey _layananKey = GlobalKey();
  final GlobalKey _caraKerjaKey = GlobalKey();
  final GlobalKey _mitraKey = GlobalKey();
  final GlobalKey _tentangKey = GlobalKey();
  final GlobalKey _searchResultKey = GlobalKey();

  // ============================================================
  // API BASE URL — konsisten dengan hero_left & hero_right
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
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // API CALL
  // ============================================================
  Future<void> _fetchJobsFromApi() async {
    setState(() {
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

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> jobListJson = [];

        if (decoded is Map<String, dynamic>) {
          final target = decoded['data'] ?? decoded['jobs'] ?? [];
          if (target is List) jobListJson = target;
        } else if (decoded is List) {
          jobListJson = decoded;
        }

        setState(() {
          _filteredJobs =
              jobListJson.map((json) => JobModel.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Gagal mengambil data (Kode: ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan koneksi ke backend: $e';
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================
  void _searchJob(String keyword) {
    setState(() {
      _searchKeyword = keyword;
    });

    _fetchJobsFromApi();

    if (keyword.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToKey(_searchResultKey);
      });
    }
  }

  // ============================================================
  // SCROLL TO KEY
  // ============================================================
  void _scrollToKey(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
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
    return Scaffold(
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // ============================
            // NAVBAR
            // ============================
            CustomNavbar(
              onLayanan: () => _scrollToKey(_layananKey),
              onCaraKerja: () => _scrollToKey(_caraKerjaKey),
              onMitra: () => _scrollToKey(_mitraKey),
              onTentang: () => _scrollToKey(_tentangKey),
            ),

            // ============================
            // HERO
            // ============================
            HeroSection(
              onCariJasa: () => _scrollToKey(_layananKey),
              onJadiMitra: () => _scrollToKey(_mitraKey),
              onSearch: _searchJob,
            ),

            // ============================
            // SEARCH RESULT (kondisional)
            // ============================
            if (_searchKeyword.isNotEmpty)
              KeyedSubtree(
                key: _searchResultKey,
                child: _buildSearchResult(),
              ),

            // ============================
            // KATEGORI
            // ============================
            KeyedSubtree(
              key: _layananKey,
              child: const CategorySection(),
            ),

            // ============================
            // CARA KERJA
            // ============================
            KeyedSubtree(
              key: _caraKerjaKey,
              child: const HowItWorksSection(),
            ),

            // ============================
            // STATS
            // ============================
            const StatsSection(),

            // ============================
            // WHY
            // ============================
            const WhySection(),

            // ============================
            // TESTIMONI
            // ============================
            const TestimonialSection(),

            // ============================
            // PARTNER CTA (Jadi Mitra)
            // ============================
            KeyedSubtree(
              key: _mitraKey,
              child: PartnerCTASection(
                onDaftarMitra: () => _scrollToKey(_mitraKey),
                onPelajari: () => _scrollToKey(_caraKerjaKey),
              ),
            ),

            // ============================
            // TENTANG KAMI (BARU)
            // ============================
            KeyedSubtree(
              key: _tentangKey,
              child: const AboutSection(),
            ),

            // ============================
            // FOOTER
            // ============================
            const FooterSection(),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _fetchJobsFromApi,
                child: const Text('Coba Lagi'),
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