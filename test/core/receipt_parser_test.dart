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

  test('reads VAT and the gross total, not "Total inc VAT" or the net', () {
    final r = parse('''
WICKES
03/10/2026
OAK BOOKCASE 120.00
FRYING PAN 24.00
GIFT CARD 25.00
Net total 140.83
VAT 28.17
Total inc VAT 169.00
CARD 169.00
See you next time
''');
    expect(r.shop, 'Wickes');
    expect(r.totalMinor, 16900);
    expect(r.taxMinor, 2817);
    expect(r.items.map((i) => i.name), [
      'Oak Bookcase',
      'Frying Pan',
      'Gift Card',
    ]);
    expect(r.items.first.category, Category.furniture);
    expect(r.items.last.category, Category.software);
    expect(r.itemsMatchTotal, isTrue);
  });

  test('VAT summary lines never take the total as the VAT', () {
    final r = parse('''
CURRYS
12/09/2026
LAPTOP 600.00
TOTAL 600.00
Total incl. VAT 600.00
VAT TOTAL 100.00
''');
    expect(r.totalMinor, 60000);
    expect(r.taxMinor, 10000);
  });

  test('fixes common OCR misreads in prices', () {
    final r = parse('''
ARGOS
10/10/2026
KETTLE 29,99
TOASTER 1O.99
TOTAL 4O.98
''');
    expect(r.items.map((i) => i.lineTotalMinor), [2999, 1099]);
    expect(r.totalMinor, 4098);
    expect(r.itemsMatchTotal, isTrue);
    expect(ReceiptParser.trailingAmount('CHAIR 1.234,56'), 123456);
    expect(ReceiptParser.trailingAmount('DESK 12. 99'), 1299);
    expect(ReceiptParser.trailingAmount('No.12 HOOK 3.50'), 350);
  });

  test('fixes OCR misreads seen on a phone: B0OKCASE and (@', () {
    // Text exactly as ML Kit returned it for a tilted IKEA receipt.
    final r = parse('''
IKEA
OAK B0OKCASE 120.00
Table Lamp 2 (@ 24.00 48.00
PS5 CONSOLE V12 450.00
TOTAL 618.00
''');
    expect(r.items[0].name, 'Oak Bookcase');
    expect(r.items[0].category, Category.furniture);
    expect(r.items[1].name, 'Table Lamp');
    expect(r.items[1].quantity, 2);
    expect(r.items[2].name, 'PS5 Console V12');
  });

  test('pairs names and prices that a tilted photo split onto two rows', () {
    final doc = OcrDocument([
      const OcrPage(
        width: 800,
        height: 400,
        lines: [
          OcrLine('HALFORDS', 20, 10, 200, 40),
          OcrLine('04/10/2026', 20, 50, 200, 80),
          // Price lower than its name.
          OcrLine('ENGINE OIL 5W-30', 20, 100, 300, 130),
          OcrLine('32.00', 600, 122, 700, 152),
          // Price higher than its name.
          OcrLine('18.50', 600, 170, 700, 200),
          OcrLine('WIPER BLADES', 20, 193, 300, 223),
          OcrLine('TOTAL', 20, 250, 120, 280),
          OcrLine('50.50', 600, 272, 700, 302),
        ],
      ),
    ]);
    final r = parser.parse(doc);
    expect(r.shop, 'Halfords');
    expect(r.items.map((i) => i.name), ['Engine Oil 5W-30', 'Wiper Blades']);
    expect(r.items.map((i) => i.lineTotalMinor), [3200, 1850]);
    expect(r.items.every((i) => i.category == Category.car), isTrue);
    expect(r.totalMinor, 5050);
    expect(r.itemsMatchTotal, isTrue);
  });

  test('reads mid-line quantities and weighed goods', () {
    final r = parse('''
DUNELM
01/10/2026
TABLE LAMP 2 @ 24.00 48.00
BANANAS 0.856 kg @ £0.68/kg 0.58
TOTAL 48.58
''');
    final lamp = r.items.first;
    expect(lamp.name, 'Table Lamp');
    expect(lamp.quantity, 2);
    expect(lamp.unitPriceMinor, 2400);
    expect(lamp.lineTotalMinor, 4800);
    expect(r.items.last.name, 'Bananas');
    expect(r.items.last.lineTotalMinor, 58);
  });

  test('keeps card products but drops card payment lines', () {
    final r = parse('''
JOE'S CAMERAS
01/10/2026
SD CARD 64GB 9.99
DEBIT CARD
CARD 9.99
TOTAL 9.99
''');
    expect(r.items.single.name, 'SD Card 64GB');
  });

  test('reads year-first, month-first and "Express" store dates', () {
    expect(parse('SHOP\n2026/09/12\nTOTAL 1.00').purchaseDate,
        DateTime(2026, 9, 12));
    expect(parse('SHOP\nOrder date: Oct 1, 2026\nTOTAL 1.00').purchaseDate,
        DateTime(2026, 10, 1));
    expect(parse('TESCO EXPRESS 06/10/2026\nTOTAL 1.00').purchaseDate,
        DateTime(2026, 10, 6));
    // Impossible dates are not read as dates.
    expect(parse('SHOP\n2026-02-30\nTOTAL 1.00').purchaseDate, isNull);
  });

  test('does not take everyday words in the body as the shop', () {
    final r = parse('''
Joe's Hardware
01/10/2026
BRAMLEY APPLES 1.20
WALKING BOOTS 45.00
TOTAL 46.20
See you next time
''');
    expect(r.shop, "Joe's Hardware");
  });

  test('suggests return deadlines from days or an explicit date', () {
    final bought = DateTime(2026, 10, 1);
    expect(
      ReceiptParser.returnDeadlineFrom('Return within 28 days', bought),
      DateTime(2026, 10, 29),
    );
    expect(
      ReceiptParser.returnDeadlineFrom(
        'Returns accepted until 12/11/2026',
        bought,
      ),
      DateTime(2026, 11, 12),
    );
    expect(ReceiptParser.returnDeadlineFrom('Return within 28 days', null),
        isNull);
  });

  test('trailingAmount handles VAT codes, thousands and negatives', () {
    expect(ReceiptParser.trailingAmount('SOFA 1,299.00 A'), 129900);
    expect(ReceiptParser.trailingAmount('Saving 5.00-'), -500);
    expect(ReceiptParser.trailingAmount('Price 12.00 each for two'), isNull);
    expect(ReceiptParser.trailingAmount('Till 03'), isNull);
  });
}
