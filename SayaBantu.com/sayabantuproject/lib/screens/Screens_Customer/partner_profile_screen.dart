import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class PartnerProfileScreen extends StatefulWidget {
  final VoidCallback onFinish;
  final int mitraId; // ID Mitra untuk mengambil data dinamis

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
    try {
      // Memanggil method GET dari ApiService yang sudah Anda miliki
      // Otomatis menyertakan baseURL dan Header Authorization token
      final response = await ApiService.get('/mitra/${widget.mitraId}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          setState(() {
            _profileData = jsonResponse['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = jsonResponse['message'] ?? 'Gagal memuat data.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = "Gagal terhubung ke server (Kode: ${response.statusCode})";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Profil Mitra"),
        centerTitle: true,
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Colors.black,
        elevation: 0,
        // 1. Matikan tombol back bawaan otomatis
        automaticallyImplyLeading: false, 
        // 2. Buat tombol panah kiri kustom yang memanggil callback 'onFinish'
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onFinish, // Mengembalikan ke menu penawaran
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(_errorMessage, textAlign: TextAlign.center),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // FOTO PROFIL
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Color(0xffFFE7D1),
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Color(0xffF97316),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // NAMA MITRA
                      Text(
                        _profileData?['name'] ?? 'Mitra',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // RATING & REVIEW COUNT
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            "${_profileData?['rating'] ?? 0.0} (${_profileData?['reviews_count'] ?? 0} Review)",
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // STATUS VERIFIKASI
                      if (_profileData?['verified'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                color: Colors.green,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "Mitra Terverifikasi",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      // STATISTIK
                      Row(
                        children: [
                          Expanded(
                            child: _StatisticCard(
                              value: "${_profileData?['jobs_completed'] ?? 0}",
                              title: "Job Selesai",
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatisticCard(
                              value: _profileData?['satisfaction'] ?? '0%',
                              title: "Kepuasan",
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatisticCard(
                              value: "${_profileData?['joined_year'] ?? '2024'}",
                              title: "Bergabung",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // TENTANG / BIO
                      _sectionTitle("Tentang Mitra"),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _profileData?['about'] ?? 'Belum ada deskripsi profil.',
                          style: TextStyle(color: Colors.grey[700], height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // KEAHLIAN (SKILLS)
                      _sectionTitle("Keahlian"),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (_profileData?['skills'] as List<dynamic>? ?? [])
                              .map<Widget>((skill) => Chip(
                                    label: Text(skill.toString()),
                                    backgroundColor: Colors.orange.shade50,
                                    labelStyle: const TextStyle(color: Color(0xffF97316)),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // TOMBOL SELESAI
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffF97316),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: widget.onFinish,
                          child: const Text(
                            "Selesai",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final String value;
  final String title;

  const _StatisticCard({
    required this.value,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xffF97316),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}