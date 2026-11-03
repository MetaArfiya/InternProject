import 'dart:convert';
import 'package:flutter/material.dart';

import '../../services/payment_service.dart';
import '../../services/api_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_colors.dart';
import '../../theme/admin_theme_provider.dart';

class AdminTopupScreen extends StatefulWidget {
  const AdminTopupScreen({super.key});

  @override
  State<AdminTopupScreen> createState() => AdminTopupScreenState(); // Diubah publik untuk GlobalKey
}

class AdminTopupScreenState extends State<AdminTopupScreen> {
  AdminTheme get theme => AdminThemeProvider.of(context);

  // ============================================================
  // STATE (Dibuat mirip dengan Kode 1)
  // ============================================================
  bool _isLoading = true;
  String? _errorMessage; // Tambahan untuk handle error seperti Kode 1
  
  List<dynamic> _topups = [];
  int? _processingId;

  // Pagination State
  int _currentPage = 1;
  int _itemsPerPage = 10;
  final List<int> _itemsPerPageOptions = [5, 10, 25, 50];

  static const double _radius = 10;
  static const double _cardRadius = 14;

  // ============================================================
  // LIFECYCLE
  // ============================================================
  @override
  void initState() {
    super.initState();
    _loadTopups();
  }

  // TAMBAHKAN FUNGSI INI UNTUK REFRESH DARI LUAR (GlobalKey)
  void refreshData() {
    _loadTopups();
  }

  // ============================================================
  // LOAD DATA (Dibuat mirip dengan Kode 1)
  // ============================================================
  Future<void> _loadTopups() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.get('/admin/topups');
      final decoded = jsonDecode(response.body);

