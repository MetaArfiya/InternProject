// lib/screens/Screens_Admin/admin_verification_screen.dart

import 'dart:async';
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
  List<Map<String, dynamic>> partners = [];
  List<Map<String, dynamic>> verifiedPartners = [];
  List<Map<String, dynamic>> pendingSkillsList = [];

  bool isLoading = true;
  bool isLoadingVerified = false;
  bool isLoadingPendingSkills = false;
  bool isProcessing = false;

  int waitingCount = 0;
  int approvedToday = 0;
  int rejected = 0;

  int? adminId;

  String _selectedTab = 'pending';

  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) async {
        if (!mounted) return;
        if (isProcessing) return;

        if (_selectedTab == 'pending') {
          await _fetchUnverifiedMitra();
        } else if (_selectedTab == 'verified') {
          await _fetchVerifiedMitra();
        } else if (_selectedTab == 'pendingSkills') {
          await _fetchPendingSkills();
        }
      },
    );
  }

  Future<void> _initialize() async {
    await _getAdminId();
    await _fetchUnverifiedMitra();
    await _fetchVerifiedMitra();
    await _fetchPendingSkills();
  }

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

  Future<void> _fetchUnverifiedMitra() async {
    if (!mounted) return;

    if (partners.isEmpty) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final response = await ApiService.get('/admin/unverified-mitra');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is! Map) {
          throw Exception('Format response API tidak valid.');
        }

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

        final dynamic rawData = decoded['data'];
        final List<dynamic> data = rawData is List ? rawData : [];

        final List<Map<String, dynamic>> mappedPartners =
            data.map<Map<String, dynamic>>((item) {
          final Map<String, dynamic> mitra = item is Map<String, dynamic>
              ? item
              : Map<String, dynamic>.from(item);

          final dynamic rawUser = mitra['user'];
          final Map<String, dynamic> user = rawUser is Map
              ? Map<String, dynamic>.from(rawUser)
              : {};

          final dynamic id = mitra['id'];

          final String name = user['name']?.toString() ??
              mitra['name']?.toString() ??
              'Tanpa Nama';

          final String email = user['email']?.toString() ??
              mitra['email']?.toString() ??
              'Tanpa Email';

          final String category = mitra['skills']?.toString() ??
              mitra['category']?.toString() ??
              'Umum';

          final String city = user['city']?.toString() ??
              mitra['city']?.toString() ??
              user['address']?.toString() ??
              mitra['address']?.toString() ??
              'Indonesia';

          final dynamic verificationImage = mitra['verification_image'];
          final dynamic selfieImage = mitra['selfie_image'];
          final dynamic rawCertificate = mitra['certificate'];
          final dynamic rawSkillPhotos = mitra['skill_photos'];
          final dynamic rawProfilePhoto = user['photo_profile'];

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
            {'title': 'KTP / Identitas', 'valid': hasKtp},
            {'title': 'Bukti Keahlian', 'valid': hasCertificate},
          ];

          return {
            'id': id,
            'name': name,
            'email': email,
            'phone': user['phone']?.toString() ?? '-',
            'category': category,
            'city': city,
            'time': _formatTime(mitra['created_at']),
            'created_at': mitra['created_at'],
            'documents': documents,
            'verification_image': verificationImage,
            'selfie_image': selfieImage,
            'certificate': rawCertificate,
            'skill_photos': rawSkillPhotos,
            'profile_photo': rawProfilePhoto,
            'gender': mitra['gender'],
            'birth_date': mitra['birth_date'],
            'bio': mitra['bio'],
            'bank_name': mitra['bank_name'],
            'bank_account_number': mitra['bank_account_number'],
            'bank_account_name': mitra['bank_account_name'],
            'user': user,
          };
        }).toList();

        if (!mounted) return;

        setState(() {
          partners = mappedPartners;
          isLoading = false;
        });

        _syncPending();
      } else {
        if (!mounted) return;
        setState(() => isLoading = false);
        _message(_getErrorMessage(response), error: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _message('Gagal terhubung ke server.', error: true);
      debugPrint('FETCH UNVERIFIED MITRA ERROR: $e');
    }
  }

  Future<void> _fetchVerifiedMitra() async {
    if (!mounted) return;

    if (verifiedPartners.isEmpty) {
      setState(() => isLoadingVerified = true);
    }

    try {
      final response = await ApiService.get('/admin/verified-mitra');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final dynamic rawData = decoded['data'];
        final List<dynamic> data = rawData is List ? rawData : [];

        final mapped = data.map<Map<String, dynamic>>((item) {
          final Map<String, dynamic> mitra = item is Map<String, dynamic>
              ? item
              : Map<String, dynamic>.from(item);

          final dynamic rawUser = mitra['user'];
          final Map<String, dynamic> user = rawUser is Map
              ? Map<String, dynamic>.from(rawUser)
              : {};

          List<dynamic> skillPhotos = [];
          if (mitra['skill_photos'] is List) {
            skillPhotos = mitra['skill_photos'] as List;
          } else if (mitra['skill_photos'] is String) {
            try {
              final decodedPhotos =
                  jsonDecode(mitra['skill_photos'].toString());
              if (decodedPhotos is List) skillPhotos = decodedPhotos;
            } catch (_) {}
          }

          return {
            'id': mitra['id'],
            'user_id': mitra['user_id'],
            'name': mitra['name']?.toString() ??
                user['name']?.toString() ??
                'Tanpa Nama',
            'email': mitra['email']?.toString() ??
                user['email']?.toString() ??
                'Tanpa Email',
            'phone': mitra['phone']?.toString() ?? '-',
            'address': mitra['address']?.toString() ?? '-',
            'profile_photo': mitra['profile_photo'],
            'gender': mitra['gender'],
            'birth_date': mitra['birth_date'],
            'city': mitra['city']?.toString() ?? '-',
            'bio': mitra['bio'],
            'skills': mitra['skills'],
            'category': mitra['category']?.toString() ??
                mitra['skills']?.toString() ??
                'Umum',
            'certificate': mitra['certificate'],
            'skill_photos': skillPhotos,
            'verification_image': mitra['verification_image'],
            'selfie_image': mitra['selfie_image'],
            'bank_name': mitra['bank_name'],
            'bank_account_number': mitra['bank_account_number'],
            'bank_account_name': mitra['bank_account_name'],
            'point': mitra['point'] ?? 0,
            'rating': mitra['rating'] ?? 0,
            'jobs_completed': mitra['jobs_completed'] ?? 0,
            'is_verified': mitra['is_verified'] == true,
            'verified_by': mitra['verified_by'],
            'verified_at': mitra['verified_at'],
            'created_at': mitra['created_at'],
            'time': _formatTime(mitra['verified_at'] ?? mitra['created_at']),
            'user': user,
          };
        }).toList();

        if (!mounted) return;

        setState(() {
          verifiedPartners = mapped;
          isLoadingVerified = false;
        });
      } else {
        if (!mounted) return;
        setState(() => isLoadingVerified = false);
      }
    } catch (e) {
      debugPrint('FETCH VERIFIED MITRA ERROR: $e');
      if (!mounted) return;
      setState(() => isLoadingVerified = false);
    }
  }

  // ============================================================
  // ✅ FIX: JANGAN paksa .toString() pada certificate yang bisa List
  // ============================================================
  Future<void> _fetchPendingSkills() async {
    if (!mounted) return;

    if (pendingSkillsList.isEmpty) {
      setState(() => isLoadingPendingSkills = true);
    }

    try {
      final response = await ApiService.get('/admin/pending-skills');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final dynamic rawData = decoded['data'];
        final List<dynamic> data = rawData is List ? rawData : [];

        final mapped = data.map<Map<String, dynamic>>((item) {
          final Map<String, dynamic> mitra = item is Map<String, dynamic>
              ? item
              : Map<String, dynamic>.from(item);

          List<dynamic> pendingPhotos = [];
          if (mitra['pending_skill_photos'] is List) {
            pendingPhotos = mitra['pending_skill_photos'] as List;
          } else if (mitra['pending_skill_photos'] is String) {
            try {
              final decoded =
                  jsonDecode(mitra['pending_skill_photos'].toString());
              if (decoded is List) pendingPhotos = decoded;
            } catch (_) {}
          }

          List<dynamic> oldPhotos = [];
          if (mitra['skill_photos'] is List) {
            oldPhotos = mitra['skill_photos'] as List;
          } else if (mitra['skill_photos'] is String) {
            try {
              final decoded = jsonDecode(mitra['skill_photos'].toString());
              if (decoded is List) oldPhotos = decoded;
            } catch (_) {}
          }

          return {
            'id': mitra['id'],
            'user_id': mitra['user_id'],
            'name': mitra['name']?.toString() ?? 'Tanpa Nama',
            'email': mitra['email']?.toString() ?? '-',
            'phone': mitra['phone']?.toString() ?? '-',
            'profile_photo': mitra['profile_photo'],
            'current_skills': mitra['current_skills']?.toString() ?? '-',
            'pending_skills': mitra['pending_skills']?.toString() ?? '-',
            'skills_updated_at': mitra['skills_updated_at'],
            'skill_photos': oldPhotos,
            'pending_skill_photos': pendingPhotos,
            // ✅ FIX: kirim raw supaya bisa String ATAU List
            'certificate': mitra['certificate'],
            'pending_certificate': mitra['pending_certificate'],
            'rating': mitra['rating'] ?? 0,
            'point': mitra['point'] ?? 0,
            'jobs_completed': mitra['jobs_completed'] ?? 0,
            'time': _formatTime(mitra['skills_updated_at']),
          };
        }).toList();

        if (!mounted) return;

        setState(() {
          pendingSkillsList = mapped;
          isLoadingPendingSkills = false;
        });
      } else {
        if (!mounted) return;
        setState(() => isLoadingPendingSkills = false);
      }
    } catch (e) {
      debugPrint('FETCH PENDING SKILLS ERROR: $e');
      if (!mounted) return;
      setState(() => isLoadingPendingSkills = false);
    }
  }

  String _buildImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty || rawPath == 'null') {
      return '';
    }

    if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
      return rawPath;
    }

    String normalized = rawPath;
    if (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }

    const baseUrl = 'http://127.0.0.1:8000';

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

    if (normalized.startsWith('storage/')) {
      normalized = normalized.substring('storage/'.length);
      return _buildImageUrl(normalized);
    }

    final filename = normalized.split('/').last;
    return '$baseUrl/api/images/profile/$filename';
  }

  // ============================================================
  // ✅ HELPER BARU: normalisasi certificate (List/String) → List<URL>
  // ============================================================
  List<String> _buildCertificateUrls(dynamic raw) {
    if (raw == null) return [];

    if (raw is List) {
      return raw
          .map((e) => _buildImageUrl(e.toString()))
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final s = raw.toString();
    if (s.isEmpty || s == 'null') return [];

    final url = _buildImageUrl(s);
    return url.isEmpty ? [] : [url];
  }

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

  bool _documentsComplete(Map<String, dynamic> partner) {
    final List<dynamic> documents =
        partner['documents'] as List<dynamic>? ?? [];

    if (documents.isEmpty) return false;

    return documents.every(
      (doc) => doc is Map && doc['valid'] == true,
    );
  }

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

    setState(() => isProcessing = true);

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

        await _fetchVerifiedMitra();

        _message('$name berhasil diverifikasi.');
      } else {
        setState(() => isProcessing = false);
        _message(_getErrorMessage(response), error: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isProcessing = false);
      _message('Terjadi kesalahan saat memverifikasi mitra.', error: true);
      debugPrint('APPROVE MITRA ERROR: $e');
    }
  }

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

    setState(() => isProcessing = true);

    try {
      final response = await ApiService.post(
        '/admin/verify-mitra/$id',
        {
          'admin_id': adminId,
          'action': 'reject',
          'reason': reason,
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
        setState(() => isProcessing = false);
        _message(_getErrorMessage(response), error: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isProcessing = false);
      _message('Terjadi kesalahan saat menolak mitra.', error: true);
      debugPrint('REJECT MITRA ERROR: $e');
    }
  }

  Future<void> _approveSkill(int index) async {
    if (index < 0 || index >= pendingSkillsList.length) return;
    if (isProcessing) return;

    final item = pendingSkillsList[index];
    final dynamic userId = item['user_id'];
    final String name = item['name']?.toString() ?? 'Mitra';
    final String newSkill = item['pending_skills']?.toString() ?? '-';

    if (userId == null) {
      _message('ID mitra tidak ditemukan.', error: true);
      return;
    }

    final bool ok = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Setujui Perubahan Keahlian'),
              content: Text(
                'Setujui perubahan keahlian $name?\n\n'
                'Keahlian baru: "$newSkill"\n\n'
                'Setelah disetujui, mitra hanya akan menerima pekerjaan '
                'yang sesuai dengan keahlian baru ini.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  icon: const Icon(Icons.check, size: 17),
                  label: const Text('Setujui'),
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

    setState(() => isProcessing = true);

    try {
      final response = await ApiService.post(
        '/admin/approve-skill/$userId',
        {},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          pendingSkillsList.removeAt(index);
          isProcessing = false;
        });

        _message('Keahlian $name berhasil disetujui.');
      } else {
        setState(() => isProcessing = false);
        _message(_getErrorMessage(response), error: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isProcessing = false);
      _message('Terjadi kesalahan saat menyetujui keahlian.', error: true);
      debugPrint('APPROVE SKILL ERROR: $e');
    }
  }

  Future<void> _rejectSkill(int index) async {
    if (index < 0 || index >= pendingSkillsList.length) return;
    if (isProcessing) return;

    final item = pendingSkillsList[index];
    final dynamic userId = item['user_id'];
    final String name = item['name']?.toString() ?? 'Mitra';

    if (userId == null) {
      _message('ID mitra tidak ditemukan.', error: true);
      return;
    }

    final String? reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final controller = TextEditingController();

        return AlertDialog(
          title: const Text('Tolak Perubahan Keahlian'),
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
                      'Contoh: Keahlian baru belum didukung sertifikat/bukti.',
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
                controller.dispose();
                Navigator.of(dialogContext)
                    .pop(text.isEmpty ? 'Ditolak oleh admin.' : text);
              },
              icon: const Icon(Icons.close, size: 17),
              label: const Text('Tolak'),
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

    setState(() => isProcessing = true);

    try {
      final response = await ApiService.post(
        '/admin/reject-skill/$userId',
        {'note': reason},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          pendingSkillsList.removeAt(index);
          isProcessing = false;
        });

        _message('Perubahan keahlian $name ditolak.', error: true);
      } else {
        setState(() => isProcessing = false);
        _message(_getErrorMessage(response), error: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isProcessing = false);
      _message('Terjadi kesalahan saat menolak keahlian.', error: true);
      debugPrint('REJECT SKILL ERROR: $e');
    }
  }

  // ============================================================
  // ✅ FIX: _viewSkillPhotos — handle certificate List & String
  // ============================================================
  void _viewSkillPhotos(Map<String, dynamic> item) {
    final String name = item['name']?.toString() ?? 'Mitra';
    final String currentSkills = item['current_skills']?.toString() ?? '-';
    final String pendingSkills = item['pending_skills']?.toString() ?? '-';

    List<String> oldPhotos = [];
    final rawOld = item['skill_photos'];
    if (rawOld is List) {
      oldPhotos = rawOld
          .map((e) => _buildImageUrl(e.toString()))
          .where((e) => e.isNotEmpty)
          .toList();
    }

    List<String> newPhotos = [];
    final rawNew = item['pending_skill_photos'];
    if (rawNew is List) {
      newPhotos = rawNew
          .map((e) => _buildImageUrl(e.toString()))
          .where((e) => e.isNotEmpty)
          .toList();
    }

    // ✅ pakai helper — support List & String
    final List<String> oldCerts = _buildCertificateUrls(item['certificate']);
    final List<String> newCerts =
        _buildCertificateUrls(item['pending_certificate']);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.photo_library_outlined, color: Color(0xFF8B5CF6)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Foto Bukti: $name',
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 600,
          height: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== FOTO BARU =====
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fiber_new, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Foto Keahlian BARU — "$pendingSkills"',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (newPhotos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Mitra tidak upload foto baru.\n'
                      'Akan pakai foto lama setelah di-ACC.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: newPhotos.map((url) {
                      return _skillPhotoThumb(url, 'Foto Baru');
                    }).toList(),
                  ),

                // ===== SERTIFIKAT BARU =====
                if (newCerts.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.assignment, color: Color(0xFFB45309)),
                        const SizedBox(width: 8),
                        Text(
                          'Sertifikat BARU (${newCerts.length})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: newCerts
                        .asMap()
                        .entries
                        .map((e) =>
                            _skillPhotoThumb(e.value, 'Sertifikat Baru ${e.key + 1}'))
                        .toList(),
                  ),
                ],

                const SizedBox(height: 24),

                // ===== FOTO LAMA =====
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.history, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Foto Keahlian SAAT INI — "$currentSkills"',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (oldPhotos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Belum ada foto keahlian tersimpan.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: oldPhotos.map((url) {
                      return _skillPhotoThumb(url, 'Foto Lama');
                    }).toList(),
                  ),

                // ===== SERTIFIKAT LAMA =====
                if (oldCerts.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.assignment, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Text(
                          'Sertifikat SAAT INI (${oldCerts.length})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: oldCerts
                        .asMap()
                        .entries
                        .map((e) =>
                            _skillPhotoThumb(e.value, 'Sertifikat Lama ${e.key + 1}'))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _skillPhotoThumb(String url, String label) {
    return GestureDetector(
      onTap: () => _openFullScreenImage(context, url, label),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 140,
          height: 140,
          color: Colors.grey.shade100,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              size: 40,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  void _viewDocuments(Map<String, dynamic> partner) {
    final String? profilePhoto = partner['profile_photo']?.toString();
    final String? verificationImage = partner['verification_image']?.toString();
    final String? selfieImage = partner['selfie_image']?.toString();
    final dynamic certificateRaw = partner['certificate'];
    final dynamic skillPhotosRaw = partner['skill_photos'];

    final List<Map<String, dynamic>> docs = [];

    if (profilePhoto != null &&
        profilePhoto.isNotEmpty &&
        profilePhoto != 'null') {
      docs.add({
        'title': 'Foto Profil',
        'path': profilePhoto,
        'icon': Icons.person,
      });
    }

    if (verificationImage != null &&
        verificationImage.isNotEmpty &&
        verificationImage != 'null') {
      docs.add({
        'title': 'KTP / Identitas',
        'path': verificationImage,
        'icon': Icons.credit_card,
      });
    }

    if (selfieImage != null && selfieImage.isNotEmpty && selfieImage != 'null') {
      docs.add({
        'title': 'Foto Verifikasi Diri (Selfie)',
        'path': selfieImage,
        'icon': Icons.camera_front,
      });
    }

    // ✅ Handle certificate List / String
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
                      children: docs.map<Widget>((doc) {
                        final url = _buildImageUrl(doc['path']?.toString());
                        final title = doc['title']?.toString() ?? 'Dokumen';
                        final iconData =
                            doc['icon'] as IconData? ?? Icons.image_outlined;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                            if (progress == null) return child;
                                            return Container(
                                              width: double.infinity,
                                              height: 200,
                                              decoration: BoxDecoration(
                                                color:
                                                    const Color(0xFFF1F5F9),
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

  void _viewFullData(Map<String, dynamic> partner) {
    final String? profilePhoto = partner['profile_photo']?.toString();
    final String? ktpPath = partner['verification_image']?.toString();
    final String? selfiePath = partner['selfie_image']?.toString();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  backgroundImage: (profilePhoto != null &&
                          profilePhoto.isNotEmpty &&
                          profilePhoto != 'null')
                      ? NetworkImage(_buildImageUrl(profilePhoto))
                      : null,
                  child: (profilePhoto == null ||
                          profilePhoto.isEmpty ||
                          profilePhoto == 'null')
                      ? const Icon(Icons.person,
                          size: 26, color: Color(0xFF2563EB))
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              partner['name']?.toString() ?? 'Mitra',
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified,
                                    size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text('Terverifikasi',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        partner['email']?.toString() ?? '-',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogSectionTitle('Identitas', Icons.badge_outlined),
                  const SizedBox(height: 10),
                  _dataRow('Nama Lengkap', partner['name']),
                  _dataRow('Email', partner['email']),
                  _dataRow('Nomor HP', partner['phone']),
                  _dataRow('Jenis Kelamin', partner['gender']),
                  _dataRow('Tanggal Lahir', partner['birth_date']),
                  _dataRow('Kota', partner['city']),
                  _dataRow('Alamat', partner['address']),
                  _dataRow('Deskripsi', partner['bio']),

                  const SizedBox(height: 20),

                  _dialogSectionTitle(
                      'Keahlian & Statistik', Icons.handyman_outlined),
                  const SizedBox(height: 10),
                  _dataRow('Kategori', partner['category']),
                  _dataRow('Poin', '${partner['point'] ?? 0}'),
                  _dataRow('Rating',
                      (partner['rating'] ?? 0).toStringAsFixed(1)),
                  _dataRow('Pekerjaan Selesai',
                      '${partner['jobs_completed'] ?? 0}'),

                  const SizedBox(height: 20),

                  _dialogSectionTitle(
                      'Rekening Bank', Icons.account_balance_outlined),
                  const SizedBox(height: 10),
                  _dataRow('Nama Bank', partner['bank_name']),
                  _dataRow('No. Rekening', partner['bank_account_number']),
                  _dataRow('Atas Nama', partner['bank_account_name']),

                  const SizedBox(height: 20),

                  _dialogSectionTitle('Berkas', Icons.folder_open_outlined),
                  const SizedBox(height: 12),

                  if (ktpPath != null &&
                      ktpPath.isNotEmpty &&
                      ktpPath != 'null')
                    _imageThumb('KTP / Identitas', ktpPath,
                        Icons.credit_card_outlined),

                  if (selfiePath != null &&
                      selfiePath.isNotEmpty &&
                      selfiePath != 'null')
                    _imageThumb('Selfie Verifikasi', selfiePath,
                        Icons.camera_front_outlined),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _viewDocuments(partner);
                      },
                      icon: const Icon(Icons.folder_open, size: 16),
                      label: const Text('Lihat Semua Berkas'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8B5CF6),
                        side: const BorderSide(color: Color(0xFFC4B5FD)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  _dialogSectionTitle('Status', Icons.info_outline),
                  const SizedBox(height: 10),
                  _dataRow(
                    'Status Verifikasi',
                    partner['is_verified'] == true
                        ? 'Terverifikasi'
                        : 'Belum Diverifikasi',
                  ),
                  _dataRow('Tanggal Verifikasi', partner['verified_at']),
                  _dataRow('Terdaftar Sejak', partner['created_at']),
                ],
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

  Widget _dialogSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF2563EB)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B)),
        ),
      ],
    );
  }

  Widget _dataRow(String label, dynamic value) {
    final text = (value == null || value.toString().isEmpty || value == 'null')
        ? '-'
        : value.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF64748B))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageThumb(String label, String path, IconData icon) {
    final url = _buildImageUrl(path);
    if (url.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF8B5CF6)),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155))),
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _openFullScreenImage(context, url, label),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url,
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('Gagal memuat',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _syncPending() {
    AdminActivityData.setPendingPartnerCount(partners.length);
    widget.onPendingCountChanged?.call(partners.length);
  }

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
                    onRefresh: () async {
                      if (_selectedTab == 'pending') {
                        await _fetchUnverifiedMitra();
                      } else if (_selectedTab == 'verified') {
                        await _fetchVerifiedMitra();
                      } else {
                        await _fetchPendingSkills();
                      }
                    },
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
                            'Verifikasi Mitra',
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _subtitleForTab(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  if (_selectedTab == 'pending') {
                                    await _fetchUnverifiedMitra();
                                  } else if (_selectedTab == 'verified') {
                                    await _fetchVerifiedMitra();
                                  } else {
                                    await _fetchPendingSkills();
                                  }
                                  if (!mounted) return;
                                  _message('Data diperbarui.');
                                },
                                icon: const Icon(Icons.refresh, size: 20),
                                tooltip: 'Refresh',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          _buildTabSelector(mobile),

                          const SizedBox(height: 20),

                          if (_selectedTab == 'pending') ...[
                            _summary(mobile),
                            const SizedBox(height: 20),
                            partners.isEmpty ? _empty() : _table(mobile),
                          ] else if (_selectedTab == 'verified') ...[
                            _buildVerifiedList(mobile),
                          ] else ...[
                            _buildPendingSkillsList(mobile),
                          ],
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  String _subtitleForTab() {
    switch (_selectedTab) {
      case 'verified':
        return '${verifiedPartners.length} mitra terverifikasi';
      case 'pendingSkills':
        return '${pendingSkillsList.length} pengajuan perubahan keahlian';
      default:
        return '$waitingCount mitra menunggu persetujuan';
    }
  }

  Widget _buildTabSelector(bool mobile) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              label: 'Menunggu',
              count: partners.length,
              isActive: _selectedTab == 'pending',
              activeColor: const Color(0xFFF59E0B),
              onTap: () => setState(() => _selectedTab = 'pending'),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _tabButton(
              label: mobile ? 'Verified' : 'Terverifikasi',
              count: verifiedPartners.length,
              isActive: _selectedTab == 'verified',
              activeColor: const Color(0xFF10B981),
              onTap: () => setState(() => _selectedTab = 'verified'),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _tabButton(
              label: mobile ? 'Keahlian' : 'Perubahan Keahlian',
              count: pendingSkillsList.length,
              isActive: _selectedTab == 'pendingSkills',
              activeColor: const Color(0xFF8B5CF6),
              onTap: () => setState(() => _selectedTab = 'pendingSkills'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String label,
    required int count,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? activeColor : const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withOpacity(0.12)
                    : const Color(0xFFCBD5E1).withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isActive ? activeColor : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingSkillsList(bool mobile) {
    if (isLoadingPendingSkills && pendingSkillsList.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (pendingSkillsList.isEmpty) {
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
            Icon(Icons.check_circle_outline,
                size: 42, color: Color(0xFF10B981)),
            SizedBox(height: 12),
            Text(
              'Tidak ada pengajuan perubahan keahlian.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }

    if (mobile) {
      return Column(
        children: List.generate(
          pendingSkillsList.length,
          (i) => _pendingSkillMobileCard(pendingSkillsList[i], i),
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
          _pendingSkillTableHeader(),
          ...List.generate(
            pendingSkillsList.length,
            (i) => _pendingSkillTableRow(pendingSkillsList[i], i),
          ),
        ],
      ),
    );
  }

  Widget _pendingSkillTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      color: const Color(0xFFF8FAFC),
      child: const Row(
        children: [
          Expanded(
            flex: 24,
            child: Text('Nama Mitra',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ),
          Expanded(
            flex: 20,
            child: Text('Keahlian Saat Ini',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ),
          Expanded(
            flex: 20,
            child: Text('Keahlian Baru',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ),
          Expanded(
            flex: 14,
            child: Text('Diajukan',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ),
          Expanded(
            flex: 30,
            child: Text('Aksi',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ),
        ],
      ),
    );
  }

  Widget _pendingSkillTableRow(Map<String, dynamic> p, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(flex: 24, child: _pendingSkillName(p)),
          Expanded(
            flex: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                p['current_skills']?.toString() ?? '-',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Expanded(
            flex: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                p['pending_skills']?.toString() ?? '-',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7C3AED),
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(
            flex: 14,
            child: Text(
              p['time']?.toString() ?? 'Baru saja',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(flex: 30, child: _pendingSkillActions(index)),
        ],
      ),
    );
  }

  Widget _pendingSkillName(Map<String, dynamic> p) {
    final photo = p['profile_photo']?.toString();
    final url = _buildImageUrl(photo);

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF1F5F9),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ClipOval(
            child: url.isNotEmpty
                ? Image.network(
                    url,
                    width: 34,
                    height: 34,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.person,
                        size: 18, color: Color(0xFF64748B)),
                  )
                : const Icon(Icons.person,
                    size: 18, color: Color(0xFF64748B)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p['name']?.toString() ?? 'Tanpa Nama',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B)),
              ),
              Text(
                p['email']?.toString() ?? '-',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pendingSkillActions(int index) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        OutlinedButton.icon(
          onPressed: () => _viewSkillPhotos(pendingSkillsList[index]),
          icon: const Icon(Icons.photo_library_outlined, size: 14),
          label: const Text('Foto Bukti', style: TextStyle(fontSize: 10)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF8B5CF6),
            side: const BorderSide(color: Color(0xFFC4B5FD)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: isProcessing ? null : () => _approveSkill(index),
          icon: const Icon(Icons.check, size: 14),
          label: const Text('Setujui', style: TextStyle(fontSize: 10)),
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
          onPressed: isProcessing ? null : () => _rejectSkill(index),
          icon: const Icon(Icons.close, size: 14),
          label: const Text('Tolak', style: TextStyle(fontSize: 10)),
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

  Widget _pendingSkillMobileCard(Map<String, dynamic> p, int index) {
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
          _pendingSkillName(p),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Keahlian Saat Ini',
                        style: TextStyle(
                            fontSize: 10, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p['current_skills']?.toString() ?? '-',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Keahlian Baru',
                        style: TextStyle(
                            fontSize: 10, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p['pending_skills']?.toString() ?? '-',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF7C3AED),
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Text(
            'Diajukan: ${p['time'] ?? 'Baru saja'}',
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),
          _pendingSkillActions(index),
        ],
      ),
    );
  }

  Widget _buildVerifiedList(bool mobile) {
    if (isLoadingVerified && verifiedPartners.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (verifiedPartners.isEmpty) {
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
            Icon(Icons.people_outline, size: 42, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            Text(
              'Belum ada mitra terverifikasi.',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }

    if (mobile) {
      return Column(
        children: List.generate(
          verifiedPartners.length,
          (i) => _verifiedMobileCard(verifiedPartners[i]),
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
          _verifiedTableHeader(),
          ...List.generate(
            verifiedPartners.length,
            (i) => _verifiedTableRow(verifiedPartners[i]),
          ),
        ],
      ),
    );
  }

  Widget _verifiedTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      color: const Color(0xFFF8FAFC),
      child: const Row(
        children: [
          Expanded(
            flex: 28,
            child: Text('Nama Mitra',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ),
          Expanded(
            flex: 22,
            child: Text('Kategori',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ),
          Expanded(
            flex: 15,
            child: Text('Kota',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ),
          Expanded(
            flex: 12,
            child: Text('Poin',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ),
          Expanded(
            flex: 12,
            child: Text('Rating',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ),
          Expanded(
            flex: 26,
            child: Text('Aksi',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ),
        ],
      ),
    );
  }

  Widget _verifiedTableRow(Map<String, dynamic> p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(flex: 28, child: _verifiedName(p)),
          Expanded(
            flex: 22,
            child: Text(
              p['category']?.toString() ?? '-',
              style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
            ),
          ),
          Expanded(
            flex: 15,
            child: Text(
              p['city']?.toString() ?? '-',
              style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
            ),
          ),
          Expanded(
            flex: 12,
            child: Row(
              children: [
                const Icon(Icons.stars, size: 13, color: Color(0xFFF59E0B)),
                const SizedBox(width: 4),
                Text(
                  '${p['point'] ?? 0}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569)),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 12,
            child: Row(
              children: [
                const Icon(Icons.star, size: 13, color: Color(0xFFFBBF24)),
                const SizedBox(width: 4),
                Text(
                  (p['rating'] ?? 0).toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569)),
                ),
              ],
            ),
          ),
          Expanded(flex: 26, child: _verifiedActions(p)),
        ],
      ),
    );
  }

  Widget _verifiedName(Map<String, dynamic> p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                p['name']?.toString() ?? 'Tanpa Nama',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B)),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.verified, size: 14, color: Color(0xFF10B981)),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          p['email']?.toString() ?? 'Tanpa Email',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  Widget _verifiedActions(Map<String, dynamic> p) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ElevatedButton.icon(
          onPressed: () => _viewFullData(p),
          icon: const Icon(Icons.person_search, size: 14),
          label: const Text('Lihat Data Lengkap',
              style: TextStyle(fontSize: 10)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
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
          onPressed: () => _viewDocuments(p),
          icon: const Icon(Icons.folder_open, size: 14),
          label: const Text('Berkas', style: TextStyle(fontSize: 10)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF8B5CF6),
            side: const BorderSide(color: Color(0xFFC4B5FD)),
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

  Widget _verifiedMobileCard(Map<String, dynamic> p) {
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
          Row(
            children: [
              Expanded(child: _verifiedName(p)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Terverifikasi',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${p['category'] ?? 'Umum'} • ${p['city'] ?? 'Indonesia'}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          Text(
            'Terverifikasi ${p['time'] ?? ''}',
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.stars, size: 13, color: Color(0xFFF59E0B)),
              const SizedBox(width: 4),
              Text('${p['point'] ?? 0} poin',
                  style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 12),
              const Icon(Icons.star, size: 13, color: Color(0xFFFBBF24)),
              const SizedBox(width: 4),
              Text(
                (p['rating'] ?? 0).toStringAsFixed(1),
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _viewFullData(p),
              icon: const Icon(Icons.person_search, size: 15),
              label: const Text('Lihat Data Lengkap',
                  style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _viewDocuments(p),
              icon: const Icon(Icons.folder_open, size: 15),
              label: const Text('Lihat Berkas',
                  style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8B5CF6),
                side: const BorderSide(color: Color(0xFFC4B5FD)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _tableRow(Map<String, dynamic> p, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(flex: 25, child: _name(p)),
          Expanded(
            flex: 22,
            child: Text(
              p['category']?.toString() ?? '-',
              style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              p['city']?.toString() ?? '-',
              style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
            ),
          ),
          Expanded(
            flex: 15,
            child: Text(
              p['time']?.toString() ?? 'Baru saja',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(flex: 18, child: _documentButton(p)),
          Expanded(flex: 24, child: _actions(index)),
        ],
      ),
    );
  }

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
          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  Widget _documentButton(Map<String, dynamic> p) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => _viewDocuments(p),
        icon: const Icon(Icons.attach_file, size: 14),
        label: const Text('Lihat Berkas', style: TextStyle(fontSize: 10)),
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

  Widget _actions(int index) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ElevatedButton.icon(
          onPressed: isProcessing ? null : () => _approve(index),
          icon: const Icon(Icons.check, size: 14),
          label: const Text('Approve', style: TextStyle(fontSize: 10)),
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
          label: const Text('Reject', style: TextStyle(fontSize: 10)),
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
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          Text(
            p['time']?.toString() ?? 'Baru saja',
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 9),
          _documentButton(p),
          const SizedBox(height: 5),
          _actions(index),
        ],
      ),
    );
  }

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
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

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