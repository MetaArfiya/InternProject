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
  // ============================================================
  // DESIGN TOKENS — disamakan dgn DashboardHeader / PaymentScreen
  // ============================================================

  static const Color _accent = Color(0xFFF97316);
  static const Color _successColor = Color(0xFF16A34A);
  static const Color _dangerColor = Color(0xFFDC2626);
  static const Color _infoColor = Color(0xFF2563EB);
  static const Color _warningColor = Color(0xFFD97706);
  static const Color _purpleColor = Color(0xFF7C3AED);

  static const Color _tableBorder = Color(0xFFE5E7EB);
  static const Color _tableDivider = Color(0xFFF3F4F6);
  static const Color _headerText = Color(0xFF6B7280);
  static const Color _cellText = Color(0xFF111827);
  static const Color _mutedText = Color(0xFF64748B);

  static const double _gapAfterHeader = 16;
  static const double _gapBetweenSections = 16;
  static const double _cardRadius = 14;
  static const double _radius = 10;

  // ============================================================
  // DATA STATE
  // ============================================================

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

  int _pendingPage = 1;
  int _verifiedPage = 1;
  int _skillsPage = 1;
  int _itemsPerPage = 10;
  static const List<int> _itemsPerPageOptions = [5, 10, 25, 50];

  // ============================================================
  // LIFECYCLE
  // ============================================================

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
          if (id != null) adminId = int.tryParse(id.toString());
        }
      }
    } catch (e) {
      debugPrint('GET ADMIN ID ERROR: $e');
    }
  }

  // ============================================================
  // FETCH
  // ============================================================

  Future<void> _fetchUnverifiedMitra() async {
    if (!mounted) return;
    if (partners.isEmpty) setState(() => isLoading = true);

    try {
      final response = await ApiService.get('/admin/unverified-mitra');
      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) throw Exception('Format response API tidak valid.');

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

        final mapped = data.map<Map<String, dynamic>>((item) {
          final mitra = item is Map<String, dynamic>
              ? item
              : Map<String, dynamic>.from(item);
          final rawUser = mitra['user'];
          final user = rawUser is Map
              ? Map<String, dynamic>.from(rawUser)
              : {};

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

          final verificationImage = mitra['verification_image'];
          final selfieImage = mitra['selfie_image'];
          final rawCertificate = mitra['certificate'];
          final rawSkillPhotos = mitra['skill_photos'];
          final rawProfilePhoto = user['photo_profile'];

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

          final documents = [
            {'title': 'KTP / Identitas', 'valid': hasKtp},
            {'title': 'Bukti Keahlian', 'valid': hasCertificate},
          ];

          return {
            'id': mitra['id'],
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

        setState(() {
          partners = mapped;
          isLoading = false;
          _pendingPage = 1;
        });

        _syncPending();
      } else {
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
    if (verifiedPartners.isEmpty) setState(() => isLoadingVerified = true);

    try {
      final response = await ApiService.get('/admin/verified-mitra');
      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final rawData = decoded['data'];
        final List<dynamic> data = rawData is List ? rawData : [];

        final mapped = data.map<Map<String, dynamic>>((item) {
          final mitra = item is Map<String, dynamic>
              ? item
              : Map<String, dynamic>.from(item);
          final rawUser = mitra['user'];
          final user = rawUser is Map
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
            'time': _formatTime(
              mitra['verified_at'] ?? mitra['created_at'],
            ),
            'user': user,
          };
        }).toList();

        setState(() {
          verifiedPartners = mapped;
          isLoadingVerified = false;
          _verifiedPage = 1;
        });
      } else {
        setState(() => isLoadingVerified = false);
      }
    } catch (e) {
      debugPrint('FETCH VERIFIED MITRA ERROR: $e');
      if (!mounted) return;
      setState(() => isLoadingVerified = false);
    }
  }

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
        final rawData = decoded['data'];
        final List<dynamic> data = rawData is List ? rawData : [];

        final mapped = data.map<Map<String, dynamic>>((item) {
          final mitra = item is Map<String, dynamic>
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
            'certificate': mitra['certificate'],
            'pending_certificate': mitra['pending_certificate'],
            'rating': mitra['rating'] ?? 0,
            'point': mitra['point'] ?? 0,
            'jobs_completed': mitra['jobs_completed'] ?? 0,
            'time': _formatTime(mitra['skills_updated_at']),
          };
        }).toList();

        setState(() {
          pendingSkillsList = mapped;
          isLoadingPendingSkills = false;
          _skillsPage = 1;
        });
      } else {
        setState(() => isLoadingPendingSkills = false);
      }
    } catch (e) {
      debugPrint('FETCH PENDING SKILLS ERROR: $e');
      if (!mounted) return;
      setState(() => isLoadingPendingSkills = false);
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  int _totalPagesFor(int total) {
    if (total == 0) return 1;
    return ((total - 1) ~/ _itemsPerPage) + 1;
  }

  List<Map<String, dynamic>> _slice(
    List<Map<String, dynamic>> list,
    int page,
  ) {
    final start = (page - 1) * _itemsPerPage;
    if (start >= list.length) return [];
    final end = (start + _itemsPerPage).clamp(0, list.length);
    return list.sublist(start, end);
  }

  List<Map<String, dynamic>> get _paginatedPartners =>
      _slice(partners, _pendingPage);
  List<Map<String, dynamic>> get _paginatedVerified =>
      _slice(verifiedPartners, _verifiedPage);
  List<Map<String, dynamic>> get _paginatedSkills =>
      _slice(pendingSkillsList, _skillsPage);

  String _buildImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty || rawPath == 'null') return '';
    if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
      return rawPath;
    }

    String normalized = rawPath;
    if (normalized.startsWith('/')) normalized = normalized.substring(1);

    const baseUrl = 'http://127.0.0.1:8000';
    if (normalized.startsWith('profile_photos/')) {
      final f = normalized.substring('profile_photos/'.length);
      return '$baseUrl/api/images/profile/$f';
    }
    if (normalized.startsWith('certificates/')) {
      final f = normalized.substring('certificates/'.length);
      return '$baseUrl/api/images/certificates/$f';
    }
    if (normalized.startsWith('skill_photos/')) {
      final f = normalized.substring('skill_photos/'.length);
      return '$baseUrl/api/images/skill_photos/$f';
    }
    if (normalized.startsWith('completion_proofs/')) {
      final f = normalized.substring('completion_proofs/'.length);
      return '$baseUrl/api/images/completion_proofs/$f';
    }
    if (normalized.startsWith('storage/')) {
      normalized = normalized.substring('storage/'.length);
      return _buildImageUrl(normalized);
    }

    final filename = normalized.split('/').last;
    return '$baseUrl/api/images/profile/$filename';
  }

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
    return documents.every((doc) => doc is Map && doc['valid'] == true);
  }

  void _syncPending() {
    AdminActivityData.setPendingPartnerCount(partners.length);
    widget.onPendingCountChanged?.call(partners.length);
  }

  String _getErrorMessage(dynamic response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        if (body['message'] != null) return body['message'].toString();
        if (body['error'] != null) return body['error'].toString();
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
      if (difference.inMinutes < 60) return '${difference.inMinutes} menit lalu';
      if (difference.inHours < 24) return '${difference.inHours} jam lalu';
      if (difference.inDays < 7) return '${difference.inDays} hari lalu';
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
          backgroundColor: error ? _dangerColor : _successColor,
        ),
      );
  }

  // ============================================================
  // AKSI: APPROVE / REJECT MITRA
  // ============================================================

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
          barrierDismissible: false,
          builder: (dialogContext) {
            final textTheme = Theme.of(dialogContext).textTheme;
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _dialogHeader(
                        dialogContext,
                        icon: Icons.check_circle_outline,
                        color: _successColor,
                        title: 'Approve Mitra',
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Text(
                        'Yakin ingin memverifikasi $name?\n\n'
                        'Pastikan identitas dan bukti keahlian sudah sesuai.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF374151),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 46),
                                foregroundColor: const Color(0xFF374151),
                                side: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(_radius),
                                ),
                              ),
                              child: const Text(
                                'Batal',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text(
                                'Approve',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _successColor,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 46),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(_radius),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ) ??
        false;

    if (!ok || !mounted) return;
    setState(() => isProcessing = true);

    try {
      final response = await ApiService.post(
        '/admin/verify-mitra/$id',
        {'admin_id': adminId, 'action': 'approve'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          partners.removeAt(index);
          isProcessing = false;
          waitingCount = partners.length;
          approvedToday++;
          if (_pendingPage > _totalPagesFor(partners.length)) {
            _pendingPage = _totalPagesFor(partners.length);
          }
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
        final textTheme = Theme.of(dialogContext).textTheme;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _dialogHeader(
                    dialogContext,
                    icon: Icons.cancel_outlined,
                    color: _dangerColor,
                    title: 'Tolak Pendaftaran',
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Text(
                    'Berikan alasan penolakan untuk $name.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText:
                          'Contoh: KTP tidak jelas atau bukti keahlian tidak sesuai.',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9CA3AF),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_radius),
                        borderSide:
                            const BorderSide(color: _tableBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_radius),
                        borderSide:
                            const BorderSide(color: _tableBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_radius),
                        borderSide:
                            const BorderSide(color: _accent, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            controller.dispose();
                            Navigator.of(dialogContext).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 46),
                            foregroundColor: const Color(0xFF374151),
                            side: const BorderSide(
                              color: Color(0xFFD1D5DB),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_radius),
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final text = controller.text.trim();
                            if (text.isEmpty) return;
                            controller.dispose();
                            Navigator.of(dialogContext).pop(text);
                          },
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text(
                            'Reject',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _dangerColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 46),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_radius),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (reason == null || !mounted) return;
    setState(() => isProcessing = true);

    try {
      final response = await ApiService.post(
        '/admin/verify-mitra/$id',
        {'admin_id': adminId, 'action': 'reject', 'reason': reason},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          partners.removeAt(index);
          isProcessing = false;
          waitingCount = partners.length;
          rejected++;
          if (_pendingPage > _totalPagesFor(partners.length)) {
            _pendingPage = _totalPagesFor(partners.length);
          }
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

  // ============================================================
  // AKSI: APPROVE / REJECT SKILL
  // ============================================================

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
          barrierDismissible: false,
          builder: (dialogContext) {
            final textTheme = Theme.of(dialogContext).textTheme;
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _dialogHeader(
                        dialogContext,
                        icon: Icons.check_circle_outline,
                        color: _successColor,
                        title: 'Setujui Perubahan Keahlian',
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Text(
                        'Setujui perubahan keahlian $name?\n\n'
                        'Keahlian baru: "$newSkill"\n\n'
                        'Setelah disetujui, mitra hanya akan menerima pekerjaan '
                        'yang sesuai dengan keahlian baru ini.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF374151),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 46),
                                foregroundColor: const Color(0xFF374151),
                                side: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(_radius),
                                ),
                              ),
                              child: const Text(
                                'Batal',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text(
                                'Setujui',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _successColor,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 46),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(_radius),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ) ??
        false;

    if (!ok || !mounted) return;
    setState(() => isProcessing = true);

    try {
      final response =
          await ApiService.post('/admin/approve-skill/$userId', {});

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          pendingSkillsList.removeAt(index);
          isProcessing = false;
          if (_skillsPage > _totalPagesFor(pendingSkillsList.length)) {
            _skillsPage = _totalPagesFor(pendingSkillsList.length);
          }
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
        final textTheme = Theme.of(dialogContext).textTheme;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _dialogHeader(
                    dialogContext,
                    icon: Icons.cancel_outlined,
                    color: _dangerColor,
                    title: 'Tolak Perubahan Keahlian',
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Text(
                    'Berikan alasan penolakan untuk $name.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText:
                          'Contoh: Keahlian baru belum didukung sertifikat/bukti.',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9CA3AF),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_radius),
                        borderSide:
                            const BorderSide(color: _tableBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_radius),
                        borderSide:
                            const BorderSide(color: _tableBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_radius),
                        borderSide:
                            const BorderSide(color: _accent, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            controller.dispose();
                            Navigator.of(dialogContext).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 46),
                            foregroundColor: const Color(0xFF374151),
                            side: const BorderSide(
                              color: Color(0xFFD1D5DB),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_radius),
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final text = controller.text.trim();
                            controller.dispose();
                            Navigator.of(dialogContext).pop(
                              text.isEmpty ? 'Ditolak oleh admin.' : text,
                            );
                          },
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text(
                            'Tolak',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _dangerColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 46),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_radius),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
          if (_skillsPage > _totalPagesFor(pendingSkillsList.length)) {
            _skillsPage = _totalPagesFor(pendingSkillsList.length);
          }
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
  // DIALOG HEADER HELPER
  // ============================================================

  Widget _dialogHeader(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(_radius),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _cellText,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, size: 20, color: _headerText),
          splashRadius: 22,
        ),
      ],
    );
  }

  // ============================================================
  // VIEW SKILL PHOTOS
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

    final List<String> oldCerts = _buildCertificateUrls(item['certificate']);
    final List<String> newCerts =
        _buildCertificateUrls(item['pending_certificate']);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final textTheme = Theme.of(dialogContext).textTheme;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _purpleColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(_radius),
                        ),
                        child: const Icon(
                          Icons.photo_library_outlined,
                          color: _purpleColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Foto Bukti: $name',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _cellText,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.pop(dialogContext),
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: _headerText,
                        ),
                        splashRadius: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionBanner(
                            icon: Icons.fiber_new,
                            color: _purpleColor,
                            text: 'Foto Keahlian BARU — "$pendingSkills"',
                          ),
                          const SizedBox(height: 10),
                          if (newPhotos.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'Mitra tidak upload foto baru.\n'
                                'Akan pakai foto lama setelah di-ACC.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: newPhotos
                                  .map((url) =>
                                      _skillPhotoThumb(url, 'Foto Baru'))
                                  .toList(),
                            ),
                          if (newCerts.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _sectionBanner(
                              icon: Icons.assignment,
                              color: _warningColor,
                              text: 'Sertifikat BARU (${newCerts.length})',
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: newCerts
                                  .asMap()
                                  .entries
                                  .map((e) => _skillPhotoThumb(
                                        e.value,
                                        'Sertifikat Baru ${e.key + 1}',
                                      ))
                                  .toList(),
                            ),
                          ],
                          const SizedBox(height: 24),
                          _sectionBanner(
                            icon: Icons.history,
                            color: _mutedText,
                            text:
                                'Foto Keahlian SAAT INI — "$currentSkills"',
                          ),
                          const SizedBox(height: 10),
                          if (oldPhotos.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'Belum ada foto keahlian tersimpan.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: oldPhotos
                                  .map((url) =>
                                      _skillPhotoThumb(url, 'Foto Lama'))
                                  .toList(),
                            ),
                          if (oldCerts.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _sectionBanner(
                              icon: Icons.assignment,
                              color: _mutedText,
                              text:
                                  'Sertifikat SAAT INI (${oldCerts.length})',
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: oldCerts
                                  .asMap()
                                  .entries
                                  .map((e) => _skillPhotoThumb(
                                        e.value,
                                        'Sertifikat Lama ${e.key + 1}',
                                      ))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionBanner({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skillPhotoThumb(String url, String label) {
    return GestureDetector(
      onTap: () => _openFullScreenImage(context, url, label),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Container(
          width: 140,
          height: 140,
          color: const Color(0xFFF9FAFB),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              size: 40,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // VIEW DOCUMENTS
  // ============================================================

  void _viewDocuments(Map<String, dynamic> partner) {
    final String? profilePhoto = partner['profile_photo']?.toString();
    final String? verificationImage =
        partner['verification_image']?.toString();
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
    if (selfieImage != null &&
        selfieImage.isNotEmpty &&
        selfieImage != 'null') {
      docs.add({
        'title': 'Foto Verifikasi Diri (Selfie)',
        'path': selfieImage,
        'icon': Icons.camera_front,
      });
    }
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
        final textTheme = Theme.of(dialogContext).textTheme;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _purpleColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(_radius),
                        ),
                        child: const Icon(
                          Icons.folder_open,
                          color: _purpleColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Berkas ${partner['name'] ?? 'Mitra'}',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _cellText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${docs.length} berkas',
                              style: textTheme.labelSmall?.copyWith(
                                color: _mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: _headerText,
                        ),
                        splashRadius: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Flexible(
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: docs.map<Widget>((doc) {
                                final url = _buildImageUrl(
                                  doc['path']?.toString(),
                                );
                                final title =
                                    doc['title']?.toString() ?? 'Dokumen';
                                final iconData = doc['icon'] as IconData? ??
                                    Icons.image_outlined;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: _purpleColor
                                                  .withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(7),
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              iconData,
                                              size: 15,
                                              color: _purpleColor,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              title,
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: _cellText,
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
                                                    BorderRadius.circular(
                                                        _radius),
                                                child: Image.network(
                                                  url,
                                                  width: double.infinity,
                                                  height: 200,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (context,
                                                      child, progress) {
                                                    if (progress == null) {
                                                      return child;
                                                    }
                                                    return Container(
                                                      width: double.infinity,
                                                      height: 200,
                                                      decoration:
                                                          BoxDecoration(
                                                        color: const Color(
                                                            0xFFF9FAFB),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    _radius),
                                                      ),
                                                      child: const Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder:
                                                      (_, __, ___) =>
                                                          Container(
                                                    width: double.infinity,
                                                    height: 200,
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFFEF2F2),
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(
                                                                  _radius),
                                                      border: Border.all(
                                                        color: const Color(
                                                            0xFFFCA5A5),
                                                      ),
                                                    ),
                                                    child: const Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .broken_image_outlined,
                                                          size: 42,
                                                          color:
                                                              Color(0xFFDC2626),
                                                        ),
                                                        SizedBox(height: 8),
                                                        Text(
                                                          'Gagal memuat gambar',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Color(
                                                                0xFFDC2626),
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
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.6),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
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
                                                          fontWeight:
                                                              FontWeight.w600,
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
                                            color:
                                                const Color(0xFFF9FAFB),
                                            borderRadius:
                                                BorderRadius.circular(_radius),
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            foregroundColor: const Color(0xFF374151),
                            side: const BorderSide(
                              color: Color(0xFFD1D5DB),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_radius),
                            ),
                          ),
                          child: const Text(
                            'Tutup',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // VIEW FULL DATA
  // ============================================================

  void _viewFullData(Map<String, dynamic> partner) {
    final String? profilePhoto = partner['profile_photo']?.toString();
    final String? ktpPath = partner['verification_image']?.toString();
    final String? selfiePath = partner['selfie_image']?.toString();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final textTheme = Theme.of(dialogContext).textTheme;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HEADER dengan avatar
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: _infoColor.withOpacity(0.12),
                        backgroundImage: (profilePhoto != null &&
                                profilePhoto.isNotEmpty &&
                                profilePhoto != 'null')
                            ? NetworkImage(_buildImageUrl(profilePhoto))
                            : null,
                        child: (profilePhoto == null ||
                                profilePhoto.isEmpty ||
                                profilePhoto == 'null')
                            ? const Icon(
                                Icons.person,
                                size: 26,
                                color: _infoColor,
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              partner['name']?.toString() ?? 'Mitra',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _cellText,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              partner['email']?.toString() ?? '-',
                              style: textTheme.bodySmall?.copyWith(
                                color: _mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _successColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 12,
                              color: _successColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Terverifikasi',
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: _successColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: _headerText,
                        ),
                        splashRadius: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _dialogSectionTitle(
                            'Identitas',
                            Icons.badge_outlined,
                          ),
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
                            'Keahlian & Statistik',
                            Icons.handyman_outlined,
                          ),
                          const SizedBox(height: 10),
                          _dataRow('Kategori', partner['category']),
                          _dataRow('Poin', '${partner['point'] ?? 0}'),
                          _dataRow(
                            'Rating',
                            (partner['rating'] ?? 0).toStringAsFixed(1),
                          ),
                          _dataRow(
                            'Pekerjaan Selesai',
                            '${partner['jobs_completed'] ?? 0}',
                          ),

                          const SizedBox(height: 20),
                          _dialogSectionTitle(
                            'Rekening Bank',
                            Icons.account_balance_outlined,
                          ),
                          const SizedBox(height: 10),
                          _dataRow('Nama Bank', partner['bank_name']),
                          _dataRow(
                            'No. Rekening',
                            partner['bank_account_number'],
                          ),
                          _dataRow(
                            'Atas Nama',
                            partner['bank_account_name'],
                          ),

                          const SizedBox(height: 20),
                          _dialogSectionTitle(
                            'Berkas',
                            Icons.folder_open_outlined,
                          ),
                          const SizedBox(height: 12),

                          if (ktpPath != null &&
                              ktpPath.isNotEmpty &&
                              ktpPath != 'null')
                            _imageThumb(
                              'KTP / Identitas',
                              ktpPath,
                              Icons.credit_card_outlined,
                            ),
                          if (selfiePath != null &&
                              selfiePath.isNotEmpty &&
                              selfiePath != 'null')
                            _imageThumb(
                              'Selfie Verifikasi',
                              selfiePath,
                              Icons.camera_front_outlined,
                            ),

                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                _viewDocuments(partner);
                              },
                              icon: const Icon(
                                Icons.folder_open,
                                size: 16,
                              ),
                              label: const Text(
                                'Lihat Semua Berkas',
                                style: TextStyle(fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _purpleColor,
                                side: BorderSide(
                                  color: _purpleColor.withOpacity(0.4),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(_radius),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                          _dialogSectionTitle(
                            'Status',
                            Icons.info_outline,
                          ),
                          const SizedBox(height: 10),
                          _dataRow(
                            'Status Verifikasi',
                            partner['is_verified'] == true
                                ? 'Terverifikasi'
                                : 'Belum Diverifikasi',
                          ),
                          _dataRow(
                            'Tanggal Verifikasi',
                            partner['verified_at'],
                          ),
                          _dataRow(
                            'Terdaftar Sejak',
                            partner['created_at'],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            foregroundColor: const Color(0xFF374151),
                            side: const BorderSide(
                              color: Color(0xFFD1D5DB),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_radius),
                            ),
                          ),
                          child: const Text(
                            'Tutup',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dialogSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _accent),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _cellText,
          ),
        ),
      ],
    );
  }

  Widget _dataRow(String label, dynamic value) {
    final text =
        (value == null || value.toString().isEmpty || value == 'null')
            ? '-'
            : value.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: _mutedText),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _cellText,
              ),
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
              Icon(icon, size: 14, color: _purpleColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _cellText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _openFullScreenImage(context, url, label),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_radius),
              child: Image.network(
                url,
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(_radius),
                  ),
                  child: const Center(
                    child: Text(
                      'Gagal memuat',
                      style:
                          TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AdminActivityData.instance,
      builder: (context, _) => Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _accent),
              )
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
                color: _accent,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final isMobile = width < 700;
                    final isTablet = width >= 700 && width < 1100;

                    final horizontalPadding =
                        isMobile ? 16.0 : (isTablet ? 24.0 : 28.0);
                    final verticalPadding = isMobile ? 16.0 : 28.0;

                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: verticalPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context, isMobile),
                          const SizedBox(height: _gapAfterHeader),
                          _buildTabSelector(isMobile),
                          const SizedBox(height: _gapBetweenSections),

                          if (_selectedTab == 'pending') ...[
                            _summary(isMobile),
                            const SizedBox(height: _gapBetweenSections),
                            partners.isEmpty ? _empty() : _table(isMobile),
                          ] else if (_selectedTab == 'verified') ...[
                            _buildVerifiedList(isMobile),
                          ] else ...[
                            _buildPendingSkillsList(isMobile),
                          ],

                          if (!isLoading &&
                              _selectedTab == 'pending' &&
                              partners.isNotEmpty) ...[
                            const SizedBox(height: _gapBetweenSections),
                            _buildPaginationFullWidth(
                              total: partners.length,
                              currentPage: _pendingPage,
                              onPageChanged: (p) =>
                                  setState(() => _pendingPage = p),
                              label: 'mitra',
                            ),
                          ] else if (_selectedTab == 'verified' &&
                              verifiedPartners.isNotEmpty) ...[
                            const SizedBox(height: _gapBetweenSections),
                            _buildPaginationFullWidth(
                              total: verifiedPartners.length,
                              currentPage: _verifiedPage,
                              onPageChanged: (p) =>
                                  setState(() => _verifiedPage = p),
                              label: 'mitra',
                            ),
                          ] else if (_selectedTab == 'pendingSkills' &&
                              pendingSkillsList.isNotEmpty) ...[
                            const SizedBox(height: _gapBetweenSections),
                            _buildPaginationFullWidth(
                              total: pendingSkillsList.length,
                              currentPage: _skillsPage,
                              onPageChanged: (p) =>
                                  setState(() => _skillsPage = p),
                              label: 'pengajuan',
                            ),
                          ],

                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  // ============================================================
  // HEADER — sama persis dgn DashboardHeader
  // ============================================================

  Widget _buildHeader(BuildContext context, bool isMobile) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Verifikasi Mitra',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
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
              icon: const Icon(Icons.refresh, size: 20, color: _mutedText),
              tooltip: 'Refresh',
              splashRadius: 22,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _subtitleForTab(),
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
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

  // ============================================================
  // TAB SELECTOR
  // ============================================================

  Widget _buildTabSelector(bool mobile) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _tableBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              label: 'Menunggu',
              count: partners.length,
              isActive: _selectedTab == 'pending',
              activeColor: _warningColor,
              onTap: () => setState(() => _selectedTab = 'pending'),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _tabButton(
              label: mobile ? 'Verified' : 'Terverifikasi',
              count: verifiedPartners.length,
              isActive: _selectedTab == 'verified',
              activeColor: _successColor,
              onTap: () => setState(() => _selectedTab = 'verified'),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _tabButton(
              label: mobile ? 'Keahlian' : 'Perubahan Keahlian',
              count: pendingSkillsList.length,
              isActive: _selectedTab == 'pendingSkills',
              activeColor: _purpleColor,
              onTap: () =>
                  setState(() => _selectedTab = 'pendingSkills'),
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
                  color: isActive ? activeColor : _mutedText,
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
                  color: isActive ? activeColor : _mutedText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  Widget _buildPaginationFullWidth({
    required int total,
    required int currentPage,
    required ValueChanged<int> onPageChanged,
    required String label,
  }) {
    if (total == 0) return const SizedBox.shrink();

    final totalPages = _totalPagesFor(total);
    final startItem = (currentPage - 1) * _itemsPerPage + 1;
    final endItem = (startItem + _itemsPerPage - 1).clamp(0, total);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _tableBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              'Menampilkan $startItem–$endItem dari $total $label',
              style: const TextStyle(
                fontSize: 12.5,
                color: _headerText,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _tableBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _itemsPerPage,
                    isDense: true,
                    icon: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: _headerText,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _cellText,
                      fontWeight: FontWeight.w600,
                    ),
                    items: _itemsPerPageOptions
                        .map((n) => DropdownMenuItem<int>(
                              value: n,
                              child: Text('$n / hal'),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _itemsPerPage = v;
                        onPageChanged(1);
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _paginationIconButton(
                icon: Icons.chevron_left,
                onTap: currentPage > 1
                    ? () => onPageChanged(currentPage - 1)
                    : null,
              ),
              const SizedBox(width: 8),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Hal $currentPage / $totalPages',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _paginationIconButton(
                icon: Icons.chevron_right,
                onTap: currentPage < totalPages
                    ? () => onPageChanged(currentPage + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paginationIconButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: onTap == null
                  ? const Color(0xFFE5E7EB)
                  : const Color(0xFFD1D5DB),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: onTap == null
                ? const Color(0xFFD1D5DB)
                : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _summary(bool mobile) {
    final cards = [
      _summaryCard(
        title: 'Menunggu',
        value: waitingCount.toString(),
        subtitle: 'Perlu Ditinjau',
        icon: Icons.hourglass_empty,
        color: _warningColor,
      ),
      _summaryCard(
        title: 'Disetujui',
        value: approvedToday.toString(),
        subtitle: 'Hari Ini',
        icon: Icons.check_circle_outline,
        color: _successColor,
      ),
      _summaryCard(
        title: 'Ditolak',
        value: rejected.toString(),
        subtitle: 'Total',
        icon: Icons.cancel_outlined,
        color: _dangerColor,
      ),
    ];

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i != cards.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _tableBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PENDING TABLE
  // ============================================================

  Widget _table(bool mobile) {
    final pageItems = _paginatedPartners;
    final baseIndex = (_pendingPage - 1) * _itemsPerPage;

    if (mobile) {
      return Column(
        children: List.generate(
          pageItems.length,
          (i) => _mobileCard(pageItems[i], baseIndex + i),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _tableBorder),
      ),
      child: Column(
        children: [
          _tableHeader(),
          ...List.generate(
            pageItems.length,
            (i) => _tableRow(pageItems[i], baseIndex + i),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(_radius)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 25,
            child: Text(
              'Nama Mitra',
              style: TextStyle(
                fontSize: 12,
                color: _headerText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 22,
            child: Text(
              'Kategori',
              style: TextStyle(
                fontSize: 12,
                color: _headerText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              'Kota',
              style: TextStyle(
                fontSize: 12,
                color: _headerText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 15,
            child: Text(
              'Waktu Daftar',
              style: TextStyle(
                fontSize: 12,
                color: _headerText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              'Berkas',
              style: TextStyle(
                fontSize: 12,
                color: _headerText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 24,
            child: Text(
              'Aksi',
              style: TextStyle(
                fontSize: 12,
                color: _headerText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableRow(Map<String, dynamic> p, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _tableDivider)),
      ),
      child: Row(
        children: [
          Expanded(flex: 25, child: _name(p)),
          Expanded(
            flex: 22,
            child: Text(
              p['category']?.toString() ?? '-',
              style: const TextStyle(fontSize: 12.5, color: _cellText),
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              p['city']?.toString() ?? '-',
              style: const TextStyle(fontSize: 12.5, color: _cellText),
            ),
          ),
          Expanded(
            flex: 15,
            child: Text(
              p['time']?.toString() ?? 'Baru saja',
              style: const TextStyle(fontSize: 12.5, color: _mutedText),
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
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _cellText,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          p['email']?.toString() ?? 'Tanpa Email',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
        ),
      ],
    );
  }

  Widget _documentButton(Map<String, dynamic> p) {
    return Align(
      alignment: Alignment.centerLeft,
      child: _pillButton(
        icon: Icons.attach_file,
        label: 'Lihat Berkas',
        bgColor: _purpleColor.withOpacity(0.10),
        fgColor: _purpleColor,
        onTap: () => _viewDocuments(p),
      ),
    );
  }

  Widget _actions(int index) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _pillButton(
          icon: Icons.check,
          label: 'Approve',
          bgColor: _successColor,
          fgColor: Colors.white,
          onTap: isProcessing ? null : () => _approve(index),
        ),
        _pillButton(
          icon: Icons.close,
          label: 'Reject',
          bgColor: _dangerColor.withOpacity(0.10),
          fgColor: _dangerColor,
          onTap: isProcessing ? null : () => _reject(index),
        ),
      ],
    );
  }

  Widget _pillButton({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color fgColor,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: onTap == null ? const Color(0xFFE5E7EB) : bgColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: onTap == null ? const Color(0xFF9CA3AF) : fgColor,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          onTap == null ? const Color(0xFF9CA3AF) : fgColor,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileCard(Map<String, dynamic> p, int index) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _tableBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _name(p),
          const SizedBox(height: 10),
          Text(
            '${p['category'] ?? 'Umum'} • ${p['city'] ?? 'Indonesia'}',
            style: const TextStyle(fontSize: 12, color: _mutedText),
          ),
          Text(
            p['time']?.toString() ?? 'Baru saja',
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 10),
          _documentButton(p),
          const SizedBox(height: 8),
          _actions(index),
        ],
      ),
    );
  }

  // ============================================================
  // VERIFIED LIST
  // ============================================================

  Widget _buildVerifiedList(bool mobile) {
    if (isLoadingVerified && verifiedPartners.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: CircularProgressIndicator(color: _accent),
        ),
      );
    }

    if (verifiedPartners.isEmpty) {
      return _buildEmptyCard(
        icon: Icons.people_outline,
        message: 'Belum ada mitra terverifikasi.',
      );
    }

    final pageItems = _paginatedVerified;

    if (mobile) {
      return Column(
        children: List.generate(
          pageItems.length,
          (i) => _verifiedMobileCard(pageItems[i]),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _tableBorder),
      ),
      child: Column(
        children: [
          _verifiedTableHeader(),
          ...List.generate(
            pageItems.length,
            (i) => _verifiedTableRow(pageItems[i]),
          ),
        ],
      ),
    );
  }

  Widget _verifiedTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(_radius)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 28,
            child: Text(
              'Nama Mitra',
              style: TextStyle(
                fontSize: 12,
                color: _headerText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 22,
            child: Text(
              'Kategori',
              style: TextStyle(
                fontSize: 12,
                color: _headerText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 15,
            child: Text(
              'Kota',
              style: TextStyle(
                fontSize: 12,
                color: _headerText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 12,
            child: Text(
              'Poin',
              style: TextStyle(
                fontSize: 12,
                color: _headerText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 12,
            child: Text(
              'Rating',
              style: TextStyle(
                fontSize: 12,
                color: _headerText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 26,
            child: Text(
              'Aksi',
              style: TextStyle(
                fontSize: 12,
                color: _headerText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verifiedTableRow(Map<String, dynamic> p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _tableDivider)),
      ),
      child: Row(
        children: [
          Expanded(flex: 28, child: _verifiedName(p)),
          Expanded(
            flex: 22,
            child: Text(
              p['category']?.toString() ?? '-',
              style: const TextStyle(fontSize: 12.5, color: _cellText),
            ),
          ),
          Expanded(
            flex: 15,
            child: Text(
              p['city']?.toString() ?? '-',
              style: const TextStyle(fontSize: 12.5, color: _cellText),
            ),
          ),
          Expanded(
            flex: 12,
            child: Row(
              children: [
                const Icon(Icons.stars, size: 13, color: _warningColor),
                const SizedBox(width: 4),
                Text(
                  '${p['point'] ?? 0}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _cellText,
                  ),
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
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _cellText,
                  ),
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
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _cellText,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.verified, size: 14, color: _successColor),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          p['email']?.toString() ?? 'Tanpa Email',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
        ),
      ],
    );
  }

  Widget _verifiedActions(Map<String, dynamic> p) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _pillButton(
          icon: Icons.person_search,
          label: 'Data Lengkap',
          bgColor: _infoColor,
          fgColor: Colors.white,
          onTap: () => _viewFullData(p),
        ),
        _pillButton(
          icon: Icons.folder_open,
          label: 'Berkas',
          bgColor: _purpleColor.withOpacity(0.10),
          fgColor: _purpleColor,
          onTap: () => _viewDocuments(p),
        ),
      ],
    );
  }

  Widget _verifiedMobileCard(Map<String, dynamic> p) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _tableBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _verifiedName(p)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _successColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Terverifikasi',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _successColor,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${p['category'] ?? 'Umum'} • ${p['city'] ?? 'Indonesia'}',
            style: const TextStyle(fontSize: 12, color: _mutedText),
          ),
          Text(
            'Terverifikasi ${p['time'] ?? ''}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.stars, size: 13, color: _warningColor),
              const SizedBox(width: 4),
              Text(
                '${p['point'] ?? 0} poin',
                style: const TextStyle(fontSize: 11),
              ),
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
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _viewFullData(p),
                  icon: const Icon(Icons.person_search, size: 15),
                  label: const Text(
                    'Data Lengkap',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _infoColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_radius),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewDocuments(p),
                  icon: const Icon(Icons.folder_open, size: 15),
                  label: const Text(
                    'Berkas',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    foregroundColor: _purpleColor,
                    side: BorderSide(
                      color: _purpleColor.withOpacity(0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_radius),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PENDING SKILLS LIST
  // ============================================================

  Widget _buildPendingSkillsList(bool mobile) {
    if (isLoadingPendingSkills && pendingSkillsList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: CircularProgressIndicator(color: _accent),
        ),
      );
    }

    if (pendingSkillsList.isEmpty) {
      return _buildEmptyCard(
        icon: Icons.check_circle_outline,
        iconColor: _successColor,
        message: 'Tidak ada pengajuan perubahan keahlian.',
      );
    }

    final pageItems = _paginatedSkills;
    final baseIndex = (_skillsPage - 1) * _itemsPerPage;

    if (mobile) {
      return Column(
        children: List.generate(
          pageItems.length,
          (i) => _pendingSkillMobileCard(pageItems[i], baseIndex + i),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _tableBorder),
      ),
      child: Column(
        children: [
          _pendingSkillTableHeader(),
          ...List.generate(
            pageItems.length,
            (i) => _pendingSkillTableRow(pageItems[i], baseIndex + i),
          ),
        ],
      ),
    );
  }

  Widget _pendingSkillTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(_radius)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 24,
            child: Text(
              'Nama Mitra',
              style: TextStyle(
                fontSize: 12,
                color: _headerText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 20,
            child: Text(
              'Keahlian Saat Ini',
              style: TextStyle(
                fontSize: 12,
                color: _headerText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 20,
            child: Text(
              'Keahlian Baru',
              style: TextStyle(
                fontSize: 12,
                color: _headerText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 14,
            child: Text(
              'Diajukan',
              style: TextStyle(
                fontSize: 12,
                color: _headerText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 30,
            child: Text(
              'Aksi',
              style: TextStyle(
                fontSize: 12,
                color: _headerText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pendingSkillTableRow(Map<String, dynamic> p, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _tableDivider)),
      ),
      child: Row(
        children: [
          Expanded(flex: 24, child: _pendingSkillName(p)),
          Expanded(
            flex: 20,
            child: _chip(
              text: p['current_skills']?.toString() ?? '-',
              bgColor: const Color(0xFFF1F5F9),
              fgColor: const Color(0xFF475569),
            ),
          ),
          Expanded(
            flex: 20,
            child: _chip(
              text: p['pending_skills']?.toString() ?? '-',
              bgColor: _purpleColor.withOpacity(0.10),
              fgColor: _purpleColor,
              bold: true,
            ),
          ),
          Expanded(
            flex: 14,
            child: Text(
              p['time']?.toString() ?? 'Baru saja',
              style: const TextStyle(fontSize: 12, color: _mutedText),
            ),
          ),
          Expanded(flex: 30, child: _pendingSkillActions(index)),
        ],
      ),
    );
  }

  Widget _chip({
    required String text,
    required Color bgColor,
    required Color fgColor,
    bool bold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: fgColor,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
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
            color: const Color(0xFFF9FAFB),
            border: Border.all(color: _tableBorder),
          ),
          child: ClipOval(
            child: url.isNotEmpty
                ? Image.network(
                    url,
                    width: 34,
                    height: 34,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person,
                      size: 18,
                      color: _mutedText,
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 18,
                    color: _mutedText,
                  ),
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
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _cellText,
                ),
              ),
              Text(
                p['email']?.toString() ?? '-',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
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
        _pillButton(
          icon: Icons.photo_library_outlined,
          label: 'Foto Bukti',
          bgColor: _purpleColor.withOpacity(0.10),
          fgColor: _purpleColor,
          onTap: () => _viewSkillPhotos(pendingSkillsList[index]),
        ),
        _pillButton(
          icon: Icons.check,
          label: 'Setujui',
          bgColor: _successColor,
          fgColor: Colors.white,
          onTap: isProcessing ? null : () => _approveSkill(index),
        ),
        _pillButton(
          icon: Icons.close,
          label: 'Tolak',
          bgColor: _dangerColor.withOpacity(0.10),
          fgColor: _dangerColor,
          onTap: isProcessing ? null : () => _rejectSkill(index),
        ),
      ],
    );
  }

  Widget _pendingSkillMobileCard(Map<String, dynamic> p, int index) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _tableBorder),
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
                    const Text(
                      'Keahlian Saat Ini',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                    const SizedBox(height: 4),
                    _chip(
                      text: p['current_skills']?.toString() ?? '-',
                      bgColor: const Color(0xFFF1F5F9),
                      fgColor: const Color(0xFF475569),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Keahlian Baru',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                    const SizedBox(height: 4),
                    _chip(
                      text: p['pending_skills']?.toString() ?? '-',
                      bgColor: _purpleColor.withOpacity(0.10),
                      fgColor: _purpleColor,
                      bold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Diajukan: ${p['time'] ?? 'Baru saja'}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 12),
          _pendingSkillActions(index),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY CARD
  // ============================================================

  Widget _empty() {
    return _buildEmptyCard(
      icon: Icons.verified_outlined,
      message: 'Tidak ada mitra yang perlu diverifikasi.',
    );
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String message,
    Color? iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _tableBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 34,
              color: iconColor ?? _accent.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: _mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FULLSCREEN IMAGE VIEWER
// ============================================================

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
                child: CircularProgressIndicator(color: Color(0xFFF97316)),
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