      if (response.statusCode != 200) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat (${response.statusCode})';
        });
        return;
      }

      if (decoded['success'] != true) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = decoded['message']?.toString() ?? 'Gagal memuat data topup.';
        });
        return;
      }

      if (!mounted) return;

      final list = decoded['data'] is List ? decoded['data'] as List : [];

      setState(() {
        _topups = list;
        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ ERROR TOPUP: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan saat memuat data.';
      });
    }
  }

  // ============================================================
  // VERIFY TOPUP
  // ============================================================
  Future<void> _verify(int id, String action) async {
    if (_processingId != null) return;
    setState(() => _processingId = id);

    final result = await PaymentService.verifyTopup(
      topupId: id,
      action: action,
      note: action == 'approve' ? 'Valid' : 'Bukti tidak sesuai',
    );

    if (!mounted) return;
    setState(() => _processingId = null);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(action == 'approve' ? 'Topup disetujui' : 'Topup ditolak'),
          backgroundColor: action == 'approve' ? theme.success : theme.danger,
        ),
      );
      _loadTopups();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Gagal memproses'), backgroundColor: theme.danger),
      );
    }
  }

  // ============================================================
  // PAGINATION LOGIC
  // ============================================================
  List<dynamic> get _paginatedTopups {
    if (_topups.isEmpty) return [];
    final start = (_currentPage - 1) * _itemsPerPage;
    if (start >= _topups.length) return [];
    final end = (start + _itemsPerPage).clamp(0, _topups.length);
    return _topups.sublist(start, end);
  }

  int get _totalPages {
    if (_topups.isEmpty) return 1;
    return ((_topups.length - 1) ~/ _itemsPerPage) + 1;
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() => _currentPage = page);
  }

  void _changeItemsPerPage(int value) {
    setState(() {
      _itemsPerPage = value;
      _currentPage = 1;
    });
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Image.network(imageUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 64)),
            ),
            Positioned(
              top: 10, right: 10,
              child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context)),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD (Struktur mirip Kode 1)
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final t = theme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: t.bg,
      child: RefreshIndicator(
        onRefresh: _loadTopups,
        color: t.accent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(isMobile ? 16 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Verifikasi Topup', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: t.cellText)),
                  const SizedBox(height: 6),
                  Text('Kelola pengajuan topup saldo dari pengguna.', style: textTheme.bodyMedium?.copyWith(color: t.mutedText)),
                  const SizedBox(height: 24),

                  // Struktur pengecekan mirip Kode 1
                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator(color: t.accent)),
                    )
                  else if (_errorMessage != null)
                    _buildErrorState() // Tambahan Widget Error
                  else if (_topups.isEmpty)
                    _buildEmptyState()
                  else ...[
                    isMobile ? _buildMobileList() : _buildDesktopTable(constraints.maxWidth),
                    _buildPagination(isMobile),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Widget Error State (Diambil dari Kode 1)
  Widget _buildErrorState() {
    final t = theme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: t.danger.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: t.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: t.danger, size: 48),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: t.danger, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadTopups,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: t.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DESKTOP TABLE (Tidak ada perubahan berarti)
  // ============================================================
  Widget _buildDesktopTable(double maxWidth) {
    final t = theme;
    final textTheme = Theme.of(context).textTheme;
    final isTablet = maxWidth >= 700 && maxWidth < 1100;
    final tableWidth = maxWidth - (isTablet ? 48.0 : 56.0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: t.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: tableWidth),
            child: DataTable(
              horizontalMargin: 20,
              columnSpacing: 24,
              headingRowHeight: 48,
              dataRowMinHeight: 56,
              dataRowMaxHeight: 88,
              headingTextStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: t.headerText),
              headingRowColor: WidgetStateProperty.all(AppColors.grey50),
              dividerThickness: 0.6,
              columns: const [
                DataColumn(label: Text('ID TOPUP')),
                DataColumn(label: Text('PENGGUNA')),
                DataColumn(label: Text('NOMINAL')),
                DataColumn(label: Text('BUKTI')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('AKSI')),
              ],
              rows: _paginatedTopups.map((topup) {
                final proofPath = topup['proof_url']?.toString() ?? '';
                final filename = proofPath.split('/').last;
                final imageUrl = 'http://127.0.0.1:8000/api/images/topup_proofs/$filename';
                final isPending = topup['status'] == 'waiting_verification';
                final isProcessing = _processingId == topup['id'];

                return DataRow(
                  cells: [
                    DataCell(Text('TP-${topup['id']}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: t.cellText))),
                    DataCell(SizedBox(width: 150, child: Text(topup['user']?['name'] ?? '-', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: t.cellText)))),
                    DataCell(Text('Rp ${topup['amount']}', style: TextStyle(fontWeight: FontWeight.w700, color: t.success))),
                    DataCell(
                      proofPath.isNotEmpty 
                        ? GestureDetector(
                            onTap: () => _showImageDialog(imageUrl),
                            child: Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: t.border), image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)),
                            ),
                          )
                        : const Text('-'),
                    ),
                    DataCell(_statusBadge(topup['status'])),
                    DataCell(
                      isProcessing
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : isPending 
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _pillButton(
                                  icon: Icons.close, label: 'Tolak', 
                                  bgColor: t.danger.withValues(alpha: 0.1), fgColor: t.danger,
                                  onTap: () => _verify(topup['id'], 'reject')
                                ),
                                const SizedBox(width: 8),
                                _pillButton(
                                  icon: Icons.check, label: 'Approve', 
                                  bgColor: t.success.withValues(alpha: 0.1), fgColor: t.success,
                                  onTap: () => _verify(topup['id'], 'approve')
                                ),
                              ],
                            )
                          : Text('Selesai', style: TextStyle(fontSize: 12, color: t.mutedText)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    final t = theme;
    return Column(
      children: _paginatedTopups.map((topup) {
        final proofPath = topup['proof_url']?.toString() ?? '';
        final filename = proofPath.split('/').last;
        final imageUrl = 'http://127.0.0.1:8000/api/images/topup_proofs/$filename';
        final isPending = topup['status'] == 'waiting_verification';
        final isProcessing = _processingId == topup['id'];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white, 
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(color: t.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('TP-${topup['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  _statusBadge(topup['status']),
                ],
              ),
              const SizedBox(height: 8),
              Text('User: ${topup['user']?['name'] ?? '-'}'),
              Text('Nominal: Rp ${topup['amount']}', style: TextStyle(fontWeight: FontWeight.bold, color: t.success)),
              const SizedBox(height: 12),
              if (proofPath.isNotEmpty)
                GestureDetector(
                  onTap: () => _showImageDialog(imageUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(imageUrl, height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Text('Gagal load gambar')),
                  ),
                ),
              if (isPending) ...[
                const SizedBox(height: 12),
                isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: () => _verify(topup['id'], 'reject'), style: OutlinedButton.styleFrom(foregroundColor: t.danger), child: const Text('Tolak'))),
                        const SizedBox(width: 8),
                        Expanded(child: ElevatedButton(onPressed: () => _verify(topup['id'], 'approve'), style: ElevatedButton.styleFrom(backgroundColor: t.success), child: const Text('Approve', style: TextStyle(color: Colors.white)))),
                      ],
                    )
              ]
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _statusBadge(String status) {
    final t = theme;
    final isPending = status == 'waiting_verification';
    final color = isPending ? Colors.orange : (status == 'approved' ? t.success : t.danger);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 10.5)),
    );
  }

  Widget _pillButton({required IconData icon, required String label, required Color bgColor, required Color fgColor, required VoidCallback onTap}) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fgColor),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: fgColor, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final t = theme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 48, color: t.mutedText),
            const SizedBox(height: 12),
            Text('Belum ada pengajuan topup.', style: TextStyle(color: t.mutedText)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PAGINATION UI
  // ============================================================
  Widget _buildPagination(bool isMobile) {
    final t = theme;
    final total = _topups.length;
    if (total == 0) return const SizedBox.shrink();
    
    final totalPages = _totalPages;
    final startItem = (_currentPage - 1) * _itemsPerPage + 1;
    final endItem = (startItem + _itemsPerPage - 1).clamp(0, total);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white, 
        borderRadius: BorderRadius.circular(_radius), 
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          // KIRI: Info Teks
          Text(
            'Menampilkan $startItem–$endItem dari $total top up',
            style: TextStyle(fontSize: 12.5, color: t.headerText, fontWeight: FontWeight.w500),
          ),
          
          const Spacer(),

          // KANAN: Kontrol Pagination
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dropdown Rows Per Page
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: t.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _itemsPerPage,
                    isDense: true,
                    icon: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(Icons.keyboard_arrow_down, size: 16, color: t.headerText),
                    ),
                    style: TextStyle(fontSize: 12.5, color: t.cellText, fontWeight: FontWeight.w600),
                    items: _itemsPerPageOptions
                        .map((n) => DropdownMenuItem<int>(value: n, child: Text('$n / hal')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _changeItemsPerPage(v);
                    },
                  ),
                ),
              ),
              
              const SizedBox(width: 12),

              // Tombol Prev
              _navButton(
                icon: Icons.chevron_left, 
                enabled: _currentPage > 1, 
                onTap: () => _goToPage(_currentPage - 1),
              ),
              
              const SizedBox(width: 8),
              
              // Indikator Halaman
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Hal $_currentPage / $totalPages',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: t.accent),
                ),
              ),
              
              const SizedBox(width: 8),

              // Tombol Next
              _navButton(
                icon: Icons.chevron_right, 
                enabled: _currentPage < totalPages, 
                onTap: () => _goToPage(_currentPage + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navButton({required IconData icon, required bool enabled, required VoidCallback onTap}) {
    final t = theme;
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8), 
            border: Border.all(color: enabled ? AppColors.grey300 : t.border)
          ),
          child: Icon(icon, size: 18, color: enabled ? AppColors.grey700 : AppColors.grey300),
        ),
      ),
    );
  }
}
