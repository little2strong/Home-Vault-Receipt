// On-device check of receipt reading: ML Kit text recognition followed by
// the receipt parser, on real images.
//
// Put the test receipts in the app's private files folder first:
//   adb push receipt_currys.jpg /data/local/tmp/
//   adb shell run-as com.homevault.home_vault_receipt mkdir -p files/ocr
//   adb shell run-as com.homevault.home_vault_receipt \
//       cp /data/local/tmp/receipt_currys.jpg files/ocr/
// then run:
//   flutter test integration_test/ocr_device_test.dart -d <device>
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_vault_receipt/core/models/enums.dart';
import 'package:home_vault_receipt/core/models/receipt_draft.dart';
import 'package:home_vault_receipt/core/parsing/receipt_parser.dart';
import 'package:home_vault_receipt/core/services/text_recognition_service.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final ocr = TextRecognitionService();
  final parser = ReceiptParser(clock: () => DateTime(2026, 10, 17));

  Future<ParsedReceipt?> read(String name) async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/ocr/$name');
    if (!file.existsSync()) {
      markTestSkipped('$name not on the device; see the header comment.');
      return null;
    }
    final doc = await ocr.recognise([
      DraftPage(localPath: file.path, contentType: 'image/jpeg'),
    ]);
    final parsed = parser.parse(doc);
    // ignore: avoid_print
    print(
      '--- $name ---\n${doc.text}\n'
      '=> shop=${parsed.shop} date=${parsed.purchaseDate} '
      'total=${parsed.totalMinor} vat=${parsed.taxMinor} '
      'returnDays=${parsed.returnDays}\n'
      '${parsed.items.map((i) => '   ${i.name} x${i.quantity} '
          '${i.lineTotalMinor} ${i.category.name}').join('\n')}',
    );
    return parsed;
  }

  testWidgets('Currys: shop, date, total, VAT, items and returns', (_) async {
    final r = await read('receipt_currys.jpg');
    if (r == null) return;
    expect(r.shop, 'Currys');
    expect(r.purchaseDate, DateTime(2026, 10, 12));
    expect(r.totalMinor, 55398);
    expect(r.taxMinor, 9233);
    expect(r.items.map((i) => i.lineTotalMinor), [49900, 1499, 3999]);
    expect(r.items.first.category, Category.electronics);
    expect(r.itemsMatchTotal, isTrue);
    expect(r.returnDays, 30);
  });

  testWidgets('Tesco: quantities on the same and the next line', (_) async {
    final r = await read('receipt_tesco.jpg');
    if (r == null) return;
    expect(r.shop, 'Tesco');
    expect(r.purchaseDate, DateTime(2026, 10, 14));
    expect(r.totalMinor, 1685);
    expect(r.items.map((i) => i.lineTotalMinor), [145, 250, 90, 1200]);
    expect(r.items[1].quantity, 2);
    expect(r.items[2].name, 'Bananas');
    expect(r.items[2].quantity, 2);
    expect(r.itemsMatchTotal, isTrue);
  });

  testWidgets('IKEA, photographed at a tilt', (_) async {
    final r = await read('receipt_ikea_tilted.jpg');
    if (r == null) return;
    expect(r.shop, 'IKEA');
    expect(r.purchaseDate, DateTime(2026, 10, 2));
    expect(r.totalMinor, 19700);
    expect(r.taxMinor, 3283);
    expect(r.items.map((i) => i.lineTotalMinor), [2900, 12000, 4800]);
    expect(r.items[1].category, Category.furniture);
    expect(r.items[2].quantity, 2);
    expect(r.itemsMatchTotal, isTrue);
    expect(r.returnDays, 365);
  });
}
