import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/indonesia_time.dart';
import 'topup_dialog.dart';
import 'withdraw_dialog.dart';

class WalletScreen extends StatefulWidget {
  final String role; // 'mitra' atau 'pelanggan'

  const WalletScreen({super.key, required this.role});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  double _balance = 0;
  double _heldBalance = 0;
  List<dynamic> _transactions = [];

  // --- STATE PAGINATION ---
  int _currentPage = 1;
  int _rowsPerPage = 10;
  static const List<int> _rowsPerPageOptions = [10, 25, 50, 100];

  static const Color _accent = AppColors.primaryTeal;
  static const Color _tableBorder = Color(0xFFE5E7EB);
  static const Color _tableDivider = Color(0xFFF3F4F6);
  static const Color _headerText = AppColors.grey500;
  static const Color _cellText = AppColors.grey900;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1; // Reset halaman saat load data baru
    });

    try {
      final response = await ApiService.get('/wallet');
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded['success'] == true) {
        if (!mounted) return;
        setState(() {
          _balance =
              double.tryParse(decoded['data']['saldo_tersedia'].toString()) ??
              0;
          _heldBalance =
              double.tryParse(decoded['data']['saldo_ditahan'].toString()) ?? 0;
          _transactions = decoded['data']['transactions'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = decoded['message'] ?? 'Gagal memuat dompet.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Koneksi error: $e';
      });
    }
  }

  String _formatRupiah(double amount) {
    final str = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  String _formatDate(String dateString) {
    try {
      final parsed = IndonesiaTime.tryParseApiTimestamp(dateString);
      if (parsed == null) return dateString;
      final date = IndonesiaTime.toWall(parsed);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}, '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateString;
    }
  }

  // ============================================================
  // LOGIKA PAGINATION
  // ============================================================
  int get _totalPages {
    if (_transactions.isEmpty) return 1;
    return (_transactions.length / _rowsPerPage).ceil();
  }

  List<dynamic> get _pagedTransactions {
    final start = (_currentPage - 1) * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, _transactions.length);
    if (start >= _transactions.length) return [];
    return _transactions.sublist(start, end);
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() => _currentPage = page);
  }

  void _changeRowsPerPage(int value) {
    setState(() {
      _rowsPerPage = value;
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
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.sectionAltLight,
      child: RefreshIndicator(
        onRefresh: _loadWallet,
        color: _accent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 28,
                vertical: isMobile ? 16 : 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: CircularProgressIndicator(color: _accent),
                      ),
                    )
                  else if (_errorMessage != null)
                    _buildErrorState()
                  else ...[
                    _buildSummaryCards(isMobile),
                    const SizedBox(height: 24),
                    const Text(
                      'Riwayat Mutasi Saldo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isMobile) _buildMobileList() else _buildDesktopTable(),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dompet Saya',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.grey900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Kelola saldo, topup, dan tarik dana Anda di sini.',
          style: TextStyle(fontSize: 13, color: AppColors.grey500),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            title: 'Saldo Tersedia',
            value: _formatRupiah(_balance),
            icon: Icons.account_balance_wallet_outlined,
            color: _accent,
            actionWidget: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final res = await showDialog(
                        context: context,
                        builder: (_) => TopupDialog(role: widget.role),
                      );
                      if (res == true) _loadWallet();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _accent,
                      side: BorderSide(color: _accent.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'Topup',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final res = await showDialog(
                        context: context,
                        builder: (_) => WithdrawDialog(
                          role: widget.role,
                          maxAmount: _balance,
                        ),
                      );
                      if (res == true) _loadWallet();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Tarik',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _summaryCard(
            title: 'Saldo Ditahan (Escrow)',
            value: _formatRupiah(_heldBalance),
            icon: Icons.lock_outline,
            color: const Color(0xFFF59E0B),
            actionWidget: const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Widget actionWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkTeal.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.grey500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 12),
          actionWidget,
        ],
      ),
    );
  }

  Widget _buildProofImage(String? proofUrl, String type) {
    // 1. Jika ada gambar, langsung tampilkan
    if (proofUrl != null && proofUrl.isNotEmpty && proofUrl != 'null') {
      // Ambil base URL tanpa '/api' (misal: http://127.0.0.1:8000)
      final String origin = ApiService.baseUrl.replaceAll(RegExp(r'/api$'), '');

      // Gabungkan origin dengan proofUrl
      final fullUrl = proofUrl.startsWith('http')
          ? proofUrl
          : '$origin$proofUrl';

      return GestureDetector(
        onTap: () => _showImageDialog(fullUrl),
        child: Container(
          width: 60,
          height: 60,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _tableBorder),
            image: DecorationImage(
              image: NetworkImage(fullUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    // 2. Jika tidak ada gambar, cek tipenya
    final isPending = (type == 'WITHDRAW' || type == 'TOPUP');

    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isPending
            ? Colors.orange.withValues(alpha: 0.1)
            : AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isPending ? Colors.orange : _tableBorder),
      ),
      child: Center(
        child: isPending
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty, color: Colors.orange, size: 16),
                  Text(
                    'Pending',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : const Icon(
                Icons.receipt_long,
                color: AppColors.grey400,
                size: 20,
              ),
      ),
    );
  }

  // ============================================================
  // DESKTOP TABLE (DENGAN FOOTER PAGINATION)
  // ============================================================
  Widget _buildDesktopTable() {
    if (_transactions.isEmpty) return _buildEmptyState();
    final rows = _pagedTransactions;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _tableBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Tabel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Expanded(flex: 3, child: _headerCell('Tanggal')),
                Expanded(flex: 2, child: _headerCell('Bukti')),
                Expanded(flex: 4, child: _headerCell('Keterangan')),
                Expanded(flex: 2, child: _headerCell('Tipe')),
                Expanded(flex: 2, child: _headerCell('Nominal')),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _tableDivider),

          // Data Tabel
          for (int i = 0; i < rows.length; i++) ...[
            _buildTableDataRow(rows[i]),
            if (i != rows.length - 1)
              const Divider(height: 1, thickness: 1, color: _tableDivider),
          ],

          // Footer Pagination
          const Divider(height: 1, thickness: 1, color: _tableDivider),
          _buildTableFooter(),
        ],
      ),
    );
  }

  Widget _buildTableFooter() {
    final total = _transactions.length;
    final start = total == 0 ? 0 : ((_currentPage - 1) * _rowsPerPage) + 1;
    final end = (_currentPage * _rowsPerPage).clamp(0, total);
    final canPrev = _currentPage > 1;
    final canNext = _currentPage < _totalPages;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text(
            'Menampilkan $start–$end dari $total mutasi',
            style: const TextStyle(color: _headerText, fontSize: 12),
          ),
          const Spacer(),
          Row(
            children: [
              _buildRowsPerPageDropdown(),
              const SizedBox(width: 12),
              _navButton(
                icon: Icons.chevron_left,
                enabled: canPrev,
                onTap: () => _goToPage(_currentPage - 1),
              ),
              const SizedBox(width: 8),
              _pageIndicator(),
              const SizedBox(width: 8),
              _navButton(
                icon: Icons.chevron_right,
                enabled: canNext,
                onTap: () => _goToPage(_currentPage + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRowsPerPageDropdown() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _tableBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _rowsPerPage,
          isDense: true,
          icon: const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppColors.grey500,
            ),
          ),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.grey900,
            fontSize: 12,
          ),
          items: _rowsPerPageOptions
              .map(
                (value) => DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value / hal'),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) _changeRowsPerPage(value);
          },
        ),
      ),
    );
  }

  Widget _navButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled ? AppColors.grey300 : AppColors.grey200,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.grey700 : AppColors.grey300,
          ),
        ),
      ),
    );
  }

  Widget _pageIndicator() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Hal $_currentPage / $_totalPages',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.primaryTeal,
          fontSize: 12,
        ),
      ),
    );
  }

  // ============================================================
  // BARIS DATA TABEL
  // ============================================================
  Widget _headerCell(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w500,
        color: _headerText,
        fontSize: 13,
      ),
    );
  }

  Widget _buildTableDataRow(dynamic tx) {
    final amount = double.tryParse(tx['amount'].toString()) ?? 0;
    final isCredit = amount > 0;
    final type = tx['type']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              _formatDate(tx['created_at'].toString()),
              style: const TextStyle(fontSize: 13, color: _cellText),
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildProofImage(
              tx['proof_url']?.toString(),
              tx['type']?.toString() ?? '',
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              tx['description'] ?? '-',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _cellText,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              type.toUpperCase(),
              style: const TextStyle(fontSize: 12, color: AppColors.grey600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${isCredit ? '+' : ''} ${_formatRupiah(amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isCredit ? const Color(0xFF16A34A) : AppColors.grey900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE LIST
  // ============================================================
  Widget _buildMobileList() {
    if (_transactions.isEmpty) return _buildEmptyState();

    return Column(
      children: _transactions.map((tx) {
        final amount = double.tryParse(tx['amount'].toString()) ?? 0;
        final isCredit = amount > 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primaryTeal.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            children: [
              _buildProofImage(
                tx['proof_url']?.toString(),
                tx['type']?.toString() ?? '',
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx['description'] ?? tx['type'] ?? 'Mutasi Saldo',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: _cellText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(tx['created_at'].toString()),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isCredit ? '+' : ''} ${_formatRupiah(amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: isCredit ? const Color(0xFF16A34A) : AppColors.grey900,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // EMPTY & ERROR
  // ============================================================
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 34,
              color: _accent.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum ada riwayat transaksi.',
            style: TextStyle(color: AppColors.grey600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 48),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadWallet,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
