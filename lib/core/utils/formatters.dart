import 'dates.dart';
import 'money.dart';

abstract final class Formatters {
  static const months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July', //
    'August', 'September', 'October', 'November', 'December',
  ];

  static String _short(int month) => months[month - 1].substring(0, 3);

  static String currency(int minor, [String currency = 'GBP']) =>
      Money.format(minor, currency: currency);

  /// `2 October 2026`
  static String date(DateTime d) => '${d.day} ${months[d.month - 1]} ${d.year}';

  /// `2 Oct`
  static String shortDate(DateTime d) => '${d.day} ${_short(d.month)}';

  /// `24 September`
  static String dayMonth(DateTime d) => '${d.day} ${months[d.month - 1]}';

  /// `1 Sep – 4 Oct 2026`
  static String dateRange(DateTime from, DateTime to) =>
      '${shortDate(from)} – ${shortDate(to)} ${to.year}';

  /// `OCTOBER 2026`, used as a list section label.
  static String monthHeader(DateTime d) =>
      '${months[d.month - 1].toUpperCase()} ${d.year}';

  static String time(int minutesOfDay) {
    final h = (minutesOfDay ~/ 60).toString().padLeft(2, '0');
    final m = (minutesOfDay % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String daysRemaining(int days) => switch (days) {
    < 0 => 'Closed',
    0 => 'Today',
    1 => '1 day',
    _ => '$days days',
  };

  static String relativeDay(DateTime d, DateTime today) =>
      switch (Dates.daysBetween(d, today)) {
        0 => 'Today',
        1 => 'Yesterday',
        _ => shortDate(d),
      };

  /// `Tomorrow at 14:00`
  static String expiry(DateTime at, DateTime now) {
    final clock = time(at.hour * 60 + at.minute);
    final day = switch (Dates.daysBetween(now, at)) {
      0 => 'Today',
      1 => 'Tomorrow',
      _ => shortDate(at),
    };
    return '$day at $clock';
  }

  static String fileSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(bytes >= 10 * 1024 * 1024 ? 0 : 1)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).round()} KB';
    return '$bytes B';
  }

  static String count(int n, String singular, [String? plural]) =>
      '$n ${n == 1 ? singular : (plural ?? '${singular}s')}';
}
