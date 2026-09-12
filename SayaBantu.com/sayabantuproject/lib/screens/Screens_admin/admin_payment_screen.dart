import 'package:flutter/material.dart';

class AdminPaymentScreen extends StatefulWidget {
  const AdminPaymentScreen({super.key});

  @override
  State<AdminPaymentScreen> createState() => _AdminPaymentScreenState();
}

class _AdminPaymentScreenState extends State<AdminPaymentScreen> {
  final List<Map<String, dynamic>> _payments = [
    {
      'id': 'PAY-001',
      'customer': 'Budi Santoso',
      'partner': 'Andi Teknik AC',
      'service': 'Service AC Bocor',
      'amount': 145000.0,
      'commission': 21750.0,
      'partnerIncome': 123250.0,
      'date': '12 September 2026',
      'status': 'Berhasil',
      'method': 'Transfer Bank',
      'account': 'BCA **** 1234',
    },
    {
      'id': 'PAY-002',
      'customer': 'Siti Aminah',
      'partner': 'Joko Plumbing',
      'service': 'Perbaikan Pipa Air',
      'amount': 200000.0,
      'commission': 30000.0,
      'partnerIncome': 170000.0,
      'date': '12 September 2026',
      'status': 'Menunggu',
      'method': 'Transfer Bank',
      'account': 'BRI **** 5678',
    },
    {
      'id': 'PAY-003',
      'customer': 'Rina Wulandari',
      'partner': 'Dimas Elektrik',
      'service': 'Perbaikan Instalasi Listrik',
      'amount': 175000.0,
      'commission': 26250.0,
      'partnerIncome': 148750.0,
      'date': '11 September 2026',
      'status': 'Diproses',
      'method': 'E-Wallet',
      'account': 'DANA **** 8899',
    },
    {
      'id': 'PAY-004',
      'customer': 'Agus Pratama',
      'partner': 'Budi Cat Rumah',
      'service': 'Pengecatan Ruang Tamu',
      'amount': 350000.0,
      'commission': 52500.0,
      'partnerIncome': 297500.0,
      'date': '10 September 2026',
      'status': 'Berhasil',
      'method': 'Transfer Bank',
      'account': 'Mandiri **** 1122',
    },
    {
      'id': 'PAY-005',
      'customer': 'Dewi Lestari',
      'partner': 'Clean Home',
      'service': 'Jasa Kebersihan Rumah',
      'amount': 125000.0,
      'commission': 18750.0,
      'partnerIncome': 106250.0,
      'date': '09 September 2026',
      'status': 'Gagal',
      'method': 'E-Wallet',
      'account': 'OVO **** 7788',
    },
    {
      'id': 'PAY-006',
      'customer': 'Fajar Hidayat',
      'partner': 'Andi Teknik AC',
      'service': 'Cuci AC Rumah',
      'amount': 100000.0,
      'commission': 15000.0,
      'partnerIncome': 85000.0,
      'date': '08 September 2026',
      'status': 'Menunggu',
      'method': 'Transfer Bank',
      'account': 'BCA **** 1234',
    },
  ];

  String _selectedStatus = 'Semua';

  final List<String> _statusOptions = [
    'Semua',
    'Menunggu',
    'Diproses',
    'Berhasil',
    'Gagal',
  ];

  List<Map<String, dynamic>> get _filteredPayments {
    if (_selectedStatus == 'Semua') {
      return _payments;
    }

    return _payments
        .where((payment) => payment['status'] == _selectedStatus)
        .toList();
  }

  double _getTotalAmount() {
    return _payments.fold(
      0,
      (total, payment) => total + (payment['amount'] as double),
    );
  }

  double _getTotalCommission() {
    return _payments.fold(
      0,
      (total, payment) => total + (payment['commission'] as double),
    );
  }

  double _getTotalPartnerIncome() {
    return _payments.fold(
      0,
      (total, payment) => total + (payment['partnerIncome'] as double),
    );
  }

  double _getTotalByStatus(String status) {
    return _payments
        .where((payment) => payment['status'] == status)
        .fold(
          0,
          (total, payment) => total + (payment['amount'] as double),
        );
  }

