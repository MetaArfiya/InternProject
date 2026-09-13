// lib/screens/Screens_Admin/admin_verification_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';

import '../../data/admin_activity_data.dart';
import '../../services/api_service.dart';

class AdminVerificationScreen extends StatefulWidget {
  final ValueChanged<int>? onPendingCountChanged;

  const AdminVerificationScreen({
    super.key,
    this.onPendingCountChanged,
  });

  @override
  State<AdminVerificationScreen> createState() =>
      _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen> {
  // =========================================================
  // STATE
  // =========================================================

  List<Map<String, dynamic>> partners = [];

  bool isLoading = true;
  bool isProcessing = false;

  int waitingCount = 0;
  int approvedToday = 0;
  int rejected = 0;

  int? adminId;

  // =========================================================
  // INIT STATE
  // =========================================================

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  // =========================================================
  // INITIALIZE
  // =========================================================

  Future<void> _initialize() async {
    await _getAdminId();
    await _fetchUnverifiedMitra();
  }

  // =========================================================
  // GET ADMIN LOGIN
  // =========================================================

  Future<void> _getAdminId() async {
    try {
      final response = await ApiService.get('/user');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        dynamic userData;
        if (decoded is Map) {
          userData = decoded['data'] ?? decoded['user'];
        }

        if (userData is Map) {
          final dynamic id = userData['id'];
          if (id != null) {
            adminId = int.tryParse(id.toString());
          }
        }
      }
    } catch (e) {
      debugPrint('GET ADMIN ID ERROR: $e');
    }
  }

  // =========================================================
  // GET MITRA BELUM TERVERIFIKASI
  // =========================================================

