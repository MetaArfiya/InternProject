// lib/models/payment_detail_model.dart

import 'payment_model.dart';
import 'bank_account_model.dart';

class PaymentDetailModel {
  final PaymentModel payment;
  final BankAccountModel transferTo;
  final double? amountToPay;
  final double? amountToTransfer;

  PaymentDetailModel({
    required this.payment,
    required this.transferTo,
    this.amountToPay,
    this.amountToTransfer,
  });

  factory PaymentDetailModel.fromJson(Map<String, dynamic> json) {
    return PaymentDetailModel(
      payment: PaymentModel.fromJson(
        json['payment'] is Map
            ? Map<String, dynamic>.from(json['payment'])
            : {},
      ),
      transferTo: BankAccountModel.fromJson(
        json['transfer_to'] is Map
            ? Map<String, dynamic>.from(json['transfer_to'])
            : null,
      ),
      amountToPay: json['amount_to_pay'] != null
          ? double.tryParse(json['amount_to_pay'].toString())
          : null,
      amountToTransfer: json['amount_to_transfer'] != null
          ? double.tryParse(json['amount_to_transfer'].toString())
          : null,
    );
  }
}