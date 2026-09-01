import 'dart:convert';
import 'package:flutter/material.dart';

import '../../models/partner_job_model.dart';
import '../../widgets/partner_job_card.dart';
import '../../services/api_service.dart';

class PartnerDashboard extends StatefulWidget {
  final Function(PartnerJobModel) onTakeOffer;

  const PartnerDashboard({
    super.key,
    required this.onTakeOffer,
  });

  @override
  State<PartnerDashboard> createState() => _PartnerDashboardState();
}

class _PartnerDashboardState extends State<PartnerDashboard> {
  List<PartnerJobModel> _jobs = [];
  bool _isLoading = true;
  String _errorMessage = '';

  int _activeOffersCount = 0;
  int _userPoints = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // 🚀 Fetch data lowongan pekerjaan untuk Mitra dari Laravel API
  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiService.get('/mitra/available-jobs');

      debugPrint("🔎 STATUS CODE: ${response.statusCode}");
      debugPrint("🔎 RAW RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        List<dynamic> jobListJson = [];

        if (decodedData is Map<String, dynamic>) {
          var target = decodedData['jobs'] ?? decodedData['data'] ?? [];

          if (target is List) {
            jobListJson = target;
          } else if (target is Map && target.containsKey('data')) {
            // Menangani jika Laravel memakai pagination
            jobListJson = target['data'] is List ? target['data'] : [];
          }
        } else if (decodedData is List) {
          jobListJson = decodedData;
        }

        final List<PartnerJobModel> loadedJobs = jobListJson
            .map((json) => PartnerJobModel.fromJson(json))
            .where((job) => !job.hasOffered)
            .toList();

        if (mounted) {
          setState(() {
            _jobs = loadedJobs;

            // Ekstrak statistik dari response API backend
            if (decodedData is Map) {
              _activeOffersCount = int.tryParse(
                      decodedData['active_offers_count']?.toString() ?? '0') ??
                  0;
              _userPoints = int.tryParse(
                      decodedData['user_points']?.toString() ?? '0') ??
                  0;
            }

            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Gagal memuat data (Status: ${response.statusCode})';
            _isLoading = false;
          });
        }
      }
    } catch (e, stacktrace) {
      debugPrint("❌ ERROR: $e");
      debugPrint("❌ STACKTRACE: $stacktrace");

      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan koneksi: $e';
          _isLoading = false;
        });
      }
    }
  }

  // 🤝 Popup Dialog Konfirmasi sebelum Mengambil / Melamar Pekerjaan
  void _showTakeOfferConfirmation(PartnerJobModel job) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi Penawaran"),
        content: Text(
          "Apakah Anda yakin ingin mengajukan penawaran untuk pekerjaan '${job.title}'?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onTakeOffer(job);
            },
            child: const Text("Ya, Ajukan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final isMobile = width < 600;
        final isTablet = width >= 600 && width < 1000;

        final padding = isMobile
            ? 16.0
            : isTablet
                ? 24.0
                : 30.0;

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section (Tombol Refresh sudah dihapus dari sini)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Lowongan Tersedia",
                    style: TextStyle(
                      fontSize: isMobile ? 24 : 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Temukan pekerjaan yang sesuai dengan keahlianmu.",
                    style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.6),
                      fontSize: isMobile ? 13 : 15,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 📈 Stat Cards Section (Grid Responsif)
              GridView.count(
                crossAxisCount: isMobile
                    ? 1
                    : isTablet
                        ? 2
                        : 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isMobile
                    ? 3.8
                    : isTablet
                        ? 2.8
                        : 2.4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _statCard(
                    Icons.work_outline,
                    "Total Lowongan",
                    _jobs.length.toString(),
                    Colors.blue,
                  ),
                  _statCard(
                    Icons.description_outlined,
                    "Penawaran Aktif",
                    _activeOffersCount.toString(),
                    Colors.orange,
                  ),
                  _statCard(
                    Icons.stars,
                    "Total Poin",
                    _userPoints.toString(),
                    Colors.green,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 📋 Main Content List Section
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _fetchDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text("Coba Lagi"),
            ),
          ],
        ),
      );
    }

    if (_jobs.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            Center(
              child: Text(
                "Belum ada lowongan pekerjaan saat ini.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _jobs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final job = _jobs[index];
          return PartnerJobCard(
            job: job,
            onTakeOffer: () => _showTakeOfferConfirmation(job),
          );
        },
      ),
    );
  }

  Widget _statCard(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}