import 'package:flutter_test/flutter_test.dart';
import 'package:home_vault_receipt/core/models/enums.dart';
import 'package:home_vault_receipt/core/models/item.dart';
import 'package:home_vault_receipt/core/models/receipt_draft.dart';
import 'package:home_vault_receipt/core/models/vault_models.dart';
import 'package:home_vault_receipt/core/utils/dates.dart';
import 'package:home_vault_receipt/core/utils/formatters.dart';
import 'package:home_vault_receipt/core/utils/money.dart';
import 'package:home_vault_receipt/core/utils/receipt_date_parser.dart';
import 'package:home_vault_receipt/core/utils/search.dart';
import 'package:home_vault_receipt/features/products/controller/products_controller.dart';

Item item({
  String id = 'i',
  ItemType type = ItemType.physical,
  bool inHome = true,
  ItemStatus status = ItemStatus.owned,
  Map<String, int> allocations = const {'r1': 1},
  int quantity = 1,
  int? line = 1000,
  DateTime? bought,
  DateTime? warrantyEnd,
}) => Item(
  id: id,
  name: 'Lamp',
  category: Category.lighting,
  type: type,
  purpose: Purpose.home,
  currency: 'GBP',
  inHome: inHome,
  status: status,
  allocations: allocations,
  quantity: quantity,
  lineTotalMinor: line,
  purchaseDate: bought,
  warrantyEnd: warrantyEnd,
);

