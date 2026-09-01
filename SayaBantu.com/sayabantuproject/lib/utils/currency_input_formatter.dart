import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: 'Rp',
        selection: TextSelection.collapsed(offset: 2),
      );
    }

    final number = int.parse(digits);
    final newText = formatter.format(number);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newText.length,
      ),
    );
  }
}