import 'package:intl/intl.dart';

/// Formatting helpers for Ugandan context (UGX, EAT, day-month order).
class Fmt {
  Fmt._();

  static final _ugx = NumberFormat('#,##0', 'en_US');
  static String ugx(int amount, {bool prefix = true}) =>
      '${prefix ? 'UGX ' : ''}${_ugx.format(amount)}';

  static String ugxSigned(int amount) =>
      amount < 0 ? '−${_ugx.format(-amount)}' : _ugx.format(amount);

  static String dayMonth(DateTime d) => DateFormat('dd MMM').format(d);
  static String dayMonthYear(DateTime d) => DateFormat('dd MMM yyyy').format(d);
  static String time(DateTime d) => DateFormat('HH:mm').format(d);
  static String dateTime(DateTime d) =>
      '${dayMonthYear(d)} · ${time(d)}';
  static String weekdayDayMonth(DateTime d) =>
      DateFormat('EEEE · dd MMM').format(d);
  static String monthAbbr(DateTime d) =>
      DateFormat('MMM').format(d).toUpperCase();
  static String day(DateTime d) => DateFormat('dd').format(d);

  static String timeRange(DateTime a, DateTime? b) =>
      b == null ? time(a) : '${time(a)}–${time(b)}';

  static String greeting(DateTime now) {
    final h = now.hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String relativeDue(int? days) {
    if (days == null) return '';
    if (days < 0) return '${-days} days overdue';
    if (days == 0) return 'Due today';
    return '$days days';
  }
}
