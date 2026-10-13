import 'package:flutter_test/flutter_test.dart';
import 'package:home_vault_receipt/core/utils/dates.dart';
import 'package:home_vault_receipt/core/utils/formatters.dart';
import 'package:home_vault_receipt/core/utils/money.dart';
import 'package:home_vault_receipt/core/utils/receipt_date_parser.dart';
import 'package:home_vault_receipt/core/utils/validators.dart';

void main() {
  group('Money', () {
    test('parses receipt and user formats into pence', () {
      expect(Money.parse('179.00'), 17900);
      expect(Money.parse('£1,099.00'), 109900);
      expect(Money.parse('GBP 12.5'), 1250);
      expect(Money.parse(' 42 '), 4200);
    });

    test('rejects anything that is not a plain amount', () {
      expect(Money.parse(''), isNull);
      expect(Money.parse('12.345'), isNull);
      expect(Money.parse('abc'), isNull);
      expect(Money.parse('-5'), isNull);
    });

    test('formats with symbol and thousands separators', () {
      expect(Money.format(109900), '£1,099.00');
      expect(Money.format(6482), '£64.82');
      expect(Money.format(5, currency: 'EUR'), '€0.05');
      expect(Money.formatWhole(342800), '£3,428');
    });

    test('round-trips a negative amount through the form field', () {
      expect(Money.toInput(-150), '-1.50');
      expect(Money.parse(Money.toInput(17900)), 17900);
    });

    test('splits UK VAT-inclusive totals like the printed receipt', () {
      final split = Money.splitVat(17900);
      expect(split.subtotal, 14917);
      expect(split.vat, 2983);
    });
  });

  group('Dates', () {
    test('counts calendar days independent of time and DST', () {
      // UK clocks go back on 25 Oct 2026; local midnights are 25h apart.
      expect(
        Dates.daysBetween(
          DateTime(2026, 10, 24, 23),
          DateTime(2026, 10, 26, 1),
        ),
        2,
      );
      expect(
        Dates.daysBetween(DateTime(2026, 10, 15), DateTime(2026, 10, 4)),
        -11,
      );
    });

    test('adds months without overflowing short months', () {
      expect(Dates.addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
      expect(Dates.addMonths(DateTime(2026, 9, 12), 12), DateTime(2027, 9, 12));
    });

    test('adds calendar days across the daylight-saving change', () {
      // Clocks go back on 25 Oct 2026. A 24-hour duration stays on the 25th.
      expect(Dates.addDays(DateTime(2026, 10, 25), 1), DateTime(2026, 10, 26));
      expect(Dates.addDays(DateTime(2026, 10, 12), 13), DateTime(2026, 10, 25));
    });
  });

  group('ReceiptDateParser', () {
    test('reads UK numeric dates and flags ambiguity', () {
      final parsed = ReceiptDateParser.parse('02/10/26');
      expect(parsed.date, DateTime(2026, 10, 2));
      expect(parsed.ambiguous, isTrue);
    });

    test('switches reading order when asked', () {
      final parsed = ReceiptDateParser.parse(
        '02/10/26',
        order: DateOrder.monthFirst,
      );
      expect(parsed.date, DateTime(2026, 2, 10));
    });

    test('is unambiguous when one part exceeds 12', () {
      final parsed = ReceiptDateParser.parse('24/09/2026');
      expect(parsed.date, DateTime(2026, 9, 24));
      expect(parsed.ambiguous, isFalse);
      // Month-first cannot mean month 24, so the only valid reading is kept.
      final switched = ReceiptDateParser.parse(
        '24/09/2026',
        order: DateOrder.monthFirst,
      );
      expect(switched.date, DateTime(2026, 9, 24));
      expect(switched.ambiguous, isFalse);
    });

    test('reads a 1970–1999 purchase from a two-digit year', () {
      expect(ReceiptDateParser.parse('15/03/99').date, DateTime(1999, 3, 15));
    });

    test('does not treat an arbitrary word as a month', () {
      expect(ReceiptDateParser.parse('02 MARBLE 2026').date, isNull);
    });

    test('reads written month names', () {
      expect(
        ReceiptDateParser.parse('02 OCTOBER 2026').date,
        DateTime(2026, 10, 2),
      );
      expect(ReceiptDateParser.parse('2 Oct 2026').date, DateTime(2026, 10, 2));
    });

    test('rejects impossible dates', () {
      expect(ReceiptDateParser.parse('31/02/26').date, isNull);
      expect(ReceiptDateParser.parse('13/13/26').date, isNull);
      expect(ReceiptDateParser.parse('soon').date, isNull);
    });
  });

  group('Formatters', () {
    test('match the design copy', () {
      expect(Formatters.date(DateTime(2026, 10, 2)), '2 October 2026');
      expect(Formatters.shortDate(DateTime(2026, 10, 2)), '2 Oct');
      expect(Formatters.daysRemaining(11), '11 days');
      expect(Formatters.daysRemaining(1), '1 day');
      expect(Formatters.count(1, 'receipt'), '1 receipt');
      expect(Formatters.count(3, 'box', 'boxes'), '3 boxes');
      expect(Formatters.fileSize(820 * 1024), '820 KB');
    });

    test('describes expiry relative to now', () {
      final now = DateTime(2026, 10, 12, 14);
      expect(
        Formatters.expiry(DateTime(2026, 10, 13, 14), now),
        'Tomorrow at 14:00',
      );
    });
  });

  group('Validators', () {
    test('password needs length, a letter and a number', () {
      expect(Validators.password('short1'), isNotNull);
      expect(Validators.password('longenough'), isNotNull);
      expect(Validators.password('longenough1'), isNull);
    });

    test('amount must be positive', () {
      expect(Validators.amount('0'), isNotNull);
      expect(Validators.amount('179.00'), isNull);
      expect(Validators.optionalAmount(''), isNull);
    });
  });
}
