import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:home_vault_receipt/app/app.dart';
import 'package:home_vault_receipt/app/routes/app_pages.dart';
import 'package:home_vault_receipt/app/routes/app_routes.dart';
import 'package:home_vault_receipt/core/models/product_category.dart';
import 'package:home_vault_receipt/core/repositories/auth_repository.dart';
import 'package:home_vault_receipt/core/repositories/settings_repository.dart';
import 'package:home_vault_receipt/core/services/key_value_store.dart';
import 'package:home_vault_receipt/features/review/controller/edit_item_controller.dart';

/// Opens every screen with sample data on a small phone and fails on any
/// build error or layout overflow.
void main() {
  const receipt = 'sample-currys';
  const pdfReceipt = 'sample-john-lewis';
  const draft = 'sample-draft';
  const item = 'p-macbook';

  final arguments = <String, Object?>{
    Routes.categoryProducts: ProductCategory.electronics,
    Routes.reviewSummary: draft,
    Routes.reviewItems: draft,
    Routes.editDate: draft,
    Routes.duplicate: draft,
    Routes.editItem: const ItemEditArgs(),
    Routes.returnTerms: receipt,
    Routes.saved: receipt,
    Routes.uploadFailure: receipt,
    Routes.receiptDetail: receipt,
    Routes.originalDocument: pdfReceipt,
    Routes.editReceipt: receipt,
    Routes.deleteReceipt: receipt,
    Routes.reminderDetail: receipt,
    Routes.possessionDetail: item,
    Routes.itemGallery: item,
    Routes.itemDocuments: item,
    Routes.documentExtraction: item,
    Routes.ownershipTimeline: item,
    Routes.resaleDraft: item,
    Routes.ownershipStatus: item,
    Routes.secureSharing: item,
    Routes.warrantyAssistant: item,
    Routes.roomDetail: 'Living room',
    Routes.movingBox: 12,
    Routes.boxLabel: 12,
  };

  // These start work on open (saving, splash timer) and are covered elsewhere.
  const skipped = {Routes.splash, Routes.saving};

  // Screens with an intentionally endless progress animation.
  const animated = {Routes.ocrProcessing};

  for (final size in const [Size(360, 690), Size(768, 1024)]) {
    testWidgets(
      'every screen renders at ${size.width.toInt()}×${size.height.toInt()}',
      (tester) async {
        tester.view
          ..physicalSize = size * 2
          ..devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        addTearDown(Get.reset);

        await tester.pumpWidget(App(store: MemoryStore()));
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        final auth = Get.find<AuthRepository>();
        await tester.runAsync(() async {
          await Get.find<SettingsRepository>().completeOnboarding();
          await auth.createAccount(
            email: 'alex@example.com',
            password: 'secret123',
            name: 'Alex',
          );
          await auth.refreshVerification();
        });

        for (final page in AppPages.pages) {
          if (skipped.contains(page.name)) continue;
          Get.offAllNamed(Routes.shell);
          await tester.pumpAndSettle();
          Get.toNamed(page.name, arguments: arguments[page.name]);
          if (animated.contains(page.name)) {
            await tester.pump(const Duration(seconds: 1));
          } else {
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull, reason: page.name);
          expect(
            Get.currentRoute,
            page.name,
            reason: 'did not stay on ${page.name}',
          );
        }

        // The three tabs.
        Get.offAllNamed(Routes.shell);
        await tester.pumpAndSettle();
        for (final tab in ['Receipts', 'More', 'Home']) {
          await tester.tap(find.text(tab).last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: tab);
        }
      },
    );
  }
}
