import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:home_vault_receipt/app/app.dart';
import 'package:home_vault_receipt/app/routes/app_routes.dart';
import 'package:home_vault_receipt/core/models/receipt_model.dart';
import 'package:home_vault_receipt/core/repositories/auth_repository.dart';
import 'package:home_vault_receipt/core/repositories/receipt_repository.dart';
import 'package:home_vault_receipt/core/repositories/settings_repository.dart';
import 'package:home_vault_receipt/core/services/key_value_store.dart';

Future<void> _signedInHome(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(390, 844) * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  addTearDown(Get.reset);

  await tester.pumpWidget(App(store: MemoryStore()));
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
  final auth = Get.find<AuthRepository>();
  await tester.runAsync(() async {
    await Get.find<SettingsRepository>().completeOnboarding();
    await auth.createAccount(email: 'alex@example.com', password: 'secret123');
    await auth.refreshVerification();
  });
  Get.offAllNamed(Routes.shell);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('camera capture is reviewed, flagged as a duplicate and saved', (
    tester,
  ) async {
    await _signedInHome(tester);
    final receipts = Get.find<ReceiptRepository>();
    final before = receipts.savedCount;

    await _tap(tester, 'Add a receipt');
    await _tap(tester, 'Camera');
    expect(find.text('Ready to scan?'), findsOneWidget);
    await _tap(tester, 'Allow camera');
    await _tap(tester, 'Capture');
    await _tap(tester, 'Use this photo');
    expect(find.text('Photo 1'), findsOneWidget);

    await tester.tap(find.text('Read receipt'));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // OCR produced a draft that waits for review; nothing is saved yet.
    expect(find.text('Check the details.'), findsOneWidget);
    expect(receipts.drafts.where((r) => r.retailer == 'Currys'), hasLength(1));
    expect(receipts.savedCount, before);

    await _tap(tester, 'Review products');
    expect(find.text('Sony wireless headphones'), findsOneWidget);
    await _tap(tester, 'Confirm & save');

    // The sample vault already holds this Currys order reference.
    expect(find.text('Already in your vault?'), findsOneWidget);
    await _tap(tester, 'Save as a separate record');

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('One less thing\nto keep track of.'), findsOneWidget);
    expect(receipts.savedCount, before + 1);

    // A return date was printed but never confirmed, so none is stored.
    final saved = receipts.saved.firstWhere(
      (r) => r.source == ReceiptSource.camera && r.id.startsWith('rcpt'),
    );
    expect(saved.returnDeadline, isNull);
    expect(saved.originalsUploaded, isTrue);
  });

  testWidgets('manual entry validates and saves without an original', (
    tester,
  ) async {
    await _signedInHome(tester);
    final receipts = Get.find<ReceiptRepository>();

    await _tap(tester, 'Add a receipt');
    await _tap(tester, 'Manual entry');
    await _tap(tester, 'Save receipt');
    expect(find.text('This field is required'), findsOneWidget);
    expect(find.text('Choose the purchase date.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Boots');
    await tester.enterText(find.byType(TextFormField).at(1), '12.50');
    await _tap(tester, 'Choose date');
    await _tap(tester, 'OK');
    await _tap(tester, 'Save receipt');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Your receipt has been saved.'), findsOneWidget);
    final boots = receipts.saved.firstWhere((r) => r.retailer == 'Boots');
    expect(boots.total, 1250);
    expect(boots.hasOriginal, isFalse);
  });
}
