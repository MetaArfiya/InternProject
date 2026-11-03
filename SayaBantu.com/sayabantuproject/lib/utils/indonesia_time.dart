/// Helpers for Indonesian wall-clock time (WIB, UTC+7).
///
/// API timestamps are stored as UTC. These helpers avoid depending on the
/// browser or device timezone when displaying or submitting job schedules.
class IndonesiaTime {
  static const Duration _wibOffset = Duration(hours: 7);
  static final RegExp _hasZone =
      RegExp(r'(?:Z|[+-]\d{2}:?\d{2})$', caseSensitive: false);

  /// Current WIB date/time represented as UTC fields for stable calendar use.
  static DateTime nowWall() => DateTime.now().toUtc().add(_wibOffset);

  /// Convert an absolute timestamp to WIB fields, independent of device zone.
  static DateTime toWall(DateTime timestamp) =>
      timestamp.toUtc().add(_wibOffset);

  /// Parse an API timestamp consistently. ISO timestamps with a zone are
  /// absolute instants; legacy zone-free API timestamps are treated as WIB.
  static DateTime parseApiTimestamp(String value) {
    final raw = value.trim();
    final parsed = DateTime.parse(raw);
    if (_hasZone.hasMatch(raw)) return parsed.toUtc();

    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour - 7,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    );
  }

  static DateTime? tryParseApiTimestamp(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return null;
    try {
      return parseApiTimestamp(value.toString());
    } catch (_) {
      return null;
    }
  }

  /// Interpret the provided calendar fields as WIB and return its UTC instant.
  static DateTime wallToUtc(DateTime wallTime) => DateTime.utc(
        wallTime.year,
        wallTime.month,
        wallTime.day,
        wallTime.hour,
        wallTime.minute,
        wallTime.second,
        wallTime.millisecond,
        wallTime.microsecond,
      ).subtract(_wibOffset);
}
