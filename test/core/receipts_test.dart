import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:home_vault_receipt/core/error/app_exception.dart';
import 'package:home_vault_receipt/core/models/product_category.dart';
import 'package:home_vault_receipt/core/models/receipt_document.dart';
import 'package:home_vault_receipt/core/models/receipt_filter.dart';
import 'package:home_vault_receipt/core/models/receipt_item.dart';
import 'package:home_vault_receipt/core/models/receipt_model.dart';
import 'package:home_vault_receipt/core/repositories/receipt_repository.dart';
import 'package:home_vault_receipt/core/services/export_service.dart';
import 'package:home_vault_receipt/core/services/key_value_store.dart';
import 'package:home_vault_receipt/core/services/receipt_save_service.dart';
import 'package:home_vault_receipt/core/services/upload_service.dart';

final _today = DateTime(2026, 10, 12);

Receipt _receipt(
  String id, {
  String retailer = 'Currys',
  int daysAgo = 0,
  int total = 17900,
  ProductCategory category = ProductCategory.electronics,
  String? reference,
  DateTime? returnDeadline,
  ReceiptStatus status = ReceiptStatus.saved,
  List<ReceiptDocument> documents = const [],
  String itemName = 'Sony wireless headphones',
}) => Receipt(
  id: id,
  retailer: retailer,
  purchaseDate: _today.subtract(Duration(days: daysAgo)),
  total: total,
  createdAt: _today,
  reference: reference,
  returnDeadline: returnDeadline,
  status: status,
  documents: documents,
  items: [
    ReceiptItem(
      id: 'item-$id',
      name: itemName,
      sourceDescription: 'SONY WH-1000XM5',
      lineTotal: total,
      category: category,
    ),
  ],
);

ReceiptRepository _repo({
  List<Receipt> seed = const [],
  KeyValueStore? store,
}) => ReceiptRepository(
  store: store ?? MemoryStore(),
  clock: () => _today,
  seed: (_) => seed,
);

