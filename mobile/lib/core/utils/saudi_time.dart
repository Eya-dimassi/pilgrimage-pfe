class SaudiTime {
  static const Duration _astOffset = Duration(hours: 3);

  /// Current device time.
  /// Keep absolute current time for real-time comparisons.
  static DateTime now() {
    return DateTime.now();
  }

  /// Convert an instant to AST display/calendar time.
  static DateTime inSaudi(DateTime value) {
    return value.toUtc().add(_astOffset);
  }

  /// Returns the AST calendar day.
  static DateTime dayOf(DateTime value) {
    final astValue = inSaudi(value);
    return DateTime(
      astValue.year,
      astValue.month,
      astValue.day,
    );
  }

  /// Compare two calendar days.
  static bool isSameDay(DateTime a, DateTime b) {
    final first = dayOf(a);
    final second = dayOf(b);

    return first.isAtSameMomentAs(second);
  }

  /// Format HH:mm
  static String formatHour(DateTime? value) {
    if (value == null) return '--:--';

    final astValue = inSaudi(value);
    final hour = astValue.hour.toString().padLeft(2, '0');
    final minute = astValue.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  /// Format dd/MM/yyyy
  static String formatDate(DateTime? value) {
    if (value == null) return '--/--/----';

    final astValue = inSaudi(value);
    final day = astValue.day.toString().padLeft(2, '0');
    final month = astValue.month.toString().padLeft(2, '0');

    return '$day/$month/${astValue.year}';
  }

  /// Format dd/MM
  static String formatShortDate(DateTime? value) {
    if (value == null) return '--/--';

    final astValue = inSaudi(value);
    final day = astValue.day.toString().padLeft(2, '0');
    final month = astValue.month.toString().padLeft(2, '0');

    return '$day/$month';
  }
}
