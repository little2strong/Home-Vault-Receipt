import 'dates.dart';
import 'formatters.dart';

enum DateOrder {
  dayFirst('UK format: day / month / year'),
  monthFirst('US format: month / day / year');

  const DateOrder(this.label);

  final String label;
}

class ParsedReceiptDate {
  const ParsedReceiptDate({this.date, this.ambiguous = false});

  /// Null when the text is not a valid calendar date.
  final DateTime? date;

  /// True when both day-first and month-first readings are valid and differ,
  /// e.g. `02/10/26`. The user must confirm which one the receipt means.
  final bool ambiguous;
}

/// Reads the dates printed on receipts: numeric (`02/10/26`, `2-10-2026`)
/// or written (`02 OCTOBER 2026`, `2 Oct 2026`).
abstract final class ReceiptDateParser {
  static final _numeric = RegExp(
    r'^(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2}|\d{4})$',
  );
  static final _written = RegExp(r'^(\d{1,2})\s+([A-Za-z]+)\.?\s+(\d{4})$');
  static final _yearFirst = RegExp(r'^(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})$');

  static ParsedReceiptDate parse(
    String raw, {
    DateOrder order = DateOrder.dayFirst,
  }) {
    final text = raw.trim();

    // `2026-09-12` and `2026/09/12` are never ambiguous.
    final yearFirst = _yearFirst.firstMatch(text);
    if (yearFirst != null) {
      return ParsedReceiptDate(
        date: _valid(
          int.parse(yearFirst.group(1)!),
          int.parse(yearFirst.group(2)!),
          int.parse(yearFirst.group(3)!),
        ),
      );
    }

    final written = _written.firstMatch(text);
    if (written != null) {
      final month = _monthFromName(written.group(2)!);
      if (month == null) return const ParsedReceiptDate();
      return ParsedReceiptDate(
        date: _valid(
          int.parse(written.group(3)!),
          month,
          int.parse(written.group(1)!),
        ),
      );
    }

    final numeric = _numeric.firstMatch(text);
    if (numeric == null) return const ParsedReceiptDate();

    final a = int.parse(numeric.group(1)!);
    final b = int.parse(numeric.group(2)!);
    var year = int.parse(numeric.group(3)!);
    // 00–69 stay in this century; 70–99 are 1970–1999. A receipt printed
    // `15/03/99` is a 1999 purchase, not 2099.
    if (year < 100) year += year >= 70 ? 1900 : 2000;

    final dayFirst = _valid(year, b, a);
    final monthFirst = _valid(year, a, b);
    final preferred = order == DateOrder.dayFirst ? dayFirst : monthFirst;
    final alternate = order == DateOrder.dayFirst ? monthFirst : dayFirst;

    if (preferred != null &&
        alternate != null &&
        !Dates.isSameDay(preferred, alternate)) {
      return ParsedReceiptDate(date: preferred, ambiguous: true);
    }
    // One component above 12 leaves only one possible calendar date, whichever
    // reading order the user has selected.
    return ParsedReceiptDate(date: preferred ?? alternate);
  }

  static DateTime? _valid(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1) return null;
    final date = DateTime(year, month, day);
    return date.month == month && date.day == day ? date : null;
  }

  static int? _monthFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.length < 3) return null;
    for (var i = 0; i < Formatters.months.length; i++) {
      final month = Formatters.months[i].toLowerCase();
      if (month.startsWith(lower) || lower.startsWith(month)) return i + 1;
    }
    return null;
  }
}
