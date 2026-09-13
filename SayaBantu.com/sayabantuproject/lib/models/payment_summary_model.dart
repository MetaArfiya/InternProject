class PaymentSummary {
  final double totalPembayaran;
  final double totalKomisi;
  final double totalMitraEarning;
  final double totalPending;
  final int totalTransaksi;

  PaymentSummary({
    required this.totalPembayaran,
    required this.totalKomisi,
    required this.totalMitraEarning,
    required this.totalPending,
    required this.totalTransaksi,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    return PaymentSummary(
      totalPembayaran: double.tryParse(
            json['total_pembayaran']?.toString() ?? '0',
          ) ??
          0,
      totalKomisi: double.tryParse(
            json['total_komisi']?.toString() ?? '0',
          ) ??
          0,
      totalMitraEarning: double.tryParse(
            json['total_mitra_earn']?.toString() ??
                json['total_pendapatan']?.toString() ??
                '0',
          ) ??
          0,
      totalPending: double.tryParse(
            json['total_pending']?.toString() ?? '0',
          ) ??
          0,
      totalTransaksi: int.tryParse(
            json['total_transaksi']?.toString() ?? '0',
          ) ??
          0,
    );
  }

  PaymentSummary copyWith({
    double? totalPembayaran,
    double? totalKomisi,
    double? totalMitraEarning,
    double? totalPending,
    int? totalTransaksi,
  }) {
    return PaymentSummary(
      totalPembayaran: totalPembayaran ?? this.totalPembayaran,
      totalKomisi: totalKomisi ?? this.totalKomisi,
      totalMitraEarning: totalMitraEarning ?? this.totalMitraEarning,
      totalPending: totalPending ?? this.totalPending,
      totalTransaksi: totalTransaksi ?? this.totalTransaksi,
    );
  }

  static PaymentSummary empty() {
    return PaymentSummary(
      totalPembayaran: 0,
      totalKomisi: 0,
      totalMitraEarning: 0,
      totalPending: 0,
      totalTransaksi: 0,
    );
  }
}