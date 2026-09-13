// lib/models/bank_account_model.dart

class BankAccountModel {
  final String bankName;
  final String accountNumber;
  final String accountName;

  BankAccountModel({
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return BankAccountModel(
        bankName: '-',
        accountNumber: '-',
        accountName: '-',
      );
    }

    return BankAccountModel(
      bankName: json['bank_name']?.toString() ??
          json['platform_bank_name']?.toString() ??
          '-',
      accountNumber: json['account_number']?.toString() ??
          json['platform_bank_account_number']?.toString() ??
          '-',
      accountName: json['account_name']?.toString() ??
          json['platform_bank_account_name']?.toString() ??
          '-',
    );
  }

  bool get isValid =>
      bankName != '-' && accountNumber != '-' && accountName != '-';
}