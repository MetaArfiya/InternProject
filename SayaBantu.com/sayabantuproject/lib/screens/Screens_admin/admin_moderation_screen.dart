import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart'; // Sesuaikan path import ApiService Anda
import '../../data/admin_activity_data.dart';

class AdminModerationScreen extends StatefulWidget {
  final ValueChanged<int>? onFlaggedCountChanged;

  const AdminModerationScreen({
    super.key,
    this.onFlaggedCountChanged,
  });

  @override
  State<AdminModerationScreen> createState() =>
      _AdminModerationScreenState();
}

class _AdminModerationScreenState
    extends State<AdminModerationScreen> {
  
  List<Map<String, dynamic>> posts = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  // =========================================================
  // AMBIL DATA DARI API LARAVEL
  // =========================================================
  Future<void> _fetchJobs() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Pastikan endpoint ini sesuai dengan rute admin di api.php
      final response = await ApiService.get('/admin/jobs-moderation');

      print("RESPON MODERASI: ${response.body}"); // Debugging untuk lihat isi JSON di console

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        
        // Menangani jika respons berupa List langsung atau dibungkus dalam key 'data' (atau paginasi Laravel)
        List<dynamic> rawData = [];
        if (decoded is List) {
          rawData = decoded;
        } else if (decoded is Map) {
          if (decoded.containsKey('data') && decoded['data'] is List) {
            rawData = decoded['data'];
          } else if (decoded.containsKey('jobs') && decoded['jobs'] is List) {
            rawData = decoded['jobs'];
          }
        }

        setState(() {
          posts = rawData.map((item) => {
            'id': item['id'],
            'pelanggan_id': item['pelanggan_id'] ?? item['user_id'],
            'mitra_id': item['mitra_id'],
            'title': item['tittle'] ?? item['judul'] ?? item['headline'] ?? 'Tanpa Judul',
            'description': item['description'] ?? item['deskripsi'],
            'location': item['location'] ?? item['lokasi'],
            'image_url': item['image_url'],
            'initial_budget': item['initial_budget'] ?? item['budget'],
            'final_price': item['final_price'],
            
            // Konversi status berdasarkan is_verified atau status dari database Laravel
            'status': (item['is_verified'] == 0 || item['is_verified'] == false || item['status'] == 'pending') 
                ? 'flagged' 
                : 'safe', 
                
            'user': item['pelanggan']?['name'] ?? item['user']?['name'] ?? item['nama_pelanggan'] ?? 'Pengguna',
            'time': _formatDate(item['created_at']),
          }).toList();
          isLoading = false;
        });

        _syncFlaggedCount();
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Gagal memuat data (Code: ${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Terjadi kesalahan koneksi: $e';
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Baru saja';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      return '${diff.inDays} hari lalu';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 700;
        final isTablet = screenWidth >= 700 && screenWidth < 1100;
        final isDesktop = screenWidth >= 1100;

        return _buildContent(
          context,
          isMobile: isMobile,
          isTablet: isTablet,
          isDesktop: isDesktop,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF4F7FB),
      child: RefreshIndicator(
        onRefresh: _fetchJobs,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            isMobile ? 16 : 26,
            isMobile ? 18 : 28,
            isMobile ? 16 : 26,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Moderasi Konten',
                    style: TextStyle(
                      fontSize: isMobile ? 23 : (isTablet ? 25 : 27),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    onPressed: _fetchJobs,
                    icon: const Icon(Icons.refresh, color: Color(0xFF7C3AED)),
                    tooltip: 'Muat Ulang',
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                '${_flaggedCount()} postingan membutuhkan pemeriksaan',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 22),
              _buildStatistics(isMobile: isMobile, isTablet: isTablet),
              const SizedBox(height: 22),
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 50),
                    child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                  ),
                )
              else if (errorMessage.isNotEmpty)
                _errorState(errorMessage)
              else if (posts.isEmpty)
                _emptyState()
              else if (isMobile || isTablet)
                _buildResponsiveCards(context)
              else
                _buildDesktopTable(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics({required bool isMobile, required bool isTablet}) {
    final statistics = [
      {
        'title': 'Perlu Ditinjau',
        'value': _flaggedCount().toString(),
        'icon': Icons.flag_outlined,
        'color': const Color(0xFFF59E0B),
      },
      {
        'title': 'Konten Aman',
        'value': _safeCount().toString(),
        'icon': Icons.check_circle_outline,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Total Postingan',
        'value': posts.length.toString(),
        'icon': Icons.article_outlined,
        'color': const Color(0xFF6366F1),
      },
    ];

    if (isMobile) {
      return Column(
        children: statistics.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _statCard(
              title: item['title'] as String,
              value: item['value'] as String,
              icon: item['icon'] as IconData,
              iconColor: item['color'] as Color,
            ),
          );
        }).toList(),
      );
    }

    if (isTablet) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: statistics.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 3.2,
        ),
        itemBuilder: (context, index) {
          final item = statistics[index];
          return _statCard(
            title: item['title'] as String,
            value: item['value'] as String,
            icon: item['icon'] as IconData,
            iconColor: item['color'] as Color,
          );
        },
      );
    }

    return Row(
      children: statistics.map((item) {
        final isLast = item == statistics.last;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 10),
            child: _statCard(
              title: item['title'] as String,
              value: item['value'] as String,
              icon: item['icon'] as IconData,
              iconColor: item['color'] as Color,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFDCE3EC)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildTableHeader(),
          ...posts.map((post) => _buildTableRow(context, post)),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: [
          Expanded(flex: 4, child: _headerText('Judul Postingan')),
          Expanded(flex: 2, child: _headerText('Pengguna')),
          Expanded(flex: 2, child: _headerText('Waktu')),
          Expanded(flex: 2, child: _headerText('Status')),
          const SizedBox(width: 275, child: Text('Aksi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF334155)))),
        ],
      ),
    );
  }

  Widget _headerText(String text) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Color(0xFF334155),
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, Map<String, dynamic> post) {
    final bool flagged = post['status'] == 'flagged';

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 62),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              post['title'] as String,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              post['user'] as String,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              post['time'] as String,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _statusBadge(flagged),
            ),
          ),
          SizedBox(
            width: 275,
            child: _desktopActions(context, post),
          ),
        ],
      ),
    );
  }

  Widget _desktopActions(BuildContext context, Map<String, dynamic> post) {
    final bool flagged = post['status'] == 'flagged';

    return Row(
      children: [
        _viewButton(context, post),
        if (flagged) ...[
          const SizedBox(width: 6),
          _safeButton(context, post),
          const SizedBox(width: 6),
          _deleteButton(context, post),
        ],
      ],
    );
  }

  Widget _buildResponsiveCards(BuildContext context) {
    return Column(
      children: posts.map((post) => _buildPostCard(context, post)).toList(),
    );
  }

  Widget _buildPostCard(BuildContext context, Map<String, dynamic> post) {
    final bool flagged = post['status'] == 'flagged';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCE3EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post['title'] as String,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.person_outline, 'Pengguna', post['user'] as String),
          const SizedBox(height: 8),
          _infoRow(Icons.access_time, 'Waktu', post['time'] as String),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.flag_outlined, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 7),
              const Text('Status', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const SizedBox(width: 8),
              _statusBadge(flagged),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFE2E8F0), height: 1),
          const SizedBox(height: 13),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _viewButton(context, post),
              if (flagged) _safeButton(context, post),
              if (flagged) _deleteButton(context, post),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 7),
        Text('$title: ', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(bool flagged) {
    return Container(
      constraints: const BoxConstraints(minWidth: 78),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: flagged ? const Color(0xFFFFF7ED) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        flagged ? 'Ditandai' : 'Aman',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: flagged ? const Color(0xFFD97706) : const Color(0xFF059669),
        ),
      ),
    );
  }

  Widget _viewButton(BuildContext context, Map<String, dynamic> post) {
    return ElevatedButton.icon(
      onPressed: () => _showPostDetail(context, post),
      icon: const Icon(Icons.visibility_outlined, size: 13),
      label: const Text('Lihat', style: TextStyle(fontSize: 10)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFEDE9FE),
        foregroundColor: const Color(0xFF7C3AED),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        minimumSize: const Size(0, 34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
    );
  }

  Widget _safeButton(BuildContext context, Map<String, dynamic> post) {
    return ElevatedButton.icon(
      onPressed: () => _confirmSafePost(context, post),
      icon: const Icon(Icons.check, size: 13),
      label: const Text('Aman', style: TextStyle(fontSize: 10)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        minimumSize: const Size(0, 34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
    );
  }

  void _confirmSafePost(BuildContext context, Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Moderasi'),
          content: const Text('Apakah kamu yakin postingan ini aman dan dapat ditampilkan kepada pengguna?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _markPostAsSafe(context, post);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
              child: const Text('Ya, Aman'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _markPostAsSafe(BuildContext context, Map<String, dynamic> post) async {
  try {
    // Ubah action dari 'suspend' menjadi 'safe' agar sesuai dengan tombol Aman
    final response = await ApiService.post('/admin/jobs-moderate/${post['id']}', {
      'action': 'safe', 
    });

    print("STATUS CODE: ${response.statusCode}");
    print("BODY RESPON: ${response.body}");

    if (response.statusCode == 200) {
      setState(() {
        post['status'] = 'safe'; // Ubah status UI menjadi 'safe' (Aman)
      });

      _syncFlaggedCount();
      AdminActivityData.addModeratedPost();
      _showMessage(context, 'Postingan ditandai sebagai aman.', const Color(0xFF10B981));
    } else {
      _showMessage(context, 'Gagal mengubah status (Code: ${response.statusCode})', const Color(0xFFEF4444));
    }
  } catch (e) {
    _showMessage(context, 'Error: $e', const Color(0xFFEF4444));
  }
}

  Widget _deleteButton(BuildContext context, Map<String, dynamic> post) {
    return OutlinedButton.icon(
      onPressed: () => _confirmDeletePost(context, post),
      icon: const Icon(Icons.delete_outline, size: 13),
      label: const Text('Hapus', style: TextStyle(fontSize: 10)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFEF4444),
        side: const BorderSide(color: Color(0xFFFCA5A5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        minimumSize: const Size(0, 34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
    );
  }

  void _confirmDeletePost(BuildContext context, Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Postingan'),
          content: const Text('Apakah kamu yakin ingin menghapus postingan ini? Tindakan ini tidak dapat dibatalkan.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _deletePost(context, post);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePost(BuildContext context, Map<String, dynamic> post) async {
    final bool wasFlagged = post['status'] == 'flagged';

    try {
      // Panggil API Delete ke backend Laravel
      final response = await ApiService.delete('/jobs/${post['id']}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          posts.remove(post);
        });

        if (wasFlagged) {
          _syncFlaggedCount();
        }

        AdminActivityData.addRejectedPost();
        _showMessage(context, 'Postingan berhasil dihapus.', const Color(0xFFEF4444));
      } else {
        _showMessage(context, 'Gagal menghapus postingan dari server.', const Color(0xFFEF4444));
      }
    } catch (e) {
      _showMessage(context, 'Error: $e', const Color(0xFFEF4444));
    }
  }

  void _showPostDetail(BuildContext context, Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final bool flagged = post['status'] == 'flagged';

        return AlertDialog(
          title: Text(post['title'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pengguna: ${post['user']}'),
                const SizedBox(height: 8),
                Text('Deskripsi: ${post['description'] ?? '-'}'),
                const SizedBox(height: 8),
                Text('Lokasi: ${post['location'] ?? '-'}'),
                const SizedBox(height: 8),
                Text('Budget Awal: Rp ${post['initial_budget'] ?? 0}'),
                const SizedBox(height: 8),
                Text('Waktu: ${post['time']}'),
                const SizedBox(height: 8),
                Text('Status: ${flagged ? 'Ditandai' : 'Aman'}'),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Tutup')),
          ],
        );
      },
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFDCE3EC)),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle_outline, size: 42, color: Color(0xFF10B981)),
          SizedBox(height: 10),
          Text(
            'Tidak ada postingan yang perlu diperiksa',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _errorState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFDCE3EC)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 42, color: Color(0xFFEF4444)),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF334155), fontSize: 13),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: _fetchJobs,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  int _flaggedCount() {
    return posts.where((post) => post['status'] == 'flagged').length;
  }

  int _safeCount() {
    return posts.where((post) => post['status'] == 'safe').length;
  }

  void _syncFlaggedCount() {
    final count = _flaggedCount();
    widget.onFlaggedCountChanged?.call(count);
  }

  void _showMessage(BuildContext context, String message, [Color? color]) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? const Color(0xFF7C3AED),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}