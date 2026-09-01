import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/job_model.dart';
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
  final ScrollController scrollController = ScrollController();

  String searchKeyword = "";
  List<JobModel> filteredJobs = [];
  
  bool _isLoading = false;
  String? _errorMessage;

  final GlobalKey layananKey = GlobalKey();
  final GlobalKey caraKerjaKey = GlobalKey();
  final GlobalKey mitraKey = GlobalKey();
  final GlobalKey tentangKey = GlobalKey();
  final GlobalKey searchResultKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchJobsFromApi();
  }

  // 🚀 Fungsi Mengambil Data dari API Laravel
  Future<void> _fetchJobsFromApi() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    // Gunakan 'localhost' atau IP LAN komputer jika dites via perangkat lain
    final Uri url = Uri.parse('http://localhost:8000/api/jobs/search').replace(
      queryParameters: searchKeyword.trim().isNotEmpty
          ? {'keyword': searchKeyword.trim()}
          : null,
    );

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      List<dynamic> jobListJson = [];

      if (decoded is Map<String, dynamic>) {
        var target = decoded['data'] ?? decoded['jobs'] ?? [];
        if (target is List) {
          jobListJson = target;
        }
      } else if (decoded is List) {
        jobListJson = decoded;
      }

      setState(() {
        filteredJobs = jobListJson
            .map((json) => JobModel.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = "Gagal mengambil data (Kode: ${response.statusCode})";
        _isLoading = false;
      });
    }
  } catch (e) {
    setState(() {
      _errorMessage = "Terjadi kesalahan koneksi ke backend: $e";
      _isLoading = false;
    });
  }
}

void searchJob(String keyword) {
  setState(() {
    searchKeyword = keyword;
  });

  // Panggil API pencarian
  _fetchJobsFromApi();

  // Otomatis scroll ke section hasil pencarian jika keyword tidak kosong
  if (keyword.trim().isNotEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = searchResultKey.currentContext;

      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      }
    });
  }
}

  void scrollTo(GlobalKey key) {
    final context = key.currentContext;

    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          children: [
            CustomNavbar(
              onLayanan: () => scrollTo(layananKey),
              onCaraKerja: () => scrollTo(caraKerjaKey),
              onMitra: () => scrollTo(mitraKey),
              onTentang: () => scrollTo(tentangKey),
            ),

            HeroSection(
              onCariJasa: () => scrollTo(layananKey),
              onJadiMitra: () => scrollTo(mitraKey),
              onSearch: searchJob,
            ),

            // 📋 Section Hasil Pencarian (dengan Loading & Error State)
            if (searchKeyword.isNotEmpty)
              KeyedSubtree(
                key: searchResultKey,
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _errorMessage != null
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: _fetchJobsFromApi,
                                    child: const Text("Coba Lagi"),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SearchResultSection(
                            jobs: filteredJobs,
                            keyword: searchKeyword,
                          ),
              ),

            KeyedSubtree(
              key: layananKey,
              child: const CategorySection(),
            ),

            KeyedSubtree(
              key: caraKerjaKey,
              child: const HowItWorksSection(),
            ),

            const StatsSection(),
            const WhySection(),
            const TestimonialSection(),

            KeyedSubtree(
              key: mitraKey,
              child: PartnerCTASection(
                onDaftarMitra: () => scrollTo(mitraKey),
                onPelajari: () => scrollTo(caraKerjaKey),
              ),
            ),

            KeyedSubtree(
              key: tentangKey,
              child: const FooterSection(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}