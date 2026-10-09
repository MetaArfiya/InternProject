class Formatters {
  Formatters._();

  /// Format angka: 1500 → "1.5rb+", 2000000 → "2jt+"
  static String compactNumber(String value) {
    final number = int.tryParse(value);
    if (number == null) return value;

    if (number >= 1000000) {
      final result = (number / 1000000).toStringAsFixed(1);
      return '${result.replaceAll('.0', '')}jt+';
    }
    if (number >= 1000) {
      final result = (number / 1000).toStringAsFixed(1);
      return '${result.replaceAll('.0', '')}rb+';
    }
    return number.toString();
  }

  /// Baca string pertama yang tidak kosong dari daftar key
  static String readString(
    Map<String, dynamic> data,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  /// Ekstrak `data` dari response API yang mungkin nested
  static Map<String, dynamic> extractData(Map<String, dynamic>? response) {
    if (response == null) return {};
    final rawData = response['data'];
    if (rawData is Map<String, dynamic>) return rawData;
    if (rawData is Map) return Map<String, dynamic>.from(rawData);
    return response;
  }

  /// True jika string berisi angka > 0
  static bool isPositive(String value) {
    final number = int.tryParse(value) ?? 0;
    return number > 0;
  }
}