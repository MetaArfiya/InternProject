import 'package:flutter/material.dart';

class PaymentScreen extends StatelessWidget {
  final String role;

  const PaymentScreen({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMitra = role.toLowerCase() == 'mitra';

    final List<Map<String, dynamic>> payments = isMitra
        ? [
            {
              'title': 'Service AC Bocor',
              'customer': 'Budi Santoso',
              'date': '10 September 2026',
              'amount': 145000.0,
              'status': 'Dibayarkan',
            },
            {
              'title': 'Perbaikan Kunci Rumah',
              'customer': 'Siti Aminah',
              'date': '8 September 2026',
              'amount': 200000.0,
              'status': 'Dibayarkan',
            },
            {
              'title': 'Pasang Lampu Teras',
              'customer': 'Andi Pratama',
              'date': '5 September 2026',
              'amount': 125000.0,
              'status': 'Menunggu',
            },
          ]
        : [
            {
              'title': 'Service AC Bocor',
              'customer': 'Andi Teknik AC',
              'date': '10 September 2026',
              'amount': 145000.0,
              'status': 'Berhasil',
            },
            {
              'title': 'Perbaikan Kunci Rumah',
              'customer': 'Budi Teknik',
              'date': '8 September 2026',
              'amount': 200000.0,
              'status': 'Berhasil',
            },
          ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isMobile = constraints.maxWidth < 700;

            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, isMitra),
                  const SizedBox(height: 24),

                  _buildSummary(
                    context,
                    payments,
                    isMitra,
                    isMobile,
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'Riwayat Pembayaran',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 16),

                  ...payments.map(
                    (payment) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _buildPaymentCard(
                        context,
                        payment,
                        isMitra,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMitra) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pembayaran',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          isMitra
              ? 'Lihat riwayat pembayaran dan pendapatan dari pekerjaan.'
              : 'Lihat riwayat transaksi dan pembayaran pekerjaan.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }

  Widget _buildSummary(
    BuildContext context,
    List<Map<String, dynamic>> payments,
    bool isMitra,
    bool isMobile,
  ) {
    double total = 0;

    for (final payment in payments) {
      total += payment['amount'] as double;
    }

    final double commission = total * 0.15;
    final double partnerIncome = total * 0.85;

    if (isMobile) {
      return Column(
        children: [
          _summaryCard(
            context,
            title: isMitra ? 'Total Pendapatan' : 'Total Pembayaran',
            value: isMitra ? partnerIncome : total,
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 12),
          _summaryCard(
            context,
            title: 'Transaksi',
            valueText: '${payments.length} transaksi',
            icon: Icons.receipt_long_outlined,
          ),
          if (!isMitra) ...[
            const SizedBox(height: 12),
            _summaryCard(
              context,
              title: 'Komisi Aplikasi',
              value: commission,
              icon: Icons.percent,
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            context,
            title: isMitra ? 'Total Pendapatan' : 'Total Pembayaran',
            value: isMitra ? partnerIncome : total,
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _summaryCard(
            context,
            title: 'Transaksi',
            valueText: '${payments.length} transaksi',
            icon: Icons.receipt_long_outlined,
          ),
        ),
        if (!isMitra) ...[
          const SizedBox(width: 16),
          Expanded(
            child: _summaryCard(
              context,
              title: 'Komisi Aplikasi',
              value: commission,
              icon: Icons.percent,
            ),
          ),
        ],
      ],
    );
  }

  Widget _summaryCard(
    BuildContext context, {
    required String title,
    double? value,
    String? valueText,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.orange,
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
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  valueText ?? _formatRupiah(value ?? 0),
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
    );
  }

  Widget _buildPaymentCard(
    BuildContext context,
    Map<String, dynamic> payment,
    bool isMitra,
  ) {
    final double amount = payment['amount'] as double;
    final double commission = amount * 0.15;
    final double partnerIncome = amount * 0.85;

    final bool isSuccess = payment['status'] == 'Berhasil' ||
        payment['status'] == 'Dibayarkan';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isMitra
                          ? 'Pelanggan: ${payment['customer']}'
                          : 'Mitra: ${payment['customer']}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      payment['date'],
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(
                context,
                payment['status'],
                isSuccess,
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 12),

          _detailRow(
            'Nilai pekerjaan',
            _formatRupiah(amount),
          ),

          const SizedBox(height: 8),

          if (isMitra) ...[
            _detailRow(
              'Komisi aplikasi (15%)',
              '- ${_formatRupiah(commission)}',
            ),
            const SizedBox(height: 8),
            _detailRow(
              'Pendapatan Mitra (85%)',
              _formatRupiah(partnerIncome),
              isBold: true,
            ),
          ] else ...[
            _detailRow(
              'Komisi aplikasi',
              _formatRupiah(commission),
            ),
            const SizedBox(height: 8),
            _detailRow(
              'Total pembayaran',
              _formatRupiah(amount),
              isBold: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(
    BuildContext context,
    String status,
    bool success,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: success
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: success ? Colors.green : Colors.orange,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _detailRow(
    String title,
    String value, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight:
                  isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  String _formatRupiah(double value) {
    final String number = value
        .round()
        .toString()
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );

    return 'Rp$number';
  }
}