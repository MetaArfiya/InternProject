import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/payment_service.dart';
import '../../services/api_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/app_colors.dart';
import '../../theme/admin_theme_provider.dart';

class AdminWithdrawScreen extends StatefulWidget {
  const AdminWithdrawScreen({super.key});

  @override
  State<AdminWithdrawScreen> createState() => AdminWithdrawScreenState(); // UBAH: Hapus underscore
}

// UBAH: Nama class tanpa underscore agar bisa diakses GlobalKey
class AdminWithdrawScreenState extends State<AdminWithdrawScreen> {
  AdminTheme get theme => AdminThemeProvider.of(context);

  bool _isLoading = true;
  List<dynamic> _withdrawals = [];
  int? _processingId;

  // Pagination State
  int _currentPage = 1;
  int _itemsPerPage = 10;
  final List<int> _itemsPerPageOptions = [5, 10, 25, 50];

  static const double _radius = 10;
  static const double _cardRadius = 14;

  @override
  void initState() {
    super.initState();
    _loadWithdrawals();
  }

  // TAMBAHKAN FUNGSI INI UNTUK DIPANGGIL DARI LUAR
  void refreshData() {
    _loadWithdrawals();
  }

  Future<void> _loadWithdrawals() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/admin/withdrawals');
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['success'] == true) {
        setState(() {
          _withdrawals = decoded['data'];
          _currentPage = 1; // Reset ke halaman 1
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _process(int id) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();

    setState(() => _processingId = id);

    final result = await PaymentService.processWithdrawal(
      withdrawalId: id,
      imageBytes: bytes,
      note: 'Transfer berhasil',
    );

    if (!mounted) return;
    setState(() => _processingId = null);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Berhasil diproses'), backgroundColor: theme.success),
      );
      _loadWithdrawals();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Gagal memproses'), backgroundColor: theme.danger),
      );
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================
  List<dynamic> get _paginatedWithdrawals {
    if (_withdrawals.isEmpty) return [];
    final start = (_currentPage - 1) * _itemsPerPage;
    if (start >= _withdrawals.length) return [];
    final end = (start + _itemsPerPage).clamp(0, _withdrawals.length);
    return _withdrawals.sublist(start, end);
  }

  int get _totalPages {
    if (_withdrawals.isEmpty) return 1;
    return ((_withdrawals.length - 1) ~/ _itemsPerPage) + 1;
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
  // BUILD
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
        onRefresh: _loadWithdrawals,
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
                  Text('Proses Withdraw', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: t.cellText)),
                  const SizedBox(height: 6),
                  Text('Proses penarikan saldo pengguna ke rekening bank.', style: textTheme.bodyMedium?.copyWith(color: t.mutedText)),
                  const SizedBox(height: 24),

                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator(color: t.accent)),
                    )
                  else if (_withdrawals.isEmpty)
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

  // ============================================================
  // DESKTOP TABLE
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
              horizontalMargin: 24,
              columnSpacing: 24,
              headingRowHeight: 52,
              dataRowMinHeight: 64,
              dataRowMaxHeight: 82,
              headingTextStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: t.headerText),
              headingRowColor: WidgetStateProperty.all(AppColors.grey50),
              dividerThickness: 0.6,
              columns: const [
                DataColumn(label: Text('ID TARIK')),
                DataColumn(label: Text('PENGGUNA')),
                DataColumn(label: Text('NOMINAL')),
                DataColumn(label: Text('REKENING TUJUAN')),
                DataColumn(label: Text('BUKTI')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('AKSI')),
              ],
              rows: _paginatedWithdrawals.map((w) {
                final isPending = w['status'] == 'pending';
                final isProcessing = _processingId == w['id'];
                final userBank = w['user'] is Map ? w['user'] as Map : const {};
                final bankName = _firstNonEmpty(w['bank_name'], userBank['bank_name']);
                final accountNumber = _firstNonEmpty(w['account_number'], userBank['bank_account_number']);
                final accountName = _firstNonEmpty(w['account_name'], userBank['bank_account_name'], userBank['name']);
                
                // Ambil URL bukti transfer
                final proofPath = w['transfer_proof_url']?.toString() ?? '';
                final filename = proofPath.split('/').last;
                final imageUrl = proofPath.isNotEmpty ? 'http://127.0.0.1:8000/api/images/withdraw_proofs/$filename' : null;

                return DataRow(
                  cells: [
                    DataCell(Text('WD-${w['id']}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: t.cellText))),
                    DataCell(SizedBox(width: 130, child: Text(w['user']?['name'] ?? '-', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: t.cellText)))),
                    DataCell(Text('Rp ${w['amount']}', style: TextStyle(fontWeight: FontWeight.w700, color: t.danger))),
                    DataCell(
                      SizedBox(
                        width: 160,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$bankName - $accountNumber', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: t.cellText)),
                            Text('A.n. $accountName', style: TextStyle(fontSize: 11, color: t.mutedText)),
                          ],
                        ),
                      )
                    ),
                    // KOLOM BUKTI
                    DataCell(
                      imageUrl != null
                          ? GestureDetector(
                              onTap: () => _showImageDialog(imageUrl),
                              child: Container(
                                width: 50, height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6), 
                                  border: Border.all(color: t.border), 
                                  image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                                ),
                              ),
                            )
                          : Text('-', style: TextStyle(color: t.mutedText)),
                    ),
                    DataCell(_statusBadge(w['status'])),
                    DataCell(
                      isProcessing
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : isPending 
                            ? _pillButton(
                                icon: Icons.upload_file, label: 'Proses', 
                                bgColor: t.accent.withValues(alpha: 0.1), fgColor: t.accent,
                                onTap: () => _process(w['id'])
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

  // ============================================================
  // MOBILE LIST
  // ============================================================
  Widget _buildMobileList() {
    final t = theme;
    return Column(
      children: _paginatedWithdrawals.map((w) {
        final isPending = w['status'] == 'pending';
        final isProcessing = _processingId == w['id'];
        final userBank = w['user'] is Map ? w['user'] as Map : const {};
        final bankName = _firstNonEmpty(w['bank_name'], userBank['bank_name']);
        final accountNumber = _firstNonEmpty(w['account_number'], userBank['bank_account_number']);
        final accountName = _firstNonEmpty(w['account_name'], userBank['bank_account_name'], userBank['name']);
        
        final proofPath = w['transfer_proof_url']?.toString() ?? '';
        final filename = proofPath.split('/').last;
        final imageUrl = proofPath.isNotEmpty ? 'http://127.0.0.1:8000/api/images/withdraw_proofs/$filename' : null;

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
                  Text('WD-${w['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  _statusBadge(w['status']),
                ],
              ),
              const SizedBox(height: 8),
              Text('User: ${w['user']?['name'] ?? '-'}'),
              Text('Nominal: Rp ${w['amount']}', style: TextStyle(fontWeight: FontWeight.bold, color: t.danger)),
              Text('Rekening tujuan: $bankName - $accountNumber'),
              Text('Atas nama: $accountName'),
              
              // TAMPILKAN GAMBAR BUKTI DI MOBILE
              if (imageUrl != null) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _showImageDialog(imageUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(imageUrl, height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Text('Gagal load gambar')),
                  ),
                ),
              ],

              const SizedBox(height: 12),
              if (isPending)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isProcessing ? null : () => _process(w['id']),
                    icon: isProcessing 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.upload_file),
                    label: Text(isProcessing ? 'Memproses...' : 'Upload Bukti Transfer & Selesai'),
                    style: ElevatedButton.styleFrom(backgroundColor: t.accent, foregroundColor: Colors.white),
                  ),
                )
            ],
          ),
        );
      }).toList(),
    );
  }

  String _firstNonEmpty(Object? first, [Object? second, Object? third]) {
    for (final value in [first, second, third]) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text != 'null') return text;
    }
    return '-';
  }

  Widget _statusBadge(String status) {
    final t = theme;
    final isPending = status == 'pending';
    final color = isPending ? Colors.orange : t.success;
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
            Icon(Icons.money_off_csred_outlined, size: 48, color: t.mutedText),
            const SizedBox(height: 12),
            Text('Belum ada pengajuan penarikan.', style: TextStyle(color: t.mutedText)),
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
    final total = _withdrawals.length;
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
            'Menampilkan $startItem–$endItem dari $total',
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
