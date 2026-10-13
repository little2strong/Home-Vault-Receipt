import 'package:get/get.dart';

import '../models/ownership_models.dart';
import '../models/product_category.dart';
import '../utils/dates.dart';
import '../utils/ids.dart';

/// In-memory data for the ownership roadmap screens. These features are not
/// part of the launch release; nothing here is persisted.
class OwnershipRepository {
  OwnershipRepository({this._clock = DateTime.now}) {
    _seed();
  }

  final Clock _clock;

  final possessions = <Possession>[].obs;
  final maintenance = <MaintenanceTask>[].obs;
  final repairs = <RepairRecord>[].obs;
  final households = <Household>[].obs;
  final members = <HouseholdMember>[].obs;
  final activity = <ActivityEntry>[].obs;
  final boxes = <MovingBox>[].obs;
  final inbox = <InboxDraft>[].obs;
  final appraisals = <Appraisal>[].obs;
  final shareLinks = <ShareLink>[].obs;
  final claims = <ClaimDraft>[].obs;
  final rooms = <String>[
    'Living room',
    'Kitchen',
    'Office',
    'Bedroom',
    'Garage',
  ].obs;
  final collections = <String>['Watches', 'Cameras', 'Art'].obs;

  DateTime get today => Dates.dateOnly(_clock());

  Possession? byId(String id) =>
      possessions.firstWhereOrNull((p) => p.id == id);

  List<Possession> inRoom(String room) =>
      possessions.where((p) => p.room == room).toList();

  List<Possession> inCollection(String name) =>
      possessions.where((p) => p.collection == name).toList();

  int recordedValue(Iterable<Possession> items) =>
      items.fold(0, (sum, p) => sum + (p.purchasePrice ?? 0));

  /// Share of owned possessions with each kind of evidence, 0–100. This is a
  /// documentation score, not an insurance coverage figure.
  int completenessPercent() {
    final owned = possessions.where((p) => p.status == OwnershipStatus.owned);
    if (owned.isEmpty) return 0;
    var met = 0;
    for (final p in owned) {
      met += [
        p.hasPhoto,
        p.hasReceipt,
        p.hasSerial,
        p.hasPurchaseDetails,
      ].where((ok) => ok).length;
    }
    return (met * 100 / (owned.length * 4)).round();
  }

  int missing(bool Function(Possession p) has) => possessions
      .where((p) => p.status == OwnershipStatus.owned && !has(p))
      .length;

  void addPossession(Possession p) {
    possessions.insert(0, p);
    _log('Item added', p.name);
  }

  void updatePossession(Possession p) {
    final i = possessions.indexWhere((e) => e.id == p.id);
    if (i != -1) possessions[i] = p;
    _log('Item edited', p.name);
  }

  void addMaintenance(MaintenanceTask task) {
    maintenance.add(task);
    maintenance.sort((a, b) => a.due.compareTo(b.due));
  }

  void addRepair(RepairRecord record) => repairs.insert(0, record);

  void addMember(HouseholdMember member) {
    members.add(member);
    _log('Invitation sent', member.email ?? member.name);
  }