  Future<void> _fetchUnverifiedMitra() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.get('/admin/unverified-mitra');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is! Map) {
          throw Exception('Format response API tidak valid.');
        }

        // =====================================================
        // STATISTIK
        // =====================================================

        final dynamic statistics = decoded['statistics'];

        if (statistics is Map) {
          waitingCount = int.tryParse(
                statistics['menunggu']?.toString() ?? '0',
              ) ??
              0;

          approvedToday = int.tryParse(
                statistics['disetujui_hari_ini']?.toString() ?? '0',
              ) ??
              0;

          rejected = int.tryParse(
                statistics['ditolak']?.toString() ?? '0',
              ) ??
              0;
        }

        // =====================================================
        // DATA MITRA
        // =====================================================

        final dynamic rawData = decoded['data'];
        final List<dynamic> data = rawData is List ? rawData : [];

        final List<Map<String, dynamic>> mappedPartners =
            data.map<Map<String, dynamic>>((item) {
          final Map<String, dynamic> mitra = item is Map<String, dynamic>
              ? item
              : Map<String, dynamic>.from(item);

          // USER
          final dynamic rawUser = mitra['user'];
          final Map<String, dynamic> user = rawUser is Map
              ? Map<String, dynamic>.from(rawUser)
              : {};

          // ID
          final dynamic id = mitra['id'];

          // NAMA
          final String name = user['name']?.toString() ??
              mitra['name']?.toString() ??
              'Tanpa Nama';

          // EMAIL
          final String email = user['email']?.toString() ??
              mitra['email']?.toString() ??
              'Tanpa Email';

          // KATEGORI
          final String category = mitra['skills']?.toString() ??
              mitra['category']?.toString() ??
              'Umum';

          // KOTA
          final String city = user['city']?.toString() ??
              mitra['city']?.toString() ??
              user['address']?.toString() ??
              mitra['address']?.toString() ??
              'Indonesia';

          // DOKUMEN
          final dynamic verificationImage = mitra['verification_image'];
          final dynamic selfieImage = mitra['selfie_image'];
          final dynamic rawCertificate = mitra['certificate'];
          final dynamic rawSkillPhotos = mitra['skill_photos'];
          final dynamic rawProfilePhoto = user['photo_profile'];

          // Hitung dokumen valid
          bool hasKtp = verificationImage != null &&
              verificationImage.toString().isNotEmpty &&
              verificationImage.toString() != 'null';

          bool hasCertificate = false;
          if (rawCertificate is List) {
            hasCertificate = rawCertificate.isNotEmpty;
          } else if (rawCertificate != null) {
            hasCertificate = rawCertificate.toString().isNotEmpty &&
                rawCertificate.toString() != 'null';
          }

          final List<Map<String, dynamic>> documents = [
            {
              'title': 'KTP / Identitas',
              'valid': hasKtp,
            },
            {
              'title': 'Bukti Keahlian',
              'valid': hasCertificate,
            },
          ];

          return {
            'id': id,
            'name': name,
            'email': email,
            'category': category,
            'city': city,
            'time': _formatTime(mitra['created_at']),
            'created_at': mitra['created_at'],
            'documents': documents,
            // Semua path gambar
            'verification_image': verificationImage,
            'selfie_image': selfieImage,
            'certificate': rawCertificate,
            'skill_photos': rawSkillPhotos,
            'profile_photo': rawProfilePhoto,
            'user': user,
          };
        }).toList();

        setState(() {
          partners = mappedPartners;
          isLoading = false;
        });

        _syncPending();
      } else {
        setState(() {
          isLoading = false;
        });

        _message(_getErrorMessage(response), error: true);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _message('Gagal terhubung ke server.', error: true);
      debugPrint('FETCH UNVERIFIED MITRA ERROR: $e');
    }
  }

  // =========================================================
  // BUILD IMAGE URL — FIX
  // =========================================================
  String _buildImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty || rawPath == 'null') {
      return '';
    }

    // 1. Full URL → pakai langsung
    if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
      return rawPath;
    }

    // 2. Normalisasi: hapus leading "/" biar konsisten
    String normalized = rawPath;
    if (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }

    // 3. Base URL (ganti sesuai environment)
    const baseUrl = 'http://127.0.0.1:8000';

    // 4. Cek folder (TANPA leading slash)
    if (normalized.startsWith('profile_photos/')) {
      final filename = normalized.substring('profile_photos/'.length);
      return '$baseUrl/api/images/profile/$filename';
    }
    if (normalized.startsWith('certificates/')) {
      final filename = normalized.substring('certificates/'.length);
      return '$baseUrl/api/images/certificates/$filename';
    }
    if (normalized.startsWith('skill_photos/')) {
      final filename = normalized.substring('skill_photos/'.length);
      return '$baseUrl/api/images/skill_photos/$filename';
    }
    if (normalized.startsWith('completion_proofs/')) {
      final filename = normalized.substring('completion_proofs/'.length);
      return '$baseUrl/api/images/completion_proofs/$filename';
    }

    // 5. Cek kalau path ada prefix "storage/"
    if (normalized.startsWith('storage/')) {
      normalized = normalized.substring('storage/'.length);
      return _buildImageUrl(normalized);
    }

    // 6. Fallback — anggap profile_photos
    final filename = normalized.split('/').last;
    return '$baseUrl/api/images/profile/$filename';
  }

  // =========================================================
  // OPEN FULLSCREEN IMAGE
  // =========================================================

  void _openFullScreenImage(
    BuildContext context,
    String imageUrl,
    String title,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullScreenImageViewer(
          imageUrl: imageUrl,
          title: title,
        ),
      ),
    );
  }

  // =========================================================
  // CHECK DOKUMEN
  // =========================================================

  bool _documentsComplete(Map<String, dynamic> partner) {
    final List<dynamic> documents =
        partner['documents'] as List<dynamic>? ?? [];

    if (documents.isEmpty) {
      return false;
    }

    return documents.every(
      (doc) => doc is Map && doc['valid'] == true,
    );
  }

  // =========================================================
  // APPROVE
  // =========================================================

  Future<void> _approve(int index) async {
    if (index < 0 || index >= partners.length) return;
    if (isProcessing) return;

    if (adminId == null) {
      _message('ID admin tidak ditemukan. Silakan login ulang.', error: true);
      return;
    }

    final partner = partners[index];
    final dynamic id = partner['id'];
    final String name = partner['name']?.toString() ?? 'Mitra';

    if (id == null) {
      _message('ID mitra tidak ditemukan.', error: true);
      return;
    }

    if (!_documentsComplete(partner)) {
      _message('Berkas $name belum lengkap atau belum valid.', error: true);
      return;
    }

    final bool ok = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Approve Mitra'),
              content: Text(
                'Yakin ingin memverifikasi $name?\n\n'
                'Pastikan identitas dan bukti keahlian sudah sesuai.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  icon: const Icon(Icons.check, size: 17),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!ok || !mounted) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final response = await ApiService.post(
        '/admin/verify-mitra/$id',
        {
          'admin_id': adminId,
          'action': 'approve',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          partners.removeAt(index);
          isProcessing = false;
          waitingCount = partners.length;
          approvedToday++;
        });

        _syncPending();

        AdminActivityData.addApprovedPartner(name: name);

        _message('$name berhasil diverifikasi.');
      } else {
        setState(() {
          isProcessing = false;
        });

        _message(_getErrorMessage(response), error: true);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      _message('Terjadi kesalahan saat memverifikasi mitra.', error: true);
      debugPrint('APPROVE MITRA ERROR: $e');
    }
  }

  // =========================================================
  // REJECT
  // =========================================================

  Future<void> _reject(int index) async {
    if (index < 0 || index >= partners.length) return;
    if (isProcessing) return;

    if (adminId == null) {
      _message('ID admin tidak ditemukan. Silakan login ulang.', error: true);
      return;
    }

    final partner = partners[index];
    final dynamic id = partner['id'];
    final String name = partner['name']?.toString() ?? 'Mitra';

    if (id == null) {
      _message('ID mitra tidak ditemukan.', error: true);
      return;
    }

    final String? reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final controller = TextEditingController();

        return AlertDialog(
          title: const Text('Tolak Pendaftaran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Berikan alasan penolakan untuk $name.'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'Contoh: KTP tidak jelas atau bukti keahlian tidak sesuai.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.dispose();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                controller.dispose();
                Navigator.of(dialogContext).pop(text);
              },
              icon: const Icon(Icons.close, size: 17),
              label: const Text('Reject'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (reason == null || !mounted) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final response = await ApiService.post(
        '/admin/verify-mitra/$id',
        {
          'admin_id': adminId,
          'action': 'reject',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          partners.removeAt(index);
          isProcessing = false;
          waitingCount = partners.length;
          rejected++;
        });

        _syncPending();

        _message('$name ditolak.', error: true);
      } else {
        setState(() {
          isProcessing = false;
        });

        _message(_getErrorMessage(response), error: true);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      _message('Terjadi kesalahan saat menolak mitra.', error: true);
      debugPrint('REJECT MITRA ERROR: $e');
    }
  }

  // =========================================================
  // VIEW DOCUMENTS — TAMPILKAN SEMUA GAMBAR
  // =========================================================

  void _viewDocuments(Map<String, dynamic> partner) {
    // Ambil semua path
    final String? profilePhoto = partner['profile_photo']?.toString();
    final String? verificationImage = partner['verification_image']?.toString();
    final String? selfieImage = partner['selfie_image']?.toString();
    final dynamic certificateRaw = partner['certificate'];
    final dynamic skillPhotosRaw = partner['skill_photos'];

    final List<Map<String, dynamic>> docs = [];

    // 1. Foto Profil
    if (profilePhoto != null &&
        profilePhoto.isNotEmpty &&
        profilePhoto != 'null') {
      docs.add({
        'title': 'Foto Profil',
        'path': profilePhoto,
        'icon': Icons.person,
      });
    }

    // 2. KTP
    if (verificationImage != null &&
        verificationImage.isNotEmpty &&
        verificationImage != 'null') {
      docs.add({
        'title': 'KTP / Identitas',
        'path': verificationImage,
        'icon': Icons.credit_card,
      });
    }

    // 3. Selfie
    if (selfieImage != null && selfieImage.isNotEmpty && selfieImage != 'null') {
      docs.add({
        'title': 'Foto Verifikasi Diri (Selfie)',
        'path': selfieImage,
        'icon': Icons.camera_front,
      });
    }

    // 4. Sertifikat (bisa multiple)
    if (certificateRaw != null) {
      if (certificateRaw is List) {
        for (int i = 0; i < certificateRaw.length; i++) {
          final cert = certificateRaw[i].toString();
          if (cert.isNotEmpty && cert != 'null') {
            docs.add({
              'title': 'Sertifikat ${i + 1}',
              'path': cert,
              'icon': Icons.assignment,
            });
          }
        }
      } else {
        final cert = certificateRaw.toString();
        if (cert.isNotEmpty && cert != 'null') {
          docs.add({
            'title': 'Sertifikat',
            'path': cert,
            'icon': Icons.assignment,
          });
        }
      }
    }

    // 5. Foto Keahlian (bisa multiple)
    if (skillPhotosRaw != null) {
      if (skillPhotosRaw is List) {
        for (int i = 0; i < skillPhotosRaw.length; i++) {
          final photo = skillPhotosRaw[i].toString();
          if (photo.isNotEmpty && photo != 'null') {
            docs.add({
              'title': 'Foto Keahlian ${i + 1}',
              'path': photo,
              'icon': Icons.handyman,
            });
          }
        }
      } else {
        final photo = skillPhotosRaw.toString();
        if (photo.isNotEmpty && photo != 'null') {
          docs.add({
            'title': 'Foto Keahlian',
            'path': photo,
            'icon': Icons.handyman,
          });
        }
      }
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.folder_open, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Berkas ${partner['name'] ?? 'Mitra'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      '${docs.length} berkas',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: docs.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder_off_outlined,
                          size: 48,
                          color: Color(0xFFCBD5E1),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Mitra belum mengunggah berkas apapun.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: docs.asMap().entries.map<Widget>((entry) {
                        final doc = entry.value;
                        final url = _buildImageUrl(doc['path']?.toString());
                        final title = doc['title']?.toString() ?? 'Dokumen';
                        final iconData =
                            doc['icon'] as IconData? ?? Icons.image_outlined;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Label + icon
                              Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0EAFE),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      iconData,
                                      size: 14,
                                      color: const Color(0xFF8B5CF6),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Gambar
                              if (url.isNotEmpty)
                                GestureDetector(
                                  onTap: () => _openFullScreenImage(
                                    context,
                                    url,
                                    title,
                                  ),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        child: Image.network(
                                          url,
                                          width: double.infinity,
                                          height: 200,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child,
                                              progress) {
                                            if (progress == null) {
                                              return child;
                                            }
                                            return Container(
                                              width: double.infinity,
                                              height: 200,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            width: double.infinity,
                                            height: 200,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF2F2),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: const Color(0xFFFCA5A5),
                                              ),
                                            ),
                                            child: const Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.broken_image_outlined,
                                                  size: 42,
                                                  color: Color(0xFFEF4444),
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'Gagal memuat gambar',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFFEF4444),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withOpacity(0.6),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.zoom_in,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Perbesar',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Path gambar tidak valid',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // SYNC PENDING
  // =========================================================

  void _syncPending() {
    AdminActivityData.setPendingPartnerCount(partners.length);
    widget.onPendingCountChanged?.call(partners.length);
  }

  // =========================================================
  // ERROR MESSAGE
  // =========================================================

  String _getErrorMessage(dynamic response) {
    try {
      final body = jsonDecode(response.body);

      if (body is Map) {
        if (body['message'] != null) {
          return body['message'].toString();
        }
        if (body['error'] != null) {
          return body['error'].toString();
        }
        if (body['errors'] is Map) {
          final errors = body['errors'] as Map;
          if (errors.isNotEmpty) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              return firstError.first.toString();
            }
          }
        }
      }
    } catch (_) {}

    switch (response.statusCode) {
      case 400:
        return 'Permintaan tidak valid.';
      case 401:
        return 'Token tidak valid atau sesi login telah berakhir.';
      case 403:
        return 'Anda tidak memiliki akses untuk melakukan tindakan ini.';
      case 404:
        return 'Endpoint atau data mitra tidak ditemukan.';
      case 422:
        return 'Data yang dikirim tidak valid.';
      case 500:
        return 'Terjadi kesalahan pada server Laravel.';
      default:
        return 'Request gagal (${response.statusCode}).';
    }
  }

  // =========================================================
  // FORMAT TIME
  // =========================================================

  String _formatTime(dynamic createdAt) {
    if (createdAt == null) return 'Baru saja';

    try {
      final date = DateTime.parse(createdAt.toString());
      final difference = DateTime.now().difference(date);

      if (difference.isNegative) return 'Baru saja';
      if (difference.inMinutes < 1) return 'Baru saja';
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} menit lalu';
      }
      if (difference.inHours < 24) {
        return '${difference.inHours} jam lalu';
      }
      if (difference.inDays < 7) {
        return '${difference.inDays} hari lalu';
      }

      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'Baru saja';
    }
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _message(String text, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              error ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        ),
      );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AdminActivityData.instance,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final mobile = constraints.maxWidth < 700;
          final tablet =
              constraints.maxWidth >= 700 && constraints.maxWidth < 1100;

          return Container(
            color: const Color(0xFFF4F7FB),
            width: double.infinity,
            height: double.infinity,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchUnverifiedMitra,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        mobile ? 16 : 26,
                        mobile ? 18 : 28,
                        mobile ? 16 : 26,
                        30,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verifikasi Mitra Baru',
                            style: TextStyle(
                              fontSize: mobile
                                  ? 23
                                  : tablet
                                      ? 25
                                      : 27,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '$waitingCount mitra menunggu persetujuan',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 22),
                          _summary(mobile),
                          const SizedBox(height: 20),
                          partners.isEmpty ? _empty() : _table(mobile),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  // =========================================================
  // SUMMARY
  // =========================================================

  Widget _summary(bool mobile) {
    final cards = [
      _summaryCard(
        'Menunggu',
        waitingCount.toString(),
        'Perlu Ditinjau',
        Icons.hourglass_empty,
        const Color(0xFFF59E0B),
        const Color(0xFFFFF7ED),
      ),
      _summaryCard(
        'Disetujui Hari Ini',
        approvedToday.toString(),
        'Mitra Disetujui',
        Icons.check_circle_outline,
        const Color(0xFF10B981),
        const Color(0xFFECFDF5),
      ),
      _summaryCard(
        'Ditolak',
        rejected.toString(),
        'Pendaftaran Ditolak',
        Icons.cancel_outlined,
        const Color(0xFFEF4444),
        const Color(0xFFFEF2F2),
      ),
    ];

    if (mobile) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  // =========================================================
  // SUMMARY CARD
  // =========================================================

  Widget _summaryCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color iconColor,
    Color iconBg,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TABLE
  // =========================================================

  Widget _table(bool mobile) {
    if (mobile) {
      return Column(
        children: List.generate(
          partners.length,
          (i) => _mobileCard(partners[i], i),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _tableHeader(),
          ...List.generate(
            partners.length,
            (i) => _tableRow(partners[i], i),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TABLE HEADER
  // =========================================================

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      color: const Color(0xFFF8FAFC),
      child: const Row(
        children: [
          Expanded(
            flex: 25,
            child: Text(
              'Nama Mitra',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            flex: 22,
            child: Text(
              'Kategori',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              'Kota',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            flex: 15,
            child: Text(
              'Waktu Daftar',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              'Berkas',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            flex: 24,
            child: Text(
              'Aksi',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TABLE ROW
  // =========================================================

  Widget _tableRow(Map<String, dynamic> p, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 25, child: _name(p)),
          Expanded(
            flex: 22,
            child: Text(
              p['category']?.toString() ?? '-',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF475569),
              ),
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              p['city']?.toString() ?? '-',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF475569),
              ),
            ),
          ),
          Expanded(
            flex: 15,
            child: Text(
              p['time']?.toString() ?? 'Baru saja',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(flex: 18, child: _documentButton(p)),
          Expanded(flex: 24, child: _actions(index)),
        ],
      ),
    );
  }

  // =========================================================
  // NAME
  // =========================================================

  Widget _name(Map<String, dynamic> p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p['name']?.toString() ?? 'Tanpa Nama',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          p['email']?.toString() ?? 'Tanpa Email',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // DOCUMENT BUTTON
  // =========================================================

  Widget _documentButton(Map<String, dynamic> p) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => _viewDocuments(p),
        icon: const Icon(Icons.attach_file, size: 14),
        label: const Text(
          'Lihat Berkas',
          style: TextStyle(fontSize: 10),
        ),
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFFF0EAFE),
          foregroundColor: const Color(0xFF8B5CF6),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // ACTIONS
  // =========================================================

  Widget _actions(int index) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ElevatedButton.icon(
          onPressed: isProcessing ? null : () => _approve(index),
          icon: const Icon(Icons.check, size: 14),
          label: const Text(
            'Approve',
            style: TextStyle(fontSize: 10),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFCBD5E1),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: isProcessing ? null : () => _reject(index),
          icon: const Icon(Icons.close, size: 14),
          label: const Text(
            'Reject',
            style: TextStyle(fontSize: 10),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFEF4444),
            side: const BorderSide(color: Color(0xFFFCA5A5)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // MOBILE CARD
  // =========================================================

  Widget _mobileCard(Map<String, dynamic> p, int index) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _name(p),
          const SizedBox(height: 10),
          Text(
            '${p['category'] ?? 'Umum'} • ${p['city'] ?? 'Indonesia'}',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
          Text(
            p['time']?.toString() ?? 'Baru saja',
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 9),
          _documentButton(p),
          const SizedBox(height: 5),
          _actions(index),
        ],
      ),
    );
  }

  // =========================================================
  // EMPTY
  // =========================================================

  Widget _empty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.verified_outlined,
            size: 42,
            color: Color(0xFFCBD5E1),
          ),
          SizedBox(height: 12),
          Text(
            'Tidak ada mitra yang perlu diverifikasi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// FULLSCREEN IMAGE VIEWER
// ================================================================
class _FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final String title;

  const _FullScreenImageViewer({
    required this.imageUrl,
    required this.title,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  final TransformationController _transformCtrl = TransformationController();
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _transformCtrl.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformCtrl.removeListener(_onTransformChanged);
    _transformCtrl.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final scale = _transformCtrl.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.05;
    if (zoomed != _isZoomed) {
      setState(() => _isZoomed = zoomed);
    }
  }

  void _resetZoom() {
    _transformCtrl.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          if (_isZoomed)
            IconButton(
              tooltip: 'Reset Zoom',
              icon: const Icon(Icons.zoom_out_map),
              onPressed: _resetZoom,
            ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          transformationController: _transformCtrl,
          minScale: 0.5,
          maxScale: 5.0,
          panEnabled: true,
          scaleEnabled: true,
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              );
            },
            errorBuilder: (_, __, ___) => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image, color: Colors.grey, size: 64),
                  SizedBox(height: 12),
                  Text(
                    'Gagal memuat gambar',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: const Text(
          'Pinch untuk zoom • Drag untuk geser',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ),
    );
  }
}