void main() {
  setUp(() => Get.testMode = true);

  group('ReceiptRepository', () {
    test('lists saved receipts newest first and keeps drafts separate', () {
      final repo = _repo(
        seed: [
          _receipt('old', daysAgo: 10),
          _receipt('new', daysAgo: 1),
          _receipt('draft', status: ReceiptStatus.draft),
        ],
      );

      expect(repo.saved.map((r) => r.id), ['new', 'old']);
      expect(repo.drafts.map((r) => r.id), ['draft']);
      expect(repo.savedCount, 2);
    });

    test('persists every change and reloads it', () async {
      final store = MemoryStore();
      final repo = _repo(store: store);
      await repo.upsert(_receipt('a'));

      final reloaded = _repo(store: store);
      expect(reloaded.byId('a')?.retailer, 'Currys');
    });

    test('keeps each account in its own vault', () async {
      final store = MemoryStore();
      final repo = ReceiptRepository(
        store: store,
        clock: () => _today,
        userId: 'alex',
      );
      await repo.upsert(_receipt('alex-receipt'));

      repo.openVault('sam');
      expect(repo.receipts, isEmpty);

      repo.openVault('alex');
      expect(repo.byId('alex-receipt'), isNotNull);
    });

    test('refuses to save while signed out', () async {
      final repo = ReceiptRepository(store: MemoryStore(), userId: null);
      await expectLater(
        repo.upsert(_receipt('a')),
        throwsA(isA<AppException>()),
      );
      expect(repo.receipts, isEmpty);
    });

    test('throws when deleting a missing receipt', () {
      expect(_repo().delete('missing'), throwsA(isA<AppException>()));
    });

    test('stores purchase dates without a time of day', () async {
      final repo = _repo();
      final saved = await repo.upsert(
        _receipt('a').copyWith(
          purchaseDate: DateTime(2026, 10, 2, 15, 30),
          returnDeadline: DateTime(2026, 10, 20, 18),
        ),
      );
      expect(saved.purchaseDate, DateTime(2026, 10, 2));
      expect(saved.returnDeadline, DateTime(2026, 10, 20));
    });

    test('flags duplicates by reference or by shop, day and total', () {
      final repo = _repo(seed: [_receipt('saved', reference: 'CR-1')]);

      expect(repo.findDuplicate(_receipt('scan')), isNotNull);
      expect(
        repo.findDuplicate(
          _receipt('other', total: 100, daysAgo: 3, reference: 'cr-1 '),
        ),
        isNotNull,
      );
      expect(repo.findDuplicate(_receipt('different', total: 100)), isNull);
      expect(
        repo.findDuplicate(_receipt('scan').copyWith(currency: 'EUR')),
        isNull,
      );
    });

    test('enforces the pilot limit only for new saves', () async {
      final repo = _repo(
        seed: [
          for (var i = 0; i < ReceiptRepository.pilotLimit; i++)
            _receipt('r$i'),
        ],
      );

      expect(repo.isAtPilotLimit, isTrue);
      expect(
        repo.commit(_receipt('one-more')),
        throwsA(isA<QuotaExceededException>()),
      );
      // Editing an already saved record is still allowed.
      await repo.commit(repo.byId('r0')!.copyWith(retailer: 'Edited'));
      expect(repo.byId('r0')!.retailer, 'Edited');
    });

    test('lists open deadlines soonest first and skips closed ones', () {
      final repo = _repo(
        seed: [
          _receipt(
            'later',
            returnDeadline: _today.add(const Duration(days: 20)),
          ),
          _receipt('soon', returnDeadline: _today.add(const Duration(days: 3))),
          _receipt(
            'closed',
            returnDeadline: _today.subtract(const Duration(days: 1)),
          ),
          _receipt('none'),
        ],
      );

      expect(repo.openDeadlines().map((r) => r.id), ['soon', 'later']);
      expect(repo.openDeadlines(withinDays: 14).map((r) => r.id), ['soon']);
    });
  });

  group('ReceiptFilter', () {
    final receipts = [
      _receipt('tv', retailer: 'Currys', itemName: 'Television'),
      _receipt(
        'sofa',
        retailer: 'IKEA',
        category: ProductCategory.home,
        itemName: 'LANDSKRONA sofa',
        daysAgo: 40,
        reference: 'IK-55120',
      ),
    ];

    List<String> run(ReceiptFilter f) => [
      for (final r in receipts)
        if (f.matches(r, _today)) r.id,
    ];

    test('searches shop, product, reference and every word', () {
      expect(run(const ReceiptFilter(query: 'ikea')), ['sofa']);
      expect(run(const ReceiptFilter(query: 'sofa landskrona')), ['sofa']);
      expect(run(const ReceiptFilter(query: 'IK-55120')), ['sofa']);
      expect(run(const ReceiptFilter(query: 'sofa currys')), isEmpty);
    });

    test('filters by product category and date range', () {
      expect(run(const ReceiptFilter(category: ProductCategory.home)), [
        'sofa',
      ]);
      expect(
        run(ReceiptFilter(from: _today.subtract(const Duration(days: 7)))),
        ['tv'],
      );
    });

    test('counts refinements but not the search text', () {
      const f = ReceiptFilter(
        query: 'x',
        category: ProductCategory.home,
        currency: 'GBP',
      );
      expect(f.refinementCount, 2);
      expect(f.cleared().query, 'x');
      expect(f.cleared().refinementCount, 0);
    });
  });

  group('ReceiptSaveService', () {
    late ReceiptRepository repo;
    late UploadService uploads;
    late ReceiptSaveService saver;
    const photo = ReceiptDocument(
      id: 'd',
      kind: DocumentKind.image,
      fileName: 'r.jpg',
    );

    setUp(() {
      repo = _repo();
      uploads = UploadService(step: Duration.zero);
      saver = ReceiptSaveService(receipts: repo, uploads: uploads);
    });

    test('uploads originals before marking the record saved', () async {
      final progress = <double>[];
      final outcome = await saver.save(
        _receipt('a', status: ReceiptStatus.draft, documents: [photo]),
        onProgress: progress.add,
      );

      expect(outcome, SaveOutcome.saved);
      expect(repo.byId('a')!.status, ReceiptStatus.saved);
      expect(repo.byId('a')!.originalsUploaded, isTrue);
      expect(progress.last, 1);
    });

    test('queues on this device when offline', () async {
      uploads.isOnline.value = false;
      final outcome = await saver.save(
        _receipt('a', status: ReceiptStatus.draft),
      );

      expect(outcome, SaveOutcome.queued);
      expect(repo.byId('a')!.status, ReceiptStatus.queued);
    });

    test(
      'keeps the draft after an interrupted upload and retries without duplicates',
      () async {
        uploads.failNextUpload.value = true;
        final first = await saver.save(
          _receipt('a', status: ReceiptStatus.draft, documents: [photo]),
        );
        expect(first, SaveOutcome.failed);
        expect(repo.byId('a')!.status, ReceiptStatus.failed);

        expect(await saver.retryPending(), 1);
        expect(repo.receipts, hasLength(1));
        expect(repo.byId('a')!.status, ReceiptStatus.saved);
      },
    );

    test('stops before writing anything when the vault is full', () async {
      repo = _repo(
        seed: [
          for (var i = 0; i < ReceiptRepository.pilotLimit; i++)
            _receipt('r$i'),
        ],
      );
      saver = ReceiptSaveService(receipts: repo, uploads: uploads);

      expect(
        saver.save(_receipt('new', status: ReceiptStatus.draft)),
        throwsA(isA<QuotaExceededException>()),
      );
      expect(repo.byId('new'), isNull);
    });
  });

  group('ExportService', () {
    final service = ExportService();

    test('writes one CSV row per product and neutralises formulas', () {
      final csv = service.toCsv([
        _receipt('a', retailer: '=HYPERLINK("x")', itemName: 'Lamp, floor'),
      ]);
      final rows = csv.split('\r\n');

      expect(rows, hasLength(2));
      expect(rows[1], contains('"\'=HYPERLINK(""x"")"'));
      expect(rows[1], contains('"Lamp, floor"'));
    });

    test('selects by scope and reports expiry', () {
      final saved = [_receipt('recent'), _receipt('old', daysAgo: 400)];
      final archive = service.build(
        saved,
        const ExportRequest(
          scope: ExportScope.last12Months,
          format: ExportFormat.json,
        ),
        _today,
      );

      expect(archive.receiptCount, 1);
      expect(archive.csv, isNull);
      expect(archive.json, contains('"recent"'));
      expect(archive.expiresAt, _today.add(const Duration(hours: 24)));
    });
  });
}
