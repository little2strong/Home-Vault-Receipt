import 'package:flutter_test/flutter_test.dart';
import 'package:home_vault_receipt/core/models/enums.dart';
import 'package:home_vault_receipt/core/parsing/ocr_document.dart';
import 'package:home_vault_receipt/core/parsing/receipt_parser.dart';

void main() {
  final parser = ReceiptParser(clock: () => DateTime(2026, 10, 6));

  ParsedReceipt parse(String text) =>
      parser.parse(OcrDocument.fromPlainText(text));

  group('Currys receipt from the design', () {
    const currys = '''
CURRYS
Store 0412 · Example Retail Park
VAT No. 000 0000 00
12/09/2026 14:32 Till 03
SAMSUNG 55 QLED TV 499.00
HDMI CABLE 2M 14.99
TV WALL BRACKET 39.99
TOTAL 553.98
VAT @20% 92.33
CARD 553.98
Returns accepted within 30 days
with proof of purchase.
''';

    test('reads shop, date, total and VAT', () {
      final r = parse(currys);
      expect(r.shop, 'Currys');
      expect(r.purchaseDate, DateTime(2026, 9, 12));
      expect(r.totalMinor, 55398);
      expect(r.taxMinor, 9233);
      expect(r.orderNumber, isNull);
    });

    test('splits three items that add up to the total', () {
      final r = parse(currys);
      expect(r.items.map((i) => i.name), [
        'Samsung 55 QLED TV',
        'HDMI Cable 2M',
        'TV Wall Bracket',
      ]);
      expect(r.items.map((i) => i.lineTotalMinor), [49900, 1499, 3999]);
      expect(r.itemsMatchTotal, isTrue);
      expect(r.items.first.category, Category.electronics);
      expect(r.items[1].category, Category.accessories);
    });

    test('keeps return wording but only suggests the deadline', () {
      final r = parse(currys);
      expect(r.returnWording, contains('30 days'));
      expect(r.returnDays, 30);
      expect(r.suggestedReturnDeadline, DateTime(2026, 10, 12));
    });

    test('records where each item sits on the page', () {
      final box = parse(currys).items.first.box!;
      expect(box.page, 0);
      expect(box.y, greaterThan(0));
      expect(box.w, greaterThan(0.5));
    });
  });

  test('joins name and price that OCR returned as separate lines', () {
    final doc = OcrDocument([
      const OcrPage(
        width: 400,
        height: 300,
        lines: [
          OcrLine('ARGOS', 20, 10, 120, 30),
          OcrLine('02/10/2026', 20, 40, 140, 60),
          OcrLine('DYSON V12 VACUUM', 20, 80, 200, 100),
          OcrLine('399.99', 300, 82, 380, 102),
          OcrLine('TOTAL', 20, 120, 100, 140),
          OcrLine('£399.99', 300, 121, 380, 141),
        ],
      ),
    ]);
    final r = parser.parse(doc);
    expect(r.shop, 'Argos');
    expect(r.items.single.name, 'Dyson V12 Vacuum');
    expect(r.items.single.category, Category.appliances);
    expect(r.totalMinor, 39999);
    expect(r.currency, 'GBP');
  });

  test('reads supermarket quantities in both printed styles', () {
    final r = parse('''
TESCO
Superstore
06/10/26
MILK 4 PINTS 1.45
2 x BREAD 2.50
BANANAS
2 @ £0.45 0.90
SUBTOTAL 4.85
TOTAL 4.85
VISA 4.85
''');
    expect(r.shop, 'Tesco');
    expect(r.purchaseDate, DateTime(2026, 10, 6));
    expect(r.items, hasLength(3));
    final bread = r.items[1];
    expect(bread.quantity, 2);
    expect(bread.unitPriceMinor, 125);
    final bananas = r.items[2];
    expect(bananas.name, 'Bananas');
    expect(bananas.quantity, 2);
    expect(bananas.lineTotalMinor, 90);
    expect(r.items.every((i) => i.category == Category.groceries), isTrue);
    expect(r.itemsMatchTotal, isTrue);
  });

  test('leaves unknown values empty rather than guessing', () {
    final r = parse('''
Thank you for shopping
Some line without numbers
''');
    expect(r.totalMinor, isNull);
    expect(r.purchaseDate, isNull);
    expect(r.taxMinor, isNull);
    expect(r.returnWording, isNull);
    expect(r.items, isEmpty);
  });

  test('ignores dates in the future and expiry dates', () {
    final r = parse('''
JOHN LEWIS
Card expiry 12/28
Valid until 01/01/2030
Order date 1 Oct 2026
Order number JL-2026-88317
COFFEE MACHINE 249.00
Order total £249.00
Return within 35 days of delivery.
''');
    expect(r.shop, 'John Lewis');
    expect(r.purchaseDate, DateTime(2026, 10, 1));
    expect(r.orderNumber, 'JL-2026-88317');
    expect(r.totalMinor, 24900);
    expect(r.returnDays, 35);
    expect(r.items.single.name, 'Coffee Machine');
  });

  test('reads euro receipts and negative discount lines', () {
    final r = parse('''
Café Lumière
15.08.2026
Croissant 2.40
Discount -0.40
TOTAL €2.00
''');
    expect(r.currency, 'EUR');
    expect(r.purchaseDate, DateTime(2026, 8, 15));
    expect(r.items.single.name, 'Croissant');
    expect(r.totalMinor, 200);
    expect(r.itemsMatchTotal, isFalse);
  });

  test('flags an ambiguous day/month order', () {
    final r = parse('IKEA\n05/06/2026\nLACK TABLE 29.00\nTOTAL 29.00');
    expect(r.purchaseDate, DateTime(2026, 6, 5));
    expect(r.dateAmbiguous, isTrue);
    expect(r.items.single.category, Category.furniture);
  });

  test('trailingAmount handles VAT codes, thousands and negatives', () {
    expect(ReceiptParser.trailingAmount('SOFA 1,299.00 A'), 129900);
    expect(ReceiptParser.trailingAmount('Saving 5.00-'), -500);
    expect(ReceiptParser.trailingAmount('Price 12.00 each for two'), isNull);
    expect(ReceiptParser.trailingAmount('Till 03'), isNull);
  });
}
