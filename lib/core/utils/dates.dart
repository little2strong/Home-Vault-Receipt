/// Injected wherever "now" matters so business rules stay testable.
typedef Clock = DateTime Function();

abstract final class Dates {
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Whole calendar days from [from] to [to]. Computed in UTC so a daylight
  /// saving change (a 23 or 25 hour day) cannot shift the result.
  static int daysBetween(DateTime from, DateTime to) => DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Calendar days, not 24-hour chunks. [DateTime.add] of a [Duration] lands
  /// on the wrong date when the span includes a daylight-saving change.
  static DateTime addDays(DateTime d, int days) {
    final day = dateOnly(d);
    return DateTime(day.year, day.month, day.day + days);
  }

  static DateTime addMonths(DateTime d, int months) {
    final target = DateTime(d.year, d.month + months);
    final lastDay = DateTime(target.year, target.month + 1, 0).day;
    return DateTime(target.year, target.month, d.day.clamp(1, lastDay));
  }
}