  String _formatRupiah(double amount) {
    final value = amount.toInt().toString();
    final reversed = value.split('').reversed.toList();

    final chunks = <String>[];

    for (int i = 0; i < reversed.length; i += 3) {
      final chunk = reversed.skip(i).take(3).toList().reversed.join();
      chunks.add(chunk);
    }

    return 'Rp${chunks.reversed.join('.')}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Berhasil':
        return Colors.green;
      case 'Diproses':
        return Colors.blue;
      case 'Menunggu':
        return Colors.orange;
      case 'Gagal':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Berhasil':
        return Icons.check_circle_outline;
      case 'Diproses':
        return Icons.sync;
      case 'Menunggu':
        return Icons.access_time;
      case 'Gagal':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  void _showPaymentDetail(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.receipt_long),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Detail Pembayaran',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('ID Pembayaran', payment['id']),
                  _detailRow('Pelanggan', payment['customer']),
                  _detailRow('Mitra', payment['partner']),
                  _detailRow('Layanan', payment['service']),
                  _detailRow('Tanggal', payment['date']),
                  _detailRow('Metode Pembayaran', payment['method']),
                  _detailRow('Rekening/E-Wallet', payment['account']),
                  const Divider(height: 25),
                  _detailRow(
                    'Total Pembayaran',
                    _formatRupiah(payment['amount']),
                    isBold: true,
                  ),
                  _detailRow(
                    'Komisi Admin 15%',
                    _formatRupiah(payment['commission']),
                  ),
                  _detailRow(
                    'Pendapatan Mitra 85%',
                    _formatRupiah(payment['partnerIncome']),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const Text(
                        'Status: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      _statusBadge(payment['status']),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (payment['status'] == 'Menunggu' ||
                payment['status'] == 'Diproses')
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showProcessConfirmation(payment);
                },
                child: const Text('Proses Pembayaran'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 155,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status),
            size: 15,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showProcessConfirmation(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Proses Pembayaran'),
          content: Text(
            'Apakah pembayaran ${payment['id']} ingin ditandai sebagai berhasil?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  payment['status'] = 'Berhasil';
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Pembayaran berhasil diperbarui.'),
                  ),
                );
              },
              child: const Text('Ya, Proses'),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 27,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;

        final cards = [
          _summaryCard(
            title: 'Total Transaksi',
            value: _formatRupiah(_getTotalAmount()),
            icon: Icons.account_balance_wallet_outlined,
            color: Colors.blue,
          ),
          _summaryCard(
            title: 'Komisi Admin 15%',
            value: _formatRupiah(_getTotalCommission()),
            icon: Icons.account_balance,
            color: Colors.green,
          ),
          _summaryCard(
            title: 'Pendapatan Mitra 85%',
            value: _formatRupiah(_getTotalPartnerIncome()),
            icon: Icons.handshake_outlined,
            color: Colors.orange,
          ),
        ];

        if (isMobile) {
          return Column(
            children: [
              for (final card in cards) ...[
                card is Expanded
                    ? SizedBox(
                        width: double.infinity,
                        child: card,
                      )
                    : card,
                const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 14),
            Expanded(child: cards[1]),
            const SizedBox(width: 14),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list),
          const SizedBox(width: 10),
          const Text(
            'Filter Status:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 15),
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: _statusOptions.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
          ),
          const Spacer(),
          Text(
            '${_filteredPayments.length} transaksi',
            style: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.4),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          headingRowColor: MaterialStateProperty.all(
            Theme.of(context).colorScheme.surface,
          ),
          columns: const [
            DataColumn(label: Text('ID Pembayaran')),
            DataColumn(label: Text('Pelanggan')),
            DataColumn(label: Text('Mitra')),
            DataColumn(label: Text('Total')),
            DataColumn(label: Text('Komisi 15%')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Aksi')),
          ],
          rows: _filteredPayments.map((payment) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    payment['id'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataCell(Text(payment['customer'])),
                DataCell(Text(payment['partner'])),
                DataCell(Text(_formatRupiah(payment['amount']))),
                DataCell(Text(_formatRupiah(payment['commission']))),
                DataCell(_statusBadge(payment['status'])),
                DataCell(
                  IconButton(
                    tooltip: 'Lihat Detail',
                    icon: const Icon(Icons.visibility_outlined),
                    onPressed: () => _showPaymentDetail(payment),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return Column(
      children: _filteredPayments.map((payment) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      payment['id'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _statusBadge(payment['status']),
                ],
              ),
              const SizedBox(height: 12),
              _mobileInfoRow(
                Icons.person_outline,
                'Pelanggan',
                payment['customer'],
              ),
              _mobileInfoRow(
                Icons.handshake_outlined,
                'Mitra',
                payment['partner'],
              ),
              _mobileInfoRow(
                Icons.work_outline,
                'Layanan',
                payment['service'],
              ),
              _mobileInfoRow(
                Icons.calendar_today_outlined,
                'Tanggal',
                payment['date'],
              ),
              const Divider(height: 22),
              _mobileInfoRow(
                Icons.payments_outlined,
                'Total Pembayaran',
                _formatRupiah(payment['amount']),
                isBold: true,
              ),
              _mobileInfoRow(
                Icons.account_balance_outlined,
                'Komisi Admin',
                _formatRupiah(payment['commission']),
              ),
              _mobileInfoRow(
                Icons.wallet_outlined,
                'Pendapatan Mitra',
                _formatRupiah(payment['partnerIncome']),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showPaymentDetail(payment),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Lihat Detail Pembayaran'),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _mobileInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.color
                ?.withOpacity(0.6),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pembayaran',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kelola dan pantau seluruh transaksi pembayaran pelanggan dan mitra.',
                style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              _buildSummarySection(),
              const SizedBox(height: 24),
              _buildFilterSection(),
              const SizedBox(height: 18),
              if (_filteredPayments.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(35),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 55,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Tidak ada data pembayaran.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else if (isMobile)
                _buildMobileList()
              else
                _buildDesktopTable(),
            ],
          ),
        );
      },
    );
  }
}