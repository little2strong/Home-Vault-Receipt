/// Money is stored as integer minor units (pence) so totals never drift the
/// way `double` sums do.
abstract final class Money {
  static const currencies = ['GBP', 'EUR', 'USD'];

  static final _codePrefix = RegExp(r'^(GBP|EUR|USD)', caseSensitive: false);
  static final _noise = RegExp(r'[£$€,\s]');
  static final _plain = RegExp(r'^\d+(\.\d{1,2})?$');
  static final _thousands = RegExp(r'\B(?=(\d{3})+(?!\d))');

  /// Parses user or OCR text such as `£1,099.00`, `1099` or `12.5` into
  /// minor units. Returns null for anything that is not a plain amount.
  static int? parse(String? input) {
    if (input == null) return null;
    final cleaned = input
        .trim()
        .replaceFirst(_codePrefix, '')
        .replaceAll(_noise, '');
    if (!_plain.hasMatch(cleaned)) return null;

    final parts = cleaned.split('.');
    final whole = int.parse(parts[0]);
    final fraction = parts.length > 1
        ? int.parse(parts[1].padRight(2, '0'))
        : 0;
    return whole * 100 + fraction;
  }

  static String format(int minor, {String currency = 'GBP'}) {
    final sign = minor < 0 ? '-' : '';
    final abs = minor.abs();
    final whole = (abs ~/ 100).toString().replaceAll(_thousands, ',');
    final fraction = (abs % 100).toString().padLeft(2, '0');
    return '$sign${symbolFor(currency)}$whole.$fraction';
  }

  /// `£1,099` style, for compact secondary lines.
  static String formatWhole(int minor, {String currency = 'GBP'}) {
    final whole = (minor.abs() / 100).round().toString().replaceAll(
      _thousands,
      ',',
    );
    return '${minor < 0 ? '-' : ''}${symbolFor(currency)}$whole';
  }

  /// Plain editable text for a form field, e.g. `179.00`.
  static String toInput(int minor) {
    final sign = minor < 0 ? '-' : '';
    final abs = minor.abs();
    return '$sign${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
  }

  static String symbolFor(String currency) => switch (currency) {
    'GBP' => '£',
    'EUR' => '€',
    'USD' => r'$',
    _ => '$currency ',
  };

  /// UK receipts print VAT-inclusive totals at the standard 20% rate.
  static ({int subtotal, int vat}) splitVat(int total, {int ratePercent = 20}) {
    final subtotal = (total * 100 / (100 + ratePercent)).round();
    return (subtotal: subtotal, vat: total - subtotal);
  }
}
