class MonthlyEarningModel {
  final String bulan;        // "2026-04"
  final String bulanLabel;   // "Apr"
  final int jumlahPekerjaan;
  final double totalPendapatan;

  MonthlyEarningModel({
    required this.bulan,
    required this.bulanLabel,
    required this.jumlahPekerjaan,
    required this.totalPendapatan,
  });

  factory MonthlyEarningModel.fromJson(Map<String, dynamic> json) {
    return MonthlyEarningModel(
      bulan: json['bulan']?.toString() ?? '',
      bulanLabel: json['bulan_label']?.toString() ?? '',
      jumlahPekerjaan:
          int.tryParse(json['jumlah_pekerjaan']?.toString() ?? '0') ?? 0,
      totalPendapatan:
          double.tryParse(json['total_pendapatan']?.toString() ?? '0') ?? 0,
    );
  }
}

class MonthlyEarningSummary {
  final double totalPendapatan;
  final int totalPekerjaan;
  final double rataRataPerBulan;

  MonthlyEarningSummary({
    required this.totalPendapatan,
    required this.totalPekerjaan,
    required this.rataRataPerBulan,
  });

  factory MonthlyEarningSummary.fromJson(Map<String, dynamic> json) {
    return MonthlyEarningSummary(
      totalPendapatan: double.tryParse(
            json['total_pendapatan']?.toString() ?? '0',
          ) ??
          0,
      totalPekerjaan: int.tryParse(
            json['total_pekerjaan']?.toString() ?? '0',
          ) ??
          0,
      rataRataPerBulan: double.tryParse(
            json['rata_rata_per_bulan']?.toString() ?? '0',
          ) ??
          0,
    );
  }
}