import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:home_vault_receipt/app/routes/app_pages.dart';
import 'package:home_vault_receipt/app/routes/app_routes.dart';
import 'package:home_vault_receipt/core/data/auth_repository.dart';
import 'package:home_vault_receipt/core/data/file_store.dart';
import 'package:home_vault_receipt/core/data/vault_repository.dart';
import 'package:home_vault_receipt/core/data/vault_store.dart';
import 'package:home_vault_receipt/core/models/receipt_draft.dart';
import 'package:home_vault_receipt/core/services/capture_service.dart';
import 'package:home_vault_receipt/core/services/connectivity_service.dart';
import 'package:home_vault_receipt/core/services/draft_store.dart';
import 'package:home_vault_receipt/core/services/receipt_saver.dart';
import 'package:home_vault_receipt/core/theme/app_theme.dart';
import 'package:home_vault_receipt/core/widgets/vault_ui.dart';

class _Files implements FileStore {
  @override
  Future<Uint8List> getData(String path, {int maxBytes = 0}) async =>
      throw StateError('no files in tests');
  @override
  Future<void> put(
    String path,
    Uint8List bytes, {
    required String contentType,
    Map<String, String> metadata = const {},
    void Function(double progress)? onProgress,
  }) async {}
  @override
  Future<void> downloadToFile(String path, String localPath) async {}
  @override
  Future<bool> exists(String path) async => false;
}

class _Saver extends ReceiptSaver {
  _Saver(VaultStore store, VaultRepository repo)
    : super(
        store: store,
        repo: repo,
        drafts: DraftStore(),
        capture: CaptureService(),
        connectivity: ConnectivityService(),
      );

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<List<ReceiptDraft>> unfinished() async => [];
}

Future<FakeFirebaseFirestore> seed() async {
  final db = FakeFirebaseFirestore();
  final now = Timestamp.now();
  const u = 'users/alice';
  await db.doc(u).set({
    'displayName': 'Sam Patel',
    'mainCurrency': 'GBP',
    'timezone': 'Europe/London',
    'notificationsAsked': true,
  });
  await db.doc('$u/rooms/living').set({
    'type': 'livingRoom',
    'name': 'Living room',
    'order': 0,
  });
  await db.doc('$u/rooms/bed1').set({
    'type': 'bedroom',
    'name': 'Bedroom 1',
    'order': 1,
  });
  await db.doc('$u/receipts/r1').set({
    'number': 'HV-000123',
    'shop': 'Currys',
    'purchaseDate': '2026-09-12',
    'currency': 'GBP',
    'totalMinor': 55398,
    'taxMinor': 9233,
    'source': 'camera',
    'originalPaths': [
      '$u/receipts/r1/original-1.jpg',
      '$u/receipts/r1/original-2.jpg',
    ],
    'originalTypes': ['image/jpeg', 'image/jpeg'],
    'itemCount': 3,
    'itemPreview': 'Samsung 55" QLED TV',
    'returnWording': 'Returns accepted within 30 days with proof of purchase.',
    'confirmedAt': now,
  });
  final items = [
    (
      'tv',
      'Samsung 55" QLED TV',
      'electronics',
      'physical',
      49900,
      1,
      {'living': 1},
      true,
    ),
    (
      'hdmi',
      'HDMI cable 2m',
      'accessories',
      'physical',
      1499,
      1,
      {'living': 1},
      false,
    ),
    (
      'lamp',
      'IKEA table lamp',
      'lighting',
      'physical',
      4800,
      2,
      {'living': 1, 'bed1': 1},
      false,
    ),
    (
      'oil',
      'Castrol 5W-30 engine oil',
      'car',
      'consumable',
      4200,
      1,
      <String, int>{},
      false,
    ),
    (
      'ms365',
      'Microsoft 365 Family',
      'software',
      'digital',
      10499,
      1,
      <String, int>{},
      false,
    ),
  ];
  for (final (id, name, cat, type, price, qty, alloc, high) in items) {
    await db.doc('$u/items/$id').set({
      'name': name,
      'category': cat,
      'type': type,
      'purpose': cat == 'car' ? 'car' : (type == 'digital' ? 'work' : 'home'),
      'currency': 'GBP',
      'receiptId': 'r1',
      'receiptNumber': 'HV-000123',
      'purchaseDate': '2026-09-12',
      'shop': 'Currys',
      'inHome': type == 'physical',
      'allocations': alloc,
      'roomIds': alloc.keys.toList(),
      'quantity': qty,
      'lineTotalMinor': price,
      'unitPriceMinor': price ~/ qty,
      'status': 'owned',
      'highValue': high,
      'serial': id == 'tv' ? '0A7H3CPW500912' : null,
      'photoCount': 0,
      'createdAt': now,
    });
  }
  await db.doc('$u/items/print').set({
    'name': 'Framed print',
    'category': 'other',
    'type': 'physical',
    'purpose': 'home',
    'currency': 'GBP',
    'inHome': true,
    'allocations': {'living': 1},
    'quantity': 1,
    'lineTotalMinor': 12000,
    'status': 'owned',
    'estimated': true,
    'yearBought': 2021,
    'createdAt': now,
  });
  final soon = DateTime.now().add(const Duration(days: 41));
  String iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  await db.doc('$u/warranties/tv').set({
    'itemId': 'tv',
    'endDate': '2028-09-12',
    'itemName': 'Samsung 55" QLED TV',
    'shop': 'Currys',
  });
  await db.doc('$u/warranties/hdmi').set({
    'itemId': 'hdmi',
    'endDate': iso(soon),
    'itemName': 'HDMI cable 2m',
    'shop': 'Currys',
  });
  await db.doc('$u/returns/r1').set({
    'deadline': iso(DateTime.now().add(const Duration(days: 5))),
    'shop': 'Currys',
    'label': 'Samsung 55" QLED TV',
  });
  await db.doc('$u/cars/golf').set({'name': 'Golf'});
  await db.doc('$u/stats/spending').set({
    'last30Days': {'GBP': 61240},
    'last365Days': {'GBP': 718420, 'EUR': 8650},
    'lifetime': {'GBP': 1190265},
    'receipts30': 14,
    'receipts365': 96,
    'receiptsLifetime': 120,
    'byCategory365': {
      'GBP': {'groceries': 231040, 'electronics': 164298},
    },
    'byPurpose365': {
      'GBP': {'home': 592000, 'car': 78000},
    },
    'cars': {
      'golf': {
        'last30Days': {'GBP': 8400},
        'last365Days': {'GBP': 61200},
        'itemCount': 1,
      },
    },
  });
  return db;
}