void main() {
  group('Money and dates', () {
    test('parses and formats minor units', () {
      expect(Money.parse('£1,099.00'), 109900);
      expect(Money.parse('12.345'), isNull);
      expect(Money.format(55398), '£553.98');
      expect(Money.format(8650, currency: 'EUR'), '€86.50');
    });

    test('calendar dates round-trip as YYYY-MM-DD', () {
      expect(Dates.toIso(DateTime(2026, 9, 2)), '2026-09-02');
      expect(Dates.parseIso('2026-09-02'), DateTime(2026, 9, 2));
      expect(Dates.parseIso('bad'), isNull);
    });

    test('formats dates the way the design does', () {
      expect(Formatters.medium(DateTime(2026, 9, 12)), '12 Sep 2026');
      expect(Formatters.mediumOrNotStated(null), 'Not stated');
      expect(Formatters.clock(38), '0:38');
      expect(Formatters.duration(72), '1 min 12 s');
    });

    test('flags ambiguous receipt dates', () {
      final p = ReceiptDateParser.parse('05/06/26');
      expect(p.date, DateTime(2026, 6, 5));
      expect(p.ambiguous, isTrue);
    });
  });

  group('Search', () {
    test('matches word prefixes across fields', () {
      expect(
        SearchText.matches('tv', ['Samsung 55" QLED TV', 'Currys']),
        isTrue,
      );
      expect(SearchText.matches('curr tv', ['Samsung TV', 'Currys']), isTrue);
      expect(SearchText.matches('sony', ['Samsung TV']), isFalse);
      expect(SearchText.matches('hv-000', ['HV-000123']), isTrue);
    });

    test('builds lowercase prefix tokens like the server', () {
      expect(SearchText.tokens(['TV room']), [
        'r', 'ro', 'roo', 'room', 't', 'tv', //
      ]);
    });
  });

  group('Items and the home inventory', () {
    test('only physical, in-home, owned items are on the inventory', () {
      expect(item().inInventory, isTrue);
      expect(item(type: ItemType.consumable).inInventory, isFalse);
      expect(item(inHome: false).inInventory, isFalse);
      expect(item(status: ItemStatus.sold).inInventory, isFalse);
    });

    test('splits value across rooms by quantity', () {
      final lamp = item(
        quantity: 2,
        line: 4800,
        allocations: const {'bed': 1, 'living': 1},
      );
      expect(lamp.isSplit, isTrue);
      expect(lamp.valueInRoom('bed'), 2400);
      expect(lamp.valueInRoom('living'), 2400);
      expect(lamp.displayName, 'Lamp × 2');
    });
  });

  group('Warranties', () {
    final today = DateTime(2026, 10, 6);
    Warranty w(DateTime end) => Warranty(itemId: 'x', endDate: end);

    test('Active, Expiring within 3 months, Expired', () {
      expect(w(DateTime(2028, 9, 12)).statusOn(today), WarrantyStatus.active);
      expect(
        w(DateTime(2026, 12, 18)).statusOn(today),
        WarrantyStatus.expiring,
      );
      expect(w(DateTime(2026, 7, 2)).statusOn(today), WarrantyStatus.expired);
      expect(w(DateTime(2026, 12, 18)).daysLeft(today), 73);
    });

    test('default reminders are 3 months and 2 weeks before', () {
      final end = DateTime(2028, 9, 12);
      expect(Warranty.threeMonthsBefore(end), DateTime(2028, 6, 12));
      expect(Warranty.twoWeeksBefore(end), DateTime(2028, 8, 29));
    });
  });

  group('Receipt drafts', () {
    ReceiptDraft draft() => ReceiptDraft(
      id: 'r1',
      saveKey: 'key-1234-5678',
      source: ReceiptSource.camera,
      createdAt: DateTime(2026, 10, 6),
      shop: 'Currys',
      purchaseDate: DateTime(2026, 9, 12),
      totalMinor: 55398,
      items: [
        DraftItem(
          id: 'a',
          name: 'TV',
          category: Category.electronics,
          lineTotalMinor: 49900,
        ),
        DraftItem(
          id: 'b',
          name: 'Cable',
          category: Category.accessories,
          lineTotalMinor: 1499,
        ),
        DraftItem(
          id: 'c',
          name: 'Bread',
          category: Category.groceries,
          lineTotalMinor: 3999,
        ),
      ],
    );

    test('survive being stored on the phone', () {
      final d = draft()..returnDeadline = DateTime(2026, 10, 12);
      final back = ReceiptDraft.fromJson(d.toJson());
      expect(back.shop, 'Currys');
      expect(back.items.length, 3);
      expect(back.items.first.category, Category.electronics);
      expect(back.returnDeadline, DateTime(2026, 10, 12));
      expect(back.itemsMatchTotal, isTrue);
    });

    test('Type defaults from category until the user picks one', () {
      final i = DraftItem(id: 'x', name: 'Milk', category: Category.groceries);
      expect(i.type, ItemType.consumable);
      i.setCategory(Category.electronics);
      expect(i.type, ItemType.physical);
      i
        ..type = ItemType.digital
        ..typeTouched = true
        ..setCategory(Category.furniture);
      expect(i.type, ItemType.digital);
    });

    test(
      '"Same for all" applies purpose and room; only physical items get a room',
      () {
        final d = draft()
          ..sharedRoomId = 'living'
          ..sharedPurpose = Purpose.work
          ..applyShared();
        expect(d.items.every((i) => i.purpose == Purpose.work), isTrue);
        expect(d.items[0].roomId, 'living');
        expect(d.items[2].roomId, isNull);
        final payload = d.items[2].toSavePayload();
        expect(payload['inHome'], isFalse);
        expect(payload['allocations'], isEmpty);
      },
    );
  });

  group('Product filters', () {
    final today = DateTime(2026, 10, 6);

    test('filter by room, warranty and date bought', () {
      final recent = item(
        bought: DateTime(2026, 9, 20),
        warrantyEnd: DateTime(2026, 12, 1),
      );
      final old = item(
        bought: DateTime(2024, 1, 1),
        allocations: const {'r2': 1},
      );
      expect(const ProductFilters(roomId: 'r1').matches(recent, today), isTrue);
      expect(const ProductFilters(roomId: 'r1').matches(old, today), isFalse);
      expect(
        const ProductFilters(
          warranty: WarrantyFilter.ending,
        ).matches(recent, today),
        isTrue,
      );
      expect(
        const ProductFilters(bought: BoughtFilter.days30).matches(old, today),
        isFalse,
      );
      expect(
        const ProductFilters(warranty: WarrantyFilter.none).matches(old, today),
        isTrue,
      );
    });

    test('counts active filters and clears with copyWith', () {
      const f = ProductFilters(purpose: Purpose.car, inHome: true);
      expect(f.activeCount, 2);
      expect(f.copyWith(purpose: null, inHome: false).isEmpty, isTrue);
    });
  });
}