  void addRoom(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _sameName(rooms, trimmed)) return;
    rooms.add(trimmed);
  }

  void addCollection(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _sameName(collections, trimmed)) return;
    collections.add(trimmed);
  }

  void addHousehold(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty ||
        households.any((h) => h.name.toLowerCase() == trimmed.toLowerCase())) {
      return;
    }
    households.add(
      Household(
        id: Ids.next('home'),
        name: trimmed,
        itemCount: 0,
        role: 'owner',
      ),
    );
  }

  bool _sameName(Iterable<String> existing, String name) =>
      existing.any((e) => e.toLowerCase() == name.toLowerCase());

  void _log(String title, String detail) =>
      activity.insert(0, ActivityEntry('Today', title, 'You · $detail.'));

  void _seed() {
    final t = today;
    DateTime ago(int d) => Dates.addDays(t, -d);
    DateTime ahead(int d) => Dates.addDays(t, d);

    possessions.assignAll([
      Possession(
        id: 'p-macbook',
        name: 'MacBook Air',
        room: 'Office',
        brandModel: 'Apple · M3 13-inch',
        category: ProductCategory.electronics,
        purchasePrice: 109900,
        purchaseDate: ago(30),
        retailer: 'Apple',
        serialNumber: 'C02-SAMPLE-1048',
        modelNumber: 'A3113',
        receiptId: 'sample-apple',
        warrantyExpiry: Dates.addMonths(ago(30), 12),
        photos: const ['Product photo', 'Serial label', 'Condition photo'],
        documents: const [
          OwnedDocument('Original receipt', 'PDF · purchase invoice'),
          OwnedDocument('Warranty terms', 'PDF · 2 pages'),
          OwnedDocument('Product manual', 'Verified model link'),
          OwnedDocument('Repair invoice', 'No document yet', missing: true),
        ],
        events: const [
          OwnershipEvent(
            label: 'Bought',
            title: 'Purchased',
            detail: 'Apple receipt attached.',
          ),
          OwnershipEvent(
            label: 'Added',
            title: 'Documented',
            detail: 'Serial and photographs added.',
          ),
          OwnershipEvent(
            label: 'Next',
            title: 'Keep the record current',
            detail: 'Log repairs or change ownership status.',
          ),
        ],
      ),
      Possession(
        id: 'p-headphones',
        name: 'Headphones',
        room: 'Office',
        brandModel: 'Sony WH-1000XM5',
        category: ProductCategory.electronics,
        purchasePrice: 17900,
        purchaseDate: ago(2),
        retailer: 'Currys',
        receiptId: 'sample-currys',
        photos: const ['Product photo'],
      ),
      Possession(
        id: 'p-coffee',
        name: 'Coffee machine',
        room: 'Kitchen',
        brandModel: 'Barista espresso',
        category: ProductCategory.appliances,
        purchasePrice: 24900,
        purchaseDate: ago(18),
        retailer: 'John Lewis',
        serialNumber: 'SAMPLE-CM-8821',
        receiptId: 'sample-john-lewis',
        warrantyExpiry: Dates.addMonths(ago(18), 12),
        photos: const ['Product photo'],
      ),
      const Possession(
        id: 'p-sofa',
        name: 'Sofa',
        room: 'Living room',
        category: ProductCategory.home,
        purchasePrice: 34900,
        receiptId: 'sample-ikea',
      ),
      const Possession(
        id: 'p-tv',
        name: 'Television',
        room: 'Living room',
        category: ProductCategory.electronics,
        purchasePrice: 129900,
        warrantyTermsMissing: true,
        photos: ['Product photo'],
      ),
      const Possession(
        id: 'p-soundbar',
        name: 'Soundbar',
        room: 'Living room',
        category: ProductCategory.electronics,
        purchasePrice: 29900,
      ),
      const Possession(
        id: 'p-table',
        name: 'Coffee table',
        room: 'Living room',
        category: ProductCategory.home,
        purchasePrice: 12900,
      ),
      const Possession(
        id: 'p-bicycle',
        name: 'Bicycle',
        room: 'Garage',
        category: ProductCategory.other,
        purchasePrice: 65000,
        photos: ['Product photo'],
      ),
      const Possession(
        id: 'p-bracelet',
        name: 'Gold bracelet',
        room: 'Bedroom',
        category: ProductCategory.clothing,
        purchasePrice: 125000,
        collection: 'Watches',
      ),
    ]);

    maintenance.assignAll([
      MaintenanceTask(
        id: 'm-1',
        item: 'Coffee machine',
        work: 'Descale',
        due: ahead(8),
      ),
      MaintenanceTask(
        id: 'm-2',
        item: 'Bicycle',
        work: 'Service',
        due: ahead(20),
      ),
      MaintenanceTask(
        id: 'm-3',
        item: 'Boiler',
        work: 'Annual service',
        due: ahead(53),
      ),
    ]);
    repairs.assignAll([
      RepairRecord(
        id: 'r-1',
        item: 'Bicycle',
        problem: 'Rear brake cable worn',
        provider: 'Local cycle workshop',
        cost: 3500,
        date: ago(9),
      ),
    ]);
    households.assignAll(const [
      Household(id: 'h-1', name: 'Main home', itemCount: 24, role: 'owner'),
      Household(
        id: 'h-2',
        name: 'Holiday home',
        itemCount: 8,
        role: 'administrator',
      ),
      Household(id: 'h-3', name: 'Storage unit', itemCount: 12, role: 'owner'),
    ]);
    members.assignAll(const [
      HouseholdMember(id: 'u-1', name: 'You', role: MemberRole.owner),
      HouseholdMember(id: 'u-2', name: 'Sam Taylor', role: MemberRole.adult),
      HouseholdMember(id: 'u-3', name: 'Jamie Morgan', role: MemberRole.viewer),
    ]);
    activity.assignAll(const [
      ActivityEntry('Today', 'Receipt added', 'You · Currys purchase.'),
      ActivityEntry(
        'Yesterday',
        'Document uploaded',
        'Sam · coffee machine warranty.',
      ),
      ActivityEntry('Last week', 'Item edited', 'You · living room sofa.'),
    ]);
    boxes.assignAll(const [
      MovingBox(
        number: 12,
        room: 'Kitchen',
        status: BoxStatus.packed,
        items: ['Blender', 'Coffee grinder', 'Kettle', 'Toaster'],
        destination: 'New home · kitchen',
      ),
      MovingBox(
        number: 13,
        room: 'Office',
        status: BoxStatus.inTransit,
        items: ['Monitor', 'Laptop stand', 'Desk lamp', 'Cables'],
        destination: 'New home · office',
      ),
      MovingBox(
        number: 14,
        room: 'Living room',
        status: BoxStatus.notPacked,
        items: ['Soundbar', 'Cushions'],
        destination: 'New home · living room',
      ),
    ]);
    inbox.assignAll(const [
      InboxDraft('i-1', 'Sony headphones', 'Receipt import', 'needs category'),
      InboxDraft('i-2', 'Air fryer', 'Photo scan', 'model unconfirmed'),
      InboxDraft(
        'i-3',
        'Coffee machine',
        'Email import',
        'check purchase date',
      ),
    ]);
    appraisals.assignAll([
      Appraisal(
        item: 'Gold bracelet',
        appraiser: 'Example jeweller',
        value: 125000,
        date: Dates.addMonths(t, -26),
      ),
    ]);
  }
}
