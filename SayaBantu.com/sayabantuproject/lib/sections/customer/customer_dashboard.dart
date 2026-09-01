import 'dart:convert';
import 'package:flutter/material.dart';

import '../../models/job_model.dart';
import '../../services/api_service.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/pekerjaan_card.dart';
import '../../widgets/statistic_card.dart';

class CustomerDashboard extends StatefulWidget {
  final Function(JobModel) onOpenOffer;

  const CustomerDashboard({
    super.key,
    required this.onOpenOffer,
  });

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  List<JobModel> _jobs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMyJobs();
  }

  // 🚀 Fetch data lowongan dari Backend API
  Future<void> _fetchMyJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.get('/pelanggan/my-jobs');

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
          _jobs = jobListJson
              .map((json) => JobModel.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              "Gagal mengambil data lowongan (Kode: ${response.statusCode})";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Terjadi kesalahan koneksi: $e";
        _isLoading = false;
      });
    }
  }

  // 🤝 Mengubah status pekerjaan menjadi Selesai via API
  Future<void> _completeJob(JobModel job) async {
    try {
      final response = await ApiService.post('/jobs/${job.id}/complete', {});

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Pekerjaan berhasil diselesaikan!"),
              backgroundColor: Colors.green,
            ),
          );
        }
        _fetchMyJobs(); // Refresh data dari server
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal menyelesaikan pekerjaan (${response.statusCode})"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Terjadi kesalahan: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void addJob(JobModel job) {
    setState(() {
      _jobs.insert(0, job);
    });
  }

  @override
  Widget build(BuildContext context) {
    final int totalJobs = _jobs.length;

    final int runningJobs = _jobs
        .where((job) =>
            job.status.toLowerCase() == "sedang dikerjakan" ||
            job.status.toLowerCase() == "proses" ||
            job.status.toLowerCase() == "dalam pengerjaan")
        .length;

    final int completedJobs = _jobs
        .where((job) => job.status.toLowerCase() == "selesai")
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: EdgeInsets.all(isMobile ? 16 : 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardHeader(
                onAddJob: (newJob) {
                  addJob(newJob);
                  _fetchMyJobs();
                },
              ),

              SizedBox(height: isMobile ? 20 : 30),

              // 📈 Kartu Statistik (Responsif Layout: Column di HP, Row di Desktop)
              if (isMobile)
                Column(
                  children: [
                    StatisticCard(
                      icon: Icons.assignment,
                      value: totalJobs.toString(),
                      title: "Total Posting",
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    StatisticCard(
                      icon: Icons.settings,
                      value: runningJobs.toString(),
                      title: "Sedang Berjalan",
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    StatisticCard(
                      icon: Icons.check_circle,
                      value: completedJobs.toString(),
                      title: "Selesai",
                      color: Colors.green,
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: StatisticCard(
                        icon: Icons.assignment,
                        value: totalJobs.toString(),
                        title: "Total Posting",
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: StatisticCard(
                        icon: Icons.settings,
                        value: runningJobs.toString(),
                        title: "Sedang Berjalan",
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: StatisticCard(
                        icon: Icons.check_circle,
                        value: completedJobs.toString(),
                        title: "Selesai",
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

              SizedBox(height: isMobile ? 20 : 30),

              // 📋 List View dengan penanganan State API
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _fetchMyJobs,
                                  child: const Text("Coba Lagi"),
                                ),
                              ],
                            ),
                          )
                        : _jobs.isEmpty
                            ? const Center(
                                child: Text(
                                  "Belum ada pekerjaan yang diposting.",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.separated(
                                itemCount: _jobs.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(height: isMobile ? 12 : 18),
                                itemBuilder: (context, index) {
                                  final job = _jobs[index];
                                  return JobCard(
                                    job: job,
                                    onRefresh: _fetchMyJobs,
                                    onOpenOffer: widget.onOpenOffer,
                                    onComplete: (selectedJob) {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text("Konfirmasi Selesai"),
                                          content: Text(
                                            "Apakah pekerjaan '${selectedJob.title}' sudah selesai dikerjakan?",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text("Batal"),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                _completeJob(selectedJob);
                                              },
                                              child: const Text("Ya, Selesai"),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
              ),
            ],
          ),
        );
      },
    );
  }
}