Future<void> boot(
  WidgetTester tester,
  String route, {
  Size size = const Size(390, 844),
  bool web = false,
}) async {
  Get.testMode = true;
  Get.reset();
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final db = await seed();
  final auth = AuthRepository(
    MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: 'alice',
        email: 'sam@example.com',
        displayName: 'Sam Patel',
      ),
    ),
  );
  Get.put(auth, permanent: true);
  Get.put<FileStore>(_Files(), permanent: true);
  final store = Get.put(VaultStore(auth, db), permanent: true);
  final repo = Get.put(
    VaultRepository(uid: () => 'alice', files: Get.find(), db: db),
    permanent: true,
  );
  Get.put<ReceiptSaver>(_Saver(store, repo), permanent: true);

  await tester.pumpWidget(
    GetMaterialApp(
      theme: AppTheme.light,
      initialRoute: route,
      getPages: web ? AppPages.web : AppPages.app,
    ),
  );
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 300)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  tearDown(Get.reset);

  testWidgets('06 Home shows spending, expiring soon and recent purchases', (
    t,
  ) async {
    await boot(t, Routes.shell);
    expect(find.text('Sam'), findsOneWidget);
    expect(find.text('£612.40'), findsOneWidget);
    expect(find.text('Expiring soon'), findsOneWidget);
    expect(find.text('HDMI cable 2m'), findsWidgets);
    await t.scrollUntilVisible(find.text('Recent purchases'), 200);
    expect(find.text('Recent purchases'), findsOneWidget);
    expect(find.textContaining('Samsung 55" QLED TV'), findsWidgets);
    expect(t.takeException(), isNull);
  });

  testWidgets('19 Products lists items with View receipt and filters', (
    t,
  ) async {
    await boot(t, Routes.shell);
    await t.tap(find.text('Products').last);
    await t.pumpAndSettle();
    expect(find.text('6 items'), findsOneWidget);
    expect(find.text('View receipt'), findsWidgets);
    expect(find.text('~£120'), findsOneWidget);
    final carChip = find.widgetWithText(ChoicePill, 'Car');
    await t.ensureVisible(carChip);
    await t.tap(carChip);
    await t.pumpAndSettle();
    expect(find.text('Castrol 5W-30 engine oil'), findsOneWidget);
    expect(find.text('Framed print'), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('30 Warranties groups by status with words, not colour alone', (
    t,
  ) async {
    await boot(t, Routes.shell);
    await t.tap(find.text('Warranties').last);
    await t.pumpAndSettle();
    expect(find.text('ENDING WITHIN 3 MONTHS'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('RETURN DEADLINES'), findsOneWidget);
    expect(find.text('Active'), findsWidgets);
    expect(t.takeException(), isNull);
  });

  testWidgets('32 Account shows spending in the main currency', (t) async {
    await boot(t, Routes.shell);
    await t.tap(find.text('Account').last);
    await t.pumpAndSettle();
    expect(find.text('Sam Patel'), findsOneWidget);
    expect(find.text('£7,184.20'), findsOneWidget);
    expect(find.text('Download lists'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('21 Item detail shows receipt, warranty and evidence', (t) async {
    await boot(t, Routes.item('tv'));
    expect(find.text('Samsung 55" QLED TV'), findsOneWidget);
    expect(find.text('HV-000123'), findsOneWidget);
    expect(find.textContaining('Active · ends 12 Sep 2028'), findsOneWidget);
    expect(find.text('0A7H3CPW500912'), findsOneWidget);
    expect(find.text('View receipt'), findsOneWidget);
    expect(find.text('High value'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('22 Receipt detail shows VAT, Not stated and its items', (
    t,
  ) async {
    await boot(t, Routes.receipt('r1'));
    expect(find.text('Currys'), findsOneWidget);
    expect(find.text('£553.98'), findsOneWidget);
    expect(find.text('£92.33'), findsOneWidget);
    expect(find.text('Not stated'), findsOneWidget);
    expect(find.text('Camera scan · 2 pages'), findsOneWidget);
    expect(find.text('View original receipt'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('27 Rooms totals the inventory per room, with splits', (t) async {
    await boot(t, Routes.rooms);
    expect(find.text('Home inventory'), findsOneWidget);
    expect(find.text('Living room'), findsOneWidget);
    expect(find.text('Bedroom 1'), findsOneWidget);
    // TV 499 + HDMI 14.99 + lamp 24 + print 120 + lamp 24 in Bedroom 1.
    expect(find.text('£681.99'), findsOneWidget);
    expect(find.text('£24.00'), findsOneWidget);
    expect(find.textContaining('high-value item'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('28 Room detail marks splits and estimates', (t) async {
    await boot(t, Routes.room('living'));
    expect(find.text('1 of 2 · other in Bedroom 1'), findsOneWidget);
    expect(find.textContaining('No receipt · estimate'), findsOneWidget);
    expect(find.text('Room walkthrough'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('07 Search finds items, receipts and rooms', (t) async {
    await boot(t, Routes.search);
    await t.enterText(find.byType(TextField), 'living');
    await t.pumpAndSettle();
    await t.ensureVisible(find.widgetWithText(ChoicePill, 'Rooms'));
    await t.tap(find.widgetWithText(ChoicePill, 'Rooms'));
    await t.pumpAndSettle();
    expect(find.text('ROOMS'), findsOneWidget);
    await t.ensureVisible(find.widgetWithText(ChoicePill, 'All'));
    await t.tap(find.widgetWithText(ChoicePill, 'All'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'hv-000123');
    await t.pumpAndSettle();
    await t.ensureVisible(find.widgetWithText(ChoicePill, 'Receipts'));
    await t.tap(find.widgetWithText(ChoicePill, 'Receipts'));
    await t.pumpAndSettle();
    expect(find.text('RECEIPTS'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('33 Spending shows the year and other currencies separately', (
    t,
  ) async {
    await boot(t, Routes.spending);
    expect(find.text('£7,184.20'), findsOneWidget);
    expect(find.textContaining('€86.50'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('34 Cars render', (t) async {
    await boot(t, Routes.cars);
    expect(find.text('Golf'), findsOneWidget);
    expect(find.text('£84.00'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('37 Settings render', (t) async {
    await boot(t, Routes.settings);
    await t.scrollUntilVisible(find.text('Delete account'), 200);
    expect(find.text('Keep photo location'), findsOneWidget);
    expect(find.text('Delete account'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('35 Export defaults to the home inventory as PDF', (t) async {
    await boot(t, Routes.export);
    expect(find.text('Download a list'), findsOneWidget);
    expect(find.textContaining('Create PDF · 4 items'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('38 Delete account explains what goes', (t) async {
    await boot(t, Routes.deleteAccount);
    expect(
      find.textContaining('1 receipt and their originals'),
      findsOneWidget,
    );
    expect(find.text('Keep my account'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('Text at 200% still lays out on Home', (t) async {
    t.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await boot(t, Routes.shell);
    expect(t.takeException(), isNull);
  });

  group('website on a laptop', () {
    const laptop = Size(1280, 1000);

    testWidgets('W2 dashboard', (t) async {
      await boot(t, Routes.webDashboard, size: laptop, web: true);
      expect(find.text('Welcome back, Sam'), findsOneWidget);
      expect(find.text('Quick downloads'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('W3 products', (t) async {
      await boot(t, Routes.webProducts, size: laptop, web: true);
      expect(find.text('Showing 1–6 of 6'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('W4 item detail', (t) async {
      await boot(t, Routes.webItem('tv'), size: laptop, web: true);
      expect(find.text('View original receipt'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('W5 home inventory', (t) async {
      await boot(t, Routes.webInventory, size: laptop, web: true);
      expect(find.text('Download for insurer'), findsOneWidget);
      expect(find.text('No receipt · no photo'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('W6 downloads', (t) async {
      await boot(t, Routes.webDownloads, size: laptop, web: true);
      expect(find.text('Everything'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('W2 dashboard on a phone-width browser', (t) async {
      await boot(t, Routes.webDashboard, web: true);
      expect(t.takeException(), isNull);
    });
  });
}
