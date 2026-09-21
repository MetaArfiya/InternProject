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

  // ============================================================
  // STANDARD UI
  // ============================================================

  static const double _bodyFontSize = 13;
  static const double _buttonFontSize = 13;
  static const double _dialogTitleFontSize = 18;
  static const double _smallRadius = 12;

  @override
  void initState() {
    super.initState();
    _fetchMyJobs();
  }

  // ============================================================
  // FETCH DATA
  // ============================================================

  Future<void> _fetchMyJobs() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await ApiService.get('/pelanggan/my-jobs');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List<dynamic> jobListJson = [];

        if (decoded is Map<String, dynamic>) {
          final target = decoded['data'] ?? decoded['jobs'] ?? [];

          if (target is List) {
            jobListJson = target;
          }
        } else if (decoded is List) {
          jobListJson = decoded;
        }

        if (!mounted) return;

        setState(() {
          _jobs = jobListJson
              .map((json) => JobModel.fromJson(json))
              .toList();

          _isLoading = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          _errorMessage =
              'Gagal mengambil data lowongan (Kode: ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Terjadi kesalahan koneksi: $e';
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // SELESAIKAN PEKERJAAN
  // ============================================================

  Future<void> _completeJob(JobModel job) async {
    try {
      final response =
          await ApiService.post('/jobs/${job.id}/complete', {});

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Pekerjaan berhasil diselesaikan!',
                style: TextStyle(
                  fontSize: _bodyFontSize,
                ),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        _fetchMyJobs();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal menyelesaikan pekerjaan (${response.statusCode})',
                style: const TextStyle(
                  fontSize: _bodyFontSize,
                ),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Terjadi kesalahan: $e',
              style: const TextStyle(
                fontSize: _bodyFontSize,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================
  // TAMBAH PEKERJAAN
  // ============================================================

  void addJob(JobModel job) {
    setState(() {
      _jobs.insert(0, job);
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final totalJobs = _jobs.length;

    final runningJobs = _jobs
        .where(
          (job) =>
              job.status.toLowerCase() == 'sedang dikerjakan' ||
              job.status.toLowerCase() == 'proses' ||
              job.status.toLowerCase() == 'dalam pengerjaan',
        )
        .length;

    final completedJobs = _jobs
        .where(
          (job) => job.status.toLowerCase() == 'selesai',
        )
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: EdgeInsets.all(isMobile ? 16 : 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ======================================================
              // HEADER
              // ======================================================

              DashboardHeader(
                onAddJob: (newJob) {
                  addJob(newJob);
                  _fetchMyJobs();
                },
              ),

              SizedBox(
                height: isMobile ? 20 : 24,
              ),

              // ======================================================
              // STATISTIC
              // ======================================================

              if (isMobile)
                Column(
                  children: [
                    StatisticCard(
                      icon: Icons.assignment,
                      value: totalJobs.toString(),
                      title: 'Total Posting',
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    StatisticCard(
                      icon: Icons.settings,
                      value: runningJobs.toString(),
                      title: 'Sedang Berjalan',
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    StatisticCard(
                      icon: Icons.check_circle,
                      value: completedJobs.toString(),
                      title: 'Selesai',
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
                        title: 'Total Posting',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StatisticCard(
                        icon: Icons.settings,
                        value: runningJobs.toString(),
                        title: 'Sedang Berjalan',
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StatisticCard(
                        icon: Icons.check_circle,
                        value: completedJobs.toString(),
                        title: 'Selesai',
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

              SizedBox(
                height: isMobile ? 20 : 24,
              ),

              // ======================================================
              // DAFTAR PEKERJAAN
              // ======================================================

              Expanded(
                child: _buildJobContent(isMobile),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // JOB CONTENT
  // ============================================================

  Widget _buildJobContent(bool isMobile) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.orange,
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_jobs.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      itemCount: _jobs.length,
      separatorBuilder: (_, __) => SizedBox(
        height: isMobile ? 12 : 16,
      ),
      itemBuilder: (context, index) {
        final job = _jobs[index];

        return JobCard(
          job: job,
          onRefresh: _fetchMyJobs,
          onOpenOffer: widget.onOpenOffer,
          onComplete: (selectedJob) {
            _showCompleteConfirmation(selectedJob);
          },
        );
      },
    );
  }

  // ============================================================
  // KONFIRMASI SELESAI
  // ============================================================

  void _showCompleteConfirmation(JobModel selectedJob) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Konfirmasi Selesai',
            style: TextStyle(
              fontSize: _dialogTitleFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            "Apakah pekerjaan '${selectedJob.title}' sudah selesai dikerjakan?",
            style: const TextStyle(
              fontSize: _bodyFontSize,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontSize: _buttonFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_smallRadius),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                _completeJob(selectedJob);
              },
              child: const Text(
                'Ya, Selesai',
                style: TextStyle(
                  fontSize: _buttonFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Terjadi kesalahan.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: _bodyFontSize,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchMyJobs,
              icon: const Icon(
                Icons.refresh,
                size: 18,
              ),
              label: const Text(
                'Coba Lagi',
                style: TextStyle(
                  fontSize: _buttonFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_smallRadius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 52,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada pekerjaan yang diposting.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: _bodyFontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}